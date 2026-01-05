import { Response } from 'express';
import { AuthRequest } from '../types';
import { UserService } from '../services/user.service';
import { fileUploadService, FileType } from '../services/file-upload.service';
import { ApiResponseUtil } from '../utils/response';
import logger from '../utils/logger';

export class UserController {
  static async getProfile(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      const result = await UserService.getProfile(userId);

      return ApiResponseUtil.success(res, result);
    } catch (error: any) {
      logger.error('Get profile error', error);
      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }
      return ApiResponseUtil.internalError(res);
    }
  }

  static async updateProfile(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      const { first_name, last_name, email, profile_picture } = req.body;

      const result = await UserService.updateProfile(userId, {
        first_name,
        last_name,
        email,
        profile_picture,
      });

      return ApiResponseUtil.success(res, { user: result }, 'Profile updated successfully');
    } catch (error: any) {
      logger.error('Update profile error', error);
      if (error.message === 'EMAIL_ALREADY_EXISTS') {
        return ApiResponseUtil.conflict(res, 'Email already in use');
      }
      return ApiResponseUtil.internalError(res);
    }
  }

  static async changePhone(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      const { new_phone, country_code, password } = req.body;

      const result = await UserService.changePhone(userId, new_phone, country_code, password);

      return ApiResponseUtil.success(res, {
        otp_sent: result.otpSent,
        new_phone: result.phone,
        verification_required: true,
      }, 'OTP sent to new phone number for verification');
    } catch (error: any) {
      logger.error('Change phone error', error);
      if (error.message === 'INVALID_PASSWORD') {
        return ApiResponseUtil.unauthorized(res, 'Invalid password');
      }
      if (error.message === 'PHONE_ALREADY_EXISTS') {
        return ApiResponseUtil.conflict(res, 'Phone number already in use');
      }
      return ApiResponseUtil.internalError(res);
    }
  }

  static async changePassword(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      const { current_password, new_password } = req.body;

      await UserService.changePassword(userId, current_password, new_password);

      return ApiResponseUtil.success(res, null, 'Password changed successfully');
    } catch (error: any) {
      logger.error('Change password error', error);
      if (error.message === 'INVALID_CURRENT_PASSWORD') {
        return ApiResponseUtil.unauthorized(res, 'Current password is incorrect');
      }
      return ApiResponseUtil.internalError(res);
    }
  }

  static async deleteAccount(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      const result = await UserService.requestAccountDeletion(userId);

      return ApiResponseUtil.success(res, {
        scheduled_for: result.scheduledFor,
        grace_period_days: 30,
      }, 'Account deletion scheduled. You have 30 days to cancel.');
    } catch (error: any) {
      logger.error('Delete account error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  static async cancelDeletion(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      await UserService.cancelAccountDeletion(userId);

      return ApiResponseUtil.success(res, null, 'Account deletion cancelled successfully');
    } catch (error: any) {
      logger.error('Cancel deletion error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  static async addBankAccount(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      const { bank_name, account_number, account_holder_name, branch_address, is_primary } = req.body;

      const result = await UserService.addBankAccount(userId, {
        bank_name,
        account_number,
        account_holder_name,
        branch_address,
        is_primary,
      });

      return ApiResponseUtil.created(res, { bank_account: result }, 'Bank account added successfully');
    } catch (error: any) {
      logger.error('Add bank account error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  static async getBankAccounts(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      const accounts = await UserService.getBankAccounts(userId);

      return ApiResponseUtil.success(res, { bank_accounts: accounts });
    } catch (error: any) {
      logger.error('Get bank accounts error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  static async uploadProfilePicture(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      const file = req.file;
      if (!file) {
        return ApiResponseUtil.badRequest(res, 'No file provided');
      }

      logger.info('Profile picture upload request', {
        userId,
        filename: file.originalname,
        mimetype: file.mimetype,
        size: file.size,
      });

      // Save the uploaded file
      const uploadedFile = await fileUploadService.saveFile(
        file,
        FileType.PROFILE_PICTURE,
        userId
      );

      // Update user profile with the new picture URL
      const updatedUser = await UserService.updateProfilePicture(userId, uploadedFile.url);

      return ApiResponseUtil.success(
        res,
        {
          profile_picture_url: uploadedFile.url,
          user: updatedUser,
        },
        'Profile picture uploaded successfully'
      );
    } catch (error: any) {
      logger.error('Profile picture upload error', error);

      if (error.message === 'Invalid file type') {
        return ApiResponseUtil.badRequest(res, 'Invalid file type. Only JPEG and PNG are allowed.');
      }
      if (error.message === 'File size exceeds maximum allowed size') {
        return ApiResponseUtil.badRequest(res, 'File size exceeds maximum allowed size (5MB)');
      }

      return ApiResponseUtil.internalError(res, 'Failed to upload profile picture');
    }
  }

  static async verifyPhone(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      const { phone, country_code } = req.body;

      const result = await UserService.verifyPhone(phone, country_code, userId);

      return ApiResponseUtil.success(res, result);
    } catch (error: any) {
      logger.error('Verify phone error', error);
      if (error.message === 'CANNOT_TRANSFER_TO_SELF') {
        return ApiResponseUtil.badRequest(res, 'Cannot transfer to yourself');
      }
      return ApiResponseUtil.internalError(res);
    }
  }
}
