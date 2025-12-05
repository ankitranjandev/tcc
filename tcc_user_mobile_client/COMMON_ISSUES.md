# Common Issues & Solutions

## Issue: Login Fails with "Validation failed"

### What you saw in the logs:
```
[ApiService] 📡 ApiService: Response status: 422
[ApiService] ⚠️ ApiService: 422 Validation Error
[AuthService] ❌ AuthService: Login error: Validation failed
```

### Cause:
The backend rejected your input because it doesn't meet validation requirements.

### Common Reasons:

#### 1. Invalid Email Format
**Problem:** Email doesn't contain `@` and domain (e.g., "1", "test", "user")

**Solution:** Enter a valid email address like:
- `user@example.com`
- `test@test.com`
- `admin@tcc.com`

**Client-side validation now added:** The app will now check email format before sending to backend.

#### 2. Password Requirements Not Met
**Problem:** Password is too short or doesn't meet requirements

**Solution:** Check your backend's password requirements:
- Usually minimum 8 characters
- May require uppercase, lowercase, numbers, special characters

#### 3. Account Doesn't Exist
**Problem:** Trying to login with credentials that aren't in the database

**Solution:**
- Create a test account in your backend first
- Or use an existing test account
- Check backend database for available test accounts

---

## Issue: "Network Error" or "Connection Refused"

### What you see:
```
[ApiService] ❌ ApiService: SocketException: Connection refused
```

### Cause:
The app cannot connect to the backend server.

### Solutions:

#### 1. Backend Not Running
```bash
# Check if backend is running
curl http://localhost:3000/v1

# If it fails, start backend
cd ../tcc_backend
npm start
```

#### 2. Wrong Port
Check your backend is running on port 3000. If using a different port, update `lib/config/app_constants.dart`.

#### 3. Emulator Network Issue
```bash
# Test connectivity from emulator
adb shell ping -c 3 10.0.2.2
```

---

## Issue: App Stuck on Loading Screen

### What you see:
- White screen with loading spinner
- Never reaches login screen

### Cause:
App initialization failed or taking too long.

### Solutions:

#### 1. Check Logs
```bash
./view_logs.sh
```

Look for:
```
🚀 TCCApp: App initialization complete
```

If you don't see this, initialization failed.

#### 2. Clear App Data
```bash
flutter clean
flutter pub get
flutter run --clear-cache
```

#### 3. Restart Emulator
Close and reopen the Android emulator.

---

## Issue: 401 Unauthorized During Login

### What you see:
```
[ApiService] ⚠️ ApiService: 401 Unauthorized
[AuthService] ❌ AuthService: Login error: Session expired. Please login again.
```

### Cause (During Login):
This happens when trying to login with invalid credentials:
- **Wrong email or password**
- **Account doesn't exist in database**
- **Account is disabled/inactive**

### Solutions:

#### 1. Verify Test Account Exists
Check your backend database:
```sql
-- Check if user exists
SELECT email FROM users WHERE email = 'test@example.com';
```

#### 2. Create Test Account in Backend
If no test account exists, create one:
```bash
# Using your backend's user creation method
# Example: npm run seed:users
# Or create manually in database
```

#### 3. Verify Password
Make sure you're using the correct password for the test account.

#### 4. Check Backend Logs
Look at your backend terminal for more specific error messages:
- "Invalid credentials"
- "User not found"
- "Account inactive"

---

## Issue: "Session expired. Please login again" (While Browsing App)

### What you see:
```
[ApiService] ⚠️ ApiService: 401 Unauthorized
```

### Cause (After Login):
- Token expired
- Token invalid
- Backend rejected the token

### Solutions:

#### 1. Login Again
The app should automatically redirect to login. Just sign in again.

#### 2. Clear Stored Tokens
```bash
# Uninstall and reinstall app
flutter clean
flutter run
```

---

## Issue: Backend Returns 500 Server Error

### What you see:
```
[ApiService] ❌ ApiService: 500 Server Error
```

### Cause:
Backend server has an internal error.

### Solutions:

#### 1. Check Backend Logs
Look at your backend terminal for error messages.

#### 2. Verify Database Connection
Backend might have lost connection to database.

#### 3. Restart Backend
```bash
# Ctrl+C to stop
# npm start to restart
```

---

## Issue: Login Success but Dashboard Doesn't Load

### What you see in logs:
```
🟢 AuthProvider: Login successful
🔐 LoginScreen: Navigating to /dashboard
(Then nothing happens)
```

### Cause:
- Navigation failed
- Dashboard route not configured
- Profile loading failed

### Solutions:

#### 1. Check Profile Loading
Look for:
```
🟡 AuthProvider: User profile loaded successfully
```

If you see an error here, backend profile endpoint has issues.

#### 2. Check Router Configuration
Verify `/dashboard` route exists in `lib/main.dart`.

---

## Best Practices for Demo

### Before Starting

1. **Create Test Accounts**
   ```sql
   -- In your backend database
   INSERT INTO users (email, password, ...)
   VALUES ('demo@tcc.com', 'hashed_password', ...);
   ```

2. **Test Login Once**
   ```bash
   curl -X POST http://localhost:3000/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"demo@tcc.com","password":"Demo123!"}'
   ```

3. **Have Credentials Written Down**
   ```
   Email: demo@tcc.com
   Password: Demo123!
   ```

4. **Test the App**
   ```bash
   flutter run
   # Try logging in with test credentials
   ```

### During Demo

1. **Type Slowly and Clearly**
   - Easy to mistype on emulator
   - Viewers can see what you're entering

2. **Have Logs Running** (optional)
   ```bash
   ./view_logs.sh
   ```
   Shows professionalism and transparency

3. **If Login Fails**
   - Check the error message
   - Double-check email/password
   - Don't panic - restart app if needed

---

## Quick Debugging Commands

### Test Backend Connectivity
```bash
curl http://localhost:3000/v1
```

### Test Login Endpoint
```bash
curl -X POST http://localhost:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password123"}'
```

### View App Logs
```bash
./view_logs.sh
# or
flutter logs
```

### Check Emulator Network
```bash
adb shell ping -c 3 10.0.2.2
```

### Restart Everything
```bash
# Terminal 1: Stop and restart backend
Ctrl+C
npm start

# Terminal 2: Stop and restart app
Ctrl+C
flutter run
```

---

## Understanding Error Codes

| Code | Meaning | Common Cause |
|------|---------|--------------|
| 400 | Bad Request | Malformed request body |
| 401 | Unauthorized | Invalid credentials or expired token |
| 403 | Forbidden | User doesn't have permission |
| 404 | Not Found | Endpoint doesn't exist |
| 422 | Validation Error | Input doesn't meet requirements |
| 500 | Server Error | Backend has internal error |
| Network Error | Cannot connect | Backend not running or wrong URL |

---

## Still Having Issues?

1. **Check all logs:**
   ```bash
   ./view_logs.sh
   ```

2. **Read the full error message:**
   - Backend validation messages are now shown
   - Look for specific field errors

3. **Verify test data:**
   - Check backend database
   - Confirm test user exists
   - Verify password is correct

4. **Review documentation:**
   - `DEBUG_SIGNIN.md` - Detailed debugging
   - `DEMO_SETUP.md` - Setup verification
   - `DEMO_QUICK_REFERENCE.md` - Quick fixes

---

## Pro Tips

### Create Multiple Test Accounts
```
demo@tcc.com / Demo123!
test@tcc.com / Test123!
admin@tcc.com / Admin123!
```

### Test Before Demo
Always do a full test run 10 minutes before the actual demo.

### Have a Backup Plan
- Screenshots of working app
- Pre-recorded video
- Slides showing features

### Stay Calm
If something fails:
1. Check error message
2. Try once more
3. If still fails, acknowledge it and move on
4. Show other features that work

---

**Remember:** Everyone encounters bugs during demos. How you handle them shows professionalism!
