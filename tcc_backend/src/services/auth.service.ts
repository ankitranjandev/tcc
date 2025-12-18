import { v4 as uuidv4 } from 'uuid';
import db from '../database';
import { PasswordUtils } from '../utils/password';
import { JWTUtils } from '../utils/jwt';
import { OTPService } from './otp.service';
import logger from '../utils/logger';
import config from '../config';
import { User, UserRole, RefreshToken } from '../types';

export class AuthService {
  /**
   * Generate unique referral code
   */
  private static async generateReferralCode(): Promise<string> {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code = '';

    for (let i = 0; i < 8; i++) {
      code += characters.charAt(Math.floor(Math.random() * characters.length));
    }

    // Check if code exists
    const existing = await db.query('SELECT id FROM users WHERE referral_code = $1', [code]);

    if (existing.length > 0) {
      return this.generateReferralCode(); // Recursive call if collision
    }

    return code;
  }

  /**
   * Register a new user
   */
  static async register(data: {
    first_name: string;
    last_name: string;
    email: string;
    phone: string;
    country_code: string;
    password: string;
    role?: UserRole;
    referral_code?: string;
  }): Promise<{ user: Partial<User>; otpExpiresIn: number }> {
    try {
      // Check if email already exists
      const emailExists = await db.query('SELECT id FROM users WHERE email = $1', [data.email]);
      if (emailExists.length > 0) {
        throw new Error('EMAIL_ALREADY_EXISTS');
      }

      // Check if phone already exists
      const phoneExists = await db.query(
        'SELECT id FROM users WHERE phone = $1 AND country_code = $2',
        [data.phone, data.country_code]
      );
      if (phoneExists.length > 0) {
        throw new Error('PHONE_ALREADY_EXISTS');
      }

      // Verify referral code if provided
      let referredBy = null;
      if (data.referral_code) {
        const referrer = await db.query<User>(
          'SELECT id FROM users WHERE referral_code = $1',
          [data.referral_code]
        );
        if (referrer.length === 0) {
          throw new Error('INVALID_REFERRAL_CODE');
        }
        referredBy = referrer[0].id;
      }

      // Hash password
      const passwordHash = await PasswordUtils.hash(data.password);

      // Generate referral code for new user
      const referralCode = await this.generateReferralCode();

      // Create user
      const users = await db.query<User>(
        `INSERT INTO users (
          first_name, last_name, email, phone, country_code,
          password_hash, role, referral_code, referred_by
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING id, first_name, last_name, email, phone, country_code,
                  role, kyc_status, is_active, created_at`,
        [
          data.first_name,
          data.last_name,
          data.email,
          data.phone,
          data.country_code,
          passwordHash,
          data.role || UserRole.USER,
          referralCode,
          referredBy,
        ]
      );

      const user = users[0];

      // Create wallet for user
      await db.query(
        'INSERT INTO wallets (user_id, balance, currency) VALUES ($1, 0, $2)',
        [user.id, 'SLL']
      );

      // Generate and send OTP
      const { expiresIn } = await OTPService.createOTP(
        data.phone,
        data.country_code,
        'REGISTRATION'
      );
      await OTPService.sendOTP(data.phone, data.country_code, data.phone);

      logger.info('User registered', { userId: user.id, email: data.email });

      return { user, otpExpiresIn: expiresIn };
    } catch (error) {
      logger.error('Error in register', error);
      throw error;
    }
  }

  /**
   * Login user - returns OTP requirement
   */
  static async login(emailOrPhone: string, password: string): Promise<{
    requiresOTP: boolean;
    phone?: string;
    userId?: string;
    otpExpiresIn?: number;
  }> {
    try {
      logger.info('Login attempt', { emailOrPhone, passwordLength: password?.length });

      // Determine if input is email or phone
      const isEmail = emailOrPhone.includes('@');

      // Get user by email or phone
      let users: User[];
      if (isEmail) {
        users = await db.query<User>(
          `SELECT id, email, phone, country_code, password_hash, is_active,
                  locked_until, failed_login_attempts
           FROM users WHERE email = $1`,
          [emailOrPhone]
        );
      } else {
        // Assume it's a phone number - try with common country codes or require full format
        // For now, we'll try to match just the phone number without country code
        users = await db.query<User>(
          `SELECT id, email, phone, country_code, password_hash, is_active,
                  locked_until, failed_login_attempts
           FROM users WHERE phone = $1`,
          [emailOrPhone]
        );
      }

      logger.info('User query result', { found: users.length, emailOrPhone, isEmail });

      if (users.length === 0) {
        logger.warn('No user found', { emailOrPhone });
        throw new Error('INVALID_CREDENTIALS');
      }

      const user = users[0];
      logger.info('User found', {
        userId: user.id,
        email: user.email,
        isActive: user.is_active,
        hasPasswordHash: !!user.password_hash,
        passwordHashLength: user.password_hash?.length
      });

      // Check if account is locked
      if (user.locked_until && new Date(user.locked_until) > new Date()) {
        logger.warn('Account locked', { userId: user.id, lockedUntil: user.locked_until });
        throw new Error('ACCOUNT_LOCKED');
      }

      // Check if account is active
      if (!user.is_active) {
        logger.warn('Account inactive', { userId: user.id });
        throw new Error('ACCOUNT_INACTIVE');
      }

      // Verify password
      logger.info('Attempting password verification', { userId: user.id });
      const isValidPassword = await PasswordUtils.compare(password, user.password_hash);
      logger.info('Password verification result', { userId: user.id, isValid: isValidPassword });

      if (!isValidPassword) {
        // Increment failed attempts
        const attempts = user.failed_login_attempts + 1;
        const lockedUntil =
          attempts >= config.security.maxLoginAttempts
            ? new Date(Date.now() + config.security.accountLockoutMinutes * 60 * 1000)
            : null;

        await db.query(
          'UPDATE users SET failed_login_attempts = $1, locked_until = $2 WHERE id = $3',
          [attempts, lockedUntil, user.id]
        );

        throw new Error('INVALID_CREDENTIALS');
      }

      // Reset failed attempts
      await db.query(
        'UPDATE users SET failed_login_attempts = 0, locked_until = NULL WHERE id = $1',
        [user.id]
      );

      // Generate and send OTP
      const { expiresIn } = await OTPService.createOTP(user.phone, user.country_code, 'LOGIN');
      await OTPService.sendOTP(user.phone, user.country_code, user.phone);

      // Mask phone number
      const maskedPhone = `****${user.phone.slice(-4)}`;

      logger.info('Login OTP sent', { userId: user.id, emailOrPhone });

      return {
        requiresOTP: true,
        phone: maskedPhone,
        userId: user.id,
        otpExpiresIn: expiresIn,
      };
    } catch (error) {
      logger.error('Error in login', error);
      throw error;
    }
  }

  /**
   * Verify OTP and complete login
   */
  static async verifyOTPAndLogin(
    phone: string,
    countryCode: string,
    otp: string,
    purpose: 'REGISTRATION' | 'LOGIN'
  ): Promise<{
    accessToken: string;
    refreshToken: string;
    expiresIn: number;
    user: Partial<User>;
  }> {
    try {
      // Verify OTP
      const otpResult = await OTPService.verifyOTP(phone, countryCode, otp, purpose);

      if (!otpResult.valid) {
        throw new Error(otpResult.error || 'INVALID_OTP');
      }

      // Get user
      const users = await db.query<User>(
        `SELECT id, first_name, last_name, email, phone, country_code, role,
                kyc_status, is_active, profile_picture_url
         FROM users WHERE phone = $1 AND country_code = $2`,
        [phone, countryCode]
      );

      if (users.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      const user = users[0];

      // Mark user as verified and active
      await db.query(
        'UPDATE users SET phone_verified = true, is_verified = true, is_active = true, last_login_at = NOW() WHERE id = $1',
        [user.id]
      );

      // Generate tokens
      const accessToken = JWTUtils.generateAccessToken(user.id, user.role, user.email);

      const refreshToken = JWTUtils.generateRefreshToken(user.id, user.role, user.email);

      // Store refresh token
      await this.storeRefreshToken(user.id, refreshToken);

      logger.info('User logged in', { userId: user.id, email: user.email });

      return {
        accessToken,
        refreshToken,
        expiresIn: 3600, // 1 hour
        user: {
          id: user.id,
          first_name: user.first_name,
          last_name: user.last_name,
          email: user.email,
          phone: user.phone,
          role: user.role,
          kyc_status: user.kyc_status,
          is_active: user.is_active,
          profile_picture_url: user.profile_picture_url,
        },
      };
    } catch (error) {
      logger.error('Error in verifyOTPAndLogin', error);
      throw error;
    }
  }

  /**
   * Store refresh token
   */
  private static async storeRefreshToken(userId: string, token: string): Promise<void> {
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

    await db.query(
      'INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES ($1, $2, $3)',
      [userId, token, expiresAt]
    );
  }

  /**
   * Refresh access token
   */
  static async refreshAccessToken(refreshToken: string): Promise<{
    accessToken: string;
    refreshToken: string;
    expiresIn: number;
  }> {
    try {
      // Verify refresh token
      const payload = JWTUtils.verifyRefreshToken(refreshToken);

      // Check if refresh token exists in database
      const tokens = await db.query<RefreshToken>(
        'SELECT * FROM refresh_tokens WHERE token = $1 AND user_id = $2',
        [refreshToken, payload.sub]
      );

      if (tokens.length === 0) {
        throw new Error('INVALID_REFRESH_TOKEN');
      }

      const tokenRecord = tokens[0];

      // Check if expired
      if (new Date() > new Date(tokenRecord.expires_at)) {
        throw new Error('REFRESH_TOKEN_EXPIRED');
      }

      // Generate new tokens
      const newAccessToken = JWTUtils.generateAccessToken(payload.sub, payload.role, payload.email);

      const newRefreshToken = JWTUtils.generateRefreshToken(payload.sub, payload.role, payload.email);

      // Delete old refresh token and store new one
      await db.query('DELETE FROM refresh_tokens WHERE token = $1', [refreshToken]);
      await this.storeRefreshToken(payload.sub, newRefreshToken);

      return {
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
        expiresIn: 3600,
      };
    } catch (error) {
      logger.error('Error refreshing token', error);
      throw error;
    }
  }

  /**
   * Logout user
   */
  static async logout(userId: string, refreshToken: string): Promise<void> {
    try {
      await db.query('DELETE FROM refresh_tokens WHERE user_id = $1 AND token = $2', [
        userId,
        refreshToken,
      ]);
      logger.info('User logged out', { userId });
    } catch (error) {
      logger.error('Error in logout', error);
      throw error;
    }
  }

  /**
   * Forgot password - send OTP
   */
  static async forgotPassword(email: string): Promise<{ phone: string; otpExpiresIn: number }> {
    try {
      // Get user
      const users = await db.query<User>(
        'SELECT id, phone, country_code FROM users WHERE email = $1',
        [email]
      );

      if (users.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      const user = users[0];

      // Generate and send OTP
      const { expiresIn } = await OTPService.createOTP(
        user.phone,
        user.country_code,
        'PASSWORD_RESET'
      );
      await OTPService.sendOTP(user.phone, user.country_code, user.phone);

      // Mask phone
      const maskedPhone = `****${user.phone.slice(-4)}`;

      logger.info('Password reset OTP sent', { userId: user.id, email });

      return { phone: maskedPhone, otpExpiresIn: expiresIn };
    } catch (error) {
      logger.error('Error in forgotPassword', error);
      throw error;
    }
  }

  /**
   * Reset password with OTP
   */
  static async resetPassword(
    phone: string,
    countryCode: string,
    otp: string,
    newPassword: string
  ): Promise<void> {
    try {
      // Verify OTP
      const otpResult = await OTPService.verifyOTP(phone, countryCode, otp, 'PASSWORD_RESET');

      if (!otpResult.valid) {
        throw new Error(otpResult.error || 'INVALID_OTP');
      }

      // Hash new password
      const passwordHash = await PasswordUtils.hash(newPassword);

      // Update password
      await db.query(
        'UPDATE users SET password_hash = $1, password_changed_at = NOW() WHERE phone = $2 AND country_code = $3',
        [passwordHash, phone, countryCode]
      );

      logger.info('Password reset successful', { phone });
    } catch (error) {
      logger.error('Error in resetPassword', error);
      throw error;
    }
  }

  /**
   * Resend OTP
   */
  static async resendOTP(
    phone: string,
    countryCode: string
  ): Promise<{ otpExpiresIn: number; retryAfter: number }> {
    try {
      // Check if recent OTP was sent (rate limiting)
      const recentOTP = await db.query(
        `SELECT created_at, purpose FROM otps
         WHERE phone = $1 AND country_code = $2
         ORDER BY created_at DESC LIMIT 1`,
        [phone, countryCode]
      );

      if (recentOTP.length > 0) {
        const lastOTPTime = new Date((recentOTP[0] as any).created_at).getTime();
        const now = Date.now();
        const timeSinceLastOTP = (now - lastOTPTime) / 1000; // seconds

        if (timeSinceLastOTP < 60) {
          // Must wait 60 seconds
          throw new Error('RATE_LIMIT_EXCEEDED');
        }
      }

      // Generate and send new OTP (purpose will be determined from last OTP)
      const lastPurpose = recentOTP.length > 0 ? (recentOTP[0] as any).purpose : 'REGISTRATION';
      const { expiresIn } = await OTPService.createOTP(phone, countryCode, lastPurpose);
      await OTPService.sendOTP(phone, countryCode, phone);

      logger.info('OTP resent', { phone });

      return { otpExpiresIn: expiresIn, retryAfter: 60 };
    } catch (error) {
      logger.error('Error in resendOTP', error);
      throw error;
    }
  }

  /**
   * Direct login without OTP - FOR DEVELOPMENT ONLY
   * This method bypasses OTP verification and logs in the user directly
   */
  static async loginDirect(emailOrPhone: string, password: string): Promise<{
    accessToken: string;
    refreshToken: string;
    expiresIn: number;
    user: Partial<User>;
  }> {
    try {
      // Only allow in development environment
      if (config.env !== 'development') {
        throw new Error('DIRECT_LOGIN_NOT_ALLOWED');
      }

      logger.info('Direct login attempt (DEV MODE)', { emailOrPhone });

      // Determine if input is email or phone
      const isEmail = emailOrPhone.includes('@');

      // Get user by email or phone
      let users: User[];
      if (isEmail) {
        users = await db.query<User>(
          `SELECT id, first_name, last_name, email, phone, country_code, password_hash,
                  is_active, role, kyc_status, profile_picture_url
           FROM users WHERE email = $1`,
          [emailOrPhone]
        );
      } else {
        users = await db.query<User>(
          `SELECT id, first_name, last_name, email, phone, country_code, password_hash,
                  is_active, role, kyc_status, profile_picture_url
           FROM users WHERE phone = $1`,
          [emailOrPhone]
        );
      }

      if (users.length === 0) {
        throw new Error('INVALID_CREDENTIALS');
      }

      const user = users[0];

      // Check if account is active
      if (!user.is_active) {
        throw new Error('ACCOUNT_INACTIVE');
      }

      // Verify password
      const isValidPassword = await PasswordUtils.compare(password, user.password_hash);

      if (!isValidPassword) {
        throw new Error('INVALID_CREDENTIALS');
      }

      // Mark user as verified (skip OTP in dev mode)
      await db.query(
        'UPDATE users SET phone_verified = true, email_verified = true, is_verified = true, last_login_at = NOW() WHERE id = $1',
        [user.id]
      );

      // Generate tokens
      const accessToken = JWTUtils.generateAccessToken(user.id, user.role, user.email);
      const refreshTokenValue = JWTUtils.generateRefreshToken(user.id, user.role, user.email);

      // Store refresh token
      await db.query(
        `INSERT INTO refresh_tokens (user_id, token, expires_at)
         VALUES ($1, $2, NOW() + INTERVAL '${config.jwt.refreshExpiresIn}')`,
        [user.id, refreshTokenValue]
      );

      logger.info('Direct login successful (DEV MODE)', { userId: user.id, emailOrPhone });

      // Parse expiresIn to seconds (e.g., "1h" -> 3600)
      const expiresInSeconds = config.jwt.expiresIn === '1h' ? 3600 : 3600;

      return {
        accessToken,
        refreshToken: refreshTokenValue,
        expiresIn: expiresInSeconds,
        user: {
          id: user.id,
          first_name: user.first_name,
          last_name: user.last_name,
          email: user.email,
          phone: user.phone,
          country_code: user.country_code,
          role: user.role,
          kyc_status: user.kyc_status,
          profile_picture_url: user.profile_picture_url,
        },
      };
    } catch (error) {
      logger.error('Error in loginDirect', error);
      throw error;
    }
  }
}
