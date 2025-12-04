# Poll/Voting API Documentation

## Overview
The TCC Poll/Voting system allows administrators to create polls for e-voting, and users can vote by paying from their wallet balance. This document describes all available endpoints.

---

## Base URL
```
/api/v1/polls
```

---

## User Endpoints

### 1. Get Active Polls
Get all currently active polls.

**Endpoint:** `GET /polls/active`
**Access:** Public (shows voting status if authenticated)
**Authentication:** Optional

**Response:**
```json
{
  "success": true,
  "data": {
    "polls": [
      {
        "id": "uuid",
        "title": "Presidential Election 2024",
        "question": "Who should be the next president?",
        "options": ["Candidate A", "Candidate B", "Candidate C"],
        "voting_charge": 100.00,
        "start_time": "2024-01-01T00:00:00Z",
        "end_time": "2024-12-31T23:59:59Z",
        "status": "ACTIVE",
        "total_votes": 1500,
        "has_voted": false,
        "user_vote": null,
        "created_at": "2023-12-01T00:00:00Z"
      }
    ],
    "count": 1
  }
}
```

---

### 2. Get Poll Details
Get detailed information about a specific poll including results (visible only after voting or poll end).

**Endpoint:** `GET /polls/:pollId`
**Access:** Public (shows user vote if authenticated)
**Authentication:** Optional

**Response:**
```json
{
  "success": true,
  "data": {
    "poll": {
      "id": "uuid",
      "title": "Presidential Election 2024",
      "question": "Who should be the next president?",
      "options": ["Candidate A", "Candidate B", "Candidate C"],
      "voting_charge": 100.00,
      "start_time": "2024-01-01T00:00:00Z",
      "end_time": "2024-12-31T23:59:59Z",
      "status": "ACTIVE",
      "total_votes": 1500,
      "total_revenue": 150000.00,
      "has_voted": true,
      "user_vote": {
        "selected_option": "Candidate A",
        "amount_paid": 100.00,
        "voted_at": "2024-06-15T10:30:00Z"
      },
      "results": [
        {
          "option": "Candidate A",
          "votes": 600,
          "percentage": 40.00
        },
        {
          "option": "Candidate B",
          "votes": 500,
          "percentage": 33.33
        },
        {
          "option": "Candidate C",
          "votes": 400,
          "percentage": 26.67
        }
      ],
      "show_results": true,
      "created_at": "2023-12-01T00:00:00Z",
      "updated_at": "2024-06-15T10:30:00Z"
    }
  }
}
```

**Note:** `results` field is only visible if:
- User has already voted on the poll
- Poll has ended
- Poll status is CLOSED

---

### 3. Request Vote OTP
Request an OTP for voting on a poll.

**Endpoint:** `POST /polls/vote/request-otp`
**Access:** Private (USER)
**Authentication:** Required

**Response:**
```json
{
  "success": true,
  "data": {
    "otp_sent": true,
    "phone": "****1234",
    "otp_expires_in": 300
  },
  "message": "OTP sent to your registered phone number"
}
```

---

### 4. Cast Vote
Cast a vote on a poll. Requires payment from wallet balance.

**Endpoint:** `POST /polls/vote`
**Access:** Private (USER)
**Authentication:** Required

**Request Body:**
```json
{
  "poll_id": "uuid",
  "selected_option": "Candidate A",
  "otp": "123456"
}
```

**Validation:**
- `poll_id`: Required, must be valid UUID
- `selected_option`: Required, must match one of the poll options
- `otp`: Required, must be 6 digits

**Response:**
```json
{
  "success": true,
  "data": {
    "vote": {
      "id": "uuid",
      "poll_id": "uuid",
      "selected_option": "Candidate A",
      "amount_paid": 100.00,
      "voted_at": "2024-06-15T10:30:00Z"
    },
    "transaction": {
      "id": "uuid",
      "transaction_id": "TXN202406151234567",
      "amount": 100.00,
      "status": "COMPLETED",
      "created_at": "2024-06-15T10:30:00Z"
    },
    "poll_title": "Presidential Election 2024"
  },
  "message": "Vote cast successfully"
}
```

**Error Responses:**
- `400 Bad Request`: Poll not active, already voted, insufficient balance, invalid OTP
- `404 Not Found`: Poll not found, user not found
- `401 Unauthorized`: Missing or invalid authentication token

**Business Rules:**
- User can only vote once per poll
- Poll must be in ACTIVE status
- Current time must be between poll start_time and end_time
- User must have sufficient wallet balance (voting_charge)
- Valid OTP is required for verification
- Payment is deducted from wallet immediately
- Results become visible to user after voting

---

### 5. Get User Voting History
Get all polls the user has voted on.

**Endpoint:** `GET /polls/my/votes`
**Access:** Private (USER)
**Authentication:** Required

**Response:**
```json
{
  "success": true,
  "data": {
    "votes": [
      {
        "id": "uuid",
        "poll_id": "uuid",
        "poll_title": "Presidential Election 2024",
        "poll_question": "Who should be the next president?",
        "poll_status": "ACTIVE",
        "poll_end_time": "2024-12-31T23:59:59Z",
        "selected_option": "Candidate A",
        "amount_paid": 100.00,
        "transaction_id": "TXN202406151234567",
        "voted_at": "2024-06-15T10:30:00Z"
      }
    ],
    "count": 1
  }
}
```

---

## Admin Endpoints

### 6. Create Poll
Create a new poll in DRAFT status.

**Endpoint:** `POST /polls/admin/create`
**Access:** Private (ADMIN, SUPER_ADMIN)
**Authentication:** Required
**Authorization:** ADMIN or SUPER_ADMIN role

**Request Body:**
```json
{
  "title": "Presidential Election 2024",
  "description": "Who should be the next president?",
  "vote_charge": 100.00,
  "options": ["Candidate A", "Candidate B", "Candidate C"],
  "start_date": "2024-01-01T00:00:00Z",
  "end_date": "2024-12-31T23:59:59Z"
}
```

**Validation:**
- `title`: Required, 5-255 characters
- `description`: Required, 10-1000 characters
- `vote_charge`: Required, must be >= 0
- `options`: Required, array of 2-10 strings, each 1-255 characters
- `start_date`: Required, valid ISO date string
- `end_date`: Required, valid ISO date string, must be after start_date

**Response:**
```json
{
  "success": true,
  "data": {
    "poll": {
      "id": "uuid",
      "title": "Presidential Election 2024",
      "question": "Who should be the next president?",
      "options": ["Candidate A", "Candidate B", "Candidate C"],
      "voting_charge": 100.00,
      "start_time": "2024-01-01T00:00:00Z",
      "end_time": "2024-12-31T23:59:59Z",
      "status": "DRAFT",
      "total_votes": 0,
      "total_revenue": 0.00,
      "created_at": "2023-12-01T00:00:00Z",
      "updated_at": "2023-12-01T00:00:00Z"
    }
  },
  "message": "Poll created successfully. Publish it to make it active."
}
```

**Error Responses:**
- `400 Bad Request`: Invalid input, validation errors
- `403 Forbidden`: Not an admin user
- `401 Unauthorized`: Missing or invalid authentication token

---

### 7. Publish Poll
Change poll status from DRAFT to ACTIVE.

**Endpoint:** `PUT /polls/admin/:pollId/publish`
**Access:** Private (ADMIN, SUPER_ADMIN)
**Authentication:** Required
**Authorization:** ADMIN or SUPER_ADMIN role

**Response:**
```json
{
  "success": true,
  "data": {
    "poll": {
      "id": "uuid",
      "title": "Presidential Election 2024",
      "question": "Who should be the next president?",
      "options": ["Candidate A", "Candidate B", "Candidate C"],
      "voting_charge": 100.00,
      "start_time": "2024-01-01T00:00:00Z",
      "end_time": "2024-12-31T23:59:59Z",
      "status": "ACTIVE",
      "total_votes": 0,
      "total_revenue": 0.00,
      "created_at": "2023-12-01T00:00:00Z",
      "updated_at": "2023-12-01T10:00:00Z"
    }
  },
  "message": "Poll published successfully"
}
```

**Error Responses:**
- `400 Bad Request`: Poll not in DRAFT status
- `403 Forbidden`: Not an admin user
- `404 Not Found`: Poll not found
- `401 Unauthorized`: Missing or invalid authentication token

---

### 8. Get Poll Revenue Analytics
Get detailed revenue analytics for a poll including breakdown by option.

**Endpoint:** `GET /polls/admin/:pollId/revenue`
**Access:** Private (ADMIN, SUPER_ADMIN)
**Authentication:** Required
**Authorization:** ADMIN or SUPER_ADMIN role

**Response:**
```json
{
  "success": true,
  "data": {
    "analytics": {
      "poll": {
        "id": "uuid",
        "title": "Presidential Election 2024",
        "question": "Who should be the next president?",
        "status": "ACTIVE",
        "start_time": "2024-01-01T00:00:00Z",
        "end_time": "2024-12-31T23:59:59Z",
        "voting_charge": 100.00
      },
      "summary": {
        "total_votes": 1500,
        "total_revenue": 150000.00,
        "average_revenue_per_vote": 100.00
      },
      "revenue_by_option": [
        {
          "option": "Candidate A",
          "votes": 600,
          "percentage": 40.00,
          "revenue": 60000.00
        },
        {
          "option": "Candidate B",
          "votes": 500,
          "percentage": 33.33,
          "revenue": 50000.00
        },
        {
          "option": "Candidate C",
          "votes": 400,
          "percentage": 26.67,
          "revenue": 40000.00
        }
      ],
      "votes_by_date": [
        {
          "date": "2024-06-15",
          "votes": 150,
          "revenue": 15000.00
        },
        {
          "date": "2024-06-14",
          "votes": 200,
          "revenue": 20000.00
        }
      ]
    }
  }
}
```

**Error Responses:**
- `403 Forbidden`: Not an admin user
- `404 Not Found`: Poll not found
- `401 Unauthorized`: Missing or invalid authentication token

---

## Poll Status Flow

```
DRAFT → ACTIVE → PAUSED → ACTIVE → CLOSED
  ↑       ↓
  └───────┘
(Only DRAFT can be published to ACTIVE)
```

**Status Definitions:**
- **DRAFT**: Poll created but not yet visible to users
- **ACTIVE**: Poll is live and accepting votes
- **PAUSED**: Poll temporarily stopped (can be resumed to ACTIVE)
- **CLOSED**: Poll ended permanently

---

## Database Tables

### polls
- `id`: UUID (Primary Key)
- `title`: VARCHAR(255)
- `question`: TEXT
- `options`: JSONB (Array of strings)
- `voting_charge`: DECIMAL(15,2)
- `start_time`: TIMESTAMP WITH TIME ZONE
- `end_time`: TIMESTAMP WITH TIME ZONE
- `status`: poll_status ENUM
- `created_by_admin_id`: UUID (Foreign Key → users.id)
- `total_votes`: INT
- `total_revenue`: DECIMAL(15,2)
- `results`: JSONB (Option → vote count mapping)
- `created_at`: TIMESTAMP WITH TIME ZONE
- `updated_at`: TIMESTAMP WITH TIME ZONE

### votes
- `id`: UUID (Primary Key)
- `poll_id`: UUID (Foreign Key → polls.id)
- `user_id`: UUID (Foreign Key → users.id)
- `selected_option`: VARCHAR(255)
- `amount_paid`: DECIMAL(15,2)
- `transaction_id`: UUID (Foreign Key → transactions.id)
- `voted_at`: TIMESTAMP WITH TIME ZONE
- **Unique Constraint**: (poll_id, user_id) - One vote per user per poll

---

## Transaction Integration

When a user votes:
1. Vote charge is deducted from user's wallet
2. A transaction record is created with type = 'VOTE'
3. Transaction status is 'COMPLETED' immediately
4. Wallet balance is updated atomically
5. Vote record is created linking to transaction

Transaction metadata includes:
```json
{
  "poll_id": "uuid",
  "selected_option": "Candidate A"
}
```

---

## Security Features

1. **OTP Verification**: Required for casting votes
2. **One Vote Per Poll**: Enforced at database level (unique constraint)
3. **Balance Check**: Ensures sufficient funds before voting
4. **Atomic Transactions**: Wallet deduction and vote recording in single transaction
5. **Results Privacy**: Results hidden until user votes or poll ends
6. **Admin Only**: Poll creation/management restricted to ADMIN/SUPER_ADMIN
7. **Role-Based Access**: Proper authorization middleware

---

## Error Codes

| Code | Message | Description |
|------|---------|-------------|
| `POLL_NOT_FOUND` | Poll not found | Invalid poll ID |
| `POLL_NOT_ACTIVE` | Poll is not active | Poll status is not ACTIVE |
| `POLL_NOT_STARTED` | Poll has not started yet | Current time before start_time |
| `POLL_ENDED` | Poll has ended | Current time after end_time |
| `INVALID_OPTION` | Invalid option selected | Selected option not in poll options |
| `ALREADY_VOTED` | You have already voted on this poll | Duplicate vote attempt |
| `INSUFFICIENT_BALANCE` | Insufficient wallet balance | Not enough funds to vote |
| `INVALID_OTP` | Invalid or expired OTP | OTP verification failed |
| `UNAUTHORIZED_ADMIN` | Admin access required | User is not ADMIN/SUPER_ADMIN |
| `POLL_NOT_IN_DRAFT_STATUS` | Only draft polls can be published | Trying to publish non-draft poll |

---

## Example Use Cases

### User Voting Flow
1. User views active polls: `GET /polls/active`
2. User views poll details: `GET /polls/:pollId`
3. User requests OTP: `POST /polls/vote/request-otp`
4. User casts vote: `POST /polls/vote` (with OTP)
5. User views results: `GET /polls/:pollId` (results now visible)

### Admin Poll Creation Flow
1. Admin creates poll: `POST /polls/admin/create` (status: DRAFT)
2. Admin reviews poll (internal)
3. Admin publishes poll: `PUT /polls/admin/:pollId/publish` (status: ACTIVE)
4. Users can now vote
5. Admin monitors revenue: `GET /polls/admin/:pollId/revenue`

---

## Best Practices

1. **Testing**: Use test mode with small vote_charge amounts
2. **Timing**: Set appropriate start_time and end_time with buffer
3. **Options**: Keep options clear and distinct (2-10 options)
4. **Charges**: Set vote_charge based on poll importance
5. **Monitoring**: Regularly check revenue analytics
6. **Status Management**: Use DRAFT status to review before publishing
