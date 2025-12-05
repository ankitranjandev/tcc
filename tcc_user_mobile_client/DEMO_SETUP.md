# Demo Setup Guide - TCC User Mobile Client

This guide will help you set up the mobile app to connect to your local backend server for the client demo.

## 🚀 Quick Start

### Prerequisites
- Backend server is running on port 3000
- Android Emulator or iOS Simulator is set up
- Flutter is installed and configured

### Step 1: Verify Backend is Running

```bash
# Test your backend is accessible
curl http://localhost:3000/v1/auth/login

# You should see a response (even if it's an error about missing credentials)
```

### Step 2: Configure the App

The app is now automatically configured to work with:
- **Android Emulator**: Uses `http://10.0.2.2:3000/v1`
- **iOS Simulator**: Uses `http://127.0.0.1:3000/v1`

No manual configuration needed! 🎉

### Step 3: Build and Run

```bash
# Clean any previous builds
flutter clean

# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run
```

### Step 4: Monitor Logs (Optional but Recommended)

Open a separate terminal and run:
```bash
./view_logs.sh
```

This will show you detailed logs of the authentication flow.

## 📱 Platform-Specific Notes

### Android Emulator

**Important**: The Android emulator maps `10.0.2.2` to your host machine's `localhost`.

✅ **Already configured** - No changes needed!

**Backend URL**: `http://10.0.2.2:3000/v1`

### iOS Simulator

**Backend URL**: `http://127.0.0.1:3000/v1`

Works with standard localhost.

### Physical Device

If testing on a physical device:

1. Find your computer's IP address:
   ```bash
   # macOS/Linux
   ifconfig | grep "inet " | grep -v 127.0.0.1

   # Or on macOS
   ipconfig getifaddr en0
   ```

2. Update `lib/config/app_constants.dart`:
   ```dart
   static String get baseUrl {
     if (Platform.isAndroid) {
       return 'http://YOUR_IP_HERE:3000/v1';  // e.g., 192.168.1.100
     } else if (Platform.isIOS) {
       return 'http://YOUR_IP_HERE:3000/v1';
     }
     // ...
   }
   ```

3. Ensure your phone and computer are on the same WiFi network

4. Make sure your firewall allows connections on port 3000

## 🔍 Troubleshooting

### Issue: "Network Error" or "Connection Refused"

**Check:**
1. Backend server is running: `curl http://localhost:3000/v1`
2. Using correct device (emulator vs physical)
3. Check logs: `./view_logs.sh`

**Look for this log:**
```
🔧 ApiService: Base URL: http://10.0.2.2:3000/v1
```

### Issue: "Cannot connect to backend"

**For Android Emulator:**
```bash
# Verify emulator can reach your backend
adb shell ping -c 3 10.0.2.2
```

**Test the endpoint from emulator:**
```bash
adb shell
curl http://10.0.2.2:3000/v1
```

### Issue: Login fails with valid credentials

**Check the logs for:**
```
❌ ApiService: Response status: 401
```

This means authentication failed. Verify:
1. Backend is returning correct token format
2. Credentials are correct
3. Backend `/auth/login` endpoint is working

### Issue: App gets stuck on loading screen

**Check:**
```
🚀 TCCApp: App initialization complete
```

If you don't see this, the app didn't finish initializing.

## 📋 Pre-Demo Checklist

Before starting your demo:

- [ ] Backend server is running and responding
  ```bash
  curl http://localhost:3000/v1/auth/login
  ```

- [ ] Test user account exists in backend database

- [ ] App is installed on emulator
  ```bash
  flutter install
  ```

- [ ] Test login flow once to verify it works

- [ ] Have log viewer running (optional)
  ```bash
  ./view_logs.sh
  ```

- [ ] Know your test credentials
  - Email: _____________
  - Password: _____________

## 🎬 Demo Flow

### Recommended Demo Steps:

1. **Show Login Screen**
   - Clean, professional UI
   - Email and password fields

2. **Enter Credentials**
   - Use your test account

3. **Sign In**
   - Loading indicator shows
   - Quick authentication

4. **Dashboard Appears**
   - User is authenticated
   - Can navigate the app

### If Something Goes Wrong During Demo:

1. **Stay calm** - Check the logs if you have them running
2. **Common fixes:**
   - Close and reopen the app
   - Check backend is still running
   - Verify WiFi/network connection
3. **Have a backup plan:**
   - Show screenshots/recordings of working flow
   - Demonstrate other features that don't require login

## 🔧 Advanced Configuration

### Custom Backend Port

If your backend runs on a different port (e.g., 8080):

Edit `lib/config/app_constants.dart`:
```dart
static String get baseUrl {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8080/v1';  // Changed port
  }
  // ...
}
```

### Custom API Prefix

If your API doesn't use `/v1`:

```dart
static String get baseUrl {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:3000/api';  // Changed prefix
  }
  // ...
}
```

### HTTPS Configuration

For production/staging servers with HTTPS:

```dart
static String get baseUrl {
  if (Platform.isAndroid) {
    return 'https://api.yourdomain.com/v1';
  }
  // ...
}
```

## 📊 Viewing Detailed Logs

### During Development:
```bash
./view_logs.sh
```

### All Logs:
```bash
flutter logs
```

### Specific Components:
```bash
flutter logs | grep "AuthProvider"
flutter logs | grep "ApiService"
```

## 🆘 Emergency Fixes

### Complete Reset

If the app is completely broken:

```bash
# Uninstall the app
flutter clean

# Clear emulator data (Android)
flutter run --clear-cache

# Reinstall
flutter pub get
flutter run
```

### Backend Connection Test

```bash
# Test from your machine
curl -X POST http://localhost:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password123"}'

# Test from emulator (Android)
adb shell curl -X POST http://10.0.2.2:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password123"}'
```

## 📞 Support

If issues persist:
1. Check `DEBUG_SIGNIN.md` for detailed troubleshooting
2. Review logs with `./view_logs.sh`
3. Verify backend is accessible and returning correct data format

---

**Ready to demo!** 🎉

Follow these steps and your client demo should go smoothly. Good luck!
