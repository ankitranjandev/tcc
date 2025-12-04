import 'package:intl/intl.dart';
import '../config/app_constants.dart';

/// Formatters utility class
class Formatters {
  // Private constructor
  Formatters._();

  // ==================== Currency Formatting ====================

  /// Format currency (Sierra Leonean Leone)
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: AppConstants.currencySymbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Format currency without symbol
  static String formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(amount).trim();
  }

  /// Format currency compact (1K, 1M, etc.)
  static String formatCurrencyCompact(double amount) {
    if (amount >= 1000000) {
      return '${AppConstants.currencySymbol} ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${AppConstants.currencySymbol} ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return formatCurrency(amount);
  }

  // ==================== Date & Time Formatting ====================

  /// Format date (MMM dd, yyyy)
  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  /// Format date and time (MMM dd, yyyy HH:mm)
  static String formatDateTime(DateTime dateTime) {
    return DateFormat(AppConstants.dateTimeFormat).format(dateTime);
  }

  /// Format time (HH:mm:ss)
  static String formatTime(DateTime time) {
    return DateFormat(AppConstants.timeFormat).format(time);
  }

  /// Format date for API (yyyy-MM-dd)
  static String formatDateForApi(DateTime date) {
    return DateFormat(AppConstants.apiDateFormat).format(date);
  }

  /// Format relative time (e.g., "2 hours ago", "Yesterday")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  // ==================== Number Formatting ====================

  /// Format number with thousand separators
  static String formatNumber(num number) {
    final formatter = NumberFormat.decimalPattern();
    return formatter.format(number);
  }

  /// Format percentage
  static String formatPercentage(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Format decimal
  static String formatDecimal(double value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals);
  }

  // ==================== Phone Formatting ====================

  /// Format phone number
  static String formatPhoneNumber(String phone) {
    // Remove all non-numeric characters
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.length == 10) {
      // Format as (XXX) XXX-XXXX
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    } else if (cleaned.length == 11 && cleaned.startsWith('1')) {
      // Format as +1 (XXX) XXX-XXXX
      return '+1 (${cleaned.substring(1, 4)}) ${cleaned.substring(4, 7)}-${cleaned.substring(7)}';
    }

    // Return as is if format not recognized
    return phone;
  }

  // ==================== Text Formatting ====================

  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Title case
  static String titleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Mask email (e.g., j***@example.com)
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return '$username***@$domain';
    }

    final masked = username[0] + ('*' * (username.length - 2)) + username[username.length - 1];
    return '$masked@$domain';
  }

  /// Mask phone number (e.g., ***-***-1234)
  static String maskPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length < 4) return phone;

    final lastFour = cleaned.substring(cleaned.length - 4);
    return '***-***-$lastFour';
  }

  // ==================== File Size Formatting ====================

  /// Format file size (bytes to KB, MB, GB)
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // ==================== Duration Formatting ====================

  /// Format duration (e.g., "2h 30m", "45s")
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
