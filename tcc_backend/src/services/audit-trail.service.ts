// @ts-nocheck
import { PoolClient } from 'pg';
import db from '../database';
import logger from '../utils/logger';
import { WalletAuditTrail, AuditActionType, TransactionType, TransactionStatus } from '../types';

export class AuditTrailService {
  /**
   * Create audit trail entry for manual balance adjustment
   */
  static async createAuditEntry(
    userId: string,
    adminId: string,
    actionType: AuditActionType,
    amount: number,
    balanceBefore: number,
    balanceAfter: number,
    reason: string,
    notes?: string,
    transactionId?: string,
    ipAddress?: string
  ): Promise<WalletAuditTrail> {
    try {
      const result = await db.query<WalletAuditTrail>(
        `INSERT INTO wallet_audit_trail (
          user_id, admin_id, action_type, amount, balance_before,
          balance_after, reason, notes, transaction_id, ip_address
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        RETURNING id, user_id, admin_id, action_type, amount, balance_before,
                  balance_after, reason, notes, transaction_id, ip_address, created_at`,
        [
          userId,
          adminId,
          actionType,
          amount,
          balanceBefore,
          balanceAfter,
          reason,
          notes || null,
          transactionId || null,
          ipAddress || null,
        ]
      );

      logger.info('Audit trail entry created', {
        userId,
        adminId,
        actionType,
        amount,
        auditId: result[0].id,
      });

      return result[0];
    } catch (error) {
      logger.error('Error creating audit trail entry', error);
      throw error;
    }
  }

  /**
   * Get audit trail for a specific user
   */
  static async getAuditTrailForUser(
    userId: string,
    limit: number = 50,
    offset: number = 0
  ): Promise<{ entries: any[]; total: number }> {
    try {
      // Get total count
      const countResult = await db.query(
        `SELECT COUNT(*) as total FROM wallet_audit_trail WHERE user_id = $1`,
        [userId]
      );
      const total = parseInt(countResult[0].total);

      // Get audit entries with admin details
      const entries = await db.query(
        `SELECT
          w.id, w.user_id, w.admin_id, w.action_type, w.amount,
          w.balance_before, w.balance_after, w.reason, w.notes,
          w.transaction_id, w.ip_address, w.created_at,
          u.first_name as admin_first_name,
          u.last_name as admin_last_name,
          u.email as admin_email
         FROM wallet_audit_trail w
         JOIN users u ON w.admin_id = u.id
         WHERE w.user_id = $1
         ORDER BY w.created_at DESC
         LIMIT $2 OFFSET $3`,
        [userId, limit, offset]
      );

      return { entries, total };
    } catch (error) {
      logger.error('Error getting audit trail for user', error);
      throw error;
    }
  }

  /**
   * Get all audit trail entries (admin view)
   */
  static async getAllAuditTrail(
    limit: number = 50,
    offset: number = 0,
    actionType?: AuditActionType
  ): Promise<{ entries: any[]; total: number }> {
    try {
      let whereClause = '';
      const params: any[] = [limit, offset];

      if (actionType) {
        whereClause = 'WHERE w.action_type = $3';
        params.push(actionType);
      }

      // Get total count
      const countQuery = `SELECT COUNT(*) as total FROM wallet_audit_trail w ${whereClause}`;
      const countResult = await db.query(countQuery, actionType ? [actionType] : []);
      const total = parseInt(countResult[0].total);

      // Get audit entries with user and admin details
      const query = `
        SELECT
          w.id, w.user_id, w.admin_id, w.action_type, w.amount,
          w.balance_before, w.balance_after, w.reason, w.notes,
          w.transaction_id, w.ip_address, w.created_at,
          u.first_name as user_first_name,
          u.last_name as user_last_name,
          u.email as user_email,
          u.phone as user_phone,
          a.first_name as admin_first_name,
          a.last_name as admin_last_name,
          a.email as admin_email
        FROM wallet_audit_trail w
        JOIN users u ON w.user_id = u.id
        JOIN users a ON w.admin_id = a.id
        ${whereClause}
        ORDER BY w.created_at DESC
        LIMIT $1 OFFSET $2
      `;

      const entries = await db.query(query, params);

      return { entries, total };
    } catch (error) {
      logger.error('Error getting all audit trail', error);
      throw error;
    }
  }

  /**
   * Manually adjust user wallet balance (credit or debit)
   */
  static async adjustBalance(
    userId: string,
    adminId: string,
    amount: number,
    reason: string,
    notes?: string,
    ipAddress?: string
  ): Promise<{ wallet: any; auditEntry: WalletAuditTrail; transaction: any }> {
    try {
      // Validate amount (positive for credit, negative for debit)
      if (amount === 0) {
        throw new Error('INVALID_AMOUNT');
      }

      // Validate reason
      if (!reason || reason.trim().length === 0) {
        throw new Error('REASON_REQUIRED');
      }

      // Perform adjustment in a transaction
      const result = await db.transaction(async (client: PoolClient) => {
        // Get user's current wallet balance
        const wallets = await client.query(
          `SELECT id, user_id, balance FROM wallets WHERE user_id = $1`,
          [userId]
        );

        if (wallets.length === 0) {
          throw new Error('WALLET_NOT_FOUND');
        }

        const wallet = wallets[0];
        const balanceBefore = parseFloat(wallet.balance);

        // Check for sufficient balance if debiting
        if (amount < 0 && balanceBefore + amount < 0) {
          throw new Error('INSUFFICIENT_BALANCE');
        }

        const balanceAfter = balanceBefore + amount;

        // Determine action type
        const actionType =
          amount > 0
            ? AuditActionType.MANUAL_CREDIT
            : AuditActionType.MANUAL_DEBIT;

        // Generate transaction ID
        const date = new Date();
        const dateStr = `${date.getFullYear()}${String(date.getMonth() + 1).padStart(2, '0')}${String(date.getDate()).padStart(2, '0')}`;
        const randomDigits = Math.floor(100000 + Math.random() * 900000);
        const transactionId = `ADJ${dateStr}${randomDigits}`;

        // Update wallet balance
        const updatedWallets = await client.query(
          `UPDATE wallets
           SET balance = balance + $1, last_transaction_at = NOW(), updated_at = NOW()
           WHERE user_id = $2
           RETURNING id, user_id, balance, currency, last_transaction_at, updated_at`,
          [amount, userId]
        );

        // Create transaction record for tracking
        const transactionType =
          amount > 0 ? TransactionType.DEPOSIT : TransactionType.WITHDRAWAL;
        const transactions = await client.query(
          `INSERT INTO transactions (
            transaction_id, type, ${amount > 0 ? 'to_user_id' : 'from_user_id'},
            amount, fee, net_amount, status, description, metadata, processed_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
          RETURNING id, transaction_id, type, amount, status, description, created_at`,
          [
            transactionId,
            transactionType,
            userId,
            Math.abs(amount),
            0,
            Math.abs(amount),
            TransactionStatus.COMPLETED,
            reason,
            JSON.stringify({
              adjustmentType: 'manual',
              adminId,
              reason,
              notes,
            }),
          ]
        );

        // Create audit trail entry
        const auditEntries = await client.query<WalletAuditTrail>(
          `INSERT INTO wallet_audit_trail (
            user_id, admin_id, action_type, amount, balance_before,
            balance_after, reason, notes, transaction_id, ip_address
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
          RETURNING id, user_id, admin_id, action_type, amount, balance_before,
                    balance_after, reason, notes, transaction_id, ip_address, created_at`,
          [
            userId,
            adminId,
            actionType,
            amount,
            balanceBefore,
            balanceAfter,
            reason,
            notes || null,
            transactionId,
            ipAddress || null,
          ]
        );

        return {
          wallet: updatedWallets[0],
          auditEntry: auditEntries[0],
          transaction: transactions[0],
        };
      });

      logger.info('Balance adjusted successfully', {
        userId,
        adminId,
        amount,
        transactionId: result.transaction.transaction_id,
      });

      return result;
    } catch (error) {
      logger.error('Error adjusting balance', error);
      throw error;
    }
  }

  /**
   * Get audit trail statistics
   */
  static async getAuditStatistics(): Promise<any> {
    try {
      const stats = await db.query(
        `SELECT
          action_type,
          COUNT(*) as count,
          SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as total_credits,
          SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END) as total_debits,
          COUNT(DISTINCT user_id) as affected_users,
          COUNT(DISTINCT admin_id) as admins
         FROM wallet_audit_trail
         GROUP BY action_type`
      );

      return stats;
    } catch (error) {
      logger.error('Error getting audit statistics', error);
      throw error;
    }
  }
}
