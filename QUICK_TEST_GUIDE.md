# Quick Test Guide - TCC User App & Backend

**Quick reference for running and testing the system locally**

---

## 🚀 Quick Start (5 Minutes)

### 1. Start Backend Server
```bash
cd tcc_backend
npm run dev
```
✅ Server should show: "Server running on port 3000"

### 2. Start Mobile App
```bash
cd tcc_user_mobile_client
flutter run
```
✅ App should launch on your device/emulator

### 3. Test Registration
1. Click "Register" in the app
2. Fill in details (any valid email/phone)
3. Click "Register"
4. **Check backend terminal for OTP code** (logged to console)
5. Enter OTP in app
6. Should see dashboard!

---

## 📋 Pre-Test Checklist

- [ ] PostgreSQL is running (`psql -U shubham -d tcc_database -c "SELECT 1;"`)
- [ ] Database has tables (`psql -U shubham -d tcc_database -c "\dt"`)
- [ ] Backend `.env` file exists and configured
- [ ] Backend dependencies installed (`npm install`)
- [ ] Flutter dependencies installed (`flutter pub get`)
- [ ] Port 3000 is available (`lsof -ti:3000`)

---

## 🧪 Testing Scenarios

### Scenario 1: New User Registration

**Backend Terminal:**
```bash
cd tcc_backend
npm run dev
# Watch for OTP codes in console output
```

**Mobile App:**
1. Launch app
2. Tap "Don't have an account? Register"
3. Enter:
   - First Name: `John`
   - Last Name: `Doe`
   - Email: `john.doe@test.com`
   - Phone: `+232 1234567890`
   - Password: `Test@123`
4. Tap "Register"
5. Look at backend console for: `OTP Code: XXXXXX`
6. Enter the 6-digit code
7. Should redirect to Dashboard ✅

**Expected Result:**
- Registration successful
- OTP sent (visible in backend logs)
- OTP verified
- JWT tokens received
- Dashboard loads with mock data

---

### Scenario 2: Existing User Login

**Backend Terminal:**
```bash
cd tcc_backend
npm run dev
```

**Mobile App:**
1. Launch app
2. Enter registered email and password
3. Tap "Sign In"
4. Check backend console for OTP
5. Enter OTP
6. Should see dashboard

**Expected Result:**
- Login successful
- 2FA OTP sent
- Dashboard loads

---

### Scenario 3: Forgot Password

**Mobile App:**
1. From login screen, tap "Forgot Password?"
2. Enter registered email
3. Tap "Send OTP"
4. Check backend for OTP
5. Enter OTP
6. Set new password
7. Confirm password
8. Should redirect to login

**Expected Result:**
- Password reset successful
- Can login with new password

---

## 🔍 Quick Debugging

### Backend Not Starting?

```bash
# Check if port 3000 is in use
lsof -ti:3000

# If in use, kill the process
lsof -ti:3000 | xargs kill

# Or change port in .env
# PORT=3001
```

### Database Connection Error?

```bash
# Check PostgreSQL is running
brew services list | grep postgresql

# Start PostgreSQL if needed
brew services start postgresql

# Test connection
psql -U shubham -d tcc_database -c "SELECT 1;"

# Check .env database credentials
cat tcc_backend/.env | grep DB_
```

### OTP Not Showing?

```bash
# OTP is logged to console - check backend terminal
# Look for lines like:
# [INFO] OTP Code: 123456
# [INFO] OTP generated for phone: +232...
```

### Mobile App Not Connecting?

```bash
# Check API URL in app
cat tcc_user_mobile_client/lib/config/app_constants.dart | grep baseUrl

# Should be: http://localhost:3000/v1

# For Android emulator, use:
# baseUrl = 'http://10.0.2.2:3000/v1'

# For physical device, use your computer's IP:
# baseUrl = 'http://192.168.1.x:3000/v1'
```

---

## 📊 Verify Everything is Working

### Check 1: Backend Health
```bash
curl http://localhost:3000/health

# Expected: {"success":true,"data":{"status":"healthy",...}}
```

### Check 2: API Version
```bash
curl http://localhost:3000/v1

# Expected: {"success":true,"data":{"version":"v1",...}}
```

### Check 3: Database Tables
```bash
psql -U shubham -d tcc_database -c "SELECT COUNT(*) FROM users;"

# Expected: Some number (or 0 if no users yet)
```

### Check 4: Test Registration API
```bash
curl -X POST http://localhost:3000/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Test",
    "last_name": "User",
    "email": "test123@example.com",
    "phone": "9876543210",
    "country_code": "+232",
    "password": "Test@123"
  }'

# Expected: Success response with OTP sent message
# Check backend console for OTP code
```

---

## 🎯 What Features Can You Test?

### ✅ Currently Working (Backend + Mobile)
- User Registration
- OTP Verification
- User Login (with 2FA)
- Password Reset
- Profile View
- Profile Update
- Change Password
- Logout

### 📱 UI Only (Mock Data in Mobile App)
- Dashboard Home
- Portfolio View
- Transaction History
- Account Settings
- Investment Categories
- Bill Payment UI
- Agent Search UI

### 🚧 Coming Soon (Service Implementation Needed)
- Real wallet balance
- Actual deposits/withdrawals
- Money transfers
- Investment creation
- Transaction recording
- KYC submission
- Bill payments

---

## 💡 Testing Tips

1. **Watch Backend Console**: All OTP codes are logged there
2. **Use Different Emails**: For testing multiple registrations
3. **Valid Password**: Must have uppercase, lowercase, number, special char, 8+ chars
4. **Phone Format**: Include country code (+232 for Sierra Leone)
5. **Clear Tokens**: If having auth issues, clear app data or reinstall

---

## 📱 Testing on Different Platforms

### iOS Simulator
```bash
flutter run -d "iPhone 15"
```
API URL: `http://localhost:3000/v1` ✅ Works!

### Android Emulator
```bash
flutter run -d emulator-5554
```
API URL needs to be: `http://10.0.2.2:3000/v1`

**To change**: Edit `tcc_user_mobile_client/lib/config/app_constants.dart`

### Physical Device (Same WiFi)
Find your computer's IP:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```
Change API URL to: `http://YOUR_IP:3000/v1`

---

## 🐛 Common Issues & Fixes

### Issue: "Network Error" in Mobile App
**Fix**: Check if backend is running and accessible from device

### Issue: "Invalid OTP"
**Fix**: Make sure you're using the latest OTP from backend console (they expire in 5 minutes)

### Issue: "Email already exists"
**Fix**: Use a different email or check database: `SELECT email FROM users;`

### Issue: Backend crashes on startup
**Fix**: Check logs in `tcc_backend/logs/app.log`

### Issue: Flutter build errors
**Fix**:
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📝 Test User Credentials (After First Registration)

Keep track of your test users:

| Email | Password | Phone | Notes |
|-------|----------|-------|-------|
| test@example.com | Test@123 | +232 1234567890 | First test user |
| | | | |

---

## 🎬 Demo Script (5 Minutes)

Perfect for showing someone the app:

1. **Start** (30s)
   - Open app
   - Show login screen

2. **Register** (2 min)
   - Click Register
   - Fill form
   - Get OTP
   - Enter OTP
   - Show dashboard

3. **Explore** (2 min)
   - Show balance card
   - Navigate to Portfolio
   - Show investments (mock data)
   - Go to Transactions
   - Show transaction history
   - Visit Account settings

4. **Features** (30s)
   - Point out KYC status
   - Show investment categories
   - Mention upcoming features

---

## 📞 Need Help?

Check these files for more details:
- `USER_APP_PROGRESS_REPORT.md` - Complete progress report
- `PROJECT_SUMMARY.md` - Project overview
- `tcc_backend/README.md` - Backend documentation
- `api_specification.md` - All API endpoints

---

**Happy Testing! 🚀**

Last Updated: December 1, 2025
