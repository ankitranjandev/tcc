import { Router } from 'express';
import { PollController } from '../controllers/poll.controller';
import { authenticate, authorize } from '../middleware/auth';
import { validate } from '../middleware/validation';
import { UserRole } from '../types';
import { z } from 'zod';

const router = Router();

// Validation schemas
const voteSchema = z.object({
  body: z.object({
    poll_id: z.string().uuid('Invalid poll ID format'),
    selected_option: z.string().min(1, 'Option cannot be empty').max(255),
    otp: z.string().length(6, 'OTP must be 6 digits'),
  }),
});

const createPollSchema = z.object({
  body: z.object({
    title: z.string().min(5, 'Title must be at least 5 characters').max(255, 'Title too long'),
    description: z.string().min(10, 'Description must be at least 10 characters').max(1000, 'Description too long'),
    vote_charge: z.number().min(0, 'Vote charge cannot be negative'),
    options: z.array(z.string().min(1).max(255))
      .min(2, 'At least 2 options required')
      .max(10, 'Maximum 10 options allowed'),
    start_date: z.string().refine((date) => !isNaN(Date.parse(date)), {
      message: 'Invalid start date format',
    }),
    end_date: z.string().refine((date) => !isNaN(Date.parse(date)), {
      message: 'Invalid end date format',
    }),
  }),
});

// =====================================================
// PUBLIC/USER ROUTES
// =====================================================

/**
 * @route   GET /polls/active
 * @desc    Get all active polls
 * @access  Public (but shows voting status if authenticated)
 */
router.get('/active', PollController.getActivePolls);

/**
 * @route   GET /polls/:pollId
 * @desc    Get poll details with results (visible after voting)
 * @access  Public (but shows user vote if authenticated)
 */
router.get('/:pollId', PollController.getPollDetails);

/**
 * @route   POST /polls/vote/request-otp
 * @desc    Request OTP for voting
 * @access  Private (USER)
 */
router.post('/vote/request-otp', authenticate, PollController.requestVoteOTP);

/**
 * @route   POST /polls/vote
 * @desc    Cast a vote on a poll (requires payment from wallet)
 * @access  Private (USER)
 */
router.post('/vote', authenticate, validate(voteSchema), PollController.vote);

/**
 * @route   GET /polls/my/votes
 * @desc    Get user's voting history
 * @access  Private (USER)
 */
router.get('/my/votes', authenticate, PollController.getUserVotes);

// =====================================================
// ADMIN ROUTES
// =====================================================

/**
 * @route   POST /polls/admin/create
 * @desc    Create a new poll (status: DRAFT)
 * @access  Private (ADMIN, SUPER_ADMIN)
 */
router.post(
  '/admin/create',
  authenticate,
  authorize(UserRole.ADMIN, UserRole.SUPER_ADMIN),
  validate(createPollSchema),
  PollController.adminCreatePoll
);

/**
 * @route   PUT /polls/admin/:pollId/publish
 * @desc    Publish a poll (change status from DRAFT to ACTIVE)
 * @access  Private (ADMIN, SUPER_ADMIN)
 */
router.put(
  '/admin/:pollId/publish',
  authenticate,
  authorize(UserRole.ADMIN, UserRole.SUPER_ADMIN),
  PollController.adminPublishPoll
);

/**
 * @route   GET /polls/admin/:pollId/revenue
 * @desc    Get revenue analytics per option for a poll
 * @access  Private (ADMIN, SUPER_ADMIN)
 */
router.get(
  '/admin/:pollId/revenue',
  authenticate,
  authorize(UserRole.ADMIN, UserRole.SUPER_ADMIN),
  PollController.adminGetPollRevenue
);

export default router;
