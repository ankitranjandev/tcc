import { Router } from 'express';
import { InvestmentController } from '../controllers/investment.controller';
import { authenticate } from '../middleware/auth';
import { validate } from '../middleware/validation';
import { z } from 'zod';

const router = Router();

// Validation schemas
const createInvestmentSchema = z.object({
  body: z.object({
    category_id: z.string().uuid('Invalid category ID'),
    sub_category: z.string().min(1).max(100).optional(),
    amount: z.number().positive('Amount must be positive').min(1000, 'Minimum investment amount is 1000'),
    tenure_months: z.number().int().positive().min(6, 'Minimum tenure is 6 months').max(24, 'Maximum tenure is 24 months'),
    has_insurance: z.boolean().optional().default(false),
  }),
});

const requestTenureChangeSchema = z.object({
  params: z.object({
    investmentId: z.string().uuid('Invalid investment ID'),
  }),
  body: z.object({
    new_tenure_months: z.number().int().positive().min(6, 'Minimum tenure is 6 months').max(24, 'Maximum tenure is 24 months'),
  }),
});

const investmentIdSchema = z.object({
  params: z.object({
    investmentId: z.string().uuid('Invalid investment ID'),
  }),
});

const calculateReturnsSchema = z.object({
  query: z.object({
    amount: z.string().refine((val) => !isNaN(parseFloat(val)) && parseFloat(val) > 0, {
      message: 'Amount must be a positive number',
    }),
    tenure_months: z.string().refine((val) => !isNaN(parseInt(val)) && parseInt(val) >= 6 && parseInt(val) <= 24, {
      message: 'Tenure must be between 6 and 24 months',
    }),
    return_rate: z.string().refine((val) => !isNaN(parseFloat(val)) && parseFloat(val) >= 0, {
      message: 'Return rate must be a positive number',
    }),
  }),
});

// Routes

/**
 * @route   GET /investments/opportunities
 * @desc    Get all active investment opportunities (public)
 * @access  Public
 * NOTE: This route MUST come before /:investmentId to avoid route conflicts
 */
router.get('/opportunities', InvestmentController.getPublicOpportunities);

/**
 * @route   GET /investments/opportunities/:opportunityId
 * @desc    Get single opportunity details (public)
 * @access  Public
 * NOTE: This route MUST come before /:investmentId to avoid route conflicts
 */
router.get('/opportunities/:opportunityId', InvestmentController.getPublicOpportunityDetails);

/**
 * @route   GET /investments/categories
 * @desc    Get investment categories with tenures
 * @access  Private
 */
router.get('/categories', authenticate, InvestmentController.getCategories);

/**
 * @route   POST /investments
 * @desc    Create new investment
 * @access  Private
 */
router.post(
  '/',
  authenticate,
  validate(createInvestmentSchema),
  InvestmentController.createInvestment
);

/**
 * @route   GET /investments/portfolio
 * @desc    Get user's investment portfolio
 * @access  Private
 */
router.get('/portfolio', authenticate, InvestmentController.getPortfolio);

/**
 * @route   GET /investments/calculate-returns
 * @desc    Calculate expected returns (preview)
 * @access  Private
 */
router.get(
  '/calculate-returns',
  authenticate,
  validate(calculateReturnsSchema),
  InvestmentController.calculateReturns
);

/**
 * @route   GET /investments/:investmentId
 * @desc    Get single investment details
 * @access  Private
 * NOTE: This route MUST come after all static routes like /opportunities, /categories, etc.
 */
router.get(
  '/:investmentId',
  authenticate,
  validate(investmentIdSchema),
  InvestmentController.getInvestmentDetails
);

/**
 * @route   POST /investments/:investmentId/request-tenure-change
 * @desc    Request tenure change for investment
 * @access  Private
 */
router.post(
  '/:investmentId/request-tenure-change',
  authenticate,
  validate(requestTenureChangeSchema),
  InvestmentController.requestTenureChange
);

/**
 * @route   GET /investments/:investmentId/withdrawal-penalty
 * @desc    Calculate withdrawal penalty (preview)
 * @access  Private
 */
router.get(
  '/:investmentId/withdrawal-penalty',
  authenticate,
  validate(investmentIdSchema),
  InvestmentController.calculateWithdrawalPenalty
);

/**
 * @route   POST /investments/:investmentId/withdraw
 * @desc    Request early withdrawal from investment
 * @access  Private
 */
router.post(
  '/:investmentId/withdraw',
  authenticate,
  validate(investmentIdSchema),
  InvestmentController.requestWithdrawal
);

export default router;
