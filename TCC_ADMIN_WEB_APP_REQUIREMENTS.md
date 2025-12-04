# TCC Admin Web Application - Complete Requirements & Specification

## 📋 Project Overview

**Date**: January 2025
**Platform**: Flutter Web (Desktop-optimized)
**Target**: Web browsers (Chrome, Firefox, Safari, Edge)
**Theme**: Professional Dark Sidebar + Light Content
**Purpose**: Central control panel for managing the TCC ecosystem

**Part of**: TCC Platform Ecosystem
**Integrates with**:
- TCC Backend API (Node.js/TypeScript/PostgreSQL)
- TCC User Mobile App (Flutter)
- TCC Agent Mobile App (Flutter)

---

## 🌐 TCC Ecosystem Context

This admin web application is the **third piece** of the TCC platform:

```
TCC Platform
├── tcc_backend/                    # ✅ Node.js/TypeScript Backend (Complete)
│   ├── 70+ API endpoints
│   ├── PostgreSQL database (40+ tables)
│   ├── JWT authentication
│   └── Complete infrastructure
│
├── tcc_user_mobile_client/         # ✅ Flutter User App (Complete)
│   ├── Authentication & KYC
│   ├── Investment management
│   ├── Bill payments & e-voting
│   └── Blue theme (#5B6EF5)
│
├── tcc_agent_client/                # ✅ Flutter Agent App (Complete)
│   ├── Agent verification
│   ├── Transaction processing
│   ├── Commission tracking
│   └── Orange theme (#FF8C42)
│
└── tcc_admin_client/                # 🔨 THIS PROJECT (To be built)
    ├── Admin control panel
    ├── User/Agent management
    ├── Transaction oversight
    └── Dark professional theme
```

---

## 🎯 Project Purpose

The TCC Admin Web Application serves as the **command center** for platform administrators to:
- Verify and approve user/agent KYC documents
- Manage deposits, withdrawals, and transactions
- Configure investment products, tenures, and returns
- Create and monitor e-voting polls
- Generate reports and analytics
- Configure system settings and fees
- Monitor security events and fraud detection
- Manage content (Terms, Privacy Policy, Agreements)

**Backend Integration**: Connects to the existing **tcc_backend** Node.js/TypeScript API

---

## 🏗️ Technology Stack

### Frontend Framework
- **Flutter Web** (Dart 3.x, Flutter 3.x)
- **Responsive Design**: Desktop-first, tablet-compatible
- **Hot Reload**: Rapid development
- **Single Codebase**: Consistent with mobile apps

### State Management
- **Provider Pattern**: ChangeNotifier for reactive state
- **AuthProvider**: Admin authentication and session management
- **DataProvider**: API data caching and management

### Routing
- **go_router**: Declarative routing with deep linking
- **Route Guards**: Role-based access control
- **Nested Routes**: Sidebar navigation structure

### UI Framework
- **Material Design 3**: Modern, accessible components
- **Custom Theme**: Dark sidebar + light content area
- **Responsive Grid**: Adaptive layouts

### Data Visualization
- **fl_chart**: Charts and graphs (line, bar, pie, area)
- **Custom Widgets**: Stat cards, KPI indicators

### Data Tables
- **data_table_2**: Advanced table features
- **Sorting**: Multi-column sorting
- **Filtering**: Dynamic filters
- **Pagination**: Server-side pagination
- **Export**: CSV/Excel export functionality

### File Handling
- **file_picker**: Document uploads (agreements, insurance)
- **image_picker**: View uploaded KYC documents
- **flutter_image_compress**: Optimize image viewing
- **pdf**: Generate/view PDF reports

### HTTP & API
- **dio**: Advanced HTTP client
- **Interceptors**: Token injection, error handling
- **Retry Logic**: Auto-retry failed requests

### Forms & Validation
- **flutter_form_builder**: Complex forms
- **form_builder_validators**: Validation rules

### Utilities
- **intl**: Date/time/currency formatting (SLL)
- **url_launcher**: Open external links
- **shared_preferences**: Session persistence
- **flutter_secure_storage**: Token storage

---

## 🎨 Design System & Theme

### Color Palette (Admin-Specific)

#### Primary Colors
```dart
// Professional dark theme for admin
static const Color primaryDark = Color(0xFF1A1A1A);      // Sidebar background
static const Color primaryGray = Color(0xFF2D2D2D);      // Sidebar hover
static const Color accentBlue = Color(0xFF5B6EF5);       // Accent (consistent with user app)
static const Color accentBlueLight = Color(0xFF7C8DF7);  // Hover states
```

#### Background Colors
```dart
static const Color bgPrimary = Color(0xFFFFFFFF);        // Card backgrounds
static const Color bgSecondary = Color(0xFFF9FAFB);      // Content area background
static const Color bgTertiary = Color(0xFFF3F4F6);       // Input backgrounds
```

#### Semantic Colors (Consistent with mobile apps)
```dart
static const Color success = Color(0xFF00C896);          // Approved, Success
static const Color warning = Color(0xFFF9B234);          // Pending, Warning
static const Color error = Color(0xFFFF5757);            // Rejected, Error
static const Color info = Color(0xFF5B6EF5);             // Info, Processing
```

#### Status Colors
```dart
// User/Agent Status
static const Color statusApproved = Color(0xFF00C896);   // Green
static const Color statusPending = Color(0xFFF9B234);    // Yellow
static const Color statusRejected = Color(0xFFFF5757);   // Red
static const Color statusActive = Color(0xFF4CAF50);     // Green (agents)
static const Color statusInactive = Color(0xFF9E9E9E);   // Gray

// Transaction Status
static const Color statusCompleted = Color(0xFF00C896);
static const Color statusProcessing = Color(0xFF5B6EF5);
static const Color statusFailed = Color(0xFFFF5757);
static const Color statusCancelled = Color(0xFF9E9E9E);

// Investment Status
static const Color statusPaid = Color(0xFF00C896);
static const Color statusMatured = Color(0xFFF9B234);
static const Color statusOngoing = Color(0xFF5B6EF5);
```

#### Text Colors
```dart
static const Color textPrimary = Color(0xFF1A1A1A);      // Headings
static const Color textSecondary = Color(0xFF6B7280);    // Body text
static const Color textTertiary = Color(0xFF9CA3AF);     // Captions
static const Color textWhite = Color(0xFFFFFFFF);        // Sidebar text
static const Color textMuted = Color(0xFFB5B5B5);        // Disabled text
```

### Typography

```dart
// Font Family
static const String fontFamily = 'Inter';

// Font Sizes
static const double fontSizeH1 = 32.0;   // Page titles
static const double fontSizeH2 = 28.0;   // Section headers
static const double fontSizeH3 = 24.0;   // Card headers
static const double fontSizeH4 = 20.0;   // Subsection headers
static const double fontSizeH5 = 18.0;   // Large body
static const double fontSizeBody1 = 16.0; // Body text
static const double fontSizeBody2 = 14.0; // Small body
static const double fontSizeCaption = 12.0; // Captions, labels
static const double fontSizeSmall = 10.0;  // Tiny labels

// Font Weights
static const FontWeight light = FontWeight.w300;
static const FontWeight regular = FontWeight.w400;
static const FontWeight medium = FontWeight.w500;
static const FontWeight semiBold = FontWeight.w600;
static const FontWeight bold = FontWeight.w700;
```

### Layout Specifications

#### Desktop Layout (1920x1080 and above)
```
┌───────────────────────────────────────────────────────┐
│  Sidebar (280px)  │  Main Content Area               │
│                   │                                   │
│  Logo             │  ┌─ Topbar (64px)               │
│                   │  │  Search | Notifications | User│
│  Navigation       │  └────────────────────────────── │
│  - Dashboard      │                                   │
│  - Users          │  Content Area (padding: 32px)    │
│  - Agents         │                                   │
│  - Transactions   │  [Page Content]                  │
│  - Investments    │                                   │
│  - Bill Payments  │                                   │
│  - E-Voting       │                                   │
│  - Reports        │                                   │
│  - Settings       │                                   │
│                   │                                   │
│  [User Profile]   │                                   │
└───────────────────────────────────────────────────────┘
```

#### Tablet Layout (768px - 1024px)
- Collapsible sidebar (icon only, 64px)
- Expands on hover or click
- Content area adjusts dynamically

#### Spacing System
```dart
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
```

### Component Specifications

#### Sidebar Navigation Item
```dart
// Active State
Container(
  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  decoration: BoxDecoration(
    color: Color(0xFF5B6EF5),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    children: [
      Icon(Icons.dashboard, color: Colors.white, size: 20),
      SizedBox(width: 12),
      Text('Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    ],
  ),
);

// Inactive State
Container(
  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  child: Row(
    children: [
      Icon(Icons.dashboard, color: Color(0xFF9CA3AF), size: 20),
      SizedBox(width: 12),
      Text('Dashboard', style: TextStyle(color: Color(0xFF9CA3AF))),
    ],
  ),
);
```

#### Stat Card
```dart
Container(
  padding: EdgeInsets.all(24),
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
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.people, color: Color(0xFF5B6EF5), size: 32),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFF00C896).withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_upward, color: Color(0xFF00C896), size: 12),
                Text('+12%', style: TextStyle(color: Color(0xFF00C896), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      SizedBox(height: 16),
      Text('Total Users', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
      SizedBox(height: 8),
      Text('15,234', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
    ],
  ),
);
```

#### Data Table Row
```dart
// Table header styling
DataTable(
  headingRowColor: MaterialStateProperty.all(Color(0xFFF9FAFB)),
  headingTextStyle: TextStyle(
    color: Color(0xFF6B7280),
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  ),
  dataRowHeight: 72,
  columns: [...],
  rows: [...],
);
```

#### Action Buttons (Approve/Reject)
```dart
// Approve Button
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF00C896),
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  child: Text('Approve'),
  onPressed: () {},
);

// Reject Button
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: Color(0xFFFF5757),
    side: BorderSide(color: Color(0xFFFF5757)),
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  child: Text('Reject'),
  onPressed: () {},
);
```

---

## 📱 Complete Feature List & Screen Specifications

### Total Screens: 60+ screens across 12 modules

---

## 1️⃣ Authentication Module (6 Screens)

### 1.1 Login Screen
**Route**: `/login`

**Features**:
- Email/username input
- Password input with visibility toggle
- Remember me checkbox
- Two-factor authentication (2FA) toggle
- Forgot password link
- Session timeout warning

**Components**:
- Logo and branding
- Login form
- Primary button (gradient)
- Error messages
- Loading indicator

**Validations**:
- Required fields
- Email format validation
- Password minimum 8 characters
- Rate limiting (max 5 attempts)
- Account lockout after failed attempts

**API**:
- `POST /api/auth/admin/login`
- Returns: `{ token, refreshToken, admin: { id, email, role, permissions } }`

---

### 1.2 Two-Factor Authentication Screen
**Route**: `/login/2fa`

**Features**:
- 6-digit OTP input
- Resend OTP button (60s cooldown)
- Timer countdown display
- Cancel and return to login

**Components**:
- OTP input grid (6 boxes)
- Timer display
- Resend button
- Instructions text

**API**:
- `POST /api/auth/admin/verify-2fa`
- `POST /api/auth/admin/resend-2fa`

---

### 1.3 Forgot Password Screen
**Route**: `/forgot-password`

**Features**:
- Email input
- Send reset link button
- Success message display
- Return to login link

**API**:
- `POST /api/auth/admin/forgot-password`

---

### 1.4 Reset Password Screen
**Route**: `/reset-password/:token`

**Features**:
- New password input
- Confirm password input
- Password strength indicator
- Submit button
- Password requirements list

**Validations**:
- Minimum 8 characters
- Uppercase + lowercase
- Number + special character
- Passwords must match

**API**:
- `POST /api/auth/admin/reset-password`

---

### 1.5 Change Password Screen
**Route**: `/settings/change-password`

**Features**:
- Current password input
- New password input
- Confirm new password input
- Save button

**API**:
- `PUT /api/auth/admin/change-password`

---

### 1.6 Session Expired Screen
**Route**: `/session-expired`

**Features**:
- Session timeout message
- Re-login button
- Auto-redirect to login after 5 seconds

---

## 2️⃣ Dashboard Module (3 Screens)

### 2.1 Main Dashboard (Home)
**Route**: `/dashboard`

**Layout**:
```
┌─────────────────────────────────────────────┐
│  KPI Cards (4 columns)                      │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐      │
│  │Users │ │Agents│ │Trans.│ │Revenue│      │
│  └──────┘ └──────┘ └──────┘ └──────┘      │
├─────────────────────────────────────────────┤
│  Charts Section (2 columns)                 │
│  ┌───────────────────┐ ┌──────────────────┐│
│  │ Transaction Trend │ │ Revenue by Cat.  ││
│  │ (Line Chart)      │ │ (Bar Chart)      ││
│  └───────────────────┘ └──────────────────┘│
├─────────────────────────────────────────────┤
│  Quick Actions & Recent Activity            │
│  ┌──────────────┐ ┌────────────────────────┐│
│  │Quick Actions │ │ Recent Activity Feed   ││
│  │- Pending KYC │ │ - Latest transactions  ││
│  │- Withdrawals │ │ - Recent approvals     ││
│  │- Deposits    │ │ - System alerts        ││
│  └──────────────┘ └────────────────────────┘│
└─────────────────────────────────────────────┘
```

**KPI Cards** (4):
1. **Total Users**
   - Count (Weekly/Monthly/Yearly filter)
   - Percentage change indicator
   - Sparkline trend

2. **Total Agents**
   - Count
   - Active vs Inactive breakdown
   - Percentage change

3. **Total Transactions**
   - Count for selected period
   - Total volume (SLL)
   - Percentage change

4. **Total Revenue**
   - Total revenue (SLL)
   - Revenue by category breakdown
   - Percentage change

**Charts**:
1. **Transaction Trend (Line Chart)**
   - Last 30 days daily transactions
   - Multiple lines: Deposits, Withdrawals, Transfers, Bill Payments
   - Hover tooltip with exact values

2. **Revenue by Category (Bar Chart)**
   - Categories: Deposits, Withdrawals, Transfers, Bill Payments, Investments, E-Voting
   - Horizontal bars with values

3. **User Growth (Area Chart)**
   - New users per day (last 30 days)
   - Cumulative total overlay

4. **Investment Distribution (Pie Chart)**
   - Agriculture, Education, Minerals
   - Percentages and amounts

**Quick Actions** (with badge counts):
- Pending KYC Approvals (badge: count)
- Pending Withdrawals (badge: count)
- Pending Deposits (badge: count)
- Pending Agent Credit Requests (badge: count)
- Matured Investments (badge: count)

**Recent Activity Feed**:
- Last 10 activities across all modules
- Real-time updates
- Click to view details
- Filter by activity type

**API**:
- `GET /api/admin/dashboard/stats`
- `GET /api/admin/dashboard/charts`
- `GET /api/admin/dashboard/recent-activity`
- `GET /api/admin/dashboard/quick-actions`

---

### 2.2 Analytics Dashboard
**Route**: `/dashboard/analytics`

**Features**:
- Date range selector (Daily/Weekly/Monthly/Custom)
- Export report button (CSV/Excel/PDF)
- Multiple chart types
- Filterable metrics

**Charts**:
1. Transaction volume trends
2. User acquisition funnel
3. Agent performance comparison
4. Investment portfolio distribution
5. Bill payment breakdown
6. E-voting participation rates
7. Revenue streams analysis
8. Fraud detection alerts

**API**:
- `GET /api/admin/analytics?startDate&endDate&metrics`

---

### 2.3 System Health Dashboard
**Route**: `/dashboard/system-health`

**Features**:
- Server status indicators
- Database connection status
- API response times
- Error rate monitoring
- Active sessions count
- Background jobs status

---

## 3️⃣ User Management Module (8 Screens)

### 3.1 Users List
**Route**: `/users`

**Features**:
- Search bar (by name, email, phone, ID)
- Filters:
  - Status: All / Pending KYC / Approved / Rejected / Inactive
  - Registration date range
  - Has bank details: Yes/No
  - Has investments: Yes/No
- Sort by: Name, Email, Registration Date, Last Active
- Pagination (25/50/100 per page)
- Bulk actions: Export selected, Deactivate selected
- Column toggles (show/hide columns)

**Table Columns**:
1. Checkbox (for bulk actions)
2. User ID
3. Name
4. Email
5. Phone
6. Status (badge)
7. KYC Status (badge)
8. Registration Date
9. Wallet Balance (SLL)
10. Last Active
11. Actions (View, Edit, Deactivate)

**Status Badges**:
- Pending: Yellow
- Approved: Green
- Rejected: Red
- Inactive: Gray

**API**:
- `GET /api/admin/users?page&limit&search&status&startDate&endDate&sort`
- `POST /api/admin/users/export`
- `PUT /api/admin/users/bulk-action`

---

### 3.2 User Detail Screen
**Route**: `/users/:id`

**Layout**: Tabbed interface

**Tabs**:
1. **Overview**
   - Profile information (name, email, phone, DOB)
   - Profile photo
   - Status badges (KYC, Verification)
   - Registration date
   - Last active
   - Account actions (Deactivate, Delete, Reset Password)

2. **KYC Documents**
   - National ID photo (front/back)
   - Image viewer with zoom
   - Document number
   - Upload date
   - Verification status
   - Approve/Reject buttons
   - Rejection reason input (if rejecting)

3. **Bank Details**
   - Bank name
   - Account number
   - Account holder name
   - Verification status

4. **Wallet**
   - Current balance (SLL)
   - Credit/Debit history
   - Manual credit/debit buttons (for admin adjustments)

5. **Transactions**
   - All user transactions (paginated table)
   - Filter by type
   - Total volume statistics

6. **Investments**
   - Active investments list
   - Matured investments
   - Total invested amount
   - Total returns received

7. **Activity Log**
   - Login history
   - Actions performed
   - Device information
   - IP addresses

**Action Buttons**:
- Edit User
- Approve KYC
- Reject KYC
- Deactivate Account
- Activate Account
- Reset Password
- View Full History

**API**:
- `GET /api/admin/users/:id`
- `GET /api/admin/users/:id/transactions`
- `GET /api/admin/users/:id/investments`
- `GET /api/admin/users/:id/activity-log`
- `PUT /api/admin/users/:id`
- `PUT /api/admin/users/:id/status`

---

### 3.3 Pending KYC Approvals
**Route**: `/users/kyc-pending`

**Features**:
- List of users with pending KYC
- Quick view of documents
- Batch approval option
- Filter by submission date

**Table Columns**:
1. User Name
2. Email
3. Phone
4. Document Type
5. Submission Date
6. Preview (thumbnail)
7. Actions (Review, Approve, Reject)

**Quick Actions**:
- View full document
- Approve (with confirmation)
- Reject (requires reason)

**API**:
- `GET /api/admin/kyc/pending`
- `POST /api/admin/kyc/:id/approve`
- `POST /api/admin/kyc/:id/reject`

---

### 3.4 KYC Review Modal/Screen
**Route**: `/users/:userId/kyc-review`

**Layout**:
```
┌────────────────────────────────────────┐
│  User Information                      │
│  Name: John Doe                        │
│  Email: john@example.com               │
│  Phone: +232 XX XXX XXXX               │
├────────────────────────────────────────┤
│  Document Viewer                       │
│  ┌──────────────────────────────────┐ │
│  │                                  │ │
│  │    [National ID Image]           │ │
│  │    Zoom, Rotate, Download        │ │
│  │                                  │ │
│  └──────────────────────────────────┘ │
│                                        │
│  Document Number: XXXXXXXX             │
├────────────────────────────────────────┤
│  Bank Details (if provided)            │
│  Bank: [Bank Name]                     │
│  Account: XXXXXXXXXXXX                 │
│  Account Holder: [Name]                │
├────────────────────────────────────────┤
│  Actions                               │
│  [Approve]  [Reject]  [Request More]   │
│                                        │
│  Rejection Reason:                     │
│  ┌──────────────────────────────────┐ │
│  │ [Textarea for rejection reason]  │ │
│  └──────────────────────────────────┘ │
└────────────────────────────────────────┘
```

**Features**:
- High-quality image viewer
- Zoom in/out functionality
- Rotate image
- Download document
- Approve button (green)
- Reject button (red) - opens rejection reason form
- Request more information button

**Rejection Reasons** (predefined + custom):
- Document unclear/blurry
- Document expired
- Name mismatch
- Information incomplete
- Suspected fraud
- Other (requires description)

**API**:
- `POST /api/admin/kyc/:id/approve`
- `POST /api/admin/kyc/:id/reject` (body: { reason })
- `POST /api/admin/kyc/:id/request-more-info`

---

### 3.5 Edit User Screen
**Route**: `/users/:id/edit`

**Editable Fields**:
- Full Name
- Email
- Phone Number
- Date of Birth
- Address
- Status (Active/Inactive)

**Non-editable** (display only):
- User ID
- Registration Date
- KYC Status

**Buttons**:
- Save Changes
- Cancel

**API**:
- `PUT /api/admin/users/:id`

---

### 3.6 Create User Screen
**Route**: `/users/create`

**Form Fields**:
- Full Name *
- Email *
- Phone Number *
- Password *
- Confirm Password *
- Date of Birth
- Address
- Auto-approve KYC (checkbox)

**API**:
- `POST /api/admin/users`

---

### 3.7 User Transaction History
**Route**: `/users/:id/transactions`

**Features**:
- Comprehensive transaction list
- Export to CSV/Excel
- Date range filter
- Transaction type filter
- Amount range filter

---

### 3.8 User Activity Log
**Route**: `/users/:id/activity-log`

**Features**:
- All user actions chronologically
- Login/logout events
- Transaction events
- KYC submissions
- Password changes
- Device and IP information

---

## 4️⃣ Agent Management Module (10 Screens)

### 4.1 Agents List
**Route**: `/agents`

**Features**:
- Search (name, email, phone, location)
- Filters:
  - Status: All / Pending / Approved / Rejected / Active / Inactive
  - Verification status
  - Location (province/district)
  - Commission tier
- Sort by: Name, Location, Commission Earned, Transactions Count
- Map view toggle (switch to map showing agent locations)

**Table Columns**:
1. Checkbox
2. Agent ID
3. Name
4. Email
5. Phone
6. Location
7. Status (badge)
8. Verification Status (badge)
9. Availability (Active/Inactive toggle)
10. Commission Rate (%)
11. Total Commission Earned (SLL)
12. Total Transactions
13. Actions (View, Edit, Deactivate)

**API**:
- `GET /api/admin/agents?page&limit&search&status&location&sort`

---

### 4.2 Agent Detail Screen
**Route**: `/agents/:id`

**Tabs**:
1. **Overview**
   - Profile information
   - Photo
   - Status badges
   - Location (with map)
   - Bank details
   - Commission rate
   - Performance summary

2. **KYC Documents**
   - National ID
   - Business license (if applicable)
   - Proof of address
   - Bank account verification

3. **Bank Details** (MANDATORY for agents)
   - Bank name
   - Account number
   - Account holder name
   - Branch
   - Verification status

4. **Performance**
   - Total transactions processed
   - Total commission earned
   - Average transaction value
   - User satisfaction rating (if available)
   - Performance charts (last 30 days)

5. **Transactions**
   - All transactions facilitated by agent
   - Filter by type (Deposit, Withdrawal, Transfer)
   - Date range filter

6. **Wallet & Credit Requests**
   - Current wallet balance
   - Credit request history
   - Pending credit requests
   - Manual credit/debit buttons

7. **Commission History**
   - All commissions earned
   - Payment history
   - Pending payouts

8. **Activity Log**
   - Login/logout events
   - Status changes (Active/Inactive)
   - Transaction events
   - Location changes

**Action Buttons**:
- Edit Agent
- Approve Verification
- Reject Verification
- Adjust Commission Rate
- Deactivate Account
- View on Map
- Generate Performance Report

**API**:
- `GET /api/admin/agents/:id`
- `GET /api/admin/agents/:id/performance`
- `GET /api/admin/agents/:id/transactions`
- `GET /api/admin/agents/:id/commissions`
- `PUT /api/admin/agents/:id`
- `PUT /api/admin/agents/:id/commission-rate`

---

### 4.3 Pending Agent Verifications
**Route**: `/agents/pending-verifications`

**Features**:
- List of agents awaiting verification
- Quick document preview
- Batch approval option

**Table Columns**:
1. Agent Name
2. Email
3. Phone
4. Location
5. Bank Details Status
6. Documents Submitted
7. Submission Date
8. Actions (Review, Approve, Reject)

**API**:
- `GET /api/admin/agents/pending-verification`

---

### 4.4 Agent Verification Review Screen
**Route**: `/agents/:id/verification-review`

**Similar to User KYC Review** but includes:
- National ID verification
- Bank account verification (MANDATORY)
- Location verification
- Business license (if applicable)
- Proof of address

**Additional Checks**:
- Verify bank account details
- Check location accessibility
- Review business credentials

**Actions**:
- Approve (set commission rate on approval)
- Reject (with reason)
- Request more information

**API**:
- `POST /api/admin/agents/:id/approve` (body: { commissionRate })
- `POST /api/admin/agents/:id/reject` (body: { reason })

---

### 4.5 Pending Credit Requests
**Route**: `/agents/credit-requests`

**Features**:
- List of agent wallet credit requests
- Receipt image preview
- Verification tools

**Table Columns**:
1. Agent Name
2. Request Amount (SLL)
3. Receipt Upload (thumbnail)
4. Bank Name
5. Deposit Date & Time (from receipt)
6. Request Date
7. Status
8. Actions (Review, Approve, Reject)

**Review Modal**:
```
┌────────────────────────────────────────┐
│  Agent: [Name]                         │
│  Amount: [Amount] SLL                  │
├────────────────────────────────────────┤
│  Receipt Image                         │
│  ┌──────────────────────────────────┐ │
│  │                                  │ │
│  │    [Bank Receipt Image]          │ │
│  │    Zoom, Download                │ │
│  │                                  │ │
│  └──────────────────────────────────┘ │
│                                        │
│  Bank: [Bank Name]                     │
│  Date: [Deposit Date]                  │
│  Time: [Deposit Time]                  │
│  Reference: [Reference Number]         │
│                                        │
│  Notes: [Optional notes from agent]    │
├────────────────────────────────────────┤
│  Actions                               │
│  [Approve]  [Reject]                   │
│                                        │
│  Rejection Reason:                     │
│  ┌──────────────────────────────────┐ │
│  │ [Textarea]                       │ │
│  └──────────────────────────────────┘ │
└────────────────────────────────────────┘
```

**API**:
- `GET /api/admin/agents/credit-requests`
- `POST /api/admin/agents/credit-requests/:id/approve`
- `POST /api/admin/agents/credit-requests/:id/reject`

---

### 4.6 Commission Configuration Screen
**Route**: `/agents/commission-settings`

**Features**:
- Default commission rate setting
- Tiered commission structure
- Individual agent rate overrides
- Volume-based bonuses

**Configuration Options**:

1. **Default Commission Rate**
   - Percentage input (e.g., 0.5%)
   - Applied to all new agents

2. **Tiered Commission Structure**
   ```
   Tier 1: 0-100 transactions/month    → 0.5%
   Tier 2: 101-500 transactions/month  → 0.6%
   Tier 3: 501-1000 transactions/month → 0.7%
   Tier 4: 1000+ transactions/month    → 0.8%
   ```

3. **Volume Bonuses**
   - Bonus for reaching transaction milestones
   - Monthly/quarterly bonus structure

4. **Individual Overrides**
   - Set custom rate for specific agents
   - Reason for override (required)

**API**:
- `GET /api/admin/agents/commission-config`
- `PUT /api/admin/agents/commission-config`
- `PUT /api/admin/agents/:id/commission-rate`

---

### 4.7 Agent Commission Report
**Route**: `/agents/:id/commission-report`

**Features**:
- Date range selector
- Export to PDF/Excel
- Commission breakdown by transaction type
- Payment history

---

### 4.8 Edit Agent Screen
**Route**: `/agents/:id/edit`

**Editable Fields**:
- Name
- Email
- Phone
- Location
- Commission Rate
- Status

---

### 4.9 Agent Map View
**Route**: `/agents/map`

**Features**:
- Interactive map showing all agent locations
- Markers color-coded by status (Active/Inactive)
- Click marker to view agent details
- Search by location
- Filter by status

---

### 4.10 Agent Performance Comparison
**Route**: `/agents/performance-comparison`

**Features**:
- Compare multiple agents side-by-side
- Metrics: Transactions, Commission, Volume, Rating
- Date range selector
- Export comparison report

---

## 5️⃣ Transaction Management Module (12 Screens)

### 5.1 All Transactions List
**Route**: `/transactions`

**Features**:
- Comprehensive transaction list
- Real-time updates
- Advanced filters
- Export functionality

**Filters**:
- Transaction Type: All / Deposit / Withdrawal / Transfer / Bill Payment / Investment / E-Voting
- Status: All / Pending / Processing / Completed / Failed / Cancelled
- Date range
- Amount range (min-max in SLL)
- User/Agent filter
- Payment method: Bank / Mobile Money / Agent / Wallet

**Table Columns**:
1. Transaction ID
2. Type (icon + label)
3. User/Agent
4. Amount (SLL)
5. Fee (SLL)
6. Total (SLL)
7. Status (badge)
8. Payment Method
9. Date & Time
10. Actions (View Details, Process, Cancel)

**Summary Cards** (above table):
- Total Transactions Today
- Total Volume (SLL)
- Total Fees Collected (SLL)
- Failed Transactions Count

**API**:
- `GET /api/admin/transactions?page&limit&type&status&startDate&endDate&minAmount&maxAmount&userId&agentId`
- `GET /api/admin/transactions/summary`

---

### 5.2 Transaction Detail Screen
**Route**: `/transactions/:id`

**Information Displayed**:
- Transaction ID
- Type
- Status with timeline
- User details (name, email, phone)
- Agent details (if agent-facilitated)
- Amount breakdown:
  - Base amount
  - Fee (%)
  - Total amount
- Payment method details
- Bank receipt (if applicable)
- Timestamps (Created, Processing, Completed)
- Related documents/receipts
- Admin notes (internal)

**Status Timeline**:
```
Created → Pending → Processing → Completed
         ↓
      Rejected/Failed/Cancelled
```

**Action Buttons** (status-dependent):
- Process Transaction
- Approve
- Reject
- Cancel
- Refund
- Add Note
- Download Receipt
- Contact User

**Audit Trail**:
- All status changes
- Admin actions
- System events
- Timestamps

**API**:
- `GET /api/admin/transactions/:id`
- `PUT /api/admin/transactions/:id/status`
- `POST /api/admin/transactions/:id/notes`

---

### 5.3 Pending Deposits
**Route**: `/transactions/deposits-pending`

**Features**:
- List of deposits awaiting approval
- Receipt verification
- Bank transfer verification

**Table Columns**:
1. User Name
2. Amount (SLL)
3. Deposit Method (Bank Transfer / Mobile Money / Agent)
4. Receipt Upload (thumbnail)
5. Bank Name
6. Deposit Date & Time
7. Request Date
8. Actions (Review, Approve, Reject)

**Review Modal** (similar to agent credit request):
- User information
- Receipt image viewer
- Amount verification
- Bank details verification
- Approve/Reject actions

**API**:
- `GET /api/admin/transactions/deposits/pending`
- `POST /api/admin/transactions/deposits/:id/approve`
- `POST /api/admin/transactions/deposits/:id/reject`

---

### 5.4 Pending Withdrawals
**Route**: `/transactions/withdrawals-pending`

**Features**:
- List of withdrawal requests awaiting approval
- Verification of user balance
- Tenure validation (for investment withdrawals)

**Table Columns**:
1. User Name
2. Amount (SLL)
3. Withdrawal Type (Wallet / Investment)
4. Destination (Bank / Mobile Money)
5. Bank/Mobile Details
6. Investment Tenure Status (if applicable)
7. Expected Amount (principal + interest)
8. Request Date
9. Actions (Review, Approve, Reject)

**Review Screen**:
```
┌────────────────────────────────────────┐
│  User: [Name]                          │
│  Withdrawal Amount: [Amount] SLL       │
│  Current Balance: [Balance] SLL        │
├────────────────────────────────────────┤
│  Withdrawal Details                    │
│  Type: [Wallet / Investment]           │
│  Destination: [Bank / Mobile Money]    │
│  Account: [Account Number]             │
│                                        │
│  If Investment Withdrawal:             │
│  Investment ID: [ID]                   │
│  Category: [Agriculture/Education/etc] │
│  Amount Invested: [Amount] SLL         │
│  Tenure: [6/12/24 months]              │
│  Start Date: [Date]                    │
│  Maturity Date: [Date]                 │
│  Status: [Ongoing / Matured]           │
│                                        │
│  Expected Return:                      │
│  - Principal: [Amount] SLL             │
│  - Interest: [Amount] SLL (X%)         │
│  - Total: [Total] SLL                  │
│                                        │
│  ⚠️ Tenure incomplete warning (if applicable)│
│  "User will only receive principal"    │
├────────────────────────────────────────┤
│  Actions                               │
│  [Approve Full Amount]                 │
│  [Approve Partial (Principal Only)]    │
│  [Reject]                              │
│                                        │
│  Rejection Reason:                     │
│  ┌──────────────────────────────────┐ │
│  │ [Textarea]                       │ │
│  └──────────────────────────────────┘ │
└────────────────────────────────────────┘
```

**Business Logic**:
- If tenure complete: Approve with interest
- If tenure incomplete: Offer partial approval (principal only) or full rejection
- Check sufficient balance
- Verify bank/mobile details
- Calculate payout amount

**API**:
- `GET /api/admin/transactions/withdrawals/pending`
- `POST /api/admin/transactions/withdrawals/:id/approve` (body: { amount, type })
- `POST /api/admin/transactions/withdrawals/:id/reject` (body: { reason })

---

### 5.5 Deposit History
**Route**: `/transactions/deposits`

**Features**:
- All completed/rejected deposits
- Filter by status, date, method
- Export report

---

### 5.6 Withdrawal History
**Route**: `/transactions/withdrawals`

**Features**:
- All completed/rejected withdrawals
- Filter by status, date, type
- Export report

---

### 5.7 Transfer History
**Route**: `/transactions/transfers`

**Features**:
- User-to-user transfers
- Agent-facilitated transfers
- Filter by date, amount
- Export report

---

### 5.8 Failed Transactions
**Route**: `/transactions/failed`

**Features**:
- List of failed transactions
- Failure reason
- Retry option
- Refund option

---

### 5.9 Refund Management
**Route**: `/transactions/refunds`

**Features**:
- Process refunds for failed/cancelled transactions
- Refund history
- Partial/full refund options

---

### 5.10 Transaction Analytics
**Route**: `/transactions/analytics`

**Features**:
- Transaction volume trends
- Peak transaction times
- Average transaction value
- Success/failure rates
- Payment method breakdown

---

### 5.11 Payment Method Configuration
**Route**: `/transactions/payment-methods`

**Features**:
- Enable/disable payment methods
- Configure fees per method
- Bank list management
- Mobile Money provider management

---

### 5.12 Transaction Limits Configuration
**Route**: `/transactions/limits`

**Configuration Options**:
```
Deposits:
- Minimum: [Input] SLL (default: 1,000)
- Maximum: [Input] SLL (default: 10,000,000)
- Daily Limit: [Input] SLL

Withdrawals:
- Minimum: [Input] SLL (default: 1,000)
- Maximum: [Input] SLL (default: 5,000,000)
- Daily Limit: [Input] SLL

Transfers:
- Minimum: [Input] SLL (default: 100)
- Maximum: [Input] SLL (default: 2,000,000)
- Daily Limit: [Input] SLL

Bill Payments:
- Minimum: [Input] SLL
- Maximum: [Input] SLL
- Daily Limit: [Input] SLL
```

**API**:
- `GET /api/admin/config/transaction-limits`
- `PUT /api/admin/config/transaction-limits`

---

## 6️⃣ Investment Management Module (10 Screens)

### 6.1 All Investments List
**Route**: `/investments`

**Features**:
- Comprehensive investment list
- Multi-level filtering
- Status tracking

**Filters**:
- Category: All / Agriculture / Education / Minerals
- Status: All / Ongoing / Matured / Paid / Withdrawn
- Tenure: All / 6 months / 12 months / 24 months
- Date range (investment start date)
- User filter
- Amount range

**Table Columns**:
1. Investment ID
2. User Name
3. Category
4. Sub-category
5. Unit Type (Lot/Plot/Farm)
6. Amount Invested (SLL)
7. Tenure (months)
8. Expected Return (%)
9. Expected Return Amount (SLL)
10. Start Date
11. Maturity Date
12. Status (badge)
13. Actions (View, Process Return, Edit)

**Summary Cards**:
- Total Investments: [Count]
- Total Invested: [Amount] SLL
- Total Returns Paid: [Amount] SLL
- Matured (Unpaid): [Count]

**API**:
- `GET /api/admin/investments?page&limit&category&status&tenure&startDate&endDate&userId`
- `GET /api/admin/investments/summary`

---

### 6.2 Investment Detail Screen
**Route**: `/investments/:id`

**Information Displayed**:
- Investment ID
- User details
- Category and sub-category
- Unit details (type, quantity, price per unit)
- Amount invested
- Tenure (months)
- Start date
- Maturity date
- Expected return (% and amount)
- Status
- Agreement document (view/download)
- Insurance document (view/download)
- Payment history
- Return payment status

**Status Timeline**:
```
Created → Ongoing → Matured → Return Processed → Paid
```

**Action Buttons**:
- Process Return (if matured)
- Edit Investment
- Download Agreement
- View User Profile
- Add Note

**API**:
- `GET /api/admin/investments/:id`

---

### 6.3 Matured Investments (Pending Return Entry)
**Route**: `/investments/matured-pending`

**Features**:
- List of matured investments awaiting return entry
- Quick entry modal
- Bulk processing option

**Table Columns**:
1. Investment ID
2. User Name
3. Category
4. Amount Invested (SLL)
5. Expected Return (%)
6. Expected Return Amount (SLL)
7. Maturity Date
8. Days Since Matured
9. Actions (Process Return)

**Process Return Modal**:
```
┌────────────────────────────────────────┐
│  Investment Return Entry               │
├────────────────────────────────────────┤
│  Investment ID: [ID]                   │
│  User: [Name]                          │
│  Category: [Category]                  │
│  Amount Invested: [Amount] SLL         │
│                                        │
│  Calculated Return:                    │
│  - Expected %: [X%]                    │
│  - Expected Amount: [Amount] SLL       │
│                                        │
│  Actual Return Entry:                  │
│  Actual Return %: [Input] %            │
│  Actual Return Amount: [Auto-calc] SLL │
│                                        │
│  Total Payout:                         │
│  - Principal: [Amount] SLL             │
│  - Return: [Amount] SLL                │
│  - Total: [Total] SLL                  │
│                                        │
│  Notes (optional):                     │
│  ┌──────────────────────────────────┐ │
│  │ [Textarea]                       │ │
│  └──────────────────────────────────┘ │
│                                        │
│  [Credit to Wallet]  [Cancel]          │
└────────────────────────────────────────┘
```

**Process**:
1. Admin enters actual return percentage
2. System auto-calculates actual return amount
3. Total payout = Principal + Actual Return
4. On submit:
   - Create investment_return record
   - Credit user wallet
   - Update investment status to PAID
   - Create transaction record
   - Send notification to user

**API**:
- `GET /api/admin/investments/matured-pending`
- `POST /api/admin/investments/:id/process-return` (body: { actualReturnPercentage, notes })

---

### 6.4 Investment Categories Management
**Route**: `/investments/categories`

**Features**:
- List of categories (Agriculture, Education, Minerals)
- Sub-categories management
- Add/Edit/Delete categories

**Category List**:
```
Agriculture
  ├── Rice Farming
  ├── Cassava Production
  └── Vegetable Gardens

Education
  ├── School Infrastructure
  ├── Scholarship Fund
  └── Educational Materials

Minerals
  ├── Diamond Mining
  ├── Gold Extraction
  └── Rutile Mining
```

**Actions**:
- Add new category
- Edit category name
- Add sub-category
- Edit sub-category
- Delete category/sub-category
- Upload category icon/image

**API**:
- `GET /api/admin/investments/categories`
- `POST /api/admin/investments/categories`
- `PUT /api/admin/investments/categories/:id`
- `DELETE /api/admin/investments/categories/:id`
- `POST /api/admin/investments/categories/:id/subcategories`

---

### 6.5 Investment Tenures Configuration
**Route**: `/investments/tenures`

**Features**:
- Define available tenures
- Set return percentages per tenure and category

**Configuration Table**:
```
┌──────────────────────────────────────────────────────┐
│ Tenure (months) │ Agriculture │ Education │ Minerals │
├──────────────────────────────────────────────────────┤
│ 6 months        │ [5%]        │ [6%]      │ [7%]     │
│ 12 months       │ [10%]       │ [12%]     │ [14%]    │
│ 24 months       │ [22%]       │ [25%]     │ [30%]    │
│ 36 months       │ [35%]       │ [40%]     │ [45%]    │
└──────────────────────────────────────────────────────┘

[Add New Tenure]
```

**Add/Edit Tenure Form**:
- Tenure duration (months)
- Return percentage per category
- Description
- Terms and conditions
- Active/Inactive toggle

**API**:
- `GET /api/admin/investments/tenures`
- `POST /api/admin/investments/tenures`
- `PUT /api/admin/investments/tenures/:id`
- `DELETE /api/admin/investments/tenures/:id`

---

### 6.6 Investment Units Pricing
**Route**: `/investments/units-pricing`

**Features**:
- Set pricing for investment units (Lot, Plot, Farm)
- Pricing per category

**Pricing Table**:
```
┌───────────────────────────────────────────────────────────┐
│ Category     │ Lot (SLL)  │ Plot (SLL) │ Farm (SLL)      │
├───────────────────────────────────────────────────────────┤
│ Agriculture  │ [100,000]  │ [500,000]  │ [2,000,000]     │
│ Education    │ [50,000]   │ [250,000]  │ [1,000,000]     │
│ Minerals     │ [200,000]  │ [1,000,000]│ [5,000,000]     │
└───────────────────────────────────────────────────────────┘
```

**Edit Pricing Modal**:
- Category selector
- Unit type (Lot/Plot/Farm)
- Price (SLL)
- Minimum investment
- Maximum investment
- Description

**API**:
- `GET /api/admin/investments/units-pricing`
- `PUT /api/admin/investments/units-pricing`

---

### 6.7 Agreement Templates Management
**Route**: `/investments/agreement-templates`

**Features**:
- Upload agreement PDFs per category
- Template variables (user name, amount, tenure, etc.)
- Preview agreements
- Version control

**Template List**:
```
┌────────────────────────────────────────────────────┐
│ Category     │ Template File         │ Version  │  │
├────────────────────────────────────────────────────┤
│ Agriculture  │ agriculture_v2.pdf    │ v2.0     │  │
│ Education    │ education_v1.pdf      │ v1.0     │  │
│ Minerals     │ minerals_v1.pdf       │ v1.0     │  │
└────────────────────────────────────────────────────┘
```

**Actions**:
- Upload new template
- Preview template
- Download template
- Set as active version
- Archive old version

**API**:
- `GET /api/admin/investments/agreement-templates`
- `POST /api/admin/investments/agreement-templates/upload`
- `GET /api/admin/investments/agreement-templates/:id/preview`

---

### 6.8 Insurance Management
**Route**: `/investments/insurance`

**Features**:
- Upload insurance policy documents
- Configure insurance costs
- Insurance providers management

**Configuration**:
- Insurance cost percentage (e.g., 1% of investment)
- Insurance provider details
- Policy documents upload
- Terms and conditions

**API**:
- `GET /api/admin/investments/insurance-config`
- `PUT /api/admin/investments/insurance-config`
- `POST /api/admin/investments/insurance/upload-policy`

---

### 6.9 Investment Tenure Change Requests
**Route**: `/investments/tenure-change-requests`

**Features**:
- Users can request to change investment tenure
- Admin approval required
- Recalculate expected returns

**Table Columns**:
1. Investment ID
2. User Name
3. Current Tenure
4. Requested Tenure
5. Current Expected Return
6. New Expected Return
7. Request Date
8. Reason
9. Actions (Approve, Reject)

**Review Modal**:
```
┌────────────────────────────────────────┐
│  Investment Tenure Change Request      │
├────────────────────────────────────────┤
│  Investment ID: [ID]                   │
│  User: [Name]                          │
│  Category: [Category]                  │
│  Amount: [Amount] SLL                  │
│                                        │
│  Current Tenure: [12 months]           │
│  Current Expected Return: [10%] [Amount]│
│                                        │
│  Requested Tenure: [24 months]         │
│  New Expected Return: [22%] [Amount]   │
│                                        │
│  User Reason: [Reason text]            │
│                                        │
│  [Approve]  [Reject]                   │
└────────────────────────────────────────┘
```

**API**:
- `GET /api/admin/investments/tenure-change-requests`
- `POST /api/admin/investments/tenure-change-requests/:id/approve`
- `POST /api/admin/investments/tenure-change-requests/:id/reject`

---

### 6.10 Investment Reports
**Route**: `/investments/reports`

**Reports Available**:
1. Investment Portfolio Summary
2. Category-wise Performance
3. Maturity Calendar (upcoming maturities)
4. Returns Paid Report
5. User Investment Report
6. ROI Analysis

**Export Formats**: PDF, Excel, CSV

---

## 7️⃣ Bill Payment Management Module (5 Screens)

### 7.1 Bill Payments List
**Route**: `/bill-payments`

**Features**:
- All bill payment transactions
- Filter by provider and service type

**Filters**:
- Service Type: All / Water / Electricity / DSTV / Internet / Mobile Recharge
- Provider
- Status: All / Pending / Completed / Failed
- Date range

**Table Columns**:
1. Transaction ID
2. User Name
3. Service Type
4. Provider
5. Account Number
6. Amount (SLL)
7. Fee (SLL)
8. Status (badge)
9. Date & Time
10. Actions (View, Retry if failed)

**API**:
- `GET /api/admin/bill-payments?page&limit&serviceType&provider&status&startDate&endDate`

---

### 7.2 Bill Payment Providers Management
**Route**: `/bill-payments/providers`

**Features**:
- Add/edit/delete service providers
- Configure provider details

**Provider Categories**:
1. **Water Providers**
   - Guma Valley Water Company
   - Others

2. **Electricity Providers**
   - EDSA (Electricity Distribution and Supply Authority)
   - Others

3. **DSTV/Cable Providers**
   - DSTV
   - Others

4. **Internet Providers**
   - Africell
   - Orange
   - Qcell
   - Others

5. **Mobile Recharge Providers**
   - Africell
   - Orange
   - Qcell

**Provider Form**:
- Provider name
- Service type
- Logo upload
- API endpoint (if integrated)
- Status (Active/Inactive)
- Fee percentage

**API**:
- `GET /api/admin/bill-providers`
- `POST /api/admin/bill-providers`
- `PUT /api/admin/bill-providers/:id`
- `DELETE /api/admin/bill-providers/:id`

---

### 7.3 Bill Payment Analytics
**Route**: `/bill-payments/analytics`

**Features**:
- Payment volume by service type
- Most popular providers
- Revenue from bill payments
- Peak payment times
- Success/failure rates

---

### 7.4 Failed Bill Payments
**Route**: `/bill-payments/failed`

**Features**:
- List of failed bill payments
- Failure reasons
- Retry option
- Refund option

---

### 7.5 Bill Payment Configuration
**Route**: `/bill-payments/config`

**Configuration**:
- Fee percentage (default: 1.5%)
- Minimum/maximum amounts per service
- Enable/disable service types
- Retry policy

---

## 8️⃣ E-Voting Management Module (6 Screens)

### 8.1 Polls List
**Route**: `/e-voting`

**Features**:
- List of all polls (Active, Upcoming, Ended)
- Quick stats per poll

**Filters**:
- Status: All / Draft / Active / Paused / Ended
- Date range

**Table Columns**:
1. Poll ID
2. Title
3. Voting Charge (TCC Coins)
4. Status (badge)
5. Start Date
6. End Date
7. Total Votes
8. Revenue (SLL)
9. Actions (View, Edit, Pause/Resume, End, Delete)

**Status Badges**:
- Draft: Gray
- Active: Green
- Paused: Yellow
- Ended: Blue

**API**:
- `GET /api/admin/polls?page&limit&status&startDate&endDate`

---

### 8.2 Create Poll Screen
**Route**: `/e-voting/create`

**Form Fields**:
```
┌────────────────────────────────────────┐
│  Create New Poll                       │
├────────────────────────────────────────┤
│  Poll Title: [Input] *                 │
│                                        │
│  Question: [Textarea] *                │
│                                        │
│  Options (2-4 required):               │
│  Option 1: [Input] *                   │
│  Option 2: [Input] *                   │
│  Option 3: [Input]                     │
│  Option 4: [Input]                     │
│  [+ Add Option] (max 4)                │
│                                        │
│  Voting Charge: [Input] TCC Coins *    │
│  (Users pay this to vote)              │
│                                        │
│  Start Date & Time: [DateTime Picker]  │
│  End Date & Time: [DateTime Picker]    │
│                                        │
│  Description (optional):               │
│  [Rich Text Editor]                    │
│                                        │
│  Status:                               │
│  ○ Save as Draft                       │
│  ○ Publish Immediately                 │
│  ○ Schedule for Start Date             │
│                                        │
│  [Create Poll]  [Cancel]               │
└────────────────────────────────────────┘
```

**Validations**:
- Title required (max 200 characters)
- Question required (max 500 characters)
- Minimum 2 options, maximum 4
- Each option required (max 100 characters)
- Voting charge > 0
- End date must be after start date

**API**:
- `POST /api/admin/polls`

---

### 8.3 Edit Poll Screen
**Route**: `/e-voting/:id/edit`

**Features**:
- Same form as Create Poll
- Cannot edit if votes have been cast
- Warning message if attempting to edit active poll

**Business Logic**:
- If poll has 0 votes: Allow full edit
- If poll has votes: Only allow ending poll early or pausing
- Cannot change options after votes are cast

**API**:
- `GET /api/admin/polls/:id`
- `PUT /api/admin/polls/:id`

---

### 8.4 Poll Detail & Results Screen
**Route**: `/e-voting/:id`

**Layout**:
```
┌────────────────────────────────────────┐
│  Poll: [Title]                         │
│  Status: [Active/Ended] [Edit] [End]   │
├────────────────────────────────────────┤
│  Question: [Question text]             │
│                                        │
│  Voting Charge: [X] TCC Coins          │
│  Start: [Date & Time]                  │
│  End: [Date & Time]                    │
├────────────────────────────────────────┤
│  Results                               │
│                                        │
│  Total Votes: [Count]                  │
│  Total Revenue: [Amount] SLL           │
│                                        │
│  Option Breakdown:                     │
│  ┌──────────────────────────────────┐ │
│  │ Option 1: [Text]                 │ │
│  │ ████████████████░░░░░░ 65%       │ │
│  │ [Count] votes                    │ │
│  └──────────────────────────────────┘ │
│  ┌──────────────────────────────────┐ │
│  │ Option 2: [Text]                 │ │
│  │ ██████░░░░░░░░░░░░░░ 25%         │ │
│  │ [Count] votes                    │ │
│  └──────────────────────────────────┘ │
│  ┌──────────────────────────────────┐ │
│  │ Option 3: [Text]                 │ │
│  │ ███░░░░░░░░░░░░░░░░░ 10%         │ │
│  │ [Count] votes                    │ │
│  └──────────────────────────────────┘ │
│                                        │
│  [Pie Chart Visualization]             │
│                                        │
│  [Download Results CSV]                │
│  [Download Voter List]                 │
│  [View All Votes]                      │
├────────────────────────────────────────┤
│  Actions                               │
│  [Pause Poll]  [End Poll]  [Delete]    │
└────────────────────────────────────────┘
```

**Action Buttons**:
- **Pause Poll**: Hide from users temporarily
- **Resume Poll**: Make visible again
- **End Poll**: Close voting permanently
- **Delete Poll**: Remove (only if 0 votes)
- **Download Results**: CSV export
- **Download Voter List**: User details + vote choice (non-anonymous)

**API**:
- `GET /api/admin/polls/:id`
- `GET /api/admin/polls/:id/results`
- `PUT /api/admin/polls/:id/status` (pause/resume/end)
- `DELETE /api/admin/polls/:id`
- `GET /api/admin/polls/:id/votes/export`

---

### 8.5 Poll Votes Detail Screen
**Route**: `/e-voting/:id/votes`

**Features**:
- Complete list of votes for a poll
- **Non-anonymous**: Shows user who voted for what

**Table Columns**:
1. Vote ID
2. User Name
3. User Email
4. User Phone
5. Option Voted
6. Charge Paid (TCC Coins)
7. Vote Date & Time
8. IP Address (security)

**Filters**:
- Filter by option
- Date range
- Search by user

**Export**: CSV with all voter details

**Note**: This is non-anonymous by design for transparency and fraud prevention.

**API**:
- `GET /api/admin/polls/:id/votes?page&limit&option&startDate&endDate`

---

### 8.6 E-Voting Analytics
**Route**: `/e-voting/analytics`

**Features**:
- Total polls created
- Total votes cast
- Total revenue from e-voting
- Most participated polls
- Vote timing analysis (peak voting times)
- User participation rates

---

## 9️⃣ Reports & Analytics Module (6 Screens)

### 9.1 Reports Dashboard
**Route**: `/reports`

**Features**:
- Pre-built report templates
- Custom report builder
- Scheduled reports
- Report history

**Available Reports**:
1. User Registration Report
2. Transaction Summary Report
3. Agent Performance Report
4. Investment Portfolio Report
5. Revenue Report
6. Bill Payment Report
7. E-Voting Report
8. Fraud Detection Report
9. Custom Report

**Each Report Card**:
- Report name
- Description
- Last generated date
- Generate button
- Schedule button

---

### 9.2 User Report
**Route**: `/reports/users`

**Parameters**:
- Date range
- KYC status filter
- Has investments filter
- Export format (PDF/Excel/CSV)

**Report Includes**:
- Total users registered
- KYC approval statistics
- User growth chart
- User demographics
- Active vs inactive users
- Users with investments count

---

### 9.3 Transaction Report
**Route**: `/reports/transactions`

**Parameters**:
- Date range
- Transaction type filter
- Status filter
- Export format

**Report Includes**:
- Total transactions count
- Total volume (SLL)
- Total fees collected
- Breakdown by type
- Breakdown by payment method
- Success/failure rates
- Charts and trends

---

### 9.4 Revenue Report
**Route**: `/reports/revenue`

**Parameters**:
- Date range
- Revenue source filter
- Export format

**Report Includes**:
- Total revenue (SLL)
- Revenue by source:
  - Deposit fees
  - Withdrawal fees
  - Transfer fees
  - Bill payment fees
  - Investment management fees
  - E-voting charges
- Revenue trends
- Comparison with previous period
- Projections

---

### 9.5 Agent Performance Report
**Route**: `/reports/agents`

**Parameters**:
- Date range
- Agent filter (individual or all)
- Export format

**Report Includes**:
- Total transactions processed
- Total volume handled
- Total commissions paid
- Agent rankings
- Performance trends
- Comparison between agents

---

### 9.6 Custom Report Builder
**Route**: `/reports/custom`

**Features**:
- Drag-and-drop report fields
- Multiple data sources
- Custom filters
- Save report template
- Schedule automated generation

---

## 🔟 Content Management Module (5 Screens)

### 10.1 Terms & Conditions Management
**Route**: `/cms/terms`

**Features**:
- Rich text editor
- Version history
- Preview before publish
- Effective date setting

**Editor Features**:
- Bold, italic, underline
- Headings (H1-H6)
- Bullet lists, numbered lists
- Links
- Tables
- Save as draft
- Publish
- Version control

**API**:
- `GET /api/admin/cms/terms`
- `PUT /api/admin/cms/terms`
- `GET /api/admin/cms/terms/versions`

---

### 10.2 Privacy Policy Management
**Route**: `/cms/privacy`

**Features**: Same as Terms & Conditions

---

### 10.3 Agreement Templates
**Route**: `/cms/agreements`

(Covered in Investment Module - links here for convenience)

---

### 10.4 Notification Management
**Route**: `/cms/notifications`

**Features**:
- Create broadcast notifications
- Send to specific user groups
- Schedule notifications
- Notification templates

**Create Notification Form**:
```
┌────────────────────────────────────────┐
│  Send Notification                     │
├────────────────────────────────────────┤
│  Title: [Input] *                      │
│                                        │
│  Message: [Textarea] *                 │
│                                        │
│  Target Audience:                      │
│  ○ All Users                           │
│  ○ All Agents                          │
│  ○ Specific User Group                 │
│  ○ Individual Users (select)           │
│                                        │
│  Priority:                             │
│  ○ Low  ○ Medium  ○ High              │
│                                        │
│  Send:                                 │
│  ○ Immediately                         │
│  ○ Schedule for: [DateTime Picker]     │
│                                        │
│  [Send Notification]  [Cancel]         │
└────────────────────────────────────────┘
```

**API**:
- `POST /api/admin/notifications/broadcast`
- `GET /api/admin/notifications/history`

---

### 10.5 FAQ Management
**Route**: `/cms/faq`

**Features**:
- Add/edit/delete FAQs
- Categorize FAQs
- Reorder FAQs
- Publish/unpublish

---

## 1️⃣1️⃣ System Configuration Module (8 Screens)

### 11.1 General Settings
**Route**: `/settings/general`

**Configuration Options**:
- Platform name
- Support email
- Support phone
- Office address
- Currency (SLL)
- Timezone
- Language
- Maintenance mode toggle

---

### 11.2 Fee Configuration
**Route**: `/settings/fees`

**Fee Settings**:
```
┌────────────────────────────────────────┐
│  Transaction Fees                      │
├────────────────────────────────────────┤
│  Deposit Fee: [0]%                     │
│  Withdrawal Fee: [2]%                  │
│  Transfer Fee: [1]%                    │
│  Bill Payment Fee: [1.5]%              │
│                                        │
│  Investment Management Fee: [0]%       │
│                                        │
│  E-Voting Charge: [Variable per poll]  │
│                                        │
│  KYC Approval Discount:                │
│  ☑ Reduce fees for KYC-approved users  │
│  Discount: [10]%                       │
│                                        │
│  [Save Changes]                        │
└────────────────────────────────────────┘
```

**API**:
- `GET /api/admin/config/fees`
- `PUT /api/admin/config/fees`

---

### 11.3 Security Settings
**Route**: `/settings/security`

**Configuration Options**:
```
┌────────────────────────────────────────┐
│  Security Configuration                │
├────────────────────────────────────────┤
│  OTP Settings:                         │
│  OTP Expiry: [5] minutes               │
│  OTP Length: [6] digits                │
│  Max Resend Attempts: [3]              │
│                                        │
│  Password Policy:                      │
│  Minimum Length: [8] characters        │
│  ☑ Require Uppercase                   │
│  ☑ Require Lowercase                   │
│  ☑ Require Numbers                     │
│  ☑ Require Special Characters          │
│  Password Expiry: [90] days            │
│                                        │
│  Login Security:                       │
│  Max Login Attempts: [5]               │
│  Account Lockout Duration: [30] minutes│
│  Session Timeout: [30] minutes         │
│                                        │
│  Two-Factor Authentication:            │
│  ☑ Require 2FA for Admins              │
│  ○ Optional 2FA for Users              │
│  ○ Required 2FA for Users              │
│                                        │
│  [Save Changes]                        │
└────────────────────────────────────────┘
```

**API**:
- `GET /api/admin/config/security`
- `PUT /api/admin/config/security`

---

### 11.4 Admin Users Management
**Route**: `/settings/admins`

**Features**:
- List of admin users
- Add new admin
- Edit admin permissions
- Deactivate admin

**Table Columns**:
1. Admin ID
2. Name
3. Email
4. Role (Admin / Super Admin)
5. Permissions
6. Status (Active/Inactive)
7. Last Login
8. Actions (Edit, Deactivate, View Activity)

**Add Admin Form**:
```
┌────────────────────────────────────────┐
│  Add New Admin                         │
├────────────────────────────────────────┤
│  Name: [Input] *                       │
│  Email: [Input] *                      │
│  Password: [Auto-generated] *          │
│  [Generate Password]                   │
│                                        │
│  Role:                                 │
│  ○ Admin                               │
│  ○ Super Admin                         │
│                                        │
│  Permissions (for Admin role):         │
│  ☑ Manage Users                        │
│  ☑ Manage Agents                       │
│  ☑ Manage Transactions                 │
│  ☑ Manage Investments                  │
│  ☐ Manage System Settings              │
│  ☑ View Reports                        │
│  ☐ Manage Admins                       │
│                                        │
│  Send welcome email:                   │
│  ☑ Send credentials to email           │
│                                        │
│  [Create Admin]  [Cancel]              │
└────────────────────────────────────────┘
```

**Role Definitions**:
- **Super Admin**: Full access to everything including system settings and admin management
- **Admin**: Customizable permissions, cannot manage other admins or critical settings

**API**:
- `GET /api/admin/admins`
- `POST /api/admin/admins`
- `PUT /api/admin/admins/:id`
- `PUT /api/admin/admins/:id/permissions`
- `DELETE /api/admin/admins/:id`

---

### 11.5 Audit Logs
**Route**: `/settings/audit-logs`

**Features**:
- Complete audit trail of all admin actions
- Filter by admin, action type, date
- Export logs

**Table Columns**:
1. Timestamp
2. Admin Name
3. Action Type
4. Entity Type (User/Agent/Transaction/etc.)
5. Entity ID
6. Changes (Before/After)
7. IP Address
8. User Agent
9. Details

**Filters**:
- Date range
- Admin filter
- Action type (Created/Updated/Deleted/Approved/Rejected)
- Entity type

**API**:
- `GET /api/admin/audit-logs?page&limit&adminId&actionType&entityType&startDate&endDate`

---

### 11.6 Security Events
**Route**: `/settings/security-events`

**Features**:
- Log of suspicious activities
- Failed login attempts
- Unusual transaction patterns
- IP blocking

**Table Columns**:
1. Timestamp
2. Event Type
3. User/Admin
4. IP Address
5. Description
6. Risk Level (Low/Medium/High)
7. Status (Resolved/Investigating/Blocked)
8. Actions

**Event Types**:
- Failed login attempts
- Multiple OTP failures
- Unusual transaction patterns
- Account access from new location
- Rapid transactions
- Large transactions

**API**:
- `GET /api/admin/security-events`

---

### 11.7 Fraud Detection Logs
**Route**: `/settings/fraud-detection`

**Features**:
- Automated fraud detection alerts
- Flagged transactions
- Flagged users/agents
- Investigation tools

**Table Columns**:
1. Alert ID
2. Timestamp
3. Alert Type
4. User/Agent
5. Transaction ID (if applicable)
6. Risk Score
7. Description
8. Status
9. Actions (Investigate, Block, Dismiss)

**Alert Types**:
- Velocity check failure (too many transactions)
- Amount anomaly
- Duplicate transactions
- KYC document fraud suspicion
- Account takeover attempt
- Agent fraud

**API**:
- `GET /api/admin/fraud-detection-logs`
- `PUT /api/admin/fraud-detection-logs/:id/status`

---

### 11.8 System Maintenance
**Route**: `/settings/maintenance`

**Features**:
- Enable/disable maintenance mode
- Maintenance message configuration
- Scheduled maintenance
- Database backup triggers

**Maintenance Mode**:
```
┌────────────────────────────────────────┐
│  Maintenance Mode                      │
├────────────────────────────────────────┤
│  Status: ○ Enabled  ● Disabled         │
│                                        │
│  Message to users:                     │
│  ┌──────────────────────────────────┐ │
│  │ [Rich Text Editor]               │ │
│  │ "We're performing scheduled      │ │
│  │ maintenance. We'll be back soon!"│ │
│  └──────────────────────────────────┘ │
│                                        │
│  Schedule Maintenance:                 │
│  Start: [DateTime Picker]              │
│  End: [DateTime Picker]                │
│  ☑ Automatically enable at start time  │
│  ☑ Automatically disable at end time   │
│                                        │
│  [Save]  [Cancel]                      │
└────────────────────────────────────────┘
```

---

## 1️⃣2️⃣ Support & Help Module (3 Screens)

### 12.1 Support Tickets
**Route**: `/support/tickets`

**Features**:
- List of user-submitted support tickets
- Respond to tickets
- Assign tickets to admins
- Close tickets

**Table Columns**:
1. Ticket ID
2. User Name
3. Subject
4. Category
5. Priority
6. Status (Open/In Progress/Resolved/Closed)
7. Created Date
8. Last Updated
9. Assigned To
10. Actions (View, Reply, Close)

---

### 12.2 Ticket Detail Screen
**Route**: `/support/tickets/:id`

**Features**:
- Ticket conversation thread
- Reply to user
- Internal notes (not visible to user)
- Change status
- Assign to admin
- Close ticket

---

### 12.3 Support Analytics
**Route**: `/support/analytics`

**Features**:
- Total tickets
- Open vs closed tickets
- Average resolution time
- Tickets by category
- Admin performance (tickets resolved)

---

## 🔒 Role-Based Access Control (RBAC)

### User Roles

1. **SUPER_ADMIN**
   - Full access to all modules
   - Manage other admins
   - System configuration
   - Security settings
   - Cannot be restricted

2. **ADMIN**
   - Customizable permissions via permissions array
   - No access to:
     - Admin management
     - Critical security settings
     - System configuration

### Permission Structure (JSONB)

```json
{
  "permissions": [
    "users.view",
    "users.edit",
    "users.approve_kyc",
    "users.deactivate",

    "agents.view",
    "agents.edit",
    "agents.approve",
    "agents.commission_adjust",

    "transactions.view",
    "transactions.approve",
    "transactions.reject",

    "investments.view",
    "investments.edit",
    "investments.process_returns",

    "bill_payments.view",
    "bill_payments.manage_providers",

    "e_voting.view",
    "e_voting.create",
    "e_voting.edit",
    "e_voting.delete",

    "reports.view",
    "reports.export",

    "cms.edit_terms",
    "cms.edit_privacy",
    "cms.send_notifications",

    "settings.view",
    "settings.edit_fees",
    "settings.edit_limits"
  ]
}
```

### Route Guards

Every route checks:
1. User is authenticated (has valid JWT)
2. User role is ADMIN or SUPER_ADMIN
3. User has required permission (if ADMIN role)

Example:
```dart
// Route definition
GoRoute(
  path: '/users',
  builder: (context, state) => UsersListScreen(),
  redirect: (context, state) {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) return '/login';
    if (!authProvider.hasPermission('users.view')) return '/unauthorized';
    return null;
  },
)
```

---

## 🔗 API Integration

### Existing Backend

This admin application connects to the **existing tcc_backend** Node.js/TypeScript API:

**Backend Project**: `tcc_backend/`
- **Technology**: Node.js 20+ with TypeScript
- **Database**: PostgreSQL with 40+ tables
- **Authentication**: JWT (access + refresh tokens)
- **API Version**: v1
- **Status**: Infrastructure complete, endpoints ready for implementation

**API Documentation**: See `api_specification.md` for complete endpoint details

### Base Configuration

```dart
class ApiService {
  // Development
  static const String baseUrlDev = 'http://localhost:3000/v1';

  // Production
  static const String baseUrlProd = 'https://api.tccapp.com/v1';

  static String get baseUrl =>
    Environment.isDevelopment ? baseUrlDev : baseUrlProd;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Interceptors
  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add auth token
        final token = getStoredToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioError e, handler) {
        // Handle errors
        if (e.response?.statusCode == 401) {
          // Redirect to login
          logout();
        }
        return handler.next(e);
      },
    ));
  }
}
```

### API Endpoints Summary

**Note**: The admin application uses the existing **tcc_backend** API endpoints. Below is a summary of admin-relevant endpoints. For complete API documentation, see `api_specification.md`.

**Backend API Categories** (70+ total endpoints across 16 categories):

**Authentication** (7 admin-specific endpoints)
- POST /v1/auth/admin/login
- POST /v1/auth/admin/verify-2fa
- POST /v1/auth/admin/logout
- POST /v1/auth/admin/refresh-token
- POST /v1/auth/admin/forgot-password
- POST /v1/auth/admin/reset-password
- PUT /v1/auth/admin/change-password

**Dashboard** (4 endpoints)
- GET /api/admin/dashboard/stats
- GET /api/admin/dashboard/charts
- GET /api/admin/dashboard/recent-activity
- GET /api/admin/dashboard/quick-actions

**Users** (12+ endpoints)
- GET /api/admin/users
- GET /api/admin/users/:id
- PUT /api/admin/users/:id
- POST /api/admin/users
- PUT /api/admin/users/:id/status
- GET /api/admin/users/:id/transactions
- GET /api/admin/users/:id/investments
- GET /api/admin/users/:id/activity-log
- GET /api/admin/kyc/pending
- POST /api/admin/kyc/:id/approve
- POST /api/admin/kyc/:id/reject
- POST /api/admin/users/export

**Agents** (15+ endpoints)
- GET /api/admin/agents
- GET /api/admin/agents/:id
- PUT /api/admin/agents/:id
- PUT /api/admin/agents/:id/commission-rate
- GET /api/admin/agents/pending-verification
- POST /api/admin/agents/:id/approve
- POST /api/admin/agents/:id/reject
- GET /api/admin/agents/credit-requests
- POST /api/admin/agents/credit-requests/:id/approve
- POST /api/admin/agents/credit-requests/:id/reject
- GET /api/admin/agents/:id/performance
- GET /api/admin/agents/:id/transactions
- GET /api/admin/agents/:id/commissions
- GET /api/admin/agents/commission-config
- PUT /api/admin/agents/commission-config

**Transactions** (12+ endpoints)
- GET /api/admin/transactions
- GET /api/admin/transactions/:id
- PUT /api/admin/transactions/:id/status
- POST /api/admin/transactions/:id/notes
- GET /api/admin/transactions/summary
- GET /api/admin/transactions/deposits/pending
- POST /api/admin/transactions/deposits/:id/approve
- POST /api/admin/transactions/deposits/:id/reject
- GET /api/admin/transactions/withdrawals/pending
- POST /api/admin/transactions/withdrawals/:id/approve
- POST /api/admin/transactions/withdrawals/:id/reject
- GET /api/admin/transactions/analytics

**Investments** (15+ endpoints)
- GET /api/admin/investments
- GET /api/admin/investments/:id
- GET /api/admin/investments/summary
- GET /api/admin/investments/matured-pending
- POST /api/admin/investments/:id/process-return
- GET /api/admin/investments/categories
- POST /api/admin/investments/categories
- PUT /api/admin/investments/categories/:id
- DELETE /api/admin/investments/categories/:id
- GET /api/admin/investments/tenures
- POST /api/admin/investments/tenures
- PUT /api/admin/investments/tenures/:id
- GET /api/admin/investments/units-pricing
- PUT /api/admin/investments/units-pricing
- GET /api/admin/investments/tenure-change-requests

**Bill Payments** (8+ endpoints)
- GET /api/admin/bill-payments
- GET /api/admin/bill-providers
- POST /api/admin/bill-providers
- PUT /api/admin/bill-providers/:id
- DELETE /api/admin/bill-providers/:id
- GET /api/admin/bill-payments/analytics
- GET /api/admin/bill-payments/failed
- GET /api/admin/bill-payments/config

**E-Voting** (10+ endpoints)
- GET /api/admin/polls
- GET /api/admin/polls/:id
- POST /api/admin/polls
- PUT /api/admin/polls/:id
- DELETE /api/admin/polls/:id
- GET /api/admin/polls/:id/results
- PUT /api/admin/polls/:id/status
- GET /api/admin/polls/:id/votes
- GET /api/admin/polls/:id/votes/export
- GET /api/admin/e-voting/analytics

**Reports** (8+ endpoints)
- GET /api/admin/reports/users
- GET /api/admin/reports/transactions
- GET /api/admin/reports/revenue
- GET /api/admin/reports/agents
- GET /api/admin/reports/investments
- GET /api/admin/reports/bill-payments
- GET /api/admin/reports/e-voting
- POST /api/admin/reports/custom

**CMS** (6+ endpoints)
- GET /api/admin/cms/terms
- PUT /api/admin/cms/terms
- GET /api/admin/cms/privacy
- PUT /api/admin/cms/privacy
- POST /api/admin/notifications/broadcast
- GET /api/admin/notifications/history

**Configuration** (8+ endpoints)
- GET /api/admin/config/general
- PUT /api/admin/config/general
- GET /api/admin/config/fees
- PUT /api/admin/config/fees
- GET /api/admin/config/security
- PUT /api/admin/config/security
- GET /api/admin/config/transaction-limits
- PUT /api/admin/config/transaction-limits

**Admin Management** (5+ endpoints)
- GET /api/admin/admins
- POST /api/admin/admins
- PUT /api/admin/admins/:id
- PUT /api/admin/admins/:id/permissions
- DELETE /api/admin/admins/:id

**Audit & Security** (3+ endpoints)
- GET /api/admin/audit-logs
- GET /api/admin/security-events
- GET /api/admin/fraud-detection-logs

**Support** (5+ endpoints)
- GET /api/admin/support/tickets
- GET /api/admin/support/tickets/:id
- POST /api/admin/support/tickets/:id/reply
- PUT /api/admin/support/tickets/:id/status
- GET /api/admin/support/analytics

**Total: 130+ API endpoints**

---

## 📁 Project Structure

### Overall TCC Project Structure

```
tcc/                                    # Root project directory
├── tcc_backend/                        # ✅ Node.js/TypeScript Backend
│   ├── src/
│   │   ├── config/
│   │   ├── database/
│   │   ├── middleware/
│   │   ├── utils/
│   │   ├── types/
│   │   ├── controllers/
│   │   ├── services/
│   │   └── routes/
│   └── package.json
│
├── tcc_user_mobile_client/             # ✅ Flutter User App
│   ├── lib/
│   ├── assets/
│   └── pubspec.yaml
│
├── tcc_agent_client/                   # ✅ Flutter Agent App
│   ├── lib/
│   ├── assets/
│   └── pubspec.yaml
│
├── tcc_admin_client/                   # 🔨 THIS PROJECT (Flutter Web)
│   ├── lib/                            # Admin app source code
│   ├── web/                            # Web-specific files
│   ├── assets/                         # Images, fonts
│   └── pubspec.yaml
│
├── database_schema.sql                 # ✅ PostgreSQL schema (40+ tables)
├── api_specification.md                # ✅ 70+ API endpoints
├── design_system.md                    # ✅ Shared design system
├── PROJECT_SUMMARY.md                  # ✅ Complete project overview
└── TCC_ADMIN_WEB_APP_REQUIREMENTS.md   # 📄 This document
```

### Admin App Project Structure (tcc_admin_client/)

```
tcc_admin_client/
├── lib/
│   ├── main.dart
│   │
│   ├── config/
│   │   ├── app_colors.dart              # Admin color palette
│   │   ├── app_theme.dart               # Theme configuration
│   │   ├── app_constants.dart           # Constants
│   │   └── routes.dart                  # Route definitions
│   │
│   ├── models/
│   │   ├── admin_model.dart
│   │   ├── user_model.dart
│   │   ├── agent_model.dart
│   │   ├── transaction_model.dart
│   │   ├── investment_model.dart
│   │   ├── poll_model.dart
│   │   ├── support_ticket_model.dart
│   │   └── api_response_model.dart
│   │
│   ├── services/
│   │   ├── api_service.dart             # Base HTTP client
│   │   ├── auth_service.dart            # Authentication
│   │   ├── user_service.dart
│   │   ├── agent_service.dart
│   │   ├── transaction_service.dart
│   │   ├── investment_service.dart
│   │   ├── poll_service.dart
│   │   ├── report_service.dart
│   │   └── storage_service.dart         # Local storage
│   │
│   ├── providers/
│   │   ├── auth_provider.dart           # Auth state
│   │   ├── dashboard_provider.dart      # Dashboard data
│   │   ├── user_provider.dart
│   │   ├── agent_provider.dart
│   │   ├── transaction_provider.dart
│   │   └── theme_provider.dart          # Theme state
│   │
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── two_fa_screen.dart
│   │   │   ├── forgot_password_screen.dart
│   │   │   └── reset_password_screen.dart
│   │   │
│   │   ├── dashboard/
│   │   │   ├── main_dashboard_screen.dart
│   │   │   ├── analytics_dashboard_screen.dart
│   │   │   └── system_health_screen.dart
│   │   │
│   │   ├── users/
│   │   │   ├── users_list_screen.dart
│   │   │   ├── user_detail_screen.dart
│   │   │   ├── pending_kyc_screen.dart
│   │   │   ├── kyc_review_screen.dart
│   │   │   ├── edit_user_screen.dart
│   │   │   └── create_user_screen.dart
│   │   │
│   │   ├── agents/
│   │   │   ├── agents_list_screen.dart
│   │   │   ├── agent_detail_screen.dart
│   │   │   ├── pending_verifications_screen.dart
│   │   │   ├── verification_review_screen.dart
│   │   │   ├── credit_requests_screen.dart
│   │   │   ├── commission_config_screen.dart
│   │   │   ├── agent_map_screen.dart
│   │   │   └── performance_comparison_screen.dart
│   │   │
│   │   ├── transactions/
│   │   │   ├── transactions_list_screen.dart
│   │   │   ├── transaction_detail_screen.dart
│   │   │   ├── pending_deposits_screen.dart
│   │   │   ├── pending_withdrawals_screen.dart
│   │   │   ├── deposit_history_screen.dart
│   │   │   ├── withdrawal_history_screen.dart
│   │   │   ├── transfer_history_screen.dart
│   │   │   ├── failed_transactions_screen.dart
│   │   │   ├── transaction_analytics_screen.dart
│   │   │   └── transaction_limits_screen.dart
│   │   │
│   │   ├── investments/
│   │   │   ├── investments_list_screen.dart
│   │   │   ├── investment_detail_screen.dart
│   │   │   ├── matured_pending_screen.dart
│   │   │   ├── categories_management_screen.dart
│   │   │   ├── tenures_config_screen.dart
│   │   │   ├── units_pricing_screen.dart
│   │   │   ├── agreement_templates_screen.dart
│   │   │   ├── insurance_management_screen.dart
│   │   │   ├── tenure_change_requests_screen.dart
│   │   │   └── investment_reports_screen.dart
│   │   │
│   │   ├── bill_payments/
│   │   │   ├── bill_payments_list_screen.dart
│   │   │   ├── providers_management_screen.dart
│   │   │   ├── bill_payment_analytics_screen.dart
│   │   │   ├── failed_bill_payments_screen.dart
│   │   │   └── bill_payment_config_screen.dart
│   │   │
│   │   ├── e_voting/
│   │   │   ├── polls_list_screen.dart
│   │   │   ├── create_poll_screen.dart
│   │   │   ├── edit_poll_screen.dart
│   │   │   ├── poll_detail_screen.dart
│   │   │   ├── poll_votes_screen.dart
│   │   │   └── e_voting_analytics_screen.dart
│   │   │
│   │   ├── reports/
│   │   │   ├── reports_dashboard_screen.dart
│   │   │   ├── user_report_screen.dart
│   │   │   ├── transaction_report_screen.dart
│   │   │   ├── revenue_report_screen.dart
│   │   │   ├── agent_report_screen.dart
│   │   │   └── custom_report_builder_screen.dart
│   │   │
│   │   ├── cms/
│   │   │   ├── terms_management_screen.dart
│   │   │   ├── privacy_management_screen.dart
│   │   │   ├── notification_management_screen.dart
│   │   │   └── faq_management_screen.dart
│   │   │
│   │   ├── settings/
│   │   │   ├── general_settings_screen.dart
│   │   │   ├── fee_configuration_screen.dart
│   │   │   ├── security_settings_screen.dart
│   │   │   ├── admin_users_screen.dart
│   │   │   ├── audit_logs_screen.dart
│   │   │   ├── security_events_screen.dart
│   │   │   ├── fraud_detection_screen.dart
│   │   │   └── maintenance_screen.dart
│   │   │
│   │   ├── support/
│   │   │   ├── support_tickets_screen.dart
│   │   │   ├── ticket_detail_screen.dart
│   │   │   └── support_analytics_screen.dart
│   │   │
│   │   └── layout/
│   │       ├── main_layout.dart          # Sidebar + Topbar + Content
│   │       ├── sidebar.dart
│   │       ├── topbar.dart
│   │       └── breadcrumbs.dart
│   │
│   ├── widgets/
│   │   ├── common/
│   │   │   ├── custom_button.dart
│   │   │   ├── custom_text_field.dart
│   │   │   ├── custom_dropdown.dart
│   │   │   ├── custom_checkbox.dart
│   │   │   ├── custom_radio.dart
│   │   │   ├── loading_indicator.dart
│   │   │   ├── error_widget.dart
│   │   │   └── empty_state.dart
│   │   │
│   │   ├── cards/
│   │   │   ├── stat_card.dart
│   │   │   ├── kpi_card.dart
│   │   │   ├── info_card.dart
│   │   │   └── white_card.dart
│   │   │
│   │   ├── tables/
│   │   │   ├── custom_data_table.dart
│   │   │   ├── table_header.dart
│   │   │   ├── table_row.dart
│   │   │   ├── pagination.dart
│   │   │   └── table_filters.dart
│   │   │
│   │   ├── charts/
│   │   │   ├── line_chart_widget.dart
│   │   │   ├── bar_chart_widget.dart
│   │   │   ├── pie_chart_widget.dart
│   │   │   ├── area_chart_widget.dart
│   │   │   └── chart_legend.dart
│   │   │
│   │   ├── badges/
│   │   │   ├── status_badge.dart
│   │   │   ├── count_badge.dart
│   │   │   └── role_badge.dart
│   │   │
│   │   ├── modals/
│   │   │   ├── confirmation_dialog.dart
│   │   │   ├── info_dialog.dart
│   │   │   ├── form_dialog.dart
│   │   │   └── image_viewer_dialog.dart
│   │   │
│   │   └── forms/
│   │       ├── kyc_approval_form.dart
│   │       ├── rejection_reason_form.dart
│   │       ├── credit_request_form.dart
│   │       ├── withdrawal_approval_form.dart
│   │       └── investment_return_form.dart
│   │
│   ├── utils/
│   │   ├── validators.dart              # Form validators
│   │   ├── formatters.dart              # Date, currency, number formatters
│   │   ├── helpers.dart                 # Helper functions
│   │   ├── constants.dart               # App-wide constants
│   │   ├── extensions.dart              # Dart extensions
│   │   └── permissions.dart             # Permission checking
│   │
│   └── l10n/
│       ├── app_en.arb                   # English translations
│       └── app_krio.arb                 # Krio translations (future)
│
├── web/
│   ├── index.html
│   ├── manifest.json
│   ├── favicon.png
│   └── icons/
│
├── assets/
│   ├── images/
│   │   ├── logo.png
│   │   ├── logo_white.png
│   │   └── illustrations/
│   └── fonts/
│       └── Inter/
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── pubspec.yaml
├── README.md
└── .env
```

---

## 📦 Dependencies (pubspec.yaml)

```yaml
name: tcc_admin_client
description: TCC Admin Web Application
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  provider: ^6.1.1

  # Routing
  go_router: ^13.0.0

  # HTTP & API
  dio: ^5.4.0
  http: ^1.1.0

  # Data Storage
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0

  # Data Tables
  data_table_2: ^2.5.9

  # Charts
  fl_chart: ^0.66.0

  # Forms
  flutter_form_builder: ^9.1.1
  form_builder_validators: ^9.1.0

  # Date & Time
  intl: ^0.18.1
  syncfusion_flutter_datepicker: ^24.1.41

  # File Handling
  file_picker: ^6.1.1
  image_picker_web: ^3.1.1
  flutter_image_compress: ^2.1.0
  pdf: ^3.10.7

  # Rich Text Editor
  html_editor_enhanced: ^2.5.1

  # Export
  csv: ^5.1.1
  excel: ^4.0.2

  # UI Utilities
  url_launcher: ^6.2.2
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  loading_animation_widget: ^1.2.0+4

  # Icons
  flutter_svg: ^2.0.9
  cupertino_icons: ^1.0.6

  # Toast/Snackbar
  fluttertoast: ^8.2.4

  # Image Viewer
  photo_view: ^0.14.0

  # Permissions
  permission_handler: ^11.1.0

  # Environment Variables
  flutter_dotenv: ^5.1.0

  # Utilities
  uuid: ^4.3.1
  path: ^1.8.3
  path_provider: ^2.1.1

  # WebSocket (optional for real-time)
  web_socket_channel: ^2.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.7

flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/images/illustrations/
    - .env

  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter/Inter-Regular.ttf
        - asset: assets/fonts/Inter/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter/Inter-Bold.ttf
          weight: 700
```

---

## 🔄 Key Workflows & Business Logic

### 1. KYC Approval Workflow

```dart
Future<void> approveKYC(String userId) async {
  try {
    // 1. Call API to approve KYC
    await _apiService.post('/api/admin/kyc/$userId/approve');

    // 2. Update user status to APPROVED
    // 3. Send notification to user
    // 4. Log admin action in audit trail
    // 5. Update UI

    showSuccessToast('KYC approved successfully');
  } catch (e) {
    showErrorToast('Failed to approve KYC: $e');
  }
}

Future<void> rejectKYC(String userId, String reason) async {
  try {
    // 1. Call API with rejection reason
    await _apiService.post(
      '/api/admin/kyc/$userId/reject',
      data: {'reason': reason},
    );

    // 2. Update user status to REJECTED
    // 3. Send notification with reason to user
    // 4. Log admin action
    // 5. Update UI

    showSuccessToast('KYC rejected');
  } catch (e) {
    showErrorToast('Failed to reject KYC: $e');
  }
}
```

### 2. Agent Credit Request Approval Workflow

```dart
Future<void> approveCreditRequest(String requestId, double amount) async {
  try {
    // 1. Verify receipt upload
    // 2. Call API to approve
    await _apiService.post(
      '/api/admin/agents/credit-requests/$requestId/approve',
    );

    // 3. Credit agent wallet
    // 4. Create transaction record
    // 5. Update agent balance
    // 6. Send notification to agent
    // 7. Log in audit trail
    // 8. Update UI

    showSuccessToast('Credit request approved. Wallet credited.');
  } catch (e) {
    showErrorToast('Failed to approve credit request: $e');
  }
}
```

### 3. Withdrawal Approval Workflow

```dart
Future<void> approveWithdrawal(String withdrawalId, {
  required double amount,
  required String type, // 'full' or 'partial'
}) async {
  try {
    // 1. Validate withdrawal details
    final withdrawal = await _apiService.get('/api/admin/transactions/withdrawals/$withdrawalId');

    // 2. If investment withdrawal, check tenure
    if (withdrawal['type'] == 'INVESTMENT') {
      final investment = withdrawal['investment'];
      final isMatured = investment['status'] == 'MATURED';

      if (!isMatured && type == 'full') {
        // Warning: Paying interest for incomplete tenure
        final confirmed = await showConfirmationDialog(
          'Tenure incomplete. Proceed with full payment?'
        );
        if (!confirmed) return;
      }
    }

    // 3. Call API to approve
    await _apiService.post(
      '/api/admin/transactions/withdrawals/$withdrawalId/approve',
      data: {
        'amount': amount,
        'type': type,
      },
    );

    // 4. Process payment to bank/mobile money
    // 5. Update transaction status
    // 6. Update user balance
    // 7. Send notification
    // 8. Log in audit trail

    showSuccessToast('Withdrawal approved and processed');
  } catch (e) {
    showErrorToast('Failed to approve withdrawal: $e');
  }
}
```

### 4. Investment Return Processing Workflow

```dart
Future<void> processInvestmentReturn({
  required String investmentId,
  required double actualReturnPercentage,
  String? notes,
}) async {
  try {
    // 1. Get investment details
    final investment = await _apiService.get('/api/admin/investments/$investmentId');

    // 2. Calculate payout
    final principal = investment['amount'];
    final actualReturn = principal * (actualReturnPercentage / 100);
    final totalPayout = principal + actualReturn;

    // 3. Show confirmation
    final confirmed = await showConfirmationDialog(
      'Process return?\n'
      'Principal: ${formatCurrency(principal)} SLL\n'
      'Return: ${formatCurrency(actualReturn)} SLL ($actualReturnPercentage%)\n'
      'Total: ${formatCurrency(totalPayout)} SLL'
    );

    if (!confirmed) return;

    // 4. Call API to process return
    await _apiService.post(
      '/api/admin/investments/$investmentId/process-return',
      data: {
        'actualReturnPercentage': actualReturnPercentage,
        'actualReturnAmount': actualReturn,
        'notes': notes,
      },
    );

    // 5. Create investment_return record
    // 6. Credit user wallet with total payout
    // 7. Update investment status to PAID
    // 8. Create transaction record
    // 9. Send notification to user
    // 10. Log in audit trail

    showSuccessToast('Investment return processed successfully');
  } catch (e) {
    showErrorToast('Failed to process return: $e');
  }
}
```

### 5. Poll Creation & Management Workflow

```dart
Future<void> createPoll({
  required String title,
  required String question,
  required List<String> options,
  required double votingCharge,
  required DateTime startDate,
  required DateTime endDate,
  String? description,
  required PollStatus status,
}) async {
  try {
    // 1. Validate inputs
    if (options.length < 2 || options.length > 4) {
      throw Exception('Poll must have 2-4 options');
    }

    // 2. Call API to create poll
    final response = await _apiService.post(
      '/api/admin/polls',
      data: {
        'title': title,
        'question': question,
        'options': options,
        'votingCharge': votingCharge,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'description': description,
        'status': status.name,
      },
    );

    // 3. If status is ACTIVE, publish immediately
    // 4. If status is SCHEDULED, set up timer
    // 5. Log in audit trail

    showSuccessToast('Poll created successfully');

    // Navigate to poll detail
    navigateTo('/e-voting/${response['id']}');
  } catch (e) {
    showErrorToast('Failed to create poll: $e');
  }
}

Future<void> endPoll(String pollId) async {
  final confirmed = await showConfirmationDialog(
    'End this poll? This action cannot be undone.'
  );

  if (!confirmed) return;

  try {
    await _apiService.put(
      '/api/admin/polls/$pollId/status',
      data: {'status': 'ENDED'},
    );

    showSuccessToast('Poll ended');
  } catch (e) {
    showErrorToast('Failed to end poll: $e');
  }
}
```

---

## 🧪 Testing Strategy

### Unit Tests
- Models serialization/deserialization
- Validators
- Formatters
- Helper functions
- Business logic functions

### Widget Tests
- Individual widgets
- Forms with validation
- Buttons and interactions
- State management

### Integration Tests
- Complete workflows (login to logout)
- KYC approval flow
- Transaction approval flow
- Report generation

### End-to-End Tests
- Critical user journeys
- Cross-browser compatibility
- Performance testing
- Security testing

---

## 🚀 Deployment

### Build for Web

```bash
# Production build
flutter build web --release --web-renderer html

# Output: build/web/
```

### Deployment Platforms

1. **Firebase Hosting**
2. **AWS S3 + CloudFront**
3. **Vercel**
4. **Netlify**
5. **Custom Server (Nginx)**

### Environment Configuration

**.env file**:
```
API_BASE_URL=https://api.tcc.sl/api
ENVIRONMENT=production
VERSION=1.0.0
```

---

## 📈 Performance Optimization

1. **Lazy Loading**: Load data on-demand
2. **Pagination**: Server-side pagination for large lists
3. **Caching**: Cache API responses with expiry
4. **Image Optimization**: Compress and cache images
5. **Code Splitting**: Split routes for faster initial load
6. **Debouncing**: Search inputs
7. **Memoization**: Expensive calculations

---

## 🔐 Security Best Practices

1. **JWT Token Management**
   - Store tokens securely (flutter_secure_storage)
   - Auto-refresh tokens before expiry
   - Clear tokens on logout

2. **Input Validation**
   - Client-side validation
   - Server-side validation (trust backend)
   - Sanitize user inputs

3. **HTTPS Only**
   - All API calls over HTTPS
   - Enforce HTTPS in production

4. **CORS Configuration**
   - Whitelist admin domain
   - Restrict API access

5. **Rate Limiting**
   - Implement request throttling
   - Prevent brute force attacks

6. **Audit Logging**
   - Log all admin actions
   - Include IP addresses
   - Timestamp everything

7. **Session Management**
   - Auto-logout on inactivity
   - Single session per admin (optional)
   - Session timeout warnings

---

## 📚 Documentation

### For Developers

1. **Setup Guide**: Getting started with development
2. **API Documentation**: All endpoints with examples
3. **Component Library**: Reusable widgets catalog
4. **Style Guide**: Design system implementation
5. **Testing Guide**: Writing tests
6. **Deployment Guide**: Production deployment steps

### For Admins (User Manual)

1. **Getting Started**: Login, navigation, dashboard overview
2. **User Management**: How to approve KYC, manage users
3. **Agent Management**: Verify agents, manage commissions
4. **Transaction Management**: Approve deposits/withdrawals
5. **Investment Management**: Process returns, configure settings
6. **E-Voting**: Create polls, monitor results
7. **Reports**: Generate and export reports
8. **System Configuration**: Fee settings, security settings
9. **Troubleshooting**: Common issues and solutions

---

## 🎯 Success Metrics

### Admin Efficiency
- Average KYC approval time < 5 minutes
- Average withdrawal approval time < 10 minutes
- Dashboard load time < 2 seconds
- Report generation time < 30 seconds

### System Performance
- 99.9% uptime
- API response time < 500ms (p95)
- Page load time < 3 seconds
- Support 100+ concurrent admins

### User Satisfaction
- Admin user satisfaction > 4.5/5
- Support ticket resolution time < 24 hours
- System error rate < 0.1%

---

## 🗓️ Development Timeline

**Note**: This timeline assumes the **tcc_backend** API endpoints will be implemented in parallel with the admin frontend development.

### Phase 1: Foundation (Week 1-2)
- Setup Flutter Web project structure
- Implement authentication (connect to existing backend)
- Create layout (sidebar, topbar)
- Setup routing and state management
- Configure API integration with tcc_backend
- **Backend**: Implement admin authentication endpoints

### Phase 2: Core Modules (Week 3-6)
- Dashboard implementation
- User management module
- Agent management module
- Transaction management module
- **Backend**: Implement user, agent, and transaction admin endpoints

### Phase 3: Advanced Modules (Week 7-10)
- Investment management module
- Bill payment management module
- E-Voting module
- Reports module
- **Backend**: Implement investment, bill payment, e-voting, and report endpoints

### Phase 4: Configuration & Support (Week 11-12)
- Content management system
- System configuration
- Support ticketing system
- Admin user management
- **Backend**: Implement CMS, config, and support endpoints

### Phase 5: Testing & Polish (Week 13-14)
- Unit testing (frontend + backend)
- Integration testing
- UI/UX polish
- Performance optimization
- Bug fixes
- Security audit

### Phase 6: Deployment (Week 15-16)
- Production deployment (backend + frontend)
- User training
- Documentation
- Monitoring setup
- Launch

**Total Estimated Time**: 16 weeks (4 months)

**Parallel Development**:
- Frontend team builds Flutter Web admin app
- Backend team implements API endpoints (from api_specification.md)
- Weekly integration testing
- Shared design system and data models

---

## 🎨 Design Assets Needed

1. **Logo**
   - Main logo (color)
   - Logo white version (for dark sidebar)
   - Favicon

2. **Illustrations** (for empty states)
   - No users found
   - No transactions
   - No data available
   - Error states

3. **Icons**
   - Custom icons for modules (if needed)
   - Status icons

4. **Placeholder Images**
   - Profile placeholder
   - Document placeholder

---

## ✅ Pre-Launch Checklist

### Development
- [ ] All 60+ screens implemented
- [ ] All API endpoints integrated
- [ ] Form validations working
- [ ] Error handling implemented
- [ ] Loading states everywhere
- [ ] Responsive design tested

### Testing
- [ ] Unit tests written (>80% coverage)
- [ ] Integration tests passed
- [ ] Cross-browser testing (Chrome, Firefox, Safari, Edge)
- [ ] Performance testing completed
- [ ] Security audit passed

### Design
- [ ] Design system fully implemented
- [ ] Consistent spacing and colors
- [ ] All states designed (empty, loading, error)
- [ ] Accessibility standards met (WCAG AA)

### Documentation
- [ ] Developer documentation complete
- [ ] Admin user manual complete
- [ ] API documentation up-to-date
- [ ] Deployment guide ready

### Security
- [ ] Authentication working
- [ ] Authorization working (RBAC)
- [ ] Audit logging implemented
- [ ] Security events monitoring
- [ ] Fraud detection active

### Deployment
- [ ] Environment variables configured
- [ ] SSL certificate installed
- [ ] Domain configured
- [ ] Backups automated
- [ ] Monitoring and alerts setup

### Training
- [ ] Admin training sessions scheduled
- [ ] Training materials prepared
- [ ] Support channels established

---

## 🆘 Support & Maintenance

### Post-Launch Support Plan

1. **Week 1-2**: Daily monitoring, immediate bug fixes
2. **Week 3-4**: Bug fixes, minor improvements
3. **Month 2+**: Regular maintenance, feature enhancements

### Monitoring Tools
- Application performance monitoring (APM)
- Error tracking (Sentry)
- Analytics (Google Analytics)
- Uptime monitoring

### Backup & Recovery
- Daily database backups
- Recovery time objective (RTO): 1 hour
- Recovery point objective (RPO): 24 hours

---

## 🔄 Future Enhancements

### Phase 2 Features (Post-Launch)
1. **Real-time Updates**
   - WebSocket integration
   - Live transaction monitoring
   - Real-time notifications

2. **Advanced Analytics**
   - Predictive analytics
   - ML-based fraud detection
   - User behavior analytics

3. **Mobile Admin App**
   - Flutter mobile version for admins
   - Quick approvals on-the-go

4. **Multi-language Support**
   - English, Krio, French
   - RTL support

5. **Advanced Reporting**
   - Custom report builder
   - Scheduled reports (email)
   - Interactive dashboards

6. **Integration Improvements**
   - Direct bank API integrations
   - Mobile Money API integrations
   - Third-party service integrations

7. **Automation**
   - Auto-approve low-risk transactions
   - Automated investment return calculations
   - Smart fraud detection with auto-blocking

---

## 📞 Contact & Team

### Development Team Contacts
- **Lead Developer**: [Name]
- **Backend Developer**: [Name]
- **Designer**: [Name]
- **Project Manager**: [Name]

### Support Channels
- **Technical Support**: tech@tcc.sl
- **Bug Reports**: GitHub Issues
- **Feature Requests**: [Platform]

---

## 📄 License & Legal

- **Copyright**: © 2025 The Community Coin (TCC)
- **License**: Proprietary - All Rights Reserved
- **Privacy Policy**: Link to privacy policy
- **Terms of Service**: Link to terms

---

## 🎉 Conclusion

This comprehensive requirements document serves as the **single source of truth** for building the TCC Admin Web Application. It includes:

- ✅ **60+ detailed screen specifications**
- ✅ **Complete feature list across 12 modules**
- ✅ **Consistent design system with agent & user apps**
- ✅ **70+ backend API endpoints** (from existing tcc_backend)
- ✅ **Business logic workflows**
- ✅ **Security & RBAC implementation**
- ✅ **Testing strategy**
- ✅ **Deployment guide**
- ✅ **Post-launch support plan**

### Existing Infrastructure

This admin app **integrates with**:
- ✅ **tcc_backend** - Complete Node.js/TypeScript API infrastructure
- ✅ **tcc_user_mobile_client** - Flutter user mobile app (blue theme)
- ✅ **tcc_agent_client** - Flutter agent mobile app (orange theme)
- ✅ **PostgreSQL Database** - 40+ tables with complete schema
- ✅ **Design System** - Shared across all applications

**Next Steps**:
1. Review and approve this requirements document
2. Setup Flutter Web project (tcc_admin_client/)
3. Implement backend admin API endpoints (in parallel)
4. Begin Phase 1 development (Foundation)
5. Weekly progress reviews with backend team
6. Iterative development and integration testing

---

**Document Version**: 1.0.0
**Last Updated**: January 2025
**Status**: Ready for Development
**Platform**: Flutter Web
**Target Completion**: 16 weeks

---

**Prepared by**: Claude Code
**For**: TCC (The Community Coin)
**Date**: January 2025

---

## 🏆 This is Production-Ready!

With this comprehensive specification, the development team has everything needed to build a world-class admin panel for the TCC platform. The requirements are consistent with the existing agent (orange) and user (blue) mobile apps, while maintaining a professional admin aesthetic with a dark sidebar and light content area.

**Let's build something amazing! 🚀**
