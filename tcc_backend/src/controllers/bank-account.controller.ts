import { Response } from 'express';
import { AuthRequest } from '../types';
import { BankAccountService } from '../services/bank-account.service';
import { ApiResponseUtil } from '../utils/response';
import logger from '../utils/logger';

export class BankAccountController {
  /**
   * Create bank account
   * POST /api/bank-accounts
   */
  static async createBankAccount(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      const {
        bank_name,
        branch_address,
        account_number,
        account_holder_name,
        swift_code,
        routing_number,
        is_primary,
      } = req.body;

      const bankAccount = await BankAccountService.createBankAccount(userId, {
        bank_name,
        branch_address,
        account_number,
        account_holder_name,
        swift_code,
        routing_number,
        is_primary,
      });

      return ApiResponseUtil.created(
        res,
        {
          id: bankAccount.id,
          bank_name: bankAccount.bank_name,
          account_number_masked: BankAccountService.maskAccountNumber(bankAccount.account_number),
          account_holder_name: bankAccount.account_holder_name,
          is_primary: bankAccount.is_primary,
          is_verified: bankAccount.is_verified,
          created_at: bankAccount.created_at,
        },
        'Bank account added successfully'
      );
    } catch (error: any) {
      logger.error('Create bank account error', error);

      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }

      return ApiResponseUtil.internalError(res, 'Failed to add bank account');
    }
  }

  /**
   * Get user's bank accounts
   * GET /api/bank-accounts
   */
  static async getUserBankAccounts(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      const accounts = await BankAccountService.getUserBankAccounts(userId);

      // Mask account numbers for response
      const maskedAccounts = accounts.map((account) => ({
        id: account.id,
        bank_name: account.bank_name,
        branch_address: account.branch_address,
        account_number_masked: BankAccountService.maskAccountNumber(account.account_number),
        account_holder_name: account.account_holder_name,
        swift_code: account.swift_code,
        routing_number: account.routing_number,
        is_primary: account.is_primary,
        is_verified: account.is_verified,
        created_at: account.created_at,
        updated_at: account.updated_at,
      }));

      return ApiResponseUtil.success(
        res,
        {
          accounts: maskedAccounts,
          count: maskedAccounts.length,
        },
        'Bank accounts retrieved successfully'
      );
    } catch (error: any) {
      logger.error('Get user bank accounts error', error);
      return ApiResponseUtil.internalError(res, 'Failed to retrieve bank accounts');
    }
  }

  /**
   * Get specific bank account
   * GET /api/bank-accounts/:accountId
   */
  static async getBankAccountById(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      const { accountId } = req.params;

      const account = await BankAccountService.getBankAccountById(accountId, userId);

      if (!account) {
        return ApiResponseUtil.notFound(res, 'Bank account not found');
      }

      return ApiResponseUtil.success(
        res,
        {
          id: account.id,
          bank_name: account.bank_name,
          branch_address: account.branch_address,
          account_number_masked: BankAccountService.maskAccountNumber(account.account_number),
          account_holder_name: account.account_holder_name,
          swift_code: account.swift_code,
          routing_number: account.routing_number,
          is_primary: account.is_primary,
          is_verified: account.is_verified,
          created_at: account.created_at,
          updated_at: account.updated_at,
        },
        'Bank account retrieved successfully'
      );
    } catch (error: any) {
      logger.error('Get bank account error', error);
      return ApiResponseUtil.internalError(res, 'Failed to retrieve bank account');
    }
  }

  /**
   * Update bank account
   * PUT /api/bank-accounts/:accountId
   */
  static async updateBankAccount(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      const { accountId } = req.params;
      const updates = req.body;

      const updatedAccount = await BankAccountService.updateBankAccount(
        accountId,
        userId,
        updates
      );

      return ApiResponseUtil.success(
        res,
        {
          id: updatedAccount.id,
          bank_name: updatedAccount.bank_name,
          account_number_masked: BankAccountService.maskAccountNumber(updatedAccount.account_number),
          account_holder_name: updatedAccount.account_holder_name,
          is_primary: updatedAccount.is_primary,
          is_verified: updatedAccount.is_verified,
          updated_at: updatedAccount.updated_at,
        },
        'Bank account updated successfully'
      );
    } catch (error: any) {
      logger.error('Update bank account error', error);

      if (error.message === 'ACCOUNT_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Bank account not found');
      }

      if (error.message === 'NO_UPDATES_PROVIDED') {
        return ApiResponseUtil.badRequest(res, 'No updates provided');
      }

      return ApiResponseUtil.internalError(res, 'Failed to update bank account');
    }
  }

  /**
   * Delete bank account
   * DELETE /api/bank-accounts/:accountId
   */
  static async deleteBankAccount(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      const { accountId } = req.params;

      await BankAccountService.deleteBankAccount(accountId, userId);

      return ApiResponseUtil.success(res, null, 'Bank account deleted successfully');
    } catch (error: any) {
      logger.error('Delete bank account error', error);

      if (error.message === 'ACCOUNT_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Bank account not found');
      }

      return ApiResponseUtil.internalError(res, 'Failed to delete bank account');
    }
  }

  /**
   * Set primary bank account
   * PUT /api/bank-accounts/:accountId/primary
   */
  static async setPrimaryAccount(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      const { accountId } = req.params;

      const updatedAccount = await BankAccountService.setPrimaryAccount(accountId, userId);

      return ApiResponseUtil.success(
        res,
        {
          id: updatedAccount.id,
          bank_name: updatedAccount.bank_name,
          is_primary: updatedAccount.is_primary,
        },
        'Primary bank account set successfully'
      );
    } catch (error: any) {
      logger.error('Set primary account error', error);

      if (error.message === 'ACCOUNT_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Bank account not found');
      }

      return ApiResponseUtil.internalError(res, 'Failed to set primary account');
    }
  }

  /**
   * Get user's bank accounts (admin view)
   * GET /api/bank-accounts/admin/:userId
   */
  static async getUserBankAccountsForAdmin(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const adminRole = req.user?.role;
      if (adminRole !== 'ADMIN' && adminRole !== 'SUPER_ADMIN') {
        return ApiResponseUtil.forbidden(res, 'Access denied');
      }

      const { userId } = req.params;

      const accounts = await BankAccountService.getUserBankAccountsForAdmin(userId);

      return ApiResponseUtil.success(
        res,
        {
          accounts,
          count: accounts.length,
        },
        'Bank accounts retrieved successfully'
      );
    } catch (error: any) {
      logger.error('Get user bank accounts for admin error', error);
      return ApiResponseUtil.internalError(res, 'Failed to retrieve bank accounts');
    }
  }
}
