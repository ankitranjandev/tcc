// @ts-nocheck
import { PoolClient } from 'pg';
import db from '../database';
import logger from '../utils/logger';
import {
  Transaction,
  TransactionType,
  TransactionStatus,
  KYCStatus,
  PaginationParams,
} from '../types';

export interface TransactionFilters {
  type?: TransactionType;
  status?: TransactionStatus;
  fromDate?: Date;
  toDate?: Date;
  search?: string;
}

export class TransactionService {
  /**
   * Get transaction history with filters and pagination
   */
  static async getTransactionHistory(
    userId: string,
    filters: TransactionFilters = {},
    pagination: PaginationParams
  ): Promise<{
    transactions: any[];
    pagination: {
      page: number;
      limit: number;
      total: number;
      totalPages: number;
    };
  }> {
    try {
      // Build WHERE clause
      const conditions: string[] = ['(from_user_id = $1 OR to_user_id = $1)'];
      const params: any[] = [userId];
      let paramCount = 2;

      // Add filters
      if (filters.type) {
        conditions.push(`type = $${paramCount}`);
        params.push(filters.type);
        paramCount++;
      }

      if (filters.status) {
        conditions.push(`status = $${paramCount}`);
        params.push(filters.status);
        paramCount++;
      }

      if (filters.fromDate) {
        conditions.push(`created_at >= $${paramCount}`);
        params.push(filters.fromDate);
        paramCount++;
      }

      if (filters.toDate) {
        conditions.push(`created_at <= $${paramCount}`);
        params.push(filters.toDate);
        paramCount++;
      }

      if (filters.search) {
        conditions.push(
          `(transaction_id ILIKE $${paramCount} OR CAST(amount AS TEXT) ILIKE $${paramCount})`
        );
        params.push(`%${filters.search}%`);
        paramCount++;
      }

      const whereClause = conditions.join(' AND ');

      // Get total count
      const countResult = await db.query(
        `SELECT COUNT(*) as total FROM transactions WHERE ${whereClause}`,
        params
      );
      const total = parseInt(countResult[0].total);

      // Get transactions
      const transactions = await db.query<Transaction>(
        `SELECT
          t.id,
          t.transaction_id,
          t.type,
          t.amount,
          t.fee,
          t.net_amount,
          t.status,
          t.payment_method,
          t.deposit_source,
          t.description,
          t.reference,
          t.created_at,
          t.processed_at,
          t.failed_at,
          t.failure_reason,
          CASE
            WHEN t.from_user_id = $1 THEN 'DEBIT'
            WHEN t.to_user_id = $1 THEN 'CREDIT'
            ELSE 'UNKNOWN'
          END as direction,
          CASE
            WHEN t.from_user_id = $1 AND t.to_user_id IS NOT NULL THEN
              (SELECT CONCAT(first_name, ' ', last_name) FROM users WHERE id = t.to_user_id)
            WHEN t.to_user_id = $1 AND t.from_user_id IS NOT NULL THEN
              (SELECT CONCAT(first_name, ' ', last_name) FROM users WHERE id = t.from_user_id)
            ELSE NULL
          END as other_party_name,
          CASE
            WHEN t.from_user_id = $1 AND t.to_user_id IS NOT NULL THEN
              (SELECT phone FROM users WHERE id = t.to_user_id)
            WHEN t.to_user_id = $1 AND t.from_user_id IS NOT NULL THEN
              (SELECT phone FROM users WHERE id = t.from_user_id)
            ELSE NULL
          END as other_party_phone
        FROM transactions t
        WHERE ${whereClause}
        ORDER BY t.created_at DESC
        LIMIT $${paramCount} OFFSET $${paramCount + 1}`,
        [...params, pagination.limit, pagination.offset]
      );

      // Format transactions
      const formattedTransactions = transactions.map((txn: any) => ({
        id: txn.id,
        transaction_id: txn.transaction_id,
        type: txn.type,
        amount: parseFloat(txn.amount),
        fee: parseFloat(txn.fee || 0),
        net_amount: parseFloat(txn.net_amount || txn.amount),
        status: txn.status,
        direction: txn.direction,
        payment_method: txn.payment_method,
        deposit_source: txn.deposit_source,
        description: txn.description || this.getDefaultDescription(txn.type),
        reference: txn.reference,
        other_party: txn.other_party_name
          ? {
              name: txn.other_party_name,
              phone: txn.other_party_phone ? `****${txn.other_party_phone.slice(-4)}` : null,
            }
          : null,
        date: txn.created_at ? new Date(txn.created_at).toISOString() : new Date().toISOString(),
        created_at: txn.created_at,
        completed_at: txn.processed_at,
        failed_at: txn.failed_at,
        failure_reason: txn.failure_reason,
      }));

      const totalPages = Math.ceil(total / pagination.limit);

      return {
        transactions: formattedTransactions,
        pagination: {
          page: pagination.page,
          limit: pagination.limit,
          total,
          totalPages,
        },
      };
    } catch (error) {
      logger.error('Error getting transaction history', error);
      throw error;
    }
  }

  /**
   * Get single transaction details
   */
  static async getTransactionDetails(userId: string, transactionId: string): Promise<any> {
    try {
      const transactions = await db.query<Transaction>(
        `SELECT
          t.*,
          CASE
            WHEN t.from_user_id = $1 THEN 'DEBIT'
            WHEN t.to_user_id = $1 THEN 'CREDIT'
            ELSE 'UNKNOWN'
          END as direction,
          CASE
            WHEN t.from_user_id = $1 AND t.to_user_id IS NOT NULL THEN
              (SELECT CONCAT(first_name, ' ', last_name) FROM users WHERE id = t.to_user_id)
            WHEN t.to_user_id = $1 AND t.from_user_id IS NOT NULL THEN
              (SELECT CONCAT(first_name, ' ', last_name) FROM users WHERE id = t.from_user_id)
            ELSE NULL
          END as other_party_name,
          CASE
            WHEN t.from_user_id = $1 AND t.to_user_id IS NOT NULL THEN
              (SELECT phone FROM users WHERE id = t.to_user_id)
            WHEN t.to_user_id = $1 AND t.from_user_id IS NOT NULL THEN
              (SELECT phone FROM users WHERE id = t.from_user_id)
            ELSE NULL
          END as other_party_phone,
          CASE
            WHEN t.from_user_id = $1 AND t.to_user_id IS NOT NULL THEN
              (SELECT email FROM users WHERE id = t.to_user_id)
            WHEN t.to_user_id = $1 AND t.from_user_id IS NOT NULL THEN
              (SELECT email FROM users WHERE id = t.from_user_id)
            ELSE NULL
          END as other_party_email
        FROM transactions t
        WHERE t.transaction_id = $2 AND (t.from_user_id = $1 OR t.to_user_id = $1)`,
        [userId, transactionId]
      );

      if (transactions.length === 0) {
        throw new Error('TRANSACTION_NOT_FOUND');
      }

      const txn: any = transactions[0];

      // Parse metadata if exists
      let metadata = null;
      if (txn.metadata) {
        try {
          metadata = typeof txn.metadata === 'string' ? JSON.parse(txn.metadata) : txn.metadata;
        } catch (e) {
          logger.warn('Failed to parse transaction metadata', { transactionId });
        }
      }

      return {
        id: txn.id,
        transaction_id: txn.transaction_id,
        type: txn.type,
        amount: parseFloat(txn.amount),
        fee: parseFloat(txn.fee || 0),
        net_amount: parseFloat(txn.net_amount || txn.amount),
        status: txn.status,
        direction: txn.direction,
        payment_method: txn.payment_method,
        deposit_source: txn.deposit_source,
        description: txn.description || this.getDefaultDescription(txn.type),
        reference: txn.reference,
        other_party: txn.other_party_name
          ? {
              name: txn.other_party_name,
              phone: txn.other_party_phone ? `****${txn.other_party_phone.slice(-4)}` : null,
              email: txn.other_party_email,
            }
          : null,
        metadata,
        date: txn.created_at ? new Date(txn.created_at).toISOString() : new Date().toISOString(),
        created_at: txn.created_at,
        processed_at: txn.processed_at,
        failed_at: txn.failed_at,
        failure_reason: txn.failure_reason,
        updated_at: txn.updated_at,
      };
    } catch (error) {
      logger.error('Error getting transaction details', error);
      throw error;
    }
  }

  /**
   * Calculate transaction fee based on type, amount, and KYC status
   */
  static calculateFee(type: TransactionType, amount: number, kycStatus: KYCStatus): number {
    switch (type) {
      case TransactionType.DEPOSIT:
        // No fee for deposits
        return 0;

      case TransactionType.WITHDRAWAL:
        if (kycStatus === KYCStatus.APPROVED) {
          // 1% fee for KYC approved users, min 50, max 500
          const fee = amount * 0.01;
          return Math.max(50, Math.min(500, fee));
        } else {
          // 2% fee for non-KYC users, min 100, max 1000
          const fee = amount * 0.02;
          return Math.max(100, Math.min(1000, fee));
        }

      case TransactionType.TRANSFER:
        if (kycStatus === KYCStatus.APPROVED) {
          // 0.5% fee for KYC approved users, min 10, max 200
          const fee = amount * 0.005;
          return Math.max(10, Math.min(200, fee));
        } else {
          // 1% fee for non-KYC users, min 20, max 500
          const fee = amount * 0.01;
          return Math.max(20, Math.min(500, fee));
        }

      case TransactionType.BILL_PAYMENT:
        // Flat 2% fee for bill payments, min 20
        const fee = amount * 0.02;
        return Math.max(20, fee);

      case TransactionType.VOTE:
        // No additional fee for votes (vote charge is the fee)
        return 0;

      case TransactionType.INVESTMENT:
        // No fee for investments
        return 0;

      case TransactionType.INVESTMENT_RETURN:
        // No fee for investment returns (system credits)
        return 0;

      case TransactionType.REFUND:
        // No fee for refunds
        return 0;

      default:
        return 0;
    }
  }

  /**
   * Process a transaction (update status)
   * This is typically called by background jobs or admin actions
   */
  static async processTransaction(
    transactionId: string,
    status: TransactionStatus,
    failureReason?: string
  ): Promise<void> {
    try {
      await db.transaction(async (client: PoolClient) => {
        // Get transaction
        const transactions = await client.query<Transaction>(
          'SELECT * FROM transactions WHERE transaction_id = $1',
          [transactionId]
        );

        if (transactions.length === 0) {
          throw new Error('TRANSACTION_NOT_FOUND');
        }

        const txn = transactions[0];

        // Check if already processed
        if (
          txn.status === TransactionStatus.COMPLETED ||
          txn.status === TransactionStatus.FAILED
        ) {
          throw new Error('TRANSACTION_ALREADY_PROCESSED');
        }

        // Update transaction status
        if (status === TransactionStatus.COMPLETED) {
          await client.query(
            'UPDATE transactions SET status = $1, processed_at = NOW(), updated_at = NOW() WHERE transaction_id = $2',
            [status, transactionId]
          );

          // For pending deposits, credit the wallet
          if (txn.type === TransactionType.DEPOSIT && txn.to_user_id) {
            await client.query(
              `UPDATE wallets
               SET balance = balance + $1, last_transaction_at = NOW(), updated_at = NOW()
               WHERE user_id = $2`,
              [txn.amount, txn.to_user_id]
            );
          }
        } else if (status === TransactionStatus.FAILED) {
          await client.query(
            `UPDATE transactions
             SET status = $1, failed_at = NOW(), failure_reason = $2, updated_at = NOW()
             WHERE transaction_id = $3`,
            [status, failureReason, transactionId]
          );

          // For failed withdrawals/transfers, refund the amount to wallet
          if (
            (txn.type === TransactionType.WITHDRAWAL || txn.type === TransactionType.TRANSFER) &&
            txn.from_user_id
          ) {
            const refundAmount = parseFloat(txn.amount.toString()) + parseFloat(txn.fee.toString());
            await client.query(
              `UPDATE wallets
               SET balance = balance + $1, updated_at = NOW()
               WHERE user_id = $2`,
              [refundAmount, txn.from_user_id]
            );
          }
        }
      });

      logger.info('Transaction processed', { transactionId, status });
    } catch (error) {
      logger.error('Error processing transaction', error);
      throw error;
    }
  }

  /**
   * Get transaction statistics for a user
   */
  static async getTransactionStats(
    userId: string,
    fromDate?: Date,
    toDate?: Date
  ): Promise<any> {
    try {
      const conditions = ['(from_user_id = $1 OR to_user_id = $1)', 'status = $2'];
      const params: any[] = [userId, TransactionStatus.COMPLETED];
      let paramCount = 3;

      if (fromDate) {
        conditions.push(`created_at >= $${paramCount}`);
        params.push(fromDate);
        paramCount++;
      }

      if (toDate) {
        conditions.push(`created_at <= $${paramCount}`);
        params.push(toDate);
        paramCount++;
      }

      const whereClause = conditions.join(' AND ');

      const stats = await db.query(
        `SELECT
          COUNT(*) as total_transactions,
          SUM(CASE WHEN from_user_id = $1 THEN amount + fee ELSE 0 END) as total_debits,
          SUM(CASE WHEN to_user_id = $1 THEN amount ELSE 0 END) as total_credits,
          SUM(CASE WHEN from_user_id = $1 THEN fee ELSE 0 END) as total_fees,
          COUNT(CASE WHEN type = 'DEPOSIT' THEN 1 END) as total_deposits,
          COUNT(CASE WHEN type = 'WITHDRAWAL' THEN 1 END) as total_withdrawals,
          COUNT(CASE WHEN type = 'TRANSFER' THEN 1 END) as total_transfers,
          SUM(CASE WHEN type = 'DEPOSIT' AND to_user_id = $1 THEN amount ELSE 0 END) as deposit_amount,
          SUM(CASE WHEN type = 'WITHDRAWAL' AND from_user_id = $1 THEN amount ELSE 0 END) as withdrawal_amount,
          SUM(CASE WHEN type = 'TRANSFER' AND from_user_id = $1 THEN amount ELSE 0 END) as transfer_sent,
          SUM(CASE WHEN type = 'TRANSFER' AND to_user_id = $1 THEN amount ELSE 0 END) as transfer_received
        FROM transactions
        WHERE ${whereClause}`,
        params
      );

      return {
        total_transactions: parseInt(stats[0].total_transactions || 0),
        total_debits: parseFloat(stats[0].total_debits || 0),
        total_credits: parseFloat(stats[0].total_credits || 0),
        total_fees: parseFloat(stats[0].total_fees || 0),
        deposits: {
          count: parseInt(stats[0].total_deposits || 0),
          amount: parseFloat(stats[0].deposit_amount || 0),
        },
        withdrawals: {
          count: parseInt(stats[0].total_withdrawals || 0),
          amount: parseFloat(stats[0].withdrawal_amount || 0),
        },
        transfers: {
          count: parseInt(stats[0].total_transfers || 0),
          sent: parseFloat(stats[0].transfer_sent || 0),
          received: parseFloat(stats[0].transfer_received || 0),
        },
      };
    } catch (error) {
      logger.error('Error getting transaction stats', error);
      throw error;
    }
  }

  /**
   * Get default description for transaction type
   */
  private static getDefaultDescription(type: TransactionType): string {
    switch (type) {
      case TransactionType.DEPOSIT:
        return 'Deposit to wallet';
      case TransactionType.WITHDRAWAL:
        return 'Withdrawal from wallet';
      case TransactionType.TRANSFER:
        return 'Transfer';
      case TransactionType.BILL_PAYMENT:
        return 'Bill payment';
      case TransactionType.INVESTMENT:
        return 'Investment';
      case TransactionType.VOTE:
        return 'Vote';
      case TransactionType.COMMISSION:
        return 'Commission earned';
      case TransactionType.AGENT_CREDIT:
        return 'Agent credit';
      case TransactionType.INVESTMENT_RETURN:
        return 'Investment return credited';
      case TransactionType.REFUND:
        return 'Transaction refund';
      default:
        return 'Transaction';
    }
  }
}
