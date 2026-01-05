import Stripe from 'stripe';
import config from '../config';
import logger from '../utils/logger';

/**
 * Initialize Stripe instance with configuration
 */
const initializeStripe = (): Stripe => {
  if (!config.stripe.secretKey) {
    logger.error('Stripe secret key not configured');
    throw new Error('Stripe secret key is required');
  }

  logger.info('Initializing Stripe with API version 2025-12-15.clover');

  const stripe = new Stripe(config.stripe.secretKey, {
    apiVersion: '2025-12-15.clover',
    typescript: true,
  });

  return stripe;
};

// Export singleton instance
export const stripe = initializeStripe();

/**
 * Create a Stripe customer for a user
 */
export const createStripeCustomer = async (
  userId: string,
  email: string,
  name: string,
  phone?: string
): Promise<Stripe.Customer> => {
  try {
    const customer = await stripe.customers.create({
      email,
      name,
      phone,
      metadata: {
        user_id: userId,
      },
    });

    logger.info(`Stripe customer created: ${customer.id} for user: ${userId}`);
    return customer;
  } catch (error) {
    logger.error('Error creating Stripe customer:', error);
    throw error;
  }
};

/**
 * Create a payment intent for wallet deposit
 */
export const createPaymentIntent = async (
  amount: number,
  userId: string,
  transactionId: string,
  stripeCustomerId?: string
): Promise<Stripe.PaymentIntent> => {
  try {
    // Amount is already in cents from frontend
    const paymentIntentData: Stripe.PaymentIntentCreateParams = {
      amount: Math.round(amount),
      currency: config.stripe.currency,
      metadata: {
        user_id: userId,
        transaction_id: transactionId,
        type: 'wallet_deposit',
      },
      description: `Wallet deposit for transaction ${transactionId}`,
      automatic_payment_methods: {
        enabled: true,
      },
    };

    // Add customer if available
    if (stripeCustomerId) {
      paymentIntentData.customer = stripeCustomerId;
    }

    const paymentIntent = await stripe.paymentIntents.create(paymentIntentData);

    logger.info(`Payment intent created: ${paymentIntent.id} for transaction: ${transactionId}`);
    return paymentIntent;
  } catch (error) {
    logger.error('Error creating payment intent:', error);
    throw error;
  }
};

/**
 * Retrieve a payment intent by ID
 */
export const retrievePaymentIntent = async (
  paymentIntentId: string
): Promise<Stripe.PaymentIntent> => {
  try {
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
    return paymentIntent;
  } catch (error) {
    logger.error(`Error retrieving payment intent ${paymentIntentId}:`, error);
    throw error;
  }
};

/**
 * Verify Stripe webhook signature
 */
export const verifyWebhookSignature = (
  payload: string | Buffer,
  signature: string
): Stripe.Event => {
  try {
    const event = stripe.webhooks.constructEvent(
      payload,
      signature,
      config.stripe.webhookSecret
    );
    return event;
  } catch (error) {
    logger.error('Webhook signature verification failed:', error);
    throw error;
  }
};

/**
 * Handle refund for failed transactions
 */
export const createRefund = async (
  paymentIntentId: string,
  reason?: string
): Promise<Stripe.Refund> => {
  try {
    const refund = await stripe.refunds.create({
      payment_intent: paymentIntentId,
      reason: reason === 'duplicate' ? 'duplicate' : 'requested_by_customer',
    });

    logger.info(`Refund created: ${refund.id} for payment intent: ${paymentIntentId}`);
    return refund;
  } catch (error) {
    logger.error(`Error creating refund for ${paymentIntentId}:`, error);
    throw error;
  }
};

export default {
  stripe,
  createStripeCustomer,
  createPaymentIntent,
  retrievePaymentIntent,
  verifyWebhookSignature,
  createRefund,
};
