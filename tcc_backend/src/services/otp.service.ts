import { randomInt } from 'crypto';
import db from '../database';
import config from '../config';
import logger from '../utils/logger';
import { OTP } from '../types';

export class OTPService {
  /**
   * Generate a random OTP
   */
  private static generateOTP(): string {
    const length = config.security.otpLength;
    const min = Math.pow(10, length - 1);
    const max = Math.pow(10, length) - 1;
    return randomInt(min, max + 1).toString();
  }

  /**
   * Create and store an OTP
   */
  static async createOTP(
    phone: string,
    countryCode: string,
    purpose: OTP['purpose']
  ): Promise<{ otp: string; expiresIn: number }> {
    try {
      const otp = this.generateOTP();
      const expiresAt = new Date(Date.now() + config.security.otpExpiryMinutes * 60 * 1000);

      // Delete any existing OTPs for this phone and purpose
      await db.query(
        'DELETE FROM otps WHERE phone = $1 AND country_code = $2 AND purpose = $3',
        [phone, countryCode, purpose]
      );

      // Insert new OTP
      await db.query(
        `INSERT INTO otps (phone, country_code, otp, purpose, expires_at, attempts, is_verified)
         VALUES ($1, $2, $3, $4, $5, 0, false)`,
        [phone, countryCode, otp, purpose, expiresAt]
      );

      logger.info('OTP created', { phone, purpose });

      // In development, log the OTP
      if (config.env === 'development') {
        logger.debug('OTP for development', { phone, otp });
      }

      return {
        otp,
        expiresIn: config.security.otpExpiryMinutes * 60,
      };
    } catch (error) {
      logger.error('Error creating OTP', error);
      throw new Error('Failed to create OTP');
    }
  }

  /**
   * Verify an OTP
   */
  static async verifyOTP(
    phone: string,
    countryCode: string,
    otp: string,
    purpose: OTP['purpose']
  ): Promise<{ valid: boolean; error?: string }> {
    try {
      // Get the OTP
      const otpRecords = await db.query<OTP>(
        `SELECT * FROM otps
         WHERE phone = $1 AND country_code = $2 AND purpose = $3
         ORDER BY created_at DESC LIMIT 1`,
        [phone, countryCode, purpose]
      );

      if (otpRecords.length === 0) {
        return { valid: false, error: 'OTP not found or expired' };
      }

      const otpRecord = otpRecords[0];

      // Check if OTP is already verified
      if (otpRecord.is_verified) {
        return { valid: false, error: 'OTP already used' };
      }

      // Check if OTP is expired
      if (new Date() > new Date(otpRecord.expires_at)) {
        return { valid: false, error: 'OTP expired' };
      }

      // Check if too many attempts
      if (otpRecord.attempts >= 3) {
        return { valid: false, error: 'Too many failed attempts. Please request a new OTP' };
      }

      // Verify OTP
      if (otpRecord.otp !== otp) {
        // Increment attempts
        await db.query('UPDATE otps SET attempts = attempts + 1 WHERE id = $1', [otpRecord.id]);
        return { valid: false, error: 'Invalid OTP' };
      }

      // Mark OTP as verified
      await db.query('UPDATE otps SET is_verified = true WHERE id = $1', [otpRecord.id]);

      logger.info('OTP verified successfully', { phone, purpose });

      return { valid: true };
    } catch (error) {
      logger.error('Error verifying OTP', error);
      throw new Error('Failed to verify OTP');
    }
  }

  /**
   * Send OTP via SMS
   */
  static async sendOTP(phone: string, countryCode: string, otp: string): Promise<boolean> {
    try {
      // TODO: Integrate with SMS provider (Twilio, Africa's Talking, etc.)
      logger.info('Sending OTP via SMS', { phone, countryCode });

      // For development, just log
      if (config.env === 'development') {
        logger.info('SMS OTP (development)', { phone, otp });
        return true;
      }

      // Production SMS sending logic would go here
      return true;
    } catch (error) {
      logger.error('Error sending OTP', error);
      return false;
    }
  }

  /**
   * Clean up expired OTPs
   */
  static async cleanupExpiredOTPs(): Promise<void> {
    try {
      const result = await db.query('DELETE FROM otps WHERE expires_at < NOW()');
      logger.info('Cleaned up expired OTPs', { count: result.length });
    } catch (error) {
      logger.error('Error cleaning up OTPs', error);
    }
  }
}
