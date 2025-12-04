# TCC Mobile App - APK Sharing Instructions

## ✅ APK Build Successful!

Your APK has been successfully built and is ready to share.

## 📱 APK Details

- **File Name:** `app-release.apk`
- **File Size:** 54 MB
- **Location:** `/Users/shubham/Documents/playground/tcc/tcc_user_mobile_client/build/app/outputs/flutter-apk/app-release.apk`

## 📤 How to Share the APK

### Option 1: Direct File Transfer
1. Navigate to the folder: `build/app/outputs/flutter-apk/`
2. Find the file: `app-release.apk`
3. Share via:
   - AirDrop (for nearby devices)
   - Email (as attachment)
   - Google Drive/Dropbox
   - WhatsApp/Telegram
   - USB cable transfer

### Option 2: Using Terminal (Quick Copy)
```bash
# Copy to Desktop
cp build/app/outputs/flutter-apk/app-release.apk ~/Desktop/TCC-Mobile-App.apk

# Copy to Downloads
cp build/app/outputs/flutter-apk/app-release.apk ~/Downloads/TCC-Mobile-App.apk
```

## 📥 Installation Instructions for Your Friend

### Before Installing:
1. **Enable Unknown Sources** on Android device:
   - Go to Settings → Security
   - Enable "Unknown sources" or "Install unknown apps"
   - For Android 8.0+: Settings → Apps & notifications → Advanced → Special app access → Install unknown apps

### Installation Steps:
1. Download the APK file to the Android device
2. Open the file manager and locate the APK
3. Tap on `app-release.apk`
4. Review permissions and tap "Install"
5. Wait for installation to complete
6. Tap "Open" to launch the app

### ⚠️ Important Notes:
- This APK works on Android devices only (Android 5.0+)
- The app is not signed with a production certificate
- Your friend may see a security warning - this is normal for test APKs
- The app requires internet connection for full functionality

## 🔄 Building Different APK Types

### For Smaller File Size (Split APKs):
```bash
flutter build apk --split-per-abi
```
This creates separate APKs for different architectures (arm64, armeabi-v7a, x86_64)

### For App Bundle (Recommended for Play Store):
```bash
flutter build appbundle
```

## 🧪 Testing Features
Once installed, your friend can test:
- User registration and login
- Investment products browsing
- Portfolio management
- Transaction history
- Bill payments
- Dark mode support
- Share transaction receipts (newly added!)

## 📱 Device Requirements
- Android 5.0 (API level 21) or higher
- At least 100 MB free storage
- Internet connection for API calls

## 🐛 Troubleshooting

### If installation fails:
1. Check if enough storage space is available
2. Ensure "Unknown sources" is enabled
3. Try downloading the APK again
4. Clear Google Play Protect cache if it blocks installation

### If app crashes:
1. Clear app cache and data
2. Reinstall the APK
3. Check Android version compatibility

---

**Happy Testing! 🎉**

For any issues, check the debug logs using:
```bash
adb logcat | grep flutter
```