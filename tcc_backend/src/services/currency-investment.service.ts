import { PoolClient } from 'pg';
import db from '../database';
import { WalletService } from './wallet.service';
import { CurrencyService } from './currency.service';
import logger from '../utils/logger';
import {
  TransactionType,
  TransactionStatus,
  CurrencyInvestmentStatus,
  SupportedCurrency,
  CurrencyInfo,
  CurrencyHolding,
  CurrencyHoldingsSummary,
  CurrencyHoldingsResponse,
  SellCurrencyResult,
} from '../types';

// Currency metadata
const CURRENCY_METADATA: Record<SupportedCurrency, { name: string; symbol: string; flag: string }> = {
  EUR: { name: 'Euro', symbol: 'EUR', flag: 'EU' },
  GBP: { name: 'British Pound', symbol: 'GBP', flag: 'GB' },
  JPY: { name: 'Japanese Yen', symbol: 'JPY', flag: 'JP' },
  AUD: { name: 'Australian Dollar', symbol: 'A$', flag: 'AU' },
  CAD: { name: 'Canadian Dollar', symbol: 'C$', flag: 'CA' },
  CHF: { name: 'Swiss Franc', symbol: 'Fr', flag: 'CH' },
  CNY: { name: 'Chinese Yuan', symbol: 'CNY', flag: 'CN' },
};

const SUPPORTED_CURRENCIES: SupportedCurrency[] = ['EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'CHF', 'CNY'];

export class CurrencyInvestmentService {
  /**
   * Get available currencies with live rates and limits
   */
  static async getAvailableCurrencies(): Promise<CurrencyInfo[]> {
    try {
      // Get investment limits from database
      const limits = await db.query<any>(
        `SELECT currency_code, min_investment, max_investment, is_active
         FROM currency_investment_limits
         WHERE is_active = true`
      );

      const limitsMap = new Map(
        limits.map((l) => [l.currency_code, { min: parseFloat(l.min_investment), max: parseFloat(l.max_investment) }])
      );

      // Get live rates from CurrencyService
      // TCC is pegged 1:1 to USD, so we get rates relative to USD
      const ratesResponse = await CurrencyService.getLiveCurrencyRates('USD', SUPPORTED_CURRENCIES);

      const currencies: CurrencyInfo[] = [];

      for (const currencyCode of SUPPORTED_CURRENCIES) {
        const rateData = ratesResponse.data[currencyCode];
        if (!rateData) continue;

        const metadata = CURRENCY_METADATA[currencyCode];
        const limitData = limitsMap.get(currencyCode) || { min: 10, max: 100000 };

        currencies.push({
          code: currencyCode,
          name: metadata.name,
          symbol: metadata.symbol,
          flag: metadata.flag,
          rate: rateData.value, // How many of this currency per 1 TCC (1 USD)
          inverse_rate: 1 / rateData.value, // How many TCC per 1 unit of this currency
          min_investment: limitData.min,
          max_investment: limitData.max,
          is_active: true,
        });
      }

      return currencies;
    } catch (error) {
      logger.error('Error getting available currencies', error);
      throw error;
    }
  }

  /**
   * Get investment limits for all currencies
   */
  static async getLimits(): Promise<{ currency_code: SupportedCurrency; min_investment: number; max_investment: number }[]> {
    try {
      const limits = await db.query<any>(
        `SELECT currency_code, min_investment, max_investment
         FROM currency_investment_limits
         WHERE is_active = true
         ORDER BY currency_code`
      );

      return limits.map((l) => ({
        currency_code: l.currency_code as SupportedCurrency,
        min_investment: parseFloat(l.min_investment),
        max_investment: parseFloat(l.max_investment),
      }));
    } catch (error) {
      logger.error('Error getting investment limits', error);
      throw error;
    }
  }

  /**
   * Get current exchange rate for a currency
   * Returns rate relative to TCC (1 TCC = X currency)
   */
  static async getCurrentRate(currencyCode: SupportedCurrency): Promise<number> {
    try {
      const ratesResponse = await CurrencyService.getLiveCurrencyRates('USD', [currencyCode]);
      const rateData = ratesResponse.data[currencyCode];

      if (!rateData) {
        throw new Error(`RATE_NOT_FOUND_FOR_${currencyCode}`);
      }

      return rateData.value;
    } catch (error) {
      logger.error(`Error getting rate for ${currencyCode}`, error);
      throw error;
    }
  }

  /**
   * Buy currency with TCC
   */
  static async buyCurrency(
    userId: string,
    currencyCode: SupportedCurrency,
    tccAmount: number
  ): Promise<any> {
    try {
      // Validate currency code
      if (!SUPPORTED_CURRENCIES.includes(currencyCode)) {
        throw new Error('INVALID_CURRENCY');
      }

      // Validate amount
      if (tccAmount <= 0) {
        throw new Error('INVALID_AMOUNT');
      }

      // Get investment limits
      const limits = await db.query<any>(
        `SELECT min_investment, max_investment, is_active
         FROM currency_investment_limits
         WHERE currency_code = $1`,
        [currencyCode]
      );

      if (limits.length === 0 || !limits[0].is_active) {
        throw new Error('CURRENCY_NOT_AVAILABLE');
      }

      const { min_investment, max_investment } = limits[0];

      if (tccAmount < parseFloat(min_investment)) {
        throw new Error(`MINIMUM_INVESTMENT_${min_investment}_TCC`);
      }

      if (tccAmount > parseFloat(max_investment)) {
        throw new Error(`MAXIMUM_INVESTMENT_${max_investment}_TCC`);
      }

      // Check wallet balance
      const wallet = await WalletService.getBalance(userId);
      if (wallet.balance < tccAmount) {
        throw new Error('INSUFFICIENT_BALANCE');
      }

      // Get current exchange rate
      const purchaseRate = await this.getCurrentRate(currencyCode);

      // Calculate currency amount (TCC * rate = currency amount)
      const currencyAmount = tccAmount * purchaseRate;

      // Create investment in transaction
      const result = await db.transaction(async (client: PoolClient) => {
        // Generate transaction ID
        const transactionId = WalletService.generateTransactionId();

        // Create transaction record
        const transactions = await client.query(
          `INSERT INTO transactions (
            transaction_id, type, from_user_id, amount, fee, net_amount,
            status, description, processed_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
          RETURNING id, transaction_id`,
          [
            transactionId,
            TransactionType.CURRENCY_BUY,
            userId,
            tccAmount,
            0,
            tccAmount,
            TransactionStatus.COMPLETED,
            `Bought ${currencyAmount.toFixed(6)} ${currencyCode} at rate ${purchaseRate.toFixed(6)}`,
          ]
        );

        const transaction = transactions.rows[0];

        // Deduct from wallet
        await client.query(
          `UPDATE wallets
           SET balance = balance - $1, last_transaction_at = NOW(), updated_at = NOW()
           WHERE user_id = $2`,
          [tccAmount, userId]
        );

        // Create currency investment record
        const investments = await client.query(
          `INSERT INTO currency_investments (
            user_id, currency_code, amount_invested, currency_amount,
            purchase_rate, status, transaction_id
          ) VALUES ($1, $2, $3, $4, $5, $6, $7)
          RETURNING id, user_id, currency_code, amount_invested, currency_amount,
                    purchase_rate, status, created_at`,
          [
            userId,
            currencyCode,
            tccAmount,
            currencyAmount,
            purchaseRate,
            CurrencyInvestmentStatus.ACTIVE,
            transaction.id,
          ]
        );

        return {
          investment: investments.rows[0],
          transaction: transaction,
        };
      });

      logger.info('Currency investment created', {
        userId,
        investmentId: result.investment.id,
        currencyCode,
        tccAmount,
        currencyAmount,
        purchaseRate,
      });

      const metadata = CURRENCY_METADATA[currencyCode];

      return {
        id: result.investment.id,
        currency_code: currencyCode,
        currency_name: metadata.name,
        currency_symbol: metadata.symbol,
        currency_flag: metadata.flag,
        amount_invested: parseFloat(result.investment.amount_invested),
        currency_amount: parseFloat(result.investment.currency_amount),
        purchase_rate: parseFloat(result.investment.purchase_rate),
        status: result.investment.status,
        transaction_id: result.transaction.transaction_id,
        created_at: result.investment.created_at,
      };
    } catch (error) {
      logger.error('Error buying currency', error);
      throw error;
    }
  }

  /**
   * Get user's currency holdings with current values
   */
  static async getUserHoldings(userId: string): Promise<CurrencyHoldingsResponse> {
    try {
      // Get all active holdings
      const holdings = await db.query<any>(
        `SELECT id, currency_code, amount_invested, currency_amount,
                purchase_rate, status, transaction_id, created_at, updated_at
         FROM currency_investments
         WHERE user_id = $1 AND status = $2
         ORDER BY created_at DESC`,
        [userId, CurrencyInvestmentStatus.ACTIVE]
      );

      // Get current rates for all currencies with holdings
      const currencyCodes = [...new Set(holdings.map((h) => h.currency_code))];
      const currentRates: Map<string, number> = new Map();

      if (currencyCodes.length > 0) {
        const ratesResponse = await CurrencyService.getLiveCurrencyRates('USD', currencyCodes);
        for (const code of currencyCodes) {
          if (ratesResponse.data[code]) {
            currentRates.set(code, ratesResponse.data[code].value);
          }
        }
      }

      // Calculate current values and profit/loss
      const holdingsWithPnL: CurrencyHolding[] = holdings.map((h) => {
        const currentRate = currentRates.get(h.currency_code) || h.purchase_rate;
        const amountInvested = parseFloat(h.amount_invested);
        const currencyAmount = parseFloat(h.currency_amount);
        const purchaseRate = parseFloat(h.purchase_rate);

        // Current value in TCC: currency_amount / current_rate
        const currentValueTcc = currencyAmount / currentRate;
        const unrealizedProfitLoss = currentValueTcc - amountInvested;
        const profitLossPercentage = (unrealizedProfitLoss / amountInvested) * 100;

        const metadata = CURRENCY_METADATA[h.currency_code as SupportedCurrency];

        return {
          id: h.id,
          user_id: userId,
          currency_code: h.currency_code,
          currency_name: metadata?.name || h.currency_code,
          currency_symbol: metadata?.symbol || h.currency_code,
          currency_flag: metadata?.flag || '',
          amount_invested: amountInvested,
          currency_amount: currencyAmount,
          purchase_rate: purchaseRate,
          status: h.status,
          transaction_id: h.transaction_id,
          created_at: h.created_at,
          updated_at: h.updated_at,
          current_rate: currentRate,
          current_value_tcc: parseFloat(currentValueTcc.toFixed(2)),
          unrealized_profit_loss: parseFloat(unrealizedProfitLoss.toFixed(2)),
          profit_loss_percentage: parseFloat(profitLossPercentage.toFixed(2)),
        } as CurrencyHolding;
      });

      // Calculate summary
      const summary: CurrencyHoldingsSummary = {
        total_invested: 0,
        current_value: 0,
        total_profit_loss: 0,
        profit_loss_percentage: 0,
        active_holdings_count: holdingsWithPnL.length,
      };

      holdingsWithPnL.forEach((h) => {
        summary.total_invested += h.amount_invested;
        summary.current_value += h.current_value_tcc;
        summary.total_profit_loss += h.unrealized_profit_loss;
      });

      if (summary.total_invested > 0) {
        summary.profit_loss_percentage = parseFloat(
          ((summary.total_profit_loss / summary.total_invested) * 100).toFixed(2)
        );
      }

      summary.total_invested = parseFloat(summary.total_invested.toFixed(2));
      summary.current_value = parseFloat(summary.current_value.toFixed(2));
      summary.total_profit_loss = parseFloat(summary.total_profit_loss.toFixed(2));

      return {
        holdings: holdingsWithPnL,
        summary,
      };
    } catch (error) {
      logger.error('Error getting user holdings', error);
      throw error;
    }
  }

  /**
   * Get single holding details
   */
  static async getHoldingDetails(userId: string, investmentId: string): Promise<CurrencyHolding> {
    try {
      const holdings = await db.query<any>(
        `SELECT id, user_id, currency_code, amount_invested, currency_amount,
                purchase_rate, status, transaction_id, created_at, updated_at
         FROM currency_investments
         WHERE id = $1 AND user_id = $2`,
        [investmentId, userId]
      );

      if (holdings.length === 0) {
        throw new Error('HOLDING_NOT_FOUND');
      }

      const h = holdings[0];
      const currencyCode = h.currency_code as SupportedCurrency;

      // Get current rate
      const currentRate = await this.getCurrentRate(currencyCode);

      const amountInvested = parseFloat(h.amount_invested);
      const currencyAmount = parseFloat(h.currency_amount);
      const purchaseRate = parseFloat(h.purchase_rate);

      // Current value in TCC: currency_amount / current_rate
      const currentValueTcc = currencyAmount / currentRate;
      const unrealizedProfitLoss = currentValueTcc - amountInvested;
      const profitLossPercentage = (unrealizedProfitLoss / amountInvested) * 100;

      const metadata = CURRENCY_METADATA[currencyCode];

      return {
        id: h.id,
        user_id: h.user_id,
        currency_code: currencyCode,
        currency_name: metadata.name,
        currency_symbol: metadata.symbol,
        currency_flag: metadata.flag,
        amount_invested: amountInvested,
        currency_amount: currencyAmount,
        purchase_rate: purchaseRate,
        status: h.status,
        transaction_id: h.transaction_id,
        created_at: h.created_at,
        updated_at: h.updated_at,
        current_rate: currentRate,
        current_value_tcc: parseFloat(currentValueTcc.toFixed(2)),
        unrealized_profit_loss: parseFloat(unrealizedProfitLoss.toFixed(2)),
        profit_loss_percentage: parseFloat(profitLossPercentage.toFixed(2)),
      } as CurrencyHolding;
    } catch (error) {
      logger.error('Error getting holding details', error);
      throw error;
    }
  }

  /**
   * Sell currency holding back to TCC
   */
  static async sellCurrency(userId: string, investmentId: string): Promise<SellCurrencyResult> {
    try {
      // Get holding details
      const holdings = await db.query<any>(
        `SELECT id, user_id, currency_code, amount_invested, currency_amount,
                purchase_rate, status
         FROM currency_investments
         WHERE id = $1 AND user_id = $2`,
        [investmentId, userId]
      );

      if (holdings.length === 0) {
        throw new Error('HOLDING_NOT_FOUND');
      }

      const holding = holdings[0];

      if (holding.status !== CurrencyInvestmentStatus.ACTIVE) {
        throw new Error('HOLDING_ALREADY_SOLD');
      }

      const currencyCode = holding.currency_code as SupportedCurrency;
      const amountInvested = parseFloat(holding.amount_invested);
      const currencyAmount = parseFloat(holding.currency_amount);

      // Get current rate
      const sellRate = await this.getCurrentRate(currencyCode);

      // Calculate TCC to receive: currency_amount / sell_rate
      const tccToReceive = currencyAmount / sellRate;
      const profitLoss = tccToReceive - amountInvested;
      const profitLossPercentage = (profitLoss / amountInvested) * 100;

      // Process sell in transaction
      const result = await db.transaction(async (client: PoolClient) => {
        // Generate transaction ID
        const transactionId = WalletService.generateTransactionId();

        // Create transaction record
        const transactions = await client.query(
          `INSERT INTO transactions (
            transaction_id, type, to_user_id, amount, fee, net_amount,
            status, description, processed_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
          RETURNING id, transaction_id`,
          [
            transactionId,
            TransactionType.CURRENCY_SELL,
            userId,
            tccToReceive,
            0,
            tccToReceive,
            TransactionStatus.COMPLETED,
            `Sold ${currencyAmount.toFixed(6)} ${currencyCode} at rate ${sellRate.toFixed(6)} (P/L: ${profitLoss >= 0 ? '+' : ''}${profitLoss.toFixed(2)} TCC)`,
          ]
        );

        const transaction = transactions.rows[0];

        // Credit wallet
        await client.query(
          `UPDATE wallets
           SET balance = balance + $1, last_transaction_at = NOW(), updated_at = NOW()
           WHERE user_id = $2`,
          [tccToReceive, userId]
        );

        // Update holding status
        await client.query(
          `UPDATE currency_investments
           SET status = $1,
               sold_at = NOW(),
               sold_rate = $2,
               sold_amount_tcc = $3,
               profit_loss = $4,
               sell_transaction_id = $5,
               updated_at = NOW()
           WHERE id = $6`,
          [
            CurrencyInvestmentStatus.SOLD,
            sellRate,
            tccToReceive,
            profitLoss,
            transaction.id,
            investmentId,
          ]
        );

        return { transaction };
      });

      logger.info('Currency sold', {
        userId,
        investmentId,
        currencyCode,
        currencyAmount,
        tccReceived: tccToReceive,
        profitLoss,
        sellRate,
      });

      return {
        transaction_id: result.transaction.transaction_id,
        currency_sold: currencyAmount,
        currency_code: currencyCode,
        sell_rate: sellRate,
        tcc_received: parseFloat(tccToReceive.toFixed(2)),
        profit_loss: parseFloat(profitLoss.toFixed(2)),
        profit_loss_percentage: parseFloat(profitLossPercentage.toFixed(2)),
      };
    } catch (error) {
      logger.error('Error selling currency', error);
      throw error;
    }
  }

  /**
   * Get transaction history for currency investments
   */
  static async getHistory(
    userId: string,
    page: number = 1,
    limit: number = 20
  ): Promise<{
    transactions: any[];
    pagination: { page: number; limit: number; total: number; totalPages: number };
  }> {
    try {
      const offset = (page - 1) * limit;

      // Get total count
      const countResult = await db.query<any>(
        `SELECT COUNT(*) as total
         FROM currency_investments
         WHERE user_id = $1`,
        [userId]
      );

      const total = parseInt(countResult[0].total);

      // Get investments with transaction details
      const investments = await db.query<any>(
        `SELECT
          ci.id,
          ci.currency_code,
          ci.amount_invested,
          ci.currency_amount,
          ci.purchase_rate,
          ci.status,
          ci.sold_at,
          ci.sold_rate,
          ci.sold_amount_tcc,
          ci.profit_loss,
          ci.created_at,
          t.transaction_id as buy_transaction_id,
          st.transaction_id as sell_transaction_id
         FROM currency_investments ci
         LEFT JOIN transactions t ON ci.transaction_id = t.id
         LEFT JOIN transactions st ON ci.sell_transaction_id = st.id
         WHERE ci.user_id = $1
         ORDER BY ci.created_at DESC
         LIMIT $2 OFFSET $3`,
        [userId, limit, offset]
      );

      const formattedTransactions = investments.map((inv) => {
        const metadata = CURRENCY_METADATA[inv.currency_code as SupportedCurrency];
        return {
          id: inv.id,
          currency_code: inv.currency_code,
          currency_name: metadata?.name || inv.currency_code,
          currency_symbol: metadata?.symbol || inv.currency_code,
          amount_invested: parseFloat(inv.amount_invested),
          currency_amount: parseFloat(inv.currency_amount),
          purchase_rate: parseFloat(inv.purchase_rate),
          status: inv.status,
          buy_transaction_id: inv.buy_transaction_id,
          sell_transaction_id: inv.sell_transaction_id,
          sold_at: inv.sold_at,
          sold_rate: inv.sold_rate ? parseFloat(inv.sold_rate) : null,
          sold_amount_tcc: inv.sold_amount_tcc ? parseFloat(inv.sold_amount_tcc) : null,
          profit_loss: inv.profit_loss ? parseFloat(inv.profit_loss) : null,
          created_at: inv.created_at,
        };
      });

      return {
        transactions: formattedTransactions,
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      };
    } catch (error) {
      logger.error('Error getting currency investment history', error);
      throw error;
    }
  }
}