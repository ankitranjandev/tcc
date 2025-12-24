import { Response } from 'express';
import { AuthRequest, TransactionStatus, UserRole, KYCStatus } from '../types';
import { AdminService } from '../services/admin.service';
import { InvestmentProductService } from '../services/investment-product.service';
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

  /**
   * Export users data
   */
  static async exportUsers(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { format = 'csv', search, role, status, kycStatus } = req.query;

      // Validate format
      const validFormats = ['csv', 'xlsx', 'pdf'];
      if (!validFormats.includes(format as string)) {
        return ApiResponseUtil.badRequest(res, 'Invalid export format. Supported formats: csv, xlsx, pdf');
      }

      // Import ExportService dynamically to avoid circular dependencies
      const { ExportService } = await import('../services/export.service');

      // Export users
      const result = await ExportService.exportUsers(format as 'csv' | 'xlsx' | 'pdf', {
        search: search as string,
        role: role as UserRole,
        status: status as string,
        kycStatus: kycStatus as KYCStatus,
      });

      // For web browsers, we'll return the file path as a downloadable URL
      // In production, you should serve this through a CDN or static file server
      const downloadUrl = `/uploads/exports/${result.filename}`;

      logger.info('Users export completed', {
        format,
        filename: result.filename,
        adminId: req.user?.id,
      });

      return ApiResponseUtil.success(res, {
        url: downloadUrl,
        filename: result.filename,
      });
    } catch (error: any) {
      logger.error('Export users error', error);
      return ApiResponseUtil.internalError(res, error.message);
    }
  }

  /**
   * Export transactions data
   */
  static async exportTransactions(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { format = 'csv', search, status, type, startDate, endDate } = req.query;

      // Validate format
      const validFormats = ['csv', 'xlsx', 'pdf'];
      if (!validFormats.includes(format as string)) {
        return ApiResponseUtil.badRequest(res, 'Invalid export format. Supported formats: csv, xlsx, pdf');
      }

      // Import ExportService dynamically to avoid circular dependencies
      const { ExportService } = await import('../services/export.service');

      // Export transactions
      const result = await ExportService.exportTransactions(format as 'csv' | 'xlsx' | 'pdf', {
        search: search as string,
        status: status as string,
        type: type as string,
        startDate: startDate as string,
        endDate: endDate as string,
      });

      const downloadUrl = `/uploads/exports/${result.filename}`;

      logger.info('Transactions export completed', {
        format,
        filename: result.filename,
        adminId: req.user?.id,
      });

      return ApiResponseUtil.success(res, {
        url: downloadUrl,
        filename: result.filename,
      });
    } catch (error: any) {
      logger.error('Export transactions error', error);
      return ApiResponseUtil.internalError(res, error.message);
    }
  }

  /**
   * Export investments data
   */
  static async exportInvestments(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { format = 'csv', search, status, productId, startDate, endDate } = req.query;

      const validFormats = ['csv', 'xlsx', 'pdf'];
      if (!validFormats.includes(format as string)) {
        return ApiResponseUtil.badRequest(res, 'Invalid export format. Supported formats: csv, xlsx, pdf');
      }

      const { ExportService } = await import('../services/export.service');

      const result = await ExportService.exportInvestments(format as 'csv' | 'xlsx' | 'pdf', {
        search: search as string,
        status: status as string,
        productId: productId as string,
        startDate: startDate as string,
        endDate: endDate as string,
      });

      const downloadUrl = `/uploads/exports/${result.filename}`;

      logger.info('Investments export completed', {
        format,
        filename: result.filename,
        adminId: req.user?.id,
      });

      return ApiResponseUtil.success(res, {
        url: downloadUrl,
        filename: result.filename,
      });
    } catch (error: any) {
      logger.error('Export investments error', error);
      return ApiResponseUtil.internalError(res, error.message);
    }
  }

  /**
   * Export bill payments data
   */
  static async exportBillPayments(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { format = 'csv', search, status, billerId, startDate, endDate } = req.query;

      const validFormats = ['csv', 'xlsx', 'pdf'];
      if (!validFormats.includes(format as string)) {
        return ApiResponseUtil.badRequest(res, 'Invalid export format. Supported formats: csv, xlsx, pdf');
      }

      const { ExportService } = await import('../services/export.service');

      const result = await ExportService.exportBillPayments(format as 'csv' | 'xlsx' | 'pdf', {
        search: search as string,
        status: status as string,
        billerId: billerId as string,
        startDate: startDate as string,
        endDate: endDate as string,
      });

      const downloadUrl = `/uploads/exports/${result.filename}`;

      logger.info('Bill payments export completed', {
        format,
        filename: result.filename,
        adminId: req.user?.id,
      });

      return ApiResponseUtil.success(res, {
        url: downloadUrl,
        filename: result.filename,
      });
    } catch (error: any) {
      logger.error('Export bill payments error', error);
      return ApiResponseUtil.internalError(res, error.message);
    }
  }

  /**
   * Export e-voting data
   */
  static async exportEVoting(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { format = 'csv', electionId, status } = req.query;

      const validFormats = ['csv', 'xlsx', 'pdf'];
      if (!validFormats.includes(format as string)) {
        return ApiResponseUtil.badRequest(res, 'Invalid export format. Supported formats: csv, xlsx, pdf');
      }

      const { ExportService } = await import('../services/export.service');

      const result = await ExportService.exportEVoting(format as 'csv' | 'xlsx' | 'pdf', {
        electionId: electionId as string,
        status: status as string,
      });

      const downloadUrl = `/uploads/exports/${result.filename}`;

      logger.info('E-voting export completed', {
        format,
        filename: result.filename,
        adminId: req.user?.id,
      });

      return ApiResponseUtil.success(res, {
        url: downloadUrl,
        filename: result.filename,
      });
    } catch (error: any) {
      logger.error('Export e-voting error', error);
      return ApiResponseUtil.internalError(res, error.message);
    }
  }

  /**
   * Export reports data
   */
  static async exportReports(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { format = 'csv', reportType, startDate, endDate, ...additionalFilters } = req.query;

      const validFormats = ['csv', 'xlsx', 'pdf'];
      if (!validFormats.includes(format as string)) {
        return ApiResponseUtil.badRequest(res, 'Invalid export format. Supported formats: csv, xlsx, pdf');
      }

      const { ExportService } = await import('../services/export.service');

      const result = await ExportService.exportReports(format as 'csv' | 'xlsx' | 'pdf', {
        reportType: reportType as string,
        startDate: startDate as string,
        endDate: endDate as string,
        ...additionalFilters,
      });

      const downloadUrl = `/uploads/exports/${result.filename}`;

      logger.info('Reports export completed', {
        format,
        filename: result.filename,
        adminId: req.user?.id,
      });

      return ApiResponseUtil.success(res, {
        url: downloadUrl,
        filename: result.filename,
      });
    } catch (error: any) {
      logger.error('Export reports error', error);
      return ApiResponseUtil.internalError(res, error.message);
    }
  }

  /**
   * Create investment opportunity
   */
  static async createOpportunity(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const adminId = req.user!.id;
      const {
        category_id,
        title,
        description,
        min_investment,
        max_investment,
        tenure_months,
        return_rate,
        total_units,
        image_url,
        metadata,
      } = req.body;

      const opportunity = await AdminService.createOpportunity(adminId, {
        category_id,
        title,
        description,
        min_investment,
        max_investment,
        tenure_months,
        return_rate,
        total_units,
        image_url,
        metadata,
      });

      return ApiResponseUtil.created(
        res,
        opportunity,
        'Investment opportunity created successfully'
      );
    } catch (error: any) {
      if (error.message === 'CATEGORY_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Investment category not found');
      }
      if (error.message === 'INVALID_CATEGORY') {
        return ApiResponseUtil.badRequest(
          res,
          'Invalid category. Only Agriculture and Education categories are allowed.'
        );
      }
      if (error.message === 'CATEGORY_OPPORTUNITY_LIMIT_REACHED') {
        return ApiResponseUtil.badRequest(
          res,
          'Maximum limit of 16 opportunities per category has been reached.'
        );
      }
      logger.error('Create opportunity error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Update investment opportunity
   */
  static async updateOpportunity(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const adminId = req.user!.id;
      const { opportunityId } = req.params;
      const updateData = req.body;

      const opportunity = await AdminService.updateOpportunity(adminId, opportunityId, updateData);

      return ApiResponseUtil.success(res, opportunity, 'Investment opportunity updated successfully');
    } catch (error: any) {
      if (error.message === 'OPPORTUNITY_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Investment opportunity not found');
      }
      logger.error('Update opportunity error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Toggle opportunity status (hide/show)
   */
  static async toggleOpportunityStatus(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const adminId = req.user!.id;
      const { opportunityId } = req.params;
      const { is_active } = req.body;

      const result = await AdminService.toggleOpportunityStatus(adminId, opportunityId, is_active);

      return ApiResponseUtil.success(
        res,
        result,
        `Opportunity ${is_active ? 'shown' : 'hidden'} successfully`
      );
    } catch (error: any) {
      if (error.message === 'OPPORTUNITY_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Investment opportunity not found');
      }
      logger.error('Toggle opportunity status error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get all opportunities with pagination and filters
   */
  static async getOpportunities(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const perPage = parseInt(req.query.per_page as string) || 25;

      const filters = {
        category: req.query.category as string | undefined,
        is_active: req.query.is_active ? req.query.is_active === 'true' : undefined,
        search: req.query.search as string | undefined,
      };

      const result = await AdminService.getOpportunities(
        {
          page,
          limit: perPage,
          offset: (page - 1) * perPage,
        },
        filters
      );

      return ApiResponseUtil.success(res, result);
    } catch (error: any) {
      logger.error('Get opportunities error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get single opportunity details
   */
  static async getOpportunityDetails(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { opportunityId } = req.params;

      const opportunity = await AdminService.getOpportunityDetails(opportunityId);

      return ApiResponseUtil.success(res, opportunity);
    } catch (error: any) {
      if (error.message === 'OPPORTUNITY_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Investment opportunity not found');
      }
      logger.error('Get opportunity details error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  // =====================================================
  // INVESTMENT PRODUCT MANAGEMENT
  // =====================================================

  /**
   * Get all investment categories with version information
   */
  static async getInvestmentCategories(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const categories = await InvestmentProductService.getCategories();
      return ApiResponseUtil.success(res, categories);
    } catch (error: any) {
      logger.error('Get investment categories error', error);
      return ApiResponseUtil.internalError(res, 'Failed to fetch investment categories');
    }
  }

  /**
   * Create a new investment category
   */
  static async createInvestmentCategory(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { name, display_name, description, sub_categories, icon_url } = req.body;

      if (!name || !display_name) {
        return ApiResponseUtil.badRequest(res, 'Name and display name are required');
      }

      const category = await InvestmentProductService.createCategory({
        name,
        display_name,
        description,
        sub_categories,
        icon_url,
      });

      return ApiResponseUtil.success(res, category, 'Investment category created successfully');
    } catch (error: any) {
      logger.error('Create investment category error', error);
      if (error.code === '23505') {
        return ApiResponseUtil.badRequest(res, 'Category with this name already exists');
      }
      return ApiResponseUtil.internalError(res, 'Failed to create investment category');
    }
  }

  /**
   * Update an investment category
   */
  static async updateInvestmentCategory(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { categoryId } = req.params;
      const { display_name, description, sub_categories, icon_url, is_active } = req.body;

      const category = await InvestmentProductService.updateCategory(categoryId, {
        display_name,
        description,
        sub_categories,
        icon_url,
        is_active,
      });

      return ApiResponseUtil.success(res, category, 'Investment category updated successfully');
    } catch (error: any) {
      if (error.message === 'CATEGORY_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Investment category not found');
      }
      if (error.message === 'NO_UPDATES_PROVIDED') {
        return ApiResponseUtil.badRequest(res, 'No updates provided');
      }
      logger.error('Update investment category error', error);
      return ApiResponseUtil.internalError(res, 'Failed to update investment category');
    }
  }

  /**
   * Deactivate an investment category
   */
  static async deactivateInvestmentCategory(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { categoryId } = req.params;

      await InvestmentProductService.deactivateCategory(categoryId);

      return ApiResponseUtil.success(res, null, 'Investment category deactivated successfully');
    } catch (error: any) {
      if (error.message === 'CATEGORY_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Investment category not found');
      }
      logger.error('Deactivate investment category error', error);
      return ApiResponseUtil.internalError(res, 'Failed to deactivate investment category');
    }
  }

  /**
   * Get all tenures for a category
   */
  static async getInvestmentTenures(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { categoryId } = req.params;

      const tenures = await InvestmentProductService.getTenures(categoryId);

      return ApiResponseUtil.success(res, tenures);
    } catch (error: any) {
      logger.error('Get investment tenures error', error);
      return ApiResponseUtil.internalError(res, 'Failed to fetch investment tenures');
    }
  }

  /**
   * Create a new investment tenure
   */
  static async createInvestmentTenure(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { categoryId } = req.params;
      const { duration_months, return_percentage, agreement_template_url } = req.body;

      if (!duration_months || !return_percentage) {
        return ApiResponseUtil.badRequest(res, 'Duration and return percentage are required');
      }

      if (duration_months <= 0) {
        return ApiResponseUtil.badRequest(res, 'Duration must be greater than 0');
      }

      if (return_percentage < 0) {
        return ApiResponseUtil.badRequest(res, 'Return percentage must be non-negative');
      }

      const tenure = await InvestmentProductService.createTenure(categoryId, {
        category_id: categoryId,
        duration_months,
        return_percentage,
        agreement_template_url,
      });

      return ApiResponseUtil.success(res, tenure, 'Investment tenure created successfully');
    } catch (error: any) {
      logger.error('Create investment tenure error', error);
      if (error.code === '23505') {
        return ApiResponseUtil.badRequest(res, 'Tenure with this duration already exists for this category');
      }
      return ApiResponseUtil.internalError(res, 'Failed to create investment tenure');
    }
  }

  /**
   * Update tenure rate - creates a new version
   */
  static async updateTenureRate(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { tenureId } = req.params;
      const { new_rate, change_reason } = req.body;
      const adminId = req.user?.id;

      if (!new_rate || new_rate < 0) {
        return ApiResponseUtil.badRequest(res, 'Valid new rate is required');
      }

      if (!change_reason || change_reason.trim() === '') {
        return ApiResponseUtil.badRequest(res, 'Change reason is required');
      }

      if (!adminId) {
        return ApiResponseUtil.unauthorized(res, 'Admin authentication required');
      }

      const newVersion = await InvestmentProductService.updateTenureRate(
        tenureId,
        new_rate,
        change_reason,
        adminId
      );

      return ApiResponseUtil.success(
        res,
        newVersion,
        'Investment rate updated successfully. Users have been notified.'
      );
    } catch (error: any) {
      if (error.message === 'TENURE_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Investment tenure not found');
      }
      if (error.message === 'NO_CURRENT_VERSION_FOUND') {
        return ApiResponseUtil.badRequest(res, 'No current version found for this tenure');
      }
      if (error.message === 'RATE_UNCHANGED') {
        return ApiResponseUtil.badRequest(res, 'New rate is the same as current rate');
      }
      logger.error('Update tenure rate error', error);
      return ApiResponseUtil.internalError(res, 'Failed to update investment rate');
    }
  }

  /**
   * Get version history for a tenure
   */
  static async getTenureVersionHistory(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { tenureId } = req.params;

      const versions = await InvestmentProductService.getTenureVersionHistory(tenureId);

      return ApiResponseUtil.success(res, versions);
    } catch (error: any) {
      logger.error('Get tenure version history error', error);
      return ApiResponseUtil.internalError(res, 'Failed to fetch version history');
    }
  }

  /**
   * Get investment units for a category
   */
  static async getInvestmentUnits(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { categoryId } = req.params;

      // First get the category to get its name
      const categories = await InvestmentProductService.getCategories();
      const category = categories.find((c) => c.category.id === categoryId);

      if (!category) {
        return ApiResponseUtil.notFound(res, 'Category not found');
      }

      const units = await InvestmentProductService.getUnits(category.category.name);

      return ApiResponseUtil.success(res, units);
    } catch (error: any) {
      logger.error('Get investment units error', error);
      return ApiResponseUtil.internalError(res, 'Failed to fetch investment units');
    }
  }

  /**
   * Create a new investment unit
   */
  static async createInvestmentUnit(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { category, unit_name, unit_price, description, icon_url, display_order } = req.body;

      if (!category || !unit_name || !unit_price) {
        return ApiResponseUtil.badRequest(res, 'Category, unit name, and unit price are required');
      }

      if (unit_price <= 0) {
        return ApiResponseUtil.badRequest(res, 'Unit price must be greater than 0');
      }

      const unit = await InvestmentProductService.createUnit({
        category,
        unit_name,
        unit_price,
        description,
        icon_url,
        display_order,
      });

      return ApiResponseUtil.success(res, unit, 'Investment unit created successfully');
    } catch (error: any) {
      logger.error('Create investment unit error', error);
      if (error.code === '23505') {
        return ApiResponseUtil.badRequest(res, 'Unit with this name already exists for this category');
      }
      return ApiResponseUtil.internalError(res, 'Failed to create investment unit');
    }
  }

  /**
   * Update an investment unit
   */
  static async updateInvestmentUnit(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { unitId } = req.params;
      const { unit_name, unit_price, description, icon_url, display_order, is_active } = req.body;

      if (unit_price !== undefined && unit_price <= 0) {
        return ApiResponseUtil.badRequest(res, 'Unit price must be greater than 0');
      }

      const unit = await InvestmentProductService.updateUnit(unitId, {
        unit_name,
        unit_price,
        description,
        icon_url,
        display_order,
        is_active,
      });

      return ApiResponseUtil.success(res, unit, 'Investment unit updated successfully');
    } catch (error: any) {
      if (error.message === 'UNIT_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Investment unit not found');
      }
      if (error.message === 'NO_UPDATES_PROVIDED') {
        return ApiResponseUtil.badRequest(res, 'No updates provided');
      }
      logger.error('Update investment unit error', error);
      return ApiResponseUtil.internalError(res, 'Failed to update investment unit');
    }
  }

  /**
   * Delete an investment unit
   */
  static async deleteInvestmentUnit(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { unitId } = req.params;

      await InvestmentProductService.deleteUnit(unitId);

      return ApiResponseUtil.success(res, null, 'Investment unit deleted successfully');
    } catch (error: any) {
      if (error.message === 'UNIT_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Investment unit not found');
      }
      logger.error('Delete investment unit error', error);
      return ApiResponseUtil.internalError(res, 'Failed to delete investment unit');
    }
  }

  /**
   * Get rate change history
   */
  static async getRateChangeHistory(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const category = req.query.category as string | undefined;
      const from_date = req.query.from_date ? new Date(req.query.from_date as string) : undefined;
      const to_date = req.query.to_date ? new Date(req.query.to_date as string) : undefined;
      const admin_id = req.query.admin_id as string | undefined;

      const history = await InvestmentProductService.getRateChangeHistory({
        category: category as any,
        from_date,
        to_date,
        admin_id,
      });

      return ApiResponseUtil.success(res, history);
    } catch (error: any) {
      logger.error('Get rate change history error', error);
      return ApiResponseUtil.internalError(res, 'Failed to fetch rate change history');
    }
  }

  /**
   * Get version-based report
   */
  static async getVersionBasedReport(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const category = req.query.category as string | undefined;
      const tenure_id = req.query.tenure_id as string | undefined;
      const from_date = req.query.from_date ? new Date(req.query.from_date as string) : undefined;
      const to_date = req.query.to_date ? new Date(req.query.to_date as string) : undefined;

      const report = await InvestmentProductService.getVersionBasedReport({
        category: category as any,
        tenure_id,
        from_date,
        to_date,
      });

      return ApiResponseUtil.success(res, report);
    } catch (error: any) {
      logger.error('Get version based report error', error);
      return ApiResponseUtil.internalError(res, 'Failed to generate version report');
    }
  }

  /**
   * Refresh transaction state from Stripe
   */
  static async refreshTransactionFromStripe(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const adminId = req.user?.id;
      if (!adminId) {
        return ApiResponseUtil.unauthorized(res, 'Admin authentication required');
      }

      const { transactionId } = req.params;

      if (!transactionId) {
        return ApiResponseUtil.badRequest(res, 'Transaction ID is required');
      }

      const result = await AdminService.refreshTransactionFromStripe(adminId, transactionId);

      return ApiResponseUtil.success(res, result, result.message);
    } catch (error: any) {
      logger.error('Refresh transaction error', error);

      if (error.message === 'TRANSACTION_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Transaction not found');
      }

      if (error.message === 'NOT_A_STRIPE_TRANSACTION') {
        return ApiResponseUtil.badRequest(
          res,
          'This transaction is not a Stripe transaction and cannot be refreshed'
        );
      }

      return ApiResponseUtil.internalError(res, 'Failed to refresh transaction from Stripe');
    }
  }
}
