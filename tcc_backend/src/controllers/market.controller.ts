import { Request, Response } from 'express';
import { AuthRequest } from '../types';
import { MetalPriceService } from '../services/metalPrice.service';
import { CurrencyService } from '../services/currency.service';
import { ApiResponseUtil } from '../utils/response';
import logger from '../utils/logger';

export class MarketController {
  /**
   * Get live metal prices (Gold, Silver, Platinum)
   * GET /api/v1/market/metal-prices
   * Query params:
   *   - base: Base currency (default: SLL)
   *   - metals: Comma-separated metal codes (default: XAU,XAG,XPT)
   */
  static async getMetalPrices(req: Request, res: Response): Promise<Response> {
    try {
      const baseCurrency = (req.query.base as string) || 'SLL';
      const metalsParam = (req.query.metals as string) || 'XAU,XAG,XPT';
      const metals = metalsParam.split(',').map((m) => m.trim());

      const prices = await MetalPriceService.getFormattedMetalPrices(baseCurrency);

      return ApiResponseUtil.success(res, {
        base: baseCurrency,
        metals: prices,
        timestamp: prices.timestamp,
      });
    } catch (error: any) {
      logger.error('Get metal prices error:', error);
      return ApiResponseUtil.internalError(
        res,
        'Failed to fetch metal prices. Please try again later.'
      );
    }
  }

  /**
   * Get live currency exchange rates
   * GET /api/v1/market/currency-rates
   * Query params:
   *   - base: Base currency (default: SLL)
   *   - currencies: Comma-separated currency codes (default: USD,EUR,GBP,NGN,GHS)
   */
  static async getCurrencyRates(req: Request, res: Response): Promise<Response> {
    try {
      const baseCurrency = (req.query.base as string) || 'SLL';
      const currenciesParam = (req.query.currencies as string) || 'USD,EUR,GBP,NGN,GHS';
      const currencies = currenciesParam.split(',').map((c) => c.trim());

      const rates = await CurrencyService.getFormattedCurrencyRates(baseCurrency);

      return ApiResponseUtil.success(res, {
        base: rates.base,
        rates: rates.rates,
        timestamp: rates.timestamp,
      });
    } catch (error: any) {
      logger.error('Get currency rates error:', error);
      return ApiResponseUtil.internalError(
        res,
        'Failed to fetch currency rates. Please try again later.'
      );
    }
  }

  /**
   * Convert between currencies
   * GET /api/v1/market/convert
   * Query params:
   *   - from: Source currency code (required)
   *   - to: Target currency code (required)
   *   - amount: Amount to convert (required)
   */
  static async convertCurrency(req: Request, res: Response): Promise<Response> {
    try {
      const { from, to, amount } = req.query;

      if (!from || !to || !amount) {
        return ApiResponseUtil.badRequest(
          res,
          'Missing required parameters: from, to, and amount are required'
        );
      }

      const fromCurrency = (from as string).toUpperCase();
      const toCurrency = (to as string).toUpperCase();
      const amountNum = parseFloat(amount as string);

      if (isNaN(amountNum) || amountNum <= 0) {
        return ApiResponseUtil.badRequest(res, 'Amount must be a positive number');
      }

      const conversion = await CurrencyService.convertCurrency(
        fromCurrency,
        toCurrency,
        amountNum
      );

      return ApiResponseUtil.success(res, {
        conversion,
      });
    } catch (error: any) {
      logger.error('Currency conversion error:', error);

      if (error.message.includes('Exchange rate not found')) {
        return ApiResponseUtil.badRequest(res, error.message);
      }

      return ApiResponseUtil.internalError(
        res,
        'Failed to convert currency. Please try again later.'
      );
    }
  }

  /**
   * Get multiple currency conversions at once
   * POST /api/v1/market/convert-multiple
   * Body:
   *   - from: Source currency code
   *   - to: Array of target currency codes
   *   - amount: Amount to convert
   */
  static async convertMultiple(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { from, to, amount } = req.body;

      if (!from || !to || !Array.isArray(to) || to.length === 0 || !amount) {
        return ApiResponseUtil.badRequest(
          res,
          'Missing required parameters: from, to (array), and amount are required'
        );
      }

      const fromCurrency = from.toUpperCase();
      const toCurrencies = to.map((c: string) => c.toUpperCase());
      const amountNum = parseFloat(amount);

      if (isNaN(amountNum) || amountNum <= 0) {
        return ApiResponseUtil.badRequest(res, 'Amount must be a positive number');
      }

      const conversions = await CurrencyService.getMultipleConversions(
        fromCurrency,
        toCurrencies,
        amountNum
      );

      return ApiResponseUtil.success(res, {
        conversions,
      });
    } catch (error: any) {
      logger.error('Multiple currency conversion error:', error);
      return ApiResponseUtil.internalError(
        res,
        'Failed to convert currencies. Please try again later.'
      );
    }
  }

  /**
   * Get specific metal price
   * GET /api/v1/market/metal-price/:metal
   * Params:
   *   - metal: Metal symbol (XAU, XAG, XPT)
   * Query params:
   *   - base: Base currency (default: SLL)
   *   - unit: Unit (gram, ounce, kilogram) (default: ounce)
   */
  static async getSpecificMetalPrice(req: Request, res: Response): Promise<Response> {
    try {
      const { metal } = req.params;
      const baseCurrency = (req.query.base as string) || 'SLL';
      const unit = (req.query.unit as string) || 'ounce';

      if (!metal) {
        return ApiResponseUtil.badRequest(res, 'Metal symbol is required');
      }

      const metalCode = metal.toUpperCase();
      const priceData = await MetalPriceService.getMetalPrice(metalCode, baseCurrency);

      let finalPrice = priceData.price;
      if (unit !== 'ounce') {
        finalPrice = MetalPriceService.convertMetalPriceUnit(
          priceData.price,
          unit as 'gram' | 'ounce' | 'kilogram'
        );
      }

      return ApiResponseUtil.success(res, {
        metal: metalCode,
        price: finalPrice,
        unit,
        currency: baseCurrency,
        timestamp: priceData.timestamp,
      });
    } catch (error: any) {
      logger.error('Get specific metal price error:', error);

      if (error.message.includes('Price not found')) {
        return ApiResponseUtil.notFound(res, error.message);
      }

      return ApiResponseUtil.internalError(
        res,
        'Failed to fetch metal price. Please try again later.'
      );
    }
  }

  /**
   * Clear market data cache (admin only)
   * POST /api/v1/market/clear-cache
   */
  static async clearCache(req: AuthRequest, res: Response): Promise<Response> {
    try {
      MetalPriceService.clearCache();
      CurrencyService.clearCache();

      return ApiResponseUtil.success(res, {
        message: 'Market data cache cleared successfully',
      });
    } catch (error: any) {
      logger.error('Clear cache error:', error);
      return ApiResponseUtil.internalError(res);
    }
  }
}
