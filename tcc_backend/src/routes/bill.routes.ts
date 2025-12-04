import { Router } from 'express';
import { BillController } from '../controllers/bill.controller';
import { authenticate } from '../middleware/auth';
import { validate } from '../middleware/validation';
import { z } from 'zod';
import { BillType, TransactionStatus } from '../types';

const router = Router();

// All routes require authentication
router.use(authenticate);

// Validation schemas
const fetchBillDetailsSchema = z.object({
  body: z.object({
    provider_id: z.string().uuid('Invalid provider ID'),
    account_number: z
      .string()
      .min(3, 'Account number must be at least 3 characters')
      .max(100, 'Account number must not exceed 100 characters'),
  }),
});

const payBillSchema = z.object({
  body: z.object({
    provider_id: z.string().uuid('Invalid provider ID'),
    account_number: z
      .string()
      .min(3, 'Account number must be at least 3 characters')
      .max(100, 'Account number must not exceed 100 characters'),
    amount: z
      .number()
      .positive('Amount must be positive')
      .min(100, 'Minimum bill payment amount is 100'),
    otp: z.string().length(6, 'OTP must be exactly 6 digits'),
    metadata: z
      .object({
        customerName: z.string().max(255).optional(),
        billPeriod: z.string().max(100).optional(),
        dueDate: z.string().optional(),
      })
      .optional(),
  }),
});

const getBillHistorySchema = z.object({
  query: z.object({
    bill_type: z.nativeEnum(BillType).optional(),
    status: z.nativeEnum(TransactionStatus).optional(),
    from_date: z.string().datetime().optional().or(z.string().date().optional()),
    to_date: z.string().datetime().optional().or(z.string().date().optional()),
    search: z.string().max(100).optional(),
    page: z
      .string()
      .regex(/^\d+$/)
      .transform(Number)
      .pipe(z.number().int().positive())
      .optional(),
    limit: z
      .string()
      .regex(/^\d+$/)
      .transform(Number)
      .pipe(z.number().int().positive().max(100))
      .optional(),
  }),
});

const getProvidersSchema = z.object({
  query: z.object({
    category: z.nativeEnum(BillType).optional(),
  }),
});

// Routes
/**
 * @route   GET /bills/providers
 * @desc    Get bill providers by category
 * @access  Private
 * @query   category - Optional bill type filter (WATER, ELECTRICITY, DSTV, INTERNET, MOBILE)
 */
router.get('/providers', validate(getProvidersSchema), BillController.getProviders);

/**
 * @route   POST /bills/fetch-details
 * @desc    Fetch bill details before payment
 * @access  Private
 * @body    provider_id - UUID of the bill provider
 * @body    account_number - Customer account/meter number
 */
router.post('/fetch-details', validate(fetchBillDetailsSchema), BillController.fetchBillDetails);

/**
 * @route   POST /bills/request-otp
 * @desc    Request OTP for bill payment
 * @access  Private
 */
router.post('/request-otp', BillController.requestPaymentOTP);

/**
 * @route   POST /bills/pay
 * @desc    Pay bill with OTP verification
 * @access  Private
 * @body    provider_id - UUID of the bill provider
 * @body    account_number - Customer account/meter number
 * @body    amount - Amount to pay
 * @body    otp - 6-digit OTP for verification
 * @body    metadata - Optional metadata (customerName, billPeriod, dueDate)
 */
router.post('/pay', validate(payBillSchema), BillController.payBill);

/**
 * @route   GET /bills/history
 * @desc    Get bill payment history with filters and pagination
 * @access  Private
 * @query   bill_type - Optional filter by bill type
 * @query   status - Optional filter by status
 * @query   from_date - Optional filter by start date
 * @query   to_date - Optional filter by end date
 * @query   search - Optional search by account number, customer name, or transaction ID
 * @query   page - Page number (default: 1)
 * @query   limit - Items per page (default: 20, max: 100)
 */
router.get('/history', validate(getBillHistorySchema), BillController.getBillHistory);

export default router;
