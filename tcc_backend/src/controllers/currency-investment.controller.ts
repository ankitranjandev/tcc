import { Response } from 'express';
import { AuthRequest, SupportedCurrency } from '../types';
import { CurrencyInvestmentService } from '../services/currency-investment.service';
import { ApiResponseUtil } from '../utils/response';
import logger from '../utils/logger';

export class CurrencyInvestmentController {
  /**
   * Get available currencies with live rates and limits
   */
  static async getAvailableCurrencies(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const currencies = await CurrencyInvestmentService.getAvailableCurrencies();

      return ApiResponseUtil.success(res, {
        currencies,
        timestamp: Date.now(),
      });
    } catch (error: any) {
      logger.error('Get available currencies error', error);
      return ApiResponseUtil.internalError(res, 'Failed to fetch currency rates');
    }
  }

  /**
   * Get investment limits
   */
  static async getLimits(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const limits = await CurrencyInvestmentService.getLimits();

      return ApiResponseUtil.success(res, { limits });
    } catch (error: any) {
      logger.error('Get investment limits error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Buy currency with TCC
   */
  static async buyCurrency(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { currency_code, tcc_amount } = req.body;

      const investment = await CurrencyInvestmentService.buyCurrency(
        userId,
        currency_code as SupportedCurrency,
        tcc_amount
      );

      return ApiResponseUtil.created(
        res,
        { investment },
        `Successfully purchased ${investment.currency_amount.toFixed(2)} ${currency_code}`
      );
    } catch (error: any) {
      logger.error('Buy currency error', error);

      if (error.message === 'INVALID_CURRENCY') {
        return ApiResponseUtil.badRequest(
          res,
          'Invalid currency. Supported currencies: EUR, GBP, JPY, AUD, CAD, CHF, CNY'
        );
      }

      if (error.message === 'INVALID_AMOUNT') {
        return ApiResponseUtil.badRequest(res, 'Invalid amount');
      }

      if (error.message === 'CURRENCY_NOT_AVAILABLE') {
        return ApiResponseUtil.badRequest(res, 'This currency is not available for investment');
      }

      if (error.message.startsWith('MINIMUM_INVESTMENT_')) {
        const minAmount = error.message.replace('MINIMUM_INVESTMENT_', '').replace('_TCC', '');
        return ApiResponseUtil.badRequest(
          res,
          `Minimum investment is ${minAmount} TCC`
        );
      }

      if (error.message.startsWith('MAXIMUM_INVESTMENT_')) {
        const maxAmount = error.message.replace('MAXIMUM_INVESTMENT_', '').replace('_TCC', '');
        return ApiResponseUtil.badRequest(
          res,
          `Maximum investment is ${maxAmount} TCC`
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
   * Get user's currency holdings
   */
  static async getUserHoldings(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const holdings = await CurrencyInvestmentService.getUserHoldings(userId);

      return ApiResponseUtil.success(res, holdings);
    } catch (error: any) {
      logger.error('Get user holdings error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get single holding details
   */
  static async getHoldingDetails(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { investmentId } = req.params;

      const holding = await CurrencyInvestmentService.getHoldingDetails(userId, investmentId);

      return ApiResponseUtil.success(res, { holding });
    } catch (error: any) {
      logger.error('Get holding details error', error);

      if (error.message === 'HOLDING_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Currency holding not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Sell currency holding
   */
  static async sellCurrency(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { investmentId } = req.params;

      const result = await CurrencyInvestmentService.sellCurrency(userId, investmentId);

      const profitLossText = result.profit_loss >= 0
        ? `Profit: +${result.profit_loss.toFixed(2)} TCC`
        : `Loss: ${result.profit_loss.toFixed(2)} TCC`;

      return ApiResponseUtil.success(
        res,
        { sale: result },
        `Successfully sold ${result.currency_sold.toFixed(2)} ${result.currency_code}. ${profitLossText}`
      );
    } catch (error: any) {
      logger.error('Sell currency error', error);

      if (error.message === 'HOLDING_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Currency holding not found');
      }

      if (error.message === 'HOLDING_ALREADY_SOLD') {
        return ApiResponseUtil.badRequest(res, 'This holding has already been sold');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get transaction history
   */
  static async getHistory(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;

      const result = await CurrencyInvestmentService.getHistory(userId, page, limit);

      return ApiResponseUtil.success(res, result);
    } catch (error: any) {
      logger.error('Get currency investment history error', error);
      return ApiResponseUtil.internalError(res);
    }
  }
}
