# 📱 TCC Mobile App - Demo Quick Reference Card

## ⚡ Quick Start Commands

### 1️⃣ Start Backend Server
```bash
cd ../tcc_backend  # or wherever your backend is
npm start
# Wait for: "Server running on port 3000"
```

### 2️⃣ Start Android Emulator
```bash
# Open Android Studio and start an emulator
# OR use command line:
emulator -avd <your_avd_name> -netdelay none -netspeed full
```

### 3️⃣ Install & Run the App
```bash
cd tcc_user_mobile_client
flutter run
# OR to just install:
flutter install
```

### 4️⃣ View Logs (Optional - Separate Terminal)
```bash
./view_logs.sh
```

---

## 🔧 Configuration Summary

| Platform | Backend URL | Notes |
|----------|-------------|-------|
| Android Emulator | `http://10.0.2.2:3000/v1` | ✅ Auto-configured |
| iOS Simulator | `http://127.0.0.1:3000/v1` | ✅ Auto-configured |
| Physical Device | `http://<YOUR_IP>:3000/v1` | ⚠️ Needs manual setup |

---

## 🎯 Demo Test Credentials

**Update these with your actual test account:**

```
Email: ________________________
Password: ______________________
```

---

## ✅ Pre-Demo Checklist (2 minutes)

**Terminal 1:**
```bash
# 1. Start backend
cd ../tcc_backend
npm start
```

**Terminal 2:**
```bash
# 2. Test backend is running
curl http://localhost:3000/v1

# 3. Start emulator (if not running)
# Open Android Studio -> AVD Manager -> Click ▶️

# 4. Run the app
cd tcc_user_mobile_client
flutter run
```

**Terminal 3 (Optional):**
```bash
# 5. Start log viewer
./view_logs.sh
```

---

## 🎬 Demo Script

### Introduction (30 seconds)
"This is the TCC mobile application built with Flutter. It provides a clean, modern interface for users to manage their transactions, investments, and payments."

### Login Flow (1 minute)
1. **Show Login Screen**
   - "Here's our authentication screen with email and password"

2. **Enter Credentials**
   - Type email and password

3. **Sign In**
   - Click "Sign In" button
   - "You'll see a loading indicator while we authenticate"

4. **Dashboard Appears**
   - "And we're in! The user is now authenticated and can access all features"

### Features Tour (2-3 minutes)
- Dashboard overview
- Navigation through bottom tabs
- Key features highlight

---

## 🆘 Emergency Troubleshooting

### Problem: "Network Error"

**Quick Fix:**
```bash
# Check backend is running
curl http://localhost:3000/v1
# If this fails, restart backend

# Check logs
./view_logs.sh
# Look for "ApiService: Base URL: http://10.0.2.2:3000/v1"
```

### Problem: Login Fails

**Quick Fix:**
1. Verify credentials are correct
2. Check backend logs for errors
3. Restart the app: Close and reopen

### Problem: App Won't Install

**Quick Fix:**
```bash
flutter clean
flutter pub get
flutter run
```

### Problem: Emulator is Slow

**Quick Fix:**
1. Close other apps
2. Restart emulator
3. Use a different AVD with less RAM

---

## 📊 Success Indicators

### When everything is working, you should see:

**In Logs:**
```
🚀 TCCApp: App initialization complete
🔧 ApiService: Base URL: http://10.0.2.2:3000/v1
```

**After Login:**
```
🟢 AuthProvider: Login successful
🔐 LoginScreen: Login successful, navigating to /dashboard
```

**In App:**
- Login screen appears
- No error messages
- Login succeeds within 1-2 seconds
- Dashboard loads with user data

---

## 🔄 If Demo Fails

### Plan B: Screenshots/Recording
- Have screenshots of working app ready
- Pre-recorded video of successful flow

### Plan C: Explain Architecture
- Show code structure
- Discuss technical implementation
- Highlight key features on slides

---

## 💡 Key Talking Points

1. **Flutter Framework**
   - Cross-platform (iOS & Android from single codebase)
   - Fast development with hot reload
   - Native performance

2. **Authentication**
   - Secure JWT token-based auth
   - Automatic token refresh
   - Persistent sessions

3. **Architecture**
   - Clean separation of concerns
   - Provider state management
   - RESTful API integration

4. **User Experience**
   - Responsive design
   - Dark mode support
   - Intuitive navigation

---

## 📱 Device Info

**Emulator Details:**
- Name: _______________________
- Android Version: _____________
- RAM: ________________________

**Backend:**
- URL: http://localhost:3000
- Version: ____________________

---

## ⏱️ Timing

- Setup: 2 minutes
- Demo: 5 minutes
- Q&A: Variable

**Total: ~10-15 minutes**

---

## 📞 Emergency Contacts

If technical issues:
- Backend Team: _______________
- Flutter Dev: ________________

---

**Last Updated:** 2025-12-04
**Build Status:** ✅ Ready for Demo

---

## 🎯 Post-Demo

After successful demo:
```bash
# Stop the app
Ctrl+C in flutter run terminal

# Stop backend
Ctrl+C in backend terminal

# Close emulator (optional)
```

**Well done!** 🎉
