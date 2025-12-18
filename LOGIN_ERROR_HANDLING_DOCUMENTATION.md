# TCC Admin Panel - Login Error Handling Documentation

## Overview
This document describes the comprehensive error handling implementation for the TCC Admin Panel login system. The system provides specific, user-friendly error messages for various login failure scenarios to improve user experience and security monitoring.

## Error Scenarios and Messages

### 1. Invalid Credentials
- **Error Code**: `INVALID_CREDENTIALS`
- **HTTP Status**: 401 Unauthorized
- **User Message**: "Invalid email or password. Please check your credentials and try again."
- **Triggered When**:
  - Email doesn't exist in the system (for admin/super_admin roles)
  - Password is incorrect
- **Security Note**: Same message for non-existent email and wrong password to prevent email enumeration

### 2. Account Locked
- **Error Code**: `ACCOUNT_LOCKED`
- **HTTP Status**: 403 Forbidden
- **User Message**: "Account is temporarily locked due to too many failed login attempts. Please try again in X minutes. If you need immediate assistance, please contact support."
- **Triggered When**:
  - User has 5 or more failed login attempts
  - Lock duration: 30 minutes from the last failed attempt
- **Features**:
  - Dynamic remaining time display
  - Automatic unlock after timeout
  - Security logging for monitoring

### 3. Account Inactive
- **Error Code**: `ACCOUNT_INACTIVE`
- **HTTP Status**: 403 Forbidden
- **User Message**: "Your account has been deactivated. Please contact the system administrator to reactivate your account."
- **Triggered When**:
  - Admin account `is_active` flag is false
- **Resolution**: Requires manual reactivation by super admin

### 4. Invalid TOTP Code
- **Error Code**: `INVALID_TOTP_CODE`
- **HTTP Status**: 401 Unauthorized
- **User Message**: "Invalid 2FA verification code. Please check your authenticator app and ensure the time is synced correctly."
- **Triggered When**:
  - 2FA is enabled and TOTP code is incorrect
- **Time Window**: Allows 2 steps (60 seconds) before/after current time

### 5. TOTP Required
- **Error Code**: `TOTP_REQUIRED`
- **HTTP Status**: 401 Unauthorized
- **User Message**: "Two-factor authentication is required for this account. Please provide the verification code from your authenticator app."
- **Triggered When**:
  - 2FA is enabled but no TOTP code provided
  - Password verification successful

### 6. Network/Timeout Errors
- **Error Code**: `TIMEOUT` / `NETWORK_ERROR`
- **User Message**: "Connection timeout. Please check your internet connection."
- **Triggered When**:
  - Connection timeout (30 seconds)
  - Network connectivity issues

### 7. Unexpected Errors
- **Error Code**: `INTERNAL_ERROR`
- **HTTP Status**: 500 Internal Server Error
- **User Message**: "An unexpected error occurred during login. Please try again later or contact support if the problem persists."
- **Triggered When**:
  - Database connection issues
  - Unexpected server errors

## Implementation Details

### Frontend (Flutter Admin Panel)

#### AuthProvider (`lib/providers/auth_provider.dart`)
```dart
Future<bool> login({
  required String email,
  required String password,
  bool rememberMe = false,
}) async {
  try {
    final response = await _authService.login(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );

    if (response.success && response.data != null) {
      _admin = response.data;
      _isAuthenticated = true;
      _errorMessage = null;
      return true;
    } else {
      // Display specific error message from backend
      _errorMessage = response.error?.message ?? 'Login failed';
      return false;
    }
  } catch (e) {
    _errorMessage = 'An unexpected error occurred: ${e.toString()}';
    return false;
  }
}
```

#### Login Screen (`lib/screens/auth/login_screen.dart`)
- Displays error messages in a styled error container
- Shows with error icon and red color theme
- Auto-clears on new login attempt

### Backend (Node.js/Express)

#### Admin Controller (`src/controllers/admin.controller.ts`)
```typescript
static async login(req: AuthRequest, res: Response): Promise<Response> {
  try {
    const result = await AdminService.login(email, password, totp_code);
    // Success response...
  } catch (error: any) {
    // Specific error handling for each scenario
    if (error.message === 'INVALID_CREDENTIALS') {
      return ApiResponseUtil.unauthorized(res, 'Invalid email or password...');
    }
    // Additional error cases...
  }
}
```

#### Admin Service (`src/services/admin.service.ts`)
- Validates credentials
- Tracks failed attempts
- Implements account locking logic
- Verifies 2FA when enabled
- Logs security events

## Security Features

### 1. Failed Attempt Tracking
- Tracks failed login attempts per account
- Increments counter on each failure
- Resets on successful login

### 2. Account Locking
- Automatic lock after 5 failed attempts
- 30-minute lock duration
- Prevents brute force attacks

### 3. Security Logging
All login attempts are logged with:
- Timestamp
- Email/Admin ID
- Success/Failure status
- Failed attempt count
- Lock status

Example log entries:
```javascript
logger.warn('Failed admin login attempt', {
  email,
  adminId: admin.id,
  attemptNumber: attempts,
  isLocked: !!lockedUntil,
  lockedUntil: lockedUntil?.toISOString(),
});
```

### 4. Prevention of Email Enumeration
- Same error message for non-existent email and wrong password
- Prevents attackers from discovering valid email addresses

## API Response Format

### Success Response
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
    "expires_in": 3600,
    "admin": {
      "id": "uuid",
      "first_name": "John",
      "last_name": "Doe",
      "email": "admin@tcc.sl",
      "role": "ADMIN"
    }
  },
  "message": "Login successful"
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "message": "Specific error message here",
    "code": "ERROR_CODE"
  }
}
```

## Testing Guide

### Test Scenarios

1. **Valid Login**
   - Email: admin@tcc.sl
   - Password: Admin@123
   - Expected: Success

2. **Wrong Password**
   - Email: admin@tcc.sl
   - Password: wrong_password
   - Expected: "Invalid email or password..."

3. **Account Locking**
   - Attempt login 5 times with wrong password
   - Expected: "Account is temporarily locked..."

4. **Inactive Account**
   - Set `is_active = false` in database
   - Expected: "Your account has been deactivated..."

5. **2FA Verification**
   - Enable 2FA for account
   - Login with correct credentials
   - Expected: Prompt for TOTP code

## Troubleshooting

### Common Issues

1. **User sees generic "Login failed" message**
   - Check if backend is returning specific error messages
   - Verify ApiService is properly extracting error messages
   - Ensure AuthService passes error.message to response

2. **Account remains locked**
   - Check `locked_until` timestamp in database
   - Verify server time is correct
   - Manually clear lock: `UPDATE users SET locked_until = NULL, failed_login_attempts = 0 WHERE email = 'user@email.com'`

3. **2FA codes not working**
   - Verify device time is synced
   - Check authenticator app settings
   - Regenerate 2FA secret if necessary

## Database Schema

### Relevant User Table Columns
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  failed_login_attempts INT DEFAULT 0,
  locked_until TIMESTAMP,
  two_factor_enabled BOOLEAN DEFAULT false,
  two_factor_secret VARCHAR(255),
  last_login_at TIMESTAMP,
  -- other columns...
);
```

## Future Enhancements

1. **Email Notifications**
   - Notify users of failed login attempts
   - Alert on account lock/unlock

2. **IP-based Restrictions**
   - Track login attempts by IP
   - Implement IP whitelisting for admin accounts

3. **Session Management**
   - Multiple device tracking
   - Force logout from other devices

4. **Password Policy**
   - Enforce strong password requirements
   - Password expiration
   - Password history

5. **Audit Trail**
   - Comprehensive login history
   - Export login reports
   - Compliance reporting

## Support Contact

For assistance with login issues:
- Email: support@tcc.com
- Phone: 1-800-TCC-HELP
- Admin Portal: Contact super admin for account issues

---

*Last Updated: December 2024*
*Version: 1.0.0*