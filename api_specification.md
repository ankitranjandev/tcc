# TCC Application - API Specification

## Base Configuration

**Base URL:** `https://api.tccapp.com/v1`

**API Version:** v1

**Protocol:** HTTPS only (TLS 1.3)

**Content-Type:** `application/json`

**Authentication:** JWT Bearer Token (except public endpoints)

---

## Common Headers

### Request Headers
```
Authorization: Bearer {jwt_token}
Content-Type: application/json
Accept: application/json
X-Device-ID: {unique_device_identifier}
X-App-Version: {app_version}
X-Platform: {iOS|Android|Web}
```

### Response Headers
```
Content-Type: application/json
X-Request-ID: {unique_request_id}
X-RateLimit-Limit: {max_requests}
X-RateLimit-Remaining: {remaining_requests}
X-RateLimit-Reset: {reset_timestamp}
```

---

## Authentication & Rate Limiting

### JWT Token Format
```json
{
  "sub": "user_uuid",
  "role": "USER|AGENT|ADMIN|SUPER_ADMIN",
  "email": "user@example.com",
  "iat": 1234567890,
  "exp": 1234571490
}
```

### Rate Limits
- **Authentication endpoints:** 5 requests/minute
- **Standard endpoints:** 100 requests/minute
- **Admin endpoints:** 200 requests/minute
- **Public endpoints:** 20 requests/minute

---

## Error Response Format

All error responses follow this structure:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {},
    "timestamp": "2025-10-26T10:30:00Z",
    "request_id": "req_abc123"
  }
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `UNAUTHORIZED` | 401 | Invalid or missing authentication token |
| `FORBIDDEN` | 403 | User lacks permission for this action |
| `NOT_FOUND` | 404 | Requested resource not found |
| `VALIDATION_ERROR` | 422 | Request validation failed |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Internal server error |
| `INSUFFICIENT_BALANCE` | 400 | Wallet balance insufficient |
| `KYC_NOT_APPROVED` | 403 | KYC verification required |
| `ACCOUNT_LOCKED` | 403 | Account temporarily locked |
| `INVALID_OTP` | 400 | OTP verification failed |

---

## 1. Authentication Endpoints

### 1.1 Register User

**Endpoint:** `POST /auth/register`

**Authentication:** None (Public)

**Rate Limit:** 5/minute

**Request:**
```json
{
  "first_name": "John",
  "last_name": "Doe",
  "email": "john.doe@example.com",
  "phone": "1234567890",
  "country_code": "+232",
  "password": "SecurePass123!",
  "role": "USER",
  "referral_code": "REF123456"
}
```

**Validation Rules:**
- `first_name`: Required, 2-100 chars, letters only
- `last_name`: Required, 2-100 chars, letters only
- `email`: Required, valid email format
- `phone`: Required, 6-15 digits
- `password`: Required, min 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special char
- `role`: Optional, defaults to "USER"
- `referral_code`: Optional, 6-10 chars

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid-v4",
      "first_name": "John",
      "last_name": "Doe",
      "email": "john.doe@example.com",
      "phone": "1234567890",
      "country_code": "+232",
      "role": "USER",
      "kyc_status": "PENDING",
      "is_active": false,
      "created_at": "2025-10-26T10:30:00Z"
    },
    "otp_sent": true,
    "otp_expires_in": 300
  },
  "message": "Registration successful. Please verify your phone number."
}
```

**Error Responses:**
- `EMAIL_ALREADY_EXISTS` (409): Email already registered
- `PHONE_ALREADY_EXISTS` (409): Phone number already registered
- `INVALID_REFERRAL_CODE` (400): Referral code not found

---

### 1.2 Verify OTP

**Endpoint:** `POST /auth/verify-otp`

**Authentication:** None (Public)

**Request:**
```json
{
  "phone": "1234567890",
  "country_code": "+232",
  "otp": "123456",
  "purpose": "REGISTRATION|LOGIN|PHONE_CHANGE|PASSWORD_RESET"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "refresh_token_string",
    "token_type": "Bearer",
    "expires_in": 3600,
    "user": {
      "id": "uuid-v4",
      "first_name": "John",
      "last_name": "Doe",
      "email": "john.doe@example.com",
      "role": "USER",
      "kyc_status": "PENDING",
      "is_active": true
    }
  },
  "message": "OTP verified successfully"
}
```

**Error Responses:**
- `INVALID_OTP` (400): OTP is incorrect
- `OTP_EXPIRED` (400): OTP has expired (5 min)
- `OTP_ATTEMPTS_EXCEEDED` (429): Too many failed attempts

---

### 1.3 Login

**Endpoint:** `POST /auth/login`

**Authentication:** None (Public)

**Request:**
```json
{
  "email": "john.doe@example.com",
  "password": "SecurePass123!"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "otp_sent": true,
    "otp_expires_in": 300,
    "phone": "****7890",
    "message": "OTP sent to your registered phone number"
  }
}
```

**Error Responses:**
- `INVALID_CREDENTIALS` (401): Email or password incorrect
- `ACCOUNT_LOCKED` (403): Account locked due to failed attempts
- `ACCOUNT_DELETED` (403): Account scheduled for deletion

---

### 1.4 Resend OTP

**Endpoint:** `POST /auth/resend-otp`

**Authentication:** None (Public)

**Request:**
```json
{
  "phone": "1234567890",
  "country_code": "+232"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "otp_sent": true,
    "otp_expires_in": 300,
    "retry_after": 60
  },
  "message": "OTP resent successfully"
}
```

---

### 1.5 Forgot Password

**Endpoint:** `POST /auth/forgot-password`

**Authentication:** None (Public)

**Request:**
```json
{
  "email": "john.doe@example.com"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "otp_sent": true,
    "phone": "****7890"
  },
  "message": "OTP sent to your registered phone number"
}
```

---

### 1.6 Reset Password

**Endpoint:** `POST /auth/reset-password`

**Authentication:** None (Public)

**Request:**
```json
{
  "phone": "1234567890",
  "country_code": "+232",
  "otp": "123456",
  "new_password": "NewSecurePass123!"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Password reset successfully"
}
```

---

### 1.7 Refresh Token

**Endpoint:** `POST /auth/refresh`

**Authentication:** Refresh Token

**Request:**
```json
{
  "refresh_token": "refresh_token_string"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "access_token": "new_access_token",
    "refresh_token": "new_refresh_token",
    "expires_in": 3600
  }
}
```

---

### 1.8 Logout

**Endpoint:** `POST /auth/logout`

**Authentication:** Required

**Request:**
```json
{
  "refresh_token": "refresh_token_string"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

## 2. User Management Endpoints

### 2.1 Get User Profile

**Endpoint:** `GET /users/profile`

**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid-v4",
      "first_name": "John",
      "last_name": "Doe",
      "email": "john.doe@example.com",
      "phone": "1234567890",
      "country_code": "+232",
      "role": "USER",
      "kyc_status": "APPROVED",
      "profile_picture_url": "https://s3.amazonaws.com/...",
      "is_active": true,
      "email_verified": true,
      "phone_verified": true,
      "two_factor_enabled": false,
      "created_at": "2025-10-26T10:30:00Z",
      "updated_at": "2025-10-26T10:30:00Z"
    },
    "wallet": {
      "balance": 15000.50,
      "currency": "SLL",
      "tcc_coins": 15000.50
    }
  }
}
```

---

### 2.2 Update User Profile

**Endpoint:** `PATCH /users/profile`

**Authentication:** Required

**Request:**
```json
{
  "first_name": "John",
  "last_name": "Doe",
  "email": "newemail@example.com",
  "profile_picture": "base64_encoded_image"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid-v4",
      "first_name": "John",
      "last_name": "Doe",
      "email": "newemail@example.com",
      "profile_picture_url": "https://s3.amazonaws.com/...",
      "updated_at": "2025-10-26T11:00:00Z"
    }
  },
  "message": "Profile updated successfully"
}
```

---

### 2.3 Change Phone Number

**Endpoint:** `POST /users/change-phone`

**Authentication:** Required

**Request:**
```json
{
  "new_phone": "9876543210",
  "country_code": "+232",
  "password": "CurrentPassword123!"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "otp_sent": true,
    "new_phone": "****3210",
    "verification_required": true
  },
  "message": "OTP sent to new phone number for verification"
}
```

---

### 2.4 Change Password

**Endpoint:** `POST /users/change-password`

**Authentication:** Required

**Request:**
```json
{
  "current_password": "OldPassword123!",
  "new_password": "NewPassword123!",
  "confirm_password": "NewPassword123!"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

---

### 2.5 Request Account Deletion

**Endpoint:** `POST /users/delete-account`

**Authentication:** Required

**Request:**
```json
{
  "password": "CurrentPassword123!",
  "reason": "No longer need the service"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "deletion_scheduled_for": "2025-11-25T10:30:00Z",
    "grace_period_days": 30,
    "can_cancel_until": "2025-11-25T10:30:00Z"
  },
  "message": "Account deletion scheduled. You have 30 days to cancel."
}
```

---

### 2.6 Cancel Account Deletion

**Endpoint:** `POST /users/cancel-deletion`

**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "message": "Account deletion cancelled successfully"
}
```

---

## 3. KYC Endpoints

### 3.1 Submit KYC Documents

**Endpoint:** `POST /kyc/submit`

**Authentication:** Required

**Request (multipart/form-data):**
```
document_type: ID_CARD|PASSPORT|DRIVERS_LICENSE
document_number: ABC123456
front_image: [file]
back_image: [file]
selfie_image: [file]
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "kyc_submission": {
      "id": "uuid-v4",
      "document_type": "ID_CARD",
      "status": "SUBMITTED",
      "submitted_at": "2025-10-26T10:30:00Z",
      "estimated_review_time": "24-48 hours"
    }
  },
  "message": "KYC documents submitted successfully"
}
```

**Error Responses:**
- `KYC_ALREADY_APPROVED` (400): KYC already approved
- `INVALID_FILE_FORMAT` (400): File format not supported
- `FILE_TOO_LARGE` (400): File size exceeds 5MB

---

### 3.2 Get KYC Status

**Endpoint:** `GET /kyc/status`

**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "kyc_status": "APPROVED",
    "document_type": "ID_CARD",
    "submitted_at": "2025-10-26T10:30:00Z",
    "reviewed_at": "2025-10-27T14:20:00Z",
    "reviewer_notes": "",
    "can_resubmit": false
  }
}
```

---

### 3.3 Resubmit KYC (After Rejection)

**Endpoint:** `POST /kyc/resubmit`

**Authentication:** Required

**Request (multipart/form-data):**
```
document_type: ID_CARD|PASSPORT|DRIVERS_LICENSE
document_number: ABC123456
front_image: [file]
back_image: [file]
selfie_image: [file]
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "kyc_submission": {
      "id": "uuid-v4",
      "status": "SUBMITTED",
      "attempt_number": 2
    }
  },
  "message": "KYC documents resubmitted successfully"
}
```

---

## 4. Wallet & Transaction Endpoints

### 4.1 Get Wallet Balance

**Endpoint:** `GET /wallet/balance`

**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "wallet": {
      "id": "uuid-v4",
      "balance": 15000.50,
      "currency": "SLL",
      "tcc_coins": 15000.50,
      "last_transaction": "2025-10-26T10:30:00Z"
    }
  }
}
```

---

### 4.2 Add Money (Deposit)

**Endpoint:** `POST /transactions/deposit`

**Authentication:** Required

**Request:**
```json
{
  "amount": 5000.00,
  "payment_method": "BANK_TRANSFER|MOBILE_MONEY|AIRTEL_MONEY|AGENT",
  "payment_details": {
    "bank_account_id": "uuid-v4",
    "transaction_reference": "BANK_TXN_123456"
  },
  "agent_id": "uuid-v4"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "transaction": {
      "id": "uuid-v4",
      "transaction_id": "TXN20251026123456",
      "type": "DEPOSIT",
      "amount": 5000.00,
      "fee": 0.00,
      "status": "PENDING",
      "payment_method": "BANK_TRANSFER",
      "created_at": "2025-10-26T10:30:00Z",
      "estimated_completion": "2025-10-26T12:30:00Z"
    }
  },
  "message": "Deposit request created. Awaiting confirmation."
}
```

**Error Responses:**
- `KYC_NOT_APPROVED` (403): Complete KYC to deposit
- `AGENT_NOT_FOUND` (404): Agent not found or inactive
- `AGENT_INSUFFICIENT_BALANCE` (400): Agent has insufficient credits

---

### 4.3 Withdraw Money

**Endpoint:** `POST /transactions/withdraw`

**Authentication:** Required

**Request:**
```json
{
  "amount": 3000.00,
  "bank_account_id": "uuid-v4",
  "otp": "123456"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "transaction": {
      "id": "uuid-v4",
      "transaction_id": "TXN20251026234567",
      "type": "WITHDRAWAL",
      "amount": 3000.00,
      "fee": 50.00,
      "net_amount": 2950.00,
      "status": "PENDING",
      "bank_account": {
        "account_number": "****5678",
        "bank_name": "Example Bank"
      },
      "created_at": "2025-10-26T10:30:00Z",
      "estimated_completion": "1-2 business days"
    }
  },
  "message": "Withdrawal request submitted for admin approval"
}
```

**Error Responses:**
- `INSUFFICIENT_BALANCE` (400): Wallet balance insufficient
- `WITHDRAWAL_LIMIT_EXCEEDED` (400): Daily/monthly limit exceeded
- `BANK_ACCOUNT_NOT_VERIFIED` (403): Bank account needs verification

---

### 4.4 Transfer Money (User to User)

**Endpoint:** `POST /transactions/transfer`

**Authentication:** Required

**Request:**
```json
{
  "recipient_phone": "9876543210",
  "recipient_country_code": "+232",
  "amount": 1000.00,
  "note": "Payment for dinner",
  "otp": "123456"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "transaction": {
      "id": "uuid-v4",
      "transaction_id": "TXN20251026345678",
      "type": "TRANSFER",
      "amount": 1000.00,
      "fee": 10.00,
      "status": "COMPLETED",
      "recipient": {
        "name": "Jane Smith",
        "phone": "****3210"
      },
      "note": "Payment for dinner",
      "created_at": "2025-10-26T10:30:00Z"
    },
    "new_balance": 14040.50
  },
  "message": "Transfer completed successfully"
}
```

**Error Responses:**
- `RECIPIENT_NOT_FOUND` (404): Recipient not registered
- `RECIPIENT_KYC_PENDING` (400): Recipient KYC not approved
- `TRANSFER_LIMIT_EXCEEDED` (400): Daily transfer limit exceeded
- `SELF_TRANSFER_NOT_ALLOWED` (400): Cannot transfer to own account

---

### 4.5 Get Transaction History

**Endpoint:** `GET /transactions/history`

**Authentication:** Required

**Query Parameters:**
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20, max: 100)
- `type`: Filter by transaction type (optional)
- `status`: Filter by status (optional)
- `from_date`: Start date (ISO 8601)
- `to_date`: End date (ISO 8601)
- `search`: Search by transaction ID or amount

**Request:**
```
GET /transactions/history?page=1&limit=20&type=DEPOSIT&from_date=2025-10-01
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "transactions": [
      {
        "id": "uuid-v4",
        "transaction_id": "TXN20251026123456",
        "type": "DEPOSIT",
        "amount": 5000.00,
        "fee": 0.00,
        "status": "COMPLETED",
        "description": "Bank Transfer",
        "created_at": "2025-10-26T10:30:00Z",
        "completed_at": "2025-10-26T12:30:00Z"
      }
    ],
    "pagination": {
      "total": 45,
      "page": 1,
      "limit": 20,
      "total_pages": 3
    }
  }
}
```

---

### 4.6 Get Transaction Details

**Endpoint:** `GET /transactions/:transaction_id`

**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "transaction": {
      "id": "uuid-v4",
      "transaction_id": "TXN20251026123456",
      "type": "DEPOSIT",
      "amount": 5000.00,
      "fee": 0.00,
      "status": "COMPLETED",
      "payment_method": "BANK_TRANSFER",
      "payment_details": {
        "bank_name": "Example Bank",
        "reference": "BANK_TXN_123456"
      },
      "created_at": "2025-10-26T10:30:00Z",
      "completed_at": "2025-10-26T12:30:00Z",
      "receipt_url": "https://s3.amazonaws.com/receipts/..."
    }
  }
}
```

---

### 4.7 Add Bank Account

**Endpoint:** `POST /users/bank-accounts`

**Authentication:** Required

**Request:**
```json
{
  "account_number": "1234567890",
  "account_holder_name": "John Doe",
  "bank_name": "Example Bank Sierra Leone",
  "bank_code": "EXSL",
  "branch_name": "Freetown Main Branch",
  "is_primary": true
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "bank_account": {
      "id": "uuid-v4",
      "account_number": "****7890",
      "account_holder_name": "John Doe",
      "bank_name": "Example Bank Sierra Leone",
      "is_verified": false,
      "is_primary": true,
      "created_at": "2025-10-26T10:30:00Z"
    }
  },
  "message": "Bank account added successfully"
}
```

---

### 4.8 Get Bank Accounts

**Endpoint:** `GET /users/bank-accounts`

**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "bank_accounts": [
      {
        "id": "uuid-v4",
        "account_number": "****7890",
        "account_holder_name": "John Doe",
        "bank_name": "Example Bank Sierra Leone",
        "is_verified": true,
        "is_primary": true,
        "created_at": "2025-10-26T10:30:00Z"
      }
    ]
  }
}
```

---

## 5. Investment Endpoints

### 5.1 Get Investment Categories

**Endpoint:** `GET /investments/categories`

**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "categories": [
      {
        "id": "uuid-v4",
        "name": "AGRICULTURE",
        "display_name": "Agriculture",
        "description": "Invest in sustainable agricultural projects",
        "icon_url": "https://s3.amazonaws.com/...",
        "min_amount": 1000.00,
        "max_amount": 1000000.00,
        "available_tenures": [
          {
            "id": "uuid-v4",
            "months": 6,
            "return_rate": 5.00,
            "insurance_available": true,
            "insurance_rate": 1.00
          },
          {
            "id": "uuid-v4",
            "months": 12,
            "return_rate": 10.00,
            "insurance_available": true,
            "insurance_rate": 1.50
          }
        ]
      }
    ]
  }
}
```

---

### 5.2 Create Investment

**Endpoint:** `POST /investments/create`

**Authentication:** Required

**Request:**
```json
{
  "category": "AGRICULTURE",
  "tenure_id": "uuid-v4",
  "amount": 10000.00,
  "take_insurance": true,
  "otp": "123456"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "investment": {
      "id": "uuid-v4",
      "category": "AGRICULTURE",
      "amount": 10000.00,
      "tenure_months": 12,
      "return_rate": 10.00,
      "expected_return": 11000.00,
      "insurance_taken": true,
      "insurance_amount": 150.00,
      "status": "ACTIVE",
      "start_date": "2025-10-26",
      "maturity_date": "2026-10-26",
      "created_at": "2025-10-26T10:30:00Z"
    },
    "transaction": {
      "transaction_id": "TXN20251026456789",
      "amount": 10150.00
    },
    "new_wallet_balance": 4850.50
  },
  "message": "Investment created successfully"
}
```

**Error Responses:**
- `INSUFFICIENT_BALANCE` (400): Wallet balance insufficient
- `BELOW_MINIMUM_AMOUNT` (400): Amount below minimum for category
- `ABOVE_MAXIMUM_AMOUNT` (400): Amount exceeds maximum for category

---

### 5.3 Get User Portfolio

**Endpoint:** `GET /investments/portfolio`

**Authentication:** Required

**Query Parameters:**
- `status`: Filter by status (ACTIVE, MATURED, WITHDRAWN, CANCELLED)

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "summary": {
      "total_invested": 50000.00,
      "total_expected_return": 55000.00,
      "total_profit": 5000.00,
      "active_investments": 3,
      "matured_investments": 2
    },
    "investments": [
      {
        "id": "uuid-v4",
        "category": "AGRICULTURE",
        "amount": 10000.00,
        "return_rate": 10.00,
        "expected_return": 11000.00,
        "tenure_months": 12,
        "status": "ACTIVE",
        "start_date": "2025-10-26",
        "maturity_date": "2026-10-26",
        "days_remaining": 365,
        "insurance_taken": true
      }
    ]
  }
}
```

---

### 5.4 Request Tenure Change

**Endpoint:** `POST /investments/:investment_id/change-tenure`

**Authentication:** Required

**Request:**
```json
{
  "new_tenure_id": "uuid-v4",
  "reason": "Financial planning adjustment"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "change_request": {
      "id": "uuid-v4",
      "investment_id": "uuid-v4",
      "current_tenure_months": 12,
      "requested_tenure_months": 6,
      "status": "PENDING",
      "submitted_at": "2025-10-26T10:30:00Z"
    }
  },
  "message": "Tenure change request submitted for admin approval"
}
```

---

### 5.5 Withdraw Investment (Early)

**Endpoint:** `POST /investments/:investment_id/withdraw`

**Authentication:** Required

**Request:**
```json
{
  "reason": "Emergency funds needed",
  "otp": "123456"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "investment": {
      "id": "uuid-v4",
      "status": "WITHDRAWN",
      "withdrawn_amount": 9500.00,
      "penalty": 500.00,
      "original_amount": 10000.00
    },
    "transaction": {
      "transaction_id": "TXN20251026567890",
      "amount": 9500.00
    },
    "new_wallet_balance": 14350.50
  },
  "message": "Investment withdrawn. Amount credited to wallet."
}
```

---

### 5.6 Get Investment Details

**Endpoint:** `GET /investments/:investment_id`

**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "investment": {
      "id": "uuid-v4",
      "category": "AGRICULTURE",
      "amount": 10000.00,
      "tenure_months": 12,
      "return_rate": 10.00,
      "expected_return": 11000.00,
      "insurance_taken": true,
      "insurance_amount": 150.00,
      "status": "ACTIVE",
      "start_date": "2025-10-26",
      "maturity_date": "2026-10-26",
      "days_remaining": 365,
      "created_at": "2025-10-26T10:30:00Z",
      "certificate_url": "https://s3.amazonaws.com/certificates/..."
    }
  }
}
```

---

## 6. Bill Payment Endpoints

### 6.1 Get Bill Providers

**Endpoint:** `GET /bills/providers`

**Authentication:** Required

**Query Parameters:**
- `category`: Filter by category (ELECTRICITY, WATER, INTERNET, MOBILE)

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "providers": [
      {
        "id": "uuid-v4",
        "name": "Electricity Distribution Company",
        "category": "ELECTRICITY",
        "logo_url": "https://s3.amazonaws.com/...",
        "is_active": true,
        "supports_fetch_bill": true,
        "fields_required": [
          {
            "name": "meter_number",
            "label": "Meter Number",
            "type": "text",
            "validation": "^[0-9]{10}$"
          },
          {
            "name": "amount",
            "label": "Amount",
            "type": "number",
            "min": 100,
            "max": 100000
          }
        ]
      }
    ]
  }
}
```

---

### 6.2 Fetch Bill Details

**Endpoint:** `POST /bills/fetch`

**Authentication:** Required

**Request:**
```json
{
  "provider_id": "uuid-v4",
  "bill_parameters": {
    "meter_number": "1234567890"
  }
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "bill": {
      "customer_name": "John Doe",
      "meter_number": "1234567890",
      "due_amount": 2500.00,
      "due_date": "2025-11-05",
      "billing_period": "October 2025",
      "provider": "Electricity Distribution Company"
    }
  }
}
```

---

### 6.3 Pay Bill

**Endpoint:** `POST /bills/pay`

**Authentication:** Required

**Request:**
```json
{
  "provider_id": "uuid-v4",
  "bill_parameters": {
    "meter_number": "1234567890"
  },
  "amount": 2500.00,
  "otp": "123456"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "payment": {
      "id": "uuid-v4",
      "transaction_id": "TXN20251026678901",
      "provider": "Electricity Distribution Company",
      "amount": 2500.00,
      "fee": 25.00,
      "total_amount": 2525.00,
      "status": "COMPLETED",
      "receipt_number": "ELEC123456789",
      "paid_at": "2025-10-26T10:30:00Z"
    },
    "new_wallet_balance": 11825.50
  },
  "message": "Bill payment successful"
}
```

**Error Responses:**
- `BILL_ALREADY_PAID` (400): Bill already paid
- `INVALID_BILL_PARAMETERS` (400): Invalid meter/account number

---

### 6.4 Get Bill Payment History

**Endpoint:** `GET /bills/history`

**Authentication:** Required

**Query Parameters:**
- `page`, `limit`, `from_date`, `to_date`
- `provider_id`: Filter by provider

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "payments": [
      {
        "id": "uuid-v4",
        "transaction_id": "TXN20251026678901",
        "provider": {
          "name": "Electricity Distribution Company",
          "logo_url": "https://s3.amazonaws.com/..."
        },
        "amount": 2500.00,
        "fee": 25.00,
        "receipt_number": "ELEC123456789",
        "paid_at": "2025-10-26T10:30:00Z"
      }
    ],
    "pagination": {
      "total": 15,
      "page": 1,
      "limit": 20,
      "total_pages": 1
    }
  }
}
```

---

## 7. E-Voting Endpoints

### 7.1 Get Active Polls

**Endpoint:** `GET /polls/active`

**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "polls": [
      {
        "id": "uuid-v4",
        "title": "Community Development Priority",
        "question": "Which project should be prioritized?",
        "options": [
          "Build new school",
          "Improve healthcare",
          "Road infrastructure",
          "Water supply"
        ],
        "voting_charge": 100.00,
        "status": "ACTIVE",
        "start_date": "2025-10-26T00:00:00Z",
        "end_date": "2025-11-02T23:59:59Z",
        "total_votes": 1250,
        "has_user_voted": false
      }
    ]
  }
}
```

---

### 7.2 Get Poll Details

**Endpoint:** `GET /polls/:poll_id`

**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "poll": {
      "id": "uuid-v4",
      "title": "Community Development Priority",
      "question": "Which project should be prioritized?",
      "description": "Help us decide the next community development project.",
      "options": [
        "Build new school",
        "Improve healthcare",
        "Road infrastructure",
        "Water supply"
      ],
      "voting_charge": 100.00,
      "status": "ACTIVE",
      "start_date": "2025-10-26T00:00:00Z",
      "end_date": "2025-11-02T23:59:59Z",
      "total_votes": 1250,
      "has_user_voted": true,
      "user_vote": "Build new school",
      "can_view_results": true,
      "results": [
        {
          "option": "Build new school",
          "votes": 450,
          "percentage": 36.0
        },
        {
          "option": "Improve healthcare",
          "votes": 400,
          "percentage": 32.0
        },
        {
          "option": "Road infrastructure",
          "votes": 250,
          "percentage": 20.0
        },
        {
          "option": "Water supply",
          "votes": 150,
          "percentage": 12.0
        }
      ]
    }
  }
}
```

---

### 7.3 Vote on Poll

**Endpoint:** `POST /polls/:poll_id/vote`

**Authentication:** Required

**Request:**
```json
{
  "selected_option": "Build new school",
  "otp": "123456"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "vote": {
      "id": "uuid-v4",
      "poll_id": "uuid-v4",
      "selected_option": "Build new school",
      "amount_paid": 100.00,
      "voted_at": "2025-10-26T10:30:00Z"
    },
    "transaction": {
      "transaction_id": "TXN20251026789012"
    },
    "new_wallet_balance": 11725.50
  },
  "message": "Vote recorded successfully"
}
```

**Error Responses:**
- `ALREADY_VOTED` (400): User already voted on this poll
- `POLL_ENDED` (400): Poll voting period has ended
- `INVALID_OPTION` (400): Selected option not available

---

### 7.4 Get User Voting History

**Endpoint:** `GET /polls/my-votes`

**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "votes": [
      {
        "id": "uuid-v4",
        "poll": {
          "id": "uuid-v4",
          "title": "Community Development Priority",
          "question": "Which project should be prioritized?"
        },
        "selected_option": "Build new school",
        "amount_paid": 100.00,
        "voted_at": "2025-10-26T10:30:00Z"
      }
    ]
  }
}
```

---

### 7.5 Get Poll Revenue Analytics (Admin)

**Endpoint:** `GET /admin/polls/:poll_id/revenue`

**Authentication:** Required (ADMIN/SUPER_ADMIN)

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "poll": {
      "id": "uuid-v4",
      "title": "Community Development Priority",
      "status": "CLOSED"
    },
    "revenue": {
      "total_revenue": 12500.00,
      "total_votes": 125,
      "voting_charge": 100.00,
      "revenue_by_option": [
        {
          "option": "Build new school",
          "votes": 45,
          "revenue": 4500.00,
          "percentage": 36.0
        },
        {
          "option": "Improve healthcare",
          "votes": 40,
          "revenue": 4000.00,
          "percentage": 32.0
        },
        {
          "option": "Road infrastructure",
          "votes": 25,
          "revenue": 2500.00,
          "percentage": 20.0
        },
        {
          "option": "Water supply",
          "votes": 15,
          "revenue": 1500.00,
          "percentage": 12.0
        }
      ],
      "demographics": {
        "male_votes": 70,
        "female_votes": 55
      }
    }
  }
}
```

---

## 8. Agent Endpoints

### 8.1 Register as Agent

**Endpoint:** `POST /agents/register`

**Authentication:** Required (USER role)

**Request:**
```json
{
  "business_name": "John's Money Services",
  "business_address": "123 Main Street, Freetown",
  "location_lat": 8.4657,
  "location_lng": -13.2317,
  "government_id_type": "NATIONAL_ID",
  "government_id_number": "NID123456789",
  "business_license": "base64_encoded_file"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "agent_application": {
      "id": "uuid-v4",
      "status": "PENDING",
      "submitted_at": "2025-10-26T10:30:00Z",
      "estimated_review": "3-5 business days"
    }
  },
  "message": "Agent application submitted successfully"
}
```

---

### 8.2 Get Agent Profile

**Endpoint:** `GET /agents/profile`

**Authentication:** Required (AGENT role)

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "agent": {
      "id": "uuid-v4",
      "user_id": "uuid-v4",
      "business_name": "John's Money Services",
      "business_address": "123 Main Street, Freetown",
      "location": {
        "lat": 8.4657,
        "lng": -13.2317
      },
      "wallet_balance": 50000.00,
      "active_status": true,
      "commission_rate": 0.50,
      "total_transactions": 145,
      "total_volume": 725000.00,
      "rating": 4.8,
      "approved_at": "2025-10-15T14:00:00Z"
    }
  }
}
```

---

### 8.3 Request Agent Wallet Credit

**Endpoint:** `POST /agents/credit-request`

**Authentication:** Required (AGENT role)

**Request:**
```json
{
  "amount": 100000.00,
  "bank_transaction_reference": "BANK_REF_123456",
  "payment_proof": "base64_encoded_image"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "credit_request": {
      "id": "uuid-v4",
      "amount": 100000.00,
      "status": "PENDING",
      "submitted_at": "2025-10-26T10:30:00Z",
      "estimated_approval": "1-2 hours during business hours"
    }
  },
  "message": "Credit request submitted. Admin will verify bank deposit."
}
```

---

### 8.4 Get Agent Credit Requests

**Endpoint:** `GET /agents/credit-requests`

**Authentication:** Required (AGENT role)

**Query Parameters:**
- `status`: Filter by status (PENDING, APPROVED, REJECTED)

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "credit_requests": [
      {
        "id": "uuid-v4",
        "amount": 100000.00,
        "status": "APPROVED",
        "bank_reference": "BANK_REF_123456",
        "submitted_at": "2025-10-26T10:30:00Z",
        "processed_at": "2025-10-26T11:45:00Z",
        "processed_by": "Admin User"
      }
    ]
  }
}
```

---

### 8.5 Agent Deposit for User

**Endpoint:** `POST /agents/deposit-for-user`

**Authentication:** Required (AGENT role)

**Request:**
```json
{
  "user_phone": "1234567890",
  "user_country_code": "+232",
  "amount": 5000.00,
  "cash_received": 5000.00
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "transaction": {
      "transaction_id": "TXN20251026890123",
      "user": {
        "name": "Jane Smith",
        "phone": "****7890"
      },
      "amount": 5000.00,
      "commission_earned": 25.00,
      "status": "COMPLETED",
      "completed_at": "2025-10-26T10:30:00Z"
    },
    "new_agent_balance": 45025.00
  },
  "message": "Deposit completed successfully"
}
```

**Error Responses:**
- `AGENT_WALLET_INSUFFICIENT` (400): Agent wallet balance too low
- `USER_NOT_FOUND` (404): User not registered
- `USER_KYC_PENDING` (403): User KYC not approved

---

### 8.6 Agent Withdrawal for User

**Endpoint:** `POST /agents/withdraw-for-user`

**Authentication:** Required (AGENT role)

**Request:**
```json
{
  "user_phone": "1234567890",
  "user_country_code": "+232",
  "amount": 3000.00,
  "user_otp": "123456"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "transaction": {
      "transaction_id": "TXN20251026901234",
      "user": {
        "name": "Jane Smith",
        "phone": "****7890"
      },
      "amount": 3000.00,
      "commission_earned": 15.00,
      "status": "COMPLETED",
      "completed_at": "2025-10-26T10:30:00Z"
    },
    "new_agent_balance": 48040.00
  },
  "message": "Withdrawal completed successfully"
}
```

---

### 8.7 Locate Nearby Agents

**Endpoint:** `GET /agents/nearby`

**Authentication:** Required

**Query Parameters:**
- `lat`: User latitude
- `lng`: User longitude
- `radius`: Search radius in km (default: 5, max: 50)
- `limit`: Max results (default: 10)

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "agents": [
      {
        "id": "uuid-v4",
        "business_name": "John's Money Services",
        "business_address": "123 Main Street, Freetown",
        "location": {
          "lat": 8.4657,
          "lng": -13.2317
        },
        "distance_km": 0.8,
        "rating": 4.8,
        "total_transactions": 145,
        "active_status": true,
        "contact_phone": "****5678"
      }
    ]
  }
}
```

---

### 8.8 Get Agent Dashboard Stats

**Endpoint:** `GET /agents/dashboard`

**Authentication:** Required (AGENT role)

**Query Parameters:**
- `period`: DAY, WEEK, MONTH, YEAR (default: MONTH)

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "stats": {
      "period": "MONTH",
      "total_transactions": 45,
      "total_volume": 225000.00,
      "total_commission": 1125.00,
      "deposits": {
        "count": 30,
        "volume": 150000.00
      },
      "withdrawals": {
        "count": 15,
        "volume": 75000.00
      },
      "current_wallet_balance": 50000.00,
      "rating": 4.8
    }
  }
}
```

---

### 8.9 Update Agent Location

**Endpoint:** `PATCH /agents/location`

**Authentication:** Required (AGENT role)

**Request:**
```json
{
  "latitude": 8.4657,
  "longitude": -13.2317,
  "address": "123 Main Street, Freetown"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "location": {
      "lat": 8.4657,
      "lng": -13.2317,
      "address": "123 Main Street, Freetown",
      "updated_at": "2025-10-26T10:30:00Z"
    }
  },
  "message": "Location updated successfully"
}
```

---

### 8.10 Submit Agent Review

**Endpoint:** `POST /agents/:agent_id/review`

**Authentication:** Required

**Request:**
```json
{
  "rating": 5,
  "comment": "Excellent service! Very professional and quick.",
  "transaction_id": "uuid-v4"
}
```

**Validation Rules:**
- `rating`: Required, integer 1-5
- `comment`: Optional, max 500 chars
- `transaction_id`: Required, must be a completed transaction with this agent

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "review": {
      "id": "uuid-v4",
      "agent_id": "uuid-v4",
      "rating": 5,
      "comment": "Excellent service! Very professional and quick.",
      "created_at": "2025-10-26T10:30:00Z"
    },
    "agent_new_rating": 4.8
  },
  "message": "Review submitted successfully"
}
```

**Error Responses:**
- `ALREADY_REVIEWED` (400): Transaction already reviewed
- `INVALID_TRANSACTION` (400): Transaction not found or not with this agent
- `TRANSACTION_NOT_COMPLETED` (400): Can only review completed transactions

---

## 9. Admin Endpoints

### 9.1 Admin Login (2FA)

**Endpoint:** `POST /admin/login`

**Authentication:** None (Public)

**Request:**
```json
{
  "email": "admin@tccapp.com",
  "password": "AdminPass123!",
  "totp_code": "123456"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "access_token": "admin_jwt_token",
    "refresh_token": "admin_refresh_token",
    "admin": {
      "id": "uuid-v4",
      "name": "Admin User",
      "email": "admin@tccapp.com",
      "role": "ADMIN",
      "permissions": ["VIEW_USERS", "APPROVE_KYC", "MANAGE_WITHDRAWALS"]
    }
  }
}
```

---

### 9.2 Get Dashboard Overview

**Endpoint:** `GET /admin/dashboard`

**Authentication:** Required (ADMIN/SUPER_ADMIN)

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "overview": {
      "total_users": 8542,
      "active_users": 6234,
      "total_agents": 145,
      "active_agents": 132,
      "pending_kyc": 234,
      "pending_withdrawals": 45,
      "pending_agent_credits": 12,
      "total_wallet_balance": 45000000.00,
      "total_investments": 25000000.00,
      "today_transactions": {
        "count": 1245,
        "volume": 5600000.00
      }
    },
    "recent_activity": [
      {
        "type": "KYC_SUBMISSION",
        "user": "John Doe",
        "timestamp": "2025-10-26T10:25:00Z"
      }
    ]
  }
}
```

---

### 9.3 Get All Users

**Endpoint:** `GET /admin/users`

**Authentication:** Required (ADMIN/SUPER_ADMIN)

**Query Parameters:**
- `page`, `limit`
- `role`: Filter by role
- `kyc_status`: Filter by KYC status
- `search`: Search by name, email, phone

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "id": "uuid-v4",
        "name": "John Doe",
        "email": "john@example.com",
        "phone": "+2321234567890",
        "role": "USER",
        "kyc_status": "APPROVED",
        "wallet_balance": 15000.50,
        "is_active": true,
        "created_at": "2025-10-26T10:30:00Z",
        "last_login": "2025-10-26T10:30:00Z"
      }
    ],
    "pagination": {
      "total": 8542,
      "page": 1,
      "limit": 50,
      "total_pages": 171
    }
  }
}
```

---

### 9.4 Get KYC Submissions

**Endpoint:** `GET /admin/kyc/submissions`

**Authentication:** Required (ADMIN/SUPER_ADMIN)

**Query Parameters:**
- `status`: Filter by status (SUBMITTED, APPROVED, REJECTED)
- `page`, `limit`

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "submissions": [
      {
        "id": "uuid-v4",
        "user": {
          "id": "uuid-v4",
          "name": "John Doe",
          "email": "john@example.com",
          "phone": "+2321234567890"
        },
        "document_type": "ID_CARD",
        "document_number": "ABC123456",
        "submitted_at": "2025-10-26T10:30:00Z",
        "status": "SUBMITTED",
        "documents": {
          "front": "https://s3.amazonaws.com/...",
          "back": "https://s3.amazonaws.com/...",
          "selfie": "https://s3.amazonaws.com/..."
        }
      }
    ],
    "pagination": {
      "total": 234,
      "page": 1,
      "limit": 20
    }
  }
}
```

---

### 9.5 Approve/Reject KYC

**Endpoint:** `POST /admin/kyc/:submission_id/review`

**Authentication:** Required (ADMIN/SUPER_ADMIN)

**Request:**
```json
{
  "action": "APPROVE|REJECT",
  "notes": "Documents verified successfully"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "kyc_submission": {
      "id": "uuid-v4",
      "status": "APPROVED",
      "reviewed_by": "Admin User",
      "reviewed_at": "2025-10-26T10:30:00Z",
      "notes": "Documents verified successfully"
    }
  },
  "message": "KYC approved successfully. User notified."
}
```

---

### 9.6 Get Withdrawal Requests

**Endpoint:** `GET /admin/withdrawals`

**Authentication:** Required (ADMIN/SUPER_ADMIN)

**Query Parameters:**
- `status`: PENDING, APPROVED, REJECTED
- `page`, `limit`

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "withdrawals": [
      {
        "id": "uuid-v4",
        "transaction_id": "TXN20251026234567",
        "user": {
          "name": "John Doe",
          "email": "john@example.com",
          "kyc_status": "APPROVED"
        },
        "amount": 3000.00,
        "fee": 50.00,
        "bank_account": {
          "account_number": "****5678",
          "account_holder": "John Doe",
          "bank_name": "Example Bank"
        },
        "requested_at": "2025-10-26T10:30:00Z",
        "status": "PENDING"
      }
    ]
  }
}
```

---

### 9.7 Approve/Reject Withdrawal

**Endpoint:** `POST /admin/withdrawals/:withdrawal_id/review`

**Authentication:** Required (ADMIN/SUPER_ADMIN)

**Request:**
```json
{
  "action": "APPROVE|REJECT",
  "transaction_reference": "BANK_TXN_789012",
  "notes": "Payment processed"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "withdrawal": {
      "id": "uuid-v4",
      "status": "APPROVED",
      "processed_by": "Admin User",
      "processed_at": "2025-10-26T10:45:00Z",
      "transaction_reference": "BANK_TXN_789012"
    }
  },
  "message": "Withdrawal approved. User notified."
}
```

---

### 9.8 Manage System Configuration

**Endpoint:** `GET /admin/config`

**Authentication:** Required (SUPER_ADMIN)

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "config": {
      "transaction_limits": {
        "min_deposit": 100.00,
        "max_deposit": 500000.00,
        "min_withdrawal": 500.00,
        "max_withdrawal": 200000.00,
        "daily_withdrawal_limit": 500000.00,
        "min_transfer": 100.00,
        "max_transfer": 100000.00,
        "daily_transfer_limit": 500000.00
      },
      "fees": {
        "withdrawal_fee_percentage": 1.00,
        "transfer_fee_percentage": 0.50,
        "bill_payment_fee_percentage": 1.00,
        "agent_commission_rate": 0.50
      },
      "security": {
        "password_min_length": 8,
        "max_login_attempts": 5,
        "lockout_duration_minutes": 30,
        "otp_expiry_minutes": 5,
        "session_timeout_minutes": 30
      }
    }
  }
}
```

---

### 9.9 Update System Configuration

**Endpoint:** `PATCH /admin/config`

**Authentication:** Required (SUPER_ADMIN)

**Request:**
```json
{
  "key": "max_withdrawal",
  "value": "250000.00"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "config": {
      "key": "max_withdrawal",
      "value": "250000.00",
      "updated_by": "Super Admin",
      "updated_at": "2025-10-26T10:30:00Z"
    }
  },
  "message": "Configuration updated successfully"
}
```

---

### 9.10 Approve Agent Credit Request

**Endpoint:** `POST /admin/agents/credit-requests/:request_id/review`

**Authentication:** Required (ADMIN/SUPER_ADMIN)

**Request:**
```json
{
  "action": "APPROVE|REJECT",
  "verified_amount": 100000.00,
  "notes": "Bank deposit verified"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "credit_request": {
      "id": "uuid-v4",
      "status": "APPROVED",
      "amount": 100000.00,
      "processed_by": "Admin User",
      "processed_at": "2025-10-26T10:30:00Z"
    },
    "agent_new_balance": 150000.00
  },
  "message": "Agent wallet credited successfully"
}
```

---

### 9.11 Create Poll

**Endpoint:** `POST /admin/polls`

**Authentication:** Required (ADMIN/SUPER_ADMIN)

**Request:**
```json
{
  "title": "Community Development Priority",
  "question": "Which project should be prioritized?",
  "description": "Help us decide the next community development project.",
  "options": [
    "Build new school",
    "Improve healthcare",
    "Road infrastructure",
    "Water supply"
  ],
  "voting_charge": 100.00,
  "start_date": "2025-10-26T00:00:00Z",
  "end_date": "2025-11-02T23:59:59Z"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "poll": {
      "id": "uuid-v4",
      "title": "Community Development Priority",
      "status": "DRAFT",
      "created_at": "2025-10-26T10:30:00Z"
    }
  },
  "message": "Poll created successfully"
}
```

---

### 9.12 Publish Poll

**Endpoint:** `POST /admin/polls/:poll_id/publish`

**Authentication:** Required (ADMIN/SUPER_ADMIN)

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "poll": {
      "id": "uuid-v4",
      "status": "ACTIVE",
      "published_at": "2025-10-26T10:30:00Z"
    }
  },
  "message": "Poll published and now active"
}
```

---

### 9.13 Get Reports

**Endpoint:** `GET /admin/reports`

**Authentication:** Required (ADMIN/SUPER_ADMIN)

**Query Parameters:**
- `type`: TRANSACTIONS, INVESTMENTS, USERS, AGENTS, REVENUE
- `from_date`, `to_date`
- `format`: JSON, CSV, PDF

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "report": {
      "type": "TRANSACTIONS",
      "period": {
        "from": "2025-10-01",
        "to": "2025-10-26"
      },
      "summary": {
        "total_transactions": 5234,
        "total_volume": 15600000.00,
        "deposits": {
          "count": 2145,
          "volume": 8500000.00
        },
        "withdrawals": {
          "count": 1234,
          "volume": 4200000.00
        },
        "transfers": {
          "count": 1455,
          "volume": 2100000.00
        },
        "bill_payments": {
          "count": 400,
          "volume": 800000.00
        }
      },
      "download_url": "https://s3.amazonaws.com/reports/..."
    }
  }
}
```

---

### 9.14 Manage Investment Returns

**Endpoint:** `POST /admin/investments/:investment_id/add-return`

**Authentication:** Required (SUPER_ADMIN)

**Request:**
```json
{
  "actual_return_rate": 10.50,
  "maturity_amount": 11050.00,
  "notes": "Investment matured successfully"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "investment": {
      "id": "uuid-v4",
      "status": "MATURED",
      "original_amount": 10000.00,
      "maturity_amount": 11050.00,
      "actual_return_rate": 10.50,
      "maturity_date": "2026-10-26"
    }
  },
  "message": "Investment return added. Amount credited to user wallet."
}
```

---

### 9.15 Get KPI Analytics

**Endpoint:** `GET /admin/analytics/kpi`

**Authentication:** Required (ADMIN/SUPER_ADMIN)

**Query Parameters:**
- `period`: DAY, WEEK, MONTH, YEAR, CUSTOM (default: MONTH)
- `from_date`: Start date (for CUSTOM period, ISO 8601)
- `to_date`: End date (for CUSTOM period, ISO 8601)
- `metrics`: Comma-separated list (TRANSACTIONS, USERS, REVENUE, INVESTMENTS, AGENTS)

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "period": {
      "type": "MONTH",
      "start": "2025-10-01",
      "end": "2025-10-26"
    },
    "metrics": {
      "transactions": {
        "total_count": 5234,
        "total_volume": 15600000.00,
        "growth_percentage": 15.5,
        "by_type": {
          "deposit": {
            "count": 2145,
            "volume": 8500000.00
          },
          "withdrawal": {
            "count": 1234,
            "volume": 4200000.00
          },
          "transfer": {
            "count": 1455,
            "volume": 2100000.00
          },
          "bill_payment": {
            "count": 400,
            "volume": 800000.00
          }
        },
        "avg_transaction_value": 2981.51
      },
      "users": {
        "total_users": 8542,
        "new_users": 245,
        "active_users": 1823,
        "growth_percentage": 8.2,
        "kyc_approved": 6234,
        "kyc_pending": 1245,
        "by_role": {
          "users": 8350,
          "agents": 145,
          "admins": 47
        }
      },
      "revenue": {
        "total_revenue": 156000.00,
        "growth_percentage": 12.3,
        "by_source": {
          "transaction_fees": 98000.00,
          "withdrawal_fees": 42000.00,
          "e_voting": 12500.00,
          "bill_payment_fees": 3500.00
        }
      },
      "investments": {
        "total_investments": 125,
        "total_volume": 5000000.00,
        "growth_percentage": 22.5,
        "active_investments": 98,
        "matured_investments": 27,
        "by_category": {
          "agriculture": {
            "count": 75,
            "volume": 3000000.00
          },
          "education": {
            "count": 30,
            "volume": 1500000.00
          },
          "minerals": {
            "count": 20,
            "volume": 500000.00
          }
        }
      },
      "agents": {
        "total_agents": 145,
        "active_agents": 132,
        "new_agents": 12,
        "total_commissions_paid": 45000.00,
        "avg_rating": 4.6,
        "total_transactions_processed": 3500
      }
    },
    "charts": {
      "daily_transactions": [
        {
          "date": "2025-10-01",
          "count": 185,
          "volume": 550000.00
        },
        {
          "date": "2025-10-02",
          "count": 195,
          "volume": 580000.00
        }
      ],
      "user_growth": [
        {
          "month": "2025-07",
          "users": 7850
        },
        {
          "month": "2025-08",
          "users": 8100
        },
        {
          "month": "2025-09",
          "users": 8297
        },
        {
          "month": "2025-10",
          "users": 8542
        }
      ]
    }
  }
}
```

---

## 10. File Upload Endpoints

### 10.1 Upload File

**Endpoint:** `POST /uploads`

**Authentication:** Required

**Content-Type:** `multipart/form-data`

**Request Parameters:**
- `file`: File binary (required)
- `type`: File type (required) - `KYC_DOCUMENT`, `BANK_RECEIPT`, `PROFILE_PICTURE`, `AGENT_LICENSE`, `SUPPORT_ATTACHMENT`
- `document_type`: Document subtype (for KYC) - `NATIONAL_ID`, `PASSPORT`, `DRIVERS_LICENSE`, `VOTER_CARD`

**File Validation:**
- Max file size: 5MB for documents, 2MB for images
- Allowed formats:
  - Documents: PDF, DOC, DOCX
  - Images: JPG, JPEG, PNG, WEBP
  - Receipts: PDF, JPG, PNG

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "file": {
      "id": "uuid-v4",
      "url": "https://s3.amazonaws.com/tcc-app/uploads/...",
      "filename": "document.pdf",
      "original_filename": "my-id-card.pdf",
      "size": 245678,
      "mime_type": "application/pdf",
      "type": "KYC_DOCUMENT",
      "uploaded_at": "2025-10-26T10:30:00Z"
    }
  },
  "message": "File uploaded successfully"
}
```

**Error Responses:**
- `FILE_TOO_LARGE` (400): File size exceeds limit
- `INVALID_FILE_FORMAT` (400): File format not supported
- `MISSING_FILE` (400): No file provided
- `UPLOAD_FAILED` (500): S3 upload failed

---

### 10.2 Delete Uploaded File

**Endpoint:** `DELETE /uploads/:file_id`

**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "message": "File deleted successfully"
}
```

---

## 11. Notification Endpoints

### 11.1 Get Notifications

**Endpoint:** `GET /notifications`

**Authentication:** Required

**Query Parameters:**
- `page`, `limit`
- `unread_only`: boolean

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "uuid-v4",
        "type": "TRANSACTION",
        "title": "Money received",
        "message": "You received SLL 5000 from Jane Smith",
        "is_read": false,
        "created_at": "2025-10-26T10:30:00Z",
        "data": {
          "transaction_id": "TXN20251026123456"
        }
      }
    ],
    "unread_count": 5,
    "pagination": {
      "total": 45,
      "page": 1,
      "limit": 20
    }
  }
}
```

---

### 11.2 Mark Notification as Read

**Endpoint:** `PATCH /notifications/:notification_id/read`

**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "message": "Notification marked as read"
}
```

---

### 11.3 Register Push Token

**Endpoint:** `POST /notifications/push-token`

**Authentication:** Required

**Request:**
```json
{
  "token": "fcm_device_token_here",
  "platform": "iOS|Android|Web"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Push token registered successfully"
}
```

---

### 11.4 Update Notification Preferences

**Endpoint:** `PATCH /notifications/preferences`

**Authentication:** Required

**Request:**
```json
{
  "push_enabled": true,
  "email_enabled": true,
  "sms_enabled": false,
  "notification_types": {
    "DEPOSIT": true,
    "WITHDRAWAL": true,
    "TRANSFER": true,
    "BILL_PAYMENT": true,
    "INVESTMENT": true,
    "KYC": true,
    "SECURITY": true,
    "ANNOUNCEMENT": false,
    "VOTE": false
  },
  "quiet_hours": {
    "enabled": true,
    "start": "22:00",
    "end": "08:00"
  }
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "preferences": {
      "push_enabled": true,
      "email_enabled": true,
      "sms_enabled": false,
      "notification_types": {
        "DEPOSIT": true,
        "WITHDRAWAL": true,
        "TRANSFER": true,
        "BILL_PAYMENT": true,
        "INVESTMENT": true,
        "KYC": true,
        "SECURITY": true,
        "ANNOUNCEMENT": false,
        "VOTE": false
      },
      "quiet_hours": {
        "enabled": true,
        "start": "22:00",
        "end": "08:00"
      },
      "updated_at": "2025-10-26T10:30:00Z"
    }
  },
  "message": "Notification preferences updated successfully"
}
```

---

### 11.5 Get Notification Preferences

**Endpoint:** `GET /notifications/preferences`

**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "preferences": {
      "push_enabled": true,
      "email_enabled": true,
      "sms_enabled": false,
      "notification_types": {
        "DEPOSIT": true,
        "WITHDRAWAL": true,
        "TRANSFER": true,
        "BILL_PAYMENT": true,
        "INVESTMENT": true,
        "KYC": true,
        "SECURITY": true,
        "ANNOUNCEMENT": false,
        "VOTE": false
      },
      "quiet_hours": {
        "enabled": true,
        "start": "22:00",
        "end": "08:00"
      }
    }
  }
}
```

---

## 12. Support Endpoints

### 12.1 Create Support Ticket

**Endpoint:** `POST /support/tickets`

**Authentication:** Required

**Request:**
```json
{
  "category": "TRANSACTION_ISSUE|ACCOUNT_ACCESS|KYC_QUERY|TECHNICAL|OTHER",
  "subject": "Unable to withdraw funds",
  "description": "I'm getting an error when trying to withdraw...",
  "attachments": ["base64_encoded_screenshot"]
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "ticket": {
      "id": "uuid-v4",
      "ticket_id": "TCK20251026123456",
      "category": "TRANSACTION_ISSUE",
      "subject": "Unable to withdraw funds",
      "status": "OPEN",
      "priority": "MEDIUM",
      "created_at": "2025-10-26T10:30:00Z"
    }
  },
  "message": "Support ticket created. We'll respond within 24 hours."
}
```

---

### 12.2 Get User Tickets

**Endpoint:** `GET /support/tickets`

**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "tickets": [
      {
        "id": "uuid-v4",
        "ticket_id": "TCK20251026123456",
        "subject": "Unable to withdraw funds",
        "status": "OPEN",
        "priority": "MEDIUM",
        "created_at": "2025-10-26T10:30:00Z",
        "last_updated": "2025-10-26T10:30:00Z",
        "unread_messages": 1
      }
    ]
  }
}
```

---

## 13. Device Management Endpoints

### 13.1 Register Device

**Endpoint:** `POST /devices/register`

**Authentication:** Required

**Request:**
```json
{
  "device_type": "iOS|Android|Web",
  "device_model": "iPhone 14 Pro",
  "device_token": "fcm_token_for_push_notifications",
  "app_version": "1.0.0",
  "os_version": "iOS 16.0"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "device": {
      "id": "uuid-v4",
      "device_fingerprint": "SHA256_HASH",
      "trusted": false,
      "registered_at": "2025-10-26T10:30:00Z"
    }
  },
  "message": "Device registered successfully"
}
```

---

### 13.2 Get User Devices

**Endpoint:** `GET /devices`

**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "devices": [
      {
        "id": "uuid-v4",
        "device_type": "iOS",
        "device_model": "iPhone 14 Pro",
        "last_used": "2025-10-26T10:30:00Z",
        "trusted": true,
        "is_current": true
      }
    ]
  }
}
```

---

### 13.3 Remove Device

**Endpoint:** `DELETE /devices/:device_id`

**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "message": "Device removed successfully"
}
```

---

## 14. Transaction Management Endpoints

### 14.1 Calculate Transaction Fee

**Endpoint:** `POST /transactions/calculate-fee`

**Authentication:** Required

**Request:**
```json
{
  "transaction_type": "WITHDRAWAL|TRANSFER|BILL_PAYMENT|INVESTMENT",
  "amount": 10000.00,
  "recipient_account": "optional_for_transfers"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "amount": 10000.00,
    "base_fee": 200.00,
    "discount_type": "KYC_VERIFIED",
    "discount_amount": 20.00,
    "final_fee": 180.00,
    "total_amount": 10180.00,
    "fee_breakdown": {
      "base_rate": "2%",
      "kyc_discount": "10%",
      "volume_discount": "0%",
      "min_fee": 50.00,
      "max_fee": 5000.00
    }
  }
}
```

---

### 14.2 Request Transaction Reversal

**Endpoint:** `POST /transactions/:transaction_id/reversal`

**Authentication:** Required

**Request:**
```json
{
  "reason": "FRAUD|ERROR|DUPLICATE|CUSTOMER_REQUEST|OTHER",
  "description": "Accidental duplicate payment",
  "evidence_urls": ["https://s3.amazonaws.com/evidence/doc1.pdf"]
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "reversal": {
      "id": "uuid-v4",
      "transaction_id": "TXN20251026123456",
      "status": "PENDING",
      "reason": "DUPLICATE",
      "created_at": "2025-10-26T10:30:00Z",
      "estimated_resolution": "2025-10-28T10:30:00Z"
    }
  },
  "message": "Reversal request submitted for review"
}
```

---

### 14.3 Get Transaction Reversals

**Endpoint:** `GET /transactions/reversals`

**Authentication:** Required

**Query Parameters:**
- `status`: PENDING|APPROVED|REJECTED|COMPLETED
- `page`: Default 1
- `limit`: Default 20

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "reversals": [
      {
        "id": "uuid-v4",
        "transaction_id": "TXN20251026123456",
        "original_amount": 10000.00,
        "status": "PENDING",
        "reason": "DUPLICATE",
        "created_at": "2025-10-26T10:30:00Z",
        "reviewed_at": null,
        "completed_at": null
      }
    ]
  },
  "pagination": {
    "total": 5,
    "page": 1,
    "limit": 20,
    "total_pages": 1
  }
}
```

---

## 15. Security & Fraud Management Endpoints

### 15.1 Report Suspicious Activity

**Endpoint:** `POST /security/report`

**Authentication:** Required

**Request:**
```json
{
  "activity_type": "UNAUTHORIZED_ACCESS|SUSPICIOUS_TRANSACTION|PHISHING|ACCOUNT_TAKEOVER|OTHER",
  "description": "Received suspicious SMS asking for OTP",
  "related_transaction_id": "optional_transaction_id",
  "evidence": ["screenshot_base64"]
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "report": {
      "id": "uuid-v4",
      "case_id": "SEC20251026123456",
      "status": "UNDER_REVIEW",
      "created_at": "2025-10-26T10:30:00Z"
    }
  },
  "message": "Security report submitted. Our team will investigate."
}
```

---

### 15.2 Get Security Events (Admin Only)

**Endpoint:** `GET /admin/security/events`

**Authentication:** Required (Admin)

**Query Parameters:**
- `user_id`: Filter by specific user
- `event_type`: LOGIN_FAILED|SUSPICIOUS_ACTIVITY|FRAUD_DETECTED
- `date_from`: ISO date
- `date_to`: ISO date

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "events": [
      {
        "id": "uuid-v4",
        "user_id": "uuid-v4",
        "event_type": "LOGIN_FAILED",
        "description": "Multiple failed login attempts",
        "risk_score": 75,
        "ip_address": "192.168.1.1",
        "device_fingerprint": "SHA256_HASH",
        "created_at": "2025-10-26T10:30:00Z",
        "action_taken": "ACCOUNT_LOCKED"
      }
    ]
  }
}
```

---

### 15.3 Get Fraud Detection Logs (Admin Only)

**Endpoint:** `GET /admin/fraud/logs`

**Authentication:** Required (Admin)

**Query Parameters:**
- `user_id`: Filter by user
- `risk_level`: LOW|MEDIUM|HIGH|CRITICAL
- `date_from`: ISO date
- `date_to`: ISO date

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "logs": [
      {
        "id": "uuid-v4",
        "user_id": "uuid-v4",
        "user_name": "John Doe",
        "risk_score": 85,
        "risk_factors": [
          "HIGH_VELOCITY: 5 transactions in 2 minutes",
          "LARGE_AMOUNT: Transaction exceeds daily average by 500%",
          "NEW_RECIPIENT: First time sending to this account"
        ],
        "transaction_id": "TXN20251026123456",
        "amount": 50000.00,
        "action_taken": "MANUAL_REVIEW",
        "detected_at": "2025-10-26T10:30:00Z",
        "resolved_at": null,
        "resolution": null
      }
    ]
  }
}
```

---

## 16. Analytics & Performance Endpoints

### 16.1 Get User Dashboard Data

**Endpoint:** `GET /dashboard`

**Authentication:** Required

**Description:** Returns comprehensive dashboard data using materialized view for performance

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "wallet_balance": 25000.50,
    "tcc_coins_balance": 1500.00,
    "total_transactions": 156,
    "monthly_volume": 450000.00,
    "active_investments": 3,
    "total_investment_value": 75000.00,
    "pending_returns": 5000.00,
    "referral_earnings": 2500.00,
    "pending_bills": 2,
    "recent_transactions": [
      {
        "id": "TXN20251026123456",
        "type": "TRANSFER",
        "amount": 5000.00,
        "status": "COMPLETED",
        "created_at": "2025-10-26T10:30:00Z"
      }
    ],
    "investment_summary": {
      "agriculture": 30000.00,
      "education": 25000.00,
      "minerals": 20000.00
    },
    "quick_actions": [
      {
        "action": "PAY_BILL",
        "label": "Electricity Due",
        "amount": 1500.00,
        "due_date": "2025-10-30"
      }
    ]
  }
}
```

---

### 16.2 Get Agent Performance Analytics

**Endpoint:** `GET /agents/performance`

**Authentication:** Required (Agent)

**Query Parameters:**
- `period`: TODAY|WEEK|MONTH|YEAR
- `metric`: TRANSACTIONS|REVENUE|CUSTOMERS

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "period": "MONTH",
    "metrics": {
      "total_transactions": 342,
      "total_volume": 2500000.00,
      "total_commission": 25000.00,
      "average_transaction": 7309.94,
      "new_customers": 28,
      "returning_customers": 145,
      "average_rating": 4.7,
      "total_reviews": 89
    },
    "daily_breakdown": [
      {
        "date": "2025-10-26",
        "transactions": 15,
        "volume": 125000.00,
        "commission": 1250.00
      }
    ],
    "top_services": [
      {
        "service": "CASH_IN",
        "count": 156,
        "volume": 1200000.00
      },
      {
        "service": "BILL_PAYMENT",
        "count": 98,
        "volume": 450000.00
      }
    ],
    "ranking": {
      "current_rank": 5,
      "previous_rank": 8,
      "total_agents": 250,
      "percentile": 98
    }
  }
}
```

---

### 16.3 Calculate Agent Commission

**Endpoint:** `POST /agents/calculate-commission`

**Authentication:** Required (Agent)

**Request:**
```json
{
  "service_type": "CASH_IN|CASH_OUT|BILL_PAYMENT|INVESTMENT",
  "amount": 50000.00
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "amount": 50000.00,
    "service_type": "CASH_IN",
    "commission_rate": "1.2%",
    "base_commission": 600.00,
    "performance_bonus": 60.00,
    "total_commission": 660.00,
    "tier_info": {
      "current_tier": "GOLD",
      "monthly_volume": 2500000.00,
      "next_tier": "PLATINUM",
      "volume_to_next_tier": 500000.00,
      "next_tier_rate": "1.5%"
    }
  }
}
```

---

### 16.4 Get Audit Logs (Admin Only)

**Endpoint:** `GET /admin/audit-logs`

**Authentication:** Required (Super Admin)

**Query Parameters:**
- `user_id`: Filter by user
- `action`: Filter by action type
- `entity_type`: users|transactions|wallets
- `date_from`: ISO date
- `date_to`: ISO date
- `page`: Default 1
- `limit`: Default 50

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "logs": [
      {
        "id": "uuid-v4",
        "user_id": "uuid-v4",
        "user_email": "admin@tccapp.com",
        "action": "UPDATE",
        "entity_type": "transactions",
        "entity_id": "uuid-v4",
        "old_values": {
          "status": "PENDING"
        },
        "new_values": {
          "status": "COMPLETED"
        },
        "ip_address": "192.168.1.1",
        "user_agent": "TCC Admin Panel/1.0",
        "created_at": "2025-10-26T10:30:00Z"
      }
    ]
  },
  "pagination": {
    "total": 1250,
    "page": 1,
    "limit": 50,
    "total_pages": 25
  }
}
```

---

### 16.5 Process Matured Investments (Admin Only)

**Endpoint:** `POST /admin/investments/process-maturity`

**Authentication:** Required (Admin)

**Description:** Manually trigger processing of matured investments

**Request:**
```json
{
  "dry_run": false,
  "investment_ids": ["uuid-v4"] // Optional, processes all matured if not specified
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "processed": 12,
    "total_principal": 500000.00,
    "total_returns": 75000.00,
    "failed": 0,
    "investments": [
      {
        "id": "uuid-v4",
        "user_id": "uuid-v4",
        "principal": 50000.00,
        "return_amount": 7500.00,
        "status": "PAID_OUT"
      }
    ]
  },
  "message": "Successfully processed 12 matured investments"
}
```

---

## 17. Validation Rules

### Request Validation

All API requests must comply with the following validation rules:

#### General Rules
- **UUID Format**: All IDs must be valid UUID v4
- **Email Format**: Must match RFC 5322 specification
- **Phone Format**: Must be 10 digits (without country code)
- **Amount Fields**: Positive decimal with max 2 decimal places
- **Date Format**: ISO 8601 (YYYY-MM-DDTHH:mm:ssZ)
- **Password**: Min 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special char
- **OTP**: Exactly 6 digits
- **Transaction ID**: Format TXN + YYYYMMDD + 6 digits

#### Field-Specific Validation

| Field | Min | Max | Pattern | Required |
|-------|-----|-----|---------|----------|
| first_name | 2 | 50 | ^[a-zA-Z\s'-]+$ | Yes |
| last_name | 2 | 50 | ^[a-zA-Z\s'-]+$ | Yes |
| email | 5 | 100 | Valid email | Yes |
| phone | 10 | 10 | ^[0-9]{10}$ | Yes |
| password | 8 | 128 | Complex pattern | Yes |
| pin | 4 | 6 | ^[0-9]+$ | Yes |
| amount | 0.01 | 10000000 | Decimal(15,2) | Yes |
| description | 0 | 500 | Any | No |
| reference | 5 | 50 | ^[A-Z0-9-]+$ | No |

#### Business Logic Validation

1. **Transaction Limits**
   - Single transaction: Max 5,000,000 SLL
   - Daily limit: 20,000,000 SLL (KYC verified)
   - Daily limit: 5,000,000 SLL (non-KYC)
   - Minimum transaction: 100 SLL

2. **Account Validation**
   - Cannot transfer to same account
   - Recipient must be active
   - Sufficient balance required (including fees)

3. **Time-Based Validation**
   - OTP expires in 5 minutes
   - Session timeout: 30 minutes (mobile), 15 minutes (web)
   - Password reset link: 1 hour
   - Investment lock period: As per terms

4. **Frequency Limits**
   - Max 3 OTP requests per 10 minutes
   - Max 5 failed login attempts (15-minute lockout)
   - Max 10 transactions per minute
   - Max 100 API calls per minute per user

---

## 18. Enhanced Error Codes

### Authentication Errors (1xxx)
- `1001`: Invalid credentials
- `1002`: Account locked
- `1003`: Session expired
- `1004`: Invalid token
- `1005`: Insufficient permissions
- `1006`: 2FA required
- `1007`: Device not trusted
- `1008`: IP address blocked

### Validation Errors (2xxx)
- `2001`: Missing required field
- `2002`: Invalid field format
- `2003`: Field value out of range
- `2004`: Duplicate entry
- `2005`: Invalid reference
- `2006`: Business rule violation
- `2007`: Rate limit exceeded
- `2008`: Invalid file type

### Transaction Errors (3xxx)
- `3001`: Insufficient balance
- `3002`: Transaction limit exceeded
- `3003`: Invalid recipient
- `3004`: Duplicate transaction
- `3005`: Transaction expired
- `3006`: Reversal not allowed
- `3007`: Fraud detected
- `3008`: Manual review required

### KYC Errors (4xxx)
- `4001`: KYC not verified
- `4002`: Document expired
- `4003`: Document rejected
- `4004`: Verification pending
- `4005`: Information mismatch
- `4006`: Blacklisted user
- `4007`: Sanctions match
- `4008`: PEP detected

### System Errors (5xxx)
- `5001`: Internal server error
- `5002`: Database error
- `5003`: External service error
- `5004`: Maintenance mode
- `5005`: Service unavailable
- `5006`: Timeout error
- `5007`: Configuration error
- `5008`: Resource exhausted

---

## 19. Rate Limiting Specifications

### Default Limits

| Endpoint Category | Authenticated | Unauthenticated |
|------------------|---------------|-----------------|
| Authentication | 10/minute | 5/minute |
| Read Operations | 100/minute | 20/minute |
| Write Operations | 50/minute | N/A |
| Admin Operations | 30/minute | N/A |
| File Uploads | 10/minute | N/A |
| Analytics | 20/minute | N/A |

### Endpoint-Specific Limits

| Endpoint | Limit | Window |
|----------|-------|--------|
| POST /auth/login | 5 | 10 minutes |
| POST /auth/otp/send | 3 | 10 minutes |
| POST /transactions | 10 | 1 minute |
| POST /transactions/bulk | 1 | 1 minute |
| GET /admin/analytics/* | 10 | 1 minute |
| POST /uploads | 5 | 1 minute |
| WebSocket connections | 3 | Per user |

### Rate Limit Headers

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1635724800
X-RateLimit-Retry-After: 45
```

### Burst Handling
- Allow 20% burst above limit for 10 seconds
- Gradual backoff algorithm
- Priority queuing for premium users

---

## WebSocket Events

### Connection
```
wss://api.tccapp.com/v1/ws?token={jwt_token}
```

### Events Published to Client

#### Transaction Status Update
```json
{
  "event": "transaction.status_updated",
  "data": {
    "transaction_id": "TXN20251026123456",
    "status": "COMPLETED",
    "timestamp": "2025-10-26T10:30:00Z"
  }
}
```

#### New Notification
```json
{
  "event": "notification.new",
  "data": {
    "id": "uuid-v4",
    "type": "TRANSACTION",
    "title": "Money received",
    "message": "You received SLL 5000 from Jane Smith"
  }
}
```

#### Wallet Balance Update
```json
{
  "event": "wallet.balance_updated",
  "data": {
    "balance": 15000.50,
    "tcc_coins": 15000.50,
    "timestamp": "2025-10-26T10:30:00Z"
  }
}
```

---

## API Versioning

**Current Version:** v1

**Deprecation Policy:**
- New versions announced 3 months in advance
- Old versions supported for 6 months after new release
- Breaking changes only in major versions

**Version Header:**
```
Accept-Version: v1
```

---

## Security Headers

All API responses include:
```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'
```

---

## Idempotency

POST requests support idempotency using:
```
Idempotency-Key: {unique_key}
```

Duplicate requests within 24 hours return the same response with `200` status.

---

## Pagination

Standard pagination format for list endpoints:
```json
{
  "pagination": {
    "total": 150,
    "page": 1,
    "limit": 20,
    "total_pages": 8,
    "has_next": true,
    "has_prev": false
  }
}
```

---

## Testing

**Sandbox Base URL:** `https://sandbox-api.tccapp.com/v1`

**Test Credentials:**
- User: `testuser@tccapp.com` / `TestPass123!`
- Agent: `testagent@tccapp.com` / `TestPass123!`
- Admin: `testadmin@tccapp.com` / `TestPass123!`

**Test OTP:** Always `123456` in sandbox

**Test Cards/Accounts:** Provided in developer documentation

---

## Support

**Developer Portal:** https://developers.tccapp.com

**API Status:** https://status.tccapp.com

**Support Email:** api-support@tccapp.com

**Changelog:** https://developers.tccapp.com/changelog
