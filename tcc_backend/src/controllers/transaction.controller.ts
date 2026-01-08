import { Response } from 'express';
import { AuthRequest, TransactionType, TransactionStatus } from '../types';
import { TransactionService } from '../services/transaction.service';
import { ReceiptService } from '../services/receipt.service';
import { ApiResponseUtil } from '../utils/response';
import logger from '../utils/logger';
import db from '../database';

export class TransactionController {
  /**
   * Get transaction history with filters
   */
  static async getTransactionHistory(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      // Parse pagination
      const page = parseInt(req.query.page as string) || 1;
      const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);
      const offset = (page - 1) * limit;

      // Parse filters
      const filters: any = {};

      if (req.query.type) {
        filters.type = req.query.type as TransactionType;
      }

      if (req.query.status) {
        filters.status = req.query.status as TransactionStatus;
      }

      if (req.query.from_date) {
        filters.fromDate = new Date(req.query.from_date as string);
      }

      if (req.query.to_date) {
        filters.toDate = new Date(req.query.to_date as string);
      }

      if (req.query.search) {
        filters.search = req.query.search as string;
      }

      const result = await TransactionService.getTransactionHistory(userId, filters, {
        page,
        limit,
        offset,
      });

      return ApiResponseUtil.success(
        res,
        {
          transactions: result.transactions,
        },
        undefined,
        {
          pagination: result.pagination,
        }
      );
    } catch (error: any) {
      logger.error('Get transaction history error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get single transaction details
   */
  static async getTransactionDetails(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { transaction_id } = req.params;

      const transaction = await TransactionService.getTransactionDetails(userId, transaction_id);

      return ApiResponseUtil.success(res, { transaction });
    } catch (error: any) {
      logger.error('Get transaction details error', error);

      if (error.message === 'TRANSACTION_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Transaction not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get transaction statistics
   */
  static async getTransactionStats(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      // Parse date filters
      let fromDate: Date | undefined;
      let toDate: Date | undefined;

      if (req.query.from_date) {
        fromDate = new Date(req.query.from_date as string);
      }

      if (req.query.to_date) {
        toDate = new Date(req.query.to_date as string);
      }

      const stats = await TransactionService.getTransactionStats(userId, fromDate, toDate);

      return ApiResponseUtil.success(res, { stats });
    } catch (error: any) {
      logger.error('Get transaction stats error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Process a transaction (Admin only)
   * This updates transaction status to completed or failed
   */
  static async processTransaction(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { transaction_id } = req.params;
      const { status, failure_reason } = req.body;

      await TransactionService.processTransaction(transaction_id, status, failure_reason);

      return ApiResponseUtil.success(res, null, 'Transaction processed successfully');
    } catch (error: any) {
      logger.error('Process transaction error', error);

      if (error.message === 'TRANSACTION_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Transaction not found');
      }

      if (error.message === 'TRANSACTION_ALREADY_PROCESSED') {
        return ApiResponseUtil.badRequest(res, 'Transaction has already been processed');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Download transaction receipt as PDF
   */
  static async downloadReceipt(req: AuthRequest, res: Response): Promise<Response | void> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { transaction_id } = req.params;

      // Get transaction details
      const transaction = await TransactionService.getTransactionDetails(userId, transaction_id);

      // Get user details
      const userResult = await db.query(
        'SELECT first_name, last_name, email, phone FROM users WHERE id = $1',
        [userId]
      );

      if (userResult.length === 0) {
        return ApiResponseUtil.notFound(res, 'User not found');
      }

      const user = userResult[0] as { first_name: string; last_name: string; email?: string; phone?: string };

      // Generate PDF receipt
      const receipt = await ReceiptService.generateTransactionReceipt(transaction, user);

      // Set response headers for PDF download
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename="${receipt.filename}"`);
      res.setHeader('Content-Length', receipt.buffer.length);

      // Send the PDF buffer
      res.send(receipt.buffer);
    } catch (error: any) {
      logger.error('Download receipt error', error);

      if (error.message === 'TRANSACTION_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Transaction not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }
}
