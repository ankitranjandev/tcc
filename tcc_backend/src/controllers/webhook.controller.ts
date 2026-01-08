import { Request, Response } from 'express';
import { ApiResponseUtil } from '../utils/response';
import logger from '../utils/logger';
import { verifyWebhookSignature } from '../services/stripe.service';
import db from '../database';
import { TransactionStatus } from '../types';
import { PushNotificationService } from '../services/push-notification.service';

export class WebhookController {
  /**
   * Handle Stripe webhook events
   */
  static async handleStripeWebhook(req: Request, res: Response): Promise<Response> {
    const signature = req.headers['stripe-signature'] as string;

    if (!signature) {
      logger.error('Missing stripe-signature header');
      return ApiResponseUtil.badRequest(res, 'Missing stripe-signature header');
    }

    try {
      // Get raw body (must be string or buffer for signature verification)
      const rawBody = req.body;

      // Verify webhook signature
      const event = verifyWebhookSignature(rawBody, signature);

      logger.info('Stripe webhook received', {
        type: event.type,
        id: event.id,
      });

      // Handle the event
      switch (event.type) {
        case 'payment_intent.succeeded':
          await WebhookController.handlePaymentIntentSucceeded(event);
          break;

        case 'payment_intent.payment_failed':
          await WebhookController.handlePaymentIntentFailed(event);
          break;

        case 'payment_intent.canceled':
          await WebhookController.handlePaymentIntentCanceled(event);
          break;

        case 'charge.refunded':
          await WebhookController.handleChargeRefunded(event);
          break;

        default:
          logger.info(`Unhandled webhook event type: ${event.type}`);
      }

      // Return a 200 response to acknowledge receipt of the event
      return res.status(200).json({ received: true });
    } catch (error: any) {
      logger.error('Webhook error', error);
      return res.status(400).json({
        error: {
          message: error.message || 'Webhook handler failed',
        },
      });
    }
  }

  /**
   * Handle successful payment intent
   */
  private static async handlePaymentIntentSucceeded(event: any): Promise<void> {
    try {
      const paymentIntent = event.data.object;
      const paymentIntentId = paymentIntent.id;
      const userId = paymentIntent.metadata.user_id;
      const transactionId = paymentIntent.metadata.transaction_id;

      logger.info('Processing payment_intent.succeeded', {
        paymentIntentId,
        userId,
        transactionId,
      });

      // Update transaction and wallet in a single transaction
      const transactionData = await db.transaction(async (client) => {
        // Get transaction details
        const result = await client.query(
          `SELECT id, transaction_id, to_user_id, amount, status
           FROM transactions
           WHERE stripe_payment_intent_id = $1`,
          [paymentIntentId]
        );

        if (result.rows.length === 0) {
          logger.error('Transaction not found for payment intent', { paymentIntentId });
          throw new Error('Transaction not found');
        }

        const transaction = result.rows[0];

        // Only process if transaction is still pending
        if (transaction.status !== TransactionStatus.PENDING) {
          logger.warn('Transaction already processed', {
            transactionId: transaction.id,
            status: transaction.status,
          });
          return null;
        }

        // Update transaction status to completed
        await client.query(
          `UPDATE transactions
           SET status = $1,
               processed_at = NOW(),
               payment_gateway_response = $2,
               updated_at = NOW()
           WHERE id = $3`,
          [TransactionStatus.COMPLETED, JSON.stringify(paymentIntent), transaction.id]
        );

        // Credit user's wallet
        await client.query(
          `UPDATE wallets
           SET balance = balance + $1,
               last_transaction_at = NOW(),
               updated_at = NOW()
           WHERE user_id = $2`,
          [transaction.amount, transaction.to_user_id]
        );

        logger.info('Payment processed successfully', {
          paymentIntentId,
          transactionId: transaction.id,
          amount: transaction.amount,
          userId: transaction.to_user_id,
        });

        return transaction;
      });

      // Send push notification for wallet top-up (outside transaction to not block)
      if (transactionData) {
        PushNotificationService.sendPaymentReceivedNotification(
          transactionData.to_user_id,
          parseFloat(transactionData.amount),
          null, // No sender for top-up
          transactionData.transaction_id,
          true // isTopUp = true
        ).catch((err) => logger.error('Failed to send payment notification', err));
      }
    } catch (error) {
      logger.error('Error handling payment_intent.succeeded', error);
      throw error;
    }
  }

  /**
   * Handle failed payment intent
   */
  private static async handlePaymentIntentFailed(event: any): Promise<void> {
    try {
      const paymentIntent = event.data.object;
      const paymentIntentId = paymentIntent.id;
      const failureMessage = paymentIntent.last_payment_error?.message || 'Payment failed';

      logger.info('Processing payment_intent.payment_failed', {
        paymentIntentId,
        failureMessage,
      });

      // Update transaction status to failed
      await db.query(
        `UPDATE transactions
         SET status = $1,
             failed_at = NOW(),
             failure_reason = $2,
             payment_gateway_response = $3,
             updated_at = NOW()
         WHERE stripe_payment_intent_id = $4 AND status = $5`,
        [
          TransactionStatus.FAILED,
          failureMessage,
          JSON.stringify(paymentIntent),
          paymentIntentId,
          TransactionStatus.PENDING,
        ]
      );

      logger.info('Payment failure recorded', { paymentIntentId });
    } catch (error) {
      logger.error('Error handling payment_intent.payment_failed', error);
      throw error;
    }
  }

  /**
   * Handle canceled payment intent
   */
  private static async handlePaymentIntentCanceled(event: any): Promise<void> {
    try {
      const paymentIntent = event.data.object;
      const paymentIntentId = paymentIntent.id;

      logger.info('Processing payment_intent.canceled', { paymentIntentId });

      // Update transaction status to cancelled
      await db.query(
        `UPDATE transactions
         SET status = $1,
             payment_gateway_response = $2,
             updated_at = NOW()
         WHERE stripe_payment_intent_id = $3 AND status = $4`,
        [
          TransactionStatus.CANCELLED,
          JSON.stringify(paymentIntent),
          paymentIntentId,
          TransactionStatus.PENDING,
        ]
      );

      logger.info('Payment cancellation recorded', { paymentIntentId });
    } catch (error) {
      logger.error('Error handling payment_intent.canceled', error);
      throw error;
    }
  }

  /**
   * Handle charge refunded
   */
  private static async handleChargeRefunded(event: any): Promise<void> {
    try {
      const charge = event.data.object;
      const paymentIntentId = charge.payment_intent;

      logger.info('Processing charge.refunded', { paymentIntentId });

      // Get the transaction
      const result = await db.query(
        `SELECT id, to_user_id, amount, status
         FROM transactions
         WHERE stripe_payment_intent_id = $1`,
        [paymentIntentId]
      );

      if (result.length === 0) {
        logger.error('Transaction not found for refund', { paymentIntentId });
        return;
      }

      const transaction: any = result[0];

      // Only process refund if transaction was completed
      if (transaction.status !== TransactionStatus.COMPLETED) {
        logger.warn('Cannot refund non-completed transaction', {
          transactionId: transaction.id,
          status: transaction.status,
        });
        return;
      }

      // Process refund in a transaction
      await db.transaction(async (client) => {
        // Update transaction status
        await client.query(
          `UPDATE transactions
           SET status = $1,
               payment_gateway_response = $2,
               updated_at = NOW()
           WHERE id = $3`,
          [TransactionStatus.CANCELLED, JSON.stringify(charge), transaction.id]
        );

        // Deduct amount from user's wallet (reverse the credit)
        await client.query(
          `UPDATE wallets
           SET balance = balance - $1,
               last_transaction_at = NOW(),
               updated_at = NOW()
           WHERE user_id = $2`,
          [transaction.amount, transaction.to_user_id]
        );

        logger.info('Refund processed successfully', {
          paymentIntentId,
          transactionId: transaction.id,
          amount: transaction.amount,
          userId: transaction.to_user_id,
        });
      });
    } catch (error) {
      logger.error('Error handling charge.refunded', error);
      throw error;
    }
  }
}
