# TCC Agent Client - Quick Reference Guide

## 🚀 Quick Start (5 Minutes)

### Step 1: Install Dependencies
```bash
cd tcc_agent_client
flutter pub get
```

### Step 2: Run the App
```bash
flutter run
```

### Step 3: Test New Features
Navigate to new screens through your existing navigation or manually:
- E-Voting: `/elections`
- Bill Payment: `/bill-payment`
- Edit Profile: `/edit-profile`
- Settings: `/settings`

---

## 📦 What's New - Summary

| Feature | Status | Files | Priority |
|---------|--------|-------|----------|
| E-Voting | ✅ Complete | 4 files | 🔴 Critical |
| Bill Payment | ✅ Complete | 3 files | 🔴 Critical |
| Push Notifications | ✅ Complete | 1 file | 🟠 High |
| Profile Editing | ✅ Complete | 1 file | 🟠 High |
| Settings Enhanced | ✅ Complete | 2 files | 🟠 High |
| WebSocket Service | ✅ Complete | 1 file | 🟠 High |
| **Total** | **14 files** | **~5,000 LOC** | - |

---

## 🗂️ File Locations

### Models
```
lib/models/vote_model.dart
lib/models/bill_payment_model.dart
```

### Voting Screens
```
lib/screens/voting/elections_screen.dart
lib/screens/voting/cast_vote_screen.dart
lib/screens/voting/election_results_screen.dart
```

### Bill Payment Screens
```
lib/screens/bill_payment/bill_payment_screen.dart
lib/screens/bill_payment/bill_payment_form_screen.dart
```

### Profile & Settings
```
lib/screens/profile/edit_profile_screen.dart
lib/screens/settings/settings_screen_enhanced.dart
lib/screens/settings/change_password_screen.dart
```

### Services
```
lib/services/notification_service.dart
lib/services/websocket_service.dart
```

---

## 🔌 Quick Integration Examples

### Add to Navigation
```dart
// In your router file
GoRoute(
  path: '/elections',
  builder: (context, state) => const ElectionsScreen(),
),
GoRoute(
  path: '/bill-payment',
  builder: (context, state) => const BillPaymentScreen(),
),
```

### Initialize Services
```dart
// In main.dart
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize();
  runApp(const MyApp());
}
```

### Use WebSocket
```dart
import 'services/websocket_service.dart';

final ws = WebSocketService();
await ws.connect(
  url: 'wss://api.example.com/ws',
  authToken: yourAuthToken,
);

ws.subscribeToWalletUpdates((data) {
  print('Balance: ${data['balance']}');
});
```

### Use Notifications
```dart
import 'services/notification_service.dart';

final notif = NotificationService();
await notif.initialize();

notif.showNotification(
  title: 'New Order',
  body: 'You have a new payment order',
);
```

---

## 🧪 Testing Commands

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Run on specific device
flutter run -d <device-id>

# Build APK (Android)
flutter build apk --release

# Build iOS
flutter build ios --release

# Clean build
flutter clean && flutter pub get && flutter run
```

---

## 📋 API Endpoints Needed

### E-Voting
```
GET    /api/elections              # List elections
POST   /api/elections/:id/vote     # Cast vote
GET    /api/elections/:id/results  # Get results
```

### Bill Payment
```
GET    /api/bills/categories       # Bill types
POST   /api/bills/pay              # Pay bill
GET    /api/bills/history          # Payment history
```

### Profile
```
GET    /api/agent/profile          # Get profile
PUT    /api/agent/profile          # Update profile
POST   /api/agent/profile/photo    # Upload photo
```

### Settings
```
POST   /api/agent/password/change  # Change password
PUT    /api/agent/settings         # Update settings
POST   /api/agent/fcm-token        # Update FCM token
```

### WebSocket
```
WS     /ws                         # WebSocket endpoint
```

---

## 🔥 Firebase Setup (5 Minutes)

### Android
1. Go to Firebase Console
2. Add Android app
3. Download `google-services.json`
4. Place in `android/app/`

### iOS
1. Add iOS app in Firebase
2. Download `GoogleService-Info.plist`
3. Place in `ios/Runner/`
4. Add to Xcode project

### Initialize
```dart
// main.dart
await Firebase.initializeApp();
```

---

## ✅ Pre-Deployment Checklist

### Code
- [ ] All new files added to navigation
- [ ] Firebase configured
- [ ] API endpoints connected
- [ ] Error handling tested
- [ ] Loading states verified

### Testing
- [ ] Test on Android device
- [ ] Test on iOS device
- [ ] Test all forms
- [ ] Test image uploads
- [ ] Test notifications
- [ ] Test WebSocket connection

### Performance
- [ ] No memory leaks
- [ ] Smooth animations
- [ ] Fast loading times
- [ ] Optimized images

### Security
- [ ] API keys secured
- [ ] Input validation
- [ ] XSS prevention
- [ ] SQL injection prevention

---

## 🐛 Common Issues & Solutions

### Dependencies won't install
```bash
flutter clean
rm -rf pubspec.lock
flutter pub get
```

### Build errors
```bash
cd android && ./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Firebase errors
- Verify `google-services.json` is in `android/app/`
- Verify `GoogleService-Info.plist` is in `ios/Runner/`
- Check package name matches Firebase app

### Navigation errors
- Ensure all routes are registered
- Check import paths
- Verify screen constructors

---

## 📞 Need Help?

### Documentation
1. `SETUP_GUIDE.md` - Detailed setup instructions
2. `IMPLEMENTATION_PROGRESS.md` - What was implemented
3. `FINAL_IMPLEMENTATION_SUMMARY.md` - Complete summary
4. `TCC_DELTA_ITEMS_LIST.md` - All delta items

### Code Comments
All major functions have inline comments explaining their purpose.

### Mock Data
All screens use mock data for testing. Replace with API calls:
```dart
// Before
final elections = mockElections;

// After
final elections = await ApiService().getElections();
```

---

## 🎯 Priority Order for Backend Integration

1. **Authentication** (if not already done)
2. **E-Voting APIs** (high user value)
3. **Bill Payment APIs** (revenue feature)
4. **Push Notifications** (engagement)
5. **WebSocket** (real-time updates)
6. **Profile/Settings** (user management)

---

## 💡 Pro Tips

### Development
- Use hot reload (`r`) for quick UI changes
- Use hot restart (`R`) for logic changes
- Check console for errors

### Testing
- Test on real devices, not just emulators
- Test with poor network conditions
- Test with different screen sizes

### Performance
- Use `const` constructors where possible
- Optimize image sizes before upload
- Implement pagination for long lists

### User Experience
- Always show loading states
- Provide clear error messages
- Add success confirmations

---

## 🎨 Customization

### Colors
Edit `lib/config/app_colors.dart`:
```dart
static const Color primaryOrange = Color(0xFFYOURCOLOR);
```

### Theme
Edit `lib/config/app_theme.dart`:
```dart
// Customize theme settings
```

### Text
Edit screen files directly for labels and messages.

---

## 📱 Screen Previews

### E-Voting
- Elections List: Tabbed view of open/closed elections
- Cast Vote: Radio button selection with confirmation
- Results: Bar charts and percentages

### Bill Payment
- Categories: 2x2 grid of bill types
- Form: Input fields with validation
- Confirmation: Review before payment

### Settings
- Organized sections
- Toggle switches
- Navigation to sub-screens

---

## 🔢 Statistics

- **Files Created**: 14
- **Services**: 2
- **Screens**: 8
- **Models**: 2
- **Dependencies**: 17
- **Lines of Code**: ~5,000
- **Documentation**: 4 files

---

## ⏱️ Time Estimates

| Task | Time |
|------|------|
| Install dependencies | 5 min |
| Add to navigation | 10 min |
| Firebase setup | 15 min |
| Connect 1 API endpoint | 30 min |
| Test feature | 15 min |
| **Total for one feature** | **~1 hour** |

---

## 🚀 Next Steps

1. ✅ Dependencies installed
2. ✅ Features implemented
3. 🔄 Add to navigation → **Do this first**
4. 🔄 Firebase setup → **Do this second**
5. 🔄 Connect APIs → **Do this third**
6. 🔄 Test thoroughly → **Do this fourth**
7. 🔄 Deploy to production → **Final step**

---

*Keep this file bookmarked for quick reference!*
*Last Updated: November 2024*