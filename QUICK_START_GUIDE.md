# 🚀 TCC Stripe Integration - Quick Start Guide

## ⚡ Get Started in 5 Minutes

### Step 1: Database Setup (2 minutes)
```bash
cd tcc_backend
psql -U postgres -d tcc_database -f src/database/migrations/002_add_stripe_and_audit_trail.sql
```

### Step 2: Configure Stripe Keys (1 minute)
1. Get your keys from https://dashboard.stripe.com/test/apikeys
2. Update `tcc_backend/.env`:
```env
STRIPE_SECRET_KEY=sk_test_YOUR_KEY_HERE
STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_KEY_HERE
STRIPE_WEBHOOK_SECRET=whsec_YOUR_SECRET_HERE
STRIPE_CURRENCY=sll
```

3. Update `tcc_user_mobile_client/lib/config/app_constants.dart` line 29:
```dart
static const String stripePublishableKey = 'pk_test_YOUR_KEY_HERE';
```

### Step 3: Start Backend (30 seconds)
```bash
cd tcc_backend
npm start
```

### Step 4: Start Mobile App (1 minute)
```bash
cd tcc_user_mobile_client
flutter run
```

### Step 5: Test Payment (30 seconds)
1. Open app → Vault → Explore
2. Tap "Add Money"
3. Enter amount: **Le 10,000**
4. Use test card: **4242 4242 4242 4242**
5. Expiry: **12/25**, CVC: **123**
6. Complete payment ✅

---

## 🎯 Test Cards

| Card Number | Exp | CVC | Result |
|------------|-----|-----|--------|
| 4242 4242 4242 4242 | 12/25 | 123 | ✅ Success |
| 4000 0000 0000 0002 | 12/25 | 123 | ❌ Decline |
| 4000 0000 0000 9995 | 12/25 | 123 | ⚠️ Insufficient |

---

## 📍 What You Can Do Now

### ✅ Users Can:
- Add money to wallet using credit/debit cards
- View real-time transaction history
- See transaction status (pending, completed, failed)
- Pull to refresh transactions

### ✅ Admins Can:
- Manually adjust user balances
- View complete audit trail
- Monitor all transactions
- Process refunds

---

## 🔗 API Endpoints

### Payment
```bash
POST http://localhost:3000/v1/wallet/create-payment-intent
Headers: Authorization: Bearer YOUR_TOKEN
Body: { "amount": 10000 }
```

### Transactions
```bash
GET http://localhost:3000/v1/transactions/history
Headers: Authorization: Bearer YOUR_TOKEN
```

### Admin - Manual Adjustment
```bash
POST http://localhost:3000/v1/admin/wallet/adjust-balance
Headers: Authorization: Bearer ADMIN_TOKEN
Body: {
  "user_id": "UUID",
  "amount": 5000,
  "reason": "Compensation"
}
```

---

## 🐛 Troubleshooting

**Payment not working?**
- Check Stripe keys in `.env` and `app_constants.dart`
- Verify backend is running on port 3000
- Check mobile app can reach `http://10.0.2.2:3000` (Android) or `http://127.0.0.1:3000` (iOS)

**Webhook not firing?**
- Webhooks only work with public URLs in production
- For local testing, use Stripe CLI: `stripe listen --forward-to localhost:3000/webhooks/stripe`
- Or test manually by marking transactions as completed

**Transaction not appearing?**
- Check backend logs for errors
- Verify database migration was applied
- Try pull-to-refresh in app

---

## 📚 Full Documentation

- **Complete Guide**: `/STRIPE_INTEGRATION_COMPLETE.md`
- **Implementation Summary**: `/IMPLEMENTATION_SUMMARY_FINAL.md`
- **Backend Setup**: `/tcc_backend/BACKEND_SETUP_GUIDE.md`

---

## ✨ Next Steps

1. ✅ Test payment flow
2. ✅ Verify transactions appear
3. ✅ Check webhook processing
4. 🔄 Set up Stripe webhook for production
5. 🔄 Complete remaining UI enhancements (optional)
6. 🚀 Deploy to production

---

**Need help?** Check the troubleshooting section or review the full documentation.

**Ready for production?** Just replace test keys with live keys and configure webhooks!
