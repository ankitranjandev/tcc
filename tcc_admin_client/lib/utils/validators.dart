import '../config/app_constants.dart';

/// Validators utility class
class Validators {
  // Private constructor
  Validators._();

  // ==================== Email Validation ====================

  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    if (!AppConstants.emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // ==================== Password Validation ====================

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }

    if (!AppConstants.passwordRegex.hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, number, and special character';
    }

    return null;
  }

  /// Validate password match
  static String? validatePasswordMatch(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // ==================== Phone Validation ====================

  /// Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    if (!AppConstants.phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // ==================== Required Field Validation ====================

  /// Validate required field
  static String? validateRequired(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // ==================== Number Validation ====================

  /// Validate number
  static String? validateNumber(String? value, [String fieldName = 'Value']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }

    return null;
  }

  /// Validate positive number
  static String? validatePositiveNumber(String? value, [String fieldName = 'Value']) {
    final numberError = validateNumber(value, fieldName);
    if (numberError != null) return numberError;

    final number = double.parse(value!);
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }

    return null;
  }

  /// Validate number range
  static String? validateNumberRange(
    String? value,
    double min,
    double max, [
    String fieldName = 'Value',
  ]) {
    final numberError = validateNumber(value, fieldName);
    if (numberError != null) return numberError;

    final number = double.parse(value!);
    if (number < min || number > max) {
      return '$fieldName must be between $min and $max';
    }

    return null;
  }

  // ==================== Length Validation ====================

  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength, [String fieldName = 'Value']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(String? value, int maxLength, [String fieldName = 'Value']) {
    if (value == null) return null;

    if (value.length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }

    return null;
  }

  /// Validate exact length
  static String? validateExactLength(String? value, int length, [String fieldName = 'Value']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length != length) {
      return '$fieldName must be exactly $length characters';
    }

    return null;
  }

  // ==================== Amount Validation ====================

  /// Validate deposit amount
  static String? validateDepositAmount(String? value) {
    return validateNumberRange(
      value,
      AppConstants.minDepositAmount,
      AppConstants.maxDepositAmount,
      'Deposit amount',
    );
  }

  /// Validate withdrawal amount
  static String? validateWithdrawalAmount(String? value) {
    return validateNumberRange(
      value,
      AppConstants.minWithdrawalAmount,
      AppConstants.maxWithdrawalAmount,
      'Withdrawal amount',
    );
  }

  /// Validate transfer amount
  static String? validateTransferAmount(String? value) {
    return validateNumberRange(
      value,
      AppConstants.minTransferAmount,
      AppConstants.maxTransferAmount,
      'Transfer amount',
    );
  }

  // ==================== OTP Validation ====================

  /// Validate OTP
  static String? validateOTP(String? value) {
    return validateExactLength(value, AppConstants.otpLength, 'OTP');
  }

  // ==================== URL Validation ====================

  /// Validate URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  // ==================== Date Validation ====================

  /// Validate date is not in future
  static String? validateNotFutureDate(DateTime? date, [String fieldName = 'Date']) {
    if (date == null) {
      return '$fieldName is required';
    }

    if (date.isAfter(DateTime.now())) {
      return '$fieldName cannot be in the future';
    }

    return null;
  }

  /// Validate date is not in past
  static String? validateNotPastDate(DateTime? date, [String fieldName = 'Date']) {
    if (date == null) {
      return '$fieldName is required';
    }

    if (date.isBefore(DateTime.now())) {
      return '$fieldName cannot be in the past';
    }

    return null;
  }

  // ==================== Custom Validation ====================

  /// Custom validator
  static String? Function(String?) custom(
    bool Function(String) test,
    String errorMessage,
  ) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'This field is required';
      }

      if (!test(value)) {
        return errorMessage;
      }

      return null;
    };
  }
}
