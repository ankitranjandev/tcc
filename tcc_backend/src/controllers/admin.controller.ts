import { Response } from 'express';
import { AuthRequest, TransactionStatus, UserRole, KYCStatus } from '../types';
import { AdminService } from '../services/admin.service';
import { ApiResponseUtil } from '../utils/response';
import logger from '../utils/logger';
import { AuditTrailService } from '../services/audit-trail.service';

export class AdminController {
  /**
   * Admin login with 2FA
   */
  static async login(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { email, password, totp_code } = req.body;

      const result = await AdminService.login(email, password, totp_code);

      if (result.requiresTOTP) {
        return ApiResponseUtil.success(
          res,
          { requires_totp: true },
          'Password verified. Please provide TOTP code.'
        );
      }

      return ApiResponseUtil.success(
        res,
        {
          access_token: result.accessToken,
          refresh_token: result.refreshToken,
          expires_in: result.expiresIn,
          admin: result.admin,
        },
        'Login successful'
      );
    } catch (error: any) {
      logger.error('Admin login error', error);

      // Provide detailed error messages for different scenarios
      if (error.message === 'INVALID_CREDENTIALS') {
        return ApiResponseUtil.unauthorized(res, 'Invalid email or password. Please check your credentials and try again.');
      }
      if (error.message === 'ACCOUNT_LOCKED') {
        const remainingTime = error.remainingTime ? ` Please try again in ${error.remainingTime} minutes.` : '';
        return ApiResponseUtil.forbidden(
          res,
          `Account is temporarily locked due to too many failed login attempts.${remainingTime} If you need immediate assistance, please contact support.`
        );
      }
      if (error.message === 'ACCOUNT_INACTIVE') {
        return ApiResponseUtil.forbidden(
          res,
          'Your account has been deactivated. Please contact the system administrator to reactivate your account.'
        );
      }
      if (error.message === 'INVALID_TOTP_CODE') {
        return ApiResponseUtil.unauthorized(
          res,
          'Invalid 2FA verification code. Please check your authenticator app and ensure the time is synced correctly.'
        );
      }
      if (error.message === 'TOTP_REQUIRED') {
        return ApiResponseUtil.unauthorized(
          res,
          'Two-factor authentication is required for this account. Please provide the verification code from your authenticator app.'
        );
      }

      // Generic error for unexpected issues
      logger.error('Unexpected admin login error:', error);
      return ApiResponseUtil.internalError(
        res,
        'An unexpected error occurred during login. Please try again later or contact support if the problem persists.'
      );
    }
  }

  /**
   * Get dashboard statistics
   */
  static async getDashboardStats(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const stats = await AdminService.getDashboardStats();
      return ApiResponseUtil.success(res, stats);
    } catch (error: any) {
      logger.error('Get dashboard stats error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get users with filters and pagination
   */
  static async getUsers(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { search, role, kyc_status, is_active, page = 1, limit = 20 } = req.query;

      const filters = {
        search: search as string,
        role: role as UserRole,
        kyc_status: kyc_status as KYCStatus,
        is_active: is_active === 'true' ? true : is_active === 'false' ? false : undefined,
      };

      const pageNum = parseInt(page as string);
      const limitNum = parseInt(limit as string);
      const offset = (pageNum - 1) * limitNum;

      const result = await AdminService.getUsers(filters, {
        page: pageNum,
        limit: limitNum,
        offset,
      });

      const totalPages = Math.ceil(result.total / limitNum);

      return ApiResponseUtil.success(
        res,
        { users: result.users },
        undefined,
        {
          pagination: {
            page: pageNum,
            limit: limitNum,
            total: result.total,
            totalPages,
          },
        }
      );
    } catch (error: any) {
      logger.error('Get users error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get agents with filters and pagination
   */
  static async getAgents(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { search, active_status, location, page = 1, limit = 20 } = req.query;

      const filters = {
        search: search as string,
        active_status: active_status === 'true' ? true : active_status === 'false' ? false : undefined,
        location: location as string,
      };

      const pageNum = parseInt(page as string);
      const limitNum = parseInt(limit as string);
      const offset = (pageNum - 1) * limitNum;

      const result = await AdminService.getAgents(filters, {
        page: pageNum,
        limit: limitNum,
        offset,
      });

      const totalPages = Math.ceil(result.total / limitNum);

      return ApiResponseUtil.success(
        res,
        { agents: result.agents },
        undefined,
        {
          pagination: {
            page: pageNum,
            limit: limitNum,
            total: result.total,
            totalPages,
          },
        }
      );
    } catch (error: any) {
      logger.error('Get agents error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get transactions with filters and pagination
   */
  static async getTransactions(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { search, type, status, start_date, end_date, page = 1, limit = 25 } = req.query;

      const filters = {
        search: search as string,
        type: type as string,
        status: status as string,
        start_date: start_date as string,
        end_date: end_date as string,
      };

      const pageNum = parseInt(page as string);
      const limitNum = parseInt(limit as string);
      const offset = (pageNum - 1) * limitNum;

      const result = await AdminService.getTransactions(filters, {
        page: pageNum,
        limit: limitNum,
        offset,
      });

      const totalPages = Math.ceil(result.total / limitNum);

      return ApiResponseUtil.success(
        res,
        { transactions: result.transactions },
        undefined,
        {
          pagination: {
            page: pageNum,
            limit: limitNum,
            total: result.total,
            totalPages,
          },
        }
      );
    } catch (error: any) {
      logger.error('Get transactions error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Create new agent
   */
  static async createAgent(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const {
        first_name,
        last_name,
        email,
        password,
        phone,
        country_code,
        location,
        location_address,
        address,
        commission_rate,
      } = req.body;

      const agent = await AdminService.createAgent({
        first_name,
        last_name,
        email,
        password,
        phone,
        country_code,
        location_address: location_address || location || address,
        commission_rate,
      });

      return ApiResponseUtil.created(res, { agent }, 'Agent created successfully');
    } catch (error: any) {
      logger.error('Create agent error', error);
      if (error.message === 'USER_EXISTS') {
        return ApiResponseUtil.error(res, 'USER_EXISTS', 'A user with this email already exists', 400);
      }
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Create new user
   */
  static async createUser(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const {
        first_name,
        last_name,
        email,
        password,
        phone,
        country_code,
        role,
      } = req.body;

      const user = await AdminService.createUser({
        first_name,
        last_name,
        email,
        password,
        phone,
        country_code,
        role,
      });

      return ApiResponseUtil.created(res, { user }, 'User created successfully');
    } catch (error: any) {
      logger.error('Create user error', error);
      if (error.message === 'USER_EXISTS') {
        return ApiResponseUtil.error(res, 'USER_EXISTS', 'A user with this email already exists', 400);
      }
      if (error.message === 'PHONE_REQUIRED') {
        return ApiResponseUtil.error(res, 'PHONE_REQUIRED', 'Phone number is required for this user role', 400);
      }
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Update user status (activate, suspend, deactivate)
   */
  static async updateUserStatus(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { userId } = req.params;
      const { status } = req.body;

      const user = await AdminService.updateUserStatus(userId, status);

      return ApiResponseUtil.success(res, { user }, 'User status updated successfully');
    } catch (error: any) {
      logger.error('Update user status error', error);
      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }
      if (error.message === 'INVALID_STATUS') {
        return ApiResponseUtil.error(res, 'INVALID_STATUS', 'Invalid status value', 400);
      }
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get withdrawal requests
   */
  static async getWithdrawals(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { status, page = 1, limit = 20 } = req.query;

      const pageNum = parseInt(page as string);
      const limitNum = parseInt(limit as string);
      const offset = (pageNum - 1) * limitNum;

      const result = await AdminService.getWithdrawals(
        status as TransactionStatus,
        { page: pageNum, limit: limitNum, offset }
      );

      const totalPages = Math.ceil(result.total / limitNum);

      return ApiResponseUtil.success(
        res,
        { withdrawals: result.withdrawals },
        undefined,
        {
          pagination: {
            page: pageNum,
            limit: limitNum,
            total: result.total,
            totalPages,
          },
        }
      );
    } catch (error: any) {
      logger.error('Get withdrawals error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Review withdrawal request
   */
  static async reviewWithdrawal(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const adminId = req.user?.id;
      if (!adminId) return ApiResponseUtil.unauthorized(res);

      const { withdrawal_id, status, reason } = req.body;

      if (!['COMPLETED', 'REJECTED'].includes(status)) {
        return ApiResponseUtil.badRequest(res, 'Invalid status. Must be COMPLETED or REJECTED');
      }

      if (status === 'REJECTED' && !reason) {
        return ApiResponseUtil.badRequest(res, 'Rejection reason is required');
      }

      await AdminService.reviewWithdrawal(adminId, withdrawal_id, status, reason);

      return ApiResponseUtil.success(
        res,
        null,
        `Withdrawal ${status === 'COMPLETED' ? 'approved' : 'rejected'} successfully`
      );
    } catch (error: any) {
      logger.error('Review withdrawal error', error);
      if (error.message === 'WITHDRAWAL_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Withdrawal request not found');
      }
      if (error.message === 'WITHDRAWAL_ALREADY_PROCESSED') {
        return ApiResponseUtil.conflict(res, 'Withdrawal has already been processed');
      }
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Review agent credit request
   */
  static async reviewAgentCredit(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const adminId = req.user?.id;
      if (!adminId) return ApiResponseUtil.unauthorized(res);

      const { request_id, status, reason } = req.body;

      if (!['COMPLETED', 'REJECTED'].includes(status)) {
        return ApiResponseUtil.badRequest(res, 'Invalid status. Must be COMPLETED or REJECTED');
      }

      if (status === 'REJECTED' && !reason) {
        return ApiResponseUtil.badRequest(res, 'Rejection reason is required');
      }

      await AdminService.reviewAgentCredit(adminId, request_id, status, reason);

      return ApiResponseUtil.success(
        res,
        null,
        `Agent credit request ${status === 'COMPLETED' ? 'approved' : 'rejected'} successfully`
      );
    } catch (error: any) {
      logger.error('Review agent credit error', error);
      if (error.message === 'REQUEST_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Agent credit request not found');
      }
      if (error.message === 'REQUEST_ALREADY_PROCESSED') {
        return ApiResponseUtil.conflict(res, 'Request has already been processed');
      }
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get system configuration
   */
  static async getSystemConfig(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const config = await AdminService.getSystemConfig();
      return ApiResponseUtil.success(res, { config });
    } catch (error: any) {
      logger.error('Get system config error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Update system configuration
   */
  static async updateSystemConfig(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const adminId = req.user?.id;
      if (!adminId) return ApiResponseUtil.unauthorized(res);

      const { config } = req.body;

      if (!config || typeof config !== 'object') {
        return ApiResponseUtil.badRequest(res, 'Invalid configuration data');
      }

      await AdminService.updateSystemConfig(adminId, config);

      return ApiResponseUtil.success(res, null, 'System configuration updated successfully');
    } catch (error: any) {
      logger.error('Update system config error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Generate report
   */
  static async generateReport(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { type, format = 'json', from, to } = req.query;

      if (!type || !['transactions', 'investments', 'users'].includes(type as string)) {
        return ApiResponseUtil.badRequest(
          res,
          'Invalid report type. Must be transactions, investments, or users'
        );
      }

      if (!['json', 'csv', 'pdf'].includes(format as string)) {
        return ApiResponseUtil.badRequest(res, 'Invalid format. Must be json, csv, or pdf');
      }

      const dateRange =
        from && to
          ? {
              from: new Date(from as string),
              to: new Date(to as string),
            }
          : undefined;

      const report = await AdminService.generateReport(
        type as 'transactions' | 'investments' | 'users',
        format as 'json' | 'csv' | 'pdf',
        dateRange
      );

      return ApiResponseUtil.success(res, report);
    } catch (error: any) {
      logger.error('Generate report error', error);
      if (error.message === 'FORMAT_NOT_SUPPORTED_YET') {
        return ApiResponseUtil.badRequest(
          res,
          'CSV and PDF formats are not yet supported. Please use JSON format.'
        );
      }
      if (error.message === 'INVALID_REPORT_TYPE') {
        return ApiResponseUtil.badRequest(res, 'Invalid report type');
      }
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get analytics KPI
   */
  static async getAnalyticsKPI(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { from, to } = req.query;

      const dateRange =
        from && to
          ? {
              from: new Date(from as string),
              to: new Date(to as string),
            }
          : undefined;

      const analytics = await AdminService.getAnalyticsKPI(dateRange);

      return ApiResponseUtil.success(res, analytics);
    } catch (error: any) {
      logger.error('Get analytics KPI error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get bill payments with filters and pagination
   */
  static async getBillPayments(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { page = '1', limit = '25', bill_type, status, from_date, to_date, search } = req.query;

      const pagination = {
        page: parseInt(page as string),
        limit: parseInt(limit as string),
        offset: (parseInt(page as string) - 1) * parseInt(limit as string),
      };

      const filters: any = {};

      if (bill_type) {
        filters.billType = bill_type as string;
      }

      if (status) {
        filters.status = status as TransactionStatus;
      }

      if (from_date) {
        filters.fromDate = new Date(from_date as string);
      }

      if (to_date) {
        filters.toDate = new Date(to_date as string);
      }

      if (search) {
        filters.search = search as string;
      }

      const result = await AdminService.getBillPayments(pagination, filters);

      return ApiResponseUtil.success(
        res,
        { billPayments: result.billPayments },
        undefined,
        { pagination: result.pagination }
      );
    } catch (error: any) {
      logger.error('Get bill payments error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get investments with filters and pagination
   */
  static async getInvestments(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { page = '1', limit = '25', category, status, from_date, to_date, search } = req.query;

      const pagination = {
        page: parseInt(page as string),
        limit: parseInt(limit as string),
        offset: (parseInt(page as string) - 1) * parseInt(limit as string),
      };

      const filters: any = {};

      if (category) {
        filters.category = category as string;
      }

      if (status) {
        filters.status = status as string;
      }

      if (from_date) {
        filters.fromDate = new Date(from_date as string);
      }

      if (to_date) {
        filters.toDate = new Date(to_date as string);
      }

      if (search) {
        filters.search = search as string;
      }

      const result = await AdminService.getInvestments(pagination, filters);

      return ApiResponseUtil.success(
        res,
        { investments: result.investments },
        undefined,
        { pagination: result.pagination }
      );
    } catch (error: any) {
      logger.error('Get investments error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get transaction report
   */
  static async getTransactionReport(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { start_date, end_date, type, status, format } = req.query;

      const dateRange = start_date && end_date
        ? { from: new Date(start_date as string), to: new Date(end_date as string) }
        : undefined;

      const result = await AdminService.getTransactionReport({
        dateRange,
        type: type as string,
        status: status as string,
        format: format as string,
      });

      return ApiResponseUtil.success(res, result);
    } catch (error: any) {
      logger.error('Get transaction report error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get user activity report
   */
  static async getUserActivityReport(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { start_date, end_date, format } = req.query;

      const dateRange = start_date && end_date
        ? { from: new Date(start_date as string), to: new Date(end_date as string) }
        : undefined;

      const result = await AdminService.getUserActivityReport({
        dateRange,
        format: format as string,
      });

      return ApiResponseUtil.success(res, result);
    } catch (error: any) {
      logger.error('Get user activity report error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get revenue report
   */
  static async getRevenueReport(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { start_date, end_date, group_by, format } = req.query;

      const dateRange = start_date && end_date
        ? { from: new Date(start_date as string), to: new Date(end_date as string) }
        : undefined;

      const result = await AdminService.getRevenueReport({
        dateRange,
        groupBy: group_by as string,
        format: format as string,
      });

      return ApiResponseUtil.success(res, result);
    } catch (error: any) {
      logger.error('Get revenue report error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get investment report
   */
  static async getInvestmentReport(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { start_date, end_date, category, format } = req.query;

      const dateRange = start_date && end_date
        ? { from: new Date(start_date as string), to: new Date(end_date as string) }
        : undefined;

      const result = await AdminService.getInvestmentReport({
        dateRange,
        category: category as string,
        format: format as string,
      });

      return ApiResponseUtil.success(res, result);
    } catch (error: any) {
      logger.error('Get investment report error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get agent performance report
   */
  static async getAgentPerformanceReport(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { start_date, end_date, agent_id, format } = req.query;

      const dateRange = start_date && end_date
        ? { from: new Date(start_date as string), to: new Date(end_date as string) }
        : undefined;

      const result = await AdminService.getAgentPerformanceReport({
        dateRange,
        agentId: agent_id as string,
        format: format as string,
      });

      return ApiResponseUtil.success(res, result);
    } catch (error: any) {
      logger.error('Get agent performance report error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Manually adjust user wallet balance
   */
  static async adjustWalletBalance(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const adminId = req.user?.id;
      if (!adminId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { user_id, amount, reason, notes } = req.body;

      const result = await AuditTrailService.adjustBalance(
        user_id,
        adminId,
        amount,
        reason,
        notes,
        req.ip
      );

      return ApiResponseUtil.success(
        res,
        {
          wallet: {
            id: result.wallet.id,
            user_id: result.wallet.user_id,
            balance: parseFloat(result.wallet.balance),
            currency: result.wallet.currency,
            last_transaction_at: result.wallet.last_transaction_at,
          },
          transaction: {
            id: result.transaction.id,
            transaction_id: result.transaction.transaction_id,
            type: result.transaction.type,
            amount: parseFloat(result.transaction.amount),
            status: result.transaction.status,
            description: result.transaction.description,
          },
          audit: {
            id: result.auditEntry.id,
            action_type: result.auditEntry.action_type,
            amount: parseFloat(result.auditEntry.amount.toString()),
            balance_before: parseFloat(result.auditEntry.balance_before.toString()),
            balance_after: parseFloat(result.auditEntry.balance_after.toString()),
            reason: result.auditEntry.reason,
            notes: result.auditEntry.notes,
          },
        },
        `Wallet balance ${amount > 0 ? 'credited' : 'debited'} successfully`
      );
    } catch (error: any) {
      logger.error('Adjust wallet balance error', error);

      if (error.message === 'INVALID_AMOUNT') {
        return ApiResponseUtil.badRequest(res, 'Invalid amount. Amount cannot be zero.');
      }

      if (error.message === 'REASON_REQUIRED') {
        return ApiResponseUtil.badRequest(res, 'Reason is required for balance adjustment');
      }

      if (error.message === 'WALLET_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Wallet not found');
      }

      if (error.message === 'INSUFFICIENT_BALANCE') {
        return ApiResponseUtil.badRequest(res, 'Insufficient balance for debit operation');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get audit trail for a specific user
   */
  static async getUserAuditTrail(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { userId } = req.params;
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 50;
      const offset = (page - 1) * limit;

      const result = await AuditTrailService.getAuditTrailForUser(userId, limit, offset);

      return ApiResponseUtil.success(res, {
        entries: result.entries,
        pagination: {
          page,
          limit,
          total: result.total,
          totalPages: Math.ceil(result.total / limit),
        },
      });
    } catch (error: any) {
      logger.error('Get user audit trail error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get all audit trail entries
   */
  static async getAllAuditTrail(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 50;
      const offset = (page - 1) * limit;
      const actionType = req.query.action_type as any;

      const result = await AuditTrailService.getAllAuditTrail(limit, offset, actionType);

      return ApiResponseUtil.success(res, {
        entries: result.entries,
        pagination: {
          page,
          limit,
          total: result.total,
          totalPages: Math.ceil(result.total / limit),
        },
      });
    } catch (error: any) {
      logger.error('Get all audit trail error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get audit trail statistics
   */
  static async getAuditStatistics(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const stats = await AuditTrailService.getAuditStatistics();

      return ApiResponseUtil.success(res, { statistics: stats });
    } catch (error: any) {
      logger.error('Get audit statistics error', error);
      return ApiResponseUtil.internalError(res);
    }
  }
}
