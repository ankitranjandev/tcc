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
   * Export transactions data
   */
  static async exportTransactions(
    format: 'csv' | 'xlsx' | 'pdf',
    filters: {
      search?: string;
      status?: string;
      type?: string;
      startDate?: string;
      endDate?: string;
    }
  ): Promise<{ filename: string; filepath: string }> {
    try {
      await this.init();

      // Fetch transactions with filters
      const transactions = await this.fetchTransactionsForExport(filters);

      logger.info('Exporting transactions', { format, count: transactions.length, filters });

      switch (format) {
        case 'csv':
          return await this.exportTransactionsToCSV(transactions);
        case 'xlsx':
          return await this.exportTransactionsToExcel(transactions);
        case 'pdf':
          return await this.exportTransactionsToPDF(transactions);
        default:
          throw new Error('Unsupported export format');
      }
    } catch (error) {
      logger.error('Error exporting transactions', error);
      throw error;
    }
  }

  /**
   * Fetch transactions for export with filters
   */
  private static async fetchTransactionsForExport(filters: {
    search?: string;
    status?: string;
    type?: string;
    startDate?: string;
    endDate?: string;
  }): Promise<any[]> {
    try {
      const conditions: string[] = [];
      const params: any[] = [];
      let paramCount = 1;

      if (filters.search) {
        conditions.push(
          `(t.transaction_id ILIKE $${paramCount} OR u.email ILIKE $${paramCount} OR u.first_name ILIKE $${paramCount} OR u.last_name ILIKE $${paramCount})`
        );
        params.push(`%${filters.search}%`);
        paramCount++;
      }

      if (filters.status) {
        conditions.push(`t.status = $${paramCount}`);
        params.push(filters.status);
        paramCount++;
      }

      if (filters.type) {
        conditions.push(`t.type = $${paramCount}`);
        params.push(filters.type);
        paramCount++;
      }

      if (filters.startDate) {
        conditions.push(`t.created_at >= $${paramCount}`);
        params.push(new Date(filters.startDate));
        paramCount++;
      }

      if (filters.endDate) {
        conditions.push(`t.created_at <= $${paramCount}`);
        params.push(new Date(filters.endDate));
        paramCount++;
      }

      const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

      const query = `
        SELECT
          t.id,
          t.transaction_id,
          t.user_id,
          CONCAT(u.first_name, ' ', u.last_name) as user_name,
          u.email as user_email,
          t.type,
          t.amount,
          t.fee,
          t.status,
          t.description,
          t.created_at,
          t.updated_at
        FROM transactions t
        LEFT JOIN users u ON t.user_id = u.id
        ${whereClause}
        ORDER BY t.created_at DESC
      `;

      const result = await db.query(query, params);
      return result;
    } catch (error) {
      logger.error('Error fetching transactions for export', error);
      throw error;
    }
  }

  /**
   * Export transactions to CSV
   */
  private static async exportTransactionsToCSV(transactions: any[]): Promise<{ filename: string; filepath: string }> {
    const timestamp = Date.now();
    const filename = `transactions_export_${timestamp}.csv`;
    const filepath = path.join(this.uploadsDir, filename);

    const csvWriter = createObjectCsvWriter({
      path: filepath,
      header: [
        { id: 'transaction_id', title: 'Transaction ID' },
        { id: 'user_name', title: 'User Name' },
        { id: 'user_email', title: 'User Email' },
        { id: 'type', title: 'Type' },
        { id: 'amount', title: 'Amount' },
        { id: 'fee', title: 'Fee' },
        { id: 'status', title: 'Status' },
        { id: 'description', title: 'Description' },
        { id: 'created_at', title: 'Date' },
      ],
    });

    await csvWriter.writeRecords(
      transactions.map((txn) => ({
        ...txn,
        amount: txn.amount ? Number(txn.amount).toFixed(2) : '0.00',
        fee: txn.fee ? Number(txn.fee).toFixed(2) : '0.00',
        created_at: new Date(txn.created_at).toISOString(),
      }))
    );

    logger.info('CSV export completed', { filename, count: transactions.length });
    return { filename, filepath };
  }

  /**
   * Export transactions to Excel
   */
  private static async exportTransactionsToExcel(transactions: any[]): Promise<{ filename: string; filepath: string }> {
    const timestamp = Date.now();
    const filename = `transactions_export_${timestamp}.xlsx`;
    const filepath = path.join(this.uploadsDir, filename);

    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Transactions');

    worksheet.columns = [
      { header: 'Transaction ID', key: 'transaction_id', width: 30 },
      { header: 'User Name', key: 'user_name', width: 25 },
      { header: 'User Email', key: 'user_email', width: 30 },
      { header: 'Type', key: 'type', width: 20 },
      { header: 'Amount', key: 'amount', width: 15 },
      { header: 'Fee', key: 'fee', width: 15 },
      { header: 'Status', key: 'status', width: 15 },
      { header: 'Description', key: 'description', width: 40 },
      { header: 'Date', key: 'created_at', width: 20 },
    ];

    worksheet.getRow(1).font = { bold: true };
    worksheet.getRow(1).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFE0E0E0' },
    };

    transactions.forEach((txn) => {
      worksheet.addRow({
        transaction_id: txn.transaction_id,
        user_name: txn.user_name,
        user_email: txn.user_email,
        type: txn.type,
        amount: txn.amount ? Number(txn.amount).toFixed(2) : '0.00',
        fee: txn.fee ? Number(txn.fee).toFixed(2) : '0.00',
        status: txn.status,
        description: txn.description,
        created_at: new Date(txn.created_at).toISOString(),
      });
    });

    await workbook.xlsx.writeFile(filepath);

    logger.info('Excel export completed', { filename, count: transactions.length });
    return { filename, filepath };
  }

  /**
   * Export transactions to PDF
   */
  private static async exportTransactionsToPDF(transactions: any[]): Promise<{ filename: string; filepath: string }> {
    return new Promise((resolve, reject) => {
      const timestamp = Date.now();
      const filename = `transactions_export_${timestamp}.pdf`;
      const filepath = path.join(this.uploadsDir, filename);

      const doc = new PDFDocument({ margin: 50, size: 'A4', layout: 'landscape' });
      const stream = fs.createWriteStream(filepath);

      doc.pipe(stream);

      doc.fontSize(20).text('Transactions Export Report', { align: 'center' });
      doc.moveDown();
      doc.fontSize(10).text(`Generated on: ${new Date().toISOString()}`, { align: 'center' });
      doc.moveDown(2);

      const tableTop = 120;
      const itemHeight = 20;

      let yPosition = tableTop;

      // Draw header
      doc.fontSize(9).font('Helvetica-Bold');
      doc.text('Transaction ID', 50, yPosition, { width: 100 });
      doc.text('User', 150, yPosition, { width: 100 });
      doc.text('Type', 250, yPosition, { width: 80 });
      doc.text('Amount', 330, yPosition, { width: 70 });
      doc.text('Fee', 400, yPosition, { width: 60 });
      doc.text('Status', 460, yPosition, { width: 80 });
      doc.text('Date', 540, yPosition, { width: 100 });

      doc.moveTo(50, yPosition + 15).lineTo(750, yPosition + 15).stroke();

      yPosition += itemHeight;

      // Draw data
      doc.font('Helvetica').fontSize(8);
      transactions.forEach((txn) => {
        if (yPosition > 500) {
          doc.addPage();
          yPosition = 50;
        }

        doc.text(txn.transaction_id || '', 50, yPosition, { width: 100, height: itemHeight });
        doc.text(txn.user_name || '', 150, yPosition, { width: 100, height: itemHeight });
        doc.text(txn.type || '', 250, yPosition, { width: 80, height: itemHeight });
        doc.text(txn.amount ? Number(txn.amount).toFixed(2) : '0.00', 330, yPosition, { width: 70, height: itemHeight });
        doc.text(txn.fee ? Number(txn.fee).toFixed(2) : '0.00', 400, yPosition, { width: 60, height: itemHeight });
        doc.text(txn.status || '', 460, yPosition, { width: 80, height: itemHeight });
        doc.text(new Date(txn.created_at).toISOString().split('T')[0], 540, yPosition, { width: 100, height: itemHeight });

        yPosition += itemHeight;
      });

      doc.fontSize(8).text(`Total Transactions: ${transactions.length}`, 50, yPosition + 20, { align: 'left' });

      doc.end();

      stream.on('finish', () => {
        logger.info('PDF export completed', { filename, count: transactions.length });
        resolve({ filename, filepath });
      });

      stream.on('error', (error) => {
        logger.error('Error writing PDF', error);
        reject(error);
      });
    });
  }

  /**
   * Export investments data
   */
  static async exportInvestments(
    format: 'csv' | 'xlsx' | 'pdf',
    filters: any
  ): Promise<{ filename: string; filepath: string }> {
    try {
      await this.init();
      const investments = await this.fetchInvestmentsForExport(filters);
      logger.info('Exporting investments', { format, count: investments.length });

      const timestamp = Date.now();
      const filename = `investments_export_${timestamp}.${format === 'xlsx' ? 'xlsx' : format}`;
      const filepath = path.join(this.uploadsDir, filename);

      if (format === 'csv') {
        const csvWriter = createObjectCsvWriter({
          path: filepath,
          header: [
            { id: 'id', title: 'Investment ID' },
            { id: 'user_name', title: 'User Name' },
            { id: 'product_name', title: 'Product' },
            { id: 'amount', title: 'Amount' },
            { id: 'status', title: 'Status' },
            { id: 'created_at', title: 'Date' },
          ],
        });
        await csvWriter.writeRecords(investments.map(i => ({ ...i, created_at: new Date(i.created_at).toISOString() })));
      } else if (format === 'xlsx') {
        const workbook = new ExcelJS.Workbook();
        const worksheet = workbook.addWorksheet('Investments');
        worksheet.columns = [
          { header: 'Investment ID', key: 'id', width: 40 },
          { header: 'User Name', key: 'user_name', width: 25 },
          { header: 'Product', key: 'product_name', width: 30 },
          { header: 'Amount', key: 'amount', width: 15 },
          { header: 'Status', key: 'status', width: 15 },
          { header: 'Date', key: 'created_at', width: 20 },
        ];
        worksheet.getRow(1).font = { bold: true };
        investments.forEach(i => worksheet.addRow({ ...i, created_at: new Date(i.created_at).toISOString() }));
        await workbook.xlsx.writeFile(filepath);
      } else {
        return await this.generateGenericPDF(investments, filename, filepath, 'Investments Export');
      }

      return { filename, filepath };
    } catch (error) {
      logger.error('Error exporting investments', error);
      throw error;
    }
  }

  /**
   * Export bill payments data
   */
  static async exportBillPayments(
    format: 'csv' | 'xlsx' | 'pdf',
    filters: any
  ): Promise<{ filename: string; filepath: string }> {
    try {
      await this.init();
      const billPayments = await this.fetchBillPaymentsForExport(filters);
      logger.info('Exporting bill payments', { format, count: billPayments.length });

      const timestamp = Date.now();
      const filename = `bill_payments_export_${timestamp}.${format === 'xlsx' ? 'xlsx' : format}`;
      const filepath = path.join(this.uploadsDir, filename);

      if (format === 'csv') {
        const csvWriter = createObjectCsvWriter({
          path: filepath,
          header: [
            { id: 'id', title: 'Payment ID' },
            { id: 'user_name', title: 'User Name' },
            { id: 'bill_type', title: 'Bill Type' },
            { id: 'amount', title: 'Amount' },
            { id: 'status', title: 'Status' },
            { id: 'created_at', title: 'Date' },
          ],
        });
        await csvWriter.writeRecords(billPayments.map(bp => ({ ...bp, created_at: new Date(bp.created_at).toISOString() })));
      } else if (format === 'xlsx') {
        const workbook = new ExcelJS.Workbook();
        const worksheet = workbook.addWorksheet('Bill Payments');
        worksheet.columns = [
          { header: 'Payment ID', key: 'id', width: 40 },
          { header: 'User Name', key: 'user_name', width: 25 },
          { header: 'Bill Type', key: 'bill_type', width: 20 },
          { header: 'Amount', key: 'amount', width: 15 },
          { header: 'Status', key: 'status', width: 15 },
          { header: 'Date', key: 'created_at', width: 20 },
        ];
        worksheet.getRow(1).font = { bold: true };
        billPayments.forEach(bp => worksheet.addRow({ ...bp, created_at: new Date(bp.created_at).toISOString() }));
        await workbook.xlsx.writeFile(filepath);
      } else {
        return await this.generateGenericPDF(billPayments, filename, filepath, 'Bill Payments Export');
      }

      return { filename, filepath };
    } catch (error) {
      logger.error('Error exporting bill payments', error);
      throw error;
    }
  }

  /**
   * Export e-voting data
   */
  static async exportEVoting(
    format: 'csv' | 'xlsx' | 'pdf',
    filters: any
  ): Promise<{ filename: string; filepath: string }> {
    try {
      await this.init();
      const eVotingData = await this.fetchEVotingForExport(filters);
      logger.info('Exporting e-voting data', { format, count: eVotingData.length });

      const timestamp = Date.now();
      const filename = `evoting_export_${timestamp}.${format === 'xlsx' ? 'xlsx' : format}`;
      const filepath = path.join(this.uploadsDir, filename);

      if (format === 'csv') {
        const csvWriter = createObjectCsvWriter({
          path: filepath,
          header: [
            { id: 'election_id', title: 'Election ID' },
            { id: 'title', title: 'Title' },
            { id: 'total_votes', title: 'Total Votes' },
            { id: 'status', title: 'Status' },
            { id: 'created_at', title: 'Date' },
          ],
        });
        await csvWriter.writeRecords(eVotingData.map(ev => ({ ...ev, created_at: new Date(ev.created_at).toISOString() })));
      } else if (format === 'xlsx') {
        const workbook = new ExcelJS.Workbook();
        const worksheet = workbook.addWorksheet('E-Voting');
        worksheet.columns = [
          { header: 'Election ID', key: 'election_id', width: 40 },
          { header: 'Title', key: 'title', width: 40 },
          { header: 'Total Votes', key: 'total_votes', width: 15 },
          { header: 'Status', key: 'status', width: 15 },
          { header: 'Date', key: 'created_at', width: 20 },
        ];
        worksheet.getRow(1).font = { bold: true };
        eVotingData.forEach(ev => worksheet.addRow({ ...ev, created_at: new Date(ev.created_at).toISOString() }));
        await workbook.xlsx.writeFile(filepath);
      } else {
        return await this.generateGenericPDF(eVotingData, filename, filepath, 'E-Voting Export');
      }

      return { filename, filepath };
    } catch (error) {
      logger.error('Error exporting e-voting data', error);
      throw error;
    }
  }

  /**
   * Export reports data
   */
  static async exportReports(
    format: 'csv' | 'xlsx' | 'pdf',
    filters: any
  ): Promise<{ filename: string; filepath: string }> {
    try {
      await this.init();

      // For reports, we'll generate data based on the report type
      const reportData = await this.generateReportData(filters);
      logger.info('Exporting report', { format, reportType: filters.reportType });

      const timestamp = Date.now();
      const filename = `report_${filters.reportType || 'general'}_${timestamp}.${format === 'xlsx' ? 'xlsx' : format}`;
      const filepath = path.join(this.uploadsDir, filename);

      if (format === 'csv') {
        const csvWriter = createObjectCsvWriter({
          path: filepath,
          header: reportData.headers || [{ id: 'data', title: 'Data' }],
        });
        await csvWriter.writeRecords(reportData.data || []);
      } else if (format === 'xlsx') {
        const workbook = new ExcelJS.Workbook();
        const worksheet = workbook.addWorksheet('Report');
        worksheet.columns = reportData.headers?.map((h: any) => ({ header: h.title, key: h.id, width: 20 })) || [];
        worksheet.getRow(1).font = { bold: true };
        reportData.data?.forEach((row: any) => worksheet.addRow(row));
        await workbook.xlsx.writeFile(filepath);
      } else {
        return await this.generateGenericPDF(reportData.data || [], filename, filepath, `${filters.reportType || 'General'} Report`);
      }

      return { filename, filepath };
    } catch (error) {
      logger.error('Error exporting report', error);
      throw error;
    }
  }

  /**
   * Fetch investments for export
   */
  private static async fetchInvestmentsForExport(filters: any): Promise<any[]> {
    try {
      const conditions: string[] = [];
      const params: any[] = [];
      let paramCount = 1;

      if (filters.search) {
        conditions.push(`(ip.name ILIKE $${paramCount} OR u.email ILIKE $${paramCount})`);
        params.push(`%${filters.search}%`);
        paramCount++;
      }

      if (filters.status) {
        conditions.push(`i.status = $${paramCount}`);
        params.push(filters.status);
        paramCount++;
      }

      if (filters.productId) {
        conditions.push(`i.product_id = $${paramCount}`);
        params.push(filters.productId);
        paramCount++;
      }

      const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

      const query = `
        SELECT
          i.id,
          CONCAT(u.first_name, ' ', u.last_name) as user_name,
          ip.name as product_name,
          i.amount,
          i.status,
          i.created_at
        FROM investments i
        LEFT JOIN users u ON i.user_id = u.id
        LEFT JOIN investment_products ip ON i.product_id = ip.id
        ${whereClause}
        ORDER BY i.created_at DESC
      `;

      const result = await db.query(query, params);
      return result;
    } catch (error) {
      logger.error('Error fetching investments for export', error);
      return [];
    }
  }

  /**
   * Fetch bill payments for export
   */
  private static async fetchBillPaymentsForExport(filters: any): Promise<any[]> {
    try {
      const conditions: string[] = [];
      const params: any[] = [];
      let paramCount = 1;

      if (filters.search) {
        conditions.push(`(u.email ILIKE $${paramCount} OR u.first_name ILIKE $${paramCount})`);
        params.push(`%${filters.search}%`);
        paramCount++;
      }

      if (filters.status) {
        conditions.push(`bp.status = $${paramCount}`);
        params.push(filters.status);
        paramCount++;
      }

      if (filters.billerId) {
        conditions.push(`bp.biller_id = $${paramCount}`);
        params.push(filters.billerId);
        paramCount++;
      }

      const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

      const query = `
        SELECT
          bp.id,
          CONCAT(u.first_name, ' ', u.last_name) as user_name,
          bp.bill_type,
          bp.amount,
          bp.status,
          bp.created_at
        FROM bill_payments bp
        LEFT JOIN users u ON bp.user_id = u.id
        ${whereClause}
        ORDER BY bp.created_at DESC
      `;

      const result = await db.query(query, params);
      return result;
    } catch (error) {
      logger.error('Error fetching bill payments for export', error);
      return [];
    }
  }

  /**
   * Fetch e-voting data for export
   */
  private static async fetchEVotingForExport(filters: any): Promise<any[]> {
    try {
      const conditions: string[] = [];
      const params: any[] = [];
      let paramCount = 1;

      if (filters.electionId) {
        conditions.push(`e.id = $${paramCount}`);
        params.push(filters.electionId);
        paramCount++;
      }

      if (filters.status) {
        conditions.push(`e.status = $${paramCount}`);
        params.push(filters.status);
        paramCount++;
      }

      const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

      const query = `
        SELECT
          e.id as election_id,
          e.title,
          COUNT(v.id) as total_votes,
          e.status,
          e.created_at
        FROM elections e
        LEFT JOIN votes v ON e.id = v.election_id
        ${whereClause}
        GROUP BY e.id, e.title, e.status, e.created_at
        ORDER BY e.created_at DESC
      `;

      const result = await db.query(query, params);
      return result;
    } catch (error) {
      logger.error('Error fetching e-voting data for export', error);
      return [];
    }
  }

  /**
   * Generate report data based on report type
   */
  private static async generateReportData(filters: any): Promise<{ headers: any[]; data: any[] }> {
    // This is a simplified implementation
    // In a real application, you would generate different reports based on the reportType
    return {
      headers: [
        { id: 'metric', title: 'Metric' },
        { id: 'value', title: 'Value' },
      ],
      data: [
        { metric: 'Total Users', value: '1000' },
        { metric: 'Total Transactions', value: '5000' },
        { metric: 'Total Revenue', value: '$50,000' },
      ],
    };
  }

  /**
   * Generate a generic PDF for any data
   */
  private static async generateGenericPDF(
    data: any[],
    filename: string,
    filepath: string,
    title: string
  ): Promise<{ filename: string; filepath: string }> {
    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ margin: 50, size: 'A4', layout: 'landscape' });
      const stream = fs.createWriteStream(filepath);

      doc.pipe(stream);

      doc.fontSize(20).text(title, { align: 'center' });
      doc.moveDown();
      doc.fontSize(10).text(`Generated on: ${new Date().toISOString()}`, { align: 'center' });
      doc.moveDown(2);

      doc.fontSize(10).text(`Total Records: ${data.length}`, { align: 'left' });
      doc.moveDown();

      // Simple table representation
      data.slice(0, 50).forEach((item, index) => {
        doc.fontSize(8).text(JSON.stringify(item, null, 2));
        if (index < data.length - 1) doc.moveDown(0.5);
      });

      if (data.length > 50) {
        doc.text(`... and ${data.length - 50} more records`, { align: 'center' });
      }

      doc.end();

      stream.on('finish', () => {
        logger.info('Generic PDF export completed', { filename });
        resolve({ filename, filepath });
      });

      stream.on('error', (error) => {
        logger.error('Error writing generic PDF', error);
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
