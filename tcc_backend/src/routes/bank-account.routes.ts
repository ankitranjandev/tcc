import { Router } from 'express';
import { BankAccountController } from '../controllers/bank-account.controller';
import { authenticate, authorize } from '../middleware/auth';
import { validate } from '../middleware/validation';
import { z } from 'zod';
import { UserRole } from '../types';

const router = Router();

// Validation schemas
const createBankAccountSchema = z.object({
  body: z.object({
    bank_name: z.string().min(2).max(255),
    branch_address: z.string().max(500).optional(),
    account_number: z.string().min(5).max(50),
    account_holder_name: z.string().min(2).max(255),
    swift_code: z.string().max(20).optional(),
    routing_number: z.string().max(20).optional(),
    is_primary: z.boolean().optional(),
  }),
});

const updateBankAccountSchema = z.object({
  body: z.object({
    bank_name: z.string().min(2).max(255).optional(),
    branch_address: z.string().max(500).optional(),
    account_number: z.string().min(5).max(50).optional(),
    account_holder_name: z.string().min(2).max(255).optional(),
    swift_code: z.string().max(20).optional(),
    routing_number: z.string().max(20).optional(),
    is_primary: z.boolean().optional(),
  }),
});

/**
 * @route   POST /api/bank-accounts
 * @desc    Create bank account
 * @access  Private
 */
router.post(
  '/',
  authenticate,
  validate(createBankAccountSchema),
  BankAccountController.createBankAccount
);

/**
 * @route   GET /api/bank-accounts
 * @desc    Get user's bank accounts
 * @access  Private
 */
router.get(
  '/',
  authenticate,
  BankAccountController.getUserBankAccounts
);

/**
 * @route   GET /api/bank-accounts/:accountId
 * @desc    Get specific bank account
 * @access  Private
 */
router.get(
  '/:accountId',
  authenticate,
  BankAccountController.getBankAccountById
);

/**
 * @route   PUT /api/bank-accounts/:accountId
 * @desc    Update bank account
 * @access  Private
 */
router.put(
  '/:accountId',
  authenticate,
  validate(updateBankAccountSchema),
  BankAccountController.updateBankAccount
);

/**
 * @route   DELETE /api/bank-accounts/:accountId
 * @desc    Delete bank account
 * @access  Private
 */
router.delete(
  '/:accountId',
  authenticate,
  BankAccountController.deleteBankAccount
);

/**
 * @route   PUT /api/bank-accounts/:accountId/primary
 * @desc    Set primary bank account
 * @access  Private
 */
router.put(
  '/:accountId/primary',
  authenticate,
  BankAccountController.setPrimaryAccount
);

/**
 * @route   GET /api/bank-accounts/admin/:userId
 * @desc    Get user's bank accounts (admin view with masked data)
 * @access  Admin only
 */
router.get(
  '/admin/:userId',
  authenticate,
  authorize(UserRole.ADMIN, UserRole.SUPER_ADMIN),
  BankAccountController.getUserBankAccountsForAdmin
);

export default router;
