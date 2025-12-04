# TCC User Mobile Client - API Integration Guide

## Overview

A complete API integration layer has been built for the TCC User Mobile Client. The app now has full backend connectivity to replace all mock data.

## Files Created

### Configuration
- **`lib/config/app_constants.dart`** - Application-wide constants including API configuration, error messages, validation rules, and status codes

### Core Services
1. **`lib/services/api_service.dart`** - HTTP client singleton with token management
2. **`lib/services/auth_service.dart`** - Authentication and user profile management
3. **`lib/services/wallet_service.dart`** - Wallet operations (deposit, withdraw, transfer)
4. **`lib/services/transaction_service.dart`** - Transaction history and statistics
5. **`lib/services/investment_service.dart`** - Investment portfolio management
6. **`lib/services/bill_service.dart`** - Bill payment services
7. **`lib/services/agent_service.dart`** - Agent discovery and reviews
8. **`lib/services/kyc_service.dart`** - KYC document submission
9. **`lib/services/bank_service.dart`** - Bank account management

### Dependencies Added
- **`http: ^1.1.0`** - HTTP client for API calls

## Architecture

### Singleton Pattern
All services use the `ApiService` singleton for HTTP operations, ensuring consistent:
- Token management
- Error handling
- Request/response formatting
- Timeout handling (30 seconds)

### Response Format
All service methods return a standardized response:
```dart
{
  'success': true/false,
  'data': {...},      // on success
  'error': 'message'  // on failure
}
```

### Error Handling
The API service includes custom exceptions:
- **`ApiException`** - General API errors
- **`UnauthorizedException`** - 401 errors (token expired)
- **`ValidationException`** - 422 errors (validation failures)

## Service Details

### 1. API Service (`api_service.dart`)

**Base Configuration:**
- Base URL: `http://localhost:3000/v1`
- Timeout: 30 seconds
- Automatic token management

**Methods:**
- `initialize()` - Load stored tokens
- `setTokens(token, refreshToken)` - Store authentication tokens
- `clearTokens()` - Clear stored tokens
- `get(endpoint, {queryParams, requiresAuth})` - HTTP GET
- `post(endpoint, {body, requiresAuth})` - HTTP POST
- `put(endpoint, {body, requiresAuth})` - HTTP PUT
- `patch(endpoint, {body, requiresAuth})` - HTTP PATCH
- `delete(endpoint, {requiresAuth})` - HTTP DELETE
- `uploadFile(endpoint, filePath, fieldName, {additionalFields, requiresAuth})` - Multipart file upload

**Usage Example:**
```dart
final apiService = ApiService();
await apiService.initialize();

// Make authenticated request
final response = await apiService.get('/users/profile', requiresAuth: true);

// Make public request
final response = await apiService.post('/auth/login',
  body: {'phoneNumber': '+123456789', 'password': 'password'},
  requiresAuth: false
);
```

### 2. Auth Service (`auth_service.dart`)

**Endpoints:**
- `register()` - POST `/auth/register`
- `verifyOTP()` - POST `/auth/verify-otp`
- `login()` - POST `/auth/login`
- `resendOTP()` - POST `/auth/resend-otp`
- `forgotPassword()` - POST `/auth/forgot-password`
- `resetPassword()` - POST `/auth/reset-password`
- `refreshToken()` - POST `/auth/refresh`
- `logout()` - POST `/auth/logout`
- `getProfile()` - GET `/users/profile`
- `updateProfile()` - PATCH `/users/profile`
- `changePassword()` - POST `/users/change-password`

**Usage Example:**
```dart
final authService = AuthService();

// Register new user
final result = await authService.register(
  fullName: 'John Doe',
  email: 'john@example.com',
  phoneNumber: '+1234567890',
  password: 'SecurePass123',
);

if (result['success']) {
  print('Registration successful');
} else {
  print('Error: ${result['error']}');
}

// Login
final loginResult = await authService.login(
  phoneNumber: '+1234567890',
  password: 'SecurePass123',
);

// Get profile
final profileResult = await authService.getProfile();
```

### 3. Wallet Service (`wallet_service.dart`)

**Endpoints:**
- `getBalance()` - GET `/wallet/balance`
- `deposit()` - POST `/wallet/deposit`
- `requestWithdrawalOTP()` - POST `/wallet/withdraw/request-otp`
- `withdraw()` - POST `/wallet/withdraw`
- `requestTransferOTP()` - POST `/wallet/transfer/request-otp`
- `transfer()` - POST `/wallet/transfer`

**Usage Example:**
```dart
final walletService = WalletService();

// Get balance
final balanceResult = await walletService.getBalance();

// Deposit money
final depositResult = await walletService.deposit(
  amount: 1000.0,
  paymentMethod: 'agent',
  agentId: 'agent_123',
);

// Request withdrawal OTP
final otpResult = await walletService.requestWithdrawalOTP(
  amount: 500.0,
  withdrawalMethod: 'bank',
  bankAccountId: 'bank_123',
);

// Withdraw with OTP
final withdrawResult = await walletService.withdraw(
  amount: 500.0,
  withdrawalMethod: 'bank',
  otp: '123456',
  bankAccountId: 'bank_123',
);

// Transfer to another user
final transferResult = await walletService.transfer(
  recipientPhoneNumber: '+9876543210',
  amount: 250.0,
  otp: '123456',
  note: 'Payment for services',
);
```

### 4. Transaction Service (`transaction_service.dart`)

**Endpoints:**
- `getTransactionHistory()` - GET `/transactions/history`
- `getTransactionDetails()` - GET `/transactions/:id`
- `getTransactionStats()` - GET `/transactions/stats`
- `downloadReceipt()` - GET `/transactions/:id/receipt`

**Usage Example:**
```dart
final transactionService = TransactionService();

// Get transaction history with filters
final historyResult = await transactionService.getTransactionHistory(
  type: 'deposit',
  status: 'completed',
  startDate: '2024-01-01',
  endDate: '2024-12-31',
  page: 1,
  limit: 20,
);

// Get transaction details
final detailsResult = await transactionService.getTransactionDetails(
  transactionId: 'txn_123',
);

// Get statistics
final statsResult = await transactionService.getTransactionStats(
  period: 'month',
);

// Download receipt
final receiptResult = await transactionService.downloadReceipt(
  transactionId: 'txn_123',
);
```

### 5. Investment Service (`investment_service.dart`)

**Endpoints:**
- `getCategories()` - GET `/investments/categories`
- `createInvestment()` - POST `/investments`
- `getPortfolio()` - GET `/investments/portfolio`
- `getInvestmentDetails()` - GET `/investments/:id`
- `requestTenureChange()` - POST `/investments/:id/request-tenure-change`
- `getWithdrawalPenalty()` - GET `/investments/:id/withdrawal-penalty`
- `withdrawInvestment()` - POST `/investments/:id/withdraw`
- `calculateReturns()` - GET `/investments/calculate-returns`

**Usage Example:**
```dart
final investmentService = InvestmentService();

// Get investment categories
final categoriesResult = await investmentService.getCategories();

// Calculate expected returns
final returnsResult = await investmentService.calculateReturns(
  categoryId: 'cat_123',
  amount: 10000.0,
  tenureMonths: 12,
);

// Create investment
final createResult = await investmentService.createInvestment(
  categoryId: 'cat_123',
  amount: 10000.0,
  tenureMonths: 12,
);

// Get portfolio
final portfolioResult = await investmentService.getPortfolio(
  status: 'active',
  page: 1,
  limit: 10,
);

// Request tenure change
final changeResult = await investmentService.requestTenureChange(
  investmentId: 'inv_123',
  newTenureMonths: 18,
);

// Get withdrawal penalty
final penaltyResult = await investmentService.getWithdrawalPenalty(
  investmentId: 'inv_123',
);

// Withdraw investment
final withdrawResult = await investmentService.withdrawInvestment(
  investmentId: 'inv_123',
  acceptPenalty: true,
);
```

### 6. Bill Service (`bill_service.dart`)

**Endpoints:**
- `getProviders()` - GET `/bills/providers`
- `fetchBillDetails()` - POST `/bills/fetch-details`
- `requestPaymentOTP()` - POST `/bills/request-otp`
- `payBill()` - POST `/bills/pay`
- `getBillHistory()` - GET `/bills/history`

**Usage Example:**
```dart
final billService = BillService();

// Get providers by category
final providersResult = await billService.getProviders(
  category: 'electricity',
);

// Fetch bill details
final detailsResult = await billService.fetchBillDetails(
  providerId: 'provider_123',
  accountNumber: '1234567890',
);

// Request payment OTP
final otpResult = await billService.requestPaymentOTP(
  providerId: 'provider_123',
  accountNumber: '1234567890',
  amount: 5000.0,
);

// Pay bill with OTP
final paymentResult = await billService.payBill(
  providerId: 'provider_123',
  accountNumber: '1234567890',
  amount: 5000.0,
  otp: '123456',
  customerName: 'John Doe',
);

// Get bill payment history
final historyResult = await billService.getBillHistory(
  providerId: 'provider_123',
  page: 1,
  limit: 20,
);
```

### 7. Agent Service (`agent_service.dart`)

**Endpoints:**
- `getNearbyAgents()` - GET `/agent/nearby`
- `getAgentDetails()` - GET `/agent/:id`
- `submitAgentReview()` - POST `/agent/review`

**Usage Example:**
```dart
final agentService = AgentService();

// Get nearby agents
final nearbyResult = await agentService.getNearbyAgents(
  latitude: 8.4657,
  longitude: -13.2317,
  radius: 5.0,
  limit: 10,
);

// Get agent details
final detailsResult = await agentService.getAgentDetails(
  agentId: 'agent_123',
);

// Submit review
final reviewResult = await agentService.submitAgentReview(
  agentId: 'agent_123',
  rating: 5,
  comment: 'Excellent service!',
);
```

### 8. KYC Service (`kyc_service.dart`)

**Endpoints:**
- `submitKYC()` - POST `/kyc/submit` (with file uploads)
- `getKYCStatus()` - GET `/kyc/status`
- `resubmitKYC()` - POST `/kyc/resubmit` (with file uploads)

**Usage Example:**
```dart
final kycService = KYCService();

// Submit KYC documents
final submitResult = await kycService.submitKYC(
  idType: 'national_id',
  idNumber: 'ID123456789',
  idImagePath: '/path/to/id_image.jpg',
  selfieImagePath: '/path/to/selfie.jpg',
  proofOfAddressPath: '/path/to/proof.jpg',
);

// Get KYC status
final statusResult = await kycService.getKYCStatus();

// Resubmit KYC after rejection
final resubmitResult = await kycService.resubmitKYC(
  idType: 'national_id',
  idNumber: 'ID123456789',
  idImagePath: '/path/to/new_id_image.jpg',
  selfieImagePath: '/path/to/new_selfie.jpg',
);
```

### 9. Bank Service (`bank_service.dart`)

**Endpoints:**
- `addBankAccount()` - POST `/users/bank-accounts`
- `getBankAccounts()` - GET `/users/bank-accounts`
- `deleteBankAccount()` - DELETE `/users/bank-accounts/:id`
- `setPrimaryBankAccount()` - PATCH `/users/bank-accounts/:id/set-primary`

**Usage Example:**
```dart
final bankService = BankService();

// Add bank account
final addResult = await bankService.addBankAccount(
  bankName: 'Sierra Leone Commercial Bank',
  accountNumber: '1234567890',
  accountHolderName: 'John Doe',
  branchName: 'Freetown Branch',
  ifscCode: 'SLCB001',
);

// Get all bank accounts
final accountsResult = await bankService.getBankAccounts();

// Set primary bank account
final primaryResult = await bankService.setPrimaryBankAccount(
  bankAccountId: 'bank_123',
);

// Delete bank account
final deleteResult = await bankService.deleteBankAccount(
  bankAccountId: 'bank_123',
);
```

## Implementation Steps

### 1. Initialize API Service

In your app's main initialization (e.g., `main.dart`):

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API service with stored tokens
  final apiService = ApiService();
  await apiService.initialize();

  runApp(MyApp());
}
```

### 2. Replace Mock Data with Real API Calls

**Before (Mock Data):**
```dart
final mockData = MockDataService.getWalletBalance();
```

**After (Real API):**
```dart
final walletService = WalletService();
final result = await walletService.getBalance();

if (result['success']) {
  final balance = result['data']['balance'];
  // Use balance...
} else {
  // Handle error
  showError(result['error']);
}
```

### 3. Handle Authentication Flow

```dart
// Login flow
final authService = AuthService();

// 1. Login
final loginResult = await authService.login(
  phoneNumber: phoneNumber,
  password: password,
);

if (loginResult['success']) {
  // 2. Tokens are automatically stored by ApiService
  // Navigate to home screen
  Navigator.pushReplacementNamed(context, '/home');
} else {
  // Show error
  showError(loginResult['error']);
}

// Logout
final logoutResult = await authService.logout();
// Tokens are automatically cleared
```

### 4. Handle Unauthorized Errors

```dart
try {
  final result = await someService.someMethod();

  if (!result['success']) {
    if (result['error'].contains('Session expired')) {
      // Token expired, redirect to login
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      showError(result['error']);
    }
  }
} catch (e) {
  showError(e.toString());
}
```

## Constants Reference

### Transaction Types
- `transactionTypeDeposit` - 'deposit'
- `transactionTypeWithdrawal` - 'withdrawal'
- `transactionTypeTransfer` - 'transfer'
- `transactionTypeInvestment` - 'investment'
- `transactionTypeBillPayment` - 'bill_payment'

### Transaction Status
- `transactionStatusPending` - 'pending'
- `transactionStatusProcessing` - 'processing'
- `transactionStatusCompleted` - 'completed'
- `transactionStatusFailed` - 'failed'
- `transactionStatusCancelled` - 'cancelled'

### Investment Status
- `investmentStatusActive` - 'active'
- `investmentStatusMatured` - 'matured'
- `investmentStatusWithdrawn` - 'withdrawn'
- `investmentStatusCancelled` - 'cancelled'

### KYC Status
- `kycStatusPending` - 'pending'
- `kycStatusVerified` - 'verified'
- `kycStatusRejected` - 'rejected'
- `kycStatusNotSubmitted` - 'not_submitted'

## Testing

### Run Flutter Pub Get
```bash
cd tcc_user_mobile_client
flutter pub get
```

### Test Individual Services
```dart
void testAuthService() async {
  final authService = AuthService();

  final result = await authService.login(
    phoneNumber: '+1234567890',
    password: 'test123',
  );

  print('Login result: $result');
}
```

## Migration from Mock Data

1. **Identify all mock data calls** in your codebase
2. **Replace with appropriate service methods**
3. **Add error handling** for API failures
4. **Update UI** to show loading states during API calls
5. **Test thoroughly** with real backend endpoints

## Error Handling Best Practices

```dart
Future<void> loadData() async {
  setState(() => isLoading = true);

  try {
    final result = await service.getData();

    if (result['success']) {
      setState(() {
        data = result['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        error = result['error'];
        isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      error = e.toString();
      isLoading = false;
    });
  }
}
```

## Notes

- All services follow the same pattern for consistency
- All API calls include proper error handling
- Token management is automatic through `ApiService`
- All services return standardized `{success, data/error}` format
- File uploads are handled through multipart requests in `KYCService`
- Query parameters are properly encoded in GET requests

## Next Steps

1. Run `flutter pub get` to install the http package
2. Test each service with your backend API
3. Update UI screens to use real API calls instead of mock data
4. Implement proper loading and error states
5. Add retry logic for failed requests if needed
6. Configure production base URL before deployment

## Support

For backend API documentation, refer to the backend team's API specification document.
