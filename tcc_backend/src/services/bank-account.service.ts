import db from '../database';
import logger from '../utils/logger';

export interface BankAccount {
  id: string;
  user_id: string;
  bank_name: string;
  branch_address?: string;
  account_number: string;
  account_holder_name: string;
  swift_code?: string;
  routing_number?: string;
  is_primary: boolean;
  is_verified: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface BankAccountInput {
  bank_name: string;
  branch_address?: string;
  account_number: string;
  account_holder_name: string;
  swift_code?: string;
  routing_number?: string;
  is_primary?: boolean;
}

export class BankAccountService {
  /**
   * Create bank account
   */
  static async createBankAccount(
    userId: string,
    accountData: BankAccountInput
  ): Promise<BankAccount> {
    const client = await db.getPool().connect();
    try {
      await client.query('BEGIN');

      // Check if user exists
      const userCheck = await client.query(
        'SELECT id FROM users WHERE id = $1',
        [userId]
      );

      if (userCheck.rows.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      // If this is primary, unset other primary accounts
      if (accountData.is_primary) {
        await client.query(
          'UPDATE bank_accounts SET is_primary = FALSE WHERE user_id = $1',
          [userId]
        );
      }

      // Insert new bank account
      const result = await client.query(
        `INSERT INTO bank_accounts (
          user_id, bank_name, branch_address, account_number,
          account_holder_name, swift_code, routing_number, is_primary
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING *`,
        [
          userId,
          accountData.bank_name,
          accountData.branch_address || null,
          accountData.account_number,
          accountData.account_holder_name,
          accountData.swift_code || null,
          accountData.routing_number || null,
          accountData.is_primary || false,
        ]
      );

      await client.query('COMMIT');

      logger.info('Bank account created', { userId, accountId: result.rows[0].id });

      return result.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Create bank account error', error);
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Get user's bank accounts
   */
  static async getUserBankAccounts(userId: string): Promise<BankAccount[]> {
    try {
      const result = await db.getPool().query(
        `SELECT * FROM bank_accounts
         WHERE user_id = $1
         ORDER BY is_primary DESC, created_at DESC`,
        [userId]
      );

      return result.rows;
    } catch (error) {
      logger.error('Get user bank accounts error', error);
      throw error;
    }
  }

  /**
   * Get specific bank account
   */
  static async getBankAccountById(accountId: string, userId: string): Promise<BankAccount | null> {
    try {
      const result = await db.getPool().query(
        'SELECT * FROM bank_accounts WHERE id = $1 AND user_id = $2',
        [accountId, userId]
      );

      return result.rows[0] || null;
    } catch (error) {
      logger.error('Get bank account error', error);
      throw error;
    }
  }

  /**
   * Update bank account
   */
  static async updateBankAccount(
    accountId: string,
    userId: string,
    updates: Partial<BankAccountInput>
  ): Promise<BankAccount> {
    const client = await db.getPool().connect();
    try {
      await client.query('BEGIN');

      // Check if account exists and belongs to user
      const existingAccount = await client.query(
        'SELECT * FROM bank_accounts WHERE id = $1 AND user_id = $2',
        [accountId, userId]
      );

      if (existingAccount.rows.length === 0) {
        throw new Error('ACCOUNT_NOT_FOUND');
      }

      // If setting as primary, unset other primary accounts
      if (updates.is_primary) {
        await client.query(
          'UPDATE bank_accounts SET is_primary = FALSE WHERE user_id = $1 AND id != $2',
          [userId, accountId]
        );
      }

      // Build update query dynamically
      const updateFields: string[] = [];
      const updateValues: any[] = [];
      let paramCount = 1;

      if (updates.bank_name !== undefined) {
        updateFields.push(`bank_name = $${paramCount++}`);
        updateValues.push(updates.bank_name);
      }
      if (updates.branch_address !== undefined) {
        updateFields.push(`branch_address = $${paramCount++}`);
        updateValues.push(updates.branch_address);
      }
      if (updates.account_number !== undefined) {
        updateFields.push(`account_number = $${paramCount++}`);
        updateValues.push(updates.account_number);
      }
      if (updates.account_holder_name !== undefined) {
        updateFields.push(`account_holder_name = $${paramCount++}`);
        updateValues.push(updates.account_holder_name);
      }
      if (updates.swift_code !== undefined) {
        updateFields.push(`swift_code = $${paramCount++}`);
        updateValues.push(updates.swift_code);
      }
      if (updates.routing_number !== undefined) {
        updateFields.push(`routing_number = $${paramCount++}`);
        updateValues.push(updates.routing_number);
      }
      if (updates.is_primary !== undefined) {
        updateFields.push(`is_primary = $${paramCount++}`);
        updateValues.push(updates.is_primary);
      }

      if (updateFields.length === 0) {
        throw new Error('NO_UPDATES_PROVIDED');
      }

      updateFields.push(`updated_at = CURRENT_TIMESTAMP`);
      updateValues.push(accountId, userId);

      const result = await client.query(
        `UPDATE bank_accounts
         SET ${updateFields.join(', ')}
         WHERE id = $${paramCount++} AND user_id = $${paramCount}
         RETURNING *`,
        updateValues
      );

      await client.query('COMMIT');

      logger.info('Bank account updated', { userId, accountId });

      return result.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Update bank account error', error);
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Delete bank account
   */
  static async deleteBankAccount(accountId: string, userId: string): Promise<boolean> {
    try {
      const result = await db.getPool().query(
        'DELETE FROM bank_accounts WHERE id = $1 AND user_id = $2 RETURNING id',
        [accountId, userId]
      );

      if (result.rows.length === 0) {
        throw new Error('ACCOUNT_NOT_FOUND');
      }

      logger.info('Bank account deleted', { userId, accountId });

      return true;
    } catch (error) {
      logger.error('Delete bank account error', error);
      throw error;
    }
  }

  /**
   * Set primary bank account
   */
  static async setPrimaryAccount(accountId: string, userId: string): Promise<BankAccount> {
    const client = await db.getPool().connect();
    try {
      await client.query('BEGIN');

      // Check if account exists
      const accountCheck = await client.query(
        'SELECT * FROM bank_accounts WHERE id = $1 AND user_id = $2',
        [accountId, userId]
      );

      if (accountCheck.rows.length === 0) {
        throw new Error('ACCOUNT_NOT_FOUND');
      }

      // Unset all primary accounts for user
      await client.query(
        'UPDATE bank_accounts SET is_primary = FALSE WHERE user_id = $1',
        [userId]
      );

      // Set this account as primary
      const result = await client.query(
        `UPDATE bank_accounts
         SET is_primary = TRUE, updated_at = CURRENT_TIMESTAMP
         WHERE id = $1 AND user_id = $2
         RETURNING *`,
        [accountId, userId]
      );

      await client.query('COMMIT');

      logger.info('Primary bank account set', { userId, accountId });

      return result.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Set primary account error', error);
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Get user's bank accounts for admin view (with masked account numbers)
   */
  static async getUserBankAccountsForAdmin(userId: string): Promise<any[]> {
    try {
      const result = await db.getPool().query(
        `SELECT
          id,
          user_id,
          bank_name,
          CONCAT('****', RIGHT(account_number, 4)) as account_number_masked,
          account_holder_name,
          is_primary,
          is_verified,
          created_at,
          updated_at
         FROM bank_accounts
         WHERE user_id = $1
         ORDER BY is_primary DESC, created_at DESC`,
        [userId]
      );

      return result.rows;
    } catch (error) {
      logger.error('Get user bank accounts for admin error', error);
      throw error;
    }
  }

  /**
   * Mask account number for display
   */
  static maskAccountNumber(accountNumber: string): string {
    if (accountNumber.length <= 4) {
      return '****';
    }
    return `****${accountNumber.slice(-4)}`;
  }
}
