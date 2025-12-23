/**
 * Investment Product Constants
 * Centralized configuration for investment product management
 */

export const INVESTMENT_PRODUCT_CONSTANTS = {
  // Validation Limits
  MAX_CHANGE_REASON_LENGTH: 500,
  MIN_CHANGE_REASON_LENGTH: 10,
  MAX_DESCRIPTION_LENGTH: 1000,
  MAX_DISPLAY_NAME_LENGTH: 100,
  MAX_UNIT_NAME_LENGTH: 50,
  MAX_CATEGORY_NAME_LENGTH: 50,

  // Rate Constraints
  MAX_RATE_PERCENTAGE: 100,
  MIN_RATE_PERCENTAGE: 0,
  RATE_DECIMAL_PLACES: 2,

  // Duration Constraints
  MIN_TENURE_MONTHS: 1,
  MAX_TENURE_MONTHS: 120, // 10 years

  // Price Constraints
  MIN_UNIT_PRICE: 0.01,
  MAX_UNIT_PRICE: 1000000,

  // Caching
  CATEGORY_CACHE_TTL_MS: 5 * 60 * 1000, // 5 minutes
  VERSION_CACHE_TTL_MS: 2 * 60 * 1000, // 2 minutes

  // Transaction Settings
  TRANSACTION_TIMEOUT_MS: 30000, // 30 seconds
  MAX_RETRY_ATTEMPTS: 3,

  // Notification Settings
  NOTIFICATION_BATCH_SIZE: 100,
  MAX_NOTIFICATIONS_PER_RATE_CHANGE: 10000,

  // Pagination
  DEFAULT_PAGE_SIZE: 25,
  MAX_PAGE_SIZE: 100,

  // Performance
  SLOW_QUERY_THRESHOLD_MS: 1000, // Log queries slower than 1s
  MAX_VERSION_HISTORY_DISPLAY: 50, // Limit version history in UI

  // Audit
  AUDIT_LOG_RETENTION_DAYS: 365,

  // Database
  MAX_PARALLEL_QUERIES: 10,
  CONNECTION_POOL_MIN: 5,
  CONNECTION_POOL_MAX: 20,
} as const;

/**
 * Investment Product Error Codes
 */
export const INVESTMENT_ERRORS = {
  // Category Errors
  CATEGORY_NOT_FOUND: 'CATEGORY_NOT_FOUND',
  CATEGORY_ALREADY_EXISTS: 'CATEGORY_ALREADY_EXISTS',
  CATEGORY_HAS_ACTIVE_TENURES: 'CATEGORY_HAS_ACTIVE_TENURES',

  // Tenure Errors
  TENURE_NOT_FOUND: 'TENURE_NOT_FOUND',
  TENURE_ALREADY_EXISTS: 'TENURE_ALREADY_EXISTS',
  TENURE_HAS_ACTIVE_INVESTMENTS: 'TENURE_HAS_ACTIVE_INVESTMENTS',
  INVALID_DURATION: 'INVALID_DURATION',

  // Version Errors
  NO_CURRENT_VERSION_FOUND: 'NO_CURRENT_VERSION_FOUND',
  RATE_UNCHANGED: 'RATE_UNCHANGED',
  INVALID_RATE: 'INVALID_RATE',
  VERSION_CONFLICT: 'VERSION_CONFLICT',

  // Unit Errors
  UNIT_NOT_FOUND: 'UNIT_NOT_FOUND',
  UNIT_ALREADY_EXISTS: 'UNIT_ALREADY_EXISTS',
  INVALID_UNIT_PRICE: 'INVALID_UNIT_PRICE',

  // Validation Errors
  INVALID_AMOUNT: 'INVALID_AMOUNT',
  CHANGE_REASON_TOO_SHORT: 'CHANGE_REASON_TOO_SHORT',
  CHANGE_REASON_TOO_LONG: 'CHANGE_REASON_TOO_LONG',
  NO_UPDATES_PROVIDED: 'NO_UPDATES_PROVIDED',

  // General Errors
  TRANSACTION_FAILED: 'TRANSACTION_FAILED',
  DATABASE_ERROR: 'DATABASE_ERROR',
  NOTIFICATION_FAILED: 'NOTIFICATION_FAILED',
} as const;

/**
 * Investment Categories (Enums)
 */
export const INVESTMENT_CATEGORIES = {
  AGRICULTURE: 'AGRICULTURE',
  EDUCATION: 'EDUCATION',
  MINERALS: 'MINERALS',
  REAL_ESTATE: 'REAL_ESTATE',
  TECHNOLOGY: 'TECHNOLOGY',
} as const;

/**
 * Investment Status Values
 */
export const INVESTMENT_STATUS = {
  ACTIVE: 'ACTIVE',
  MATURED: 'MATURED',
  WITHDRAWN: 'WITHDRAWN',
  CANCELLED: 'CANCELLED',
} as const;

/**
 * Notification Types
 */
export const NOTIFICATION_TYPES = {
  RATE_CHANGE: 'INVESTMENT',
  INVESTMENT_MATURED: 'INVESTMENT_MATURED',
  INVESTMENT_CREATED: 'INVESTMENT_CREATED',
} as const;

/**
 * Audit Action Types
 */
export const AUDIT_ACTIONS = {
  UPDATE_RATE: 'UPDATE_INVESTMENT_RATE',
  CREATE_CATEGORY: 'CREATE_INVESTMENT_CATEGORY',
  UPDATE_CATEGORY: 'UPDATE_INVESTMENT_CATEGORY',
  DEACTIVATE_CATEGORY: 'DEACTIVATE_INVESTMENT_CATEGORY',
  CREATE_TENURE: 'CREATE_INVESTMENT_TENURE',
  UPDATE_TENURE: 'UPDATE_INVESTMENT_TENURE',
  CREATE_UNIT: 'CREATE_INVESTMENT_UNIT',
  UPDATE_UNIT: 'UPDATE_INVESTMENT_UNIT',
  DELETE_UNIT: 'DELETE_INVESTMENT_UNIT',
} as const;

/**
 * Rate Change Templates
 */
export const RATE_CHANGE_TEMPLATES = {
  IN_APP_TITLE: 'Investment Rate Update',
  IN_APP_MESSAGE: (
    category: string,
    tenureMonths: number,
    oldRate: number,
    newRate: number
  ): string =>
    `The return rate for ${category} - ${tenureMonths} months has changed from ${oldRate}% to ${newRate}%. Your existing investments remain at the original rate.`,

  EMAIL_SUBJECT: 'Important: Investment Return Rate Update',
  EMAIL_BODY: (
    userName: string,
    category: string,
    tenureMonths: number,
    oldRate: number,
    newRate: number,
    effectiveDate: string,
    changeReason: string
  ): string => `
Dear ${userName},

We are writing to inform you about an update to our investment products.

Product: ${category} - ${tenureMonths} months
Previous Rate: ${oldRate}%
New Rate: ${newRate}%
Effective From: ${effectiveDate}

Reason: ${changeReason}

IMPORTANT: Your existing investments will continue to earn returns at the original rate of ${oldRate}%. Only new investments made after ${effectiveDate} will use the new rate of ${newRate}%.

If you have any questions, please contact our support team.

Best regards,
The TCC Team
  `,
} as const;

/**
 * Helper Functions
 */
export const INVESTMENT_HELPERS = {
  /**
   * Format rate for display
   */
  formatRate: (rate: number): string => {
    return rate.toFixed(INVESTMENT_PRODUCT_CONSTANTS.RATE_DECIMAL_PLACES) + '%';
  },

  /**
   * Validate rate value
   */
  isValidRate: (rate: number): boolean => {
    return (
      rate >= INVESTMENT_PRODUCT_CONSTANTS.MIN_RATE_PERCENTAGE &&
      rate <= INVESTMENT_PRODUCT_CONSTANTS.MAX_RATE_PERCENTAGE
    );
  },

  /**
   * Validate duration
   */
  isValidDuration: (months: number): boolean => {
    return (
      months >= INVESTMENT_PRODUCT_CONSTANTS.MIN_TENURE_MONTHS &&
      months <= INVESTMENT_PRODUCT_CONSTANTS.MAX_TENURE_MONTHS
    );
  },

  /**
   * Validate change reason
   */
  isValidChangeReason: (reason: string): boolean => {
    const trimmed = reason.trim();
    return (
      trimmed.length >= INVESTMENT_PRODUCT_CONSTANTS.MIN_CHANGE_REASON_LENGTH &&
      trimmed.length <= INVESTMENT_PRODUCT_CONSTANTS.MAX_CHANGE_REASON_LENGTH
    );
  },

  /**
   * Sanitize string input
   */
  sanitizeString: (input: string, maxLength: number): string => {
    return input.trim().slice(0, maxLength);
  },

  /**
   * Calculate rate change percentage
   */
  calculateRateChange: (oldRate: number, newRate: number): number => {
    if (oldRate === 0) return 0;
    return ((newRate - oldRate) / oldRate) * 100;
  },
} as const;

export default INVESTMENT_PRODUCT_CONSTANTS;
