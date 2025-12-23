import { Router } from 'express';
import electionController from '../controllers/election.controller';
import { authenticate, authorize } from '../middleware/auth';
import { UserRole } from '../types';
import { validate } from '../middleware/validation';
import { z } from 'zod';

const router = Router();

// Validation schemas
const createElectionSchema = z.object({
  body: z.object({
    title: z.string().min(1).max(255),
    question: z.string().min(1),
    options: z.array(z.string().min(1)).min(2),
    voting_charge: z.number().min(0),
    end_time: z.string().refine((val) => {
      const endTime = new Date(val);
      return endTime > new Date();
    }, { message: 'End time must be in the future' })
  })
});

const updateElectionSchema = z.object({
  params: z.object({
    electionId: z.string()
  }),
  body: z.object({
    title: z.string().min(1).max(255).optional(),
    question: z.string().min(1).optional(),
    options: z.array(z.string().min(1)).min(2).optional(),
    voting_charge: z.number().min(0).optional(),
    end_time: z.string().optional()
  })
});

const electionIdSchema = z.object({
  params: z.object({
    electionId: z.string()
  })
});

const castVoteSchema = z.object({
  body: z.object({
    election_id: z.number().int(),
    option_id: z.number().int()
  })
});

// Admin routes
router.post(
  '/admin/elections',
  authenticate,
  authorize(UserRole.ADMIN, UserRole.SUPER_ADMIN),
  validate(createElectionSchema),
  electionController.createElection
);

router.put(
  '/admin/elections/:electionId',
  authenticate,
  authorize(UserRole.ADMIN, UserRole.SUPER_ADMIN),
  validate(updateElectionSchema),
  electionController.updateElection
);

router.post(
  '/admin/elections/:electionId/end',
  authenticate,
  authorize(UserRole.ADMIN, UserRole.SUPER_ADMIN),
  validate(electionIdSchema),
  electionController.endElection
);

router.post(
  '/admin/elections/:electionId/pause',
  authenticate,
  authorize(UserRole.ADMIN, UserRole.SUPER_ADMIN),
  validate(electionIdSchema),
  electionController.pauseElection
);

router.post(
  '/admin/elections/:electionId/resume',
  authenticate,
  authorize(UserRole.ADMIN, UserRole.SUPER_ADMIN),
  validate(electionIdSchema),
  electionController.resumeElection
);

router.get(
  '/admin/elections/:electionId/stats',
  authenticate,
  authorize(UserRole.ADMIN, UserRole.SUPER_ADMIN),
  validate(electionIdSchema),
  electionController.getElectionStats
);

router.get(
  '/admin/elections',
  authenticate,
  authorize(UserRole.ADMIN, UserRole.SUPER_ADMIN),
  electionController.getAllElections
);

router.delete(
  '/admin/elections/:electionId',
  authenticate,
  authorize(UserRole.ADMIN, UserRole.SUPER_ADMIN),
  validate(electionIdSchema),
  electionController.deleteElection
);

// User routes
router.get(
  '/elections/active',
  authenticate,
  electionController.getActiveElections
);

router.get(
  '/elections/closed',
  authenticate,
  electionController.getClosedElections
);

router.post(
  '/elections/vote',
  authenticate,
  validate(castVoteSchema),
  electionController.castVote
);

router.get(
  '/elections/:electionId',
  authenticate,
  validate(electionIdSchema),
  electionController.getElection
);

export default router;
