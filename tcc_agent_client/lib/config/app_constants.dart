class AppConstants {
  // App Information
  static const String appName = 'TCC Agent';
  static const String appVersion = '1.0.0';

  // Demo Mode (set to false when backend is ready)
  static const bool isDemoMode = false;

  // API Configuration
  static const String baseUrl = 'http://localhost:3000/v1'; // Change for production
  static const String apiVersion = 'v1';

  // API Endpoints - Auth
  static const String loginEndpoint = '/auth/login-direct';  // DEV: Using direct login (bypasses OTP)
  static const String adminLoginEndpoint = '/admin/login';
  static const String registerEndpoint = '/auth/register';
  static const String verifyOtpEndpoint = '/auth/verify-otp';
  static const String resendOtpEndpoint = '/auth/resend-otp';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String refreshTokenEndpoint = '/auth/refresh';

  // API Endpoints - Agent
  static const String agentProfileEndpoint = '/agent/profile';
  static const String updateAgentStatusEndpoint = '/agents/status';
  static const String updateLocationEndpoint = '/agents/location';

  static const String addMoneyToUserEndpoint = '/agents/add-money-to-user';
  static const String paymentOrdersEndpoint = '/agents/payment-orders';
  static const String acceptOrderEndpoint = '/agents/accept-order';
  static const String completeOrderEndpoint = '/agents/complete-order';

  static const String dashboardEndpoint = '/agents/dashboard';
  static const String commissionsEndpoint = '/agents/commissions';
  static const String transactionsEndpoint = '/agents/transactions';

  static const String creditRequestEndpoint = '/agents/credit-request';
  static const String nearbyAgentsEndpoint = '/agents/nearby';

  // Agent Status
  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';
  static const String statusBusy = 'busy';
  static const String statusPendingVerification = 'pending_verification';
  static const String statusVerified = 'verified';
  static const String statusRejected = 'rejected';

  // Transaction Types
  static const String transactionTypeDeposit = 'deposit';
  static const String transactionTypeWithdrawal = 'withdrawal';
  static const String transactionTypeTransfer = 'transfer';
  static const String transactionTypeCommission = 'commission';

  // Transaction Status
  static const String transactionStatusPending = 'pending';
  static const String transactionStatusProcessing = 'processing';
  static const String transactionStatusCompleted = 'completed';
  static const String transactionStatusFailed = 'failed';
  static const String transactionStatusCancelled = 'cancelled';

  // Payment Methods
  static const String paymentMethodCash = 'cash';
  static const String paymentMethodBank = 'bank';
  static const String paymentMethodMobileMoney = 'mobile_money';
  static const String paymentMethodAirtelMoney = 'airtel_money';

  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int otpLength = 6;
  static const int otpResendTimeout = 60; // seconds
  static const int minCommissionRate = 0;
  static const int maxCommissionRate = 10; // percentage

  // Currency Denominations (TCC Coin)
  static const List<int> currencyDenominations = [
    10000,
    5000,
    2000,
    1000,
    500,
    200,
    100,
  ];

  // Timeouts
  static const int apiTimeout = 30; // seconds
  static const int imageUploadTimeout = 60; // seconds
  static const int locationUpdateInterval = 300; // seconds (5 minutes)

  // Image Configuration
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int imageQuality = 85;
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Distance (for nearby agents)
  static const double nearbyAgentRadius = 5.0; // kilometers
  static const double maxAgentRadius = 50.0; // kilometers

  // Verification
  static const int verificationWaitTime = 48; // hours

  // Cache Keys
  static const String cacheKeyToken = 'auth_token';
  static const String cacheKeyRefreshToken = 'refresh_token';
  static const String cacheKeyAgentProfile = 'agent_profile';
  static const String cacheKeyThemeMode = 'theme_mode';
  static const String cacheKeyLanguage = 'language';
  static const String cacheKeyLastLocation = 'last_location';

  // Error Messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'No internet connection. Please check your network and try again.';
  static const String errorTimeout = 'Request timed out. Please check your connection and try again.';
  static const String errorUnauthorized = 'Session expired. Please login again.';
  static const String errorInvalidCredentials = 'Invalid email or password.';
  static const String errorInvalidOtp = 'Invalid or expired OTP.';
  static const String errorLocationPermission = 'Location permission denied.';
  static const String errorCameraPermission = 'Camera permission denied.';
  static const String errorStoragePermission = 'Storage permission denied.';
  static const String errorImageTooLarge = 'Image size too large. Maximum 5MB allowed.';
  static const String errorInsufficientBalance = 'Insufficient wallet balance.';
  static const String errorServerUnavailable = 'Server is currently unavailable. Please try again later.';
  static const String errorBadRequest = 'Invalid request. Please check your input and try again.';
  static const String errorDuplicateEntry = 'This record already exists in the system.';
  static const String errorNotFound = 'The requested resource was not found.';

  // Success Messages
  static const String successLogin = 'Login successful!';
  static const String successRegistration = 'Registration successful!';
  static const String successOtpSent = 'OTP sent successfully.';
  static const String successPasswordReset = 'Password reset successful.';
  static const String successProfileUpdated = 'Profile updated successfully.';
  static const String successTransactionCompleted = 'Transaction completed successfully.';
  static const String successOrderAccepted = 'Order accepted successfully.';
  static const String successStatusUpdated = 'Status updated successfully.';

  // Regex Patterns
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phonePattern = r'^\+?[1-9]\d{1,14}$';
  static const String passwordPattern = r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$';

  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';
  static const String apiDateFormat = 'yyyy-MM-dd';
  static const String apiDateTimeFormat = 'yyyy-MM-ddTHH:mm:ss.SSSZ';
}
