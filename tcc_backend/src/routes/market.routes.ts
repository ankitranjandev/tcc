import { Router } from 'express';
import { MarketController } from '../controllers/market.controller';
import { authenticate } from '../middleware/auth';
import { validate } from '../middleware/validation';
import { z } from 'zod';

const router = Router();

// Validation schemas
const convertCurrencySchema = z.object({
  query: z.object({
    from: z.string().min(3).max(3, 'Currency code must be 3 characters'),
    to: z.string().min(3).max(3, 'Currency code must be 3 characters'),
    amount: z.string().refine((val) => !isNaN(parseFloat(val)) && parseFloat(val) > 0, {
      message: 'Amount must be a positive number',
    }),
  }),
});

const convertMultipleSchema = z.object({
  body: z.object({
    from: z.string().min(3).max(3, 'Currency code must be 3 characters'),
    to: z.array(z.string().min(3).max(3, 'Currency code must be 3 characters')).min(1),
    amount: z.number().positive('Amount must be positive'),
  }),
});

const metalPriceSchema = z.object({
  params: z.object({
    metal: z.string().min(2).max(4, 'Invalid metal symbol'),
  }),
});

// Routes
/**
 * @route   GET /market/metal-prices
 * @desc    Get live metal prices (Gold, Silver, Platinum)
 * @access  Public (no auth required for market data)
 * @query   base - Base currency (default: SLL)
 * @query   metals - Comma-separated metal codes (default: XAU,XAG,XPT)
 */
router.get('/metal-prices', MarketController.getMetalPrices);

/**
 * @route   GET /market/metal-price/:metal
 * @desc    Get specific metal price
 * @access  Public
 * @params  metal - Metal symbol (XAU, XAG, XPT)
 * @query   base - Base currency (default: SLL)
 * @query   unit - Unit (gram, ounce, kilogram) (default: ounce)
 */
router.get(
  '/metal-price/:metal',
  validate(metalPriceSchema),
  MarketController.getSpecificMetalPrice
);

/**
 * @route   GET /market/currency-rates
 * @desc    Get live currency exchange rates
 * @access  Public
 * @query   base - Base currency (default: SLL)
 * @query   currencies - Comma-separated currency codes (default: USD,EUR,GBP,NGN,GHS)
 */
router.get('/currency-rates', MarketController.getCurrencyRates);

/**
 * @route   GET /market/convert
 * @desc    Convert between currencies
 * @access  Public
 * @query   from - Source currency code (required)
 * @query   to - Target currency code (required)
 * @query   amount - Amount to convert (required)
 */
router.get(
  '/convert',
  validate(convertCurrencySchema),
  MarketController.convertCurrency
);

/**
 * @route   POST /market/convert-multiple
 * @desc    Get multiple currency conversions at once
 * @access  Private (requires authentication)
 * @body    from - Source currency code
 * @body    to - Array of target currency codes
 * @body    amount - Amount to convert
 */
router.post(
  '/convert-multiple',
  authenticate,
  validate(convertMultipleSchema),
  MarketController.convertMultiple
);

/**
 * @route   POST /market/clear-cache
 * @desc    Clear market data cache (admin only)
 * @access  Private
 */
router.post('/clear-cache', authenticate, MarketController.clearCache);

export default router;
