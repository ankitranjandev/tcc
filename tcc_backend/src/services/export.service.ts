import { createObjectCsvWriter } from 'csv-writer';
import ExcelJS from 'exceljs';
import PDFDocument from 'pdfkit';
import db from '../database';
import { UserRole, KYCStatus } from '../types';
import logger from '../utils/logger';
import * as fs from 'fs';
import * as path from 'path';

interface ExportFilters {
  search?: string;
  role?: UserRole;
  status?: string;
  kycStatus?: KYCStatus;
}

export class ExportService {
  private static uploadsDir = path.join(__dirname, '../../uploads/exports');

  /**
   * Initialize export directory
   */
  static async init() {
    if (!fs.existsSync(this.uploadsDir)) {
      fs.mkdirSync(this.uploadsDir, { recursive: true });
    }
  }

  /**
   * Export users data
   */
  static async exportUsers(
    format: 'csv' | 'xlsx' | 'pdf',
    filters: ExportFilters
  ): Promise<{ filename: string; filepath: string }> {
    try {
      await this.init();

      // Fetch users with filters
      const users = await this.fetchUsersForExport(filters);

      logger.info('Exporting users', { format, userCount: users.length, filters });

      switch (format) {
        case 'csv':
          return await this.exportUsersToCSV(users);
        case 'xlsx':
          return await this.exportUsersToExcel(users);
        case 'pdf':
          return await this.exportUsersToPDF(users);
        default:
          throw new Error('Unsupported export format');
      }
    } catch (error) {
      logger.error('Error exporting users', error);
      throw error;
    }
  }

  /**
   * Fetch users for export with filters
   */
  private static async fetchUsersForExport(filters: ExportFilters): Promise<any[]> {
    try {
      const conditions: string[] = [];
      const params: any[] = [];
      let paramCount = 1;

      // Build WHERE clause
      if (filters.search) {
        conditions.push(
          `(u.first_name ILIKE $${paramCount} OR u.last_name ILIKE $${paramCount} OR u.email ILIKE $${paramCount} OR u.phone ILIKE $${paramCount})`
        );
        params.push(`%${filters.search}%`);
        paramCount++;
      }

      if (filters.role) {
        conditions.push(`u.role = $${paramCount}`);
        params.push(filters.role);
        paramCount++;
      }

      if (filters.status) {
        const isActive = filters.status === 'ACTIVE';
        conditions.push(`u.is_active = $${paramCount}`);
        params.push(isActive);
        paramCount++;
      }

      if (filters.kycStatus) {
        conditions.push(`u.kyc_status = $${paramCount}`);
        params.push(filters.kycStatus);
        paramCount++;
      }

      const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

      const query = `
        SELECT
          u.id,
          u.first_name,
          u.last_name,
          u.email,
          u.phone,
          u.country_code,
          u.role,
          u.kyc_status,
          u.is_active,
          COALESCE(w.balance, 0) as wallet_balance,
          u.created_at,
          u.last_login_at
        FROM users u
        LEFT JOIN wallets w ON u.id = w.user_id
        ${whereClause}
        ORDER BY u.created_at DESC
      `;

      const result = await db.query(query, params);
      return result;
    } catch (error) {
      logger.error('Error fetching users for export', error);
      throw error;
    }
  }

  /**
   * Export users to CSV
   */
  private static async exportUsersToCSV(users: any[]): Promise<{ filename: string; filepath: string }> {
    const timestamp = Date.now();
    const filename = `users_export_${timestamp}.csv`;
    const filepath = path.join(this.uploadsDir, filename);

    const csvWriter = createObjectCsvWriter({
      path: filepath,
      header: [
        { id: 'id', title: 'User ID' },
        { id: 'first_name', title: 'First Name' },
        { id: 'last_name', title: 'Last Name' },
        { id: 'email', title: 'Email' },
        { id: 'phone', title: 'Phone' },
        { id: 'country_code', title: 'Country Code' },
        { id: 'role', title: 'Role' },
        { id: 'kyc_status', title: 'KYC Status' },
        { id: 'is_active', title: 'Active' },
        { id: 'wallet_balance', title: 'Wallet Balance' },
        { id: 'created_at', title: 'Registration Date' },
        { id: 'last_login_at', title: 'Last Login' },
      ],
    });

    await csvWriter.writeRecords(
      users.map((user) => ({
        ...user,
        is_active: user.is_active ? 'Yes' : 'No',
        wallet_balance: user.wallet_balance ? Number(user.wallet_balance).toFixed(2) : '0.00',
        created_at: new Date(user.created_at).toISOString(),
        last_login_at: user.last_login_at ? new Date(user.last_login_at).toISOString() : '',
      }))
    );

    logger.info('CSV export completed', { filename, userCount: users.length });
    return { filename, filepath };
  }

  /**
   * Export users to Excel
   */
  private static async exportUsersToExcel(users: any[]): Promise<{ filename: string; filepath: string }> {
    const timestamp = Date.now();
    const filename = `users_export_${timestamp}.xlsx`;
    const filepath = path.join(this.uploadsDir, filename);

    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Users');

    // Define columns
    worksheet.columns = [
      { header: 'User ID', key: 'id', width: 40 },
      { header: 'First Name', key: 'first_name', width: 20 },
      { header: 'Last Name', key: 'last_name', width: 20 },
      { header: 'Email', key: 'email', width: 30 },
      { header: 'Phone', key: 'phone', width: 15 },
      { header: 'Country Code', key: 'country_code', width: 15 },
      { header: 'Role', key: 'role', width: 15 },
      { header: 'KYC Status', key: 'kyc_status', width: 15 },
      { header: 'Active', key: 'is_active', width: 10 },
      { header: 'Wallet Balance', key: 'wallet_balance', width: 15 },
      { header: 'Registration Date', key: 'created_at', width: 20 },
      { header: 'Last Login', key: 'last_login_at', width: 20 },
    ];

    // Style header row
    worksheet.getRow(1).font = { bold: true };
    worksheet.getRow(1).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFE0E0E0' },
    };

    // Add data
    users.forEach((user) => {
      worksheet.addRow({
        id: user.id,
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        phone: user.phone,
        country_code: user.country_code,
        role: user.role,
        kyc_status: user.kyc_status,
        is_active: user.is_active ? 'Yes' : 'No',
        wallet_balance: user.wallet_balance ? Number(user.wallet_balance).toFixed(2) : '0.00',
        created_at: new Date(user.created_at).toISOString(),
        last_login_at: user.last_login_at ? new Date(user.last_login_at).toISOString() : '',
      });
    });

    await workbook.xlsx.writeFile(filepath);

    logger.info('Excel export completed', { filename, userCount: users.length });
    return { filename, filepath };
  }

  /**
   * Export users to PDF
   */
  private static async exportUsersToPDF(users: any[]): Promise<{ filename: string; filepath: string }> {
    return new Promise((resolve, reject) => {
      const timestamp = Date.now();
      const filename = `users_export_${timestamp}.pdf`;
      const filepath = path.join(this.uploadsDir, filename);

      const doc = new PDFDocument({ margin: 50, size: 'A4', layout: 'landscape' });
      const stream = fs.createWriteStream(filepath);

      doc.pipe(stream);

      // Title
      doc.fontSize(20).text('Users Export Report', { align: 'center' });
      doc.moveDown();
      doc.fontSize(10).text(`Generated on: ${new Date().toISOString()}`, { align: 'center' });
      doc.moveDown(2);

      // Table headers
      const tableTop = 120;
      const itemHeight = 20;
      const columnWidths = {
        name: 100,
        email: 120,
        phone: 80,
        role: 60,
        kyc: 80,
        balance: 70,
        status: 50,
        date: 80,
      };

      let yPosition = tableTop;

      // Draw header
      doc.fontSize(9).font('Helvetica-Bold');
      doc.text('Name', 50, yPosition, { width: columnWidths.name });
      doc.text('Email', 150, yPosition, { width: columnWidths.email });
      doc.text('Phone', 270, yPosition, { width: columnWidths.phone });
      doc.text('Role', 350, yPosition, { width: columnWidths.role });
      doc.text('KYC Status', 410, yPosition, { width: columnWidths.kyc });
      doc.text('Balance', 490, yPosition, { width: columnWidths.balance });
      doc.text('Status', 560, yPosition, { width: columnWidths.status });
      doc.text('Registered', 610, yPosition, { width: columnWidths.date });

      doc
        .moveTo(50, yPosition + 15)
        .lineTo(750, yPosition + 15)
        .stroke();

      yPosition += itemHeight;

      // Draw data
      doc.font('Helvetica').fontSize(8);
      users.forEach((user, index) => {
        if (yPosition > 500) {
          doc.addPage();
          yPosition = 50;
        }

        const fullName = `${user.first_name} ${user.last_name}`;
        doc.text(fullName, 50, yPosition, { width: columnWidths.name, height: itemHeight });
        doc.text(user.email || '', 150, yPosition, { width: columnWidths.email, height: itemHeight });
        doc.text(user.phone || '', 270, yPosition, { width: columnWidths.phone, height: itemHeight });
        doc.text(user.role || '', 350, yPosition, { width: columnWidths.role, height: itemHeight });
        doc.text(user.kyc_status || '', 410, yPosition, { width: columnWidths.kyc, height: itemHeight });
        doc.text(user.wallet_balance ? Number(user.wallet_balance).toFixed(2) : '0.00', 490, yPosition, {
          width: columnWidths.balance,
          height: itemHeight,
        });
        doc.text(user.is_active ? 'Active' : 'Inactive', 560, yPosition, {
          width: columnWidths.status,
          height: itemHeight,
        });
        doc.text(new Date(user.created_at).toISOString().split('T')[0], 610, yPosition, {
          width: columnWidths.date,
          height: itemHeight,
        });

        yPosition += itemHeight;
      });

      // Footer
      doc.fontSize(8).text(`Total Users: ${users.length}`, 50, yPosition + 20, { align: 'left' });

      doc.end();

      stream.on('finish', () => {
        logger.info('PDF export completed', { filename, userCount: users.length });
        resolve({ filename, filepath });
      });

      stream.on('error', (error) => {
        logger.error('Error writing PDF', error);
        reject(error);
      });
    });
  }

  /**
   * Clean up old export files (older than 24 hours)
   */
  static async cleanupOldExports(): Promise<void> {
    try {
      await this.init();

      const files = fs.readdirSync(this.uploadsDir);
      const now = Date.now();
      const maxAge = 24 * 60 * 60 * 1000; // 24 hours

      files.forEach((file) => {
        const filepath = path.join(this.uploadsDir, file);
        const stats = fs.statSync(filepath);
        const age = now - stats.mtimeMs;

        if (age > maxAge) {
          fs.unlinkSync(filepath);
          logger.info('Deleted old export file', { file });
        }
      });
    } catch (error) {
      logger.error('Error cleaning up old exports', error);
    }
  }
}
