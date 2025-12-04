# TCC Backend API

A comprehensive backend API for the TCC (The Community Coin) application - A financial services platform for African markets, specifically Sierra Leone.

## Table of Contents

- [Features](#features)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Database Setup](#database-setup)
- [Running the Application](#running-the-application)
- [API Documentation](#api-documentation)
- [Development](#development)
- [Testing](#testing)
- [Deployment](#deployment)
- [Contributing](#contributing)

## Features

- **Authentication & Authorization**: JWT-based authentication with role-based access control
- **User Management**: Registration, profile management, KYC verification
- **Wallet & Transactions**: Deposits, withdrawals, transfers with transaction history
- **Investment System**: Multiple investment categories (Agriculture, Education, Minerals)
- **Bill Payments**: Pay utilities and other bills
- **E-Voting**: Democratic voting system with paid participation
- **Agent Network**: Agent registration, commission tracking, and management
- **Admin Dashboard**: Comprehensive admin controls and analytics
- **Security**: Rate limiting, password hashing, account lockout, fraud detection
- **File Uploads**: Document management for KYC and receipts
- **Notifications**: Push notifications, email, and SMS support
- **Real-time Updates**: WebSocket support for live updates

## Technology Stack

- **Runtime**: Node.js (v18+)
- **Language**: TypeScript
- **Framework**: Express.js
- **Database**: PostgreSQL
- **Authentication**: JWT (JSON Web Tokens)
- **Password Hashing**: bcrypt
- **Validation**: Zod
- **Logging**: Winston
- **File Upload**: Multer
- **Real-time**: Socket.io
- **Security**: Helmet, CORS, Rate Limiting

## Project Structure

```
tcc_backend/
├── src/
│   ├── config/              # Configuration files
│   │   └── index.ts         # Environment configuration
│   ├── controllers/         # Request handlers
│   ├── services/            # Business logic
│   ├── repositories/        # Database queries
│   ├── middleware/          # Express middleware
│   │   ├── auth.ts          # Authentication middleware
│   │   ├── errorHandler.ts # Error handling
│   │   ├── rateLimit.ts    # Rate limiting
│   │   └── validation.ts   # Request validation
│   ├── routes/              # API routes
│   ├── utils/               # Utility functions
│   │   ├── logger.ts        # Logging utility
│   │   ├── jwt.ts           # JWT utilities
│   │   ├── password.ts      # Password utilities
│   │   └── response.ts      # Response formatting
│   ├── types/               # TypeScript types/interfaces
│   │   └── index.ts         # Common types
│   ├── database/            # Database connection & migrations
│   │   └── index.ts         # Database client
│   ├── app.ts               # Express app setup
│   └── server.ts            # Server entry point
├── uploads/                 # File uploads directory
├── logs/                    # Application logs
├── .env.example             # Environment variables template
├── .gitignore               # Git ignore rules
├── tsconfig.json            # TypeScript configuration
├── package.json             # Dependencies
└── README.md                # This file
```

## Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js**: v18.0.0 or higher
- **npm**: v9.0.0 or higher
- **PostgreSQL**: v14 or higher
- **Git**: For version control

## Installation

1. **Clone the repository**

```bash
cd /path/to/tcc
cd tcc_backend
```

2. **Install dependencies**

```bash
npm install
```

3. **Create environment file**

```bash
cp .env.example .env
```

Then edit `.env` with your configuration (see [Configuration](#configuration) section).

## Configuration

Edit the `.env` file with your settings:

### Essential Configuration

```env
# Environment
NODE_ENV=development

# Server
PORT=3000

# Database (IMPORTANT: Update these!)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=tcc_database
DB_USER=postgres
DB_PASSWORD=your_secure_password

# JWT (IMPORTANT: Change these secrets!)
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-this-in-production
```

### Security Notes

⚠️ **IMPORTANT**:
- Change all default secrets before deploying to production
- Use strong, randomly generated secrets (minimum 32 characters)
- Never commit `.env` file to version control

## Database Setup

1. **Create PostgreSQL database**

```bash
createdb tcc_database
```

Or using psql:

```sql
CREATE DATABASE tcc_database;
```

2. **Run database schema**

The complete database schema is available at `/database_schema.sql` in the project root.

```bash
psql -U postgres -d tcc_database -f ../database_schema.sql
```

This will create:
- 40+ tables with relationships
- Enums for various statuses
- Indexes for performance
- Triggers for automated actions
- Functions for business logic
- Seed data for investment categories

3. **Verify database connection**

```bash
npm run dev
```

Check logs for: `✓ Database connection test successful`

## Running the Application

### Development Mode

```bash
npm run dev
```

This will start the server with hot-reload using nodemon.

### Production Build

```bash
npm run build
npm start
```

### Available Scripts

- `npm run dev` - Start development server with hot-reload
- `npm run build` - Build TypeScript to JavaScript
- `npm start` - Start production server
- `npm run lint` - Run ESLint
- `npm run format` - Format code with Prettier
- `npm test` - Run tests (when implemented)

## API Documentation

### Base URL

```
http://localhost:3000/v1
```

### Health Check

```bash
curl http://localhost:3000/health
```

### Authentication Flow

1. **Register User**
```http
POST /v1/auth/register
Content-Type: application/json

{
  "first_name": "John",
  "last_name": "Doe",
  "email": "john@example.com",
  "phone": "232XXXXXXXX",
  "password": "SecurePass123!"
}
```

2. **Verify OTP** (to be implemented)
```http
POST /v1/auth/verify-otp
```

3. **Login**
```http
POST /v1/auth/login
```

### API Endpoints (To Be Implemented)

Refer to `../api_specification.md` for complete API documentation with 70+ endpoints covering:

- Authentication (`/auth/*`)
- User Management (`/users/*`)
- KYC (`/kyc/*`)
- Wallet & Transactions (`/wallet/*`, `/transactions/*`)
- Investments (`/investments/*`)
- Bill Payments (`/bills/*`)
- E-Voting (`/polls/*`)
- Agents (`/agents/*`)
- Admin (`/admin/*`)
- Notifications (`/notifications/*`)
- File Uploads (`/uploads/*`)

## Development

### Code Style

This project uses:
- **ESLint** for linting
- **Prettier** for code formatting
- **TypeScript** for type safety

Run linting and formatting:

```bash
npm run lint
npm run format
```

### Adding New Features

1. Create service in `src/services/`
2. Create repository in `src/repositories/`
3. Create controller in `src/controllers/`
4. Create routes in `src/routes/`
5. Register routes in `src/app.ts`

### Middleware Usage

```typescript
import { authenticate, authorize } from './middleware/auth';
import { validate } from './middleware/validation';
import { UserRole } from './types';

// Protected route - requires authentication
router.get('/profile', authenticate, controller.getProfile);

// Admin only route
router.get('/admin/users',
  authenticate,
  authorize(UserRole.ADMIN, UserRole.SUPER_ADMIN),
  controller.getAllUsers
);

// Validated route
router.post('/register',
  validate(registerSchema),
  controller.register
);
```

## Testing

```bash
npm test
```

Testing framework is configured but tests need to be implemented.

## Deployment

### Environment Variables

Ensure all production environment variables are set:

- Change all secret keys
- Set `NODE_ENV=production`
- Configure production database
- Set up email/SMS providers
- Configure file storage (S3, etc.)

### Production Checklist

- [ ] Update all secrets in `.env`
- [ ] Set `NODE_ENV=production`
- [ ] Configure SSL/TLS
- [ ] Set up reverse proxy (nginx)
- [ ] Configure firewall rules
- [ ] Set up database backups
- [ ] Configure monitoring and logging
- [ ] Set up CI/CD pipeline
- [ ] Configure file uploads to cloud storage
- [ ] Set up email service (SendGrid, AWS SES, etc.)
- [ ] Set up SMS service
- [ ] Enable database SSL
- [ ] Configure CORS for production domain

### Docker (Optional)

A Dockerfile can be added for containerized deployment.

## Architecture

### Layered Architecture

```
┌─────────────────────────────────────┐
│         Controllers                  │  ← HTTP request handlers
├─────────────────────────────────────┤
│          Services                    │  ← Business logic
├─────────────────────────────────────┤
│        Repositories                  │  ← Database access
├─────────────────────────────────────┤
│         Database                     │  ← PostgreSQL
└─────────────────────────────────────┘
```

### Security Layers

- Rate limiting on all endpoints
- JWT authentication
- Role-based authorization
- Password hashing with bcrypt
- Input validation with Zod
- SQL injection prevention
- XSS protection
- CSRF protection
- Account lockout after failed attempts

## Database Schema Highlights

- **Users**: Multi-role support (USER, AGENT, ADMIN, SUPER_ADMIN)
- **Wallets**: Balance tracking in SLL (Sierra Leonean Leone)
- **Transactions**: Complete audit trail with fees and status
- **Investments**: Multiple categories with tenure-based returns
- **Agents**: Location-based with commission tracking
- **Polls**: E-voting with revenue tracking
- **Notifications**: Multi-channel support
- **Audit Logs**: Comprehensive tracking of all changes

## Currency

All monetary values use **SLL (Sierra Leonean Leone)**:
- Stored as `DECIMAL(15, 2)` in database
- Formatted using utilities in `../currency_formatting_utilities.md`

## Troubleshooting

### Database Connection Issues

```bash
# Check PostgreSQL is running
pg_isready

# Check database exists
psql -l | grep tcc_database

# Test connection manually
psql -U postgres -d tcc_database
```

### Port Already in Use

```bash
# Find process using port 3000
lsof -i :3000

# Kill the process
kill -9 <PID>
```

### TypeScript Errors

```bash
# Clean build
rm -rf dist/
npm run build
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License - See LICENSE file for details

## Support

For issues and questions:
- Create an issue in the repository
- Contact: support@tccapp.com

## Roadmap

- [ ] Implement all 70+ API endpoints
- [ ] Add unit and integration tests
- [ ] Set up CI/CD pipeline
- [ ] Add API documentation (Swagger/OpenAPI)
- [ ] Implement WebSocket for real-time updates
- [ ] Add email and SMS service integrations
- [ ] Implement cron jobs for scheduled tasks
- [ ] Add file upload to cloud storage
- [ ] Implement advanced fraud detection
- [ ] Add performance monitoring
- [ ] Create admin dashboard API
- [ ] Add analytics and reporting endpoints

---

**Built with ❤️ for African Financial Inclusion**
