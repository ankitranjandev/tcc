# Agent API Documentation

## Base URL
```
http://localhost:3000/v1/agent
```

## Authentication
Most endpoints require JWT authentication. Include the token in the Authorization header:
```
Authorization: Bearer <your_jwt_token>
```

---

## Endpoints

### 1. Register as Agent

Register the current user as an agent.

**Endpoint:** `POST /register`

**Authentication:** Required

**Request Body:**
```json
{
  "location_lat": 8.4657,
  "location_lng": -13.2317,
  "location_address": "15 Wilkinson Road, Freetown, Sierra Leone"
}
```

**Request Body Schema:**
- `location_lat` (number, optional): Latitude (-90 to 90)
- `location_lng` (number, optional): Longitude (-180 to 180)
- `location_address` (string, optional): Physical address (max 500 chars)

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "agent": {
      "id": "uuid",
      "user_id": "uuid",
      "wallet_balance": 0.00,
      "active_status": false,
      "verification_status": "PENDING",
      "location_lat": 8.4657,
      "location_lng": -13.2317,
      "location_address": "15 Wilkinson Road, Freetown, Sierra Leone",
      "commission_rate": 0.5,
      "created_at": "2024-11-19T10:00:00.000Z"
    }
  },
  "message": "Agent registration successful. Your account will be activated after verification."
}
```

**Error Responses:**
- `400`: Already registered as agent
- `404`: User not found
- `401`: Unauthorized

---

### 2. Get Agent Profile

Get the complete agent profile with statistics.

**Endpoint:** `GET /profile`

**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "agent": {
      "id": "uuid",
      "user_id": "uuid",
      "wallet_balance": 500000.00,
      "active_status": true,
      "verification_status": "APPROVED",
      "location_lat": 8.4657,
      "location_lng": -13.2317,
      "location_address": "15 Wilkinson Road, Freetown, Sierra Leone",
      "commission_rate": 0.5,
      "total_commission_earned": 25000.00,
      "total_transactions_processed": 150,
      "verified_at": "2024-11-15T10:00:00.000Z",
      "created_at": "2024-11-01T10:00:00.000Z",
      "updated_at": "2024-11-19T10:00:00.000Z",
      "user": {
        "firstName": "John",
        "lastName": "Doe",
        "email": "john@example.com",
        "phone": "+23276123456",
        "profilePicture": "https://..."
      },
      "stats": {
        "totalTransactions": 150,
        "commissionsEarned": 25000.00,
        "walletBalance": 500000.00,
        "averageRating": 4.5,
        "totalReviews": 45
      }
    }
  }
}
```

**Error Responses:**
- `404`: Agent profile not found
- `401`: Unauthorized

---

### 3. Request Wallet Credit

Request credit for agent wallet (requires admin approval).

**Endpoint:** `POST /credit/request`

**Authentication:** Required

**Request Body:**
```json
{
  "agent_id": "uuid",
  "amount": 1000000,
  "receipt_url": "https://storage.example.com/receipts/receipt123.jpg",
  "deposit_date": "2024-11-19",
  "deposit_time": "14:30:00",
  "bank_name": "Rokel Commercial Bank"
}
```

**Request Body Schema:**
- `agent_id` (string, required): UUID of the agent
- `amount` (number, required): Amount to credit (minimum 1000)
- `receipt_url` (string, required): URL to receipt image
- `deposit_date` (string, required): Date in YYYY-MM-DD format
- `deposit_time` (string, required): Time in HH:MM:SS format
- `bank_name` (string, optional): Bank name (max 255 chars)

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "credit_request": {
      "id": "uuid",
      "agent_id": "uuid",
      "amount": 1000000,
      "receipt_url": "https://storage.example.com/receipts/receipt123.jpg",
      "deposit_date": "2024-11-19",
      "deposit_time": "14:30:00",
      "bank_name": "Rokel Commercial Bank",
      "status": "PENDING",
      "created_at": "2024-11-19T10:00:00.000Z"
    }
  },
  "message": "Credit request submitted successfully. Your wallet will be credited after admin approval."
}
```

**Error Responses:**
- `400`: Invalid amount
- `404`: Agent not found
- `401`: Unauthorized

---

### 4. Get Credit Request History

Get paginated history of credit requests.

**Endpoint:** `GET /credit/requests`

**Authentication:** Required

**Query Parameters:**
- `agent_id` (string, required): UUID of the agent
- `status` (string, optional): Filter by status (PENDING, PROCESSING, COMPLETED, FAILED, CANCELLED)
- `start_date` (string, optional): Start date in YYYY-MM-DD format
- `end_date` (string, optional): End date in YYYY-MM-DD format
- `page` (number, optional): Page number (default: 1)
- `limit` (number, optional): Items per page (default: 20)

**Example:**
```
GET /credit/requests?agent_id=uuid&status=PENDING&page=1&limit=10
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "credit_requests": [
      {
        "id": "uuid",
        "agent_id": "uuid",
        "amount": 1000000,
        "receipt_url": "https://...",
        "deposit_date": "2024-11-19",
        "deposit_time": "14:30:00",
        "bank_name": "Rokel Commercial Bank",
        "status": "PENDING",
        "admin_id": null,
        "rejection_reason": null,
        "approved_at": null,
        "rejected_at": null,
        "created_at": "2024-11-19T10:00:00.000Z"
      }
    ]
  },
  "meta": {
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 25,
      "totalPages": 3
    }
  }
}
```

---

### 5. Process Deposit for User

Process a cash deposit for a user (agent gives user wallet credit).

**Endpoint:** `POST /deposit`

**Authentication:** Required

**Request Body:**
```json
{
  "agent_id": "uuid",
  "user_phone": "76123456",
  "amount": 50000,
  "payment_method": "AGENT"
}
```

**Request Body Schema:**
- `agent_id` (string, required): UUID of the agent
- `user_phone` (string, required): User's phone number (10-15 digits)
- `amount` (number, required): Amount to deposit (minimum 100)
- `payment_method` (string, required): Payment method (BANK_TRANSFER, MOBILE_MONEY, AGENT, BANK_RECEIPT)

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "transaction": {
      "id": "uuid",
      "transaction_id": "TXN202411191234567",
      "type": "DEPOSIT",
      "amount": 50000,
      "fee": 0,
      "net_amount": 50000,
      "status": "COMPLETED",
      "payment_method": "AGENT",
      "commission": 250,
      "user": {
        "name": "Jane Smith",
        "phone": "****3456"
      },
      "created_at": "2024-11-19T10:00:00.000Z"
    }
  },
  "message": "Deposit processed successfully"
}
```

**Error Responses:**
- `400`: Invalid amount, Agent account is not active, Insufficient agent wallet balance
- `404`: Agent not found, User not found
- `401`: Unauthorized

---

### 6. Process Withdrawal for User

Process a cash withdrawal for a user (agent receives wallet credit).

**Endpoint:** `POST /withdraw`

**Authentication:** Required

**Request Body:**
```json
{
  "agent_id": "uuid",
  "user_phone": "76123456",
  "amount": 30000
}
```

**Request Body Schema:**
- `agent_id` (string, required): UUID of the agent
- `user_phone` (string, required): User's phone number (10-15 digits)
- `amount` (number, required): Amount to withdraw (minimum 100)

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "transaction": {
      "id": "uuid",
      "transaction_id": "TXN202411191234568",
      "type": "WITHDRAWAL",
      "amount": 30000,
      "fee": 0,
      "net_amount": 30000,
      "status": "COMPLETED",
      "payment_method": "AGENT",
      "commission": 150,
      "user": {
        "name": "Jane Smith",
        "phone": "****3456"
      },
      "created_at": "2024-11-19T10:00:00.000Z"
    }
  },
  "message": "Withdrawal processed successfully"
}
```

**Error Responses:**
- `400`: Invalid amount, Agent account is not active, Insufficient user wallet balance
- `404`: Agent not found, User not found
- `401`: Unauthorized

---

### 7. Find Nearby Agents

Find agents within a specified radius (public endpoint).

**Endpoint:** `GET /nearby`

**Authentication:** Not Required

**Query Parameters:**
- `latitude` (number, required): Latitude coordinate
- `longitude` (number, required): Longitude coordinate
- `radius` (number, optional): Search radius in km (default: 10)

**Example:**
```
GET /nearby?latitude=8.4657&longitude=-13.2317&radius=5
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "agents": [
      {
        "id": "uuid",
        "user_id": "uuid",
        "first_name": "John",
        "last_name": "Doe",
        "phone": "****3456",
        "profile_picture": "https://...",
        "location": {
          "latitude": 8.4657,
          "longitude": -13.2317,
          "address": "15 Wilkinson Road, Freetown"
        },
        "distance_km": 1.25,
        "rating": 4.5,
        "total_reviews": 45,
        "active_status": true,
        "wallet_balance": 500000
      }
    ],
    "search_params": {
      "latitude": 8.4657,
      "longitude": -13.2317,
      "radius_km": 5
    },
    "total_found": 1
  }
}
```

**Error Responses:**
- `400`: Latitude and longitude are required, Invalid coordinates or radius

---

### 8. Get Dashboard Statistics

Get comprehensive dashboard statistics for an agent.

**Endpoint:** `GET /dashboard`

**Authentication:** Required

**Query Parameters:**
- `agent_id` (string, required): UUID of the agent

**Example:**
```
GET /dashboard?agent_id=uuid
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "stats": {
      "wallet_balance": 500000.00,
      "total_transactions": 150,
      "total_commissions_earned": 25000.00,
      "average_rating": 4.5,
      "total_reviews": 45,
      "today": {
        "transactions": 5,
        "commissions": 750.00
      },
      "this_week": {
        "transactions": 23,
        "commissions": 3450.00
      },
      "this_month": {
        "transactions": 87,
        "commissions": 13050.00
      }
    }
  }
}
```

**Error Responses:**
- `400`: Agent ID is required
- `404`: Agent not found
- `401`: Unauthorized

---

### 9. Update Agent Location

Update the agent's current location.

**Endpoint:** `PUT /location`

**Authentication:** Required

**Request Body:**
```json
{
  "agent_id": "uuid",
  "latitude": 8.4657,
  "longitude": -13.2317,
  "address": "20 Siaka Stevens Street, Freetown"
}
```

**Request Body Schema:**
- `agent_id` (string, required): UUID of the agent
- `latitude` (number, required): Latitude (-90 to 90)
- `longitude` (number, required): Longitude (-180 to 180)
- `address` (string, optional): Physical address (max 500 chars)

**Success Response (200):**
```json
{
  "success": true,
  "data": {},
  "message": "Location updated successfully"
}
```

**Error Responses:**
- `401`: Unauthorized
- `500`: Internal server error

---

### 10. Submit Agent Review

Submit a review for an agent after a transaction.

**Endpoint:** `POST /review`

**Authentication:** Required

**Request Body:**
```json
{
  "agent_id": "uuid",
  "transaction_id": "uuid",
  "rating": 5,
  "comment": "Excellent service, very professional and quick!"
}
```

**Request Body Schema:**
- `agent_id` (string, required): UUID of the agent
- `transaction_id` (string, required): UUID of the transaction
- `rating` (number, required): Rating from 1 to 5
- `comment` (string, optional): Review comment (max 500 chars)

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "review": {
      "id": "uuid",
      "agent_id": "uuid",
      "user_id": "uuid",
      "transaction_id": "uuid",
      "rating": 5,
      "comment": "Excellent service, very professional and quick!",
      "created_at": "2024-11-19T10:00:00.000Z"
    }
  },
  "message": "Review submitted successfully"
}
```

**Error Responses:**
- `400`: Rating must be between 1 and 5, Review already submitted for this transaction
- `404`: Agent not found, Transaction not found or not authorized
- `401`: Unauthorized

---

## Error Response Format

All error responses follow this format:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {},
    "timestamp": "2024-11-19T10:00:00.000Z"
  }
}
```

## Common Error Codes

- `BAD_REQUEST` (400): Invalid request data
- `UNAUTHORIZED` (401): Missing or invalid authentication
- `FORBIDDEN` (403): Insufficient permissions
- `NOT_FOUND` (404): Resource not found
- `VALIDATION_ERROR` (422): Request validation failed
- `RATE_LIMIT_EXCEEDED` (429): Too many requests
- `INTERNAL_ERROR` (500): Internal server error

## Rate Limiting

API requests are rate-limited to prevent abuse. Default limits:
- General endpoints: 100 requests per minute
- Authentication endpoints: 5 requests per minute

## Notes

1. All monetary amounts are in Sierra Leonean Leones (SLL)
2. Phone numbers are masked in responses for privacy
3. All timestamps are in ISO 8601 format (UTC)
4. UUIDs are version 4
5. Transactions are atomic and use database transactions
6. Commission rates are configurable via environment variables
7. Distance calculations use the Haversine formula for accuracy
