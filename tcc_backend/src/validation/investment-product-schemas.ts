import { z } from 'zod';
import { INVESTMENT_PRODUCT_CONSTANTS, INVESTMENT_CATEGORIES } from '../constants/investment-constants';

/**
 * Validation Schemas for Investment Product Management
 * Uses Zod for runtime type checking and validation
 */

// =====================================================
// CATEGORY SCHEMAS
// =====================================================

export const createCategorySchema = z.object({
  body: z.object({
    name: z
      .string()
      .min(1, 'Category name is required')
      .max(INVESTMENT_PRODUCT_CONSTANTS.MAX_CATEGORY_NAME_LENGTH)
      .refine(
        (val) => Object.values(INVESTMENT_CATEGORIES).includes(val as any),
        'Invalid category name'
      ),
    display_name: z
      .string()
      .min(1, 'Display name is required')
      .max(INVESTMENT_PRODUCT_CONSTANTS.MAX_DISPLAY_NAME_LENGTH),
    description: z
      .string()
      .max(INVESTMENT_PRODUCT_CONSTANTS.MAX_DESCRIPTION_LENGTH)
      .optional(),
    sub_categories: z.array(z.string()).optional(),
    icon_url: z.string().url('Invalid icon URL').optional().or(z.literal('')),
  }),
});

export const updateCategorySchema = z.object({
  params: z.object({
    categoryId: z.string().uuid('Invalid category ID'),
  }),
  body: z.object({
    display_name: z
      .string()
      .min(1)
      .max(INVESTMENT_PRODUCT_CONSTANTS.MAX_DISPLAY_NAME_LENGTH)
      .optional(),
    description: z
      .string()
      .max(INVESTMENT_PRODUCT_CONSTANTS.MAX_DESCRIPTION_LENGTH)
      .optional(),
    sub_categories: z.array(z.string()).optional(),
    icon_url: z.string().url().optional().or(z.literal('')),
    is_active: z.boolean().optional(),
  }),
});

export const getCategorySchema = z.object({
  params: z.object({
    categoryId: z.string().uuid('Invalid category ID'),
  }),
});

export const deleteCategorySchema = z.object({
  params: z.object({
    categoryId: z.string().uuid('Invalid category ID'),
  }),
});

// =====================================================
// TENURE SCHEMAS
// =====================================================

export const createTenureSchema = z.object({
  params: z.object({
    categoryId: z.string().uuid('Invalid category ID'),
  }),
  body: z.object({
    duration_months: z
      .number()
      .int('Duration must be an integer')
      .min(
        INVESTMENT_PRODUCT_CONSTANTS.MIN_TENURE_MONTHS,
        `Duration must be at least ${INVESTMENT_PRODUCT_CONSTANTS.MIN_TENURE_MONTHS} month`
      )
      .max(
        INVESTMENT_PRODUCT_CONSTANTS.MAX_TENURE_MONTHS,
        `Duration cannot exceed ${INVESTMENT_PRODUCT_CONSTANTS.MAX_TENURE_MONTHS} months`
      ),
    return_percentage: z
      .number()
      .min(
        INVESTMENT_PRODUCT_CONSTANTS.MIN_RATE_PERCENTAGE,
        'Return percentage must be non-negative'
      )
      .max(
        INVESTMENT_PRODUCT_CONSTANTS.MAX_RATE_PERCENTAGE,
        `Return percentage cannot exceed ${INVESTMENT_PRODUCT_CONSTANTS.MAX_RATE_PERCENTAGE}%`
      )
      .refine(
        (val) => {
          // Check decimal places
          const decimalPlaces = (val.toString().split('.')[1] || '').length;
          return decimalPlaces <= INVESTMENT_PRODUCT_CONSTANTS.RATE_DECIMAL_PLACES;
        },
        `Return percentage can have at most ${INVESTMENT_PRODUCT_CONSTANTS.RATE_DECIMAL_PLACES} decimal places`
      ),
    agreement_template_url: z
      .string()
      .url('Invalid agreement template URL')
      .optional()
      .or(z.literal('')),
  }),
});

export const getTenuresSchema = z.object({
  params: z.object({
    categoryId: z.string().uuid('Invalid category ID'),
  }),
});

export const updateTenureRateSchema = z.object({
  params: z.object({
    tenureId: z.string().uuid('Invalid tenure ID'),
  }),
  body: z.object({
    new_rate: z
      .number()
      .min(
        INVESTMENT_PRODUCT_CONSTANTS.MIN_RATE_PERCENTAGE,
        'Rate must be non-negative'
      )
      .max(
        INVESTMENT_PRODUCT_CONSTANTS.MAX_RATE_PERCENTAGE,
        `Rate cannot exceed ${INVESTMENT_PRODUCT_CONSTANTS.MAX_RATE_PERCENTAGE}%`
      )
      .refine(
        (val) => {
          const decimalPlaces = (val.toString().split('.')[1] || '').length;
          return decimalPlaces <= INVESTMENT_PRODUCT_CONSTANTS.RATE_DECIMAL_PLACES;
        },
        `Rate can have at most ${INVESTMENT_PRODUCT_CONSTANTS.RATE_DECIMAL_PLACES} decimal places`
      ),
    change_reason: z
      .string()
      .min(
        INVESTMENT_PRODUCT_CONSTANTS.MIN_CHANGE_REASON_LENGTH,
        `Change reason must be at least ${INVESTMENT_PRODUCT_CONSTANTS.MIN_CHANGE_REASON_LENGTH} characters`
      )
      .max(
        INVESTMENT_PRODUCT_CONSTANTS.MAX_CHANGE_REASON_LENGTH,
        `Change reason cannot exceed ${INVESTMENT_PRODUCT_CONSTANTS.MAX_CHANGE_REASON_LENGTH} characters`
      )
      .refine(
        (val) => val.trim().length >= INVESTMENT_PRODUCT_CONSTANTS.MIN_CHANGE_REASON_LENGTH,
        'Change reason cannot be just whitespace'
      ),
  }),
});

export const getTenureVersionHistorySchema = z.object({
  params: z.object({
    tenureId: z.string().uuid('Invalid tenure ID'),
  }),
});

// =====================================================
// UNIT SCHEMAS
// =====================================================

export const createUnitSchema = z.object({
  body: z.object({
    category: z
      .string()
      .refine(
        (val) => Object.values(INVESTMENT_CATEGORIES).includes(val as any),
        'Invalid category'
      ),
    unit_name: z
      .string()
      .min(1, 'Unit name is required')
      .max(INVESTMENT_PRODUCT_CONSTANTS.MAX_UNIT_NAME_LENGTH),
    unit_price: z
      .number()
      .min(
        INVESTMENT_PRODUCT_CONSTANTS.MIN_UNIT_PRICE,
        `Unit price must be at least ${INVESTMENT_PRODUCT_CONSTANTS.MIN_UNIT_PRICE}`
      )
      .max(
        INVESTMENT_PRODUCT_CONSTANTS.MAX_UNIT_PRICE,
        `Unit price cannot exceed ${INVESTMENT_PRODUCT_CONSTANTS.MAX_UNIT_PRICE}`
      ),
    description: z
      .string()
      .max(INVESTMENT_PRODUCT_CONSTANTS.MAX_DESCRIPTION_LENGTH)
      .optional(),
    icon_url: z.string().url('Invalid icon URL').optional().or(z.literal('')),
    display_order: z.number().int().min(0).optional(),
  }),
});

export const updateUnitSchema = z.object({
  params: z.object({
    unitId: z.string().uuid('Invalid unit ID'),
  }),
  body: z.object({
    unit_name: z
      .string()
      .min(1)
      .max(INVESTMENT_PRODUCT_CONSTANTS.MAX_UNIT_NAME_LENGTH)
      .optional(),
    unit_price: z
      .number()
      .min(INVESTMENT_PRODUCT_CONSTANTS.MIN_UNIT_PRICE)
      .max(INVESTMENT_PRODUCT_CONSTANTS.MAX_UNIT_PRICE)
      .optional(),
    description: z
      .string()
      .max(INVESTMENT_PRODUCT_CONSTANTS.MAX_DESCRIPTION_LENGTH)
      .optional(),
    icon_url: z.string().url().optional().or(z.literal('')),
    display_order: z.number().int().min(0).optional(),
    is_active: z.boolean().optional(),
  }),
});

export const getUnitsSchema = z.object({
  params: z.object({
    categoryId: z.string().uuid('Invalid category ID'),
  }),
});

export const deleteUnitSchema = z.object({
  params: z.object({
    unitId: z.string().uuid('Invalid unit ID'),
  }),
});

// =====================================================
// REPORT SCHEMAS
// =====================================================

export const getRateChangeHistorySchema = z.object({
  query: z.object({
    category: z
      .string()
      .refine(
        (val) => Object.values(INVESTMENT_CATEGORIES).includes(val as any),
        'Invalid category'
      )
      .optional(),
    from_date: z
      .string()
      .datetime({ message: 'Invalid from_date format (ISO 8601 required)' })
      .optional(),
    to_date: z
      .string()
      .datetime({ message: 'Invalid to_date format (ISO 8601 required)' })
      .optional(),
    admin_id: z.string().uuid('Invalid admin ID').optional(),
  }),
});

export const getVersionReportSchema = z.object({
  query: z.object({
    category: z
      .string()
      .refine(
        (val) => Object.values(INVESTMENT_CATEGORIES).includes(val as any),
        'Invalid category'
      )
      .optional(),
    tenure_id: z.string().uuid('Invalid tenure ID').optional(),
    from_date: z
      .string()
      .datetime({ message: 'Invalid from_date format (ISO 8601 required)' })
      .optional(),
    to_date: z
      .string()
      .datetime({ message: 'Invalid to_date format (ISO 8601 required)' })
      .optional(),
  }),
});

// =====================================================
// PAGINATION SCHEMA
// =====================================================

export const paginationSchema = z.object({
  query: z.object({
    page: z
      .string()
      .optional()
      .transform((val) => (val ? parseInt(val, 10) : 1))
      .refine((val) => val > 0, 'Page must be greater than 0'),
    limit: z
      .string()
      .optional()
      .transform((val) =>
        val
          ? Math.min(
              parseInt(val, 10),
              INVESTMENT_PRODUCT_CONSTANTS.MAX_PAGE_SIZE
            )
          : INVESTMENT_PRODUCT_CONSTANTS.DEFAULT_PAGE_SIZE
      )
      .refine((val) => val > 0 && val <= INVESTMENT_PRODUCT_CONSTANTS.MAX_PAGE_SIZE,
        `Limit must be between 1 and ${INVESTMENT_PRODUCT_CONSTANTS.MAX_PAGE_SIZE}`),
  }),
});

// =====================================================
// EXPORT ALL SCHEMAS
// =====================================================

export const investmentProductSchemas = {
  // Categories
  createCategory: createCategorySchema,
  updateCategory: updateCategorySchema,
  getCategory: getCategorySchema,
  deleteCategory: deleteCategorySchema,

  // Tenures
  createTenure: createTenureSchema,
  getTenures: getTenuresSchema,
  updateTenureRate: updateTenureRateSchema,
  getTenureVersionHistory: getTenureVersionHistorySchema,

  // Units
  createUnit: createUnitSchema,
  updateUnit: updateUnitSchema,
  getUnits: getUnitsSchema,
  deleteUnit: deleteUnitSchema,

  // Reports
  getRateChangeHistory: getRateChangeHistorySchema,
  getVersionReport: getVersionReportSchema,

  // Pagination
  pagination: paginationSchema,
} as const;

export default investmentProductSchemas;
