import { Router } from 'express';
import { AdminController } from '../controllers/admin.controller';
import { authenticate, authorize } from '../middleware/auth';
import { validate } from '../middleware/validation';
import { UserRole } from '../types';
import { z } from 'zod';

const router = Router();

// Validation schemas
const loginSchema = z.object({
  body: z.object({
    email: z.string().email(),
    password: z.string().min(1),
    totp_code: z.string().length(6).optional(),
  }),
});

const reviewWithdrawalSchema = z.object({
  body: z.object({
    withdrawal_id: z.string().uuid(),
    status: z.enum(['COMPLETED', 'REJECTED']),
    reason: z.string().optional(),
  }),
});

const reviewAgentCreditSchema = z.object({
  body: z.object({
    request_id: z.string().uuid(),
    status: z.enum(['COMPLETED', 'REJECTED']),
    reason: z.string().optional(),
  }),
});

const updateSystemConfigSchema = z.object({
  body: z.object({
    config: z.record(z.any()),
  }),
});

const getUsersSchema = z.object({
  query: z.object({
    search: z.string().optional(),
    role: z.enum(['USER', 'AGENT', 'ADMIN', 'SUPER_ADMIN']).optional(),
    kyc_status: z.enum(['PENDING', 'SUBMITTED', 'APPROVED', 'REJECTED']).optional(),
    is_active: z.string().optional(),
    page: z.string().optional(),
    limit: z.string().optional(),
  }),
});

const createUserSchema = z.object({
  body: z.object({
    first_name: z.string().min(1),
    last_name: z.string().min(1),
    email: z.string().email(),
    password: z.string().min(8),
    phone: z.string().optional(),
    country_code: z.string().optional(),
    role: z.enum(['USER', 'AGENT', 'ADMIN']).optional(),
  }),
});

const updateUserStatusSchema = z.object({
  params: z.object({
    userId: z.string().uuid(),
  }),
  body: z.object({
    status: z.enum(['ACTIVE', 'INACTIVE', 'SUSPENDED']),
  }),
});

const getWithdrawalsSchema = z.object({
  query: z.object({
    status: z
      .enum(['PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'CANCELLED'])
      .optional(),
    page: z.string().optional(),
    limit: z.string().optional(),
  }),
});

const generateReportSchema = z.object({
  query: z.object({
    type: z.enum(['transactions', 'investments', 'users']),
    format: z.enum(['json', 'csv', 'pdf']).optional(),
    from: z.string().optional(),
    to: z.string().optional(),
  }),
});

const getAnalyticsSchema = z.object({
  query: z.object({
    from: z.string().optional(),
    to: z.string().optional(),
  }),
});

const exportUsersSchema = z.object({
  query: z.object({
    format: z.enum(['csv', 'xlsx', 'pdf']).optional(),
    search: z.string().optional(),
    role: z.enum(['USER', 'AGENT', 'ADMIN', 'SUPER_ADMIN']).optional(),
    status: z.string().optional(),
    kycStatus: z.enum(['PENDING', 'SUBMITTED', 'APPROVED', 'REJECTED']).optional(),
  }),
});

// Public routes (no authentication required)
router.post('/login', validate(loginSchema), AdminController.login);

// Protected routes (require ADMIN or SUPER_ADMIN role)
router.use(authenticate);
router.use(authorize(UserRole.ADMIN, UserRole.SUPER_ADMIN));

// Dashboard
router.get('/dashboard/stats', AdminController.getDashboardStats);
router.get('/analytics', validate(getAnalyticsSchema), AdminController.getAnalyticsKPI);

// User management
router.get('/users', validate(getUsersSchema), AdminController.getUsers);
router.get('/users/export', validate(exportUsersSchema), AdminController.exportUsers);
router.post('/users', validate(createUserSchema), AdminController.createUser);
router.put('/users/:userId/status', validate(updateUserStatusSchema), AdminController.updateUserStatus);

// Agent management
router.get('/agents', AdminController.getAgents);
router.post('/agents', AdminController.createAgent);

// Transaction management
router.get('/transactions', AdminController.getTransactions);

// Withdrawal management
router.get('/withdrawals', validate(getWithdrawalsSchema), AdminController.getWithdrawals);
router.post(
  '/withdrawals/review',
  validate(reviewWithdrawalSchema),
  AdminController.reviewWithdrawal
);

// Agent credit management
router.post(
  '/agent-credits/review',
  validate(reviewAgentCreditSchema),
  AdminController.reviewAgentCredit
);

// System configuration
router.get('/config', AdminController.getSystemConfig);
router.put(
  '/config',
  validate(updateSystemConfigSchema),
  AdminController.updateSystemConfig
);

// Reports
router.get('/reports', validate(generateReportSchema), AdminController.generateReport);
router.get('/reports/transactions', AdminController.getTransactionReport);
router.get('/reports/user-activity', AdminController.getUserActivityReport);
router.get('/reports/revenue', AdminController.getRevenueReport);
router.get('/reports/investments', AdminController.getInvestmentReport);
router.get('/reports/agent-performance', AdminController.getAgentPerformanceReport);

// Bill Payments
router.get('/bill-payments', AdminController.getBillPayments);

// Investments
router.get('/investments', AdminController.getInvestments);

// Wallet management
router.post('/wallet/adjust-balance', AdminController.adjustWalletBalance);
router.get('/wallet/audit-trail', AdminController.getAllAuditTrail);
router.get('/wallet/audit-trail/stats', AdminController.getAuditStatistics);
router.get('/wallet/audit-trail/:userId', AdminController.getUserAuditTrail);

export default router;
