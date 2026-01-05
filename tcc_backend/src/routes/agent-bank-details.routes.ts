import { Router } from 'express';
import { AgentBankDetailsController } from '../controllers/agent-bank-details.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

// Agent endpoints (require authentication)
router.post(
  '/agents/:agentId/bank-details',
  authenticate,
  AgentBankDetailsController.submitBankDetails
);

router.get(
  '/agents/:agentId/bank-details',
  authenticate,
  AgentBankDetailsController.getBankDetails
);

router.delete(
  '/agents/bank-details/:bankDetailsId',
  authenticate,
  AgentBankDetailsController.deleteBankDetails
);

// Admin endpoints (require admin authentication)
router.get(
  '/admin/agent-bank-details',
  authenticate,
  AgentBankDetailsController.getAllBankDetailsForAdmin
);

router.patch(
  '/admin/agent-bank-details/:bankDetailsId/verify',
  authenticate,
  AgentBankDetailsController.verifyBankDetails
);

export default router;