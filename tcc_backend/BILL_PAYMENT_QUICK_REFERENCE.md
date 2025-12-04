# Bill Payment API - Quick Reference

## Base URL
```
https://api.tcc.com/api/v1/bills
```

## Endpoints

### 1. GET /providers
Get list of bill providers (optionally filtered by category)

**Query Parameters:**
- `category` (optional): WATER | ELECTRICITY | DSTV | INTERNET | MOBILE

**Response:**
```json
{
  "providers": [{
    "id": "uuid",
    "name": "EDSA",
    "category": "ELECTRICITY",
    "logo_url": "https://...",
    "fields_required": ["account_number"],
    "is_active": true
  }],
  "total": 1
}
```

---

### 2. POST /fetch-details
Fetch bill details before payment

**Body:**
```json
{
  "provider_id": "uuid",
  "account_number": "123456789"
}
```

**Response:**
```json
{
  "bill_details": {
    "account_number": "123456789",
    "customer_name": "John Kamara",
    "amount_due": 250000,
    "bill_period": "November 2025",
    "due_date": "2025-12-03"
  }
}
```

---

### 3. POST /request-otp
Request OTP for bill payment

**Response:**
```json
{
  "otp_sent": true,
  "phone": "****5678",
  "otp_expires_in": 300
}
```

---

### 4. POST /pay
Pay bill with OTP verification

**Body:**
```json
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
```

**Response:**
```json
{
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
}
```

---

### 5. GET /history
Get bill payment history

**Query Parameters:**
- `bill_type` (optional): WATER | ELECTRICITY | DSTV | INTERNET | MOBILE
- `status` (optional): PENDING | PROCESSING | COMPLETED | FAILED | CANCELLED
- `from_date` (optional): ISO date string
- `to_date` (optional): ISO date string
- `search` (optional): Search by account number, customer name, or transaction ID
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20, max: 100)

**Response:**
```json
{
  "payments": [{
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
  }],
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

## Payment Flow

```
1. GET /providers
   ↓
2. POST /fetch-details
   ↓
3. POST /request-otp
   ↓
4. POST /pay (with OTP)
   ↓
5. GET /history (to view receipt)
```

## Fee Structure

- **Fee:** 1% of amount
- **Minimum Fee:** 20 SLL
- **Total Deducted:** amount + fee

## Error Codes

| Code | Message | Description |
|------|---------|-------------|
| 400 | Invalid amount | Amount is zero, negative, or below minimum |
| 400 | Insufficient balance | Wallet balance too low for payment + fee |
| 400 | Invalid OTP | OTP is incorrect, expired, or already used |
| 404 | User not found | User account doesn't exist |
| 404 | Bill provider not found | Provider doesn't exist or is inactive |
| 500 | Internal server error | Server-side error |

## Authentication

All endpoints require Bearer token authentication:

```
Authorization: Bearer {access_token}
```

## Bill Types

- `WATER` - Water utility bills
- `ELECTRICITY` - Electricity bills
- `DSTV` - DStv/satellite TV subscriptions
- `INTERNET` - Internet service bills
- `MOBILE` - Mobile phone airtime/data

## Important Notes

1. **OTP Expiry:** OTPs expire in 5 minutes
2. **Minimum Payment:** 100 SLL
3. **Currency:** All amounts in Sierra Leonean Leone (SLL)
4. **Transaction ID Format:** TXN + YYYYMMDD + 6 random digits
5. **Mock Implementation:** Current provider integration is mocked (see TODO comments)

## Integration Checklist

- [ ] Add provider to `bill_providers` table
- [ ] Configure provider API credentials
- [ ] Test bill fetching
- [ ] Test payment processing
- [ ] Verify wallet deduction
- [ ] Check transaction history
- [ ] Test error scenarios
- [ ] Verify OTP flow
