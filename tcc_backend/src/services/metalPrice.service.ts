import axios from 'axios';
import db from '../database';
import logger from '../utils/logger';

interface MetalPriceResponse {
  success: boolean;
  base: string;
  timestamp: number;
  rates: {
    [key: string]: number;
  };
}

interface CachedMetalPrice {
  id: string;
  metal_symbol: string;
  base_currency: string;
  price_per_ounce: string;
  price_per_gram: string;
  price_per_kilogram: string;
  api_timestamp: string;
  cached_at: Date;
  expires_at: Date;
  is_expired: boolean;
}

export class MetalPriceService {
  private static readonly API_KEY = process.env.METAL_PRICE_API_KEY || '';
  private static readonly API_URL = process.env.METAL_PRICE_API_URL || 'https://api.metalpriceapi.com/v1';
  private static readonly CACHE_TTL = parseInt(process.env.METAL_PRICE_CACHE_TTL || '86400'); // Default 24 hours in seconds
  private static readonly TROY_OUNCE_IN_GRAMS = 31.1034768;

  /**
   * Get cached metal price from database
   */
  private static async getCachedPrice(
    metal: string,
    baseCurrency: string
  ): Promise<CachedMetalPrice | null> {
    try {
      const result = await db.query<CachedMetalPrice>(
        'SELECT * FROM get_cached_metal_price($1, $2)',
        [metal, baseCurrency]
      );

      if (result.length === 0) {
        return null;
      }

      return result[0];
    } catch (error: any) {
      logger.error(`Error getting cached metal price: ${error.message}`);
      return null;
    }
  }

  /**
   * Save metal price to database cache
   */
  private static async savePriceToCache(
    metal: string,
    baseCurrency: string,
    pricePerOunce: number,
    timestamp: number
  ): Promise<void> {
    try {
      const pricePerGram = pricePerOunce / this.TROY_OUNCE_IN_GRAMS;
      const pricePerKilogram = pricePerOunce * (1000 / this.TROY_OUNCE_IN_GRAMS);

      await db.query(
        'SELECT upsert_metal_price($1, $2, $3, $4, $5, $6, $7)',
        [
          metal,
          baseCurrency,
          pricePerOunce,
          pricePerGram,
          pricePerKilogram,
          timestamp,
          this.CACHE_TTL,
        ]
      );

      logger.info(`Metal price cached: ${metal} in ${baseCurrency}`);
    } catch (error: any) {
      logger.error(`Error saving metal price to cache: ${error.message}`);
      // Don't throw error here - continue even if caching fails
    }
  }

  /**
   * Get live metal prices from API (with database caching)
   * @param metals - Array of metal symbols (e.g., ['XAU', 'XAG', 'XPT'] for Gold, Silver, Platinum)
   * @param baseCurrency - Base currency (default: 'SLL' for Sierra Leone Leone)
   */
  static async getLiveMetalPrices(
    metals: string[] = ['XAU', 'XAG', 'XPT'],
    baseCurrency: string = 'SLL'
  ): Promise<MetalPriceResponse> {
    try {
      // Check database cache for all requested metals
      const cachedPrices = await Promise.all(
        metals.map((metal) => this.getCachedPrice(metal, baseCurrency))
      );

      // Check if all metals have valid (non-expired) cache entries
      const allCached = cachedPrices.every((cached) => cached && !cached.is_expired);

      if (allCached) {
        logger.info('Returning cached metal prices from database');

        // Build response from cached data
        const rates: { [key: string]: number } = {};
        let timestamp = 0;

        cachedPrices.forEach((cached) => {
          if (cached) {
            rates[cached.metal_symbol] = parseFloat(cached.price_per_ounce);
            timestamp = Math.max(timestamp, parseInt(cached.api_timestamp));
          }
        });

        return {
          success: true,
          base: baseCurrency,
          timestamp,
          rates,
        };
      }

      // Fetch fresh data from API
      const symbols = metals.join(',');
      const url = `${this.API_URL}/latest`;

      logger.info(`Fetching metal prices from API: ${url} (${symbols})`);

      const response = await axios.get<MetalPriceResponse>(url, {
        params: {
          api_key: this.API_KEY,
          base: baseCurrency,
          currencies: symbols,
        },
        timeout: 10000, // 10 second timeout
      });

      if (!response.data.success) {
        throw new Error('Metal Price API returned unsuccessful response');
      }

      // Save each metal price to database cache
      await Promise.all(
        Object.entries(response.data.rates).map(([metal, price]) =>
          this.savePriceToCache(metal, baseCurrency, price, response.data.timestamp)
        )
      );

      logger.info('Metal prices fetched successfully and cached to database');
      return response.data;
    } catch (error: any) {
      logger.error(`Error fetching metal prices: ${error.message}`);

      // Try to return cached data, even if expired
      const cachedPrices = await Promise.all(
        metals.map((metal) => this.getCachedPrice(metal, baseCurrency))
      );

      const anyCached = cachedPrices.some((cached) => cached !== null);

      if (anyCached) {
        logger.warn('Returning expired cached metal prices due to API error');

        const rates: { [key: string]: number } = {};
        let timestamp = 0;

        cachedPrices.forEach((cached) => {
          if (cached) {
            rates[cached.metal_symbol] = parseFloat(cached.price_per_ounce);
            timestamp = Math.max(timestamp, parseInt(cached.api_timestamp));
          }
        });

        return {
          success: true,
          base: baseCurrency,
          timestamp,
          rates,
        };
      }

      throw new Error(`Failed to fetch metal prices: ${error.message}`);
    }
  }

  /**
   * Get price for a specific metal
   * @param metal - Metal symbol (e.g., 'XAU' for Gold)
   * @param baseCurrency - Base currency
   */
  static async getMetalPrice(
    metal: string,
    baseCurrency: string = 'SLL'
  ): Promise<{ metal: string; price: number; currency: string; timestamp: number }> {
    try {
      const prices = await this.getLiveMetalPrices([metal], baseCurrency);

      if (!prices.rates[metal]) {
        throw new Error(`Price not found for metal: ${metal}`);
      }

      return {
        metal,
        price: prices.rates[metal],
        currency: baseCurrency,
        timestamp: prices.timestamp,
      };
    } catch (error: any) {
      logger.error(`Error fetching price for ${metal}: ${error.message}`);
      throw error;
    }
  }

  /**
   * Convert metal price to different units
   * Metal prices are typically per troy ounce (31.1g)
   * @param pricePerOunce - Price per troy ounce
   * @param unit - Target unit ('gram', 'ounce', 'kilogram')
   */
  static convertMetalPriceUnit(
    pricePerOunce: number,
    unit: 'gram' | 'ounce' | 'kilogram'
  ): number {
    switch (unit) {
      case 'gram':
        return pricePerOunce / this.TROY_OUNCE_IN_GRAMS;
      case 'ounce':
        return pricePerOunce;
      case 'kilogram':
        return pricePerOunce * (1000 / this.TROY_OUNCE_IN_GRAMS);
      default:
        return pricePerOunce;
    }
  }

  /**
   * Clear database cache (useful for testing or forced refresh)
   */
  static async clearCache(): Promise<void> {
    try {
      await db.query('DELETE FROM metal_price_cache');
      logger.info('Metal price database cache cleared');
    } catch (error: any) {
      logger.error(`Error clearing metal price cache: ${error.message}`);
      throw error;
    }
  }

  /**
   * Get formatted metal prices with percentage changes
   * Note: Percentage change calculation would require historical data
   */
  static async getFormattedMetalPrices(baseCurrency: string = 'SLL'): Promise<{
    gold: { price: number; pricePerGram: number };
    silver: { price: number; pricePerGram: number };
    platinum: { price: number; pricePerGram: number };
    timestamp: number;
  }> {
    try {
      const prices = await this.getLiveMetalPrices(['XAU', 'XAG', 'XPT'], baseCurrency);

      return {
        gold: {
          price: prices.rates.XAU || 0,
          pricePerGram: this.convertMetalPriceUnit(prices.rates.XAU || 0, 'gram'),
        },
        silver: {
          price: prices.rates.XAG || 0,
          pricePerGram: this.convertMetalPriceUnit(prices.rates.XAG || 0, 'gram'),
        },
        platinum: {
          price: prices.rates.XPT || 0,
          pricePerGram: this.convertMetalPriceUnit(prices.rates.XPT || 0, 'gram'),
        },
        timestamp: prices.timestamp,
      };
    } catch (error: any) {
      logger.error(`Error getting formatted metal prices: ${error.message}`);
      throw error;
    }
  }
}
