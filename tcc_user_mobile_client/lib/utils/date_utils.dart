import 'dart:developer' as developer;
import 'package:intl/intl.dart';

/// Centralized date utility class for parsing and formatting dates consistently
/// across the app with proper timezone handling and error recovery
class DateUtils {
  /// Parses a date from API response with robust error handling
  ///
  /// Tries multiple strategies:
  /// 1. Checks for multiple field names (date, created_at, createdAt, timestamp)
  /// 2. Handles both ISO8601 strings and millisecond timestamps
  /// 3. Converts UTC to local timezone
  /// 4. Returns epoch (0) instead of DateTime.now() for invalid/null dates
  ///
  /// Returns epoch timestamp (Jan 1, 1970) if parsing fails, making it obvious
  /// something is wrong rather than silently using current time
  static DateTime parseApiDate(dynamic json) {
    // Try multiple field names that APIs might use
    dynamic dateValue = json['date'] ??
                       json['created_at'] ??
                       json['createdAt'] ??
                       json['timestamp'];

    return _parseDateSafe(dateValue);
  }

  /// Safely parse a date value with error handling and logging
  static DateTime _parseDateSafe(dynamic dateValue) {
    if (dateValue == null) {
      developer.log(
        '⚠️ Date value is null! Using epoch timestamp.',
        name: 'DateUtils',
      );
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    try {
      if (dateValue is String) {
        // Parse ISO8601 string and convert to local timezone
        final parsed = DateTime.parse(dateValue);
        return parsed.toLocal();
      } else if (dateValue is int) {
        // Handle milliseconds timestamp
        return DateTime.fromMillisecondsSinceEpoch(dateValue).toLocal();
      } else if (dateValue is double) {
        // Handle timestamp as double (convert to int)
        return DateTime.fromMillisecondsSinceEpoch(dateValue.toInt()).toLocal();
      } else {
        developer.log(
          '⚠️ Unexpected date type: ${dateValue.runtimeType}',
          name: 'DateUtils',
        );
      }
    } catch (e) {
      developer.log(
        '❌ Failed to parse date: $dateValue, error: $e',
        name: 'DateUtils',
      );
    }

    // Return epoch as indicator of parse failure
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Check if a date is valid (not epoch/null indicator)
  static bool isValidDate(DateTime date) {
    return date.millisecondsSinceEpoch > 0;
  }

  /// Format date for display in transaction list
  /// Returns "Date unavailable" for invalid dates
  static String formatTransactionDate(DateTime date) {
    if (!isValidDate(date)) {
      return 'Date unavailable';
    }
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  /// Format date for transaction detail screen (date only)
  static String formatDetailDate(DateTime date) {
    if (!isValidDate(date)) {
      return 'Date unavailable';
    }
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  /// Format time for transaction detail screen (time only)
  static String formatDetailTime(DateTime date) {
    if (!isValidDate(date)) {
      return 'Time unavailable';
    }
    return DateFormat('hh:mm a').format(date);
  }

  /// Convert DateTime to ISO8601 string for API requests
  static String toApiFormat(DateTime date) {
    return date.toUtc().toIso8601String();
  }

  /// Parse date using AppConstants format (for consistency)
  static DateTime? parseWithFormat(String dateString, String format) {
    try {
      final formatter = DateFormat(format);
      final parsed = formatter.parse(dateString);
      return parsed.toLocal();
    } catch (e) {
      developer.log(
        '❌ Failed to parse date with format $format: $dateString, error: $e',
        name: 'DateUtils',
      );
      return null;
    }
  }

  /// Ensure a DateTime is in local timezone
  static DateTime toLocal(DateTime date) {
    return date.toLocal();
  }

  /// Ensure a DateTime is in UTC timezone
  static DateTime toUtc(DateTime date) {
    return date.toUtc();
  }
}
