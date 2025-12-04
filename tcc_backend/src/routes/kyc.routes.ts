import { Router } from 'express';
import { KYCController } from '../controllers/kyc.controller';
import { authenticate, authorize } from '../middleware/auth';
import { validate } from '../middleware/validation';
import { z } from 'zod';
import { DocumentType, KYCStatus, UserRole } from '../types';

const router = Router();

// Validation schemas
const submitKYCSchema = z.object({
  body: z.object({
    document_type: z.enum([
      DocumentType.NATIONAL_ID,
      DocumentType.PASSPORT,
      DocumentType.DRIVERS_LICENSE,
      DocumentType.VOTER_CARD,
    ]),
    document_number: z.string().min(3).max(100),
    front_image_url: z.string().url(),
    back_image_url: z.string().url().optional(),
    selfie_url: z.string().url().optional(),
  }),
});

const resubmitKYCSchema = z.object({
  body: z.object({
    document_type: z.enum([
      DocumentType.NATIONAL_ID,
      DocumentType.PASSPORT,
      DocumentType.DRIVERS_LICENSE,
      DocumentType.VOTER_CARD,
    ]),
    document_number: z.string().min(3).max(100),
    front_image_url: z.string().url(),
    back_image_url: z.string().url().optional(),
    selfie_url: z.string().url().optional(),
  }),
});

const adminGetSubmissionsSchema = z.object({
  query: z.object({
    status: z.enum([
      KYCStatus.PENDING,
      KYCStatus.SUBMITTED,
      KYCStatus.APPROVED,
      KYCStatus.REJECTED,
    ]).optional(),
    search: z.string().optional(),
    document_type: z.enum([
      DocumentType.NATIONAL_ID,
      DocumentType.PASSPORT,
      DocumentType.DRIVERS_LICENSE,
      DocumentType.VOTER_CARD,
    ]).optional(),
    page: z.string().regex(/^\d+$/).optional(),
    limit: z.string().regex(/^\d+$/).optional(),
  }),
});

const adminReviewKYCSchema = z.object({
  params: z.object({
    id: z.string().uuid(),
  }),
  body: z.object({
    status: z.enum(['APPROVED', 'REJECTED']),
    rejection_reason: z.string().min(10).max(500).optional(),
  }).refine(
    (data) => {
      // If status is REJECTED, rejection_reason must be provided
      if (data.status === 'REJECTED') {
        return data.rejection_reason && data.rejection_reason.length >= 10;
      }
      return true;
    },
    {
      message: 'Rejection reason is required and must be at least 10 characters when rejecting KYC',
      path: ['rejection_reason'],
    }
  ),
});

const adminGetDetailsSchema = z.object({
  params: z.object({
    id: z.string().uuid(),
  }),
});

// User routes (authenticated)
router.use(authenticate);

/**
 * @route   POST /api/kyc/submit
 * @desc    Submit KYC documents for verification
 * @access  Private (USER, AGENT)
 */
router.post('/submit', validate(submitKYCSchema), KYCController.submitKYC);

/**
 * @route   GET /api/kyc/status
 * @desc    Get KYC verification status
 * @access  Private (USER, AGENT)
 */
router.get('/status', KYCController.getKYCStatus);

/**
 * @route   POST /api/kyc/resubmit
 * @desc    Resubmit KYC documents after rejection
 * @access  Private (USER, AGENT)
 */
router.post('/resubmit', validate(resubmitKYCSchema), KYCController.resubmitKYC);

// Admin routes (require ADMIN or SUPER_ADMIN role)
/**
 * @route   GET /api/kyc/admin/submissions
 * @desc    Get KYC submissions for admin review
 * @access  Private (ADMIN, SUPER_ADMIN)
 */
router.get(
  '/admin/submissions',
  authorize(UserRole.ADMIN, UserRole.SUPER_ADMIN),
  validate(adminGetSubmissionsSchema),
  KYCController.adminGetKYCSubmissions
);

/**
 * @route   GET /api/kyc/admin/submissions/:id
 * @desc    Get detailed KYC submission by ID
 * @access  Private (ADMIN, SUPER_ADMIN)
 */
router.get(
  '/admin/submissions/:id',
  authorize(UserRole.ADMIN, UserRole.SUPER_ADMIN),
  validate(adminGetDetailsSchema),
  KYCController.adminGetKYCDetails
);

/**
 * @route   POST /api/kyc/admin/review/:id
 * @desc    Approve or reject KYC submission
 * @access  Private (ADMIN, SUPER_ADMIN)
 */
router.post(
  '/admin/review/:id',
  authorize(UserRole.ADMIN, UserRole.SUPER_ADMIN),
  validate(adminReviewKYCSchema),
  KYCController.adminReviewKYC
);

export default router;
