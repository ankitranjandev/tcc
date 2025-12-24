// @ts-nocheck
import { PoolClient } from 'pg';
import db from '../database';
import { OTPService } from './otp.service';
import { WalletService } from './wallet.service';
import logger from '../utils/logger';
import {
  BillType,
  TransactionType,
  TransactionStatus,
  PaginationParams,
} from '../types';

export interface BillProvider {
  id: string;
  name: string;
  category: BillType;
  logo_url?: string;
  fields_required: string[];
  is_active: boolean;
}

export interface BillDetails {
  account_number: string;
  customer_name: string;
  amount_due?: number;
  bill_period?: string;
  due_date?: string;
}

export interface BillPaymentFilters {
  bill_type?: BillType;
  status?: TransactionStatus;
  fromDate?: Date;
  toDate?: Date;
  search?: string;
}

export class BillService {
  /**
   * Get bill providers by category
   */
  static async getProviders(category?: BillType): Promise<BillProvider[]> {
    try {
      let query = `
        SELECT id, name, type as category, logo_url, metadata, is_active
        FROM bill_providers
        WHERE is_active = true
      `;
      const params: any[] = [];

      if (category) {
        query += ' AND type = $1';
        params.push(category);
      }

      query += ' ORDER BY name ASC';

      const providers = await db.query<any>(query, params);

      // Format providers with fields_required from metadata
      return providers.map((provider) => {
        let metadata = {};
        if (provider.metadata) {
          try {
            metadata =
              typeof provider.metadata === 'string'
                ? JSON.parse(provider.metadata)
                : provider.metadata;
          } catch (e) {
            logger.warn('Failed to parse provider metadata', { providerId: provider.id });
          }
        }

        // Default fields required for bill payments
        const defaultFields = ['account_number'];
        const fieldsRequired = (metadata as any).fields_required || defaultFields;

        return {
          id: provider.id,
          name: provider.name,
          category: provider.category,
          logo_url: provider.logo_url,
          fields_required: fieldsRequired,
          is_active: provider.is_active,
        };
      });
    } catch (error) {
      logger.error('Error getting bill providers', error);
      throw error;
    }
  }

  /**
   * Fetch bill details before payment
   * This is a mock implementation - TODO: Integrate with actual provider APIs
   */
  static async fetchBillDetails(
    providerId: string,
    accountNumber: string
  ): Promise<BillDetails> {
    try {
      // Verify provider exists
      const providers = await db.query(
        'SELECT id, name, type, api_endpoint FROM bill_providers WHERE id = $1 AND is_active = true',
        [providerId]
      );

      if (providers.length === 0) {
        throw new Error('PROVIDER_NOT_FOUND');
      }

      const provider = providers[0];

      // TODO: Integrate with actual provider API
      // For now, return mock data
      logger.info('Fetching bill details (MOCK)', { providerId, accountNumber });

      // Mock response - simulate API call delay
      await new Promise((resolve) => setTimeout(resolve, 500));

      // Return mock bill details
      const mockDetails: BillDetails = {
        account_number: accountNumber,
        customer_name: this.generateMockCustomerName(),
        amount_due: this.generateMockAmount(provider.type),
        bill_period: this.getCurrentBillPeriod(),
        due_date: this.getDueDate(),
      };

      logger.info('Bill details fetched (MOCK)', { providerId, accountNumber, details: mockDetails });

      return mockDetails;
    } catch (error) {
      logger.error('Error fetching bill details', error);
      throw error;
    }
  }

  /**
   * Pay bill with OTP verification
   */
  static async payBill(
    userId: string,
    providerId: string,
    accountNumber: string,
    amount: number,
    otp: string,
    metadata?: {
      customerName?: string;
      billPeriod?: string;
      dueDate?: string;
    }
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
        'BILL_PAYMENT'
      );

      if (!otpResult.valid) {
        throw new Error(otpResult.error || 'INVALID_OTP');
      }

      // Verify provider exists
      const providers = await db.query(
        'SELECT id, name, type FROM bill_providers WHERE id = $1 AND is_active = true',
        [providerId]
      );

      if (providers.length === 0) {
        throw new Error('PROVIDER_NOT_FOUND');
      }

      const provider = providers[0];

      // Get wallet balance
      const wallet = await WalletService.getBalance(userId);

      // Calculate fee (1% for bill payments)
      const fee = Math.max(20, amount * 0.01);
      const totalAmount = amount + fee;

      // Check sufficient balance
      if (wallet.balance < totalAmount) {
        throw new Error('INSUFFICIENT_BALANCE');
      }

      // Generate transaction ID
      const transactionId = WalletService.generateTransactionId();

      // Create bill payment transaction
      const result = await db.transaction(async (client: PoolClient) => {
        // Insert transaction
        const transactions = await client.query(
          `INSERT INTO transactions (
            transaction_id, type, from_user_id, amount, fee, net_amount,
            status, description, metadata, processed_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
          RETURNING id, transaction_id, type, amount, fee, net_amount, status,
                    description, created_at, processed_at`,
          [
            transactionId,
            TransactionType.BILL_PAYMENT,
            userId,
            amount,
            fee,
            amount,
            TransactionStatus.COMPLETED,
            `Bill payment to ${provider.name}`,
            JSON.stringify({
              providerId,
              providerName: provider.name,
              accountNumber,
              customerName: metadata?.customerName,
              billPeriod: metadata?.billPeriod,
              dueDate: metadata?.dueDate,
            }),
          ]
        );

        const transaction = transactions[0];

        // Deduct from wallet (including fee)
        await client.query(
          `UPDATE wallets
           SET balance = balance - $1, last_transaction_at = NOW(), updated_at = NOW()
           WHERE user_id = $2`,
          [totalAmount, userId]
        );

        // TODO: Integrate with actual provider API to process payment
        // For now, we'll mark as completed and store in bill_payments table
        const providerTransactionId = `MOCK-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

        // Insert bill payment record
        await client.query(
          `INSERT INTO bill_payments (
            user_id, provider_id, bill_type, bill_id, bill_holder_name,
            amount, transaction_id, provider_transaction_id, status, processed_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())`,
          [
            userId,
            providerId,
            provider.type,
            accountNumber,
            metadata?.customerName || 'N/A',
            amount,
            transaction.id,
            providerTransactionId,
            TransactionStatus.COMPLETED,
          ]
        );

        logger.info('Bill payment completed', {
          userId,
          transactionId,
          providerId,
          amount,
          fee,
        });

        return {
          transaction,
          providerTransactionId,
          provider,
        };
      });

      return {
        transaction_id: result.transaction.transaction_id,
        reference_number: result.providerTransactionId,
        status: result.transaction.status,
        provider: {
          id: result.provider.id,
          name: result.provider.name,
          type: result.provider.type,
        },
        account_number: accountNumber,
        customer_name: metadata?.customerName,
        amount: parseFloat(result.transaction.amount),
        fee: parseFloat(result.transaction.fee),
        total_amount: totalAmount,
        created_at: result.transaction.created_at,
        completed_at: result.transaction.processed_at,
      };
    } catch (error) {
      logger.error('Error processing bill payment', error);
      throw error;
    }
  }

  /**
   * Get bill payment history with filters and pagination
   */
  static async getBillHistory(
    userId: string,
    filters: BillPaymentFilters = {},
    pagination: PaginationParams
  ): Promise<{
    payments: any[];
    pagination: {
      page: number;
      limit: number;
      total: number;
      totalPages: number;
    };
  }> {
    try {
      // Build WHERE clause
      const conditions: string[] = ['bp.user_id = $1'];
      const params: any[] = [userId];
      let paramCount = 2;

      // Add filters
      if (filters.bill_type) {
        conditions.push(`bp.bill_type = $${paramCount}`);
        params.push(filters.bill_type);
        paramCount++;
      }

      if (filters.status) {
        conditions.push(`bp.status = $${paramCount}`);
        params.push(filters.status);
        paramCount++;
      }

      if (filters.fromDate) {
        conditions.push(`bp.created_at >= $${paramCount}`);
        params.push(filters.fromDate);
        paramCount++;
      }

      if (filters.toDate) {
        conditions.push(`bp.created_at <= $${paramCount}`);
        params.push(filters.toDate);
        paramCount++;
      }

      if (filters.search) {
        conditions.push(
          `(bp.bill_id ILIKE $${paramCount} OR bp.bill_holder_name ILIKE $${paramCount} OR t.transaction_id ILIKE $${paramCount})`
        );
        params.push(`%${filters.search}%`);
        paramCount++;
      }

      const whereClause = conditions.join(' AND ');

      // Get total count
      const countResult = await db.query(
        `SELECT COUNT(*) as total FROM bill_payments bp WHERE ${whereClause}`,
        params
      );
      const total = parseInt(countResult[0].total);

      // Get bill payments
      const payments = await db.query(
        `SELECT
          bp.id,
          bp.bill_type,
          bp.bill_id,
          bp.bill_holder_name,
          bp.amount,
          bp.provider_transaction_id,
          bp.status,
          bp.processed_at,
          bp.created_at,
          bp.updated_at,
          t.transaction_id,
          t.fee,
          t.description,
          pr.name as provider_name,
          pr.logo_url as provider_logo
        FROM bill_payments bp
        JOIN transactions t ON bp.transaction_id = t.id
        LEFT JOIN bill_providers pr ON bp.provider_id = pr.id
        WHERE ${whereClause}
        ORDER BY bp.created_at DESC
        LIMIT $${paramCount} OFFSET $${paramCount + 1}`,
        [...params, pagination.limit, pagination.offset]
      );

      // Format payments
      const formattedPayments = payments.map((payment: any) => ({
        id: payment.id,
        transaction_id: payment.transaction_id,
        reference_number: payment.provider_transaction_id,
        bill_type: payment.bill_type,
        provider: {
          name: payment.provider_name,
          logo_url: payment.provider_logo,
        },
        account_number: payment.bill_id,
        customer_name: payment.bill_holder_name,
        amount: parseFloat(payment.amount),
        fee: parseFloat(payment.fee || 0),
        total_amount: parseFloat(payment.amount) + parseFloat(payment.fee || 0),
        status: payment.status,
        description: payment.description,
        created_at: payment.created_at,
        completed_at: payment.processed_at,
      }));

      const totalPages = Math.ceil(total / pagination.limit);

      return {
        payments: formattedPayments,
        pagination: {
          page: pagination.page,
          limit: pagination.limit,
          total,
          totalPages,
        },
      };
    } catch (error) {
      logger.error('Error getting bill payment history', error);
      throw error;
    }
  }

  /**
   * Request OTP for bill payment
   */
  static async requestBillPaymentOTP(
    userId: string
  ): Promise<{ otpSent: boolean; phone: string; otpExpiresIn: number }> {
    try {
      // Get user phone
      const users = await db.query('SELECT phone, country_code FROM users WHERE id = $1', [userId]);

      if (users.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      const user = users[0];

      // Generate and send OTP
      const { expiresIn } = await OTPService.createOTP(
        user.phone,
        user.country_code,
        'BILL_PAYMENT'
      );
      await OTPService.sendOTP(user.phone, user.country_code, user.phone);

      const maskedPhone = `****${user.phone.slice(-4)}`;

      logger.info('Bill payment OTP sent', { userId });

      return {
        otpSent: true,
        phone: maskedPhone,
        otpExpiresIn: expiresIn,
      };
    } catch (error) {
      logger.error('Error sending bill payment OTP', error);
      throw error;
    }
  }

  /**
   * Create Stripe payment intent for bill payment
   */
  static async createPaymentIntent(
    userId: string,
    providerId: string,
    accountNumber: string,
    amount: number,
    metadata?: {
      customerName?: string;
      billPeriod?: string;
      dueDate?: string;
    }
  ): Promise<{
    clientSecret: string;
    paymentIntentId: string;
    transactionId: string;
    amount: number;
    fee: number;
    total: number;
    currency: string;
    publishableKey: string;
  }> {
    try {
      // Validate amount
      if (amount <= 0) {
        throw new Error('INVALID_AMOUNT');
      }

      // Verify provider exists
      const providers = await db.query(
        'SELECT id, name, type FROM bill_providers WHERE id = $1 AND is_active = true',
        [providerId]
      );

      if (providers.length === 0) {
        throw new Error('PROVIDER_NOT_FOUND');
      }

      const provider = providers[0];

      // Get user details
      const users = await db.query(
        'SELECT id, email, first_name, last_name, phone, stripe_customer_id FROM users WHERE id = $1',
        [userId]
      );

      if (users.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      const user = users[0];

      // Calculate fee (1% for bill payments)
      const fee = Math.max(20, amount * 0.01);
      const totalAmount = amount + fee;

      // Create or get Stripe customer
      const { createStripeCustomer, createPaymentIntent: createStripePaymentIntent } = await import('./stripe.service');
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
      const transactionId = WalletService.generateTransactionId();

      // Create pending transaction in database
      const result = await db.transaction(async (client: PoolClient) => {
        // Create Stripe payment intent
        const paymentIntent = await createStripePaymentIntent(
          totalAmount,
          userId,
          transactionId,
          stripeCustomerId
        );

        // Insert transaction record
        await client.query(
          `INSERT INTO transactions (
            transaction_id, type, from_user_id, amount, fee, net_amount,
            status, description, metadata,
            stripe_payment_intent_id
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
          [
            transactionId,
            TransactionType.BILL_PAYMENT,
            userId,
            amount,
            fee,
            amount,
            TransactionStatus.PENDING,
            `Bill payment to ${provider.name}`,
            JSON.stringify({
              providerId,
              providerName: provider.name,
              accountNumber,
              customerName: metadata?.customerName,
              billPeriod: metadata?.billPeriod,
              dueDate: metadata?.dueDate,
              paymentGateway: 'stripe',
              paymentIntentId: paymentIntent.id,
            }),
            paymentIntent.id,
          ]
        );

        // Get config
        const config = (await import('../config')).default;

        return {
          clientSecret: paymentIntent.client_secret!,
          paymentIntentId: paymentIntent.id,
          transactionId,
          amount,
          fee,
          total: totalAmount,
          currency: config.stripe.currency,
          publishableKey: config.stripe.publishableKey,
        };
      });

      logger.info('Bill payment intent created', {
        userId,
        transactionId,
        providerId,
        amount,
        fee,
        paymentIntentId: result.paymentIntentId,
      });

      return result;
    } catch (error) {
      logger.error('Error creating bill payment intent', error);
      throw error;
    }
  }

  // =====================================================
  // MOCK HELPER METHODS
  // TODO: Remove these when integrating with real APIs
  // =====================================================

  private static generateMockCustomerName(): string {
    const firstNames = ['John', 'Jane', 'Mohamed', 'Fatima', 'Ibrahim', 'Aminata', 'Sorie', 'Mariama'];
    const lastNames = ['Kamara', 'Sesay', 'Koroma', 'Bangura', 'Conteh', 'Turay', 'Mansaray', 'Kanu'];
    const firstName = firstNames[Math.floor(Math.random() * firstNames.length)];
    const lastName = lastNames[Math.floor(Math.random() * lastNames.length)];
    return `${firstName} ${lastName}`;
  }

  private static generateMockAmount(billType: BillType): number {
    const ranges: Record<BillType, [number, number]> = {
      [BillType.WATER]: [50000, 200000],
      [BillType.ELECTRICITY]: [100000, 500000],
      [BillType.DSTV]: [150000, 350000],
      [BillType.INTERNET]: [200000, 600000],
      [BillType.MOBILE]: [50000, 300000],
      [BillType.OTHER]: [50000, 300000],
    };

    const [min, max] = ranges[billType];
    return Math.floor(Math.random() * (max - min + 1)) + min;
  }

  private static getCurrentBillPeriod(): string {
    const now = new Date();
    const month = now.toLocaleString('en-US', { month: 'long' });
    const year = now.getFullYear();
    return `${month} ${year}`;
  }

  private static getDueDate(): string {
    const dueDate = new Date();
    dueDate.setDate(dueDate.getDate() + 14); // 14 days from now
    return dueDate.toISOString().split('T')[0];
  }
}
