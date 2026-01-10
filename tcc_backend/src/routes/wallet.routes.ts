import { Router } from 'express';
import { WalletController } from '../controllers/wallet.controller';
import { authenticate } from '../middleware/auth';
import { validate } from '../middleware/validation';
import { z } from 'zod';

const router = Router();

// Validation schemas
const depositSchema = z.object({
  body: z.object({
    amount: z.number().positive().min(100),
    payment_method: z.enum(['BANK_TRANSFER', 'MOBILE_MONEY', 'AGENT', 'BANK_RECEIPT']),
    payment_details: z
      .object({
        bank_account_id: z.string().uuid().optional(),
        transaction_reference: z.string().optional(),
        receipt_url: z.string().url().optional(),
        source: z
          .enum(['BANK_DEPOSIT', 'AGENT', 'AIRTEL_MONEY', 'INTERNET_BANKING', 'ORANGE_MONEY'])
          .optional(),
      })
      .optional(),
    agent_id: z.string().uuid().optional(),
  }),
});

const paymentIntentSchema = z.object({
  body: z.object({
    amount: z.number().positive(),
  }),
});

const verifyPaymentSchema = z.object({
  body: z.object({
    payment_intent_id: z.string().min(1, 'Payment intent ID is required'),
  }),
});

const withdrawSchema = z.object({
  body: z.object({
    amount: z.number().positive(),
    bank_account_id: z.string().uuid(),
    otp: z.string().length(6),
  }),
});

const transferSchema = z.object({
  body: z.object({
    recipient_phone: z.string().min(10).max(15),
    recipient_country_code: z.string().regex(/^\+\d{1,4}$/),
    amount: z.number().positive().min(100),
    note: z.string().max(200).optional(),
    otp: z.string().length(6),
  }),
});

// Routes
/**
 * @route   GET /wallet/balance
 * @desc    Get wallet balance
 * @access  Private
 */
router.get('/balance', authenticate, WalletController.getBalance);

/**
 * @route   POST /wallet/deposit
 * @desc    Deposit money into wallet
 * @access  Private
 */
router.post('/deposit', authenticate, validate(depositSchema), WalletController.deposit);

/**
 * @route   POST /wallet/create-payment-intent
 * @desc    Create Stripe payment intent for deposit
 * @access  Private
 */
router.post('/create-payment-intent', authenticate, validate(paymentIntentSchema), WalletController.createPaymentIntent);

/**
 * @route   POST /wallet/verify-stripe-payment
 * @desc    Verify Stripe payment and return updated balance
 * @access  Private
 */
router.post('/verify-stripe-payment', authenticate, validate(verifyPaymentSchema), WalletController.verifyStripePayment);

/**
 * @route   POST /wallet/withdraw/request-otp
 * @desc    Request OTP for withdrawal
 * @access  Private
 */
router.post('/withdraw/request-otp', authenticate, WalletController.requestWithdrawalOTP);

/**
 * @route   POST /wallet/withdraw
 * @desc    Withdraw money from wallet
 * @access  Private
 */
router.post('/withdraw', authenticate, validate(withdrawSchema), WalletController.withdraw);

/**
 * @route   POST /wallet/transfer/request-otp
 * @desc    Request OTP for transfer
 * @access  Private
 */
router.post('/transfer/request-otp', authenticate, WalletController.requestTransferOTP);

/**
 * @route   POST /wallet/transfer
 * @desc    Transfer money to another user
 * @access  Private
 */
router.post('/transfer', authenticate, validate(transferSchema), WalletController.transfer);

export default router;
