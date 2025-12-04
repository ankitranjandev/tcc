/// TCC Admin Application Constants
class AppConstants {
  // Private constructor
  AppConstants._();

  // ==================== App Info ====================
  static const String appName = 'TCC Admin';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'The Community Coin Admin Panel';

  // ==================== Demo Mode ====================
  /// Set to true to use mock data instead of real API calls
  /// This is useful for development and testing without a backend
  static const bool useMockData = false;

  // ==================== API ====================
  static const String apiVersion = 'v1';
  static const int apiTimeout = 30; // seconds
  static const int maxRetries = 3;

  // ==================== Storage Keys ====================
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserData = 'user_data';
  static const String keyRememberMe = 'remember_me';

  // ==================== Pagination ====================
  static const int defaultPageSize = 25;
  static const List<int> pageSizeOptions = [25, 50, 100];

  // ==================== Date Formats ====================
  static const String dateFormat = 'MMM dd, yyyy';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm';
  static const String timeFormat = 'HH:mm:ss';
  static const String apiDateFormat = 'yyyy-MM-dd';

  // ==================== Currency ====================
  static const String currency = 'Le'; // Sierra Leonean Leone
  static const String currencyCode = 'SLL';
  static const String currencySymbol = 'Le';

  // ==================== Validation ====================
  static const int minPasswordLength = 8;
  static const int maxLoginAttempts = 5;
  static const int otpLength = 6;
  static const int otpExpiryMinutes = 5;

  // ==================== Session ====================
  static const int sessionTimeoutMinutes = 30;
  static const int refreshTokenBeforeExpiryMinutes = 5;

  // ==================== File Upload ====================
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx'];

  // ==================== Transaction Limits (SLL) ====================
  static const double minDepositAmount = 1000.0;
  static const double maxDepositAmount = 10000000.0;
  static const double minWithdrawalAmount = 1000.0;
  static const double maxWithdrawalAmount = 5000000.0;
  static const double minTransferAmount = 100.0;
  static const double maxTransferAmount = 2000000.0;

  // ==================== Fees (%) ====================
  static const double depositFee = 0.0;
  static const double withdrawalFee = 2.0;
  static const double transferFee = 1.0;
  static const double billPaymentFee = 1.5;

  // ==================== User Roles ====================
  static const String roleSuperAdmin = 'SUPER_ADMIN';
  static const String roleAdmin = 'ADMIN';
  static const String roleAgent = 'AGENT';
  static const String roleUser = 'USER';

  // ==================== Transaction Types ====================
  static const String transactionDeposit = 'DEPOSIT';
  static const String transactionWithdrawal = 'WITHDRAWAL';
  static const String transactionTransfer = 'TRANSFER';
  static const String transactionBillPayment = 'BILL_PAYMENT';
  static const String transactionInvestment = 'INVESTMENT';
  static const String transactionVoting = 'VOTING';

  // ==================== Transaction Status ====================
  static const String statusPending = 'PENDING';
  static const String statusProcessing = 'PROCESSING';
  static const String statusCompleted = 'COMPLETED';
  static const String statusFailed = 'FAILED';
  static const String statusCancelled = 'CANCELLED';
  static const String statusRejected = 'REJECTED';

  // ==================== KYC Status ====================
  static const String kycPending = 'PENDING';
  static const String kycApproved = 'APPROVED';
  static const String kycRejected = 'REJECTED';
  static const String kycUnderReview = 'UNDER_REVIEW';

  // ==================== Investment Categories ====================
  static const String categoryAgriculture = 'AGRICULTURE';
  static const String categoryEducation = 'EDUCATION';
  static const String categoryMinerals = 'MINERALS';

  // ==================== Investment Tenures (months) ====================
  static const List<int> investmentTenures = [6, 12, 24, 36];

  // ==================== Investment Units ====================
  static const String unitLot = 'LOT';
  static const String unitPlot = 'PLOT';
  static const String unitFarm = 'FARM';

  // ==================== Bill Service Types ====================
  static const String serviceWater = 'WATER';
  static const String serviceElectricity = 'ELECTRICITY';
  static const String serviceDSTV = 'DSTV';
  static const String serviceInternet = 'INTERNET';
  static const String serviceMobileRecharge = 'MOBILE_RECHARGE';

  // ==================== Agent Status ====================
  static const String agentActive = 'ACTIVE';
  static const String agentInactive = 'INACTIVE';
  static const String agentVerificationPending = 'VERIFICATION_PENDING';

  // ==================== Regex Patterns ====================
  static final RegExp emailRegex = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  static final RegExp phoneRegex = RegExp(
    r'^\+?[0-9]{10,15}$',
  );

  static final RegExp passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  // ==================== Error Messages ====================
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorUnauthorized = 'Unauthorized. Please login again.';
  static const String errorServerError = 'Server error. Please try again later.';
  static const String errorInvalidCredentials = 'Invalid email or password.';
  static const String errorSessionExpired = 'Your session has expired. Please login again.';

  // ==================== Success Messages ====================
  static const String successLogin = 'Login successful';
  static const String successLogout = 'Logged out successfully';
  static const String successKycApproved = 'KYC approved successfully';
  static const String successKycRejected = 'KYC rejected';
  static const String successTransactionApproved = 'Transaction approved successfully';
  static const String successTransactionRejected = 'Transaction rejected';

  // ==================== Chart Colors ====================
  static const List<String> chartColors = [
    '#5B6EF5', // Blue
    '#00C896', // Green
    '#F9B234', // Yellow
    '#FF5757', // Red
    '#7C8DF7', // Light Blue
    '#4AE4BC', // Light Green
  ];

  // ==================== Date Range Presets ====================
  static const String rangeToday = 'TODAY';
  static const String rangeYesterday = 'YESTERDAY';
  static const String rangeThisWeek = 'THIS_WEEK';
  static const String rangeThisMonth = 'THIS_MONTH';
  static const String rangeLastMonth = 'LAST_MONTH';
  static const String rangeCustom = 'CUSTOM';

  // ==================== Export Formats ====================
  static const String exportCSV = 'CSV';
  static const String exportExcel = 'EXCEL';
  static const String exportPDF = 'PDF';

  // ==================== Notification Types ====================
  static const String notificationKycPending = 'KYC_PENDING';
  static const String notificationWithdrawalPending = 'WITHDRAWAL_PENDING';
  static const String notificationDepositPending = 'DEPOSIT_PENDING';
  static const String notificationSecurityAlert = 'SECURITY_ALERT';
  static const String notificationSystemAlert = 'SYSTEM_ALERT';
}
