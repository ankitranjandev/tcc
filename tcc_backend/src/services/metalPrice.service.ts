import axios from 'axios';
import logger from '../utils/logger';

interface MetalPriceResponse {
  success: boolean;
  base: string;
  timestamp: number;
  rates: {
    [key: string]: number;
  };
}

interface CachedMetalPrices {
  data: MetalPriceResponse;
  timestamp: number;
}

export class MetalPriceService {
  private static cache: CachedMetalPrices | null = null;
  private static readonly API_KEY = process.env.METAL_PRICE_API_KEY || '';
  private static readonly API_URL = process.env.METAL_PRICE_API_URL || 'https://api.metalpriceapi.com/v1';
  private static readonly CACHE_TTL = parseInt(process.env.METAL_PRICE_CACHE_TTL || '300') * 1000; // Convert to ms

  /**
   * Check if cache is still valid
   */
  private static isCacheValid(): boolean {
    if (!this.cache) return false;
    const now = Date.now();
    return (now - this.cache.timestamp) < this.CACHE_TTL;
  }

  /**
   * Get live metal prices from API
   * @param metals - Array of metal symbols (e.g., ['XAU', 'XAG', 'XPT'] for Gold, Silver, Platinum)
   * @param baseCurrency - Base currency (default: 'SLL' for Sierra Leone Leone)
   */
  static async getLiveMetalPrices(
    metals: string[] = ['XAU', 'XAG', 'XPT'],
    baseCurrency: string = 'SLL'
  ): Promise<MetalPriceResponse> {
    try {
      // Return cached data if still valid
      if (this.isCacheValid() && this.cache) {
        logger.info('Returning cached metal prices');
        return this.cache.data;
      }

      // Fetch fresh data from API
      const symbols = metals.join(',');
      const url = `${this.API_URL}/latest`;

      logger.info(`Fetching metal prices from API: ${url}`);

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

      // Cache the response
      this.cache = {
        data: response.data,
        timestamp: Date.now(),
      };

      logger.info('Metal prices fetched successfully and cached');
      return response.data;
    } catch (error: any) {
      logger.error('Error fetching metal prices:', error.message);

      // Return cached data if available, even if expired
      if (this.cache) {
        logger.warn('Returning expired cached metal prices due to API error');
        return this.cache.data;
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
      logger.error(`Error fetching price for ${metal}:`, error.message);
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
    const TROY_OUNCE_IN_GRAMS = 31.1034768;

    switch (unit) {
      case 'gram':
        return pricePerOunce / TROY_OUNCE_IN_GRAMS;
      case 'ounce':
        return pricePerOunce;
      case 'kilogram':
        return pricePerOunce * (1000 / TROY_OUNCE_IN_GRAMS);
      default:
        return pricePerOunce;
    }
  }

  /**
   * Clear cache (useful for testing or forced refresh)
   */
  static clearCache(): void {
    this.cache = null;
    logger.info('Metal price cache cleared');
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
      logger.error('Error getting formatted metal prices:', error.message);
      throw error;
    }
  }
}
