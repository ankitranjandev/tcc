# Quick Start Guide - API Integration

## Installation

```bash
cd tcc_user_mobile_client
flutter pub get
```

## Initialization

Add to your `main.dart`:

```dart
import 'package:tcc_user_mobile_client/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API service (loads stored tokens)
  final apiService = ApiService();
  await apiService.initialize();

  runApp(MyApp());
}
```

## Basic Usage Examples

### 1. Login

```dart
import 'package:tcc_user_mobile_client/services/auth_service.dart';

final authService = AuthService();

// Login
final result = await authService.login(
  phoneNumber: '+1234567890',
  password: 'YourPassword123',
);

if (result['success']) {
  // Tokens automatically stored
  final user = result['data']['user'];
  print('Welcome ${user['fullName']}');
  Navigator.pushReplacementNamed(context, '/home');
} else {
  showError(result['error']);
}
```

### 2. Get Wallet Balance

```dart
import 'package:tcc_user_mobile_client/services/wallet_service.dart';

final walletService = WalletService();

final result = await walletService.getBalance();

if (result['success']) {
  final balance = result['data']['balance'];
  print('Balance: Le $balance');
} else {
  showError(result['error']);
}
```

### 3. Create Investment

```dart
import 'package:tcc_user_mobile_client/services/investment_service.dart';

final investmentService = InvestmentService();

// First, calculate expected returns
final returnsResult = await investmentService.calculateReturns(
  categoryId: 'category_id_here',
  amount: 10000.0,
  tenureMonths: 12,
);

if (returnsResult['success']) {
  final expectedReturn = returnsResult['data']['expectedReturn'];
  print('Expected return: Le $expectedReturn');

  // If user confirms, create investment
  final createResult = await investmentService.createInvestment(
    categoryId: 'category_id_here',
    amount: 10000.0,
    tenureMonths: 12,
  );

  if (createResult['success']) {
    print('Investment created successfully');
  }
}
```

### 4. Pay Bill

```dart
import 'package:tcc_user_mobile_client/services/bill_service.dart';

final billService = BillService();

// Step 1: Fetch bill details
final detailsResult = await billService.fetchBillDetails(
  providerId: 'provider_id',
  accountNumber: '1234567890',
);

if (detailsResult['success']) {
  final amount = detailsResult['data']['amount'];

  // Step 2: Request OTP
  final otpResult = await billService.requestPaymentOTP(
    providerId: 'provider_id',
    accountNumber: '1234567890',
    amount: amount,
  );

  if (otpResult['success']) {
    // Step 3: Show OTP input, then pay
    final payResult = await billService.payBill(
      providerId: 'provider_id',
      accountNumber: '1234567890',
      amount: amount,
      otp: userEnteredOtp,
    );

    if (payResult['success']) {
      print('Bill paid successfully');
    }
  }
}
```

### 5. Transfer Money

```dart
import 'package:tcc_user_mobile_client/services/wallet_service.dart';

final walletService = WalletService();

// Step 1: Request OTP
final otpResult = await walletService.requestTransferOTP(
  recipientPhoneNumber: '+9876543210',
  amount: 1000.0,
);

if (otpResult['success']) {
  // Step 2: Show OTP input, then transfer
  final transferResult = await walletService.transfer(
    recipientPhoneNumber: '+9876543210',
    amount: 1000.0,
    otp: userEnteredOtp,
    note: 'Payment for services',
  );

  if (transferResult['success']) {
    print('Transfer completed successfully');
  }
}
```

## Error Handling Pattern

```dart
Future<void> loadData() async {
  setState(() => isLoading = true);

  try {
    final result = await service.getData();

    if (result['success']) {
      setState(() {
        data = result['data'];
        isLoading = false;
        error = null;
      });
    } else {
      setState(() {
        error = result['error'];
        isLoading = false;
      });

      // Handle session expiration
      if (result['error'].contains('Session expired')) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  } catch (e) {
    setState(() {
      error = 'An unexpected error occurred';
      isLoading = false;
    });
  }
}
```

## UI Integration Pattern

```dart
class WalletScreen extends StatefulWidget {
  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final walletService = WalletService();
  bool isLoading = true;
  String? error;
  double balance = 0.0;

  @override
  void initState() {
    super.initState();
    loadBalance();
  }

  Future<void> loadBalance() async {
    setState(() => isLoading = true);

    final result = await walletService.getBalance();

    if (result['success']) {
      setState(() {
        balance = result['data']['balance'];
        isLoading = false;
      });
    } else {
      setState(() {
        error = result['error'];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error!),
            ElevatedButton(
              onPressed: loadBalance,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Text('Balance: Le $balance'),
        // ... rest of UI
      ],
    );
  }
}
```

## Available Services

```dart
// Import services as needed
import 'package:tcc_user_mobile_client/services/api_service.dart';
import 'package:tcc_user_mobile_client/services/auth_service.dart';
import 'package:tcc_user_mobile_client/services/wallet_service.dart';
import 'package:tcc_user_mobile_client/services/transaction_service.dart';
import 'package:tcc_user_mobile_client/services/investment_service.dart';
import 'package:tcc_user_mobile_client/services/bill_service.dart';
import 'package:tcc_user_mobile_client/services/agent_service.dart';
import 'package:tcc_user_mobile_client/services/kyc_service.dart';
import 'package:tcc_user_mobile_client/services/bank_service.dart';
```

## Configuration

### Development (Default)
```dart
// lib/config/app_constants.dart
static const String baseUrl = 'http://localhost:3000/v1';
```

### Production
Update `app_constants.dart` before deployment:
```dart
static const String baseUrl = 'https://api.yourdomain.com/v1';
```

## Testing

### 1. Test Authentication
```bash
# In your backend terminal
cd tcc_backend
npm run dev
```

```dart
// In your Flutter app
final authService = AuthService();
final result = await authService.login(
  phoneNumber: 'test_user_phone',
  password: 'test_password',
);
print(result);
```

### 2. Test API Connection
```dart
final apiService = ApiService();
try {
  final result = await apiService.get('/health', requiresAuth: false);
  print('API is reachable: $result');
} catch (e) {
  print('API error: $e');
}
```

## Common Issues

### Issue: "Network error"
**Solution:** Check backend is running on localhost:3000

### Issue: "Session expired"
**Solution:** Tokens expired, redirect to login:
```dart
if (error.contains('Session expired')) {
  Navigator.pushReplacementNamed(context, '/login');
}
```

### Issue: "Validation error"
**Solution:** Check request parameters match backend expectations

### Issue: HTTP package not found
**Solution:** Run `flutter pub get`

## Response Format

All services return this format:
```dart
{
  'success': true/false,
  'data': {...},      // on success
  'error': 'message'  // on failure
}
```

## Need Help?

1. **Detailed Documentation:** See `API_INTEGRATION_GUIDE.md`
2. **Endpoint Reference:** See `API_ENDPOINTS_REFERENCE.md`
3. **Overview:** See `API_INTEGRATION_SUMMARY.md`

## Tips

- Always check `result['success']` before accessing data
- Handle session expiration by redirecting to login
- Show loading indicators during API calls
- Display user-friendly error messages
- Use try-catch for unexpected errors
- Test with backend running on localhost:3000
- Update base URL before production deployment
