# Bill Payment Service Implementation

## Overview
Complete implementation of bill payment services for the TCC backend, following existing patterns for transactions, validation, and error handling.

## Files Created

### 1. Service Layer
**File:** `/src/services/bill.service.ts`

**Methods:**
- `getProviders(category?)` - Get bill providers by category (WATER, ELECTRICITY, DSTV, INTERNET, MOBILE)
- `fetchBillDetails(providerId, accountNumber)` - Fetch bill details before payment (mock implementation)
- `payBill(userId, providerId, accountNumber, amount, otp, metadata)` - Pay bill with OTP verification
- `getBillHistory(userId, filters, pagination)` - Get bill payment history with filters
- `requestBillPaymentOTP(userId)` - Request OTP for bill payment

**Features:**
- 1% fee for bill payments (minimum 20 SLL)
- Deducts from wallet balance
- Creates transaction with type `BILL_PAYMENT`
- Stores record in `bill_payments` table
- Returns receipt with reference number
- Mock provider integration with TODO comments for real API integration

### 2. Controller Layer
**File:** `/src/controllers/bill.controller.ts`

**Endpoints:**
- `getProviders` - Get list of bill providers
- `fetchBillDetails` - Fetch bill details for validation
- `requestPaymentOTP` - Request OTP for payment
- `payBill` - Execute bill payment
- `getBillHistory` - Get payment history

**Error Handling:**
- INVALID_AMOUNT
- USER_NOT_FOUND
- PROVIDER_NOT_FOUND
- INVALID_OTP / OTP errors
- INSUFFICIENT_BALANCE

### 3. Routes Layer
**File:** `/src/routes/bill.routes.ts`

**Routes:**
- `GET /bills/providers?category=WATER` - Get providers
- `POST /bills/fetch-details` - Fetch bill details
- `POST /bills/request-otp` - Request OTP
- `POST /bills/pay` - Pay bill
- `GET /bills/history` - Get payment history

**Validation:**
- UUID validation for provider_id
- Account number length (3-100 chars)
- Amount minimum (100 SLL)
- OTP length (6 digits)
- Query parameter validation for filters

## Database Integration

### Tables Used

#### bill_providers
```sql
- id (UUID)
- name (VARCHAR)
- type (bill_type enum)
- logo_url (TEXT)
- metadata (JSONB) - contains fields_required
- is_active (BOOLEAN)
```

#### bill_payments
```sql
- id (UUID)
- user_id (UUID)
- provider_id (UUID)
- bill_type (bill_type enum)
- bill_id (VARCHAR) - account/meter number
- bill_holder_name (VARCHAR)
- amount (DECIMAL)
- transaction_id (UUID) - references transactions
- provider_transaction_id (VARCHAR)
- status (transaction_status enum)
- processed_at (TIMESTAMP)
```

#### transactions
- Creates transaction with type `BILL_PAYMENT`
- Stores provider details in metadata field
- Deducts amount + fee from wallet

## API Usage Examples

### 1. Get Bill Providers
```bash
GET /api/v1/bills/providers?category=ELECTRICITY
Authorization: Bearer {token}

Response:
{
  "success": true,
  "data": {
    "providers": [
      {
        "id": "uuid",
        "name": "EDSA",
        "category": "ELECTRICITY",
        "logo_url": "https://...",
        "fields_required": ["account_number", "meter_number"],
        "is_active": true
      }
    ],
    "total": 1
  }
}
```

### 2. Fetch Bill Details
```bash
POST /api/v1/bills/fetch-details
Authorization: Bearer {token}
Content-Type: application/json

{
  "provider_id": "uuid",
  "account_number": "123456789"
}

Response:
{
  "success": true,
  "data": {
    "bill_details": {
      "account_number": "123456789",
      "customer_name": "John Kamara",
      "amount_due": 250000,
      "bill_period": "November 2025",
      "due_date": "2025-12-03"
    }
  },
  "message": "Bill details fetched successfully"
}
```

### 3. Request OTP
```bash
POST /api/v1/bills/request-otp
Authorization: Bearer {token}

Response:
{
  "success": true,
  "data": {
    "otp_sent": true,
    "phone": "****5678",
    "otp_expires_in": 300
  },
  "message": "OTP sent to your registered phone number"
}
```

### 4. Pay Bill
```bash
POST /api/v1/bills/pay
Authorization: Bearer {token}
Content-Type: application/json

{
  "provider_id": "uuid",
  "account_number": "123456789",
  "amount": 250000,
  "otp": "123456",
  "metadata": {
    "customerName": "John Kamara",
    "billPeriod": "November 2025",
    "dueDate": "2025-12-03"
  }
}

Response:
{
  "success": true,
  "data": {
    "payment": {
      "transaction_id": "TXN20251119123456",
      "reference_number": "MOCK-1234567890-abc123",
      "status": "COMPLETED",
      "provider": {
        "id": "uuid",
        "name": "EDSA",
        "type": "ELECTRICITY"
      },
      "account_number": "123456789",
      "customer_name": "John Kamara",
      "amount": 250000,
      "fee": 2500,
      "total_amount": 252500,
      "created_at": "2025-11-19T...",
      "completed_at": "2025-11-19T..."
    }
  },
  "message": "Bill payment completed successfully"
}
```

### 5. Get Bill History
```bash
GET /api/v1/bills/history?bill_type=ELECTRICITY&status=COMPLETED&page=1&limit=20
Authorization: Bearer {token}

Response:
{
  "success": true,
  "data": {
    "payments": [
      {
        "id": "uuid",
        "transaction_id": "TXN20251119123456",
        "reference_number": "MOCK-1234567890-abc123",
        "bill_type": "ELECTRICITY",
        "provider": {
          "name": "EDSA",
          "logo_url": "https://..."
        },
        "account_number": "123456789",
        "customer_name": "John Kamara",
        "amount": 250000,
        "fee": 2500,
        "total_amount": 252500,
        "status": "COMPLETED",
        "created_at": "2025-11-19T...",
        "completed_at": "2025-11-19T..."
      }
    ]
  },
  "meta": {
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 5,
      "totalPages": 1
    }
  }
}
```

## Fee Structure

- **Bill Payment Fee:** 1% of amount (minimum 20 SLL)
- **Fee Calculation:** `Math.max(20, amount * 0.01)`
- **Total Deducted:** `amount + fee`

## Transaction Flow

1. User requests OTP (`POST /bills/request-otp`)
2. User fetches bill details (`POST /bills/fetch-details`)
3. User initiates payment with OTP (`POST /bills/pay`)
4. System validates:
   - OTP verification
   - Provider exists
   - Sufficient wallet balance
   - Valid amount
5. System processes:
   - Creates transaction record (type: BILL_PAYMENT)
   - Deducts from wallet (amount + fee)
   - Creates bill_payment record
   - Returns receipt with reference number

## Mock Implementation Notes

The current implementation uses mock data for provider integration:

### Mock Methods (To Replace with Real APIs)
- `fetchBillDetails()` - Returns simulated bill data
- `payBill()` - Generates mock provider transaction ID
- Helper methods for generating mock customer names, amounts, etc.

### TODO Comments
Search for `TODO` in `/src/services/bill.service.ts` for integration points:
- Line ~115: Integrate with actual provider API for fetching bill details
- Line ~213: Integrate with actual provider API to process payment

### Real Integration Steps
1. Add provider API credentials to environment variables
2. Create HTTP client for provider API
3. Implement provider-specific request/response mapping
4. Add error handling for provider API failures
5. Update `fetchBillDetails()` to call real API
6. Update `payBill()` to submit payment to provider
7. Implement webhook handlers for async payment confirmations
8. Add retry logic for failed provider calls

## Type Updates

### Added to `/src/types/index.ts`
- Updated `OTP` interface to include `'BILL_PAYMENT'` purpose

## Integration with Existing Systems

- **Wallet Service:** Uses `WalletService.getBalance()` and `WalletService.generateTransactionId()`
- **OTP Service:** Uses `OTPService.createOTP()`, `OTPService.sendOTP()`, and `OTPService.verifyOTP()`
- **Transaction System:** Creates records in `transactions` table with type `BILL_PAYMENT`
- **Error Handling:** Follows existing `ApiResponseUtil` pattern
- **Validation:** Uses Zod schemas with `validate()` middleware
- **Authentication:** Protected by `authenticate` middleware

## Testing Checklist

- [ ] Get providers without filter
- [ ] Get providers with category filter
- [ ] Fetch bill details with valid provider
- [ ] Fetch bill details with invalid provider
- [ ] Request OTP
- [ ] Pay bill with valid OTP
- [ ] Pay bill with invalid OTP
- [ ] Pay bill with insufficient balance
- [ ] Pay bill with invalid amount
- [ ] Get bill history without filters
- [ ] Get bill history with filters
- [ ] Get bill history with pagination
- [ ] Verify transaction record created
- [ ] Verify wallet balance deducted
- [ ] Verify bill_payment record created

## Next Steps

1. **Install Dependencies:** Run `npm install` in `/tcc_backend`
2. **Database Setup:** Ensure `bill_providers` table has seed data
3. **Provider Integration:** Replace mock implementations with real APIs
4. **Testing:** Create unit and integration tests
5. **Documentation:** Update API documentation with bill payment endpoints
6. **Mobile App:** Integrate bill payment screens with these endpoints

## Notes

- All routes require authentication
- OTP expires in 5 minutes (configurable)
- Bill payment fee is 1% (configurable in fee calculation)
- All amounts are in Sierra Leonean Leone (SLL)
- Transaction IDs follow format: `TXN + YYYYMMDD + 6 random digits`
