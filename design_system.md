# TCC Application - Design System & Theme Specification

## Overview

This design system defines the comprehensive visual language, components, and patterns for the TCC Application across all platforms (Flutter mobile apps and React web admin panel).

---

## Color Palette

### Primary Colors

```dart
// Flutter
static const Color primaryBlue = Color(0xFF5B6EF5);
static const Color primaryBlueDark = Color(0xFF4A5CD4);
static const Color primaryBlueLight = Color(0xFF7C8DF7);

// CSS/React
--primary-blue: #5B6EF5;
--primary-blue-dark: #4A5CD4;
--primary-blue-light: #7C8DF7;
```

### Secondary Colors

```dart
// Flutter
static const Color secondaryYellow = Color(0xFFF9B234);
static const Color secondaryYellowDark = Color(0xFFE6A020);
static const Color secondaryGreen = Color(0xFF00C896);
static const Color secondaryGreenLight = Color(0xFF4AE4BC);

// CSS/React
--secondary-yellow: #F9B234;
--secondary-yellow-dark: #E6A020;
--secondary-green: #00C896;
--secondary-green-light: #4AE4BC;
```

### Semantic Colors

```dart
// Flutter
static const Color success = Color(0xFF00C896);
static const Color warning = Color(0xFFF9B234);
static const Color error = Color(0xFFFF5757);
static const Color info = Color(0xFF5B6EF5);

// CSS/React
--color-success: #00C896;
--color-warning: #F9B234;
--color-error: #FF5757;
--color-info: #5B6EF5;
```

### Neutral Colors

```dart
// Flutter
static const Color black = Color(0xFF1A1A1A);
static const Color gray900 = Color(0xFF2D2D2D);
static const Color gray800 = Color(0xFF4A4A4A);
static const Color gray700 = Color(0xFF6B7280);
static const Color gray600 = Color(0xFF9CA3AF);
static const Color gray500 = Color(0xFFB5B5B5);
static const Color gray400 = Color(0xFFD1D5DB);
static const Color gray300 = Color(0xFFE5E7EB);
static const Color gray200 = Color(0xFFF3F4F6);
static const Color gray100 = Color(0xFFF9FAFB);
static const Color white = Color(0xFFFFFFFF);

// CSS/React
--color-black: #1A1A1A;
--color-gray-900: #2D2D2D;
--color-gray-800: #4A4A4A;
--color-gray-700: #6B7280;
--color-gray-600: #9CA3AF;
--color-gray-500: #B5B5B5;
--color-gray-400: #D1D5DB;
--color-gray-300: #E5E7EB;
--color-gray-200: #F3F4F6;
--color-gray-100: #F9FAFB;
--color-white: #FFFFFF;
```

### Gradient Colors

```dart
// Flutter - Primary Button Gradient
LinearGradient primaryGradient = LinearGradient(
  colors: [Color(0xFF5B6EF5), Color(0xFF7C8DF7)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// Flutter - Card Gradient (Yellow)
LinearGradient yellowCardGradient = LinearGradient(
  colors: [Color(0xFFF9B234), Color(0xFFFDD97D)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Flutter - Card Gradient (Green)
LinearGradient greenCardGradient = LinearGradient(
  colors: [Color(0xFF00C896), Color(0xFF4AE4BC)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// CSS/React
--gradient-primary: linear-gradient(90deg, #5B6EF5 0%, #7C8DF7 100%);
--gradient-yellow: linear-gradient(135deg, #F9B234 0%, #FDD97D 100%);
--gradient-green: linear-gradient(135deg, #00C896 0%, #4AE4BC 100%);
```

### Background Colors

```dart
// Flutter
static const Color backgroundPrimary = Color(0xFFFFFFFF);
static const Color backgroundSecondary = Color(0xFFF9FAFB);
static const Color backgroundTertiary = Color(0xFFF3F4F6);

// CSS/React
--bg-primary: #FFFFFF;
--bg-secondary: #F9FAFB;
--bg-tertiary: #F3F4F6;
```

---

## Typography

### Font Family

**Primary Font:** SF Pro Display (iOS), Roboto (Android), Inter (Web)

```dart
// Flutter
static const String fontFamily = 'SFProDisplay'; // iOS
static const String fontFamily = 'Roboto'; // Android

// CSS/React
font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', sans-serif;
```

### Font Sizes

```dart
// Flutter
static const double fontSizeH1 = 32.0;
static const double fontSizeH2 = 28.0;
static const double fontSizeH3 = 24.0;
static const double fontSizeH4 = 20.0;
static const double fontSizeH5 = 18.0;
static const double fontSizeBody1 = 16.0;
static const double fontSizeBody2 = 14.0;
static const double fontSizeCaption = 12.0;
static const double fontSizeSmall = 10.0;

// CSS/React
--font-size-h1: 32px;
--font-size-h2: 28px;
--font-size-h3: 24px;
--font-size-h4: 20px;
--font-size-h5: 18px;
--font-size-body1: 16px;
--font-size-body2: 14px;
--font-size-caption: 12px;
--font-size-small: 10px;
```

### Font Weights

```dart
// Flutter
static const FontWeight light = FontWeight.w300;
static const FontWeight regular = FontWeight.w400;
static const FontWeight medium = FontWeight.w500;
static const FontWeight semiBold = FontWeight.w600;
static const FontWeight bold = FontWeight.w700;

// CSS/React
--font-weight-light: 300;
--font-weight-regular: 400;
--font-weight-medium: 500;
--font-weight-semibold: 600;
--font-weight-bold: 700;
```

### Text Styles

```dart
// Flutter
TextStyle h1 = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.w700,
  color: AppColors.black,
  height: 1.2,
);

TextStyle h2 = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w700,
  color: AppColors.black,
  height: 1.3,
);

TextStyle h3 = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w700,
  color: AppColors.black,
  height: 1.3,
);

TextStyle h4 = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  color: AppColors.black,
  height: 1.4,
);

TextStyle body1 = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  color: AppColors.black,
  height: 1.5,
);

TextStyle body2 = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: AppColors.gray700,
  height: 1.5,
);

TextStyle caption = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  color: AppColors.gray600,
  height: 1.4,
);

TextStyle button = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: AppColors.white,
  height: 1.2,
);
```

---

## Spacing System

### Padding & Margins

```dart
// Flutter
static const double space4 = 4.0;
static const double space8 = 8.0;
static const double space12 = 12.0;
static const double space16 = 16.0;
static const double space20 = 20.0;
static const double space24 = 24.0;
static const double space32 = 32.0;
static const double space40 = 40.0;
static const double space48 = 48.0;
static const double space64 = 64.0;

// CSS/React
--space-4: 4px;
--space-8: 8px;
--space-12: 12px;
--space-16: 16px;
--space-20: 20px;
--space-24: 24px;
--space-32: 32px;
--space-40: 40px;
--space-48: 48px;
--space-64: 64px;
```

### Screen Padding

```dart
// Flutter
static const double screenPaddingHorizontal = 20.0;
static const double screenPaddingVertical = 16.0;

// CSS/React
--screen-padding-x: 20px;
--screen-padding-y: 16px;
```

---

## Border Radius

```dart
// Flutter
static const double radiusSmall = 8.0;
static const double radiusMedium = 12.0;
static const double radiusLarge = 16.0;
static const double radiusXLarge = 24.0;
static const double radiusFull = 999.0; // Pill shape

// CSS/React
--radius-small: 8px;
--radius-medium: 12px;
--radius-large: 16px;
--radius-xlarge: 24px;
--radius-full: 999px;
```

---

## Elevation & Shadows

```dart
// Flutter
static BoxShadow shadowSmall = BoxShadow(
  color: Colors.black.withOpacity(0.05),
  blurRadius: 4,
  offset: Offset(0, 2),
);

static BoxShadow shadowMedium = BoxShadow(
  color: Colors.black.withOpacity(0.08),
  blurRadius: 8,
  offset: Offset(0, 4),
);

static BoxShadow shadowLarge = BoxShadow(
  color: Colors.black.withOpacity(0.12),
  blurRadius: 16,
  offset: Offset(0, 8),
);

static BoxShadow shadowXLarge = BoxShadow(
  color: Colors.black.withOpacity(0.15),
  blurRadius: 24,
  offset: Offset(0, 12),
);

// CSS/React
--shadow-small: 0 2px 4px rgba(0, 0, 0, 0.05);
--shadow-medium: 0 4px 8px rgba(0, 0, 0, 0.08);
--shadow-large: 0 8px 16px rgba(0, 0, 0, 0.12);
--shadow-xlarge: 0 12px 24px rgba(0, 0, 0, 0.15);
```

---

## Component Specifications

### 1. Buttons

#### Primary Button

```dart
// Flutter
Container(
  width: double.infinity,
  height: 56,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF5B6EF5), Color(0xFF7C8DF7)],
    ),
    borderRadius: BorderRadius.circular(999),
    boxShadow: [
      BoxShadow(
        color: Color(0xFF5B6EF5).withOpacity(0.3),
        blurRadius: 12,
        offset: Offset(0, 6),
      ),
    ],
  ),
  child: Text('Button Text', style: buttonTextStyle),
);

// CSS/React
.btn-primary {
  width: 100%;
  height: 56px;
  background: linear-gradient(90deg, #5B6EF5 0%, #7C8DF7 100%);
  border-radius: 999px;
  border: none;
  box-shadow: 0 6px 12px rgba(91, 110, 245, 0.3);
  font-size: 16px;
  font-weight: 600;
  color: #FFFFFF;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 16px rgba(91, 110, 245, 0.4);
}

.btn-primary:active {
  transform: translateY(0);
}
```

#### Secondary Button

```dart
// Flutter
Container(
  width: double.infinity,
  height: 56,
  decoration: BoxDecoration(
    color: Colors.white,
    border: Border.all(color: Color(0xFF5B6EF5), width: 2),
    borderRadius: BorderRadius.circular(999),
  ),
  child: Text('Button Text',
    style: TextStyle(color: Color(0xFF5B6EF5), fontWeight: FontWeight.w600),
  ),
);

// CSS/React
.btn-secondary {
  width: 100%;
  height: 56px;
  background: #FFFFFF;
  border: 2px solid #5B6EF5;
  border-radius: 999px;
  font-size: 16px;
  font-weight: 600;
  color: #5B6EF5;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-secondary:hover {
  background: #F9FAFB;
}
```

#### Text Button

```dart
// Flutter
TextButton(
  child: Text('Button Text',
    style: TextStyle(
      color: Color(0xFF5B6EF5),
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
  ),
);

// CSS/React
.btn-text {
  background: transparent;
  border: none;
  color: #5B6EF5;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  padding: 8px 16px;
  transition: opacity 0.3s ease;
}

.btn-text:hover {
  opacity: 0.8;
}
```

---

### 2. Input Fields

```dart
// Flutter
Container(
  height: 56,
  decoration: BoxDecoration(
    color: Color(0xFFF3F4F6),
    borderRadius: BorderRadius.circular(12),
  ),
  child: TextField(
    decoration: InputDecoration(
      hintText: 'Placeholder',
      hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      prefixIcon: Icon(Icons.email, color: Color(0xFF6B7280)),
    ),
  ),
);

// CSS/React
.input-field {
  width: 100%;
  height: 56px;
  background: #F3F4F6;
  border: none;
  border-radius: 12px;
  padding: 18px 20px 18px 52px;
  font-size: 16px;
  color: #1A1A1A;
  transition: all 0.3s ease;
}

.input-field::placeholder {
  color: #9CA3AF;
}

.input-field:focus {
  outline: none;
  background: #FFFFFF;
  box-shadow: 0 0 0 2px #5B6EF5;
}

.input-wrapper {
  position: relative;
}

.input-icon {
  position: absolute;
  left: 20px;
  top: 50%;
  transform: translateY(-50%);
  color: #6B7280;
}
```

---

### 3. Cards

#### Balance Card (with gradient)

```dart
// Flutter
Container(
  width: double.infinity,
  height: 180,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF5B6EF5), Color(0xFF7C8DF7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Color(0xFF5B6EF5).withOpacity(0.3),
        blurRadius: 16,
        offset: Offset(0, 8),
      ),
    ],
  ),
  padding: EdgeInsets.all(24),
);

// CSS/React
.balance-card {
  width: 100%;
  height: 180px;
  background: linear-gradient(135deg, #5B6EF5 0%, #7C8DF7 100%);
  border-radius: 24px;
  box-shadow: 0 8px 16px rgba(91, 110, 245, 0.3);
  padding: 24px;
}
```

#### Info Card (Yellow/Green)

```dart
// Flutter - Yellow
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFFF9B234), Color(0xFFFDD97D)],
    ),
    borderRadius: BorderRadius.circular(16),
  ),
  padding: EdgeInsets.all(20),
);

// Flutter - Green
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF00C896), Color(0xFF4AE4BC)],
    ),
    borderRadius: BorderRadius.circular(16),
  ),
  padding: EdgeInsets.all(20),
);

// CSS/React
.info-card-yellow {
  background: linear-gradient(135deg, #F9B234 0%, #FDD97D 100%);
  border-radius: 16px;
  padding: 20px;
}

.info-card-green {
  background: linear-gradient(135deg, #00C896 0%, #4AE4BC 100%);
  border-radius: 16px;
  padding: 20px;
}
```

#### White Card

```dart
// Flutter
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ],
  ),
  padding: EdgeInsets.all(20),
);

// CSS/React
.card-white {
  background: #FFFFFF;
  border-radius: 16px;
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.05);
  padding: 20px;
}
```

---

### 4. Bottom Navigation

```dart
// Flutter
BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
  selectedItemColor: Color(0xFF5B6EF5),
  unselectedItemColor: Color(0xFF9CA3AF),
  selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Vault'),
    BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Pay'),
    BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Gift'),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
    BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'More'),
  ],
);

// CSS/React
.bottom-nav {
  display: flex;
  justify-content: space-around;
  align-items: center;
  background: #FFFFFF;
  border-top: 1px solid #E5E7EB;
  height: 64px;
  padding: 8px 0;
}

.nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  color: #9CA3AF;
  font-size: 12px;
  font-weight: 400;
  transition: color 0.3s ease;
}

.nav-item.active {
  color: #5B6EF5;
  font-weight: 600;
}

.nav-item-icon {
  font-size: 24px;
}
```

---

### 5. Tabs

```dart
// Flutter
Container(
  decoration: BoxDecoration(
    color: Color(0xFFF3F4F6),
    borderRadius: BorderRadius.circular(999),
  ),
  padding: EdgeInsets.all(4),
  child: Row(
    children: [
      // Active Tab
      Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Color(0xFF5B6EF5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text('Successful',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      // Inactive Tab
      Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Text('Pending',
          style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w400),
        ),
      ),
    ],
  ),
);

// CSS/React
.tabs-container {
  background: #F3F4F6;
  border-radius: 999px;
  padding: 4px;
  display: flex;
  gap: 4px;
}

.tab-item {
  padding: 12px 24px;
  border-radius: 999px;
  font-size: 14px;
  font-weight: 400;
  color: #9CA3AF;
  cursor: pointer;
  transition: all 0.3s ease;
}

.tab-item.active {
  background: #5B6EF5;
  color: #FFFFFF;
  font-weight: 600;
}
```

---

### 6. List Items (Transaction/History)

```dart
// Flutter
Container(
  padding: EdgeInsets.symmetric(vertical: 16),
  child: Row(
    children: [
      // Icon
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.phone_android, color: Color(0xFF5B6EF5)),
      ),
      SizedBox(width: 16),
      // Content
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mobile recharge', style: h5),
            SizedBox(height: 4),
            Text('89273 89834', style: caption),
          ],
        ),
      ),
      // Amount
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('\$ 45.6', style: h5),
          SizedBox(height: 4),
          Text('Debited from XX9864', style: caption),
        ],
      ),
    ],
  ),
);

// CSS/React
.list-item {
  display: flex;
  align-items: center;
  padding: 16px 0;
  border-bottom: 1px solid #F3F4F6;
}

.list-item-icon {
  width: 48px;
  height: 48px;
  background: #F3F4F6;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #5B6EF5;
}

.list-item-content {
  flex: 1;
  margin-left: 16px;
}

.list-item-title {
  font-size: 16px;
  font-weight: 600;
  color: #1A1A1A;
  margin-bottom: 4px;
}

.list-item-subtitle {
  font-size: 12px;
  color: #9CA3AF;
}

.list-item-amount {
  text-align: right;
}

.list-item-value {
  font-size: 16px;
  font-weight: 600;
  color: #1A1A1A;
  margin-bottom: 4px;
}

.list-item-detail {
  font-size: 12px;
  color: #9CA3AF;
}
```

---

### 7. Status Badges

```dart
// Flutter
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: Color(0xFF00C896).withOpacity(0.1),
    borderRadius: BorderRadius.circular(999),
  ),
  child: Text('Successful',
    style: TextStyle(
      color: Color(0xFF00C896),
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  ),
);

// Pending
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: Color(0xFFF9B234).withOpacity(0.1),
    borderRadius: BorderRadius.circular(999),
  ),
  child: Text('Pending',
    style: TextStyle(
      color: Color(0xFFF9B234),
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  ),
);

// CSS/React
.badge {
  padding: 6px 12px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 600;
}

.badge-success {
  background: rgba(0, 200, 150, 0.1);
  color: #00C896;
}

.badge-pending {
  background: rgba(249, 178, 52, 0.1);
  color: #F9B234;
}

.badge-error {
  background: rgba(255, 87, 87, 0.1);
  color: #FF5757;
}

.badge-processing {
  background: rgba(91, 110, 245, 0.1);
  color: #5B6EF5;
}
```

---

### 8. OTP Input

```dart
// Flutter
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: List.generate(6, (index) =>
    Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: index == currentIndex
            ? Color(0xFF5B6EF5)
            : Colors.transparent,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(otpDigits[index],
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
    ),
  ),
);

// CSS/React
.otp-container {
  display: flex;
  justify-content: space-between;
  gap: 8px;
}

.otp-input {
  width: 48px;
  height: 56px;
  background: #F3F4F6;
  border: 2px solid transparent;
  border-radius: 12px;
  text-align: center;
  font-size: 24px;
  font-weight: 600;
  color: #1A1A1A;
  transition: all 0.3s ease;
}

.otp-input:focus {
  outline: none;
  border-color: #5B6EF5;
  background: #FFFFFF;
}
```

---

### 9. Loading/Pending States

```dart
// Flutter - Full Screen Pending
Container(
  color: Color(0xFFF9B234),
  child: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.access_time, size: 64, color: Colors.white),
        ),
        SizedBox(height: 40),
        Text('Your request is under process.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 16),
        Text('We will update the status in the next 24-48 hours.',
          style: TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  ),
);

// CSS/React
.pending-screen {
  background: #F9B234;
  height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px;
}

.pending-icon {
  width: 120px;
  height: 120px;
  background: rgba(255, 255, 255, 0.3);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 40px;
}

.pending-title {
  color: #FFFFFF;
  font-size: 24px;
  font-weight: 700;
  margin-bottom: 16px;
  text-align: center;
}

.pending-subtitle {
  color: #FFFFFF;
  font-size: 16px;
  text-align: center;
  max-width: 400px;
}
```

---

### 10. Charts/Graphs

```dart
// Flutter - Area Chart for investments
Container(
  height: 200,
  child: CustomPaint(
    painter: AreaChartPainter(
      color: Color(0xFF5B6EF5),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF5B6EF5).withOpacity(0.4),
          Color(0xFF5B6EF5).withOpacity(0.0),
        ],
      ),
    ),
  ),
);

// CSS/React - Using Chart.js or Recharts
const chartOptions = {
  colors: ['#5B6EF5'],
  fill: {
    type: 'gradient',
    gradient: {
      shadeIntensity: 1,
      opacityFrom: 0.4,
      opacityTo: 0,
      stops: [0, 100],
    },
  },
  stroke: {
    width: 3,
    curve: 'smooth',
  },
};
```

---

### 11. Illustrations

**Style Guide:**
- Use flat design with minimal gradients
- Primary colors: Blue (#5B6EF5) and Purple (#7C8DF7)
- Accent colors: Use sparingly (plants, decorative elements)
- Characters: Modern, friendly, diverse
- Shadows: Subtle, purple-tinted (#B5B5F7)

**Usage:**
- Onboarding screens
- Empty states
- Success/Error screens
- Feature explanations

---

### 12. Icons

**Icon Style:**
- Outlined icons (stroke width: 2px)
- Size: 24x24 (standard), 20x20 (small), 32x32 (large)
- Color: Match context (primary, gray, white)

**Icon Library:**
- Flutter: Material Icons, Cupertino Icons
- React: Heroicons, Lucide Icons, Material Icons

---

## Screen Layouts

### Mobile Screen Structure

```dart
// Flutter
Scaffold(
  backgroundColor: Colors.white,
  appBar: AppBar(
    elevation: 0,
    backgroundColor: Colors.white,
    title: Text('Screen Title', style: h3),
    actions: [
      IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
    ],
  ),
  body: SafeArea(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content here
          ],
        ),
      ),
    ),
  ),
  bottomNavigationBar: BottomNavigationBar(...),
);
```

### Web Admin Layout

```css
.admin-layout {
  display: grid;
  grid-template-columns: 280px 1fr;
  height: 100vh;
}

.sidebar {
  background: #1A1A1A;
  color: #FFFFFF;
  padding: 24px;
}

.main-content {
  background: #F9FAFB;
  overflow-y: auto;
}

.topbar {
  background: #FFFFFF;
  height: 64px;
  border-bottom: 1px solid #E5E7EB;
  padding: 0 32px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.content-area {
  padding: 32px;
}
```

---

## Animation & Transitions

### Timing Functions

```dart
// Flutter
static const Duration durationFast = Duration(milliseconds: 150);
static const Duration durationNormal = Duration(milliseconds: 300);
static const Duration durationSlow = Duration(milliseconds: 500);

static const Curve curveStandard = Curves.easeInOut;
static const Curve curveDecelerate = Curves.easeOut;
static const Curve curveAccelerate = Curves.easeIn;

// CSS/React
--duration-fast: 150ms;
--duration-normal: 300ms;
--duration-slow: 500ms;

--ease-standard: cubic-bezier(0.4, 0.0, 0.2, 1);
--ease-decelerate: cubic-bezier(0.0, 0.0, 0.2, 1);
--ease-accelerate: cubic-bezier(0.4, 0.0, 1, 1);
```

### Common Animations

```dart
// Flutter - Fade In
FadeTransition(
  opacity: _animation,
  child: child,
);

// Flutter - Slide Up
SlideTransition(
  position: Tween<Offset>(
    begin: Offset(0, 0.3),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  )),
  child: child,
);

// CSS/React
@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

@keyframes slideUp {
  from {
    transform: translateY(20px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

.fade-in {
  animation: fadeIn 300ms ease-out;
}

.slide-up {
  animation: slideUp 300ms ease-out;
}
```

---

## Responsive Breakpoints (Web)

```css
/* Mobile */
@media (max-width: 640px) {
  --screen-padding-x: 16px;
}

/* Tablet */
@media (min-width: 641px) and (max-width: 1024px) {
  --screen-padding-x: 24px;
}

/* Desktop */
@media (min-width: 1025px) {
  --screen-padding-x: 32px;
}

/* Breakpoints */
--breakpoint-sm: 640px;
--breakpoint-md: 768px;
--breakpoint-lg: 1024px;
--breakpoint-xl: 1280px;
--breakpoint-2xl: 1536px;
```

---

## Accessibility

### Color Contrast

All text must meet WCAG AA standards:
- Normal text: 4.5:1 minimum
- Large text (18px+): 3:1 minimum
- UI components: 3:1 minimum

### Touch Targets

- Minimum size: 44x44 dp (Flutter) / 44x44 px (Web)
- Spacing between targets: 8px minimum

### Screen Reader Support

```dart
// Flutter
Semantics(
  label: 'Add money button',
  hint: 'Tap to add money to your wallet',
  button: true,
  child: ElevatedButton(...),
);

// React
<button aria-label="Add money to wallet">
  Add Money
</button>
```

---

## File Structure

### Flutter

```
lib/
├── theme/
│   ├── app_colors.dart
│   ├── app_text_styles.dart
│   ├── app_theme.dart
│   ├── app_dimensions.dart
│   └── app_shadows.dart
├── widgets/
│   ├── buttons/
│   │   ├── primary_button.dart
│   │   ├── secondary_button.dart
│   │   └── text_button.dart
│   ├── cards/
│   │   ├── balance_card.dart
│   │   ├── info_card.dart
│   │   └── white_card.dart
│   └── inputs/
│       ├── text_input.dart
│       ├── otp_input.dart
│       └── dropdown_input.dart
```

### React

```
src/
├── styles/
│   ├── variables.css
│   ├── colors.css
│   ├── typography.css
│   └── components.css
├── components/
│   ├── buttons/
│   │   ├── PrimaryButton.tsx
│   │   ├── SecondaryButton.tsx
│   │   └── TextButton.tsx
│   ├── cards/
│   │   ├── BalanceCard.tsx
│   │   ├── InfoCard.tsx
│   │   └── WhiteCard.tsx
│   └── inputs/
│       ├── TextInput.tsx
│       ├── OTPInput.tsx
│       └── Dropdown.tsx
```

---

## Best Practices

1. **Consistency:** Use design tokens consistently across all platforms
2. **Accessibility:** Always consider color contrast, touch targets, and screen readers
3. **Performance:** Optimize images, use lazy loading for heavy components
4. **Responsiveness:** Test on multiple screen sizes and orientations
5. **Dark Mode:** Prepare alternative color schemes for future dark mode support
6. **Documentation:** Keep this design system updated as new patterns emerge
7. **Component Reusability:** Create reusable components following this system
8. **Testing:** Test components in isolation and in various combinations

---

## Implementation Checklist

### Phase 1: Foundation
- [ ] Setup color constants in Flutter and React
- [ ] Implement typography system
- [ ] Create spacing utilities
- [ ] Define shadow system

### Phase 2: Core Components
- [ ] Buttons (Primary, Secondary, Text)
- [ ] Input fields (Text, Password, Dropdown)
- [ ] Cards (Balance, Info, White)
- [ ] Navigation components

### Phase 3: Complex Components
- [ ] OTP Input
- [ ] Status badges
- [ ] List items
- [ ] Charts
- [ ] Tabs

### Phase 4: Screens
- [ ] Authentication screens
- [ ] Dashboard/Home
- [ ] Transaction history
- [ ] Profile/Settings
- [ ] Investment screens

---

## Version History

**v1.0.0** - October 2025
- Initial design system based on Figma screenshots
- Complete color palette definition
- Typography system
- Core component specifications
- Layout guidelines

---

## Contact & Support

For questions or suggestions about this design system, contact the development team.

**Last Updated:** October 26, 2025
