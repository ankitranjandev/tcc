# TCC Application - Currency Formatting & Utilities

## Currency Display Decision

### Background

**Database Storage:** Sierra Leonean Leone (SLL)
**Figma Designs:** Show `$` symbol throughout

### Recommendation: Use `Le` Symbol (Leone)

**Rationale:**
1. **Regulatory Compliance:** Using the correct currency symbol avoids potential regulatory issues in Sierra Leone
2. **User Trust:** Displaying the actual local currency builds trust with users
3. **Financial Accuracy:** Prevents confusion about actual currency being used
4. **Market Positioning:** Reinforces that this is a local, African solution

### Implementation

Display currency as:
- **Short Format:** `Le 5,000`
- **Long Format:** `Le 5,000.50`
- **With Label:** `5,000 Leones` or `5,000 TCC Coins`

**Alternative (If simplified UX is required):**
- Use `SLE` (ISO code for Sierra Leonean Leone) instead of `$`
- Example: `SLE 5,000`

---

## Flutter Utilities

### 1. Currency Formatter Class

**File:** `lib/core/utils/currency_formatter.dart`

```dart
import 'package:intl/intl.dart';

class CurrencyFormatter {
  // Currency configuration
  static const String currencyCode = 'SLL';
  static const String currencySymbol = 'Le';
  static const String currencyName = 'Leone';
  static const String currencyNamePlural = 'Leones';
  static const int decimalDigits = 2;

  // Locale for Sierra Leone
  static const String locale = 'en_SL';

  /// Format amount with currency symbol
  /// Example: formatCurrency(5000.50) => "Le 5,000.50"
  static String formatCurrency(
    double amount, {
    bool showSymbol = true,
    bool showDecimals = true,
    bool compact = false,
  }) {
    if (compact) {
      return formatCompact(amount, showSymbol: showSymbol);
    }

    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: showSymbol ? '$currencySymbol ' : '',
      decimalDigits: showDecimals ? decimalDigits : 0,
    );

    return formatter.format(amount);
  }

  /// Format currency in compact form
  /// Example: formatCompact(1500000) => "Le 1.5M"
  static String formatCompact(double amount, {bool showSymbol = true}) {
    String symbol = showSymbol ? '$currencySymbol ' : '';

    if (amount >= 1000000000) {
      return '$symbol${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '$symbol${amount.toStringAsFixed(0)}';
    }
  }

  /// Format with currency name
  /// Example: formatWithName(5000) => "5,000 Leones"
  static String formatWithName(double amount, {bool plural = true}) {
    final formatter = NumberFormat.decimalPattern(locale);
    final formattedAmount = formatter.format(amount);
    final name = (amount == 1.0 || !plural) ? currencyName : currencyNamePlural;
    return '$formattedAmount $name';
  }

  /// Format for TCC Coins (1:1 with Leone)
  /// Example: formatCoins(5000.50) => "5,000.50 TCC Coins"
  static String formatCoins(double amount, {bool showDecimals = true}) {
    final formatter = NumberFormat.decimalPattern(locale);
    String formatted;

    if (showDecimals) {
      formatted = amount.toStringAsFixed(decimalDigits);
    } else {
      formatted = formatter.format(amount.round());
    }

    return '$formatted TCC Coins';
  }

  /// Format for input (removes formatting, keeps only numbers)
  /// Example: parseInput("Le 5,000.50") => 5000.50
  static double parseInput(String input) {
    // Remove all non-numeric characters except decimal point
    String cleaned = input.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Format phone number display (masked)
  /// Example: formatPhoneMasked("+2321234567890") => "+232 ****7890"
  static String formatPhoneMasked(String phone, {int visibleDigits = 4}) {
    if (phone.length <= visibleDigits) return phone;

    final lastDigits = phone.substring(phone.length - visibleDigits);
    final countryCode = phone.substring(0, 4); // +232
    final masked = '*' * (phone.length - visibleDigits - 4);

    return '$countryCode $masked$lastDigits';
  }

  /// Format phone number for display
  /// Example: formatPhone("+232", "1234567890") => "+232 123 456 7890"
  static String formatPhone(String countryCode, String phone) {
    // Remove any existing formatting
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.length >= 10) {
      return '$countryCode ${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    } else if (cleaned.length >= 6) {
      return '$countryCode ${cleaned.substring(0, 3)} ${cleaned.substring(3)}';
    } else {
      return '$countryCode $cleaned';
    }
  }

  /// Format transaction ID for display
  /// Example: formatTransactionId("TXN20251026123456") => "TXN-2025-1026-123456"
  static String formatTransactionId(String txnId) {
    if (txnId.length < 15) return txnId;
    // TXN20251026123456 => TXN-2025-1026-123456
    return '${txnId.substring(0, 3)}-${txnId.substring(3, 7)}-${txnId.substring(7, 11)}-${txnId.substring(11)}';
  }

  /// Format date relative to now
  /// Example: formatDateRelative(DateTime.now().subtract(Duration(days: 2))) => "2 days ago"
  static String formatDateRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Format date for display
  /// Example: formatDate(DateTime.now()) => "Oct 26, 2025"
  static String formatDate(DateTime date, {bool shortMonth = true}) {
    if (shortMonth) {
      return DateFormat('MMM d, y').format(date);
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }

  /// Format date and time
  /// Example: formatDateTime(DateTime.now()) => "Oct 26, 2025 10:30 AM"
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, y h:mm a').format(dateTime);
  }

  /// Format time only
  /// Example: formatTime(DateTime.now()) => "10:30 AM"
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Format percentage
  /// Example: formatPercentage(12.5) => "12.5%"
  static String formatPercentage(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Format large numbers
  /// Example: formatNumber(1234567) => "1,234,567"
  static String formatNumber(num value, {int decimals = 0}) {
    final formatter = NumberFormat.decimalPattern(locale);
    if (decimals > 0 && value is double) {
      return value.toStringAsFixed(decimals);
    }
    return formatter.format(value);
  }
}
```

---

### 2. Currency Input Formatter (for TextFields)

**File:** `lib/core/widgets/currency_input_formatter.dart`

```dart
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final int decimalDigits;
  final String locale;

  CurrencyInputFormatter({
    this.decimalDigits = 2,
    this.locale = 'en_SL',
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove all non-numeric characters except decimal point
    String cleaned = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');

    // Handle multiple decimal points
    int decimalCount = '.'.allMatches(cleaned).length;
    if (decimalCount > 1) {
      cleaned = cleaned.substring(0, cleaned.lastIndexOf('.'));
    }

    // Limit decimal places
    if (cleaned.contains('.')) {
      List<String> parts = cleaned.split('.');
      if (parts[1].length > decimalDigits) {
        parts[1] = parts[1].substring(0, decimalDigits);
      }
      cleaned = '${parts[0]}.${parts[1]}';
    }

    double value = double.tryParse(cleaned) ?? 0.0;

    final formatter = NumberFormat.decimalPattern(locale);
    String formatted = formatter.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
```

---

### 3. Usage Examples in Flutter

```dart
import 'package:flutter/material.dart';
import 'currency_formatter.dart';

class ExampleUsage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double walletBalance = 15000.50;
    double investmentAmount = 5000000.00;
    DateTime transactionDate = DateTime.now().subtract(Duration(days: 2));

    return Column(
      children: [
        // Display wallet balance
        Text(
          CurrencyFormatter.formatCurrency(walletBalance),
          // Output: "Le 15,000.50"
        ),

        // Display large amount in compact form
        Text(
          CurrencyFormatter.formatCompact(investmentAmount),
          // Output: "Le 5.0M"
        ),

        // Display as TCC Coins
        Text(
          CurrencyFormatter.formatCoins(walletBalance),
          // Output: "15,000.50 TCC Coins"
        ),

        // Display transaction date
        Text(
          CurrencyFormatter.formatDateRelative(transactionDate),
          // Output: "2 days ago"
        ),

        // Currency input field
        TextField(
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [CurrencyInputFormatter()],
          decoration: InputDecoration(
            prefixText: 'Le ',
            hintText: '0.00',
          ),
        ),
      ],
    );
  }
}
```

---

## React/TypeScript Utilities

### 1. Currency Formatter Utility

**File:** `src/utils/currencyFormatter.ts`

```typescript
export class CurrencyFormatter {
  // Currency configuration
  static readonly CURRENCY_CODE = 'SLL';
  static readonly CURRENCY_SYMBOL = 'Le';
  static readonly CURRENCY_NAME = 'Leone';
  static readonly CURRENCY_NAME_PLURAL = 'Leones';
  static readonly DECIMAL_DIGITS = 2;
  static readonly LOCALE = 'en-SL';

  /**
   * Format amount with currency symbol
   * @example formatCurrency(5000.50) => "Le 5,000.50"
   */
  static formatCurrency(
    amount: number,
    options: {
      showSymbol?: boolean;
      showDecimals?: boolean;
      compact?: boolean;
    } = {}
  ): string {
    const {
      showSymbol = true,
      showDecimals = true,
      compact = false,
    } = options;

    if (compact) {
      return this.formatCompact(amount, showSymbol);
    }

    const formatter = new Intl.NumberFormat(this.LOCALE, {
      style: 'currency',
      currency: this.CURRENCY_CODE,
      minimumFractionDigits: showDecimals ? this.DECIMAL_DIGITS : 0,
      maximumFractionDigits: showDecimals ? this.DECIMAL_DIGITS : 0,
    });

    let formatted = formatter.format(amount);

    // Replace ISO code with our symbol
    if (showSymbol) {
      formatted = formatted.replace(this.CURRENCY_CODE, this.CURRENCY_SYMBOL);
    } else {
      formatted = formatted.replace(this.CURRENCY_CODE, '').trim();
    }

    return formatted;
  }

  /**
   * Format currency in compact form
   * @example formatCompact(1500000) => "Le 1.5M"
   */
  static formatCompact(amount: number, showSymbol: boolean = true): string {
    const symbol = showSymbol ? `${this.CURRENCY_SYMBOL} ` : '';

    if (amount >= 1000000000) {
      return `${symbol}${(amount / 1000000000).toFixed(1)}B`;
    } else if (amount >= 1000000) {
      return `${symbol}${(amount / 1000000).toFixed(1)}M`;
    } else if (amount >= 1000) {
      return `${symbol}${(amount / 1000).toFixed(1)}K`;
    } else {
      return `${symbol}${amount.toFixed(0)}`;
    }
  }

  /**
   * Format with currency name
   * @example formatWithName(5000) => "5,000 Leones"
   */
  static formatWithName(amount: number, plural: boolean = true): string {
    const formatter = new Intl.NumberFormat(this.LOCALE);
    const formattedAmount = formatter.format(amount);
    const name = amount === 1 || !plural ? this.CURRENCY_NAME : this.CURRENCY_NAME_PLURAL;
    return `${formattedAmount} ${name}`;
  }

  /**
   * Format for TCC Coins
   * @example formatCoins(5000.50) => "5,000.50 TCC Coins"
   */
  static formatCoins(amount: number, showDecimals: boolean = true): string {
    const formatter = new Intl.NumberFormat(this.LOCALE, {
      minimumFractionDigits: showDecimals ? this.DECIMAL_DIGITS : 0,
      maximumFractionDigits: showDecimals ? this.DECIMAL_DIGITS : 0,
    });
    return `${formatter.format(amount)} TCC Coins`;
  }

  /**
   * Parse input string to number
   * @example parseInput("Le 5,000.50") => 5000.50
   */
  static parseInput(input: string): number {
    // Remove all non-numeric characters except decimal point
    const cleaned = input.replace(/[^0-9.]/g, '');
    return parseFloat(cleaned) || 0;
  }

  /**
   * Format phone number (masked)
   * @example formatPhoneMasked("+2321234567890") => "+232 ****7890"
   */
  static formatPhoneMasked(phone: string, visibleDigits: number = 4): string {
    if (phone.length <= visibleDigits) return phone;

    const lastDigits = phone.substring(phone.length - visibleDigits);
    const countryCode = phone.substring(0, 4); // +232
    const masked = '*'.repeat(phone.length - visibleDigits - 4);

    return `${countryCode} ${masked}${lastDigits}`;
  }

  /**
   * Format phone number for display
   * @example formatPhone("+232", "1234567890") => "+232 123 456 7890"
   */
  static formatPhone(countryCode: string, phone: string): string {
    const cleaned = phone.replace(/[^0-9]/g, '');

    if (cleaned.length >= 10) {
      return `${countryCode} ${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}`;
    } else if (cleaned.length >= 6) {
      return `${countryCode} ${cleaned.substring(0, 3)} ${cleaned.substring(3)}`;
    } else {
      return `${countryCode} ${cleaned}`;
    }
  }

  /**
   * Format transaction ID
   * @example formatTransactionId("TXN20251026123456") => "TXN-2025-1026-123456"
   */
  static formatTransactionId(txnId: string): string {
    if (txnId.length < 15) return txnId;
    return `${txnId.substring(0, 3)}-${txnId.substring(3, 7)}-${txnId.substring(7, 11)}-${txnId.substring(11)}`;
  }

  /**
   * Format date relative to now
   * @example formatDateRelative(new Date(Date.now() - 2 * 24 * 60 * 60 * 1000)) => "2 days ago"
   */
  static formatDateRelative(date: Date): string {
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffSec = Math.floor(diffMs / 1000);
    const diffMin = Math.floor(diffSec / 60);
    const diffHour = Math.floor(diffMin / 60);
    const diffDay = Math.floor(diffHour / 24);
    const diffMonth = Math.floor(diffDay / 30);
    const diffYear = Math.floor(diffDay / 365);

    if (diffYear > 0) {
      return `${diffYear} ${diffYear === 1 ? 'year' : 'years'} ago`;
    } else if (diffMonth > 0) {
      return `${diffMonth} ${diffMonth === 1 ? 'month' : 'months'} ago`;
    } else if (diffDay > 0) {
      return `${diffDay} ${diffDay === 1 ? 'day' : 'days'} ago`;
    } else if (diffHour > 0) {
      return `${diffHour} ${diffHour === 1 ? 'hour' : 'hours'} ago`;
    } else if (diffMin > 0) {
      return `${diffMin} ${diffMin === 1 ? 'minute' : 'minutes'} ago`;
    } else {
      return 'Just now';
    }
  }

  /**
   * Format date
   * @example formatDate(new Date()) => "Oct 26, 2025"
   */
  static formatDate(date: Date, shortMonth: boolean = true): string {
    const options: Intl.DateTimeFormatOptions = shortMonth
      ? { month: 'short', day: 'numeric', year: 'numeric' }
      : { month: 'long', day: 'numeric', year: 'numeric' };

    return new Intl.DateTimeFormat('en-US', options).format(date);
  }

  /**
   * Format date and time
   * @example formatDateTime(new Date()) => "Oct 26, 2025 10:30 AM"
   */
  static formatDateTime(dateTime: Date): string {
    return new Intl.DateTimeFormat('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
    }).format(dateTime);
  }

  /**
   * Format time only
   * @example formatTime(new Date()) => "10:30 AM"
   */
  static formatTime(dateTime: Date): string {
    return new Intl.DateTimeFormat('en-US', {
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
    }).format(dateTime);
  }

  /**
   * Format percentage
   * @example formatPercentage(12.5) => "12.5%"
   */
  static formatPercentage(value: number, decimals: number = 1): string {
    return `${value.toFixed(decimals)}%`;
  }

  /**
   * Format large numbers
   * @example formatNumber(1234567) => "1,234,567"
   */
  static formatNumber(value: number, decimals: number = 0): string {
    const formatter = new Intl.NumberFormat(this.LOCALE, {
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
    });
    return formatter.format(value);
  }
}
```

---

### 2. React Currency Input Component

**File:** `src/components/inputs/CurrencyInput.tsx`

```typescript
import React, { useState } from 'react';
import { CurrencyFormatter } from '../../utils/currencyFormatter';

interface CurrencyInputProps {
  value: number;
  onChange: (value: number) => void;
  placeholder?: string;
  disabled?: boolean;
  error?: string;
}

export const CurrencyInput: React.FC<CurrencyInputProps> = ({
  value,
  onChange,
  placeholder = '0.00',
  disabled = false,
  error,
}) => {
  const [displayValue, setDisplayValue] = useState(
    value > 0 ? CurrencyFormatter.formatNumber(value, 2) : ''
  );

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const input = e.target.value;
    const numericValue = CurrencyFormatter.parseInput(input);

    setDisplayValue(input);
    onChange(numericValue);
  };

  const handleBlur = () => {
    if (value > 0) {
      setDisplayValue(CurrencyFormatter.formatNumber(value, 2));
    } else {
      setDisplayValue('');
    }
  };

  return (
    <div className="currency-input-wrapper">
      <div className="currency-input">
        <span className="currency-symbol">Le</span>
        <input
          type="text"
          value={displayValue}
          onChange={handleChange}
          onBlur={handleBlur}
          placeholder={placeholder}
          disabled={disabled}
          className={error ? 'error' : ''}
        />
      </div>
      {error && <span className="error-message">{error}</span>}
    </div>
  );
};
```

---

### 3. Usage Examples in React

```tsx
import { CurrencyFormatter } from './utils/currencyFormatter';
import { CurrencyInput } from './components/inputs/CurrencyInput';

function App() {
  const [amount, setAmount] = useState(0);
  const walletBalance = 15000.50;
  const transactionDate = new Date(Date.now() - 2 * 24 * 60 * 60 * 1000);

  return (
    <div>
      {/* Display wallet balance */}
      <p>{CurrencyFormatter.formatCurrency(walletBalance)}</p>
      {/* Output: "Le 15,000.50" */}

      {/* Display in compact form */}
      <p>{CurrencyFormatter.formatCompact(5000000)}</p>
      {/* Output: "Le 5.0M" */}

      {/* Display as TCC Coins */}
      <p>{CurrencyFormatter.formatCoins(walletBalance)}</p>
      {/* Output: "15,000.50 TCC Coins" */}

      {/* Display relative date */}
      <p>{CurrencyFormatter.formatDateRelative(transactionDate)}</p>
      {/* Output: "2 days ago" */}

      {/* Currency input */}
      <CurrencyInput
        value={amount}
        onChange={setAmount}
        placeholder="Enter amount"
      />
    </div>
  );
}
```

---

## Testing

### Flutter Tests

**File:** `test/utils/currency_formatter_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats currency with symbol', () {
      expect(
        CurrencyFormatter.formatCurrency(5000.50),
        'Le 5,000.50',
      );
    });

    test('formats currency without decimals', () {
      expect(
        CurrencyFormatter.formatCurrency(5000.50, showDecimals: false),
        'Le 5,001',
      );
    });

    test('formats compact currency', () {
      expect(
        CurrencyFormatter.formatCompact(1500000),
        'Le 1.5M',
      );
    });

    test('formats TCC coins', () {
      expect(
        CurrencyFormatter.formatCoins(5000.50),
        '5,000.50 TCC Coins',
      );
    });

    test('parses input correctly', () {
      expect(
        CurrencyFormatter.parseInput('Le 5,000.50'),
        5000.50,
      );
    });
  });
}
```

---

### React/Jest Tests

**File:** `src/utils/__tests__/currencyFormatter.test.ts`

```typescript
import { CurrencyFormatter } from '../currencyFormatter';

describe('CurrencyFormatter', () => {
  test('formats currency with symbol', () => {
    expect(CurrencyFormatter.formatCurrency(5000.50)).toBe('Le 5,000.50');
  });

  test('formats currency without decimals', () => {
    expect(
      CurrencyFormatter.formatCurrency(5000.50, { showDecimals: false })
    ).toBe('Le 5,001');
  });

  test('formats compact currency', () => {
    expect(CurrencyFormatter.formatCompact(1500000)).toBe('Le 1.5M');
  });

  test('formats TCC coins', () => {
    expect(CurrencyFormatter.formatCoins(5000.50)).toBe('5,000.50 TCC Coins');
  });

  test('parses input correctly', () => {
    expect(CurrencyFormatter.parseInput('Le 5,000.50')).toBe(5000.50);
  });
});
```

---

## Migration Guide

### Updating Figma Designs

1. **Search and Replace:**
   - Find all instances of `$` symbol
   - Replace with `Le` symbol
   - Update design system documentation

2. **Component Updates:**
   - Update all text layers showing currency
   - Update input field prefixes from `$` to `Le`
   - Update transaction history displays

3. **Examples to Update:**
   - Balance cards: `$ 340` → `Le 340`
   - Investment units: `$ 234` → `Le 234`
   - Transaction amounts: `$ 45.6` → `Le 45.6`

### Code Implementation

1. **Import formatter utility in all files displaying currency**
2. **Replace hardcoded `$` symbols with `CurrencyFormatter.formatCurrency()`**
3. **Update API responses to use proper currency code `SLL`**
4. **Add currency symbol to design system constants**
5. **Update all input fields to use currency input formatters**

---

## Best Practices

1. **Always use formatter utilities** - Never hardcode currency symbols
2. **Consistent decimal places** - Always show 2 decimal places for financial amounts
3. **Locale-aware formatting** - Use proper thousand separators (,) and decimal points (.)
4. **Input validation** - Always validate and sanitize user input before parsing
5. **Accessibility** - Include currency information in screen readers
6. **Testing** - Test with edge cases (0, negatives, very large numbers)
7. **Documentation** - Document currency format in API responses

---

## FAQ

**Q: Why not use $ for simplified UX?**
A: Using the correct local currency symbol builds trust and complies with financial regulations.

**Q: What if users prefer seeing $?**
A: Users can be educated through onboarding that "Le" is their local currency. The 1:1 TCC Coin conversion makes it simple.

**Q: How do we handle different currencies in the future?**
A: The formatter utilities are designed to be configurable. Simply update the currency constants.

**Q: Should we support currency conversion?**
A: Not in MVP. TCC Coins are pegged 1:1 with Sierra Leonean Leone.

---

## Summary

✅ **Decision:** Use `Le` symbol for Sierra Leonean Leone
✅ **Utilities:** Comprehensive formatters for Flutter and React
✅ **Components:** Ready-to-use currency input components
✅ **Testing:** Test suites included
✅ **Migration:** Clear path to update Figma designs

This ensures consistency, regulatory compliance, and user trust across the entire TCC Application.
