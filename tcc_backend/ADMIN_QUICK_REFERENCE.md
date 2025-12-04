# Admin API Quick Reference

Quick reference guide for TCC Admin API endpoints.

## Base URL
```
/v1/admin
```

## Authentication
```http
Authorization: Bearer <access_token>
```

---

## Endpoints Summary

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| POST | `/login` | No | Admin login with 2FA |
| GET | `/dashboard/stats` | Yes | Dashboard KPIs |
| GET | `/users` | Yes | List users with filters |
| GET | `/withdrawals` | Yes | List withdrawal requests |
| POST | `/withdrawals/review` | Yes | Approve/reject withdrawal |
| POST | `/agent-credits/review` | Yes | Approve/reject agent credit |
| GET | `/config` | Yes | Get system configuration |
| PUT | `/config` | Yes | Update system configuration |
| GET | `/reports` | Yes | Generate reports |
| GET | `/analytics` | Yes | Get analytics KPIs |

---

## Quick Examples

### Login
```bash
curl -X POST /v1/admin/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@tccapp.com","password":"pass","totp_code":"123456"}'
```

### Get Dashboard
```bash
curl -X GET /v1/admin/dashboard/stats \
  -H "Authorization: Bearer TOKEN"
```

### List Users
```bash
curl -X GET "/v1/admin/users?search=john&page=1&limit=20" \
  -H "Authorization: Bearer TOKEN"
```

### Review Withdrawal
```bash
curl -X POST /v1/admin/withdrawals/review \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"withdrawal_id":"uuid","status":"COMPLETED"}'
```

### Get Analytics
```bash
curl -X GET "/v1/admin/analytics?from=2024-01-01&to=2024-01-31" \
  -H "Authorization: Bearer TOKEN"
```

---

## Query Parameters

### Users Endpoint
- `search`: Search by name, email, phone
- `role`: USER | AGENT | ADMIN | SUPER_ADMIN
- `kyc_status`: PENDING | SUBMITTED | APPROVED | REJECTED
- `is_active`: true | false
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20)

### Withdrawals Endpoint
- `status`: PENDING | PROCESSING | COMPLETED | FAILED | CANCELLED
- `page`: Page number
- `limit`: Items per page

### Reports Endpoint
- `type`: transactions | investments | users (required)
- `format`: json | csv | pdf (default: json)
- `from`: ISO date string
- `to`: ISO date string

### Analytics Endpoint
- `from`: ISO date string
- `to`: ISO date string

---

## Request Bodies

### Login
```json
{
  "email": "admin@tccapp.com",
  "password": "SecurePass123!",
  "totp_code": "123456"  // Optional
}
```

### Review Withdrawal
```json
{
  "withdrawal_id": "uuid",
  "status": "COMPLETED",  // or "REJECTED"
  "reason": "Optional rejection reason"
}
```

### Review Agent Credit
```json
{
  "request_id": "uuid",
  "status": "COMPLETED",  // or "REJECTED"
  "reason": "Optional rejection reason"
}
```

### Update Config
```json
{
  "config": {
    "MIN_DEPOSIT_AMOUNT": 2000,
    "WITHDRAWAL_FEE_PERCENT": 2.5
  }
}
```

---

## Response Format

### Success
```json
{
  "success": true,
  "data": { ... },
  "message": "Optional message",
  "meta": {
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 100,
      "totalPages": 5
    }
  }
}
```

### Error
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Error description",
    "details": {},
    "timestamp": "2024-01-20T15:30:00.000Z"
  }
}
```

---

## Common Error Codes

| Code | Status | Description |
|------|--------|-------------|
| BAD_REQUEST | 400 | Invalid request |
| UNAUTHORIZED | 401 | Not authenticated |
| FORBIDDEN | 403 | No permission |
| NOT_FOUND | 404 | Resource not found |
| CONFLICT | 409 | Resource conflict |
| VALIDATION_ERROR | 422 | Validation failed |
| RATE_LIMIT_EXCEEDED | 429 | Too many requests |
| INTERNAL_ERROR | 500 | Server error |

---

## File Structure

```
tcc_backend/src/
├── services/
│   └── admin.service.ts       # Business logic
├── controllers/
│   └── admin.controller.ts    # Request handlers
└── routes/
    └── admin.routes.ts        # Route definitions
```

---

## Key Functions

### AdminService

```typescript
// Authentication
login(email, password, totpCode?)

// Dashboard
getDashboardStats()
getAnalyticsKPI(dateRange?)

// User Management
getUsers(filters, pagination)

// Withdrawal Management
getWithdrawals(status?, pagination?)
reviewWithdrawal(adminId, withdrawalId, status, reason?)

// Agent Management
reviewAgentCredit(adminId, requestId, status, reason?)

// Configuration
getSystemConfig()
updateSystemConfig(adminId, config)

// Reporting
generateReport(type, format, dateRange?)
```

---

## Database Tables

| Table | Purpose |
|-------|---------|
| users | Admin accounts |
| withdrawal_requests | Pending withdrawals |
| agent_credit_requests | Agent credit requests |
| system_config | Platform settings |
| admin_audit_logs | Action tracking |
| transactions | Financial records |
| wallets | User balances |

---

## Environment Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Ensure database has required tables

3. Start server:
   ```bash
   npm run dev
   ```

4. Test endpoint:
   ```bash
   curl http://localhost:3000/health
   ```

---

## Security Notes

- All endpoints (except login) require ADMIN or SUPER_ADMIN role
- 2FA using TOTP (Google Authenticator compatible)
- Account lockout after 5 failed login attempts (30 min)
- All admin actions logged in audit trail
- Rate limiting applied to prevent abuse

---

## TODO

- CSV/PDF report export
- Bulk operations
- KYC review endpoints
- Email notifications
- Advanced analytics charts

---

For detailed documentation, see `ADMIN_API_DOCUMENTATION.md`

For implementation details, see `ADMIN_IMPLEMENTATION_SUMMARY.md`
