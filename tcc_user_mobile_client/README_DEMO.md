# TCC User Mobile Client - Ready for Demo! 🚀

**Status:** ✅ Configured and ready for client demo

## Quick Start (3 Steps)

### 1. Start Backend
```bash
# Make sure your backend is running on port 3000
npm start
```

### 2. Run the App
```bash
flutter run
```

### 3. Sign In
The app will automatically connect to your local backend!

---

## 📚 Documentation

Choose based on your needs:

| Document | Use When |
|----------|----------|
| **[DEMO_QUICK_REFERENCE.md](DEMO_QUICK_REFERENCE.md)** | 📱 **Demo day** - Essential commands & checklist |
| **[DEMO_SETUP.md](DEMO_SETUP.md)** | 🔧 **First-time setup** - Detailed configuration guide |
| **[DEBUG_SIGNIN.md](DEBUG_SIGNIN.md)** | 🐛 **Sign-in issues** - Comprehensive debugging |
| **[CHANGES_SUMMARY.md](CHANGES_SUMMARY.md)** | 📝 **Technical details** - What was changed and why |

---

## 🎯 What's Been Fixed

✅ **Backend Connection:** Automatically uses correct URL for emulator (`http://10.0.2.2:3000/v1`)

✅ **Authentication:** Fixed initialization issue - stored tokens now load properly

✅ **Logging:** Comprehensive logs added throughout sign-in flow

✅ **Documentation:** Complete guides for setup, demo, and debugging

---

## 🔧 Helper Scripts

```bash
./view_logs.sh          # View filtered authentication logs
./configure_backend.sh  # Configure backend URL (if needed)
```

---

## ⚡ TL;DR for Demo Day

1. Backend running? ✓
2. Run: `flutter run` ✓
3. Sign in with test credentials ✓
4. Done! 🎉

**See [DEMO_QUICK_REFERENCE.md](DEMO_QUICK_REFERENCE.md) for complete demo checklist.**

---

## 🆘 Something Not Working?

1. Check backend is running: `curl http://localhost:3000/v1`
2. View logs: `./view_logs.sh`
3. See [DEBUG_SIGNIN.md](DEBUG_SIGNIN.md) for solutions

---

## 📱 Platform Support

| Platform | Status | Backend URL |
|----------|--------|-------------|
| Android Emulator | ✅ Auto-configured | `http://10.0.2.2:3000/v1` |
| iOS Simulator | ✅ Auto-configured | `http://127.0.0.1:3000/v1` |
| Physical Device | ⚙️ Manual setup needed | See [DEMO_SETUP.md](DEMO_SETUP.md) |

---

## 🎬 Need Help?

- **Before demo:** Read [DEMO_SETUP.md](DEMO_SETUP.md)
- **Demo day:** Use [DEMO_QUICK_REFERENCE.md](DEMO_QUICK_REFERENCE.md)
- **Issues:** Check [DEBUG_SIGNIN.md](DEBUG_SIGNIN.md)
- **Technical details:** See [CHANGES_SUMMARY.md](CHANGES_SUMMARY.md)

---

**Everything is ready! Good luck with your demo!** 🎉
