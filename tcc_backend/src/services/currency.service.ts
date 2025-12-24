import axios from 'axios';
import logger from '../utils/logger';

interface CurrencyRateResponse {
  meta: {
    last_updated_at: string;
  };
  data: {
    [key: string]: {
      code: string;
      value: number;
    };
  };
}

interface CachedCurrencyRates {
  data: CurrencyRateResponse;
  timestamp: number;
}

export class CurrencyService {
  private static cache: CachedCurrencyRates | null = null;
  private static readonly API_KEY = process.env.CURRENCY_API_KEY || '';
  private static readonly API_URL = process.env.CURRENCY_API_URL || 'https://api.currencyapi.com/v3';
  private static readonly CACHE_TTL = parseInt(process.env.CURRENCY_RATE_CACHE_TTL || '300') * 1000; // Convert to ms

  /**
   * Map TCC currency to SLL for external API compatibility
   * External currency APIs don't recognize 'TCC' as a valid currency code
   * @param currency - The currency code to map
   * @returns The mapped currency code for external API calls
   */
  private static mapCurrencyForAPI(currency: string): string {
    // Map TCC to SLL for external API compatibility
    return currency === 'TCC' ? 'SLL' : currency;
  }

  /**
   * Check if cache is still valid
   */
  private static isCacheValid(): boolean {
    if (!this.cache) return false;
    const now = Date.now();
    return (now - this.cache.timestamp) < this.CACHE_TTL;
  }

  /**
   * Get live currency rates from API
   * @param baseCurrency - Base currency (default: 'TCC' for TCC Coin)
   * @param currencies - Array of currency codes (e.g., ['USD', 'EUR', 'GBP'])
   */
  static async getLiveCurrencyRates(
    baseCurrency: string = 'TCC',
    currencies: string[] = ['USD', 'EUR', 'GBP', 'NGN', 'GHS']
  ): Promise<CurrencyRateResponse> {
    try {
      // Return cached data if still valid
      if (this.isCacheValid() && this.cache) {
        logger.info('Returning cached currency rates');
        return this.cache.data;
      }

      // Fetch fresh data from API
      const url = `${this.API_URL}/latest`;

      logger.info(`Fetching currency rates from API: ${url}`);

      // Map TCC to SLL for external API compatibility
      const apiBaseCurrency = this.mapCurrencyForAPI(baseCurrency);

      const response = await axios.get<CurrencyRateResponse>(url, {
        params: {
          apikey: this.API_KEY,
          base_currency: apiBaseCurrency,
          currencies: currencies.join(','),
        },
        timeout: 10000, // 10 second timeout
      });

      if (!response.data.data) {
        throw new Error('Currency API returned invalid response');
      }

      // Cache the response
      this.cache = {
        data: response.data,
        timestamp: Date.now(),
      };

      logger.info('Currency rates fetched successfully and cached');
      return response.data;
    } catch (error: any) {
      logger.error(`Error fetching currency rates: ${error.message}`);

      // Return cached data if available, even if expired
      if (this.cache) {
        logger.warn('Returning expired cached currency rates due to API error');
        return this.cache.data;
      }

      throw new Error(`Failed to fetch currency rates: ${error.message}`);
    }
  }

  /**
   * Convert amount from one currency to another
   * @param from - Source currency code
   * @param to - Target currency code
   * @param amount - Amount to convert
   */
  static async convertCurrency(
    from: string,
    to: string,
    amount: number
  ): Promise<{ from: string; to: string; amount: number; convertedAmount: number; rate: number }> {
    try {
      // If converting from the same currency, return the same amount
      if (from === to) {
        return {
          from,
          to,
          amount,
          convertedAmount: amount,
          rate: 1,
        };
      }

      // Get rates with 'from' as base currency
      const rates = await this.getLiveCurrencyRates(from, [to]);

      if (!rates.data[to]) {
        throw new Error(`Exchange rate not found for ${from} to ${to}`);
      }

      const rate = rates.data[to].value;
      const convertedAmount = amount * rate;

      return {
        from,
        to,
        amount,
        convertedAmount: parseFloat(convertedAmount.toFixed(2)),
        rate,
      };
    } catch (error: any) {
      logger.error(`Error converting ${from} to ${to}: ${error.message}`);
      throw error;
    }
  }

  /**
   * Get exchange rate between two currencies
   * @param from - Source currency code
   * @param to - Target currency code
   */
  static async getExchangeRate(from: string, to: string): Promise<number> {
    try {
      if (from === to) return 1;

      const rates = await this.getLiveCurrencyRates(from, [to]);

      if (!rates.data[to]) {
        throw new Error(`Exchange rate not found for ${from} to ${to}`);
      }

      return rates.data[to].value;
    } catch (error: any) {
      logger.error(`Error getting exchange rate ${from}/${to}: ${error.message}`);
      throw error;
    }
  }

  /**
   * Get formatted currency rates for mobile app display
   * Returns rates for common currency pairs with TCC
   */
  static async getFormattedCurrencyRates(baseCurrency: string = 'TCC'): Promise<{
    base: string;
    rates: {
      [key: string]: {
        code: string;
        rate: number;
        inverseRate: number; // How much of base currency equals 1 unit of this currency
      };
    };
    timestamp: number;
  }> {
    try {
      const currencies = ['USD', 'EUR', 'GBP', 'NGN', 'GHS'];
      const ratesData = await this.getLiveCurrencyRates(baseCurrency, currencies);

      const formattedRates: {
        [key: string]: {
          code: string;
          rate: number;
          inverseRate: number;
        };
      } = {};

      // Format each currency rate
      for (const [code, data] of Object.entries(ratesData.data)) {
        formattedRates[code] = {
          code: data.code,
          rate: data.value, // How many of this currency per 1 base currency
          inverseRate: 1 / data.value, // How many base currency per 1 of this currency
        };
      }

      return {
        base: baseCurrency,
        rates: formattedRates,
        timestamp: Date.now(),
      };
    } catch (error: any) {
      logger.error(`Error getting formatted currency rates: ${error.message}`);
      throw error;
    }
  }

  /**
   * Get multiple conversion rates at once
   * Useful for displaying a conversion table
   */
  static async getMultipleConversions(
    from: string,
    toCurrencies: string[],
    amount: number
  ): Promise<{
    from: string;
    amount: number;
    conversions: Array<{
      to: string;
      convertedAmount: number;
      rate: number;
    }>;
  }> {
    try {
      const rates = await this.getLiveCurrencyRates(from, toCurrencies);

      const conversions = toCurrencies.map((to) => {
        const rate = rates.data[to]?.value || 0;
        return {
          to,
          convertedAmount: parseFloat((amount * rate).toFixed(2)),
          rate,
        };
      });

      return {
        from,
        amount,
        conversions,
      };
    } catch (error: any) {
      logger.error(`Error getting multiple conversions: ${error.message}`);
      throw error;
    }
  }

  /**
   * Clear cache (useful for testing or forced refresh)
   */
  static clearCache(): void {
    this.cache = null;
    logger.info('Currency rate cache cleared');
  }
}
