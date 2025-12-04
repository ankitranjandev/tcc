# Admin Services Setup Instructions

## Prerequisites

- Node.js >= 18.0.0
- PostgreSQL database with TCC schema
- npm >= 9.0.0

## Installation Steps

### 1. Install Dependencies

Navigate to the backend directory and install the new dependencies:

```bash
cd tcc_backend
npm install
```

This will install:
- `speakeasy@^2.0.0` - TOTP library for 2FA
- `@types/speakeasy@^2.0.10` - TypeScript definitions

### 2. Verify Installation

Check that the packages are installed:

```bash
npm list speakeasy
npm list @types/speakeasy
```

Expected output:
```
tcc-backend@1.0.0
├── speakeasy@2.0.0
└── @types/speakeasy@2.0.10
```

### 3. Database Verification

Ensure your database has the required tables and columns:

**Required Tables:**
- `users` (with `two_factor_enabled` and `two_factor_secret` columns)
- `withdrawal_requests`
- `agent_credit_requests`
- `system_config`
- `admin_audit_logs`
- `transactions`
- `wallets`
- `agents`
- `investments`
- `notifications`
- `refresh_tokens`

**Verify with SQL:**
```sql
-- Check if required columns exist
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'users'
AND column_name IN ('two_factor_enabled', 'two_factor_secret');

-- Check if admin_audit_logs exists
SELECT EXISTS (
  SELECT FROM information_schema.tables
  WHERE table_name = 'admin_audit_logs'
);
```

### 4. Create Test Admin Account

Create a test admin account to test the login endpoint:

```sql
-- First, generate a password hash using bcrypt (password: Admin@123)
-- You can use an online bcrypt tool or Node.js:
-- const bcrypt = require('bcrypt');
-- const hash = await bcrypt.hash('Admin@123', 10);
-- console.log(hash);

INSERT INTO users (
  role, first_name, last_name, email, phone, country_code,
  password_hash, is_active, is_verified, email_verified,
  phone_verified, kyc_status
) VALUES (
  'ADMIN',
  'Test',
  'Admin',
  'testadmin@tccapp.com',
  '2331234567',
  '+232',
  '$2b$10$YourGeneratedHashHere',  -- Replace with actual hash
  true,
  true,
  true,
  true,
  'APPROVED'
);

-- Optionally, add to admins table if you have specific admin metadata
INSERT INTO admins (user_id, admin_role, is_active)
SELECT id, 'ADMIN', true FROM users WHERE email = 'testadmin@tccapp.com';
```

### 5. Start the Server

Start the development server:

```bash
npm run dev
```

You should see in the logs:
```
Admin routes registered
```

### 6. Test the Health Endpoint

Verify the server is running:

```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "timestamp": "2024-01-20T10:30:00.000Z",
    "uptime": 123.456,
    "environment": "development"
  }
}
```

### 7. Test Admin Login

Test the admin login endpoint:

```bash
curl -X POST http://localhost:3000/v1/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testadmin@tccapp.com",
    "password": "Admin@123"
  }'
```

Expected response (without 2FA):
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 3600,
    "admin": {
      "id": "uuid",
      "first_name": "Test",
      "last_name": "Admin",
      "email": "testadmin@tccapp.com",
      "role": "ADMIN"
    }
  },
  "message": "Login successful"
}
```

### 8. Test Protected Endpoints

Use the access token to test protected endpoints:

```bash
# Get dashboard stats
curl -X GET http://localhost:3000/v1/admin/dashboard/stats \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN_HERE"

# Get users
curl -X GET "http://localhost:3000/v1/admin/users?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN_HERE"

# Get system config
curl -X GET http://localhost:3000/v1/admin/config \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN_HERE"
```

## Enable Two-Factor Authentication (Optional)

To test 2FA functionality:

### 1. Generate TOTP Secret

Use Node.js to generate a secret:

```javascript
const speakeasy = require('speakeasy');

const secret = speakeasy.generateSecret({
  name: 'TCC Admin (testadmin@tccapp.com)',
  length: 32
});

console.log('Secret:', secret.base32);
console.log('QR Code URL:', secret.otpauth_url);
```

### 2. Update Admin Account

```sql
UPDATE users
SET two_factor_enabled = true,
    two_factor_secret = 'YOUR_GENERATED_SECRET_HERE'
WHERE email = 'testadmin@tccapp.com';
```

### 3. Add to Authenticator App

1. Install Google Authenticator or Authy on your phone
2. Scan the QR code from the `otpauth_url`
3. Or manually enter the `base32` secret

### 4. Test 2FA Login

```bash
# Step 1: Login with password
curl -X POST http://localhost:3000/v1/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testadmin@tccapp.com",
    "password": "Admin@123"
  }'

# Response: {"success": true, "data": {"requires_totp": true}}

# Step 2: Get TOTP code from authenticator app (e.g., 123456)

# Step 3: Login with TOTP
curl -X POST http://localhost:3000/v1/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testadmin@tccapp.com",
    "password": "Admin@123",
    "totp_code": "123456"
  }'
```

## Troubleshooting

### Issue: TypeScript Compilation Errors

**Solution:** Ensure TypeScript is installed:
```bash
npm install --save-dev typescript
```

### Issue: Module 'speakeasy' not found

**Solution:** Install the package:
```bash
npm install speakeasy
npm install --save-dev @types/speakeasy
```

### Issue: Database connection errors

**Solution:** Check your `.env` file and database configuration:
```bash
# Verify database is running
psql -h localhost -U your_user -d tcc_db -c "SELECT 1"

# Check environment variables
cat .env | grep DB_
```

### Issue: Routes not registered

**Solution:** Check server logs for any import errors. Ensure all files are in the correct location:
- `/src/services/admin.service.ts`
- `/src/controllers/admin.controller.ts`
- `/src/routes/admin.routes.ts`

### Issue: 401 Unauthorized on protected routes

**Solution:** Ensure you're sending the Authorization header:
```bash
curl -X GET http://localhost:3000/v1/admin/dashboard/stats \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json"
```

### Issue: Cannot find module 'speakeasy'

**Solution:** TypeScript may not recognize the module. Try:
```bash
rm -rf node_modules package-lock.json
npm install
```

## Verification Checklist

- [ ] Dependencies installed (`speakeasy` and `@types/speakeasy`)
- [ ] Database tables verified
- [ ] Test admin account created
- [ ] Server starts without errors
- [ ] Admin routes registered (check logs)
- [ ] Health endpoint responds
- [ ] Admin login works
- [ ] Protected endpoints require authentication
- [ ] Dashboard stats returns data
- [ ] User listing works with pagination
- [ ] System config can be retrieved

## Next Steps

1. **Test All Endpoints**: Use the examples in `ADMIN_API_DOCUMENTATION.md`
2. **Create More Admin Accounts**: Add SUPER_ADMIN accounts for testing
3. **Test Withdrawal Workflow**: Create test withdrawal requests and approve/reject
4. **Test Agent Credits**: Create agent credit requests and review
5. **Configure System Settings**: Update system config values
6. **Generate Reports**: Test report generation with different parameters
7. **Review Audit Logs**: Check `admin_audit_logs` table after actions

## Production Deployment

Before deploying to production:

1. **Change Default Passwords**: Update all test/default admin passwords
2. **Enable 2FA**: Require 2FA for all admin accounts
3. **Configure Rate Limiting**: Adjust rate limits for your traffic
4. **Set Up Monitoring**: Add logging and alerting for admin actions
5. **Backup Strategy**: Ensure audit logs are backed up
6. **SSL/TLS**: Use HTTPS for all admin endpoints
7. **IP Whitelisting**: Consider restricting admin access by IP
8. **Review Permissions**: Ensure RBAC is properly configured

## Support

For issues or questions:
- Check `ADMIN_API_DOCUMENTATION.md` for endpoint details
- Review `ADMIN_IMPLEMENTATION_SUMMARY.md` for architecture
- See `ADMIN_QUICK_REFERENCE.md` for quick examples

## Files Overview

```
tcc_backend/
├── src/
│   ├── services/
│   │   └── admin.service.ts          # Business logic
│   ├── controllers/
│   │   └── admin.controller.ts       # Request handlers
│   ├── routes/
│   │   └── admin.routes.ts           # Route definitions
│   └── app.ts                        # Updated with admin routes
├── package.json                      # Updated with speakeasy
├── ADMIN_API_DOCUMENTATION.md        # Detailed API docs
├── ADMIN_IMPLEMENTATION_SUMMARY.md   # Implementation details
├── ADMIN_QUICK_REFERENCE.md          # Quick reference guide
└── ADMIN_SETUP_INSTRUCTIONS.md       # This file
```

---

**Ready to go!** Follow these instructions to get the admin services up and running.
