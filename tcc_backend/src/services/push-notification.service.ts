import admin from 'firebase-admin';
import db from '../database';
import logger from '../utils/logger';
import config from '../config';

let firebaseApp: admin.app.App | null = null;

/**
 * Initialize Firebase Admin SDK
 */
const initializeFirebase = (): boolean => {
  if (firebaseApp) return true;

  if (!config.firebase.projectId || !config.firebase.clientEmail || !config.firebase.privateKey) {
    logger.warn('Firebase configuration missing - push notifications will be disabled');
    return false;
  }

  try {
    const serviceAccount = {
      projectId: config.firebase.projectId,
      clientEmail: config.firebase.clientEmail,
      privateKey: config.firebase.privateKey.replace(/\\n/g, '\n'),
    };

    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount as admin.ServiceAccount),
    });

    logger.info('Firebase Admin SDK initialized successfully');
    return true;
  } catch (error) {
    logger.error('Failed to initialize Firebase Admin SDK', error);
    return false;
  }
};

export interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
  channelId?: string;
}

export enum NotificationChannel {
  TRANSACTION = 'tcc_user_transactions',
  INVESTMENT = 'tcc_user_investments',
  SYSTEM = 'tcc_user_system',
  DEFAULT = 'tcc_user_default_channel',
}

export class PushNotificationService {
  /**
   * Initialize Firebase (call once at app startup)
   */
  static initialize(): void {
    initializeFirebase();
  }

  /**
   * Check if Firebase is properly configured
   */
  static isConfigured(): boolean {
    return firebaseApp !== null;
  }

  /**
   * Send push notification to a specific user
   */
  static async sendToUser(
    userId: string,
    payload: NotificationPayload
  ): Promise<{ success: boolean; messageId?: string; error?: string }> {
    try {
      if (!initializeFirebase()) {
        return { success: false, error: 'FIREBASE_NOT_CONFIGURED' };
      }

      // Get user's FCM token
      const users = await db.query<{ fcm_token: string | null }>(
        'SELECT fcm_token FROM users WHERE id = $1',
        [userId]
      );

      if (users.length === 0) {
        logger.warn('User not found for push notification', { userId });
        return { success: false, error: 'USER_NOT_FOUND' };
      }

      const fcmToken = users[0].fcm_token;

      if (!fcmToken) {
        logger.debug('No FCM token for user', { userId });
        return { success: false, error: 'NO_FCM_TOKEN' };
      }

      return await this.sendToToken(fcmToken, payload, userId);
    } catch (error) {
      logger.error('Error sending push notification to user', { userId, error });
      return { success: false, error: 'SEND_FAILED' };
    }
  }

  /**
   * Send push notification to a specific FCM token
   */
  static async sendToToken(
    token: string,
    payload: NotificationPayload,
    userId?: string
  ): Promise<{ success: boolean; messageId?: string; error?: string }> {
    try {
      if (!initializeFirebase()) {
        return { success: false, error: 'FIREBASE_NOT_CONFIGURED' };
      }

      const message: admin.messaging.Message = {
        token,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data || {},
        android: {
          priority: 'high',
          notification: {
            channelId: payload.channelId || NotificationChannel.TRANSACTION,
            sound: 'default',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: payload.title,
                body: payload.body,
              },
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().send(message);

      logger.info('Push notification sent successfully', {
        messageId: response,
        title: payload.title,
        userId,
      });

      return { success: true, messageId: response };
    } catch (error: any) {
      logger.error('Error sending push notification', { error: error.message, token: token.substring(0, 20) + '...' });

      // Handle invalid/expired token - remove from database
      if (
        error.code === 'messaging/invalid-registration-token' ||
        error.code === 'messaging/registration-token-not-registered'
      ) {
        logger.warn('Invalid FCM token detected, removing from database', { userId });
        if (userId) {
          await this.removeToken(userId);
        }
      }

      return { success: false, error: error.message };
    }
  }

  /**
   * Send notification for incoming payment (P2P transfer or Stripe top-up)
   */
  static async sendPaymentReceivedNotification(
    userId: string,
    amount: number,
    senderName: string | null,
    transactionId: string,
    isTopUp: boolean = false
  ): Promise<void> {
    const formattedAmount = `TCC${amount.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

    const payload: NotificationPayload = {
      title: isTopUp ? 'Wallet Top-up Successful' : 'Payment Received',
      body: isTopUp
        ? `${formattedAmount} has been added to your wallet`
        : `You received ${formattedAmount} from ${senderName || 'another user'}`,
      data: {
        type: 'transaction',
        transactionId,
        action: 'payment_received',
      },
      channelId: NotificationChannel.TRANSACTION,
    };

    const result = await this.sendToUser(userId, payload);

    if (result.success) {
      logger.info('Payment notification sent', { userId, amount, isTopUp, transactionId });
    } else {
      logger.debug('Payment notification not sent', { userId, reason: result.error });
    }
  }

  /**
   * Register or update FCM token for a user
   */
  static async registerToken(userId: string, fcmToken: string): Promise<void> {
    try {
      await db.query(
        `UPDATE users
         SET fcm_token = $1, fcm_token_updated_at = NOW(), updated_at = NOW()
         WHERE id = $2`,
        [fcmToken, userId]
      );

      logger.info('FCM token registered', { userId });
    } catch (error) {
      logger.error('Error registering FCM token', { userId, error });
      throw error;
    }
  }

  /**
   * Remove FCM token for a user (e.g., on logout or invalid token)
   */
  static async removeToken(userId: string): Promise<void> {
    try {
      await db.query(
        `UPDATE users
         SET fcm_token = NULL, fcm_token_updated_at = NOW(), updated_at = NOW()
         WHERE id = $1`,
        [userId]
      );

      logger.info('FCM token removed', { userId });
    } catch (error) {
      logger.error('Error removing FCM token', { userId, error });
      throw error;
    }
  }
}
