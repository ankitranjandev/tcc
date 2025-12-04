# Poll/Voting System - Quick Start Guide

## Setup

1. **Install Dependencies**
```bash
cd tcc_backend
npm install
```

2. **Start Server**
```bash
npm run dev
```

## Testing the API

### 1. Create a Poll (Admin)

**Request:**
```bash
curl -X POST http://localhost:3000/api/v1/polls/admin/create \
  -H "Authorization: Bearer {ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Best Programming Language 2024",
    "description": "Which programming language is best for backend development?",
    "vote_charge": 50,
    "options": ["JavaScript", "Python", "Go", "Rust"],
    "start_date": "2024-01-01T00:00:00Z",
    "end_date": "2024-12-31T23:59:59Z"
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "poll": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Best Programming Language 2024",
      "status": "DRAFT",
      ...
    }
  },
  "message": "Poll created successfully. Publish it to make it active."
}
```

### 2. Publish Poll (Admin)

**Request:**
```bash
curl -X PUT http://localhost:3000/api/v1/polls/admin/{POLL_ID}/publish \
  -H "Authorization: Bearer {ADMIN_TOKEN}"
```

**Response:**
```json
{
  "success": true,
  "data": {
    "poll": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "status": "ACTIVE",
      ...
    }
  },
  "message": "Poll published successfully"
}
```

### 3. View Active Polls (Public)

**Request:**
```bash
curl http://localhost:3000/api/v1/polls/active
```

**Response:**
```json
{
  "success": true,
  "data": {
    "polls": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "title": "Best Programming Language 2024",
        "question": "Which programming language is best for backend development?",
        "options": ["JavaScript", "Python", "Go", "Rust"],
        "voting_charge": 50,
        "total_votes": 0,
        "has_voted": false,
        "user_vote": null
      }
    ],
    "count": 1
  }
}
```

### 4. Request Vote OTP (User)

**Request:**
```bash
curl -X POST http://localhost:3000/api/v1/polls/vote/request-otp \
  -H "Authorization: Bearer {USER_TOKEN}"
```

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

### 5. Cast Vote (User)

**Request:**
```bash
curl -X POST http://localhost:3000/api/v1/polls/vote \
  -H "Authorization: Bearer {USER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "poll_id": "550e8400-e29b-41d4-a716-446655440000",
    "selected_option": "JavaScript",
    "otp": "123456"
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "vote": {
      "id": "660e8400-e29b-41d4-a716-446655440001",
      "poll_id": "550e8400-e29b-41d4-a716-446655440000",
      "selected_option": "JavaScript",
      "amount_paid": 50,
      "voted_at": "2024-06-15T10:30:00Z"
    },
    "transaction": {
      "id": "770e8400-e29b-41d4-a716-446655440002",
      "transaction_id": "TXN202406151234567",
      "amount": 50,
      "status": "COMPLETED",
      "created_at": "2024-06-15T10:30:00Z"
    },
    "poll_title": "Best Programming Language 2024"
  },
  "message": "Vote cast successfully"
}
```

### 6. View Poll Results (After Voting)

**Request:**
```bash
curl http://localhost:3000/api/v1/polls/{POLL_ID} \
  -H "Authorization: Bearer {USER_TOKEN}"
```

**Response:**
```json
{
  "success": true,
  "data": {
    "poll": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Best Programming Language 2024",
      "has_voted": true,
      "user_vote": {
        "selected_option": "JavaScript",
        "amount_paid": 50,
        "voted_at": "2024-06-15T10:30:00Z"
      },
      "results": [
        {
          "option": "JavaScript",
          "votes": 15,
          "percentage": 50.0
        },
        {
          "option": "Python",
          "votes": 8,
          "percentage": 26.67
        },
        {
          "option": "Go",
          "votes": 5,
          "percentage": 16.67
        },
        {
          "option": "Rust",
          "votes": 2,
          "percentage": 6.66
        }
      ],
      "show_results": true,
      "total_votes": 30,
      "total_revenue": 1500
    }
  }
}
```

### 7. View Voting History (User)

**Request:**
```bash
curl http://localhost:3000/api/v1/polls/my/votes \
  -H "Authorization: Bearer {USER_TOKEN}"
```

**Response:**
```json
{
  "success": true,
  "data": {
    "votes": [
      {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "poll_id": "550e8400-e29b-41d4-a716-446655440000",
        "poll_title": "Best Programming Language 2024",
        "poll_question": "Which programming language is best for backend development?",
        "poll_status": "ACTIVE",
        "selected_option": "JavaScript",
        "amount_paid": 50,
        "transaction_id": "TXN202406151234567",
        "voted_at": "2024-06-15T10:30:00Z"
      }
    ],
    "count": 1
  }
}
```

### 8. View Revenue Analytics (Admin)

**Request:**
```bash
curl http://localhost:3000/api/v1/polls/admin/{POLL_ID}/revenue \
  -H "Authorization: Bearer {ADMIN_TOKEN}"
```

**Response:**
```json
{
  "success": true,
  "data": {
    "analytics": {
      "poll": {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "title": "Best Programming Language 2024",
        "status": "ACTIVE",
        "voting_charge": 50
      },
      "summary": {
        "total_votes": 30,
        "total_revenue": 1500,
        "average_revenue_per_vote": 50
      },
      "revenue_by_option": [
        {
          "option": "JavaScript",
          "votes": 15,
          "percentage": 50.0,
          "revenue": 750
        },
        {
          "option": "Python",
          "votes": 8,
          "percentage": 26.67,
          "revenue": 400
        },
        {
          "option": "Go",
          "votes": 5,
          "percentage": 16.67,
          "revenue": 250
        },
        {
          "option": "Rust",
          "votes": 2,
          "percentage": 6.66,
          "revenue": 100
        }
      ],
      "votes_by_date": [
        {
          "date": "2024-06-15",
          "votes": 15,
          "revenue": 750
        },
        {
          "date": "2024-06-14",
          "votes": 10,
          "revenue": 500
        },
        {
          "date": "2024-06-13",
          "votes": 5,
          "revenue": 250
        }
      ]
    }
  }
}
```

## Testing Error Cases

### 1. Vote Without Sufficient Balance

**Request:**
```bash
curl -X POST http://localhost:3000/api/v1/polls/vote \
  -H "Authorization: Bearer {USER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "poll_id": "550e8400-e29b-41d4-a716-446655440000",
    "selected_option": "JavaScript",
    "otp": "123456"
  }'
```

**Response:**
```json
{
  "success": false,
  "error": {
    "code": "BAD_REQUEST",
    "message": "Insufficient wallet balance to cast vote"
  }
}
```

### 2. Vote Twice on Same Poll

**Request:** (Second vote attempt)
```bash
curl -X POST http://localhost:3000/api/v1/polls/vote \
  -H "Authorization: Bearer {USER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "poll_id": "550e8400-e29b-41d4-a716-446655440000",
    "selected_option": "Python",
    "otp": "123456"
  }'
```

**Response:**
```json
{
  "success": false,
  "error": {
    "code": "BAD_REQUEST",
    "message": "You have already voted on this poll"
  }
}
```

### 3. Create Poll as Non-Admin

**Request:**
```bash
curl -X POST http://localhost:3000/api/v1/polls/admin/create \
  -H "Authorization: Bearer {USER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Poll",
    "description": "Test Description",
    "vote_charge": 10,
    "options": ["A", "B"],
    "start_date": "2024-01-01T00:00:00Z",
    "end_date": "2024-12-31T23:59:59Z"
  }'
```

**Response:**
```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "You do not have permission to access this resource"
  }
}
```

### 4. Invalid OTP

**Request:**
```bash
curl -X POST http://localhost:3000/api/v1/polls/vote \
  -H "Authorization: Bearer {USER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "poll_id": "550e8400-e29b-41d4-a716-446655440000",
    "selected_option": "JavaScript",
    "otp": "000000"
  }'
```

**Response:**
```json
{
  "success": false,
  "error": {
    "code": "BAD_REQUEST",
    "message": "Invalid or expired OTP"
  }
}
```

## Postman Collection

Import this JSON into Postman:

```json
{
  "info": {
    "name": "TCC Poll/Voting API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "User Endpoints",
      "item": [
        {
          "name": "Get Active Polls",
          "request": {
            "method": "GET",
            "url": "{{base_url}}/polls/active"
          }
        },
        {
          "name": "Get Poll Details",
          "request": {
            "method": "GET",
            "url": "{{base_url}}/polls/{{poll_id}}"
          }
        },
        {
          "name": "Request Vote OTP",
          "request": {
            "method": "POST",
            "url": "{{base_url}}/polls/vote/request-otp",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{user_token}}"
              }
            ]
          }
        },
        {
          "name": "Cast Vote",
          "request": {
            "method": "POST",
            "url": "{{base_url}}/polls/vote",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{user_token}}"
              },
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"poll_id\": \"{{poll_id}}\",\n  \"selected_option\": \"JavaScript\",\n  \"otp\": \"123456\"\n}"
            }
          }
        },
        {
          "name": "Get Voting History",
          "request": {
            "method": "GET",
            "url": "{{base_url}}/polls/my/votes",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{user_token}}"
              }
            ]
          }
        }
      ]
    },
    {
      "name": "Admin Endpoints",
      "item": [
        {
          "name": "Create Poll",
          "request": {
            "method": "POST",
            "url": "{{base_url}}/polls/admin/create",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{admin_token}}"
              },
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"title\": \"Best Programming Language 2024\",\n  \"description\": \"Which programming language is best for backend development?\",\n  \"vote_charge\": 50,\n  \"options\": [\"JavaScript\", \"Python\", \"Go\", \"Rust\"],\n  \"start_date\": \"2024-01-01T00:00:00Z\",\n  \"end_date\": \"2024-12-31T23:59:59Z\"\n}"
            }
          }
        },
        {
          "name": "Publish Poll",
          "request": {
            "method": "PUT",
            "url": "{{base_url}}/polls/admin/{{poll_id}}/publish",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{admin_token}}"
              }
            ]
          }
        },
        {
          "name": "Get Poll Revenue",
          "request": {
            "method": "GET",
            "url": "{{base_url}}/polls/admin/{{poll_id}}/revenue",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{admin_token}}"
              }
            ]
          }
        }
      ]
    }
  ],
  "variable": [
    {
      "key": "base_url",
      "value": "http://localhost:3000/api/v1"
    },
    {
      "key": "user_token",
      "value": "YOUR_USER_TOKEN"
    },
    {
      "key": "admin_token",
      "value": "YOUR_ADMIN_TOKEN"
    },
    {
      "key": "poll_id",
      "value": "550e8400-e29b-41d4-a716-446655440000"
    }
  ]
}
```

## Database Queries for Verification

### Check Poll Creation
```sql
SELECT id, title, status, voting_charge, total_votes, total_revenue
FROM polls
ORDER BY created_at DESC
LIMIT 10;
```

### Check Votes
```sql
SELECT v.id, p.title, u.email, v.selected_option, v.amount_paid, v.voted_at
FROM votes v
JOIN polls p ON v.poll_id = p.id
JOIN users u ON v.user_id = u.id
ORDER BY v.voted_at DESC
LIMIT 10;
```

### Check Transactions
```sql
SELECT id, transaction_id, type, amount, status, description, created_at
FROM transactions
WHERE type = 'VOTE'
ORDER BY created_at DESC
LIMIT 10;
```

### Check User Wallet Balance
```sql
SELECT u.email, w.balance, w.last_transaction_at
FROM users u
JOIN wallets w ON u.id = w.user_id
WHERE u.email = 'user@example.com';
```

### Poll Results Summary
```sql
SELECT
  p.title,
  p.status,
  p.total_votes,
  p.total_revenue,
  p.results
FROM polls p
WHERE p.id = 'YOUR_POLL_ID';
```

## Common Issues & Solutions

### 1. OTP Not Received
- Check OTP service configuration
- Verify phone number format
- Check SMS service integration
- In development, OTP is logged in console

### 2. Insufficient Balance
- Top up wallet using deposit endpoint
- Check minimum vote charge requirement
- Verify wallet exists for user

### 3. Poll Not Active
- Verify poll status is ACTIVE
- Check start_time and end_time
- Ensure poll was published by admin

### 4. Results Not Visible
- User must vote first OR poll must be ended
- Check show_results flag in response
- Verify poll end_time

### 5. Admin Access Denied
- Verify user has ADMIN or SUPER_ADMIN role
- Check JWT token is valid
- Confirm user is in admins table

## Next Steps

1. Test all endpoints with different scenarios
2. Monitor database for data integrity
3. Check transaction records
4. Verify wallet balances
5. Review revenue analytics
6. Test with multiple concurrent votes
7. Verify one-vote-per-poll constraint
8. Test with different poll statuses
9. Check error handling for edge cases
10. Load test with many votes

## Support

For issues or questions:
- Check logs: `tail -f logs/app.log`
- Review error responses
- Verify database state
- Check authentication tokens
- Consult POLL_API_DOCUMENTATION.md
