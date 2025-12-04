# Bill Payment - Developer Quick Start Guide

## Getting Started

### 1. Installation
```bash
cd /Users/shubham/Documents/playground/tcc/tcc_backend
npm install
```

### 2. Database Setup
```bash
# Load bill providers seed data
psql -U postgres -d tcc_db -f seed_bill_providers.sql
```

### 3. Environment Variables
Ensure these are set in `.env`:
```env
DATABASE_URL=postgresql://user:pass@localhost:5432/tcc_db
JWT_SECRET=your_jwt_secret
OTP_EXPIRY_MINUTES=5
```

### 4. Start Server
```bash
npm run dev
```

## File Locations

### Service Layer
```
/src/services/bill.service.ts
```
Contains all business logic for bill payments.

### Controller Layer
```
/src/controllers/bill.controller.ts
```
Handles HTTP requests and responses.

### Routes
```
/src/routes/bill.routes.ts
```
Defines API endpoints and validation.

## API Endpoints

### Base URL: `/api/v1/bills`

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/providers` | List providers | Yes |
| POST | `/fetch-details` | Get bill details | Yes |
| POST | `/request-otp` | Request OTP | Yes |
| POST | `/pay` | Pay bill | Yes |
| GET | `/history` | Payment history | Yes |

## Quick Test Flow

### Using cURL

**1. Get Auth Token** (from login)
```bash
export TOKEN="your_jwt_token"
```

**2. List Providers**
```bash
curl -X GET "http://localhost:3000/api/v1/bills/providers?category=ELECTRICITY" \
  -H "Authorization: Bearer $TOKEN"
```

**3. Fetch Bill Details**
```bash
curl -X POST "http://localhost:3000/api/v1/bills/fetch-details" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "provider_id": "uuid-from-step-2",
    "account_number": "123456789"
  }'
```

**4. Request OTP**
```bash
curl -X POST "http://localhost:3000/api/v1/bills/request-otp" \
  -H "Authorization: Bearer $TOKEN"
```

**5. Pay Bill**
```bash
curl -X POST "http://localhost:3000/api/v1/bills/pay" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "provider_id": "uuid-from-step-2",
    "account_number": "123456789",
    "amount": 100000,
    "otp": "123456",
    "metadata": {
      "customerName": "John Doe",
      "billPeriod": "November 2025"
    }
  }'
```

**6. View History**
```bash
curl -X GET "http://localhost:3000/api/v1/bills/history?page=1&limit=10" \
  -H "Authorization: Bearer $TOKEN"
```

## Common Development Tasks

### Adding a New Provider

**1. Insert into database:**
```sql
INSERT INTO bill_providers (id, name, type, logo_url, is_active, metadata)
VALUES (
  uuid_generate_v4(),
  'New Provider',
  'ELECTRICITY',
  'https://example.com/logo.png',
  true,
  '{"fields_required": ["account_number"]}'::jsonb
);
```

**2. Test the provider:**
```bash
curl -X GET "http://localhost:3000/api/v1/bills/providers?category=ELECTRICITY" \
  -H "Authorization: Bearer $TOKEN"
```

### Modifying Fee Structure

Edit `/src/services/bill.service.ts`:
```typescript
// Line ~190
const fee = Math.max(20, amount * 0.01); // Change 0.01 to adjust percentage
```

### Adding New Bill Category

**1. Update enum in `/src/types/index.ts`:**
```typescript
export enum BillType {
  WATER = 'WATER',
  ELECTRICITY = 'ELECTRICITY',
  DSTV = 'DSTV',
  INTERNET = 'INTERNET',
  MOBILE = 'MOBILE',
  GAS = 'GAS', // New category
  OTHER = 'OTHER',
}
```

**2. Update database enum:**
```sql
ALTER TYPE bill_type ADD VALUE 'GAS';
```

**3. Add mock amount range in service (if using mocks):**
```typescript
const ranges: Record<BillType, [number, number]> = {
  // ... existing ranges
  [BillType.GAS]: [80000, 400000], // New range
};
```

### Integrating Real Provider API

**1. Create provider adapter:** `/src/services/providers/edsa.provider.ts`
```typescript
export class EDSAProvider {
  async fetchBillDetails(accountNumber: string) {
    // Call real API
    const response = await axios.post('https://edsa-api.com/bills', {
      account: accountNumber
    });
    return response.data;
  }

  async processPayment(accountNumber: string, amount: number) {
    // Process payment via API
    const response = await axios.post('https://edsa-api.com/pay', {
      account: accountNumber,
      amount: amount
    });
    return response.data;
  }
}
```

**2. Update `bill.service.ts`:**
```typescript
// Replace mock implementation
static async fetchBillDetails(providerId: string, accountNumber: string) {
  const provider = await this.getProviderById(providerId);

  // Use real provider adapter
  switch(provider.name) {
    case 'EDSA':
      const edsaProvider = new EDSAProvider();
      return await edsaProvider.fetchBillDetails(accountNumber);
    // ... other providers
  }
}
```

## Debugging

### Enable Debug Logging
```typescript
// In bill.service.ts, add:
logger.debug('Bill payment request', { userId, providerId, amount });
```

### Check Database Records

**View recent transactions:**
```sql
SELECT * FROM transactions
WHERE type = 'BILL_PAYMENT'
ORDER BY created_at DESC
LIMIT 10;
```

**View bill payments:**
```sql
SELECT bp.*, t.transaction_id, pr.name as provider_name
FROM bill_payments bp
JOIN transactions t ON bp.transaction_id = t.id
JOIN bill_providers pr ON bp.provider_id = pr.id
ORDER BY bp.created_at DESC
LIMIT 10;
```

**Check wallet balance:**
```sql
SELECT u.first_name, u.last_name, w.balance
FROM users u
JOIN wallets w ON u.id = w.user_id
WHERE u.id = 'user-uuid';
```

### Common Issues

**Issue: "PROVIDER_NOT_FOUND"**
- Verify provider exists: `SELECT * FROM bill_providers WHERE id = 'uuid';`
- Check is_active flag is true

**Issue: "INSUFFICIENT_BALANCE"**
- Check wallet balance includes fee
- Remember: total = amount + (amount * 0.01)

**Issue: "INVALID_OTP"**
- OTP expires after 5 minutes
- Check OTP was generated for 'BILL_PAYMENT' purpose
- Verify OTP: `SELECT * FROM otps WHERE phone = 'phone_number';`

**Issue: Routes not found (404)**
- Check server logs for "Bill routes registered"
- Verify `/src/app.ts` imports bill routes
- Restart server after adding routes

## Testing

### Unit Tests
Create `/src/tests/services/bill.service.test.ts`:
```typescript
import { BillService } from '../../services/bill.service';

describe('BillService', () => {
  test('should calculate fee correctly', () => {
    const amount = 100000;
    const expectedFee = 1000; // 1%
    // Test implementation
  });

  test('should enforce minimum fee', () => {
    const amount = 1000;
    const expectedFee = 20; // Minimum
    // Test implementation
  });
});
```

### Integration Tests
Create `/src/tests/routes/bill.routes.test.ts`:
```typescript
import request from 'supertest';
import app from '../../app';

describe('Bill Routes', () => {
  test('GET /bills/providers returns providers', async () => {
    const response = await request(app)
      .get('/api/v1/bills/providers')
      .set('Authorization', `Bearer ${token}`);

    expect(response.status).toBe(200);
    expect(response.body.data.providers).toBeDefined();
  });
});
```

## Performance Optimization

### Database Indexes
Already created in schema:
```sql
CREATE INDEX idx_bill_payments_user ON bill_payments(user_id);
CREATE INDEX idx_bill_payments_status ON bill_payments(status);
CREATE INDEX idx_bill_payments_provider ON bill_payments(provider_id);
```

### Query Optimization
- Use pagination for history queries
- Limit default page size to 20
- Add indexes on frequently filtered columns

### Caching
Consider caching provider list:
```typescript
// Add simple cache
const providerCache = new Map();

static async getProviders(category?: BillType) {
  const cacheKey = category || 'all';

  if (providerCache.has(cacheKey)) {
    return providerCache.get(cacheKey);
  }

  const providers = await /* fetch from DB */;
  providerCache.set(cacheKey, providers);

  return providers;
}
```

## Monitoring

### Key Metrics to Track
1. Payment success rate
2. Average payment amount
3. Most popular providers
4. Failed payment reasons
5. OTP verification success rate

### Add Metrics
```typescript
// In payBill method
logger.info('Bill payment metrics', {
  providerId,
  amount,
  fee,
  duration: Date.now() - startTime,
  status: 'success'
});
```

## Documentation Files

- `BILL_PAYMENT_IMPLEMENTATION.md` - Complete implementation details
- `BILL_PAYMENT_QUICK_REFERENCE.md` - API reference
- `BILL_PAYMENT_SUMMARY.md` - Project summary
- `seed_bill_providers.sql` - Sample data

## Need Help?

- Check TODO comments in code for integration points
- Review existing services (wallet, transaction) for patterns
- Consult database schema: `/database_schema.sql`
- API patterns: `/src/controllers/wallet.controller.ts`

## Next Steps

1. Test all endpoints manually
2. Write unit tests
3. Integrate real provider APIs
4. Add monitoring/alerting
5. Update mobile app to use endpoints
6. Load test for production readiness
