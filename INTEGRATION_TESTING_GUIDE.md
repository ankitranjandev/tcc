# TCC Platform - Integration Testing Guide

## 🧪 Complete Testing Workflow

This guide walks you through testing the complete TCC platform integration between backend and all client applications.

---

## Prerequisites

### 1. Backend Setup

```bash
# Navigate to backend
cd tcc_backend

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your database credentials and secrets

# Setup database
psql -U postgres -c "CREATE DATABASE tcc_database;"
psql -U postgres -d tcc_database -f ../database_schema.sql
psql -U postgres -d tcc_database -f src/database/migrations/001_add_otp_and_tokens.sql

# Start backend server
npm run dev

# Verify backend is running
curl http://localhost:3000/health
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "timestamp": "2025-...",
    "uptime": 1.234,
    "environment": "development"
  }
}
```

---

## Test Scenarios

### Scenario 1: User Registration & Login (User Mobile Client)

#### Step 1: Register New User

**UI Actions**:
1. Open User Mobile Client
2. Navigate to Registration screen
3. Fill in:
   - First Name: "John"
   - Last Name: "Doe"
   - Email: "john.doe@example.com"
   - Phone: "1234567890"
   - Password: "SecurePass123!"
4. Tap "Register"

**Backend Call**:
```
POST http://localhost:3000/v1/auth/register
Body: {
  "first_name": "John",
  "last_name": "Doe",
  "email": "john.doe@example.com",
  "phone": "1234567890",
  "country_code": "+232",
  "password": "SecurePass123!"
}
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid-here",
      "first_name": "John",
      "last_name": "Doe",
      "email": "john.doe@example.com",
      ...
    },
    "otp_sent": true,
    "otp_expires_in": 300
  }
}
```

**Verify**:
- ✅ User created in database
- ✅ OTP generated and logged (check backend console in dev mode)
- ✅ User redirected to OTP verification screen

---

#### Step 2: Verify OTP

**UI Actions**:
1. Check backend console for OTP (in development mode)
2. Enter OTP in app
3. Tap "Verify"

**Backend Call**:
```
POST http://localhost:3000/v1/auth/verify-otp
Body: {
  "phone": "1234567890",
  "country_code": "+232",
  "otp": "123456",
  "purpose": "REGISTRATION"
}
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "access_token": "jwt_token_here",
    "refresh_token": "refresh_token_here",
    "token_type": "Bearer",
    "expires_in": 3600,
    "user": { ... }
  }
}
```

**Verify**:
- ✅ Tokens stored in local storage
- ✅ User marked as verified in database
- ✅ User redirected to dashboard
- ✅ Dashboard shows user data

---

#### Step 3: Check Profile

**UI Actions**:
1. Navigate to Profile screen
2. View user information

**Backend Call**:
```
GET http://localhost:3000/v1/users/profile
Headers: {
  "Authorization": "Bearer {access_token}"
}
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "first_name": "John",
      "last_name": "Doe",
      "email": "john.doe@example.com",
      ...
    },
    "wallet": {
      "balance": 0.00,
      "currency": "SLL",
      "tcc_coins": 0.00
    }
  }
}
```

**Verify**:
- ✅ Profile data displayed correctly
- ✅ Wallet balance shows 0
- ✅ All user details match registration

---

### Scenario 2: Wallet Deposit (User Mobile Client)

#### Step 1: View Wallet Balance

**UI Actions**:
1. Navigate to Wallet screen
2. View current balance

**Backend Call**:
```
GET http://localhost:3000/v1/wallet/balance
Headers: { "Authorization": "Bearer {token}" }
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "balance": 0.00,
    "currency": "SLL",
    "tcc_coins": 0.00
  }
}
```

---

#### Step 2: Initiate Deposit

**UI Actions**:
1. Tap "Add Money"
2. Enter amount: 10000
3. Select method: "Bank Transfer"
4. Upload receipt (optional)
5. Tap "Confirm"

**Backend Call**:
```
POST http://localhost:3000/v1/wallet/deposit
Headers: { "Authorization": "Bearer {token}" }
Body: {
  "amount": 10000,
  "method": "BANK_TRANSFER",
  "source": "BANK_DEPOSIT",
  "metadata": {
    "receipt_url": "https://..."
  }
}
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "transaction": {
      "transaction_id": "TXN20251119123456",
      "amount": 10000,
      "status": "PENDING",
      ...
    }
  },
  "message": "Deposit request submitted. Awaiting admin approval."
}
```

**Verify**:
- ✅ Transaction created with PENDING status
- ✅ Transaction visible in history
- ✅ Balance not updated yet (awaiting approval)

---

### Scenario 3: Admin Approval Workflow (Admin Web Client)

#### Step 1: Admin Login

**UI Actions**:
1. Open Admin Web Client
2. Enter admin credentials
3. Enter 2FA code (if enabled)
4. Login

**Backend Call**:
```
POST http://localhost:3000/v1/admin/login
Body: {
  "email": "admin@tccapp.com",
  "password": "AdminPass123!",
  "totp_code": "123456"
}
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "access_token": "...",
    "refresh_token": "...",
    "admin": { ... }
  }
}
```

---

#### Step 2: View Dashboard

**UI Actions**:
1. Admin Dashboard loads automatically

**Backend Call**:
```
GET http://localhost:3000/v1/admin/dashboard/stats
Headers: { "Authorization": "Bearer {admin_token}" }
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "total_users": 1,
    "total_transactions": 1,
    "total_revenue": 0,
    "active_agents": 0,
    "pending_withdrawals": 0,
    "pending_kyc": 0,
    "todays_revenue": 0,
    "todays_transactions": 1
  }
}
```

**Verify**:
- ✅ Stats displayed on dashboard
- ✅ Pending items highlighted

---

#### Step 3: Approve Deposit

**UI Actions**:
1. Navigate to "Withdrawals/Deposits" section
2. Click on pending deposit
3. Review details
4. Click "Approve"

**Backend Call**:
```
POST http://localhost:3000/v1/admin/withdrawals/review
Headers: { "Authorization": "Bearer {admin_token}" }
Body: {
  "withdrawal_id": "uuid",
  "status": "APPROVED"
}
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Withdrawal approved successfully"
}
```

**Verify**:
- ✅ Transaction status updated to COMPLETED
- ✅ User's wallet balance increased
- ✅ Transaction appears in user's history

---

### Scenario 4: Money Transfer (User Mobile Client)

#### Step 1: Request Transfer OTP

**UI Actions**:
1. In User Client, tap "Send Money"
2. Enter recipient phone: "0987654321"
3. Enter amount: 5000
4. Add note: "Test transfer"
5. Tap "Continue"

**Backend Call**:
```
POST http://localhost:3000/v1/wallet/transfer/request-otp
Headers: { "Authorization": "Bearer {token}" }
Body: {
  "phone": "0987654321",
  "country_code": "+232",
  "amount": 5000
}
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "otp_sent": true,
    "otp_expires_in": 300
  }
}
```

---

#### Step 2: Complete Transfer

**UI Actions**:
1. Enter OTP received
2. Tap "Confirm Transfer"

**Backend Call**:
```
POST http://localhost:3000/v1/wallet/transfer
Headers: { "Authorization": "Bearer {token}" }
Body: {
  "to_phone": "0987654321",
  "to_country_code": "+232",
  "amount": 5000,
  "otp": "123456",
  "note": "Test transfer"
}
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "transaction": {
      "transaction_id": "TXN20251119123457",
      "amount": 5000,
      "fee": 50,
      "net_amount": 4950,
      "status": "COMPLETED"
    },
    "new_balance": 4950
  },
  "message": "Transfer successful"
}
```

**Verify**:
- ✅ Sender's balance decreased
- ✅ Recipient's balance increased
- ✅ Fee deducted correctly
- ✅ Transaction recorded for both parties

---

### Scenario 5: Agent Operations (Agent Mobile Client)

#### Step 1: Agent Registration

**UI Actions**:
1. Open Agent Client
2. Complete registration form
3. Upload business documents
4. Submit

**Backend Call**:
```
POST http://localhost:3000/v1/agent/register
Headers: { "Authorization": "Bearer {token}" }
Body: {
  "location_lat": 8.4657,
  "location_lng": -13.2317,
  "location_address": "Freetown, Sierra Leone"
}
```

---

#### Step 2: Deposit for User

**UI Actions**:
1. Scan user's QR code or enter phone
2. Enter amount: 2000
3. Select payment method
4. Confirm

**Backend Call**:
```
POST http://localhost:3000/v1/agent/deposit
Headers: { "Authorization": "Bearer {agent_token}" }
Body: {
  "user_phone": "1234567890",
  "country_code": "+232",
  "amount": 2000,
  "method": "CASH"
}
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "transaction": { ... },
    "commission": {
      "amount": 10,
      "rate": 0.5
    },
    "new_agent_balance": 8990,
    "user_new_balance": 7000
  }
}
```

**Verify**:
- ✅ User's wallet credited
- ✅ Agent's wallet debited
- ✅ Commission calculated and added
- ✅ Both parties see transaction

---

### Scenario 6: Investment Creation (User Mobile Client)

#### Step 1: Browse Investment Options

**UI Actions**:
1. Navigate to Investments
2. View categories

**Backend Call**:
```
GET http://localhost:3000/v1/investments/categories
Headers: { "Authorization": "Bearer {token}" }
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "categories": [
      {
        "id": "uuid",
        "name": "AGRICULTURE",
        "display_name": "Agriculture",
        "tenures": [
          {"months": 6, "return_percentage": 5.0},
          {"months": 12, "return_percentage": 12.0},
          {"months": 24, "return_percentage": 28.0}
        ]
      },
      ...
    ]
  }
}
```

---

#### Step 2: Create Investment

**UI Actions**:
1. Select "Agriculture"
2. Choose 12-month tenure
3. Enter amount: 50000
4. Add insurance: Yes
5. Confirm

**Backend Call**:
```
POST http://localhost:3000/v1/investments
Headers: { "Authorization": "Bearer {token}" }
Body: {
  "category_id": "uuid",
  "sub_category": "Farm Development",
  "amount": 50000,
  "tenure_months": 12,
  "has_insurance": true
}
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "investment": {
      "id": "uuid",
      "amount": 50000,
      "expected_return": 6000,
      "maturity_date": "2026-11-19",
      "status": "ACTIVE"
    },
    "new_balance": 0
  }
}
```

**Verify**:
- ✅ Investment created
- ✅ Amount deducted from wallet
- ✅ Insurance added
- ✅ Returns calculated correctly

---

### Scenario 7: Bill Payment (User Mobile Client)

#### Step 1: Select Bill Provider

**UI Actions**:
1. Navigate to Bill Payments
2. Select category: "Electricity"
3. Choose provider: "EDSA"

**Backend Call**:
```
GET http://localhost:3000/v1/bills/providers?category=ELECTRICITY
Headers: { "Authorization": "Bearer {token}" }
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "providers": [
      {
        "id": "uuid",
        "name": "EDSA",
        "category": "ELECTRICITY",
        "logo_url": "...",
        "fields_required": ["meter_number", "customer_name"]
      }
    ]
  }
}
```

---

#### Step 2: Pay Bill

**UI Actions**:
1. Enter meter number
2. Fetch bill details
3. Confirm payment
4. Enter OTP

**Backend Calls**:
```
# Fetch bill
POST http://localhost:3000/v1/bills/fetch-details
Body: {
  "provider_id": "uuid",
  "account_number": "123456789"
}

# Request OTP
POST http://localhost:3000/v1/bills/request-otp
Body: { ... }

# Pay bill
POST http://localhost:3000/v1/bills/pay
Body: {
  "provider_id": "uuid",
  "account_number": "123456789",
  "amount": 15000,
  "otp": "123456",
  "metadata": { ... }
}
```

**Verify**:
- ✅ Bill amount fetched
- ✅ Fee calculated (2%)
- ✅ Payment processed
- ✅ Receipt generated

---

### Scenario 8: KYC Submission (User Mobile Client)

#### Step 1: Submit KYC Documents

**UI Actions**:
1. Navigate to Profile → KYC
2. Select document type: "National ID"
3. Upload front image
4. Upload back image
5. Take selfie
6. Submit

**Backend Call**:
```
POST http://localhost:3000/v1/kyc/submit
Headers: { "Authorization": "Bearer {token}" }
Body: {
  "document_type": "NATIONAL_ID",
  "document_number": "SL12345678",
  "front_image_url": "https://...",
  "back_image_url": "https://...",
  "selfie_url": "https://..."
}
```

**Verify**:
- ✅ KYC status changed to SUBMITTED
- ✅ Documents uploaded successfully
- ✅ Admin can see in review queue

---

#### Step 2: Admin Reviews KYC (Admin Client)

**Backend Call**:
```
GET http://localhost:3000/v1/kyc/admin/submissions
Headers: { "Authorization": "Bearer {admin_token}" }

# Then approve
POST http://localhost:3000/v1/kyc/admin/review/{submission_id}
Body: {
  "status": "APPROVED"
}
```

**Verify**:
- ✅ User's KYC status updated to APPROVED
- ✅ User can now enjoy lower fees
- ✅ Notification sent to user

---

## Database Verification

Throughout testing, you can verify database state:

```sql
-- Check users
SELECT id, first_name, last_name, email, kyc_status, is_active
FROM users;

-- Check wallets
SELECT u.first_name, w.balance
FROM wallets w
JOIN users u ON w.user_id = u.id;

-- Check transactions
SELECT transaction_id, type, amount, status, created_at
FROM transactions
ORDER BY created_at DESC
LIMIT 10;

-- Check investments
SELECT u.first_name, i.amount, i.status, i.expected_return
FROM investments i
JOIN users u ON i.user_id = u.id;

-- Check agents
SELECT u.first_name, a.wallet_balance, a.total_commission_earned
FROM agents a
JOIN users u ON a.user_id = u.id;
```

---

## Common Issues & Solutions

### Issue: "Network Error"
**Solution**: Ensure backend is running on `http://localhost:3000`

### Issue: "Unauthorized"
**Solution**: Check that token is being sent in Authorization header

### Issue: "OTP Invalid"
**Solution**: In development, check backend console for OTP, or use test OTP: 123456

### Issue: "Insufficient Balance"
**Solution**: Approve pending deposit via admin panel first

### Issue: "KYC Not Approved"
**Solution**: Submit KYC and approve via admin panel

---

## Performance Testing

### Load Testing with Apache Bench

```bash
# Test auth endpoint
ab -n 100 -c 10 -p register.json -T application/json \
  http://localhost:3000/v1/auth/register

# Test wallet balance
ab -n 1000 -c 50 -H "Authorization: Bearer {token}" \
  http://localhost:3000/v1/wallet/balance
```

### Expected Performance
- Auth endpoints: < 200ms
- Wallet operations: < 100ms
- Transaction queries: < 150ms
- Admin dashboard: < 300ms

---

## Integration Testing Checklist

### User Flow
- [ ] Registration
- [ ] OTP verification
- [ ] Login
- [ ] Profile view
- [ ] Wallet deposit
- [ ] Money transfer
- [ ] Investment creation
- [ ] Bill payment
- [ ] KYC submission
- [ ] Transaction history

### Agent Flow
- [ ] Agent registration
- [ ] Login
- [ ] Credit request
- [ ] Deposit for user
- [ ] Withdraw for user
- [ ] Commission tracking
- [ ] Location update
- [ ] Nearby agents

### Admin Flow
- [ ] Admin login with 2FA
- [ ] Dashboard view
- [ ] User management
- [ ] Withdrawal approval
- [ ] KYC approval
- [ ] Agent credit approval
- [ ] System configuration
- [ ] Report generation

---

## Success Criteria

✅ All API calls return expected responses
✅ Database updates correctly after each operation
✅ Tokens are managed properly
✅ Errors are handled gracefully
✅ UI updates reflect API responses
✅ All user flows work end-to-end
✅ Admin workflows function correctly
✅ Agent operations process successfully

---

**Testing Complete!** Your TCC platform integration is verified and ready for production! 🎉
