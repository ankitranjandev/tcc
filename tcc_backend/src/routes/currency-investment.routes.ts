import { Router } from 'express';
import { CurrencyInvestmentController } from '../controllers/currency-investment.controller';
import { authenticate } from '../middleware/auth';
import { validate } from '../middleware/validation';
import { z } from 'zod';

const router = Router();

// Supported currencies
const supportedCurrencies = ['EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'CHF', 'CNY'] as const;

// Validation schemas
const buyCurrencySchema = z.object({
  body: z.object({
    currency_code: z.enum(supportedCurrencies, {
      errorMap: () => ({ message: 'Invalid currency. Supported: EUR, GBP, JPY, AUD, CAD, CHF, CNY' }),
    }),
    tcc_amount: z
      .number()
      .positive('Amount must be positive')
      .min(10, 'Minimum investment is 10 TCC')
      .max(100000, 'Maximum investment is 100,000 TCC'),
  }),
});

const investmentIdSchema = z.object({
  params: z.object({
    investmentId: z.string().uuid('Invalid investment ID'),
  }),
});

const historyQuerySchema = z.object({
  query: z.object({
    page: z.string().optional().transform((val) => (val ? parseInt(val) : 1)),
    limit: z.string().optional().transform((val) => (val ? parseInt(val) : 20)),
  }),
});

// Routes

/**
 * @route   GET /currency-investments/available
 * @desc    Get available currencies with live rates and limits
 * @access  Private
 */
router.get('/available', authenticate, CurrencyInvestmentController.getAvailableCurrencies);

/**
 * @route   GET /currency-investments/limits
 * @desc    Get investment limits for all currencies
 * @access  Private
 */
router.get('/limits', authenticate, CurrencyInvestmentController.getLimits);

/**
 * @route   POST /currency-investments/buy
 * @desc    Buy currency with TCC
 * @access  Private
 */
router.post(
  '/buy',
  authenticate,
  validate(buyCurrencySchema),
  CurrencyInvestmentController.buyCurrency
);

/**
 * @route   GET /currency-investments/holdings
 * @desc    Get user's currency holdings with current values
 * @access  Private
 */
router.get('/holdings', authenticate, CurrencyInvestmentController.getUserHoldings);

/**
 * @route   GET /currency-investments/holdings/:investmentId
 * @desc    Get single holding details
 * @access  Private
 */
router.get(
  '/holdings/:investmentId',
  authenticate,
  validate(investmentIdSchema),
  CurrencyInvestmentController.getHoldingDetails
);

/**
 * @route   POST /currency-investments/sell/:investmentId
 * @desc    Sell currency holding back to TCC
 * @access  Private
 */
router.post(
  '/sell/:investmentId',
  authenticate,
  validate(investmentIdSchema),
  CurrencyInvestmentController.sellCurrency
);

/**
 * @route   GET /currency-investments/history
 * @desc    Get currency investment transaction history
 * @access  Private
 */
router.get(
  '/history',
  authenticate,
  validate(historyQuerySchema),
  CurrencyInvestmentController.getHistory
);

export default router;