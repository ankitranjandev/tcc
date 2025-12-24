import db from '../database';
import { PasswordUtils } from '../utils/password';
import { OTPService } from './otp.service';
import logger from '../utils/logger';
import { User, Wallet } from '../types';

export class UserService {
  /**
   * Get user profile with wallet
   */
  static async getProfile(userId: string): Promise<{ user: Partial<User>; wallet: Partial<Wallet> }> {
    try {
      const users = await db.query<User>(
        `SELECT id, first_name, last_name, email, phone, country_code, role,
                kyc_status, profile_picture_url, is_active, email_verified,
                phone_verified, two_factor_enabled, created_at, updated_at
         FROM users WHERE id = $1`,
        [userId]
      );

      if (users.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      const user = users[0];

      const wallets = await db.query<Wallet>(
        'SELECT balance, currency FROM wallets WHERE user_id = $1',
        [userId]
      );

      const wallet = wallets[0] || { balance: 0, currency: 'SLL' };

      return { user, wallet };
    } catch (error) {
      logger.error('Error getting profile', error);
      throw error;
    }
  }

  /**
   * Update user profile
   */
  static async updateProfile(
    userId: string,
    data: {
      first_name?: string;
      last_name?: string;
      email?: string;
      profile_picture?: string;
    }
  ): Promise<Partial<User>> {
    try {
      const updates: string[] = [];
      const values: any[] = [];
      let paramCount = 1;

      if (data.first_name) {
        updates.push(`first_name = $${paramCount++}`);
        values.push(data.first_name);
      }

      if (data.last_name) {
        updates.push(`last_name = $${paramCount++}`);
        values.push(data.last_name);
      }

      if (data.email) {
        // Check if email is already taken by another user
        const existing = await db.query(
          'SELECT id FROM users WHERE email = $1 AND id != $2',
          [data.email, userId]
        );

        if (existing.length > 0) {
          throw new Error('EMAIL_ALREADY_EXISTS');
        }

        updates.push(`email = $${paramCount++}, email_verified = false`);
        values.push(data.email);
      }

      if (data.profile_picture) {
        // TODO: Upload to S3 and get URL
        const profilePictureUrl = data.profile_picture; // For now, assume it's a URL
        updates.push(`profile_picture_url = $${paramCount++}`);
        values.push(profilePictureUrl);
      }

      updates.push(`updated_at = NOW()`);
      values.push(userId);

      const query = `
        UPDATE users
        SET ${updates.join(', ')}
        WHERE id = $${paramCount}
        RETURNING id, first_name, last_name, email, profile_picture_url, updated_at
      `;

      const result = await db.query<User>(query, values);

      logger.info('Profile updated', { userId });

      return result[0];
    } catch (error) {
      logger.error('Error updating profile', error);
      throw error;
    }
  }

  /**
   * Change phone number
   */
  static async changePhone(
    userId: string,
    newPhone: string,
    countryCode: string,
    password: string
  ): Promise<{ otpSent: boolean; phone: string; otpExpiresIn: number }> {
    try {
      // Verify password
      const users = await db.query<User>(
        'SELECT password_hash FROM users WHERE id = $1',
        [userId]
      );

      if (users.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      const isValidPassword = await PasswordUtils.compare(password, users[0].password_hash);

      if (!isValidPassword) {
        throw new Error('INVALID_PASSWORD');
      }

      // Check if new phone already exists
      const phoneExists = await db.query(
        'SELECT id FROM users WHERE phone = $1 AND country_code = $2 AND id != $3',
        [newPhone, countryCode, userId]
      );

      if (phoneExists.length > 0) {
        throw new Error('PHONE_ALREADY_EXISTS');
      }

      // Generate and send OTP
      const { expiresIn } = await OTPService.createOTP(newPhone, countryCode, 'PHONE_CHANGE');
      await OTPService.sendOTP(newPhone, countryCode, newPhone);

      const maskedPhone = `****${newPhone.slice(-4)}`;

      logger.info('Phone change OTP sent', { userId });

      return { otpSent: true, phone: maskedPhone, otpExpiresIn: expiresIn };
    } catch (error) {
      logger.error('Error changing phone', error);
      throw error;
    }
  }

  /**
   * Verify phone change OTP and update phone
   */
  static async verifyPhoneChange(
    userId: string,
    phone: string,
    countryCode: string,
    otp: string
  ): Promise<void> {
    try {
      // Verify OTP
      const otpResult = await OTPService.verifyOTP(phone, countryCode, otp, 'PHONE_CHANGE');

      if (!otpResult.valid) {
        throw new Error(otpResult.error || 'INVALID_OTP');
      }

      // Update phone
      await db.query(
        'UPDATE users SET phone = $1, country_code = $2, phone_verified = true, updated_at = NOW() WHERE id = $3',
        [phone, countryCode, userId]
      );

      logger.info('Phone changed successfully', { userId });
    } catch (error) {
      logger.error('Error verifying phone change', error);
      throw error;
    }
  }

  /**
   * Change password
   */
  static async changePassword(
    userId: string,
    currentPassword: string,
    newPassword: string
  ): Promise<void> {
    try {
      // Get current password hash
      const users = await db.query<User>(
        'SELECT password_hash FROM users WHERE id = $1',
        [userId]
      );

      if (users.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      // Verify current password
      const isValidPassword = await PasswordUtils.compare(currentPassword, users[0].password_hash);

      if (!isValidPassword) {
        throw new Error('INVALID_CURRENT_PASSWORD');
      }

      // Hash new password
      const newPasswordHash = await PasswordUtils.hash(newPassword);

      // Update password
      await db.query(
        'UPDATE users SET password_hash = $1, password_changed_at = NOW(), updated_at = NOW() WHERE id = $2',
        [newPasswordHash, userId]
      );

      logger.info('Password changed', { userId });
    } catch (error) {
      logger.error('Error changing password', error);
      throw error;
    }
  }

  /**
   * Request account deletion
   */
  static async requestAccountDeletion(userId: string): Promise<{ scheduledFor: Date }> {
    try {
      const scheduledFor = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days

      await db.query(
        'UPDATE users SET deletion_requested_at = NOW(), deletion_scheduled_for = $1, updated_at = NOW() WHERE id = $2',
        [scheduledFor, userId]
      );

      logger.info('Account deletion requested', { userId, scheduledFor });

      return { scheduledFor };
    } catch (error) {
      logger.error('Error requesting account deletion', error);
      throw error;
    }
  }

  /**
   * Cancel account deletion
   */
  static async cancelAccountDeletion(userId: string): Promise<void> {
    try {
      await db.query(
        'UPDATE users SET deletion_requested_at = NULL, deletion_scheduled_for = NULL, updated_at = NOW() WHERE id = $1',
        [userId]
      );

      logger.info('Account deletion cancelled', { userId });
    } catch (error) {
      logger.error('Error cancelling account deletion', error);
      throw error;
    }
  }

  /**
   * Add bank account
   */
  static async addBankAccount(
    userId: string,
    data: {
      bank_name: string;
      account_number: string;
      account_holder_name: string;
      branch_address?: string;
      is_primary?: boolean;
    }
  ): Promise<any> {
    try {
      // If this is primary, unset other primary accounts
      if (data.is_primary) {
        await db.query('UPDATE bank_accounts SET is_primary = false WHERE user_id = $1', [userId]);
      }

      const result = await db.query(
        `INSERT INTO bank_accounts (
          user_id, bank_name, account_number, account_holder_name,
          branch_address, is_primary
        ) VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING id, bank_name, account_number, account_holder_name, is_primary, created_at`,
        [
          userId,
          data.bank_name,
          data.account_number,
          data.account_holder_name,
          data.branch_address,
          data.is_primary || false,
        ]
      );

      logger.info('Bank account added', { userId });

      return result[0];
    } catch (error) {
      logger.error('Error adding bank account', error);
      throw error;
    }
  }

  /**
   * Get user bank accounts
   */
  static async getBankAccounts(userId: string): Promise<any[]> {
    try {
      const accounts = await db.query(
        `SELECT id, bank_name, account_number, account_holder_name,
                branch_address, is_primary, is_verified, created_at
         FROM bank_accounts WHERE user_id = $1
         ORDER BY is_primary DESC, created_at DESC`,
        [userId]
      );

      return accounts;
    } catch (error) {
      logger.error('Error getting bank accounts', error);
      throw error;
    }
  }

  /**
   * Update user profile picture
   */
  static async updateProfilePicture(userId: string, profilePictureUrl: string): Promise<Partial<User>> {
    try {
      const result = await db.query<User>(
        `UPDATE users
         SET profile_picture_url = $1, updated_at = NOW()
         WHERE id = $2
         RETURNING id, first_name, last_name, email, phone, country_code,
                   profile_picture_url, kyc_status, created_at, updated_at`,
        [profilePictureUrl, userId]
      );

      if (result.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      logger.info('Profile picture updated', { userId, profilePictureUrl });

      return result[0];
    } catch (error) {
      logger.error('Error updating profile picture', error);
      throw error;
    }
  }
}
