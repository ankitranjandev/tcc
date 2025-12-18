import db from '../database';
import logger from '../utils/logger';
import * as crypto from 'crypto';

export interface AgentBankDetails {
  id?: string;
  agent_id: string;
  bank_name: string;
  branch_address: string;
  ifsc_code: string;
  account_holder_name: string;
  account_number?: string;
  account_type?: 'SAVINGS' | 'CURRENT';
  is_primary?: boolean;
  is_verified?: boolean;
  verified_by?: string;
  verified_at?: Date;
  verification_notes?: string;
  created_at?: Date;
  updated_at?: Date;
}

export interface BankDetailsSubmission {
  bank_name: string;
  branch_address: string;
  ifsc_code: string;
  account_holder_name: string;
  account_number?: string;
  account_type?: 'SAVINGS' | 'CURRENT';
}

export class AgentBankDetailsService {
  // Encryption key - should be stored in environment variables
  private static ENCRYPTION_KEY = process.env.BANK_ENCRYPTION_KEY || 'default-key-change-in-production';
  private static ENCRYPTION_ALGORITHM = 'aes-256-cbc';

  /**
   * Encrypt sensitive bank account number
   */
  private static encryptAccountNumber(accountNumber: string): string {
    if (!accountNumber) return '';

    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv(
      this.ENCRYPTION_ALGORITHM,
      crypto.scryptSync(this.ENCRYPTION_KEY, 'salt', 32),
      iv
    );

    let encrypted = cipher.update(accountNumber, 'utf8', 'hex');
    encrypted += cipher.final('hex');

    return iv.toString('hex') + ':' + encrypted;
  }

  /**
   * Decrypt bank account number
   */
  private static decryptAccountNumber(encryptedAccount: string): string {
    if (!encryptedAccount) return '';

    const [ivHex, encrypted] = encryptedAccount.split(':');
    const iv = Buffer.from(ivHex, 'hex');

    const decipher = crypto.createDecipheriv(
      this.ENCRYPTION_ALGORITHM,
      crypto.scryptSync(this.ENCRYPTION_KEY, 'salt', 32),
      iv
    );

    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');

    return decrypted;
  }

  /**
   * Submit or update bank details for an agent
   */
  static async submitBankDetails(
    agentId: string,
    bankDetails: BankDetailsSubmission
  ): Promise<AgentBankDetails> {
    try {
      // Check if agent exists
      const agents = await db.query(
        'SELECT id FROM agents WHERE id = $1',
        [agentId]
      );

      if (agents.length === 0) {
        throw new Error('AGENT_NOT_FOUND');
      }

      // Encrypt account number if provided
      const encryptedAccountNumber = bankDetails.account_number
        ? this.encryptAccountNumber(bankDetails.account_number)
        : null;

      // Check if agent already has bank details
      const existingDetails = await db.query<AgentBankDetails>(
        'SELECT id FROM agent_bank_details WHERE agent_id = $1',
        [agentId]
      );

      let result: AgentBankDetails;

      if (existingDetails.length > 0) {
        // Update existing bank details
        const updateResult = await db.query<AgentBankDetails>(
          `UPDATE agent_bank_details SET
            bank_name = $2,
            branch_address = $3,
            ifsc_code = $4,
            account_holder_name = $5,
            account_number = $6,
            account_type = $7,
            updated_at = NOW()
          WHERE agent_id = $1
          RETURNING *`,
          [
            agentId,
            bankDetails.bank_name,
            bankDetails.branch_address,
            bankDetails.ifsc_code,
            bankDetails.account_holder_name,
            encryptedAccountNumber,
            bankDetails.account_type || 'SAVINGS'
          ]
        );
        result = updateResult[0];
      } else {
        // Insert new bank details
        const insertResult = await db.query<AgentBankDetails>(
          `INSERT INTO agent_bank_details (
            agent_id,
            bank_name,
            branch_address,
            ifsc_code,
            account_holder_name,
            account_number,
            account_type,
            is_primary
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
          RETURNING *`,
          [
            agentId,
            bankDetails.bank_name,
            bankDetails.branch_address,
            bankDetails.ifsc_code,
            bankDetails.account_holder_name,
            encryptedAccountNumber,
            bankDetails.account_type || 'SAVINGS',
            true // First bank account is primary by default
          ]
        );
        result = insertResult[0];
      }

      // Don't return encrypted account number
      if (result.account_number) {
        result.account_number = '****' + bankDetails.account_number?.slice(-4);
      }

      logger.info('Bank details submitted for agent', { agentId });
      return result;
    } catch (error) {
      logger.error('Error submitting bank details', error);
      throw error;
    }
  }

  /**
   * Get bank details for an agent
   */
  static async getBankDetails(agentId: string): Promise<AgentBankDetails | null> {
    try {
      const result = await db.query<AgentBankDetails>(
        `SELECT
          id,
          agent_id,
          bank_name,
          branch_address,
          ifsc_code,
          account_holder_name,
          account_type,
          is_primary,
          is_verified,
          verified_at,
          created_at,
          updated_at
        FROM agent_bank_details
        WHERE agent_id = $1 AND is_primary = true`,
        [agentId]
      );

      if (result.length === 0) {
        return null;
      }

      const bankDetails = result[0];

      // Don't return the actual account number for security
      // Just indicate if it exists
      return {
        ...bankDetails,
        account_number: bankDetails.account_number ? '****' : undefined
      };
    } catch (error) {
      logger.error('Error getting bank details', error);
      throw error;
    }
  }

  /**
   * Get all bank details for admin review
   */
  static async getAllBankDetailsForAdmin(
    limit: number = 20,
    offset: number = 0
  ): Promise<{ details: AgentBankDetails[]; total: number }> {
    try {
      // Get total count
      const countResult = await db.query<{ count: number }>(
        'SELECT COUNT(*) as count FROM agent_bank_details'
      );
      const total = parseInt(countResult[0].count.toString());

      // Get bank details with agent information
      const result = await db.query<AgentBankDetails & {
        agent_name: string;
        agent_email: string;
      }>(
        `SELECT
          abd.*,
          CONCAT(u.first_name, ' ', u.last_name) as agent_name,
          u.email as agent_email
        FROM agent_bank_details abd
        JOIN agents a ON abd.agent_id = a.id
        JOIN users u ON a.user_id = u.id
        ORDER BY abd.created_at DESC
        LIMIT $1 OFFSET $2`,
        [limit, offset]
      );

      // Mask account numbers for security
      const details = result.map(detail => ({
        ...detail,
        account_number: detail.account_number ? '****' : undefined
      }));

      return { details, total };
    } catch (error) {
      logger.error('Error getting all bank details', error);
      throw error;
    }
  }

  /**
   * Verify bank details by admin
   */
  static async verifyBankDetails(
    bankDetailsId: string,
    adminId: string,
    isVerified: boolean,
    notes?: string
  ): Promise<AgentBankDetails> {
    try {
      const result = await db.query<AgentBankDetails>(
        `UPDATE agent_bank_details SET
          is_verified = $2,
          verified_by = $3,
          verified_at = $4,
          verification_notes = $5,
          updated_at = NOW()
        WHERE id = $1
        RETURNING *`,
        [
          bankDetailsId,
          isVerified,
          adminId,
          isVerified ? new Date() : null,
          notes
        ]
      );

      if (result.length === 0) {
        throw new Error('BANK_DETAILS_NOT_FOUND');
      }

      logger.info('Bank details verification updated', {
        bankDetailsId,
        adminId,
        isVerified
      });

      return result[0];
    } catch (error) {
      logger.error('Error verifying bank details', error);
      throw error;
    }
  }

  /**
   * Delete bank details
   */
  static async deleteBankDetails(
    bankDetailsId: string,
    agentId: string
  ): Promise<boolean> {
    try {
      const result = await db.getPool().query(
        'DELETE FROM agent_bank_details WHERE id = $1 AND agent_id = $2',
        [bankDetailsId, agentId]
      );

      return (result.rowCount ?? 0) > 0;
    } catch (error) {
      logger.error('Error deleting bank details', error);
      throw error;
    }
  }
}