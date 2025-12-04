# TCC Mobile App - Demo Version

A complete mock implementation of the TCC (The Community Coin) mobile application, ready for client demonstration.

## What's Implemented

This demo app includes fully functional screens with realistic mock data for demonstration purposes.

### Features

✅ **Authentication Flow**
- Login screen with email/password
- Registration with form validation
- OTP verification (6-digit code entry)
- Auto-login after successful registration

✅ **Dashboard**
- Welcome screen with user greeting
- TCC Coin balance card
- Total invested and expected returns
- Quick action buttons
- Investment category cards (Agriculture, Minerals, Education)

✅ **Portfolio Management**
- Investment portfolio overview
- Individual investment cards with details
- ROI display and progress tracking
- Days remaining counter
- Total invested vs expected returns summary

✅ **Transaction History**
- Complete transaction list with filters
- Tabs: All, Successful, Pending
- Transaction details: amount, status, date, recipient
- Color-coded transaction types
- Status indicators

✅ **Account/Profile**
- User profile display
- KYC verification status badge
- Settings sections (Account, Preferences, Support)
- Bank account management option
- Security settings
- Notification toggle
- Logout functionality

### Mock Data Included

- **User Profile**: Andrew Johnson (verified user)
- **Wallet Balance**: Le 34,000.00 (SLL)
- **3 Active Investments**:
  - Agriculture: Le 2,000 (12% ROI)
  - Gold Investment: Le 5,000 (15% ROI)
  - Education Fund: Le 3,000 (10% ROI)
- **5 Recent Transactions**: Mix of deposits, investments, bills, transfers
- **Investment Products**: 3 fixed-return products (Lot, Plot, Farm)

## Quick Start

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- iOS Simulator (Mac only) or Android Emulator

### Installation

1. **Navigate to the project directory**

```bash
cd tcc_user_mobile_client
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Run the app**

```bash
# iOS Simulator
flutter run -d ios

# Android Emulator
flutter run -d android

# Chrome (for web testing)
flutter run -d chrome
```

## Demo Flow for Client Presentation

### 1. Authentication Demo (2 minutes)

**Login:**
- Email: Any valid email
- Password: Any password (min 8 characters)
- Click "Sign In"

**Register:**
- Click "Register" link
- Fill in:
  - First Name: John
  - Last Name: Doe
  - Email: john@example.com
  - Phone: +232 XX XXX XXXX
  - Password: (min 8 characters)
- Click "Create Account"

**OTP Verification:**
- Enter any 6-digit code (e.g., 123456)
- Click "Verify" or it auto-submits

### 2. Dashboard Tour (3 minutes)

**Show:**
- Personalized welcome message
- TCC Coin balance card
- Investment stats (Total Invested, Expected Returns)
- "Add Money" button (currently demo)
- Investment categories (Agriculture, Minerals, Education)
- Bottom navigation bar

### 3. Portfolio Demo (2 minutes)

**Navigate to Portfolio tab:**
- Show portfolio summary card
- Scroll through active investments
- Point out:
  - Investment names and categories
  - Amount invested and expected returns
  - ROI percentage badges
  - Progress bars and days left
  - Active investment count

### 4. Transactions Demo (2 minutes)

**Navigate to Transactions tab:**
- Show "All Transactions" view
- Switch to "Successful" tab
- Switch to "Pending" tab
- Point out:
  - Transaction types (deposit, withdrawal, transfer, etc.)
  - Status indicators
  - Date and time stamps
  - Recipient information
  - Amount formatting (Le XXX)

### 5. Account Settings Demo (1 minute)

**Navigate to Account tab:**
- Show user profile card
- Show KYC verification badge
- Scroll through settings sections:
  - Account Settings
  - Preferences (with notification toggle)
  - Support options
- Demonstrate logout functionality

## Demo Tips

### For Smooth Presentation

1. **Start Fresh**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Use iOS Simulator** (if available) for better visual appeal

3. **Enable Hot Reload**: Press `r` in terminal to refresh during demo

4. **Landscape Support**: Rotate device to show responsive design

5. **Navigation Flow**:
   - Start at login
   - Show registration (don't complete)
   - Go back and login
   - Tour all 4 main tabs
   - Show logout

### Key Selling Points

✨ **User Experience**
- Clean, modern design following Material Design 3
- Smooth animations and transitions
- Intuitive navigation
- Consistent color scheme (Blue primary, Yellow/Green accents)

✨ **Security**
- Multi-step authentication
- OTP verification
- KYC verification system
- Secure logout

✨ **Functionality**
- Complete investment tracking
- Transaction history with filters
- Real-time balance updates (mocked)
- Comprehensive account management

## Technical Details

### Architecture

```
lib/
├── config/             # Theme, colors, constants
├── models/             # Data models (User, Investment, Transaction)
├── providers/          # State management (Auth Provider)
├── screens/            # UI screens
│   ├── auth/           # Login, Register, OTP
│   ├── dashboard/      # Home, Portfolio, Transactions, Navigation
│   └── profile/        # Account settings
├── services/           # Mock data service
└── main.dart           # App entry point
```

### Technologies

- **Framework**: Flutter 3.9.2+
- **State Management**: Provider
- **Navigation**: go_router
- **Charts**: fl_chart (ready for investment charts)
- **OTP Input**: pin_code_fields
- **Formatting**: intl (currency, date formatting)

### Design System

**Colors:**
- Primary: #5B6EF5 (Blue)
- Secondary: #F9B234 (Yellow)
- Success: #00C896 (Green)
- Error: #FF5757 (Red)

**Typography:**
- Font Family: Inter (system default)
- Sizes: 12px - 32px
- Weights: 400, 600, 700

**Components:**
- Cards: 16px border radius
- Buttons: 12px border radius
- Inputs: 12px border radius, filled style

## Customization for Demo

### Change User Data

Edit `lib/services/mock_data_service.dart`:

```dart
factory UserModel.mock() {
  return UserModel(
    firstName: 'Your Name',
    lastName: 'Last Name',
    email: 'your.email@example.com',
    // ... other fields
  );
}
```

### Add More Investments

In `mock_data_service.dart`, add to `userInvestments` list:

```dart
InvestmentModel(
  name: 'New Investment',
  category: 'AGRICULTURE',
  amount: 1000.00,
  roi: 15.0,
  // ... other fields
)
```

### Add More Transactions

In `mock_data_service.dart`, add to `recentTransactions` list:

```dart
TransactionModel(
  type: 'DEPOSIT',
  amount: 5000.00,
  status: 'COMPLETED',
  // ... other fields
)
```

## Known Demo Limitations

🔸 **Mock Data Only**: All data is hardcoded, no API integration
🔸 **No Persistence**: Data resets on app restart
🔸 **Demo Logins**: Any credentials work for login
🔸 **OTP**: Any 6-digit code accepted
🔸 **Action Buttons**: Some buttons show "Coming soon" messages
🔸 **Charts**: Investment charts not yet implemented
🔸 **File Uploads**: Document upload UI not functional

## Next Steps for Production

To convert this to a production-ready app:

1. **Backend Integration**
   - Connect to TCC Backend API (already set up in `tcc_backend/`)
   - Replace MockDataService with real API calls
   - Add HTTP client (dio or http package)

2. **State Management Enhancement**
   - Add more providers (Wallet, Investment, Transaction)
   - Implement proper error handling
   - Add loading states

3. **Security**
   - Implement secure storage (flutter_secure_storage)
   - Add biometric authentication
   - Implement proper token management

4. **Features**
   - Complete investment flow (Fixed & Variable returns)
   - Payment integration (Mobile money, Bank transfers)
   - Bill payment system
   - E-voting functionality
   - Push notifications
   - Real-time updates (WebSocket)

5. **Testing**
   - Unit tests for business logic
   - Widget tests for UI components
   - Integration tests for user flows

6. **Deployment**
   - App Store submission (iOS)
   - Play Store submission (Android)
   - Code signing and certificates

## Troubleshooting

### Common Issues

**Issue**: Dependencies not installing
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

**Issue**: Build errors
```bash
cd ios && pod install && cd ..
flutter clean
flutter run
```

**Issue**: Hot reload not working
- Press `R` (capital R) for full restart

### Support

For demo-related questions or issues:
- Check logs: `flutter logs`
- Verbose mode: `flutter run -v`
- Clear cache: `flutter clean`

## Demo Checklist

Before presenting to client:

- [ ] App runs without errors
- [ ] All screens load correctly
- [ ] Navigation works smoothly
- [ ] Bottom nav bar switches tabs
- [ ] Login flow works
- [ ] OTP screen accepts input
- [ ] Dashboard shows all data
- [ ] Portfolio displays investments
- [ ] Transactions list loads
- [ ] Account settings accessible
- [ ] Logout works properly
- [ ] Device looks good (charge, volume off, notifications off)

## Screenshots Reference

Reference designs available in: `image/Onboarding and dashboard/`
- Login: Android Large - 11.png
- Register: Android Large - 12.png
- OTP: Android Large - 13.png
- Dashboard: Android Large - 142.png
- Portfolio: Android Large - 143.png
- Transactions: Android Large - 144.png

---

**Demo Version**: 1.0.0
**Last Updated**: October 26, 2025
**Status**: Ready for Client Presentation ✅

Happy Demoing! 🚀
