import { Response } from 'express';
import { AuthRequest } from '../types';
import { WalletService } from '../services/wallet.service';
import { ApiResponseUtil } from '../utils/response';
import logger from '../utils/logger';
import config from '../config';

export class WalletController {
  /**
   * Get wallet balance
   */
  static async getBalance(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const wallet = await WalletService.getBalance(userId);

      return ApiResponseUtil.success(res, {
        wallet: {
          id: wallet.id,
          balance: parseFloat(wallet.balance.toString()),
          currency: wallet.currency,
          tcc_coins: parseFloat(wallet.balance.toString()), // TCC coins = balance
          last_transaction: wallet.last_transaction_at,
        },
      });
    } catch (error: any) {
      logger.error('Get balance error', error);

      if (error.message === 'WALLET_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Wallet not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Deposit money into wallet
   */
  static async deposit(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { amount, payment_method, payment_details, agent_id } = req.body;

      // Prepare metadata
      const metadata = {
        bankAccountId: payment_details?.bank_account_id,
        transactionReference: payment_details?.transaction_reference,
        agentId: agent_id,
        receiptUrl: payment_details?.receipt_url,
      };

      const transaction = await WalletService.deposit(
        userId,
        amount,
        payment_method,
        payment_details?.source || payment_method,
        metadata
      );

      return ApiResponseUtil.created(
        res,
        {
          transaction: {
            id: transaction.id,
            transaction_id: transaction.transaction_id,
            type: transaction.type,
            amount: parseFloat(transaction.amount),
            fee: parseFloat(transaction.fee || 0),
            status: transaction.status,
            payment_method: transaction.payment_method,
            deposit_source: transaction.deposit_source,
            created_at: transaction.created_at,
            estimated_completion: transaction.status === 'PENDING' ? '24-48 hours' : null,
          },
        },
        transaction.status === 'COMPLETED'
          ? 'Deposit completed successfully'
          : 'Deposit request submitted. Your wallet will be credited after verification.'
      );
    } catch (error: any) {
      logger.error('Deposit error', error);

      if (error.message === 'INVALID_AMOUNT') {
        return ApiResponseUtil.badRequest(res, 'Invalid amount');
      }

      if (error.message === 'WALLET_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Wallet not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Create Stripe payment intent for wallet deposit
   */
  static async createPaymentIntent(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { amount } = req.body;

      // Validate amount - must be positive
      if (!amount || amount <= 0) {
        return ApiResponseUtil.badRequest(res, 'Amount must be a positive number');
      }

      const result = await WalletService.createPaymentIntent(userId, amount, req.ip);

      return ApiResponseUtil.success(res, {
        client_secret: result.clientSecret,
        payment_intent_id: result.paymentIntentId,
        transaction_id: result.transactionId,
        amount: result.amount,
        currency: result.currency,
        publishable_key: config.stripe.publishableKey,
      }, 'Payment intent created successfully');
    } catch (error: any) {
      logger.error('Create payment intent error', error);

      if (error.message === 'INVALID_AMOUNT') {
        return ApiResponseUtil.badRequest(res, 'Invalid amount');
      }

      if (error.message === 'WALLET_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Wallet not found');
      }

      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }

      if (error.message.includes('STRIPE')) {
        return ApiResponseUtil.badRequest(res, 'Payment processing error. Please try again.');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Request OTP for withdrawal
   */
  static async requestWithdrawalOTP(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const result = await WalletService.requestTransactionOTP(userId, 'WITHDRAWAL');

      return ApiResponseUtil.success(res, {
        otp_sent: result.otpSent,
        phone: result.phone,
        otp_expires_in: result.otpExpiresIn,
      }, 'OTP sent to your registered phone number');
    } catch (error: any) {
      logger.error('Request withdrawal OTP error', error);

      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Withdraw money from wallet
   */
  static async withdraw(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { amount, bank_account_id, otp } = req.body;

      const transaction = await WalletService.withdraw(userId, amount, bank_account_id, otp);

      return ApiResponseUtil.created(
        res,
        {
          transaction: {
            id: transaction.id,
            transaction_id: transaction.transaction_id,
            type: transaction.type,
            amount: parseFloat(transaction.amount),
            fee: parseFloat(transaction.fee),
            net_amount: parseFloat(transaction.net_amount),
            status: transaction.status,
            bank_account: transaction.bank_account,
            created_at: transaction.created_at,
            estimated_completion: '24-48 hours',
          },
        },
        'Withdrawal request submitted successfully. Amount will be transferred within 24-48 hours.'
      );
    } catch (error: any) {
      logger.error('Withdrawal error', error);

      if (error.message === 'INVALID_AMOUNT') {
        return ApiResponseUtil.badRequest(res, 'Invalid amount');
      }

      if (error.message === 'INSUFFICIENT_BALANCE') {
        return ApiResponseUtil.badRequest(res, 'Insufficient balance');
      }

      if (error.message === 'INVALID_OTP' || error.message.includes('OTP')) {
        return ApiResponseUtil.badRequest(res, error.message);
      }

      if (error.message === 'BANK_ACCOUNT_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Bank account not found');
      }

      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Request OTP for transfer
   */
  static async requestTransferOTP(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const result = await WalletService.requestTransactionOTP(userId, 'TRANSFER');

      return ApiResponseUtil.success(res, {
        otp_sent: result.otpSent,
        phone: result.phone,
        otp_expires_in: result.otpExpiresIn,
      }, 'OTP sent to your registered phone number');
    } catch (error: any) {
      logger.error('Request transfer OTP error', error);

      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Transfer money to another user
   */
  static async transfer(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { recipient_phone, recipient_country_code, amount, note, otp } = req.body;

      const transaction = await WalletService.transfer(
        userId,
        recipient_phone,
        recipient_country_code,
        amount,
        note,
        otp
      );

      return ApiResponseUtil.created(
        res,
        {
          transaction: {
            id: transaction.id,
            transaction_id: transaction.transaction_id,
            type: transaction.type,
            amount: parseFloat(transaction.amount),
            fee: parseFloat(transaction.fee),
            status: transaction.status,
            recipient: transaction.recipient,
            description: transaction.description,
            created_at: transaction.created_at,
          },
        },
        'Transfer completed successfully'
      );
    } catch (error: any) {
      logger.error('Transfer error', error);

      if (error.message === 'INVALID_AMOUNT') {
        return ApiResponseUtil.badRequest(res, 'Invalid amount');
      }

      if (error.message === 'INSUFFICIENT_BALANCE') {
        return ApiResponseUtil.badRequest(res, 'Insufficient balance');
      }

      if (error.message === 'INVALID_OTP' || error.message.includes('OTP')) {
        return ApiResponseUtil.badRequest(res, error.message);
      }

      if (error.message === 'RECIPIENT_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Recipient not found');
      }

      if (error.message === 'CANNOT_TRANSFER_TO_SELF') {
        return ApiResponseUtil.badRequest(res, 'Cannot transfer to yourself');
      }

      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Verify Stripe payment and return updated balance
   */
  static async verifyStripePayment(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { payment_intent_id } = req.body;

      if (!payment_intent_id) {
        return ApiResponseUtil.badRequest(res, 'Payment intent ID is required');
      }

      const result = await WalletService.verifyStripePayment(userId, payment_intent_id);

      return ApiResponseUtil.success(res, result, 'Payment verified successfully');
    } catch (error: any) {
      logger.error('Verify Stripe payment error', error);

      if (error.message === 'TRANSACTION_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Transaction not found');
      }

      if (error.message === 'UNAUTHORIZED') {
        return ApiResponseUtil.unauthorized(res);
      }

      if (error.message === 'PAYMENT_NOT_COMPLETED') {
        return ApiResponseUtil.badRequest(res, 'Payment has not been completed yet');
      }

      if (error.message.includes('STRIPE')) {
        return ApiResponseUtil.badRequest(res, 'Payment verification error. Please try again.');
      }

      return ApiResponseUtil.internalError(res);
    }
  }
}
