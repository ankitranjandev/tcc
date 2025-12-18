import { Router } from 'express';
import { WebhookController } from '../controllers/webhook.controller';
import express from 'express';

const router = Router();

/**
 * @route   POST /webhooks/stripe
 * @desc    Handle Stripe webhook events
 * @access  Public (verified by Stripe signature)
 *
 * Note: This route must receive raw body for signature verification
 * The express.raw() middleware is applied in app.ts before JSON parsing
 */
router.post(
  '/stripe',
  express.raw({ type: 'application/json' }),
  WebhookController.handleStripeWebhook
);

export default router;
