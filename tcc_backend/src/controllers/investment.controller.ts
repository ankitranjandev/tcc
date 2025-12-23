import { Response } from 'express';
import { AuthRequest } from '../types';
import { InvestmentService } from '../services/investment.service';
import { ApiResponseUtil } from '../utils/response';
import logger from '../utils/logger';

export class InvestmentController {
  /**
   * Get investment categories with tenures
   */
  static async getCategories(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const categories = await InvestmentService.getCategories();

      return ApiResponseUtil.success(res, { categories });
    } catch (error: any) {
      logger.error('Get categories error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Create new investment
   */
  static async createInvestment(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const {
        category_id,
        sub_category,
        amount,
        tenure_months,
        has_insurance,
      } = req.body;

      const investment = await InvestmentService.createInvestment(
        userId,
        category_id,
        sub_category || null,
        amount,
        tenure_months,
        has_insurance || false
      );

      return ApiResponseUtil.created(
        res,
        { investment },
        'Investment created successfully'
      );
    } catch (error: any) {
      logger.error('Create investment error', error);

      if (error.message === 'INVALID_AMOUNT') {
        return ApiResponseUtil.badRequest(res, 'Invalid amount');
      }

      if (error.message === 'CATEGORY_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Investment category not found');
      }

      if (error.message === 'INVALID_SUB_CATEGORY') {
        return ApiResponseUtil.badRequest(res, 'Invalid sub-category');
      }

      if (error.message === 'TENURE_NOT_FOUND') {
        return ApiResponseUtil.badRequest(
          res,
          'Invalid tenure. Please select a valid tenure for this category.'
        );
      }

      if (error.message === 'INSUFFICIENT_BALANCE') {
        return ApiResponseUtil.badRequest(
          res,
          'Insufficient wallet balance. Please add funds to your wallet.'
        );
      }

      if (error.message === 'WALLET_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Wallet not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get user's investment portfolio
   */
  static async getPortfolio(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const portfolio = await InvestmentService.getPortfolio(userId);

      return ApiResponseUtil.success(res, portfolio);
    } catch (error: any) {
      logger.error('Get portfolio error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get single investment details
   */
  static async getInvestmentDetails(
    req: AuthRequest,
    res: Response
  ): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { investmentId } = req.params;

      const investment = await InvestmentService.getInvestmentDetails(
        userId,
        investmentId
      );

      return ApiResponseUtil.success(res, { investment });
    } catch (error: any) {
      logger.error('Get investment details error', error);

      if (error.message === 'INVESTMENT_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Investment not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Request tenure change
   */
  static async requestTenureChange(
    req: AuthRequest,
    res: Response
  ): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { investmentId } = req.params;
      const { new_tenure_months } = req.body;

      const request = await InvestmentService.requestTenureChange(
        userId,
        investmentId,
        new_tenure_months
      );

      return ApiResponseUtil.created(
        res,
        { request },
        'Tenure change request submitted successfully. An admin will review your request.'
      );
    } catch (error: any) {
      logger.error('Request tenure change error', error);

      if (error.message === 'INVESTMENT_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Investment not found');
      }

      if (error.message === 'INVESTMENT_NOT_ACTIVE') {
        return ApiResponseUtil.badRequest(
          res,
          'Cannot change tenure for inactive investment'
        );
      }

      if (error.message === 'PENDING_REQUEST_EXISTS') {
        return ApiResponseUtil.badRequest(
          res,
          'You already have a pending tenure change request for this investment'
        );
      }

      if (error.message === 'TENURE_NOT_FOUND') {
        return ApiResponseUtil.badRequest(
          res,
          'Invalid tenure. Please select a valid tenure for this category.'
        );
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Request early withdrawal
   */
  static async requestWithdrawal(
    req: AuthRequest,
    res: Response
  ): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { investmentId } = req.params;

      const result = await InvestmentService.requestWithdrawal(userId, investmentId);

      return ApiResponseUtil.success(res, result, result.message);
    } catch (error: any) {
      logger.error('Request withdrawal error', error);

      if (error.message === 'INVESTMENT_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Investment not found');
      }

      if (error.message === 'INVESTMENT_NOT_ACTIVE') {
        return ApiResponseUtil.badRequest(
          res,
          'Cannot withdraw from inactive investment'
        );
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Calculate returns (preview)
   */
  static async calculateReturns(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { amount, tenure_months, return_rate } = req.query;

      if (!amount || !tenure_months || !return_rate) {
        return ApiResponseUtil.badRequest(
          res,
          'Missing required parameters: amount, tenure_months, return_rate'
        );
      }

      const expectedReturn = InvestmentService.calculateReturns(
        parseFloat(amount as string),
        parseInt(tenure_months as string),
        parseFloat(return_rate as string)
      );

      const totalReturn = parseFloat(amount as string) + expectedReturn;

      return ApiResponseUtil.success(res, {
        principal: parseFloat(amount as string),
        tenure_months: parseInt(tenure_months as string),
        return_rate: parseFloat(return_rate as string),
        expected_return: expectedReturn,
        total_return: totalReturn,
      });
    } catch (error: any) {
      logger.error('Calculate returns error', error);
      return ApiResponseUtil.badRequest(res, 'Invalid parameters');
    }
  }

  /**
   * Calculate withdrawal penalty (preview)
   */
  static async calculateWithdrawalPenalty(
    req: AuthRequest,
    res: Response
  ): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { investmentId } = req.params;

      const investment = await InvestmentService.getInvestmentDetails(
        userId,
        investmentId
      );

      const penalty = InvestmentService.calculateWithdrawalPenalty(investment);

      return ApiResponseUtil.success(res, {
        original_amount: parseFloat(investment.amount),
        expected_return: parseFloat(investment.expected_return),
        penalty_percentage: 10,
        penalty_amount: penalty.penalty_amount,
        amount_to_return: penalty.amount_to_return,
        returns_forfeited: parseFloat(investment.expected_return),
        warning:
          'Early withdrawal will result in 10% penalty on principal and forfeiture of all expected returns.',
      });
    } catch (error: any) {
      logger.error('Calculate withdrawal penalty error', error);

      if (error.message === 'INVESTMENT_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Investment not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get all active investment opportunities (public endpoint)
   */
  static async getPublicOpportunities(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const perPage = parseInt(req.query.per_page as string) || 25;

      const filters = {
        category: req.query.category as string | undefined,
        is_active: true, // Only show active opportunities to public
        search: req.query.search as string | undefined,
      };

      // Import AdminService dynamically to avoid circular dependency
      const { AdminService } = await import('../services/admin.service');

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
      logger.error('Get public opportunities error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get single opportunity details (public endpoint)
   */
  static async getPublicOpportunityDetails(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { opportunityId } = req.params;

      // Import AdminService dynamically to avoid circular dependency
      const { AdminService } = await import('../services/admin.service');

      const opportunity = await AdminService.getOpportunityDetails(opportunityId);

      // Only return if opportunity is active
      if (!opportunity.is_active) {
        return ApiResponseUtil.notFound(res, 'Investment opportunity not found');
      }

      return ApiResponseUtil.success(res, opportunity);
    } catch (error: any) {
      if (error.message === 'OPPORTUNITY_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Investment opportunity not found');
      }
      logger.error('Get public opportunity details error', error);
      return ApiResponseUtil.internalError(res);
    }
  }
}
