# TCC Backend - Quick Setup Guide

This guide will help you get the backend up and running quickly.

## Quick Start (5 minutes)

### Step 1: Install Dependencies

```bash
cd tcc_backend
npm install
```

### Step 2: Set Up Database

1. **Create PostgreSQL database:**

```bash
# Option 1: Using createdb command
createdb tcc_database

# Option 2: Using psql
psql -U postgres
CREATE DATABASE tcc_database;
\q
```

2. **Run the schema:**

```bash
# From the tcc_backend directory
psql -U postgres -d tcc_database -f ../database_schema.sql
```

You should see output creating all tables, indexes, and seed data.

### Step 3: Configure Environment

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your database credentials
# At minimum, update:
# - DB_PASSWORD (your PostgreSQL password)
# - JWT_SECRET (any random string for now)
# - JWT_REFRESH_SECRET (any random string for now)
```

**Quick .env example:**

```env
NODE_ENV=development
PORT=3000

# Update these:
DB_PASSWORD=your_postgres_password
JWT_SECRET=my-secret-key-for-development-123456
JWT_REFRESH_SECRET=my-refresh-secret-key-for-development-123456
```

### Step 4: Start the Server

```bash
npm run dev
```

You should see:

```
✓ Database connection test successful
✓ Server started successfully on port 3000
```

### Step 5: Test It

Open your browser or use curl:

```bash
curl http://localhost:3000/health
```

You should get:

```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "timestamp": "2025-10-26T...",
    "uptime": 1.234,
    "database": "connected",
    "memory": {
      "used": 45,
      "total": 100
    }
  }
}
```

## What's Next?

Now that the backend is running, you need to implement the API endpoints. Here's the recommended order:

### Phase 1: Authentication (Priority 1)

Implement these endpoints first:

1. `POST /v1/auth/register` - User registration
2. `POST /v1/auth/verify-otp` - OTP verification
3. `POST /v1/auth/login` - User login
4. `POST /v1/auth/refresh` - Refresh access token
5. `POST /v1/auth/logout` - Logout

**Files to create:**
- `src/controllers/auth.controller.ts`
- `src/services/auth.service.ts`
- `src/repositories/user.repository.ts`
- `src/routes/auth.routes.ts`
- `src/validators/auth.validators.ts`

### Phase 2: User Management (Priority 2)

1. `GET /v1/users/profile`
2. `PATCH /v1/users/profile`
3. `POST /v1/users/change-password`

### Phase 3: KYC (Priority 3)

1. `POST /v1/kyc/submit`
2. `GET /v1/kyc/status`

### Phase 4: Wallet & Transactions (Priority 4)

1. `GET /v1/wallet/balance`
2. `POST /v1/transactions/deposit`
3. `POST /v1/transactions/withdraw`
4. `POST /v1/transactions/transfer`
5. `GET /v1/transactions/history`

### Phase 5: Other Features

- Investments
- Bill Payments
- E-Voting
- Agent System
- Admin Panel

## Project Structure Example

Here's how to structure a feature (using Auth as an example):

```
src/
├── controllers/
│   └── auth.controller.ts       # Handles HTTP requests
├── services/
│   └── auth.service.ts          # Business logic
├── repositories/
│   └── user.repository.ts       # Database queries
├── routes/
│   └── auth.routes.ts           # Route definitions
├── validators/
│   └── auth.validators.ts       # Zod schemas
└── types/
    └── auth.types.ts            # TypeScript interfaces
```

## Example Implementation

### 1. Create Validator (`src/validators/auth.validators.ts`)

```typescript
import { z } from 'zod';

export const registerSchema = z.object({
  body: z.object({
    first_name: z.string().min(2).max(100),
    last_name: z.string().min(2).max(100),
    email: z.string().email(),
    phone: z.string().regex(/^232[0-9]{9}$/),
    password: z.string().min(8),
  }),
});
```

### 2. Create Repository (`src/repositories/user.repository.ts`)

```typescript
import database from '../database';
import { User } from '../types';

export class UserRepository {
  async createUser(userData: Partial<User>): Promise<User> {
    const query = `
      INSERT INTO users (first_name, last_name, email, phone, password_hash)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `;
    const values = [
      userData.first_name,
      userData.last_name,
      userData.email,
      userData.phone,
      userData.password_hash,
    ];
    const result = await database.query<User>(query, values);
    return result[0];
  }

  async findByEmail(email: string): Promise<User | null> {
    const query = 'SELECT * FROM users WHERE email = $1';
    const result = await database.query<User>(query, [email]);
    return result[0] || null;
  }
}
```

### 3. Create Service (`src/services/auth.service.ts`)

```typescript
import { UserRepository } from '../repositories/user.repository';
import { PasswordUtils } from '../utils/password';
import { JWTUtils } from '../utils/jwt';

export class AuthService {
  private userRepo = new UserRepository();

  async register(userData: any) {
    // Check if user exists
    const existing = await this.userRepo.findByEmail(userData.email);
    if (existing) {
      throw new Error('User already exists');
    }

    // Hash password
    const password_hash = await PasswordUtils.hash(userData.password);

    // Create user
    const user = await this.userRepo.createUser({
      ...userData,
      password_hash,
    });

    // Generate tokens
    const accessToken = JWTUtils.generateAccessToken(
      user.id,
      user.role,
      user.email
    );

    return { user, accessToken };
  }
}
```

### 4. Create Controller (`src/controllers/auth.controller.ts`)

```typescript
import { Request, Response, NextFunction } from 'express';
import { AuthService } from '../services/auth.service';
import { ApiResponseUtil } from '../utils/response';

export class AuthController {
  private authService = new AuthService();

  register = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await this.authService.register(req.body);
      return ApiResponseUtil.success(res, result, 201);
    } catch (error) {
      next(error);
    }
  };
}
```

### 5. Create Routes (`src/routes/auth.routes.ts`)

```typescript
import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { validate } from '../middleware/validation';
import { registerSchema } from '../validators/auth.validators';
import { authRateLimiter } from '../middleware/rateLimit';

const router = Router();
const controller = new AuthController();

router.post(
  '/register',
  authRateLimiter,
  validate(registerSchema),
  controller.register
);

export default router;
```

### 6. Register Routes (`src/app.ts`)

```typescript
import authRoutes from './routes/auth.routes';

// In initializeRoutes():
this.app.use(`/${config.apiVersion}/auth`, authRoutes);
```

## Database Queries

### Using the Database Client

```typescript
// Simple query
const users = await database.query<User>('SELECT * FROM users WHERE id = $1', [
  userId,
]);

// Transaction
await database.transaction(async (client) => {
  await client.query('UPDATE wallets SET balance = balance - $1', [amount]);
  await client.query('INSERT INTO transactions (...) VALUES (...)');
});
```

## Common Issues

### 1. Database Connection Failed

```bash
# Check PostgreSQL is running
pg_isready

# Check credentials in .env
# Make sure DB_PASSWORD matches your PostgreSQL password
```

### 2. TypeScript Errors

```bash
# Install types
npm install --save-dev @types/node @types/express

# Rebuild
npm run build
```

### 3. Port 3000 Already in Use

```bash
# Change PORT in .env to 3001 or another port
PORT=3001
```

## Testing Your Endpoints

Use Postman, Insomnia, or curl:

```bash
# Register user
curl -X POST http://localhost:3000/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "phone": "232123456789",
    "password": "SecurePass123!"
  }'

# Login
curl -X POST http://localhost:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "SecurePass123!"
  }'
```

## Next Steps

1. ✅ Backend is running
2. ⏳ Implement authentication endpoints
3. ⏳ Implement user management
4. ⏳ Implement wallet & transactions
5. ⏳ Test with Flutter mobile app
6. ⏳ Deploy to production

## Resources

- Full API Specification: `../api_specification.md`
- Database Schema: `../database_schema.sql`
- Currency Utilities: `../currency_formatting_utilities.md`
- Design System: `../design_system.md`

## Need Help?

- Check the full README.md for detailed documentation
- Review the API specification for endpoint details
- Check the database schema for table structures
- Look at the example code above

Happy coding! 🚀
