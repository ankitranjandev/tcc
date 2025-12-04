# TCC Admin API Documentation

This document describes the Admin API endpoints for the TCC backend application.

## Base URL
```
https://api.tccapp.com/v1/admin
```

## Authentication

All endpoints (except login) require authentication with a valid JWT access token with ADMIN or SUPER_ADMIN role.

```http
Authorization: Bearer <access_token>
```

---

## Endpoints

### 1. Admin Login

Login with email, password, and optional TOTP code for two-factor authentication.

**Endpoint:** `POST /admin/login`

**Authentication:** Not required

**Request Body:**
```json
{
  "email": "admin@tccapp.com",
  "password": "SecurePassword123!",
  "totp_code": "123456"  // Optional, required if 2FA is enabled
}
```

**Response (Password verified, requires TOTP):**
```json
{
  "success": true,
  "data": {
    "requires_totp": true
  },
  "message": "Password verified. Please provide TOTP code."
}
```

**Response (Login successful):**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 3600,
    "admin": {
      "id": "uuid",
      "first_name": "Admin",
      "last_name": "User",
      "email": "admin@tccapp.com",
      "role": "ADMIN"
    }
  },
  "message": "Login successful"
}
```

**Error Responses:**
- `401 Unauthorized`: Invalid credentials or TOTP code
- `403 Forbidden`: Account locked or inactive

---

### 2. Get Dashboard Statistics

Get real-time KPIs for the admin dashboard.

**Endpoint:** `GET /admin/dashboard/stats`

**Authentication:** Required (ADMIN or SUPER_ADMIN)

**Response:**
```json
{
  "success": true,
  "data": {
    "totalUsers": 1500,
    "totalTransactions": 25000,
    "totalRevenue": 50000000.00,
    "activeAgents": 45,
    "pendingWithdrawals": 12,
    "pendingKYC": 8,
    "todayRevenue": 150000.00,
    "todayTransactions": 350
  }
}
```

---

### 3. Get Users

Get users with optional filters and pagination.

**Endpoint:** `GET /admin/users`

**Authentication:** Required (ADMIN or SUPER_ADMIN)

**Query Parameters:**
- `search` (optional): Search by name, email, or phone
- `role` (optional): Filter by role (USER, AGENT, ADMIN, SUPER_ADMIN)
- `kyc_status` (optional): Filter by KYC status (PENDING, SUBMITTED, APPROVED, REJECTED)
- `is_active` (optional): Filter by active status (true/false)
- `page` (optional, default: 1): Page number
- `limit` (optional, default: 20): Items per page

**Example Request:**
```
GET /admin/users?search=john&kyc_status=APPROVED&page=1&limit=20
```

**Response:**
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "id": "uuid",
        "first_name": "John",
        "last_name": "Doe",
        "email": "john@example.com",
        "phone": "2331234567",
        "country_code": "+232",
        "role": "USER",
        "kyc_status": "APPROVED",
        "is_active": true,
        "is_verified": true,
        "created_at": "2024-01-15T10:30:00Z",
        "last_login_at": "2024-01-20T08:15:00Z"
      }
    ]
  },
  "meta": {
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 150,
      "totalPages": 8
    }
  }
}
```

---

### 4. Get Withdrawal Requests

Get withdrawal requests with optional status filter and pagination.

**Endpoint:** `GET /admin/withdrawals`

**Authentication:** Required (ADMIN or SUPER_ADMIN)

**Query Parameters:**
- `status` (optional): Filter by status (PENDING, PROCESSING, COMPLETED, FAILED, CANCELLED)
- `page` (optional, default: 1): Page number
- `limit` (optional, default: 20): Items per page

**Example Request:**
```
GET /admin/withdrawals?status=PENDING&page=1&limit=20
```

**Response:**
```json
{
  "success": true,
  "data": {
    "withdrawals": [
      {
        "id": "uuid",
        "user_id": "uuid",
        "amount": 100000.00,
        "fee": 2000.00,
        "net_amount": 98000.00,
        "withdrawal_type": "WALLET",
        "destination": "BANK",
        "status": "PENDING",
        "rejection_reason": null,
        "created_at": "2024-01-20T10:30:00Z",
        "approved_at": null,
        "first_name": "John",
        "last_name": "Doe",
        "email": "john@example.com",
        "phone": "2331234567",
        "bank_name": "Sierra Leone Commercial Bank",
        "account_number": "****1234"
      }
    ]
  },
  "meta": {
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 12,
      "totalPages": 1
    }
  }
}
```

---

### 5. Review Withdrawal Request

Approve or reject a withdrawal request.

**Endpoint:** `POST /admin/withdrawals/review`

**Authentication:** Required (ADMIN or SUPER_ADMIN)

**Request Body:**
```json
{
  "withdrawal_id": "uuid",
  "status": "COMPLETED",  // or "REJECTED"
  "reason": "Insufficient documentation"  // Required if status is REJECTED
}
```

**Response (Success):**
```json
{
  "success": true,
  "data": null,
  "message": "Withdrawal approved successfully"
}
```

**Error Responses:**
- `400 Bad Request`: Invalid status or missing reason for rejection
- `404 Not Found`: Withdrawal request not found
- `409 Conflict`: Withdrawal already processed

**Notes:**
- Approved withdrawals create a transaction record and deduct from user wallet
- Rejected withdrawals refund the amount to user wallet
- User receives a notification with the decision
- Admin action is logged in audit log

---

### 6. Review Agent Credit Request

Approve or reject an agent credit request.

**Endpoint:** `POST /admin/agent-credits/review`

**Authentication:** Required (ADMIN or SUPER_ADMIN)

**Request Body:**
```json
{
  "request_id": "uuid",
  "status": "COMPLETED",  // or "REJECTED"
  "reason": "Invalid receipt"  // Required if status is REJECTED
}
```

**Response (Success):**
```json
{
  "success": true,
  "data": null,
  "message": "Agent credit request approved successfully"
}
```

**Error Responses:**
- `400 Bad Request`: Invalid status or missing reason for rejection
- `404 Not Found`: Credit request not found
- `409 Conflict`: Request already processed

**Notes:**
- Approved requests credit the agent wallet
- A transaction record is created for tracking
- Admin action is logged in audit log

---

### 7. Get System Configuration

Get all system configuration settings.

**Endpoint:** `GET /admin/config`

**Authentication:** Required (ADMIN or SUPER_ADMIN)

**Response:**
```json
{
  "success": true,
  "data": {
    "config": {
      "MIN_DEPOSIT_AMOUNT": {
        "value": 1000,
        "category": "TRANSACTION_LIMITS",
        "description": "Minimum deposit amount in SLL",
        "type": "NUMBER"
      },
      "MAX_DEPOSIT_AMOUNT": {
        "value": 10000000,
        "category": "TRANSACTION_LIMITS",
        "description": "Maximum deposit amount in SLL",
        "type": "NUMBER"
      },
      "WITHDRAWAL_FEE_PERCENT": {
        "value": 2,
        "category": "FEES",
        "description": "Withdrawal fee percentage",
        "type": "NUMBER"
      },
      "OTP_EXPIRY_MINUTES": {
        "value": 5,
        "category": "SECURITY",
        "description": "OTP expiration time in minutes",
        "type": "NUMBER"
      }
    }
  }
}
```

---

### 8. Update System Configuration

Update system configuration settings.

**Endpoint:** `PUT /admin/config`

**Authentication:** Required (ADMIN or SUPER_ADMIN)

**Request Body:**
```json
{
  "config": {
    "MIN_DEPOSIT_AMOUNT": 2000,
    "WITHDRAWAL_FEE_PERCENT": 2.5,
    "OTP_EXPIRY_MINUTES": 10
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": null,
  "message": "System configuration updated successfully"
}
```

**Notes:**
- Only provide the keys you want to update
- Values will be converted to string and stored
- Admin action is logged in audit log
- Changes take effect immediately

---

### 9. Generate Report

Generate reports in various formats (JSON, CSV, PDF).

**Endpoint:** `GET /admin/reports`

**Authentication:** Required (ADMIN or SUPER_ADMIN)

**Query Parameters:**
- `type` (required): Report type (transactions, investments, users)
- `format` (optional, default: json): Output format (json, csv, pdf)
- `from` (optional): Start date (ISO 8601 format)
- `to` (optional): End date (ISO 8601 format)

**Example Request:**
```
GET /admin/reports?type=transactions&format=json&from=2024-01-01T00:00:00Z&to=2024-01-31T23:59:59Z
```

**Response:**
```json
{
  "success": true,
  "data": {
    "type": "transactions",
    "format": "json",
    "dateRange": {
      "from": "2024-01-01T00:00:00.000Z",
      "to": "2024-01-31T23:59:59.000Z"
    },
    "generatedAt": "2024-01-20T15:30:00.000Z",
    "count": 250,
    "data": [
      {
        "id": "uuid",
        "transaction_id": "TXN20240115123456",
        "type": "DEPOSIT",
        "amount": 50000.00,
        "fee": 0.00,
        "net_amount": 50000.00,
        "status": "COMPLETED",
        "created_at": "2024-01-15T10:30:00Z",
        "from_email": null,
        "to_email": "john@example.com"
      }
    ]
  }
}
```

**Error Responses:**
- `400 Bad Request`: Invalid report type or format
- `400 Bad Request`: CSV and PDF formats not yet supported

**Notes:**
- CSV and PDF formats are TODO (currently returns error)
- Reports can be large, consider using pagination for production
- Date range is optional, omitting it returns all records

---

### 10. Get Analytics KPI

Get comprehensive analytics and KPIs with optional date range.

**Endpoint:** `GET /admin/analytics`

**Authentication:** Required (ADMIN or SUPER_ADMIN)

**Query Parameters:**
- `from` (optional): Start date (ISO 8601 format)
- `to` (optional): End date (ISO 8601 format)

**Example Request:**
```
GET /admin/analytics?from=2024-01-01T00:00:00Z&to=2024-01-31T23:59:59Z
```

**Response:**
```json
{
  "success": true,
  "data": {
    "dateRange": {
      "from": "2024-01-01T00:00:00.000Z",
      "to": "2024-01-31T23:59:59.000Z"
    },
    "transactions": {
      "total_count": 5000,
      "completed_count": 4850,
      "failed_count": 150,
      "total_volume": 250000000.00,
      "total_fees": 5000000.00,
      "avg_transaction_amount": 51546.39
    },
    "users": {
      "total_users": 1500,
      "active_users": 1200,
      "kyc_approved_users": 800,
      "new_users_today": 15
    },
    "investments": {
      "total_investments": 350,
      "active_investments": 280,
      "total_invested": 150000000.00,
      "expected_returns": 165000000.00
    },
    "agents": {
      "total_agents": 50,
      "active_agents": 45,
      "total_commissions": 3500000.00
    },
    "generatedAt": "2024-01-20T15:30:00.000Z"
  }
}
```

---

## Error Responses

All endpoints follow a consistent error response format:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": {},
    "timestamp": "2024-01-20T15:30:00.000Z"
  }
}
```

### Common Error Codes

- `BAD_REQUEST` (400): Invalid request parameters
- `UNAUTHORIZED` (401): Missing or invalid authentication token
- `FORBIDDEN` (403): Insufficient permissions
- `NOT_FOUND` (404): Resource not found
- `CONFLICT` (409): Resource conflict
- `VALIDATION_ERROR` (422): Request validation failed
- `RATE_LIMIT_EXCEEDED` (429): Too many requests
- `INTERNAL_ERROR` (500): Internal server error

---

## Security Features

### Two-Factor Authentication (TOTP)

Admins can enable 2FA using TOTP (Time-based One-Time Password). When enabled:

1. Login with email and password
2. Server responds with `requires_totp: true`
3. Submit TOTP code from authenticator app
4. Server verifies and issues tokens

### Account Lockout

After 5 failed login attempts, the admin account is locked for 30 minutes.

### Audit Logging

All admin actions are logged in the `admin_audit_logs` table with:
- Admin ID
- Action performed
- Entity type and ID
- Changes made (before/after)
- IP address and user agent
- Timestamp

### Rate Limiting

Admin endpoints are rate limited to prevent abuse:
- General limit: 100 requests per 15 minutes per IP
- Login limit: 5 attempts per 15 minutes per IP

---

## TODO Items

The following features are planned but not yet implemented:

1. **CSV Report Export**: Generate reports in CSV format
2. **PDF Report Export**: Generate reports in PDF format with charts
3. **Advanced Filtering**: More granular filters for user and transaction queries
4. **Bulk Operations**: Approve/reject multiple requests at once
5. **Email Notifications**: Send email notifications for admin actions
6. **Activity Dashboard**: Real-time activity feed for admins
7. **User Impersonation**: View application as a specific user (for support)
8. **KYC Review Endpoints**: Dedicated endpoints for reviewing KYC submissions
9. **System Health Monitoring**: Database, cache, and service health checks
10. **Scheduled Reports**: Configure automatic report generation and delivery

---

## Testing

You can test the admin endpoints using tools like Postman or cURL.

### Example cURL Request

```bash
# Login
curl -X POST https://api.tccapp.com/v1/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@tccapp.com",
    "password": "SecurePassword123!",
    "totp_code": "123456"
  }'

# Get Dashboard Stats
curl -X GET https://api.tccapp.com/v1/admin/dashboard/stats \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Review Withdrawal
curl -X POST https://api.tccapp.com/v1/admin/withdrawals/review \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "withdrawal_id": "550e8400-e29b-41d4-a716-446655440000",
    "status": "COMPLETED"
  }'
```

---

## Support

For questions or issues with the Admin API, contact the development team or refer to the main API documentation.
