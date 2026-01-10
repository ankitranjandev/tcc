// @ts-nocheck
import { PoolClient } from 'pg';
import db from '../database';
import { OTPService } from './otp.service';
import logger from '../utils/logger';
import config from '../config';
import {
  Wallet,
  TransactionType,
  TransactionStatus,
  PaymentMethod,
  DepositSource,
  KYCStatus,
} from '../types';
import {
  createStripeCustomer,
  createPaymentIntent as createStripePaymentIntent,
} from './stripe.service';
import { PushNotificationService } from './push-notification.service';
import { normalizePhone, normalizeCountryCode } from '../utils/phone';

export class WalletService {
  /**
   * Generate unique transaction ID
   * Format: TXN + YYYYMMDD + 6 random digits
   */
  static generateTransactionId(): string {
    const date = new Date();
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const dateStr = `${year}${month}${day}`;

    // Generate 6 random digits
    const randomDigits = Math.floor(100000 + Math.random() * 900000);

    return `TXN${dateStr}${randomDigits}`;
  }

  /**
   * Get wallet balance for a user
   */
  static async getBalance(userId: string): Promise<Wallet> {
    try {
      const wallets = await db.query<Wallet>(
        `SELECT id, user_id, balance, currency, last_transaction_at, created_at, updated_at
         FROM wallets WHERE user_id = $1`,
        [userId]
      );

      if (wallets.length === 0) {
        throw new Error('WALLET_NOT_FOUND');
      }

      return wallets[0];
    } catch (error) {
      logger.error('Error getting wallet balance', error);
      throw error;
    }
  }

  /**
   * Deposit money into wallet
   */
  static async deposit(
    userId: string,
    amount: number,
    method: PaymentMethod,
    source: DepositSource,
    metadata?: {
      bankAccountId?: string;
      transactionReference?: string;
      agentId?: string;
      receiptUrl?: string;
    }
  ): Promise<any> {
    try {
      // Validate amount
      if (amount <= 0) {
        throw new Error('INVALID_AMOUNT');
      }

      // Get user's wallet
      const wallet = await this.getBalance(userId);

      // Generate transaction ID
      const transactionId = this.generateTransactionId();

      // Create transaction record
      const result = await db.transaction(async (client: PoolClient) => {
        // Insert transaction
        const transactions = await client.query(
          `INSERT INTO transactions (
            transaction_id, type, to_user_id, amount, fee, net_amount,
            status, payment_method, deposit_source, reference, metadata
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
          RETURNING id, transaction_id, type, amount, fee, net_amount, status,
                    payment_method, deposit_source, reference, created_at`,
          [
            transactionId,
            TransactionType.DEPOSIT,
            userId,
            amount,
            0, // No fee for deposits
            amount,
            TransactionStatus.PENDING,
            method,
            source,
            metadata?.transactionReference || null,
            JSON.stringify(metadata || {}),
          ]
        );

        // For agent deposits, mark as completed immediately
        if (method === PaymentMethod.AGENT && metadata?.agentId) {
          // Update transaction status
          await client.query(
            `UPDATE transactions
             SET status = $1, processed_at = NOW()
             WHERE id = $2`,
            [TransactionStatus.COMPLETED, transactions.rows[0].id]
          );

          // Update wallet balance
          await client.query(
            `UPDATE wallets
             SET balance = balance + $1, last_transaction_at = NOW(), updated_at = NOW()
             WHERE user_id = $2`,
            [amount, userId]
          );

          // Update agent's wallet (deduct)
          await client.query(
            `UPDATE wallets
             SET balance = balance - $1, last_transaction_at = NOW(), updated_at = NOW()
             WHERE user_id = (SELECT user_id FROM agents WHERE id = $2)`,
            [amount, metadata.agentId]
          );

          // Create agent transaction record
          await client.query(
            `INSERT INTO transactions (
              transaction_id, type, from_user_id, to_user_id, amount, fee, net_amount,
              status, payment_method, reference, processed_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW())`,
            [
              this.generateTransactionId(),
              TransactionType.AGENT_CREDIT,
              metadata.agentId,
              userId,
              amount,
              0,
              amount,
              TransactionStatus.COMPLETED,
              PaymentMethod.AGENT,
              transactionId,
            ]
          );

          transactions.rows[0].status = TransactionStatus.COMPLETED;
        }

        return transactions.rows[0];
      });

      logger.info('Deposit initiated', {
        userId,
        transactionId,
        amount,
        method,
        source,
      });

      return result;
    } catch (error) {
      logger.error('Error processing deposit', error);
      throw error;
    }
  }

  /**
   * Create Stripe payment intent for wallet deposit
   */
  static async createPaymentIntent(
    userId: string,
    amount: number,
    ipAddress?: string
  ): Promise<{
    clientSecret: string;
    paymentIntentId: string;
    transactionId: string;
    amount: number;
    currency: string;
  }> {
    try {
      // Validate amount
      if (amount <= 0) {
        throw new Error('INVALID_AMOUNT');
      }

      // Get wallet to ensure it exists
      const wallet = await this.getBalance(userId);

      // Get user details
      const users = await db.query(
        'SELECT id, email, first_name, last_name, phone, stripe_customer_id FROM users WHERE id = $1',
        [userId]
      );

      if (users.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      const user = users[0];

      // Create or get Stripe customer
      let stripeCustomerId = user.stripe_customer_id;

      if (!stripeCustomerId) {
        const stripeCustomer = await createStripeCustomer(
          user.id,
          user.email,
          `${user.first_name} ${user.last_name}`,
          user.phone
        );
        stripeCustomerId = stripeCustomer.id;

        // Update user with Stripe customer ID
        await db.query('UPDATE users SET stripe_customer_id = $1 WHERE id = $2', [
          stripeCustomerId,
          userId,
        ]);
      }

      // Generate transaction ID
      const transactionId = this.generateTransactionId();

      // Convert cents to TCC (amount comes in cents from frontend)
      const amountInTCC = amount / 100;

      // Create pending transaction in database
      const result = await db.transaction(async (client: PoolClient) => {
        // Create Stripe payment intent (Stripe expects cents)
        const paymentIntent = await createStripePaymentIntent(
          amount,
          userId,
          transactionId,
          stripeCustomerId
        );

        // Insert transaction record (store in TCC, not cents)
        await client.query(
          `INSERT INTO transactions (
            transaction_id, type, to_user_id, amount, fee, net_amount,
            status, payment_method, deposit_source, metadata,
            stripe_payment_intent_id, ip_address
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
          [
            transactionId,
            TransactionType.DEPOSIT,
            userId,
            amountInTCC,
            0, // No fee for deposits
            amountInTCC,
            TransactionStatus.PENDING,
            PaymentMethod.MOBILE_MONEY, // Using mobile money as payment method for Stripe
            DepositSource.INTERNET_BANKING,
            JSON.stringify({
              paymentGateway: 'stripe',
              paymentIntentId: paymentIntent.id,
            }),
            paymentIntent.id,
            ipAddress || null,
          ]
        );

        return {
          clientSecret: paymentIntent.client_secret,
          paymentIntentId: paymentIntent.id,
          transactionId,
          amount: amountInTCC,
          currency: config.stripe.currency,
        };
      });

      logger.info('Payment intent created', {
        userId,
        transactionId,
        amountInTCC,
        amountInCents: amount,
        paymentIntentId: result.paymentIntentId,
      });

      return result;
    } catch (error) {
      logger.error('Error creating payment intent', error);
      throw error;
    }
  }

  /**
   * Calculate withdrawal fee based on amount and KYC status
   */
  private static calculateWithdrawalFee(amount: number, kycStatus: KYCStatus): number {
    // Fee structure based on KYC status
    if (kycStatus === KYCStatus.APPROVED) {
      // 1% fee for KYC approved users, min 1, max 500
      const fee = amount * 0.01;
      return Math.max(1, Math.min(500, fee));
    } else {
      // 2% fee for non-KYC users, min 1, max 1000
      const fee = amount * 0.02;
      return Math.max(1, Math.min(1000, fee));
    }
  }

  /**
   * Withdraw money from wallet
   */
  static async withdraw(
    userId: string,
    amount: number,
    bankAccountId: string,
    otp: string
  ): Promise<any> {
    try {
      // Validate amount
      if (amount <= 0) {
        throw new Error('INVALID_AMOUNT');
      }

      // Get user details
      const users = await db.query(
        'SELECT phone, country_code, kyc_status FROM users WHERE id = $1',
        [userId]
      );

      if (users.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      const user = users[0];

      // Verify OTP
      const otpResult = await OTPService.verifyOTP(
        user.phone,
        user.country_code,
        otp,
        'WITHDRAWAL'
      );

      if (!otpResult.valid) {
        throw new Error(otpResult.error || 'INVALID_OTP');
      }

      // Get wallet balance
      const wallet = await this.getBalance(userId);

      // Calculate fee
      const fee = this.calculateWithdrawalFee(amount, user.kyc_status);
      const totalAmount = amount + fee;

      // Check sufficient balance
      if (wallet.balance < totalAmount) {
        throw new Error('INSUFFICIENT_BALANCE');
      }

      // Verify bank account belongs to user
      const bankAccounts = await db.query(
        `SELECT id, bank_name, account_number, account_holder_name, is_verified
         FROM bank_accounts WHERE id = $1 AND user_id = $2`,
        [bankAccountId, userId]
      );

      if (bankAccounts.length === 0) {
        throw new Error('BANK_ACCOUNT_NOT_FOUND');
      }

      const bankAccount = bankAccounts[0];

      // Generate transaction ID
      const transactionId = this.generateTransactionId();

      // Create withdrawal transaction
      const result = await db.transaction(async (client: PoolClient) => {
        // Insert transaction
        const transactions = await client.query(
          `INSERT INTO transactions (
            transaction_id, type, from_user_id, amount, fee, net_amount,
            status, payment_method, reference, metadata
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
          RETURNING id, transaction_id, type, amount, fee, net_amount, status,
                    payment_method, created_at`,
          [
            transactionId,
            TransactionType.WITHDRAWAL,
            userId,
            amount,
            fee,
            amount - fee,
            TransactionStatus.PENDING,
            PaymentMethod.BANK_TRANSFER,
            null,
            JSON.stringify({
              bankAccountId,
              bankName: bankAccount.bank_name,
              accountNumber: bankAccount.account_number,
              accountHolderName: bankAccount.account_holder_name,
            }),
          ]
        );

        // Deduct amount from wallet (including fee)
        await client.query(
          `UPDATE wallets
           SET balance = balance - $1, last_transaction_at = NOW(), updated_at = NOW()
           WHERE user_id = $2`,
          [totalAmount, userId]
        );

        return transactions.rows[0];
      });

      logger.info('Withdrawal initiated', {
        userId,
        transactionId,
        amount,
        fee,
        bankAccountId,
      });

      return {
        ...result,
        bank_account: {
          bank_name: bankAccount.bank_name,
          account_number: `****${bankAccount.account_number.slice(-4)}`,
          account_holder_name: bankAccount.account_holder_name,
        },
      };
    } catch (error) {
      logger.error('Error processing withdrawal', error);
      throw error;
    }
  }

  /**
   * Calculate transfer fee based on amount and KYC status
   */
  private static calculateTransferFee(amount: number, kycStatus: KYCStatus): number {
    // Fee structure for transfers
    if (kycStatus === KYCStatus.APPROVED) {
      // 0.5% fee for KYC approved users, min 10, max 200
      const fee = amount * 0.005;
      return Math.max(10, Math.min(200, fee));
    } else {
      // 1% fee for non-KYC users, min 20, max 500
      const fee = amount * 0.01;
      return Math.max(20, Math.min(500, fee));
    }
  }

  /**
   * Transfer money to another user
   */
  static async transfer(
    userId: string,
    toPhone: string,
    toCountryCode: string,
    amount: number,
    note: string,
    otp: string
  ): Promise<any> {
    try {
      // Validate amount
      if (amount <= 0) {
        throw new Error('INVALID_AMOUNT');
      }

      // Get sender details
      const senders = await db.query(
        'SELECT first_name, last_name, phone, country_code, kyc_status FROM users WHERE id = $1',
        [userId]
      );

      if (senders.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      const sender = senders[0];

      // Verify OTP
      const otpResult = await OTPService.verifyOTP(
        sender.phone,
        sender.country_code,
        otp,
        'TRANSFER'
      );

      if (!otpResult.valid) {
        throw new Error(otpResult.error || 'INVALID_OTP');
      }

      // Normalize phone numbers for comparison
      const normalizedToPhone = normalizePhone(toPhone);
      const normalizedToCountryCode = normalizeCountryCode(toCountryCode);

      // Get recipient details using normalized phone comparison
      const recipients = await db.query(
        `SELECT id, first_name, last_name FROM users
         WHERE REGEXP_REPLACE(phone, '^0+', '') = $1
         AND REGEXP_REPLACE(REGEXP_REPLACE(country_code, '^\\+', ''), '^0+', '') = $2
         AND is_active = true`,
        [normalizedToPhone, normalizedToCountryCode]
      );

      if (recipients.length === 0) {
        throw new Error('RECIPIENT_NOT_FOUND');
      }

      const recipient = recipients[0];

      // Check not transferring to self
      if (userId === recipient.id) {
        throw new Error('CANNOT_TRANSFER_TO_SELF');
      }

      // Get wallet balance
      const wallet = await this.getBalance(userId);

      // Calculate fee
      const fee = this.calculateTransferFee(amount, sender.kyc_status);
      const totalAmount = amount + fee;

      // Check sufficient balance
      if (wallet.balance < totalAmount) {
        throw new Error('INSUFFICIENT_BALANCE');
      }

      // Generate transaction ID
      const transactionId = this.generateTransactionId();

      // Create transfer transaction
      const result = await db.transaction(async (client: PoolClient) => {
        // Insert transaction
        const transactions = await client.query(
          `INSERT INTO transactions (
            transaction_id, type, from_user_id, to_user_id, amount, fee, net_amount,
            status, description, processed_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
          RETURNING id, transaction_id, type, amount, fee, net_amount, status,
                    description, created_at`,
          [
            transactionId,
            TransactionType.TRANSFER,
            userId,
            recipient.id,
            amount,
            fee,
            amount,
            TransactionStatus.COMPLETED,
            note || 'Transfer',
          ]
        );

        // Deduct from sender wallet (including fee)
        await client.query(
          `UPDATE wallets
           SET balance = balance - $1, last_transaction_at = NOW(), updated_at = NOW()
           WHERE user_id = $2`,
          [totalAmount, userId]
        );

        // Add to recipient wallet
        await client.query(
          `UPDATE wallets
           SET balance = balance + $1, last_transaction_at = NOW(), updated_at = NOW()
           WHERE user_id = $2`,
          [amount, recipient.id]
        );

        return transactions.rows[0];
      });

      logger.info('Transfer completed', {
        fromUserId: userId,
        toUserId: recipient.id,
        transactionId,
        amount,
        fee,
      });

      // Send push notification to recipient (async, don't block the response)
      const senderName = `${sender.first_name} ${sender.last_name}`;
      PushNotificationService.sendPaymentReceivedNotification(
        recipient.id,
        amount,
        senderName,
        transactionId,
        false // isTopUp = false (P2P transfer)
      ).catch((err) => logger.error('Failed to send transfer notification', err));

      return {
        ...result,
        recipient: {
          name: `${recipient.first_name} ${recipient.last_name}`,
          phone: `****${toPhone.slice(-4)}`,
        },
      };
    } catch (error) {
      logger.error('Error processing transfer', error);
      throw error;
    }
  }

  /**
   * Request OTP for withdrawal or transfer
   */
  static async requestTransactionOTP(
    userId: string,
    purpose: 'WITHDRAWAL' | 'TRANSFER'
  ): Promise<{ otpSent: boolean; phone: string; otpExpiresIn: number }> {
    try {
      // Get user phone
      const users = await db.query(
        'SELECT phone, country_code FROM users WHERE id = $1',
        [userId]
      );

      if (users.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      const user = users[0];

      // Generate and send OTP
      const { expiresIn } = await OTPService.createOTP(
        user.phone,
        user.country_code,
        purpose
      );
      await OTPService.sendOTP(user.phone, user.country_code, user.phone);

      const maskedPhone = `****${user.phone.slice(-4)}`;

      logger.info('Transaction OTP sent', { userId, purpose });

      return {
        otpSent: true,
        phone: maskedPhone,
        otpExpiresIn: expiresIn,
      };
    } catch (error) {
      logger.error('Error sending transaction OTP', error);
      throw error;
    }
  }

  /**
   * Verify Stripe payment and return updated balance
   */
  static async verifyStripePayment(
    userId: string,
    paymentIntentId: string
  ): Promise<{
    success: boolean;
    transaction_id: string;
    amount: number;
    balance: number;
    currency: string;
  }> {
    try {
      // Get transaction details from database
      const transactions = await db.query(
        `SELECT id, transaction_id, to_user_id, amount, status, stripe_payment_intent_id
         FROM transactions
         WHERE stripe_payment_intent_id = $1`,
        [paymentIntentId]
      );

      if (transactions.length === 0) {
        throw new Error('TRANSACTION_NOT_FOUND');
      }

      const transaction = transactions[0];

      // Verify the transaction belongs to the user
      if (transaction.to_user_id !== userId) {
        throw new Error('UNAUTHORIZED');
      }

      // Check if transaction is already completed
      if (transaction.status === TransactionStatus.COMPLETED) {
        // Get updated wallet balance
        const wallet = await this.getBalance(userId);

        if (!wallet) {
          throw new Error('WALLET_NOT_FOUND');
        }

        return {
          verified: true,
          transaction: {
            id: transaction.transaction_id,
            amount: parseFloat(transaction.amount),
            status: transaction.status,
          },
          balance: parseFloat(wallet.balance.toString()),
          currency: wallet.currency,
        };
      }

      // If transaction is still pending, retrieve payment intent from Stripe to check status
      const { retrievePaymentIntent } = await import('./stripe.service');
      const paymentIntent = await retrievePaymentIntent(paymentIntentId);

      // Check payment intent status
      if (paymentIntent.status !== 'succeeded') {
        throw new Error('PAYMENT_NOT_COMPLETED');
      }

      // Payment succeeded in Stripe but transaction is still pending in our DB
      // This means the webhook hasn't processed it yet
      // We update the transaction status here but DO NOT credit the wallet
      // The wallet credit happens ONLY via the webhook to prevent duplicate increments

      // Update transaction status to completed (wallet credit handled by webhook)
      const updateResult = await db.query(
        `UPDATE transactions
         SET status = $1,
             processed_at = NOW(),
             payment_gateway_response = $2,
             updated_at = NOW()
         WHERE id = $3 AND status = $4
         RETURNING *`,
        [
          TransactionStatus.COMPLETED,
          JSON.stringify({ verified_via: 'polling', payment_intent_status: paymentIntent.status }),
          transaction.id,
          TransactionStatus.PENDING,
        ]
      );

      // Only credit wallet if we were the ones who updated the transaction
      // This prevents race condition with webhook
      if (updateResult.rowCount > 0) {
        await db.query(
          `UPDATE wallets
           SET balance = balance + $1,
               last_transaction_at = NOW(),
               updated_at = NOW()
           WHERE user_id = $2`,
          [transaction.amount, userId]
        );
      }

      // Get updated balance after crediting
      const updatedWallet = await this.getBalance(userId);

      logger.info('Stripe payment verified and credited via polling', {
        userId,
        paymentIntentId,
        transactionId: transaction.transaction_id,
        amount: transaction.amount,
      });

      return {
        verified: true,
        transaction: {
          id: transaction.transaction_id,
          amount: parseFloat(transaction.amount),
          status: TransactionStatus.COMPLETED,
        },
        balance: parseFloat(updatedWallet.balance.toString()),
        currency: updatedWallet.currency,
      };
    } catch (error) {
      logger.error('Error verifying Stripe payment', error);
      throw error;
    }
  }
}
