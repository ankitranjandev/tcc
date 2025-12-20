import { Response } from 'express';
import { AuthRequest } from '../types';
import { AuthService } from '../services/auth.service';
import { OTPService } from '../services/otp.service';
import { ApiResponseUtil } from '../utils/response';
import logger from '../utils/logger';

export class AuthController {
  /**
   * Register a new user
   */
  static async register(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { first_name, last_name, email, phone, country_code, password, role, referral_code } =
        req.body;

      logger.info('📥 Registration endpoint called', {
        email,
        phone,
        country_code,
        first_name,
        last_name,
        hasReferralCode: !!referral_code,
        ip: req.ip,
        userAgent: req.headers['user-agent'],
      });

      const result = await AuthService.register({
        first_name,
        last_name,
        email,
        phone,
        country_code,
        password,
        role,
        referral_code,
      });

      logger.info('📤 Registration endpoint response', {
        success: true,
        userId: result.user.id,
        email: result.user.email,
        otpExpiresIn: result.otpExpiresIn,
      });

      return ApiResponseUtil.created(res, {
        user: result.user,
        otp_sent: true,
        otp_expires_in: result.otpExpiresIn,
      }, 'Registration successful. Please verify your phone number.');
    } catch (error: any) {
      logger.error('❌ Register endpoint error', { 
        error: error.message,
        stack: error.stack,
        email: req.body.email,
        phone: req.body.phone 
      });

      if (error.message === 'EMAIL_ALREADY_EXISTS') {
        return ApiResponseUtil.conflict(res, 'Email already registered');
      }

      if (error.message === 'PHONE_ALREADY_EXISTS') {
        return ApiResponseUtil.conflict(res, 'Phone number already registered');
      }

      if (error.message === 'INVALID_REFERRAL_CODE') {
        return ApiResponseUtil.badRequest(res, 'Invalid referral code');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Verify OTP after registration or login
   */
  static async verifyOTP(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { phone, country_code, otp, purpose } = req.body;

      logger.info('📥 OTP verification endpoint called', {
        phone,
        country_code,
        otp,
        purpose,
        ip: req.ip,
        userAgent: req.headers['user-agent'],
        timestamp: new Date().toISOString(),
      });

      const result = await AuthService.verifyOTPAndLogin(phone, country_code, otp, purpose);

      logger.info('📤 OTP verification endpoint response', {
        success: true,
        userId: result.user.id,
        email: result.user.email,
        purpose,
      });

      return ApiResponseUtil.success(res, {
        access_token: result.accessToken,
        refresh_token: result.refreshToken,
        token_type: 'Bearer',
        expires_in: result.expiresIn,
        user: result.user,
      }, 'OTP verified successfully');
    } catch (error: any) {
      logger.error('❌ Verify OTP endpoint error', {
        error: error.message,
        stack: error.stack,
        phone: req.body.phone,
        country_code: req.body.country_code,
        purpose: req.body.purpose,
      });

      if (error.message === 'INVALID_OTP' || error.message.includes('OTP')) {
        return ApiResponseUtil.badRequest(res, error.message);
      }

      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Login with email/phone and password
   */
  static async login(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { email, email_or_phone, password } = req.body;
      const loginIdentifier = email_or_phone || email;

      const result = await AuthService.login(loginIdentifier, password);

      return ApiResponseUtil.success(res, {
        access_token: result.accessToken,
        refresh_token: result.refreshToken,
        token_type: 'Bearer',
        expires_in: result.expiresIn,
        user: result.user,
      }, 'Login successful');
    } catch (error: any) {
      logger.error('Login error', error);

      if (error.message === 'INVALID_CREDENTIALS') {
        return ApiResponseUtil.unauthorized(res, 'Invalid email/phone or password');
      }

      if (error.message === 'ACCOUNT_LOCKED') {
        return ApiResponseUtil.forbidden(res, 'Account temporarily locked due to failed login attempts');
      }

      if (error.message === 'ACCOUNT_INACTIVE') {
        return ApiResponseUtil.forbidden(res, 'Account is inactive');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Resend OTP
   */
  static async resendOTP(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { phone, country_code } = req.body;

      const result = await AuthService.resendOTP(phone, country_code);

      return ApiResponseUtil.success(res, {
        otp_sent: true,
        otp_expires_in: result.otpExpiresIn,
        retry_after: result.retryAfter,
      }, 'OTP resent successfully');
    } catch (error: any) {
      logger.error('Resend OTP error', error);

      if (error.message === 'RATE_LIMIT_EXCEEDED') {
        return ApiResponseUtil.tooManyRequests(res, 'Please wait before requesting another OTP');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Direct login without OTP - FOR DEVELOPMENT ONLY
   */
  static async loginDirect(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { email_or_phone, password } = req.body;

      const result = await AuthService.loginDirect(email_or_phone, password);

      return ApiResponseUtil.success(res, {
        access_token: result.accessToken,
        refresh_token: result.refreshToken,
        token_type: 'Bearer',
        expires_in: result.expiresIn,
        user: result.user,
      }, 'Login successful (DEV MODE - OTP bypassed)');
    } catch (error: any) {
      logger.error('Login direct error', error);

      if (error.message === 'INVALID_CREDENTIALS') {
        return ApiResponseUtil.unauthorized(res, 'Invalid email/phone or password');
      }

      if (error.message === 'ACCOUNT_INACTIVE') {
        return ApiResponseUtil.forbidden(res, 'Account is inactive');
      }

      if (error.message === 'DIRECT_LOGIN_NOT_ALLOWED') {
        return ApiResponseUtil.forbidden(res, 'Direct login is only allowed in development mode');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Forgot password
   */
  static async forgotPassword(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { email } = req.body;

      const result = await AuthService.forgotPassword(email);

      return ApiResponseUtil.success(res, {
        otp_sent: true,
        phone: result.phone,
      }, 'OTP sent to your registered phone number');
    } catch (error: any) {
      logger.error('Forgot password error', error);

      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Reset password
   */
  static async resetPassword(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { phone, country_code, otp, new_password } = req.body;

      await AuthService.resetPassword(phone, country_code, otp, new_password);

      return ApiResponseUtil.success(res, null, 'Password reset successfully');
    } catch (error: any) {
      logger.error('Reset password error', error);

      if (error.message === 'INVALID_OTP' || error.message.includes('OTP')) {
        return ApiResponseUtil.badRequest(res, error.message);
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Refresh access token
   */
  static async refreshToken(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { refresh_token } = req.body;

      const result = await AuthService.refreshAccessToken(refresh_token);

      return ApiResponseUtil.success(res, {
        access_token: result.accessToken,
        refresh_token: result.refreshToken,
        expires_in: result.expiresIn,
      });
    } catch (error: any) {
      logger.error('Refresh token error', error);

      if (error.message === 'INVALID_REFRESH_TOKEN' || error.message === 'REFRESH_TOKEN_EXPIRED') {
        return ApiResponseUtil.unauthorized(res, 'Invalid or expired refresh token');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Logout
   */
  static async logout(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { refresh_token } = req.body;
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      await AuthService.logout(userId, refresh_token);

      return ApiResponseUtil.success(res, null, 'Logged out successfully');
    } catch (error: any) {
      logger.error('Logout error', error);
      return ApiResponseUtil.internalError(res);
    }
  }
}
