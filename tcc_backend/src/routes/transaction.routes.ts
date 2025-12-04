import { Router } from 'express';
import { TransactionController } from '../controllers/transaction.controller';
import { authenticate, authorize } from '../middleware/auth';
import { validate } from '../middleware/validation';
import { UserRole } from '../types';
import { z } from 'zod';

const router = Router();

// Validation schemas
const transactionHistorySchema = z.object({
  query: z.object({
    page: z.string().optional().transform(val => (val ? parseInt(val) : 1)),
    limit: z.string().optional().transform(val => (val ? parseInt(val) : 20)),
    type: z.enum(['DEPOSIT', 'WITHDRAWAL', 'TRANSFER', 'BILL_PAYMENT', 'INVESTMENT', 'VOTE', 'COMMISSION', 'AGENT_CREDIT']).optional(),
    status: z.enum(['PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'CANCELLED']).optional(),
    from_date: z.string().optional(),
    to_date: z.string().optional(),
    search: z.string().optional(),
  }),
});

const transactionStatsSchema = z.object({
  query: z.object({
    from_date: z.string().optional(),
    to_date: z.string().optional(),
  }),
});

const processTransactionSchema = z.object({
  body: z.object({
    status: z.enum(['COMPLETED', 'FAILED']),
    failure_reason: z.string().optional(),
  }),
});

// Routes
/**
 * @route   GET /transactions/history
 * @desc    Get transaction history with filters
 * @access  Private
 */
router.get(
  '/history',
  authenticate,
  validate(transactionHistorySchema),
  TransactionController.getTransactionHistory
);

/**
 * @route   GET /transactions/stats
 * @desc    Get transaction statistics
 * @access  Private
 */
router.get(
  '/stats',
  authenticate,
  validate(transactionStatsSchema),
  TransactionController.getTransactionStats
);

/**
 * @route   GET /transactions/:transaction_id
 * @desc    Get single transaction details
 * @access  Private
 */
router.get('/:transaction_id', authenticate, TransactionController.getTransactionDetails);

/**
 * @route   GET /transactions/:transaction_id/receipt
 * @desc    Download transaction receipt
 * @access  Private
 */
router.get('/:transaction_id/receipt', authenticate, TransactionController.downloadReceipt);

/**
 * @route   POST /transactions/:transaction_id/process
 * @desc    Process a transaction (mark as completed or failed)
 * @access  Admin only
 */
router.post(
  '/:transaction_id/process',
  authenticate,
  authorize(UserRole.ADMIN, UserRole.SUPER_ADMIN),
  validate(processTransactionSchema),
  TransactionController.processTransaction
);

export default router;
