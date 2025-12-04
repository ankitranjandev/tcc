# TCC Agent Client - Setup Guide for New Features

## Quick Start

### Step 1: Install Dependencies
```bash
cd tcc_agent_client
flutter pub get
```

### Step 2: Run the App
```bash
flutter run
```

---

## 🎯 New Features Added

### 1. E-Voting Module ✅
### 2. Bill Payment Module ✅

---

## 📦 Dependencies Added

All dependencies have been added to `pubspec.yaml`. Run `flutter pub get` to install them.

### New Packages:
- **Firebase** (Push notifications, Analytics, Crashlytics)
- **WebSocket** (Real-time features)
- **SQLite** (Offline support)
- **Country Picker** (International phone numbers)
- **QR Code** (Scanner and generator)
- **Biometrics** (Fingerprint/Face ID)
- **And more...**

---

## 🔌 Integration Steps

### Add E-Voting to Navigation

**Option 1: Add to Bottom Navigation** (Recommended)

Update `lib/screens/dashboard/main_navigation.dart`:
```dart
// Add voting icon to bottom nav
BottomNavigationBarItem(
  icon: Icon(Icons.how_to_vote),
  label: 'Voting',
),
```

Add routing in the body:
```dart
import 'package:tcc_agent_client/screens/voting/elections_screen.dart';

// In the indexed stack
const ElectionsScreen(),
```

**Option 2: Add to Dashboard Quick Actions**

Update `lib/screens/dashboard/dashboard_home_screen.dart`:
```dart
import '../voting/elections_screen.dart';

// Add to quick actions
_buildQuickAction(
  context,
  'Voting',
  Icons.how_to_vote,
  () => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const ElectionsScreen()),
  ),
),
```

### Add Bill Payment to Navigation

**Update Dashboard Quick Actions**:
```dart
import '../bill_payment/bill_payment_screen.dart';

_buildQuickAction(
  context,
  'Bill Payment',
  Icons.receipt_long,
  () => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const BillPaymentScreen()),
  ),
),
```

### Update Go Router (if using declarative routing)

Add to `lib/config/router.dart` or wherever routes are defined:
```dart
GoRoute(
  path: '/elections',
  name: 'elections',
  builder: (context, state) => const ElectionsScreen(),
),
GoRoute(
  path: '/bill-payment',
  name: 'billPayment',
  builder: (context, state) => const BillPaymentScreen(),
),
```

---

## 🔥 Firebase Setup (For Push Notifications)

### Android Setup

1. **Create Firebase Project** at https://console.firebase.google.com

2. **Add Android App** to project
   - Package name: `com.example.tcc_agent_client` (or your actual package name)

3. **Download `google-services.json`**
   - Place in: `android/app/google-services.json`

4. **Update `android/build.gradle`**:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

5. **Update `android/app/build.gradle`**:
```gradle
// At the bottom of the file
apply plugin: 'com.google.gms.google-services'
```

### iOS Setup

1. **Add iOS App** to Firebase project
   - Bundle ID: `com.example.tccAgentClient` (or your actual bundle ID)

2. **Download `GoogleService-Info.plist`**
   - Place in: `ios/Runner/GoogleService-Info.plist`
   - Add to Xcode project

3. **Update `ios/Runner/Info.plist`** for notifications

### Initialize Firebase

Update `lib/main.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  runApp(const MyApp());
}
```

---

## 🧪 Testing the New Features

### Test E-Voting Module

1. Run the app
2. Navigate to Elections screen (via navigation you added)
3. You should see:
   - **Open Elections tab** with 2 mock elections
   - **Closed Elections tab** with 1 mock election
4. Click on an open election (not marked as "Voted")
5. Select an option and click "Cast Vote"
6. Confirm in the dialog
7. See success message

### Test Bill Payment Module

1. Run the app
2. Navigate to Bill Payment screen
3. You should see:
   - 4 bill categories (Water, Electricity, DSTV, Others)
   - Recent payments section
4. Click on "Water Bill" or "Electricity Bill"
5. Fill in the form:
   - Bill ID: any text
   - Name: any text
   - Amount: any number > 0
6. Select a payment method
7. Click "Proceed to Payment"
8. Confirm in the dialog
9. See success message

---

## 🔍 Troubleshooting

### Dependencies Not Installing
```bash
flutter clean
flutter pub get
```

### Build Errors
```bash
cd android && ./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Firebase Errors
- Make sure `google-services.json` is in `android/app/`
- Make sure `GoogleService-Info.plist` is in `ios/Runner/`
- Run `flutter clean` and rebuild

### Import Errors
Make sure all new files are in the correct folders:
```
lib/
├── models/
│   ├── vote_model.dart
│   └── bill_payment_model.dart
└── screens/
    ├── voting/
    │   ├── elections_screen.dart
    │   ├── cast_vote_screen.dart
    │   └── election_results_screen.dart
    └── bill_payment/
        ├── bill_payment_screen.dart
        └── bill_payment_form_screen.dart
```

---

## 📋 Next Steps After Setup

### 1. Connect to Backend API

Replace mock data with real API calls in:
- `lib/screens/voting/elections_screen.dart` - Fetch elections from API
- `lib/screens/voting/cast_vote_screen.dart` - Submit vote to API
- `lib/screens/bill_payment/bill_payment_screen.dart` - Fetch recent payments
- `lib/screens/bill_payment/bill_payment_form_screen.dart` - Submit payment to API

### 2. Add API Endpoints

Create these endpoints in your backend:
```
GET  /api/elections                    - List all elections
GET  /api/elections/:id                - Get election details
POST /api/elections/:id/vote           - Cast a vote
GET  /api/elections/:id/results        - Get election results

POST /api/bills/pay                    - Process bill payment
GET  /api/bills/history                - Get payment history
GET  /api/bills/categories             - Get available bill categories
```

### 3. Update Models

If your backend API structure is different, update:
- `lib/models/vote_model.dart`
- `lib/models/bill_payment_model.dart`

### 4. Add Error Handling

Implement proper error handling for:
- Network errors
- API errors
- Validation errors

### 5. Add Loading States

Improve UX with better loading indicators and skeleton screens.

---

## 🎨 Customization

### Change Colors

Update `lib/config/app_colors.dart`:
```dart
static const Color primaryOrange = Color(0xFFFF7043); // Your brand color
```

### Change Text

Update screen titles and labels directly in the screen files.

### Add More Bill Categories

Update `lib/models/bill_payment_model.dart`:
```dart
BillCategory(
  type: 'internet',
  name: 'Internet Bill',
  icon: '🌐',
  description: 'Pay for internet services',
),
```

---

## 📊 Feature Flags (Optional)

To gradually roll out features, you can add feature flags:

```dart
class FeatureFlags {
  static const bool enableVoting = true;
  static const bool enableBillPayment = true;
}

// In your navigation code
if (FeatureFlags.enableVoting) {
  // Show voting option
}
```

---

## 🚀 Deployment Checklist

Before deploying to production:

- [ ] Replace all mock data with real API calls
- [ ] Add proper error handling
- [ ] Test on real devices (iOS and Android)
- [ ] Set up Firebase for production
- [ ] Configure proper API URLs (not localhost)
- [ ] Add analytics tracking
- [ ] Test payment flows thoroughly
- [ ] Test voting flows thoroughly
- [ ] Add loading states everywhere
- [ ] Add offline support (optional)
- [ ] Performance testing
- [ ] Security audit

---

## 📞 Support

If you encounter any issues:
1. Check this guide first
2. Review error messages carefully
3. Check Flutter and Firebase documentation
4. Ensure all dependencies are correctly installed

---

## 📝 Summary

You now have:
- ✅ **Complete E-Voting Module** with 3 screens
- ✅ **Complete Bill Payment Module** with 2 screens
- ✅ **All necessary dependencies** added
- ✅ **Beautiful UI/UX** ready to use
- ✅ **Firebase integration** ready
- ✅ **Mock data** for testing

What you need to do:
1. Run `flutter pub get`
2. Add screens to navigation
3. Test the features
4. Connect to backend API
5. Deploy!

**Estimated time to production: 1-2 weeks** (with backend integration)

---

*Happy coding! 🎉*