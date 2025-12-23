# Investment Product Versioning API Documentation

## Overview

This document provides comprehensive documentation for the Investment Product Versioning API. This system allows admins to manage investment products (categories, tenures, units) with automatic rate versioning, user notifications, and detailed reporting.

---

## Table of Contents

1. [Authentication](#authentication)
2. [Category Management](#category-management)
3. [Tenure Management](#tenure-management)
4. [Unit Management](#unit-management)
5. [Reporting & History](#reporting--history)
6. [Data Models](#data-models)
7. [Error Handling](#error-handling)
8. [Examples](#examples)

---

## Authentication

All endpoints require admin authentication using Bearer token.

```
Authorization: Bearer <your_admin_token>
```

**Required Roles:** `ADMIN` or `SUPER_ADMIN`

---

## Category Management

### GET /admin/investment-products/categories

Get all investment categories with version information.

**Request:**
```http
GET /admin/investment-products/categories
Authorization: Bearer <token>
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "category": {
        "id": "uuid",
        "name": "AGRICULTURE",
        "display_name": "Agriculture",
        "description": "Invest in agricultural projects",
        "sub_categories": ["Land Lease", "Production"],
        "icon_url": "https://...",
        "is_active": true,
        "created_at": "2024-01-01T00:00:00Z",
        "updated_at": "2024-01-01T00:00:00Z"
      },
      "tenures": [
        {
          "tenure": {
            "id": "uuid",
            "category_id": "uuid",
            "duration_months": 12,
            "return_percentage": 10.50,
            "agreement_template_url": "https://...",
            "is_active": true,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
          },
          "current_version": {
            "id": "uuid",
            "tenure_id": "uuid",
            "version_number": 2,
            "return_percentage": 10.50,
            "effective_from": "2024-06-01T00:00:00Z",
            "effective_until": null,
            "is_current": true,
            "change_reason": "Market adjustment",
            "changed_by": "admin-uuid",
            "admin_name": "John Doe",
            "created_at": "2024-06-01T00:00:00Z",
            "updated_at": "2024-06-01T00:00:00Z"
          },
          "version_history": [...],
          "investment_count": 150,
          "total_amount": 500000.00
        }
      ]
    }
  ]
}
```

---

### POST /admin/investment-products/categories

Create a new investment category.

**Request:**
```http
POST /admin/investment-products/categories
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "TECHNOLOGY",
  "display_name": "Technology",
  "description": "Invest in technology startups",
  "sub_categories": ["AI", "Blockchain", "Fintech"],
  "icon_url": "https://example.com/tech-icon.png"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "TECHNOLOGY",
    "display_name": "Technology",
    "description": "Invest in technology startups",
    "sub_categories": ["AI", "Blockchain", "Fintech"],
    "icon_url": "https://example.com/tech-icon.png",
    "is_active": true,
    "created_at": "2024-12-22T10:00:00Z",
    "updated_at": "2024-12-22T10:00:00Z"
  },
  "message": "Investment category created successfully"
}
```

**Validation:**
- `name` (required): Must be unique
- `display_name` (required): Display name for UI
- `description` (optional): Category description
- `sub_categories` (optional): Array of sub-category names
- `icon_url` (optional): URL to category icon

---

### PUT /admin/investment-products/categories/:categoryId

Update an existing investment category.

**Request:**
```http
PUT /admin/investment-products/categories/uuid
Authorization: Bearer <token>
Content-Type: application/json

{
  "display_name": "Updated Technology",
  "description": "Updated description",
  "sub_categories": ["AI", "Blockchain", "Fintech", "IoT"],
  "is_active": true
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": { /* updated category object */ },
  "message": "Investment category updated successfully"
}
```

**Notes:**
- All fields are optional
- Only provided fields will be updated
- Cannot change the `name` field (use for internal enum matching)

---

### DELETE /admin/investment-products/categories/:categoryId

Deactivate an investment category (soft delete).

**Request:**
```http
DELETE /admin/investment-products/categories/uuid
Authorization: Bearer <token>
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Investment category deactivated successfully"
}
```

---

## Tenure Management

### GET /admin/investment-products/categories/:categoryId/tenures

Get all tenures for a category with version history.

**Request:**
```http
GET /admin/investment-products/categories/uuid/tenures
Authorization: Bearer <token>
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "tenure": {
        "id": "uuid",
        "category_id": "uuid",
        "duration_months": 12,
        "return_percentage": 10.50,
        "is_active": true
      },
      "current_version": {
        "id": "uuid",
        "version_number": 2,
        "return_percentage": 10.50,
        "is_current": true,
        "change_reason": "Market conditions improved"
      },
      "version_history": [
        {
          "id": "uuid",
          "version_number": 2,
          "return_percentage": 10.50,
          "effective_from": "2024-06-01T00:00:00Z",
          "effective_until": null,
          "is_current": true
        },
        {
          "id": "uuid",
          "version_number": 1,
          "return_percentage": 10.00,
          "effective_from": "2024-01-01T00:00:00Z",
          "effective_until": "2024-06-01T00:00:00Z",
          "is_current": false
        }
      ],
      "investment_count": 150,
      "total_amount": 500000.00
    }
  ]
}
```

---

### POST /admin/investment-products/categories/:categoryId/tenures

Create a new investment tenure.

**Request:**
```http
POST /admin/investment-products/categories/uuid/tenures
Authorization: Bearer <token>
Content-Type: application/json

{
  "duration_months": 24,
  "return_percentage": 15.00,
  "agreement_template_url": "https://example.com/agreement-template.pdf"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "category_id": "uuid",
    "duration_months": 24,
    "return_percentage": 15.00,
    "agreement_template_url": "https://example.com/agreement-template.pdf",
    "is_active": true,
    "created_at": "2024-12-22T10:00:00Z",
    "updated_at": "2024-12-22T10:00:00Z"
  },
  "message": "Investment tenure created successfully"
}
```

**Validation:**
- `duration_months` (required): Must be > 0
- `return_percentage` (required): Must be >= 0
- `agreement_template_url` (optional): URL to agreement template

**Automatic Actions:**
- Creates version 1 for the new tenure
- Sets version as current

---

### PUT /admin/investment-products/tenures/:tenureId/rate

Update tenure rate - creates a new version and notifies users.

**Request:**
```http
PUT /admin/investment-products/tenures/uuid/rate
Authorization: Bearer <token>
Content-Type: application/json

{
  "new_rate": 12.00,
  "change_reason": "Interest rates increased due to market conditions"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "tenure_id": "uuid",
    "version_number": 3,
    "return_percentage": 12.00,
    "effective_from": "2024-12-22T10:30:00Z",
    "effective_until": null,
    "is_current": true,
    "change_reason": "Interest rates increased due to market conditions",
    "changed_by": "admin-uuid",
    "created_at": "2024-12-22T10:30:00Z",
    "updated_at": "2024-12-22T10:30:00Z"
  },
  "message": "Investment rate updated successfully. Users have been notified."
}
```

**Validation:**
- `new_rate` (required): Must be >= 0, must be different from current rate
- `change_reason` (required): Must not be empty

**Automatic Actions:**
1. Closes current version (sets `effective_until`, `is_current = false`)
2. Creates new version with incremented version number
3. Updates `investment_tenures.return_percentage` for backward compatibility
4. Finds all users with active investments in this product
5. Creates in-app notifications for each user
6. Tracks notifications in `investment_rate_change_notifications` table
7. Creates audit log entry

**Important Notes:**
- Existing investments retain their original rate (locked to old version)
- Only NEW investments created after this update will use the new rate
- All users with active investments receive notifications
- Transaction is atomic - all or nothing

---

### GET /admin/investment-products/tenures/:tenureId/versions

Get complete version history for a tenure.

**Request:**
```http
GET /admin/investment-products/tenures/uuid/versions
Authorization: Bearer <token>
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "tenure_id": "uuid",
      "version_number": 3,
      "return_percentage": 12.00,
      "effective_from": "2024-12-22T10:30:00Z",
      "effective_until": null,
      "is_current": true,
      "change_reason": "Market conditions improved",
      "changed_by": "admin-uuid",
      "admin_name": "John Doe",
      "created_at": "2024-12-22T10:30:00Z",
      "updated_at": "2024-12-22T10:30:00Z"
    },
    {
      "id": "uuid",
      "tenure_id": "uuid",
      "version_number": 2,
      "return_percentage": 10.50,
      "effective_from": "2024-06-01T00:00:00Z",
      "effective_until": "2024-12-22T10:30:00Z",
      "is_current": false,
      "change_reason": "Quarterly review adjustment",
      "changed_by": "admin-uuid",
      "admin_name": "Jane Smith"
    },
    {
      "id": "uuid",
      "tenure_id": "uuid",
      "version_number": 1,
      "return_percentage": 10.00,
      "effective_from": "2024-01-01T00:00:00Z",
      "effective_until": "2024-06-01T00:00:00Z",
      "is_current": false,
      "change_reason": "Initial version from migration",
      "changed_by": null,
      "admin_name": "System"
    }
  ]
}
```

---

## Unit Management

### GET /admin/investment-products/categories/:categoryId/units

Get all units for a category.

**Request:**
```http
GET /admin/investment-products/categories/uuid/units
Authorization: Bearer <token>
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "category": "AGRICULTURE",
      "unit_name": "Lot",
      "unit_price": 234.00,
      "description": "Small agricultural plot",
      "icon_url": "https://...",
      "display_order": 1,
      "is_active": true,
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

---

### POST /admin/investment-products/units

Create a new investment unit.

**Request:**
```http
POST /admin/investment-products/units
Authorization: Bearer <token>
Content-Type: application/json

{
  "category": "AGRICULTURE",
  "unit_name": "Premium Farm",
  "unit_price": 5000.00,
  "description": "Large agricultural farm",
  "icon_url": "https://example.com/farm-icon.png",
  "display_order": 4
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "category": "AGRICULTURE",
    "unit_name": "Premium Farm",
    "unit_price": 5000.00,
    "description": "Large agricultural farm",
    "icon_url": "https://example.com/farm-icon.png",
    "display_order": 4,
    "is_active": true,
    "created_at": "2024-12-22T10:00:00Z",
    "updated_at": "2024-12-22T10:00:00Z"
  },
  "message": "Investment unit created successfully"
}
```

**Validation:**
- `category` (required): Must be valid investment category enum
- `unit_name` (required): Must be unique per category
- `unit_price` (required): Must be > 0
- `description` (optional): Unit description
- `icon_url` (optional): URL to unit icon
- `display_order` (optional): Order for display (default: 0)

---

### PUT /admin/investment-products/units/:unitId

Update an investment unit.

**Request:**
```http
PUT /admin/investment-products/units/uuid
Authorization: Bearer <token>
Content-Type: application/json

{
  "unit_name": "Updated Farm",
  "unit_price": 5500.00,
  "display_order": 3,
  "is_active": true
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": { /* updated unit object */ },
  "message": "Investment unit updated successfully"
}
```

---

### DELETE /admin/investment-products/units/:unitId

Delete an investment unit (soft delete).

**Request:**
```http
DELETE /admin/investment-products/units/uuid
Authorization: Bearer <token>
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Investment unit deleted successfully"
}
```

---

## Reporting & History

### GET /admin/investment-products/rate-changes/history

Get rate change history with filters.

**Request:**
```http
GET /admin/investment-products/rate-changes/history?category=AGRICULTURE&from_date=2024-01-01&to_date=2024-12-31
Authorization: Bearer <token>
```

**Query Parameters:**
- `category` (optional): Filter by category (AGRICULTURE, EDUCATION, MINERALS)
- `from_date` (optional): Start date (ISO 8601 format)
- `to_date` (optional): End date (ISO 8601 format)
- `admin_id` (optional): Filter by admin who made changes

**Response:** `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "version_id": "uuid",
      "tenure_id": "uuid",
      "category": "AGRICULTURE",
      "category_display_name": "Agriculture",
      "tenure_months": 12,
      "version_number": 3,
      "old_rate": 10.50,
      "new_rate": 12.00,
      "change_reason": "Market conditions improved",
      "changed_by": "admin-uuid",
      "admin_name": "John Doe",
      "effective_from": "2024-12-22T10:30:00Z",
      "users_notified": 45,
      "active_investments": 150
    }
  ]
}
```

---

### GET /admin/investment-products/versions/report

Get version-based report showing investments grouped by version.

**Request:**
```http
GET /admin/investment-products/versions/report?category=AGRICULTURE
Authorization: Bearer <token>
```

**Query Parameters:**
- `category` (optional): Filter by category
- `tenure_id` (optional): Filter by specific tenure
- `from_date` (optional): Start date for version effective dates
- `to_date` (optional): End date for version effective dates

**Response:** `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "tenure_id": "uuid",
      "category": "AGRICULTURE",
      "tenure_months": 12,
      "versions": [
        {
          "version_id": "uuid",
          "version_number": 3,
          "return_percentage": 12.00,
          "effective_from": "2024-12-22T10:30:00Z",
          "effective_until": null,
          "is_current": true,
          "investment_count": 25,
          "total_amount": 125000.00,
          "active_count": 25
        },
        {
          "version_id": "uuid",
          "version_number": 2,
          "return_percentage": 10.50,
          "effective_from": "2024-06-01T00:00:00Z",
          "effective_until": "2024-12-22T10:30:00Z",
          "is_current": false,
          "investment_count": 75,
          "total_amount": 250000.00,
          "active_count": 60
        },
        {
          "version_id": "uuid",
          "version_number": 1,
          "return_percentage": 10.00,
          "effective_from": "2024-01-01T00:00:00Z",
          "effective_until": "2024-06-01T00:00:00Z",
          "is_current": false,
          "investment_count": 50,
          "total_amount": 125000.00,
          "active_count": 15
        }
      ],
      "summary": {
        "total_versions": 3,
        "total_investments": 150,
        "total_amount": 500000.00,
        "current_rate": 12.00
      }
    }
  ]
}
```

**Use Cases:**
- Analyze version adoption rates
- Identify how many investments are on old rates
- Calculate impact of rate changes
- Generate reports for stakeholders

---

## Data Models

### ProductVersion

```typescript
{
  id: string;                    // UUID
  tenure_id: string;             // Reference to investment_tenures
  version_number: number;        // Sequential version (1, 2, 3...)
  return_percentage: number;     // Interest rate (e.g., 10.50)
  effective_from: Date;          // When this version became active
  effective_until: Date | null;  // When superseded (null = current)
  is_current: boolean;           // Only one true per tenure
  change_reason: string | null;  // Why rate changed
  changed_by: string | null;     // Admin user ID
  metadata: object | null;       // Additional JSON data
  created_at: Date;
  updated_at: Date;
}
```

### InvestmentTenure

```typescript
{
  id: string;
  category_id: string;
  duration_months: number;       // 6, 12, 24, etc.
  return_percentage: number;     // Current rate (synced with current version)
  agreement_template_url: string | null;
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
}
```

### Investment (Updated)

```typescript
{
  id: string;
  user_id: string;
  category: string;
  sub_category: string | null;
  tenure_id: string;
  amount: number;
  tenure_months: number;
  return_rate: number;           // Locked rate from version
  expected_return: number;
  actual_return: number | null;
  start_date: Date;
  end_date: Date;
  status: string;                // ACTIVE, MATURED, WITHDRAWN, CANCELLED
  product_version_id: string;    // 🆕 Links to specific version
  // ... other fields
}
```

---

## Error Handling

### Error Response Format

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": { /* optional additional info */ },
    "timestamp": "2024-12-22T10:00:00Z",
    "request_id": "uuid"
  }
}
```

### Common Error Codes

| Status Code | Error Code | Description |
|-------------|------------|-------------|
| 400 | `INVALID_AMOUNT` | Amount must be greater than 0 |
| 400 | `INVALID_DURATION` | Duration must be greater than 0 |
| 400 | `RATE_UNCHANGED` | New rate is same as current rate |
| 400 | `NO_UPDATES_PROVIDED` | No fields provided for update |
| 401 | `UNAUTHORIZED` | Authentication token missing or invalid |
| 403 | `FORBIDDEN` | User doesn't have required role |
| 404 | `CATEGORY_NOT_FOUND` | Investment category not found |
| 404 | `TENURE_NOT_FOUND` | Investment tenure not found |
| 404 | `UNIT_NOT_FOUND` | Investment unit not found |
| 404 | `NO_CURRENT_VERSION_FOUND` | No current version exists for tenure |
| 409 | `DUPLICATE_ENTRY` | Category/unit name already exists |
| 500 | `INTERNAL_ERROR` | Internal server error |

---

## Examples

### Example 1: Create Category and Tenure

```bash
# 1. Create category
curl -X POST http://localhost:3000/admin/investment-products/categories \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "REAL_ESTATE",
    "display_name": "Real Estate",
    "description": "Invest in real estate properties",
    "sub_categories": ["Residential", "Commercial", "Land"]
  }'

# Response: { "success": true, "data": { "id": "cat-uuid", ... } }

# 2. Create tenure for the category
curl -X POST http://localhost:3000/admin/investment-products/categories/cat-uuid/tenures \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "duration_months": 12,
    "return_percentage": 8.5
  }'

# Response: { "success": true, "data": { "id": "tenure-uuid", ... } }
```

### Example 2: Update Rate and View History

```bash
# 1. Update rate (creates new version)
curl -X PUT http://localhost:3000/admin/investment-products/tenures/tenure-uuid/rate \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "new_rate": 9.0,
    "change_reason": "Quarterly rate adjustment based on market performance"
  }'

# Response: New version created, users notified

# 2. View version history
curl -X GET http://localhost:3000/admin/investment-products/tenures/tenure-uuid/versions \
  -H "Authorization: Bearer YOUR_TOKEN"

# Response: Array of all versions with timestamps and reasons
```

### Example 3: Generate Reports

```bash
# 1. Get rate change history for last 6 months
curl -X GET "http://localhost:3000/admin/investment-products/rate-changes/history?from_date=2024-06-01&to_date=2024-12-31" \
  -H "Authorization: Bearer YOUR_TOKEN"

# 2. Get version report for Agriculture category
curl -X GET "http://localhost:3000/admin/investment-products/versions/report?category=AGRICULTURE" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Database Schema Reference

### Key Tables

1. **investment_product_versions**
   - Primary versioning table
   - Stores all historical rates
   - Enforces only one current version per tenure

2. **investment_rate_change_notifications**
   - Tracks which users received notifications
   - Links to both version and notification tables

3. **investments** (modified)
   - Added `product_version_id` column
   - Links to specific version at creation time
   - Rate never changes after creation

### Helper Functions

1. **get_current_product_version(tenure_id)**
   - Returns current version for a tenure
   - Used in investment creation

2. **get_tenure_version_history(tenure_id)**
   - Returns all versions ordered by version number
   - Includes admin name and change reason

3. **get_investment_count_by_version(tenure_id)**
   - Returns investment statistics per version
   - Used for reporting

---

## Best Practices

### For Admins

1. **Always provide clear change reasons** when updating rates
   - Good: "Adjusted based on Q4 market performance and inflation rates"
   - Bad: "Update"

2. **Review impact before rate changes**
   - Check how many users will be notified
   - Consider timing (avoid weekends/holidays)

3. **Monitor version adoption**
   - Use version reports to see how many investments are on old rates
   - Helps understand rate change impact

4. **Use filters for targeted analysis**
   - Filter by category, date range, or admin
   - Export data for detailed analysis

### For Developers

1. **Always use product_version_id in investments**
   - Ensures rate is locked to specific version
   - Enables accurate historical reporting

2. **Handle rate updates atomically**
   - All steps happen in a transaction
   - Rollback on any failure

3. **Test notification delivery**
   - Ensure users receive rate change notifications
   - Monitor notification table for delivery status

4. **Index performance**
   - Queries use indexes on version_id, tenure_id, is_current
   - Ensure migrations include all indexes

---

## Support

For questions or issues:
- Backend Issues: Check `/Volumes/Extreme SSD/projects/tcc/tcc_backend/src/services/investment-product.service.ts`
- API Endpoints: Check `/Volumes/Extreme SSD/projects/tcc/tcc_backend/src/routes/admin.routes.ts`
- Database Schema: Check `/Volumes/Extreme SSD/projects/tcc/database_schema.sql`

---

**Version:** 1.0
**Last Updated:** 2024-12-22
**Status:** Production Ready
