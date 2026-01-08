import PDFDocument from 'pdfkit';
import * as fs from 'fs';
import * as path from 'path';
import logger from '../utils/logger';

interface TransactionData {
  id: string;
  transaction_id: string;
  type: string;
  amount: number;
  fee: number;
  net_amount?: number;
  status: string;
  direction: string;
  description?: string;
  recipient?: string;
  account_info?: string;
  created_at: string;
  other_party?: {
    name?: string;
    phone?: string;
    email?: string;
  };
}

interface UserData {
  first_name: string;
  last_name: string;
  email?: string;
  phone?: string;
}

export class ReceiptService {
  private static uploadsDir = path.join(__dirname, '../../uploads/receipts');

  /**
   * Initialize receipt directory
   */
  static async init() {
    if (!fs.existsSync(this.uploadsDir)) {
      fs.mkdirSync(this.uploadsDir, { recursive: true });
    }
  }

  /**
   * Generate a PDF receipt for a transaction
   */
  static async generateTransactionReceipt(
    transaction: TransactionData,
    user: UserData
  ): Promise<{ filename: string; filepath: string; buffer: Buffer }> {
    return new Promise(async (resolve, reject) => {
      try {
        await this.init();

        const timestamp = Date.now();
        const filename = `TCC_Receipt_${transaction.transaction_id}_${timestamp}.pdf`;
        const filepath = path.join(this.uploadsDir, filename);

        const doc = new PDFDocument({
          margin: 50,
          size: 'A4',
          info: {
            Title: `Transaction Receipt - ${transaction.transaction_id}`,
            Author: 'TCC - The Community Coin',
            Subject: 'Transaction Receipt',
          },
        });

        const chunks: Buffer[] = [];
        doc.on('data', (chunk) => chunks.push(chunk));

        const stream = fs.createWriteStream(filepath);
        doc.pipe(stream);

        // Colors
        const primaryBlue = '#2196F3';
        const successGreen = '#4CAF50';
        const errorRed = '#F44336';
        const warningOrange = '#FF9800';
        const textGray = '#666666';
        const lightGray = '#E0E0E0';

        // Get status color
        const getStatusColor = (status: string) => {
          switch (status.toUpperCase()) {
            case 'COMPLETED':
              return successGreen;
            case 'PENDING':
            case 'PROCESSING':
              return warningOrange;
            case 'FAILED':
            case 'CANCELLED':
              return errorRed;
            default:
              return textGray;
          }
        };

        // Header Section
        doc.fontSize(28).fillColor(primaryBlue).text('TCC', { align: 'center' });
        doc.fontSize(12).fillColor(textGray).text('The Community Coin', { align: 'center' });
        doc.moveDown(0.5);

        doc.fontSize(18).fillColor('#000000').text('Transaction Receipt', { align: 'center' });
        doc.moveDown(0.5);

        // Status Badge
        const statusColor = getStatusColor(transaction.status);
        const statusText = transaction.status.toUpperCase();
        const statusWidth = 100;
        const statusX = (doc.page.width - statusWidth) / 2;

        doc
          .roundedRect(statusX, doc.y, statusWidth, 25, 12)
          .fill(statusColor);
        doc
          .fontSize(11)
          .fillColor('#FFFFFF')
          .text(statusText, statusX, doc.y - 18, { width: statusWidth, align: 'center' });

        doc.moveDown(2);

        // Divider
        doc
          .moveTo(50, doc.y)
          .lineTo(doc.page.width - 50, doc.y)
          .strokeColor(lightGray)
          .lineWidth(2)
          .stroke();

        doc.moveDown(1.5);

        // Amount Section
        doc.fontSize(12).fillColor(textGray).text('Amount', { align: 'center' });
        doc.moveDown(0.3);

        const isCredit = transaction.direction === 'CREDIT';
        const amountPrefix = isCredit ? '+' : '-';
        const amountColor = isCredit ? successGreen : errorRed;

        doc
          .fontSize(32)
          .fillColor(amountColor)
          .text(`${amountPrefix}TCC ${Math.abs(transaction.amount).toFixed(2)}`, { align: 'center' });

        doc.moveDown(1.5);

        // Divider
        doc
          .moveTo(50, doc.y)
          .lineTo(doc.page.width - 50, doc.y)
          .strokeColor(lightGray)
          .lineWidth(1)
          .stroke();

        doc.moveDown(1.5);

        // Transaction Details Section
        doc.fontSize(14).fillColor('#000000').text('Transaction Details', 50);
        doc.moveDown(0.8);

        const drawDetailRow = (label: string, value: string, yOffset?: number) => {
          const y = yOffset ?? doc.y;
          doc.fontSize(11).fillColor(textGray).text(label, 50, y);
          doc.fontSize(11).fillColor('#000000').text(value, 250, y, { width: 295, align: 'right' });
          doc.moveDown(0.8);
        };

        drawDetailRow('Transaction ID', transaction.transaction_id);
        drawDetailRow('Type', this.formatTransactionType(transaction.type));

        if (transaction.description) {
          drawDetailRow('Description', transaction.description);
        }

        // Other party details
        if (transaction.other_party?.name) {
          const partyLabel = isCredit ? 'From' : 'To';
          drawDetailRow(partyLabel, transaction.other_party.name);

          if (transaction.other_party.phone) {
            drawDetailRow(`${partyLabel} Phone`, transaction.other_party.phone);
          }
        }

        if (transaction.recipient) {
          drawDetailRow('Recipient', transaction.recipient);
        }

        if (transaction.account_info) {
          drawDetailRow('Account', transaction.account_info);
        }

        // Date and Time
        const txDate = new Date(transaction.created_at);
        const dateStr = txDate.toLocaleDateString('en-US', {
          weekday: 'long',
          year: 'numeric',
          month: 'long',
          day: 'numeric',
        });
        const timeStr = txDate.toLocaleTimeString('en-US', {
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit',
          hour12: true,
        });

        drawDetailRow('Date', dateStr);
        drawDetailRow('Time', timeStr);

        doc.moveDown(0.5);

        // Divider
        doc
          .moveTo(50, doc.y)
          .lineTo(doc.page.width - 50, doc.y)
          .strokeColor(lightGray)
          .lineWidth(1)
          .stroke();

        doc.moveDown(1);

        // Amount Breakdown Section
        doc.fontSize(14).fillColor('#000000').text('Amount Breakdown', 50);
        doc.moveDown(0.8);

        const amount = Math.abs(transaction.amount);
        const fee = transaction.fee || 0;
        const total = amount + fee;

        drawDetailRow('Amount', `TCC ${amount.toFixed(2)}`);
        drawDetailRow('Transaction Fee', `TCC ${fee.toFixed(2)}`);

        // Divider before total
        doc
          .moveTo(250, doc.y)
          .lineTo(doc.page.width - 50, doc.y)
          .strokeColor(lightGray)
          .lineWidth(1)
          .stroke();

        doc.moveDown(0.5);

        doc.fontSize(12).fillColor(textGray).text('Total', 50);
        doc
          .fontSize(14)
          .fillColor(amountColor)
          .font('Helvetica-Bold')
          .text(`TCC ${total.toFixed(2)}`, 250, doc.y - 14, { width: 295, align: 'right' });

        doc.font('Helvetica');
        doc.moveDown(2);

        // Divider
        doc
          .moveTo(50, doc.y)
          .lineTo(doc.page.width - 50, doc.y)
          .strokeColor(lightGray)
          .lineWidth(1)
          .stroke();

        doc.moveDown(1);

        // Customer Details Section
        doc.fontSize(14).fillColor('#000000').text('Customer Details', 50);
        doc.moveDown(0.8);

        drawDetailRow('Name', `${user.first_name} ${user.last_name}`);
        if (user.phone) {
          drawDetailRow('Phone', user.phone);
        }
        if (user.email) {
          drawDetailRow('Email', user.email);
        }

        doc.moveDown(2);

        // Footer
        doc
          .moveTo(50, doc.y)
          .lineTo(doc.page.width - 50, doc.y)
          .strokeColor(lightGray)
          .lineWidth(1)
          .stroke();

        doc.moveDown(1);

        doc.fontSize(10).fillColor(textGray).text('Thank you for using TCC', { align: 'center' });
        doc.moveDown(0.3);
        doc
          .fontSize(8)
          .fillColor(textGray)
          .text('This is a computer-generated receipt and does not require a signature.', { align: 'center' });
        doc.moveDown(0.3);
        doc.fontSize(8).fillColor(textGray).text('For support: support@tcc.com', { align: 'center' });

        // End the document
        doc.end();

        stream.on('finish', () => {
          const buffer = Buffer.concat(chunks);
          logger.info('Transaction receipt generated', {
            filename,
            transactionId: transaction.transaction_id,
          });
          resolve({ filename, filepath, buffer });
        });

        stream.on('error', (error) => {
          logger.error('Error generating transaction receipt', error);
          reject(error);
        });
      } catch (error) {
        logger.error('Error in generateTransactionReceipt', error);
        reject(error);
      }
    });
  }

  /**
   * Format transaction type for display
   */
  private static formatTransactionType(type: string): string {
    switch (type.toUpperCase()) {
      case 'DEPOSIT':
        return 'Deposit';
      case 'WITHDRAWAL':
        return 'Withdrawal';
      case 'TRANSFER':
        return 'Transfer';
      case 'BILL_PAYMENT':
        return 'Bill Payment';
      case 'INVESTMENT':
        return 'Investment';
      case 'VOTE':
        return 'Vote';
      case 'COMMISSION':
        return 'Commission';
      case 'AGENT_CREDIT':
        return 'Agent Credit';
      case 'INVESTMENT_RETURN':
        return 'Investment Return';
      case 'REFUND':
        return 'Refund';
      case 'CURRENCY_BUY':
        return 'Currency Purchase';
      case 'CURRENCY_SELL':
        return 'Currency Sale';
      default:
        return type.charAt(0).toUpperCase() + type.slice(1).toLowerCase().replace(/_/g, ' ');
    }
  }

  /**
   * Cleanup old receipts (older than 24 hours)
   */
  static async cleanupOldReceipts(): Promise<number> {
    try {
      await this.init();

      const files = fs.readdirSync(this.uploadsDir);
      const now = Date.now();
      const maxAge = 24 * 60 * 60 * 1000; // 24 hours
      let deletedCount = 0;

      for (const file of files) {
        const filepath = path.join(this.uploadsDir, file);
        const stats = fs.statSync(filepath);
        const fileAge = now - stats.mtimeMs;

        if (fileAge > maxAge) {
          fs.unlinkSync(filepath);
          deletedCount++;
        }
      }

      if (deletedCount > 0) {
        logger.info(`Cleaned up ${deletedCount} old receipt files`);
      }

      return deletedCount;
    } catch (error) {
      logger.error('Error cleaning up old receipts', error);
      return 0;
    }
  }
}
