# TCC Admin Services Implementation Summary

## Overview

This document summarizes the implementation of admin services for the TCC backend application. The admin services provide comprehensive management capabilities for the platform including user management, withdrawal approval, agent credit approval, system configuration, analytics, and reporting.

## Files Created

### 1. Service Layer
**File:** `/src/services/admin.service.ts`

Implements the core business logic for admin operations:

- **login(email, password, totpCode)**: Admin authentication with 2FA/TOTP support
  - Password verification
  - Account lockout after 5 failed attempts (30 minutes)
  - TOTP verification using speakeasy library
  - JWT token generation
  - Refresh token storage

- **getDashboardStats()**: Real-time KPI calculation
  - Total users, transactions, revenue
  - Active agents count
  - Pending withdrawals and KYC submissions
  - Today's revenue and transaction count

- **getUsers(filters, pagination)**: User management with advanced filtering
  - Search by name, email, phone
  - Filter by role, KYC status, active status
  - Pagination support

- **getWithdrawals(status, pagination)**: Withdrawal request management
  - Filter by status
  - Join with user and bank account data
  - Pagination support

- **reviewWithdrawal(adminId, withdrawalId, status, reason)**: Approve/reject withdrawals
  - Transaction creation for approved withdrawals
  - Wallet refund for rejected withdrawals
  - User notifications
  - Audit logging

- **reviewAgentCredit(adminId, requestId, status, reason)**: Agent credit approval workflow
  - Agent wallet credit for approved requests
  - Transaction record creation
  - Audit logging

- **getSystemConfig()**: Retrieve all system configuration
  - Dynamic type parsing (NUMBER, BOOLEAN, JSON, STRING)
  - Organized by category

- **updateSystemConfig(adminId, config)**: Update configuration settings
  - Batch updates
  - Audit logging

- **generateReport(type, format, dateRange)**: Report generation
  - Types: transactions, investments, users
  - JSON format (CSV/PDF marked as TODO)
  - Optional date range filtering

- **getAnalyticsKPI(dateRange)**: Comprehensive analytics
  - Transaction analytics (volume, fees, counts)
  - User analytics (total, active, KYC approved)
  - Investment analytics (active, total invested, returns)
  - Agent analytics (total agents, commissions)

### 2. Controller Layer
**File:** `/src/controllers/admin.controller.ts`

Handles HTTP request/response for admin endpoints:

- Input validation
- Error handling with appropriate HTTP status codes
- Response formatting using ApiResponseUtil
- Pagination metadata generation
- Request logging

Implemented controllers:
- `login()`: Admin authentication
- `getDashboardStats()`: Dashboard KPIs
- `getUsers()`: User listing with filters
- `getWithdrawals()`: Withdrawal requests
- `reviewWithdrawal()`: Withdrawal approval/rejection
- `reviewAgentCredit()`: Agent credit review
- `getSystemConfig()`: Get configuration
- `updateSystemConfig()`: Update configuration
- `generateReport()`: Report generation
- `getAnalyticsKPI()`: Analytics data

### 3. Routes Layer
**File:** `/src/routes/admin.routes.ts`

Defines API endpoints with validation and authorization:

**Public Routes:**
- `POST /admin/login`: Admin login (no auth required)

**Protected Routes** (ADMIN or SUPER_ADMIN role required):
- `GET /admin/dashboard/stats`: Dashboard statistics
- `GET /admin/analytics`: Analytics KPIs
- `GET /admin/users`: User management
- `GET /admin/withdrawals`: Withdrawal requests
- `POST /admin/withdrawals/review`: Review withdrawal
- `POST /admin/agent-credits/review`: Review agent credit
- `GET /admin/config`: Get system config
- `PUT /admin/config`: Update system config
- `GET /admin/reports`: Generate reports

**Validation Schemas** (using Zod):
- Login schema with email, password, optional TOTP
- Review schemas with UUIDs and status enums
- Query parameter schemas for filtering and pagination
- Configuration update schema

### 4. Application Integration
**File:** `/src/app.ts` (updated)

Added admin routes registration:
```typescript
import('./routes/admin.routes').then(module => {
  this.app.use(`${apiPrefix}/admin`, module.default);
  logger.info('Admin routes registered');
});
```

### 5. Dependencies
**File:** `/package.json` (updated)

Added packages:
- `speakeasy: ^2.0.0`: TOTP implementation for 2FA
- `@types/speakeasy: ^2.0.10`: TypeScript definitions

### 6. Documentation
**File:** `/ADMIN_API_DOCUMENTATION.md`

Comprehensive API documentation including:
- Endpoint descriptions
- Request/response examples
- Error codes and handling
- Authentication flow
- Security features
- Testing examples
- TODO items

## Features Implemented

### 1. Authentication & Security

**Two-Factor Authentication (2FA)**
- TOTP-based using speakeasy library
- Compatible with Google Authenticator, Authy, etc.
- 60-second time window with 2-step tolerance
- Stored in `users.two_factor_secret` field

**Account Security**
- Failed login attempt tracking
- Automatic lockout after 5 failed attempts
- 30-minute lockout duration
- Active/inactive status checks

**Authorization**
- Role-based access control (RBAC)
- Middleware enforcement using `authorize(UserRole.ADMIN, UserRole.SUPER_ADMIN)`
- JWT token validation on all protected routes

### 2. Dashboard & Analytics

**Real-Time Statistics**
- Total users, transactions, revenue
- Active agents count
- Pending items (withdrawals, KYC)
- Today's metrics

**Comprehensive Analytics**
- Transaction analytics (volume, fees, averages)
- User metrics (total, active, verified)
- Investment tracking (active, returns)
- Agent performance (commissions)
- Date range filtering

### 3. User Management

**Advanced Filtering**
- Search across name, email, phone
- Filter by role (USER, AGENT, ADMIN, SUPER_ADMIN)
- Filter by KYC status
- Filter by active status

**Pagination**
- Configurable page size
- Total count and page calculation
- Offset-based pagination

### 4. Withdrawal Management

**Review Workflow**
- Approve or reject requests
- Required rejection reason
- Automatic wallet updates
- Transaction creation
- User notifications

**Listing & Filtering**
- Filter by status
- Join with user and bank data
- Pagination support

### 5. Agent Credit Management

**Approval Process**
- Review credit requests with receipt verification
- Approve or reject with reason
- Agent wallet credit on approval
- Transaction record creation
- Audit logging

### 6. System Configuration

**Configuration Management**
- Get all settings organized by category
- Dynamic type parsing (NUMBER, BOOLEAN, JSON, STRING)
- Batch updates
- Audit trail for changes

**Configuration Categories**
- TRANSACTION_LIMITS: Min/max amounts, daily limits
- FEES: Percentage-based fees
- SECURITY: OTP settings, login attempts, timeouts

### 7. Reporting

**Report Types**
- Transactions report with user details
- Investments report with returns
- Users report with wallet balances

**Features**
- JSON format (CSV/PDF marked as TODO)
- Date range filtering
- Record count and metadata
- Generation timestamp

### 8. Audit Logging

**Comprehensive Tracking**
- All admin actions logged in `admin_audit_logs`
- Withdrawal reviews
- Agent credit reviews
- Configuration changes
- Before/after change tracking

**Logged Information**
- Admin ID
- Action type
- Entity type and ID
- Changes (JSON format)
- IP address (prepared for future use)
- Timestamp

## Database Integration

### Tables Used

1. **users**: Admin authentication and profile
2. **withdrawal_requests**: Withdrawal management
3. **agent_credit_requests**: Agent credit approval
4. **transactions**: Financial transaction records
5. **wallets**: User and agent balances
6. **agents**: Agent information
7. **investments**: Investment tracking
8. **system_config**: Platform configuration
9. **admin_audit_logs**: Admin action tracking
10. **notifications**: User notifications
11. **refresh_tokens**: Session management

### Transaction Safety

All critical operations use database transactions:
- Withdrawal approval/rejection (wallet updates + transaction creation)
- Agent credit approval (wallet credit + transaction creation)
- Configuration updates (batch updates + audit logging)

## Security Considerations

### 1. Authentication
- Secure password hashing with bcrypt
- JWT tokens with expiration
- Refresh token rotation
- TOTP-based 2FA

### 2. Authorization
- Role-based access control
- Middleware enforcement
- Route-level protection

### 3. Audit Trail
- Complete action logging
- Change tracking
- Admin accountability

### 4. Input Validation
- Zod schema validation
- Type safety
- SQL injection prevention (parameterized queries)

### 5. Rate Limiting
- General rate limiter applied to all routes
- Protection against brute force attacks

## API Design Patterns

### 1. Consistent Response Format
```typescript
{
  success: boolean,
  data?: any,
  message?: string,
  error?: {
    code: string,
    message: string,
    details?: any
  },
  meta?: {
    pagination?: {...}
  }
}
```

### 2. Error Handling
- Try-catch blocks in all methods
- Specific error messages
- Appropriate HTTP status codes
- Logged errors with context

### 3. Pagination
- Standard parameters (page, limit)
- Offset calculation
- Total count and pages
- Metadata in response

### 4. Filtering
- Optional query parameters
- Dynamic SQL WHERE clause building
- Parameterized queries for security

## TODO Items

The following features are marked for future implementation:

### 1. Report Generation
- **CSV Export**: Implement CSV formatting and download
- **PDF Export**: Add PDF generation with charts and styling
- Consider using libraries like `csv-writer` and `pdfkit`

### 2. Enhanced Features
- **Bulk Operations**: Approve/reject multiple items at once
- **Email Notifications**: Send emails on admin actions
- **KYC Review Endpoints**: Dedicated KYC approval workflow
- **User Impersonation**: Support functionality for debugging
- **Activity Feed**: Real-time admin activity dashboard

### 3. Performance Optimizations
- **Caching**: Add Redis caching for dashboard stats
- **Database Indexing**: Review and optimize query performance
- **Materialized Views**: Use for complex analytics queries

### 4. Advanced Analytics
- **Charts/Graphs**: Generate visual analytics data
- **Trend Analysis**: Historical comparison and trends
- **Export Scheduling**: Automated report generation

## Testing

### Manual Testing
Use the provided cURL examples in the documentation to test endpoints.

### Recommended Tests
1. Admin login with/without 2FA
2. Dashboard stats retrieval
3. User listing with various filters
4. Withdrawal approval workflow
5. Agent credit approval
6. Configuration updates
7. Report generation
8. Analytics retrieval

### Test Accounts
Create test admin accounts:
```sql
-- Example (password should be hashed)
INSERT INTO users (role, first_name, last_name, email, phone, country_code, password_hash, is_active, is_verified, email_verified, phone_verified, kyc_status)
VALUES ('ADMIN', 'Test', 'Admin', 'testadmin@tccapp.com', '2331234567', '+232', '$2b$10$...', true, true, true, true, 'APPROVED');
```

## Installation & Setup

### 1. Install Dependencies
```bash
cd tcc_backend
npm install
```

This will install `speakeasy` and `@types/speakeasy` along with other dependencies.

### 2. Database Setup
Ensure the database schema is up to date with all required tables, especially:
- `users` with `two_factor_enabled` and `two_factor_secret` columns
- `admin_audit_logs` table
- `system_config` table

### 3. Environment Configuration
No additional environment variables needed. Uses existing JWT secret and database configuration.

### 4. Start Server
```bash
npm run dev
```

### 5. Verify Routes
Check server logs for:
```
Admin routes registered
```

## Usage Examples

### 1. Admin Login with 2FA

```bash
# Step 1: Login with password
curl -X POST http://localhost:3000/v1/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@tccapp.com",
    "password": "SecurePass123!"
  }'

# Response: {"success": true, "data": {"requires_totp": true}}

# Step 2: Login with TOTP code
curl -X POST http://localhost:3000/v1/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@tccapp.com",
    "password": "SecurePass123!",
    "totp_code": "123456"
  }'
```

### 2. Get Dashboard Stats

```bash
curl -X GET http://localhost:3000/v1/admin/dashboard/stats \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 3. Review Withdrawal

```bash
curl -X POST http://localhost:3000/v1/admin/withdrawals/review \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "withdrawal_id": "uuid-here",
    "status": "COMPLETED"
  }'
```

## Integration with Frontend

The admin web app should:

1. **Login Flow**
   - Collect email/password
   - If 2FA enabled, show TOTP input
   - Store access and refresh tokens
   - Redirect to dashboard

2. **Dashboard**
   - Fetch stats on load
   - Display KPIs in cards/widgets
   - Real-time updates (consider WebSocket)

3. **User Management**
   - Searchable, filterable table
   - Pagination controls
   - User detail modal

4. **Withdrawal Review**
   - List pending withdrawals
   - Review modal with approve/reject
   - Reason input for rejection
   - Refresh on action

5. **Reports**
   - Form with type, format, date range
   - Download or display inline
   - Export to CSV/PDF (when implemented)

## Performance Considerations

### Current Implementation
- Direct database queries
- No caching layer
- Synchronous operations

### Recommendations
1. **Add Redis Caching**
   - Cache dashboard stats (5-minute TTL)
   - Cache system config (until update)
   - Cache user counts and aggregates

2. **Database Optimization**
   - Add indexes on frequently queried fields
   - Use materialized views for complex analytics
   - Consider read replicas for reporting

3. **Async Processing**
   - Queue large report generation
   - Background job for scheduled reports
   - Email delivery queue

4. **API Optimization**
   - Implement field selection (sparse fieldsets)
   - Add ETag/conditional requests
   - Gzip compression (already enabled)

## Monitoring & Logging

### Current Logging
- Winston logger for all operations
- Error logging with context
- Request/response logging

### Recommended Additions
1. **Metrics**
   - Admin login frequency
   - Withdrawal approval time
   - Report generation time
   - API response times

2. **Alerts**
   - Failed login attempts spike
   - Unusual admin activity
   - System configuration changes
   - High error rates

3. **Audit Reports**
   - Daily admin activity summary
   - Weekly security review
   - Monthly audit export

## Conclusion

The admin services implementation provides a comprehensive management interface for the TCC platform with:

- Secure authentication with 2FA
- Real-time dashboard analytics
- User and transaction management
- Approval workflows
- System configuration
- Audit logging
- Extensible reporting

All endpoints are protected with role-based authorization, input validation, and comprehensive error handling. The implementation follows established patterns from the existing codebase and integrates seamlessly with the database schema.

For production deployment, consider implementing the TODO items, adding caching, and setting up monitoring/alerting systems.
