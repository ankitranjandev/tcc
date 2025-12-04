import { Router } from 'express';
import { AgentController } from '../controllers/agent.controller';
import { authenticate } from '../middleware/auth';
import { validate } from '../middleware/validation';
import { z } from 'zod';

const router = Router();

// Validation schemas
const registerAgentSchema = z.object({
  body: z.object({
    location_lat: z.number().min(-90).max(90).optional(),
    location_lng: z.number().min(-180).max(180).optional(),
    location_address: z.string().max(500).optional(),
  }),
});

const requestCreditSchema = z.object({
  body: z.object({
    agent_id: z.string().uuid(),
    amount: z.number().positive().min(1000),
    receipt_url: z.string().url(),
    deposit_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/), // YYYY-MM-DD format
    deposit_time: z.string().regex(/^\d{2}:\d{2}:\d{2}$/), // HH:MM:SS format
    bank_name: z.string().max(255).optional(),
  }),
});

const getCreditRequestsSchema = z.object({
  query: z.object({
    agent_id: z.string().uuid(),
    status: z.enum(['PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'CANCELLED']).optional(),
    start_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
    end_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
    page: z.string().regex(/^\d+$/).optional(),
    limit: z.string().regex(/^\d+$/).optional(),
  }),
});

const depositForUserSchema = z.object({
  body: z.object({
    agent_id: z.string().uuid(),
    user_phone: z.string().min(10).max(15),
    amount: z.number().positive().min(100),
    payment_method: z.enum(['BANK_TRANSFER', 'MOBILE_MONEY', 'AGENT', 'BANK_RECEIPT']),
  }),
});

const withdrawForUserSchema = z.object({
  body: z.object({
    agent_id: z.string().uuid(),
    user_phone: z.string().min(10).max(15),
    amount: z.number().positive().min(100),
  }),
});

const getNearbyAgentsSchema = z.object({
  query: z.object({
    latitude: z.string().regex(/^-?\d+\.?\d*$/),
    longitude: z.string().regex(/^-?\d+\.?\d*$/),
    radius: z.string().regex(/^\d+\.?\d*$/).optional(),
  }),
});

const getDashboardStatsSchema = z.object({
  query: z.object({
    agent_id: z.string().uuid(),
  }),
});

const updateLocationSchema = z.object({
  body: z.object({
    agent_id: z.string().uuid(),
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
    address: z.string().max(500).optional(),
  }),
});

const submitReviewSchema = z.object({
  body: z.object({
    agent_id: z.string().uuid(),
    transaction_id: z.string().uuid(),
    rating: z.number().int().min(1).max(5),
    comment: z.string().max(500).optional(),
  }),
});

// Routes
/**
 * @route   POST /agent/register
 * @desc    Register as agent
 * @access  Private
 */
router.post(
  '/register',
  authenticate,
  validate(registerAgentSchema),
  AgentController.registerAgent
);

/**
 * @route   GET /agent/profile
 * @desc    Get agent profile
 * @access  Private
 */
router.get('/profile', authenticate, AgentController.getProfile);

/**
 * @route   POST /agent/credit/request
 * @desc    Request wallet credit
 * @access  Private
 */
router.post(
  '/credit/request',
  authenticate,
  validate(requestCreditSchema),
  AgentController.requestCredit
);

/**
 * @route   GET /agent/credit/requests
 * @desc    Get credit request history
 * @access  Private
 */
router.get(
  '/credit/requests',
  authenticate,
  validate(getCreditRequestsSchema),
  AgentController.getCreditRequests
);

/**
 * @route   POST /agent/deposit
 * @desc    Process deposit for user
 * @access  Private
 */
router.post(
  '/deposit',
  authenticate,
  validate(depositForUserSchema),
  AgentController.depositForUser
);

/**
 * @route   POST /agent/withdraw
 * @desc    Process withdrawal for user
 * @access  Private
 */
router.post(
  '/withdraw',
  authenticate,
  validate(withdrawForUserSchema),
  AgentController.withdrawForUser
);

/**
 * @route   GET /agent/nearby
 * @desc    Find nearby agents
 * @access  Public
 */
router.get('/nearby', validate(getNearbyAgentsSchema), AgentController.getNearbyAgents);

/**
 * @route   GET /agent/dashboard
 * @desc    Get dashboard statistics
 * @access  Private
 */
router.get(
  '/dashboard',
  authenticate,
  validate(getDashboardStatsSchema),
  AgentController.getDashboardStats
);

/**
 * @route   PUT /agent/location
 * @desc    Update agent location
 * @access  Private
 */
router.put(
  '/location',
  authenticate,
  validate(updateLocationSchema),
  AgentController.updateLocation
);

/**
 * @route   POST /agent/review
 * @desc    Submit agent review
 * @access  Private
 */
router.post(
  '/review',
  authenticate,
  validate(submitReviewSchema),
  AgentController.submitReview
);

export default router;
