import 'dart:io';

class AppConstants {
  // App Information
  static const String appName = 'TCC User';
  static const String appVersion = '1.0.0';

  // API Configuration
  // 10.0.2.2 is the special IP for Android emulator to access host machine's localhost
  // For iOS simulator, use 127.0.0.1 or localhost
  // For physical devices, replace with your computer's IP address (e.g., 192.168.1.100)
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine's localhost
      return 'http://10.0.2.2:3000/v1';
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost
      return 'http://127.0.0.1:3000/v1';
    } else {
      // Fallback for other platforms
      return 'http://localhost:3000/v1';
    }
  }

  static const String apiVersion = 'v1';

  // Transaction Types
  static const String transactionTypeDeposit = 'deposit';
  static const String transactionTypeWithdrawal = 'withdrawal';
  static const String transactionTypeTransfer = 'transfer';
  static const String transactionTypeInvestment = 'investment';
  static const String transactionTypeBillPayment = 'bill_payment';
  static const String transactionTypeInvestmentWithdrawal = 'investment_withdrawal';

  // Transaction Status
  static const String transactionStatusPending = 'pending';
  static const String transactionStatusProcessing = 'processing';
  static const String transactionStatusCompleted = 'completed';
  static const String transactionStatusFailed = 'failed';
  static const String transactionStatusCancelled = 'cancelled';

  // Investment Status
  static const String investmentStatusActive = 'active';
  static const String investmentStatusMatured = 'matured';
  static const String investmentStatusWithdrawn = 'withdrawn';
  static const String investmentStatusCancelled = 'cancelled';

  // KYC Status
  static const String kycStatusPending = 'pending';
  static const String kycStatusVerified = 'verified';
  static const String kycStatusRejected = 'rejected';
  static const String kycStatusNotSubmitted = 'not_submitted';

  // Bill Categories
  static const String billCategoryElectricity = 'electricity';
  static const String billCategoryWater = 'water';
  static const String billCategoryInternet = 'internet';
  static const String billCategoryMobile = 'mobile';
  static const String billCableTv = 'cable_tv';

  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int otpLength = 6;
  static const int otpResendTimeout = 60; // seconds

  // Timeouts
  static const int apiTimeout = 30; // seconds
  static const int imageUploadTimeout = 60; // seconds

  // Image Configuration
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int imageQuality = 85;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Keys
  static const String cacheKeyToken = 'auth_token';
  static const String cacheKeyRefreshToken = 'refresh_token';
  static const String cacheKeyUserProfile = 'user_profile';
  static const String cacheKeyThemeMode = 'theme_mode';
  static const String cacheKeyLanguage = 'language';

  // Error Messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorTimeout = 'Request timed out. Please try again.';
  static const String errorUnauthorized = 'Session expired. Please login again.';
  static const String errorInvalidCredentials = 'Invalid email or password.';
  static const String errorInvalidOtp = 'Invalid or expired OTP.';
  static const String errorInsufficientBalance = 'Insufficient wallet balance.';
  static const String errorImageTooLarge = 'Image size too large. Maximum 5MB allowed.';

  // Success Messages
  static const String successLogin = 'Login successful!';
  static const String successRegistration = 'Registration successful!';
  static const String successOtpSent = 'OTP sent successfully.';
  static const String successPasswordReset = 'Password reset successful.';
  static const String successProfileUpdated = 'Profile updated successfully.';
  static const String successTransactionCompleted = 'Transaction completed successfully.';
  static const String successDepositCompleted = 'Deposit completed successfully.';
  static const String successWithdrawalCompleted = 'Withdrawal completed successfully.';
  static const String successTransferCompleted = 'Transfer completed successfully.';
  static const String successBillPaymentCompleted = 'Bill payment completed successfully.';
  static const String successInvestmentCreated = 'Investment created successfully.';

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

  // Currency
  static const String currencySymbol = 'Le';
  static const String currencyCode = 'SLL';
}
