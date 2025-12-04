import { PoolClient } from 'pg';
import db from '../database';
import { WalletService } from './wallet.service';
import logger from '../utils/logger';
import {
  InvestmentCategory,
  InvestmentStatus,
  TransactionType,
  TransactionStatus,
} from '../types';

export interface InvestmentCategoryInfo {
  id: string;
  name: InvestmentCategory;
  display_name: string;
  description: string;
  sub_categories: string[];
  icon_url: string;
  tenures: {
    id: string;
    duration_months: number;
    return_percentage: number;
  }[];
}

export interface InvestmentPortfolio {
  investments: any[];
  summary: {
    total_invested: number;
    expected_returns: number;
    active_investments: number;
    matured_investments: number;
    total_value: number;
  };
}

export class InvestmentService {
  /**
   * Get investment categories with their tenures
   */
  static async getCategories(): Promise<InvestmentCategoryInfo[]> {
    try {
      const categories = await db.query<any>(
        `SELECT
          ic.id,
          ic.name,
          ic.display_name,
          ic.description,
          ic.sub_categories,
          ic.icon_url,
          ic.is_active
         FROM investment_categories ic
         WHERE ic.is_active = true
         ORDER BY ic.display_name`
      );

      // Get tenures for each category
      const categoriesWithTenures = await Promise.all(
        categories.map(async (category) => {
          const tenures = await db.query<any>(
            `SELECT id, duration_months, return_percentage
             FROM investment_tenures
             WHERE category_id = $1 AND is_active = true
             ORDER BY duration_months`,
            [category.id]
          );

          return {
            id: category.id,
            name: category.name,
            display_name: category.display_name,
            description: category.description,
            sub_categories: category.sub_categories || [],
            icon_url: category.icon_url,
            tenures: tenures.map((t) => ({
              id: t.id,
              duration_months: t.duration_months,
              return_percentage: parseFloat(t.return_percentage),
            })),
          };
        })
      );

      return categoriesWithTenures;
    } catch (error) {
      logger.error('Error getting investment categories', error);
      throw error;
    }
  }

  /**
   * Calculate expected returns based on amount, tenure, and return rate
   */
  static calculateReturns(
    amount: number,
    tenureMonths: number,
    returnRate: number
  ): number {
    // Simple interest calculation: Principal * Rate * Time
    // returnRate is annual percentage, tenureMonths is in months
    const returns = (amount * returnRate * tenureMonths) / (100 * 12);
    return Math.round(returns * 100) / 100; // Round to 2 decimal places
  }

  /**
   * Calculate insurance cost (5% of investment amount)
   */
  private static calculateInsuranceCost(amount: number): number {
    return Math.round(amount * 0.05 * 100) / 100;
  }

  /**
   * Create a new investment
   */
  static async createInvestment(
    userId: string,
    categoryId: string,
    subCategory: string | null,
    amount: number,
    tenureMonths: number,
    hasInsurance: boolean
  ): Promise<any> {
    try {
      // Validate amount
      if (amount <= 0) {
        throw new Error('INVALID_AMOUNT');
      }

      // Get category details
      const categories = await db.query<any>(
        `SELECT ic.name, ic.display_name, ic.sub_categories
         FROM investment_categories ic
         WHERE ic.id = $1 AND ic.is_active = true`,
        [categoryId]
      );

      if (categories.length === 0) {
        throw new Error('CATEGORY_NOT_FOUND');
      }

      const category = categories[0];

      // Validate sub_category if provided
      if (subCategory) {
        const validSubCategories = category.sub_categories || [];
        if (!validSubCategories.includes(subCategory)) {
          throw new Error('INVALID_SUB_CATEGORY');
        }
      }

      // Get tenure details
      const tenures = await db.query<any>(
        `SELECT id, duration_months, return_percentage, agreement_template_url
         FROM investment_tenures
         WHERE category_id = $1 AND duration_months = $2 AND is_active = true`,
        [categoryId, tenureMonths]
      );

      if (tenures.length === 0) {
        throw new Error('TENURE_NOT_FOUND');
      }

      const tenure = tenures[0];

      // Calculate returns
      const expectedReturn = this.calculateReturns(
        amount,
        tenureMonths,
        parseFloat(tenure.return_percentage)
      );

      // Calculate insurance cost if requested
      const insuranceCost = hasInsurance ? this.calculateInsuranceCost(amount) : 0;
      const totalAmount = amount + insuranceCost;

      // Check wallet balance
      const wallet = await WalletService.getBalance(userId);
      if (wallet.balance < totalAmount) {
        throw new Error('INSUFFICIENT_BALANCE');
      }

      // Calculate dates
      const startDate = new Date();
      const endDate = new Date();
      endDate.setMonth(endDate.getMonth() + tenureMonths);

      // Create investment in transaction
      const result = await db.transaction(async (client: PoolClient) => {
        // Generate transaction ID
        const transactionId = WalletService.generateTransactionId();

        // Create transaction record for investment
        const transactions = await client.query(
          `INSERT INTO transactions (
            transaction_id, type, from_user_id, amount, fee, net_amount,
            status, description, processed_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
          RETURNING id, transaction_id`,
          [
            transactionId,
            TransactionType.INVESTMENT,
            userId,
            totalAmount,
            0,
            totalAmount,
            TransactionStatus.COMPLETED,
            `Investment in ${category.display_name} - ${tenureMonths} months`,
          ]
        );

        const transaction = transactions[0];

        // Deduct from wallet
        await client.query(
          `UPDATE wallets
           SET balance = balance - $1, last_transaction_at = NOW(), updated_at = NOW()
           WHERE user_id = $2`,
          [totalAmount, userId]
        );

        // Create investment record
        const investments = await client.query(
          `INSERT INTO investments (
            user_id, category, sub_category, tenure_id, amount,
            tenure_months, return_rate, expected_return,
            start_date, end_date, insurance_taken, insurance_cost,
            status, transaction_id, agreement_url
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
          RETURNING id, user_id, category, sub_category, amount, tenure_months,
                    return_rate, expected_return, start_date, end_date,
                    insurance_taken, insurance_cost, status, created_at`,
          [
            userId,
            category.name,
            subCategory,
            tenure.id,
            amount,
            tenureMonths,
            tenure.return_percentage,
            expectedReturn,
            startDate,
            endDate,
            hasInsurance,
            insuranceCost > 0 ? insuranceCost : null,
            InvestmentStatus.ACTIVE,
            transaction.id,
            tenure.agreement_template_url,
          ]
        );

        return {
          investment: investments[0],
          transaction: transaction,
        };
      });

      logger.info('Investment created', {
        userId,
        investmentId: result.investment.id,
        amount,
        category: category.name,
        tenureMonths,
      });

      return {
        id: result.investment.id,
        category: result.investment.category,
        sub_category: result.investment.sub_category,
        amount: parseFloat(result.investment.amount),
        tenure_months: result.investment.tenure_months,
        return_rate: parseFloat(result.investment.return_rate),
        expected_return: parseFloat(result.investment.expected_return),
        start_date: result.investment.start_date,
        maturity_date: result.investment.end_date,
        insurance_taken: result.investment.insurance_taken,
        insurance_cost: result.investment.insurance_cost
          ? parseFloat(result.investment.insurance_cost)
          : 0,
        status: result.investment.status,
        transaction_id: result.transaction.transaction_id,
        created_at: result.investment.created_at,
      };
    } catch (error) {
      logger.error('Error creating investment', error);
      throw error;
    }
  }

  /**
   * Get user's investment portfolio with summary
   */
  static async getPortfolio(userId: string): Promise<InvestmentPortfolio> {
    try {
      // Get all investments for user
      const investments = await db.query<any>(
        `SELECT
          i.id,
          i.category,
          i.sub_category,
          i.amount,
          i.tenure_months,
          i.return_rate,
          i.expected_return,
          i.actual_return,
          i.start_date,
          i.end_date,
          i.insurance_taken,
          i.insurance_cost,
          i.status,
          i.withdrawn_at,
          i.created_at,
          ic.display_name as category_display_name,
          ic.icon_url as category_icon
         FROM investments i
         LEFT JOIN investment_categories ic ON i.category = ic.name
         WHERE i.user_id = $1
         ORDER BY i.created_at DESC`,
        [userId]
      );

      // Calculate summary
      const summary = {
        total_invested: 0,
        expected_returns: 0,
        active_investments: 0,
        matured_investments: 0,
        total_value: 0,
      };

      investments.forEach((inv) => {
        const amount = parseFloat(inv.amount);
        const expectedReturn = parseFloat(inv.expected_return);

        summary.total_invested += amount;
        summary.expected_returns += expectedReturn;

        if (inv.status === InvestmentStatus.ACTIVE) {
          summary.active_investments++;
          summary.total_value += amount + expectedReturn;
        } else if (inv.status === InvestmentStatus.MATURED) {
          summary.matured_investments++;
        }
      });

      // Format investments
      const formattedInvestments = investments.map((inv) => ({
        id: inv.id,
        category: inv.category,
        category_display_name: inv.category_display_name,
        category_icon: inv.category_icon,
        sub_category: inv.sub_category,
        amount: parseFloat(inv.amount),
        tenure_months: inv.tenure_months,
        return_rate: parseFloat(inv.return_rate),
        expected_return: parseFloat(inv.expected_return),
        actual_return: inv.actual_return ? parseFloat(inv.actual_return) : null,
        start_date: inv.start_date,
        maturity_date: inv.end_date,
        insurance_taken: inv.insurance_taken,
        insurance_cost: inv.insurance_cost ? parseFloat(inv.insurance_cost) : null,
        status: inv.status,
        withdrawn_at: inv.withdrawn_at,
        created_at: inv.created_at,
      }));

      return {
        investments: formattedInvestments,
        summary,
      };
    } catch (error) {
      logger.error('Error getting investment portfolio', error);
      throw error;
    }
  }

  /**
   * Get single investment details
   */
  static async getInvestmentDetails(
    userId: string,
    investmentId: string
  ): Promise<any> {
    try {
      const investments = await db.query<any>(
        `SELECT
          i.*,
          ic.display_name as category_display_name,
          ic.description as category_description,
          ic.icon_url as category_icon,
          t.transaction_id,
          t.created_at as transaction_date
         FROM investments i
         LEFT JOIN investment_categories ic ON i.category = ic.name
         LEFT JOIN transactions t ON i.transaction_id = t.id
         WHERE i.id = $1 AND i.user_id = $2`,
        [investmentId, userId]
      );

      if (investments.length === 0) {
        throw new Error('INVESTMENT_NOT_FOUND');
      }

      const inv = investments[0];

      return {
        id: inv.id,
        category: inv.category,
        category_display_name: inv.category_display_name,
        category_description: inv.category_description,
        category_icon: inv.category_icon,
        sub_category: inv.sub_category,
        amount: parseFloat(inv.amount),
        tenure_months: inv.tenure_months,
        return_rate: parseFloat(inv.return_rate),
        expected_return: parseFloat(inv.expected_return),
        actual_return: inv.actual_return ? parseFloat(inv.actual_return) : null,
        start_date: inv.start_date,
        maturity_date: inv.end_date,
        agreement_url: inv.agreement_url,
        insurance_taken: inv.insurance_taken,
        insurance_cost: inv.insurance_cost ? parseFloat(inv.insurance_cost) : null,
        status: inv.status,
        transaction_id: inv.transaction_id,
        transaction_date: inv.transaction_date,
        withdrawn_at: inv.withdrawn_at,
        created_at: inv.created_at,
        updated_at: inv.updated_at,
      };
    } catch (error) {
      logger.error('Error getting investment details', error);
      throw error;
    }
  }

  /**
   * Request tenure change for an investment
   */
  static async requestTenureChange(
    userId: string,
    investmentId: string,
    newTenureMonths: number
  ): Promise<any> {
    try {
      // Get investment details
      const investments = await db.query<any>(
        `SELECT i.*, it.category_id
         FROM investments i
         JOIN investment_tenures it ON i.tenure_id = it.id
         WHERE i.id = $1 AND i.user_id = $2`,
        [investmentId, userId]
      );

      if (investments.length === 0) {
        throw new Error('INVESTMENT_NOT_FOUND');
      }

      const investment = investments[0];

      // Check if investment is active
      if (investment.status !== InvestmentStatus.ACTIVE) {
        throw new Error('INVESTMENT_NOT_ACTIVE');
      }

      // Check if there's already a pending request
      const existingRequests = await db.query<any>(
        `SELECT id FROM investment_tenure_requests
         WHERE investment_id = $1 AND status = $2`,
        [investmentId, TransactionStatus.PENDING]
      );

      if (existingRequests.length > 0) {
        throw new Error('PENDING_REQUEST_EXISTS');
      }

      // Get new tenure details
      const newTenures = await db.query<any>(
        `SELECT id, duration_months, return_percentage
         FROM investment_tenures
         WHERE category_id = $1 AND duration_months = $2 AND is_active = true`,
        [investment.category_id, newTenureMonths]
      );

      if (newTenures.length === 0) {
        throw new Error('TENURE_NOT_FOUND');
      }

      const newTenure = newTenures[0];

      // Create tenure change request
      const requests = await db.query<any>(
        `INSERT INTO investment_tenure_requests (
          investment_id, user_id, old_tenure_months, new_tenure_months,
          old_return_rate, new_return_rate, status
        ) VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING id, investment_id, old_tenure_months, new_tenure_months,
                  old_return_rate, new_return_rate, status, created_at`,
        [
          investmentId,
          userId,
          investment.tenure_months,
          newTenure.duration_months,
          investment.return_rate,
          newTenure.return_percentage,
          TransactionStatus.PENDING,
        ]
      );

      logger.info('Tenure change requested', {
        userId,
        investmentId,
        requestId: requests[0].id,
        oldTenure: investment.tenure_months,
        newTenure: newTenure.duration_months,
      });

      return {
        id: requests[0].id,
        investment_id: requests[0].investment_id,
        old_tenure_months: requests[0].old_tenure_months,
        new_tenure_months: requests[0].new_tenure_months,
        old_return_rate: parseFloat(requests[0].old_return_rate),
        new_return_rate: parseFloat(requests[0].new_return_rate),
        status: requests[0].status,
        created_at: requests[0].created_at,
      };
    } catch (error) {
      logger.error('Error requesting tenure change', error);
      throw error;
    }
  }

  /**
   * Calculate early withdrawal penalty
   * Penalty: 10% of principal + loss of all returns
   */
  static calculateWithdrawalPenalty(investment: any): {
    penalty_amount: number;
    amount_to_return: number;
  } {
    const principal = parseFloat(investment.amount);
    const penaltyRate = 0.1; // 10% penalty
    const penaltyAmount = principal * penaltyRate;
    const amountToReturn = principal - penaltyAmount;

    return {
      penalty_amount: Math.round(penaltyAmount * 100) / 100,
      amount_to_return: Math.round(amountToReturn * 100) / 100,
    };
  }

  /**
   * Request early withdrawal from investment
   */
  static async requestWithdrawal(
    userId: string,
    investmentId: string
  ): Promise<any> {
    try {
      // Get investment details
      const investments = await db.query<any>(
        `SELECT * FROM investments
         WHERE id = $1 AND user_id = $2`,
        [investmentId, userId]
      );

      if (investments.length === 0) {
        throw new Error('INVESTMENT_NOT_FOUND');
      }

      const investment = investments[0];

      // Check if investment is active
      if (investment.status !== InvestmentStatus.ACTIVE) {
        throw new Error('INVESTMENT_NOT_ACTIVE');
      }

      // Calculate penalty and return amount
      const { penalty_amount, amount_to_return } =
        this.calculateWithdrawalPenalty(investment);

      // Process withdrawal
      const result = await db.transaction(async (client: PoolClient) => {
        // Generate transaction ID
        const transactionId = WalletService.generateTransactionId();

        // Create withdrawal transaction
        const transactions = await client.query(
          `INSERT INTO transactions (
            transaction_id, type, to_user_id, amount, fee, net_amount,
            status, description, processed_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
          RETURNING id, transaction_id`,
          [
            transactionId,
            TransactionType.WITHDRAWAL,
            userId,
            amount_to_return,
            penalty_amount,
            amount_to_return,
            TransactionStatus.COMPLETED,
            `Early withdrawal from investment (10% penalty applied)`,
          ]
        );

        const transaction = transactions[0];

        // Update investment status
        await client.query(
          `UPDATE investments
           SET status = $1,
               actual_return = 0,
               withdrawal_transaction_id = $2,
               withdrawn_at = NOW(),
               updated_at = NOW()
           WHERE id = $3`,
          [InvestmentStatus.WITHDRAWN, transaction.id, investmentId]
        );

        // Credit wallet with return amount
        await client.query(
          `UPDATE wallets
           SET balance = balance + $1, last_transaction_at = NOW(), updated_at = NOW()
           WHERE user_id = $2`,
          [amount_to_return, userId]
        );

        return {
          transaction: transaction,
          penalty_amount,
          amount_to_return,
        };
      });

      logger.info('Investment withdrawn', {
        userId,
        investmentId,
        penaltyAmount: penalty_amount,
        amountReturned: amount_to_return,
      });

      return {
        transaction_id: result.transaction.transaction_id,
        original_amount: parseFloat(investment.amount),
        penalty_amount: result.penalty_amount,
        amount_returned: result.amount_to_return,
        penalty_percentage: 10,
        message:
          'Investment withdrawn successfully. 10% penalty has been applied and all expected returns forfeited.',
      };
    } catch (error) {
      logger.error('Error processing withdrawal', error);
      throw error;
    }
  }
}
