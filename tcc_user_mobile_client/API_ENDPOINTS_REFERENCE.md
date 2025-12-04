# TCC User Mobile Client - API Endpoints Quick Reference

## Base URL
```
http://localhost:3000/v1
```

## Authentication Endpoints

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| POST | `/auth/register` | No | Register new user |
| POST | `/auth/verify-otp` | No | Verify OTP after registration |
| POST | `/auth/login` | No | Login user |
| POST | `/auth/resend-otp` | No | Resend OTP |
| POST | `/auth/forgot-password` | No | Request password reset OTP |
| POST | `/auth/reset-password` | No | Reset password with OTP |
| POST | `/auth/refresh` | No | Refresh access token |
| POST | `/auth/logout` | Yes | Logout user |

## User Profile Endpoints

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| GET | `/users/profile` | Yes | Get user profile |
| PATCH | `/users/profile` | Yes | Update user profile |
| POST | `/users/change-password` | Yes | Change password |

## Wallet Endpoints

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| GET | `/wallet/balance` | Yes | Get wallet balance |
| POST | `/wallet/deposit` | Yes | Deposit money |
| POST | `/wallet/withdraw/request-otp` | Yes | Request OTP for withdrawal |
| POST | `/wallet/withdraw` | Yes | Withdraw money with OTP |
| POST | `/wallet/transfer/request-otp` | Yes | Request OTP for transfer |
| POST | `/wallet/transfer` | Yes | Transfer money with OTP |

## Transaction Endpoints

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| GET | `/transactions/history` | Yes | Get transaction history |
| GET | `/transactions/:id` | Yes | Get transaction details |
| GET | `/transactions/stats` | Yes | Get transaction statistics |
| GET | `/transactions/:id/receipt` | Yes | Download transaction receipt |

## Investment Endpoints

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| GET | `/investments/categories` | Yes | Get investment categories |
| POST | `/investments` | Yes | Create new investment |
| GET | `/investments/portfolio` | Yes | Get investment portfolio |
| GET | `/investments/:id` | Yes | Get investment details |
| POST | `/investments/:id/request-tenure-change` | Yes | Request tenure change |
| GET | `/investments/:id/withdrawal-penalty` | Yes | Get withdrawal penalty |
| POST | `/investments/:id/withdraw` | Yes | Withdraw investment |
| GET | `/investments/calculate-returns` | Yes | Calculate expected returns |

## Bill Payment Endpoints

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| GET | `/bills/providers` | Yes | Get bill providers |
| POST | `/bills/fetch-details` | Yes | Fetch bill details |
| POST | `/bills/request-otp` | Yes | Request OTP for payment |
| POST | `/bills/pay` | Yes | Pay bill with OTP |
| GET | `/bills/history` | Yes | Get bill payment history |

## Agent Endpoints

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| GET | `/agent/nearby` | Yes | Get nearby agents |
| GET | `/agent/:id` | Yes | Get agent details |
| POST | `/agent/review` | Yes | Submit agent review |

## KYC Endpoints

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| POST | `/kyc/upload-document` | Yes | Upload KYC document |
| POST | `/kyc/submit` | Yes | Submit KYC application |
| GET | `/kyc/status` | Yes | Get KYC status |
| POST | `/kyc/resubmit` | Yes | Resubmit KYC after rejection |

## Bank Account Endpoints

| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| POST | `/users/bank-accounts` | Yes | Add bank account |
| GET | `/users/bank-accounts` | Yes | Get bank accounts |
| DELETE | `/users/bank-accounts/:id` | Yes | Delete bank account |
| PATCH | `/users/bank-accounts/:id/set-primary` | Yes | Set primary bank account |

## Service to Endpoint Mapping

### AuthService
```dart
register()           → POST /auth/register
verifyOTP()          → POST /auth/verify-otp
login()              → POST /auth/login
resendOTP()          → POST /auth/resend-otp
forgotPassword()     → POST /auth/forgot-password
resetPassword()      → POST /auth/reset-password
refreshToken()       → POST /auth/refresh
logout()             → POST /auth/logout
getProfile()         → GET /users/profile
updateProfile()      → PATCH /users/profile
changePassword()     → POST /users/change-password
```

### WalletService
```dart
getBalance()           → GET /wallet/balance
deposit()              → POST /wallet/deposit
requestWithdrawalOTP() → POST /wallet/withdraw/request-otp
withdraw()             → POST /wallet/withdraw
requestTransferOTP()   → POST /wallet/transfer/request-otp
transfer()             → POST /wallet/transfer
```

### TransactionService
```dart
getTransactionHistory() → GET /transactions/history
getTransactionDetails() → GET /transactions/:id
getTransactionStats()   → GET /transactions/stats
downloadReceipt()       → GET /transactions/:id/receipt
```

### InvestmentService
```dart
getCategories()        → GET /investments/categories
createInvestment()     → POST /investments
getPortfolio()         → GET /investments/portfolio
getInvestmentDetails() → GET /investments/:id
requestTenureChange()  → POST /investments/:id/request-tenure-change
getWithdrawalPenalty() → GET /investments/:id/withdrawal-penalty
withdrawInvestment()   → POST /investments/:id/withdraw
calculateReturns()     → GET /investments/calculate-returns
```

### BillService
```dart
getProviders()       → GET /bills/providers
fetchBillDetails()   → POST /bills/fetch-details
requestPaymentOTP()  → POST /bills/request-otp
payBill()            → POST /bills/pay
getBillHistory()     → GET /bills/history
```

### AgentService
```dart
getNearbyAgents()      → GET /agent/nearby
getAgentDetails()      → GET /agent/:id
submitAgentReview()    → POST /agent/review
```

### KYCService
```dart
submitKYC()     → POST /kyc/upload-document (multiple) + POST /kyc/submit
getKYCStatus()  → GET /kyc/status
resubmitKYC()   → POST /kyc/upload-document (multiple) + POST /kyc/resubmit
```

### BankService
```dart
addBankAccount()        → POST /users/bank-accounts
getBankAccounts()       → GET /users/bank-accounts
deleteBankAccount()     → DELETE /users/bank-accounts/:id
setPrimaryBankAccount() → PATCH /users/bank-accounts/:id/set-primary
```

## Response Format

All endpoints return JSON responses in this format:

### Success Response
```json
{
  "success": true,
  "data": {
    // Response data
  }
}
```

### Error Response
```json
{
  "success": false,
  "error": "Error message",
  "errors": {
    // Validation errors (for 422 responses)
  }
}
```

## HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request |
| 401 | Unauthorized (token expired) |
| 403 | Forbidden |
| 404 | Not Found |
| 422 | Validation Error |
| 500 | Server Error |

## Authentication

All authenticated endpoints require Bearer token in header:
```
Authorization: Bearer <access_token>
```

Tokens are automatically managed by `ApiService` singleton.

## Common Query Parameters

### Pagination
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 20)

### Date Filters
- `startDate` - Start date (format: YYYY-MM-DD)
- `endDate` - End date (format: YYYY-MM-DD)

### Status Filters
- `status` - Filter by status
- `type` - Filter by type

## File Upload Format

For KYC document uploads:
- Content-Type: `multipart/form-data`
- Field name: `document`
- Additional fields as needed

## Timeout Configuration

- Standard API calls: 30 seconds
- File uploads: 60 seconds

## Notes

- All dates should be in ISO 8601 format
- Phone numbers should include country code (e.g., +1234567890)
- Amount values should be in decimal format (e.g., 1000.50)
- All endpoints use JSON request/response format except file uploads
