// @ts-nocheck
import { PoolClient } from 'pg';
import db from '../database';
import logger from '../utils/logger';
import config from '../config';
import {
  Agent,
  KYCStatus,
  TransactionType,
  TransactionStatus,
  PaymentMethod,
  UserRole,
} from '../types';

export interface AgentStats {
  totalTransactions: number;
  commissionsEarned: number;
  walletBalance: number;
  averageRating: number;
  totalReviews: number;
}

export interface AgentProfile extends Agent {
  user: {
    firstName: string;
    lastName: string;
    email: string;
    phone: string;
    profilePicture?: string;
  };
  stats: AgentStats;
}

export interface CreditRequest {
  id: string;
  agentId: string;
  amount: number;
  receiptUrl: string;
  depositDate: string;
  depositTime: string;
  bankName?: string;
  status: TransactionStatus;
  adminId?: string;
  rejectionReason?: string;
  approvedAt?: Date;
  rejectedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface NearbyAgent {
  id: string;
  userId: string;
  firstName: string;
  lastName: string;
  phone: string;
  profilePicture?: string;
  locationLat: number;
  locationLng: number;
  locationAddress: string;
  distance: number; // in kilometers
  averageRating: number;
  totalReviews: number;
  activeStatus: boolean;
  walletBalance: number;
}

export class AgentService {
  /**
   * Generate unique transaction ID
   * Format: TXN + YYYYMMDD + 6 random digits
   */
  private static generateTransactionId(): string {
    const date = new Date();
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const dateStr = `${year}${month}${day}`;

    // Generate 6 random digits
    const randomDigits = Math.floor(100000 + Math.random() * 900000);

    return `TXN${dateStr}${randomDigits}`;
  }

  /**
   * Calculate distance between two coordinates using Haversine formula
   * Returns distance in kilometers
   */
  private static calculateDistance(
    lat1: number,
    lng1: number,
    lat2: number,
    lng2: number
  ): number {
    const R = 6371; // Earth's radius in kilometers
    const dLat = this.toRadians(lat2 - lat1);
    const dLng = this.toRadians(lng2 - lng1);

    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRadians(lat1)) *
        Math.cos(this.toRadians(lat2)) *
        Math.sin(dLng / 2) *
        Math.sin(dLng / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private static toRadians(degrees: number): number {
    return degrees * (Math.PI / 180);
  }

  /**
   * Calculate commission based on transaction amount
   */
  private static calculateCommission(amount: number, commissionRate: number): number {
    return (amount * commissionRate) / 100;
  }

  /**
   * Register user as agent
   */
  static async registerAgent(
    userId: string,
    locationLat?: number,
    locationLng?: number,
    locationAddress?: string
  ): Promise<Agent> {
    try {
      // Check if user exists
      const users = await db.query('SELECT id, role FROM users WHERE id = $1', [userId]);

      if (users.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      // Check if already an agent
      const existingAgents = await db.query('SELECT id FROM agents WHERE user_id = $1', [userId]);

      if (existingAgents.length > 0) {
        throw new Error('ALREADY_REGISTERED_AS_AGENT');
      }

      const result = await db.transaction(async (client: PoolClient) => {
        // Create agent record
        const agents = await client.query<Agent>(
          `INSERT INTO agents (
            user_id, wallet_balance, active_status, verification_status,
            location_lat, location_lng, location_address, commission_rate
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
          RETURNING id, user_id, wallet_balance, active_status, verification_status,
                    location_lat, location_lng, location_address, commission_rate,
                    total_commission_earned, total_transactions_processed,
                    created_at, updated_at`,
          [
            userId,
            0,
            false, // Will be activated after verification
            KYCStatus.PENDING,
            locationLat || null,
            locationLng || null,
            locationAddress || null,
            config.agent.baseCommissionRate,
          ]
        );

        // Update user role to AGENT
        await client.query(
          `UPDATE users SET role = $1, updated_at = NOW() WHERE id = $2`,
          [UserRole.AGENT, userId]
        );

        return agents[0];
      });

      logger.info('Agent registered successfully', { userId, agentId: result.id });

      return result;
    } catch (error) {
      logger.error('Error registering agent', error);
      throw error;
    }
  }

  /**
   * Get agent profile with stats
   */
  static async getAgentProfile(userId: string): Promise<AgentProfile> {
    try {
      // Get agent details with user info
      const agents = await db.query<any>(
        `SELECT
          a.id, a.user_id, a.wallet_balance, a.active_status, a.verification_status,
          a.location_lat, a.location_lng, a.location_address, a.commission_rate,
          a.total_commission_earned, a.total_transactions_processed,
          a.verified_at, a.verified_by, a.created_at, a.updated_at,
          u.first_name, u.last_name, u.email, u.phone, u.profile_picture_url
        FROM agents a
        JOIN users u ON a.user_id = u.id
        WHERE a.user_id = $1`,
        [userId]
      );

      if (agents.length === 0) {
        throw new Error('AGENT_NOT_FOUND');
      }

      const agent = agents[0];

      // Get rating statistics
      const ratingStats = await db.query(
        `SELECT
          COALESCE(AVG(rating), 0) as average_rating,
          COUNT(*) as total_reviews
        FROM agent_reviews
        WHERE agent_id = $1`,
        [agent.id]
      );

      const stats: AgentStats = {
        totalTransactions: parseInt(agent.total_transactions_processed) || 0,
        commissionsEarned: parseFloat(agent.total_commission_earned) || 0,
        walletBalance: parseFloat(agent.wallet_balance) || 0,
        averageRating: parseFloat(ratingStats[0]?.average_rating) || 0,
        totalReviews: parseInt(ratingStats[0]?.total_reviews) || 0,
      };

      const profile: AgentProfile = {
        id: agent.id,
        user_id: agent.user_id,
        wallet_balance: parseFloat(agent.wallet_balance),
        active_status: agent.active_status,
        verification_status: agent.verification_status,
        location_lat: agent.location_lat ? parseFloat(agent.location_lat) : undefined,
        location_lng: agent.location_lng ? parseFloat(agent.location_lng) : undefined,
        location_address: agent.location_address,
        commission_rate: parseFloat(agent.commission_rate),
        total_commission_earned: parseFloat(agent.total_commission_earned),
        total_transactions_processed: parseInt(agent.total_transactions_processed),
        verified_at: agent.verified_at,
        verified_by: agent.verified_by,
        created_at: agent.created_at,
        updated_at: agent.updated_at,
        user: {
          firstName: agent.first_name,
          lastName: agent.last_name,
          email: agent.email,
          phone: agent.phone,
          profilePicture: agent.profile_picture_url,
        },
        stats,
      };

      return profile;
    } catch (error) {
      logger.error('Error getting agent profile', error);
      throw error;
    }
  }

  /**
   * Request credit for agent wallet
   */
  static async requestCredit(
    agentId: string,
    amount: number,
    receiptUrl: string,
    depositDate: string,
    depositTime: string,
    bankName?: string
  ): Promise<CreditRequest> {
    try {
      // Validate amount
      if (amount <= 0) {
        throw new Error('INVALID_AMOUNT');
      }

      // Check if agent exists
      const agents = await db.query('SELECT id FROM agents WHERE id = $1', [agentId]);

      if (agents.length === 0) {
        throw new Error('AGENT_NOT_FOUND');
      }

      // Create credit request
      const requests = await db.query<any>(
        `INSERT INTO agent_credit_requests (
          agent_id, amount, receipt_url, deposit_date, deposit_time, bank_name, status
        ) VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING id, agent_id, amount, receipt_url, deposit_date, deposit_time,
                  bank_name, status, admin_id, rejection_reason, approved_at,
                  rejected_at, created_at, updated_at`,
        [agentId, amount, receiptUrl, depositDate, depositTime, bankName || null, TransactionStatus.PENDING]
      );

      logger.info('Agent credit request created', { agentId, requestId: requests[0].id, amount });

      return {
        id: requests[0].id,
        agentId: requests[0].agent_id,
        amount: parseFloat(requests[0].amount),
        receiptUrl: requests[0].receipt_url,
        depositDate: requests[0].deposit_date,
        depositTime: requests[0].deposit_time,
        bankName: requests[0].bank_name,
        status: requests[0].status,
        adminId: requests[0].admin_id,
        rejectionReason: requests[0].rejection_reason,
        approvedAt: requests[0].approved_at,
        rejectedAt: requests[0].rejected_at,
        createdAt: requests[0].created_at,
        updatedAt: requests[0].updated_at,
      };
    } catch (error) {
      logger.error('Error creating credit request', error);
      throw error;
    }
  }

  /**
   * Get credit request history with filters
   */
  static async getCreditRequests(
    agentId: string,
    filters?: {
      status?: TransactionStatus;
      startDate?: string;
      endDate?: string;
      page?: number;
      limit?: number;
    }
  ): Promise<{ requests: CreditRequest[]; total: number; page: number; limit: number }> {
    try {
      const page = filters?.page || 1;
      const limit = filters?.limit || 20;
      const offset = (page - 1) * limit;

      let whereConditions = ['agent_id = $1'];
      let params: any[] = [agentId];
      let paramCount = 1;

      if (filters?.status) {
        paramCount++;
        whereConditions.push(`status = $${paramCount}`);
        params.push(filters.status);
      }

      if (filters?.startDate) {
        paramCount++;
        whereConditions.push(`created_at >= $${paramCount}`);
        params.push(filters.startDate);
      }

      if (filters?.endDate) {
        paramCount++;
        whereConditions.push(`created_at <= $${paramCount}`);
        params.push(filters.endDate);
      }

      const whereClause = whereConditions.join(' AND ');

      // Get total count
      const countResult = await db.query(
        `SELECT COUNT(*) as total FROM agent_credit_requests WHERE ${whereClause}`,
        params
      );
      const total = parseInt(countResult[0]?.total || '0');

      // Get requests
      const requests = await db.query<any>(
        `SELECT id, agent_id, amount, receipt_url, deposit_date, deposit_time,
                bank_name, status, admin_id, rejection_reason, approved_at,
                rejected_at, created_at, updated_at
         FROM agent_credit_requests
         WHERE ${whereClause}
         ORDER BY created_at DESC
         LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}`,
        [...params, limit, offset]
      );

      return {
        requests: requests.map((r: any) => ({
          id: r.id,
          agentId: r.agent_id,
          amount: parseFloat(r.amount),
          receiptUrl: r.receipt_url,
          depositDate: r.deposit_date,
          depositTime: r.deposit_time,
          bankName: r.bank_name,
          status: r.status,
          adminId: r.admin_id,
          rejectionReason: r.rejection_reason,
          approvedAt: r.approved_at,
          rejectedAt: r.rejected_at,
          createdAt: r.created_at,
          updatedAt: r.updated_at,
        })),
        total,
        page,
        limit,
      };
    } catch (error) {
      logger.error('Error getting credit requests', error);
      throw error;
    }
  }

  /**
   * Process deposit for user (agent provides cash, user gets wallet credit)
   */
  static async depositForUser(
    agentId: string,
    userPhone: string,
    amount: number,
    method: PaymentMethod
  ): Promise<any> {
    try {
      // Validate amount
      if (amount <= 0) {
        throw new Error('INVALID_AMOUNT');
      }

      // Get agent details
      const agents = await db.query<any>(
        `SELECT id, user_id, wallet_balance, active_status, commission_rate
         FROM agents WHERE id = $1`,
        [agentId]
      );

      if (agents.length === 0) {
        throw new Error('AGENT_NOT_FOUND');
      }

      const agent = agents[0];

      if (!agent.active_status) {
        throw new Error('AGENT_NOT_ACTIVE');
      }

      // Check agent has sufficient balance
      if (parseFloat(agent.wallet_balance) < amount) {
        throw new Error('INSUFFICIENT_AGENT_BALANCE');
      }

      // Get user details
      const users = await db.query(
        `SELECT id, first_name, last_name FROM users WHERE phone = $1 AND is_active = true`,
        [userPhone]
      );

      if (users.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      const user = users[0];

      // Calculate commission
      const commission = this.calculateCommission(amount, parseFloat(agent.commission_rate));

      const transactionId = this.generateTransactionId();

      const result = await db.transaction(async (client: PoolClient) => {
        // Create transaction for user deposit
        const transactions = await client.query(
          `INSERT INTO transactions (
            transaction_id, type, to_user_id, amount, fee, net_amount,
            status, payment_method, metadata, processed_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
          RETURNING id, transaction_id, type, amount, fee, net_amount, status,
                    payment_method, created_at`,
          [
            transactionId,
            TransactionType.DEPOSIT,
            user.id,
            amount,
            0,
            amount,
            TransactionStatus.COMPLETED,
            method,
            JSON.stringify({ agentId, processedBy: 'agent' }),
          ]
        );

        // Update user wallet (add amount)
        await client.query(
          `UPDATE wallets
           SET balance = balance + $1, last_transaction_at = NOW(), updated_at = NOW()
           WHERE user_id = $2`,
          [amount, user.id]
        );

        // Update agent wallet (deduct amount)
        await client.query(
          `UPDATE agents
           SET wallet_balance = wallet_balance - $1,
               total_transactions_processed = total_transactions_processed + 1,
               updated_at = NOW()
           WHERE id = $2`,
          [amount, agentId]
        );

        // Add commission to agent
        await client.query(
          `UPDATE agents
           SET wallet_balance = wallet_balance + $1,
               total_commission_earned = total_commission_earned + $1,
               updated_at = NOW()
           WHERE id = $2`,
          [commission, agentId]
        );

        // Record commission
        await client.query(
          `INSERT INTO agent_commissions (
            agent_id, transaction_id, commission_amount, commission_rate,
            transaction_type, paid
          ) VALUES ($1, $2, $3, $4, $5, $6)`,
          [agentId, transactions[0].id, commission, agent.commission_rate, 'DEPOSIT', true]
        );

        // Create commission transaction
        await client.query(
          `INSERT INTO transactions (
            transaction_id, type, to_user_id, amount, fee, net_amount,
            status, reference, processed_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())`,
          [
            this.generateTransactionId(),
            TransactionType.COMMISSION,
            agent.user_id,
            commission,
            0,
            commission,
            TransactionStatus.COMPLETED,
            transactionId,
          ]
        );

        return transactions[0];
      });

      logger.info('Agent deposit for user completed', {
        agentId,
        userId: user.id,
        transactionId,
        amount,
        commission,
      });

      return {
        ...result,
        amount: parseFloat(result.amount),
        fee: parseFloat(result.fee),
        net_amount: parseFloat(result.net_amount),
        commission,
        user: {
          name: `${user.first_name} ${user.last_name}`,
          phone: `****${userPhone.slice(-4)}`,
        },
      };
    } catch (error) {
      logger.error('Error processing agent deposit', error);
      throw error;
    }
  }

  /**
   * Process withdrawal for user (user provides wallet credit, agent gives cash)
   */
  static async withdrawForUser(
    agentId: string,
    userPhone: string,
    amount: number
  ): Promise<any> {
    try {
      // Validate amount
      if (amount <= 0) {
        throw new Error('INVALID_AMOUNT');
      }

      // Get agent details
      const agents = await db.query<any>(
        `SELECT id, user_id, wallet_balance, active_status, commission_rate
         FROM agents WHERE id = $1`,
        [agentId]
      );

      if (agents.length === 0) {
        throw new Error('AGENT_NOT_FOUND');
      }

      const agent = agents[0];

      if (!agent.active_status) {
        throw new Error('AGENT_NOT_ACTIVE');
      }

      // Get user details and wallet
      const users = await db.query<any>(
        `SELECT u.id, u.first_name, u.last_name, w.balance
         FROM users u
         JOIN wallets w ON u.id = w.user_id
         WHERE u.phone = $1 AND u.is_active = true`,
        [userPhone]
      );

      if (users.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      const user = users[0];

      // Check user has sufficient balance
      if (parseFloat(user.balance) < amount) {
        throw new Error('INSUFFICIENT_USER_BALANCE');
      }

      // Calculate commission
      const commission = this.calculateCommission(amount, parseFloat(agent.commission_rate));

      const transactionId = this.generateTransactionId();

      const result = await db.transaction(async (client: PoolClient) => {
        // Create transaction for user withdrawal
        const transactions = await client.query(
          `INSERT INTO transactions (
            transaction_id, type, from_user_id, amount, fee, net_amount,
            status, payment_method, metadata, processed_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
          RETURNING id, transaction_id, type, amount, fee, net_amount, status,
                    payment_method, created_at`,
          [
            transactionId,
            TransactionType.WITHDRAWAL,
            user.id,
            amount,
            0,
            amount,
            TransactionStatus.COMPLETED,
            PaymentMethod.AGENT,
            JSON.stringify({ agentId, processedBy: 'agent' }),
          ]
        );

        // Update user wallet (deduct amount)
        await client.query(
          `UPDATE wallets
           SET balance = balance - $1, last_transaction_at = NOW(), updated_at = NOW()
           WHERE user_id = $2`,
          [amount, user.id]
        );

        // Update agent wallet (add amount)
        await client.query(
          `UPDATE agents
           SET wallet_balance = wallet_balance + $1,
               total_transactions_processed = total_transactions_processed + 1,
               updated_at = NOW()
           WHERE id = $2`,
          [amount, agentId]
        );

        // Add commission to agent
        await client.query(
          `UPDATE agents
           SET wallet_balance = wallet_balance + $1,
               total_commission_earned = total_commission_earned + $1,
               updated_at = NOW()
           WHERE id = $2`,
          [commission, agentId]
        );

        // Record commission
        await client.query(
          `INSERT INTO agent_commissions (
            agent_id, transaction_id, commission_amount, commission_rate,
            transaction_type, paid
          ) VALUES ($1, $2, $3, $4, $5, $6)`,
          [agentId, transactions[0].id, commission, agent.commission_rate, 'WITHDRAWAL', true]
        );

        // Create commission transaction
        await client.query(
          `INSERT INTO transactions (
            transaction_id, type, to_user_id, amount, fee, net_amount,
            status, reference, processed_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())`,
          [
            this.generateTransactionId(),
            TransactionType.COMMISSION,
            agent.user_id,
            commission,
            0,
            commission,
            TransactionStatus.COMPLETED,
            transactionId,
          ]
        );

        return transactions[0];
      });

      logger.info('Agent withdrawal for user completed', {
        agentId,
        userId: user.id,
        transactionId,
        amount,
        commission,
      });

      return {
        ...result,
        amount: parseFloat(result.amount),
        fee: parseFloat(result.fee),
        net_amount: parseFloat(result.net_amount),
        commission,
        user: {
          name: `${user.first_name} ${user.last_name}`,
          phone: `****${userPhone.slice(-4)}`,
        },
      };
    } catch (error) {
      logger.error('Error processing agent withdrawal', error);
      throw error;
    }
  }

  /**
   * Find nearby agents using geolocation
   */
  static async getNearbyAgents(
    lat: number,
    lng: number,
    radius: number = 10 // default 10km radius
  ): Promise<NearbyAgent[]> {
    try {
      // Get all active agents with location
      const agents = await db.query<any>(
        `SELECT
          a.id, a.user_id, a.location_lat, a.location_lng, a.location_address,
          a.active_status, a.wallet_balance,
          u.first_name, u.last_name, u.phone, u.profile_picture_url,
          COALESCE(AVG(ar.rating), 0) as average_rating,
          COUNT(ar.id) as total_reviews
        FROM agents a
        JOIN users u ON a.user_id = u.id
        LEFT JOIN agent_reviews ar ON a.id = ar.agent_id
        WHERE a.active_status = true
          AND a.location_lat IS NOT NULL
          AND a.location_lng IS NOT NULL
        GROUP BY a.id, a.user_id, a.location_lat, a.location_lng, a.location_address,
                 a.active_status, a.wallet_balance, u.first_name, u.last_name,
                 u.phone, u.profile_picture_url`
      );

      // Calculate distances and filter by radius
      const nearbyAgents: NearbyAgent[] = [];

      for (const agent of agents) {
        const distance = this.calculateDistance(
          lat,
          lng,
          parseFloat(agent.location_lat),
          parseFloat(agent.location_lng)
        );

        if (distance <= radius) {
          nearbyAgents.push({
            id: agent.id,
            userId: agent.user_id,
            firstName: agent.first_name,
            lastName: agent.last_name,
            phone: `****${agent.phone.slice(-4)}`, // Masked phone
            profilePicture: agent.profile_picture_url,
            locationLat: parseFloat(agent.location_lat),
            locationLng: parseFloat(agent.location_lng),
            locationAddress: agent.location_address,
            distance: Math.round(distance * 100) / 100, // Round to 2 decimal places
            averageRating: parseFloat(agent.average_rating) || 0,
            totalReviews: parseInt(agent.total_reviews) || 0,
            activeStatus: agent.active_status,
            walletBalance: parseFloat(agent.wallet_balance),
          });
        }
      }

      // Sort by distance
      nearbyAgents.sort((a, b) => a.distance - b.distance);

      logger.info('Nearby agents found', { lat, lng, radius, count: nearbyAgents.length });

      return nearbyAgents;
    } catch (error) {
      logger.error('Error finding nearby agents', error);
      throw error;
    }
  }

  /**
   * Get agent dashboard statistics
   */
  static async getDashboardStats(agentId: string): Promise<AgentStats & {
    todayTransactions: number;
    todayCommissions: number;
    weeklyTransactions: number;
    weeklyCommissions: number;
    monthlyTransactions: number;
    monthlyCommissions: number;
  }> {
    try {
      // Get agent basic info
      const agents = await db.query<any>(
        `SELECT wallet_balance, total_commission_earned, total_transactions_processed
         FROM agents WHERE id = $1`,
        [agentId]
      );

      if (agents.length === 0) {
        throw new Error('AGENT_NOT_FOUND');
      }

      const agent = agents[0];

      // Get rating statistics
      const ratingStats = await db.query(
        `SELECT
          COALESCE(AVG(rating), 0) as average_rating,
          COUNT(*) as total_reviews
        FROM agent_reviews
        WHERE agent_id = $1`,
        [agentId]
      );

      // Get today's stats
      const todayStats = await db.query(
        `SELECT
          COUNT(*) as transactions,
          COALESCE(SUM(commission_amount), 0) as commissions
        FROM agent_commissions
        WHERE agent_id = $1 AND DATE(created_at) = CURRENT_DATE`,
        [agentId]
      );

      // Get this week's stats
      const weeklyStats = await db.query(
        `SELECT
          COUNT(*) as transactions,
          COALESCE(SUM(commission_amount), 0) as commissions
        FROM agent_commissions
        WHERE agent_id = $1
          AND created_at >= DATE_TRUNC('week', CURRENT_DATE)`,
        [agentId]
      );

      // Get this month's stats
      const monthlyStats = await db.query(
        `SELECT
          COUNT(*) as transactions,
          COALESCE(SUM(commission_amount), 0) as commissions
        FROM agent_commissions
        WHERE agent_id = $1
          AND created_at >= DATE_TRUNC('month', CURRENT_DATE)`,
        [agentId]
      );

      return {
        totalTransactions: parseInt(agent.total_transactions_processed) || 0,
        commissionsEarned: parseFloat(agent.total_commission_earned) || 0,
        walletBalance: parseFloat(agent.wallet_balance) || 0,
        averageRating: parseFloat(ratingStats[0]?.average_rating) || 0,
        totalReviews: parseInt(ratingStats[0]?.total_reviews) || 0,
        todayTransactions: parseInt(todayStats[0]?.transactions) || 0,
        todayCommissions: parseFloat(todayStats[0]?.commissions) || 0,
        weeklyTransactions: parseInt(weeklyStats[0]?.transactions) || 0,
        weeklyCommissions: parseFloat(weeklyStats[0]?.commissions) || 0,
        monthlyTransactions: parseInt(monthlyStats[0]?.transactions) || 0,
        monthlyCommissions: parseFloat(monthlyStats[0]?.commissions) || 0,
      };
    } catch (error) {
      logger.error('Error getting dashboard stats', error);
      throw error;
    }
  }

  /**
   * Update agent location
   */
  static async updateLocation(
    agentId: string,
    lat: number,
    lng: number,
    address?: string
  ): Promise<void> {
    try {
      await db.query(
        `UPDATE agents
         SET location_lat = $1, location_lng = $2, location_address = $3, updated_at = NOW()
         WHERE id = $4`,
        [lat, lng, address || null, agentId]
      );

      logger.info('Agent location updated', { agentId, lat, lng });
    } catch (error) {
      logger.error('Error updating agent location', error);
      throw error;
    }
  }

  /**
   * Submit review for agent
   */
  static async submitReview(
    userId: string,
    agentId: string,
    transactionId: string,
    rating: number,
    comment?: string
  ): Promise<any> {
    try {
      // Validate rating
      if (rating < 1 || rating > 5) {
        throw new Error('INVALID_RATING');
      }

      // Check if agent exists
      const agents = await db.query('SELECT id FROM agents WHERE id = $1', [agentId]);

      if (agents.length === 0) {
        throw new Error('AGENT_NOT_FOUND');
      }

      // Check if transaction exists and belongs to user
      const transactions = await db.query(
        `SELECT id FROM transactions
         WHERE id = $1 AND (from_user_id = $2 OR to_user_id = $2)
         AND metadata::jsonb->>'agentId' = $3`,
        [transactionId, userId, agentId]
      );

      if (transactions.length === 0) {
        throw new Error('TRANSACTION_NOT_FOUND');
      }

      // Check if review already exists for this transaction
      const existingReviews = await db.query(
        'SELECT id FROM agent_reviews WHERE transaction_id = $1',
        [transactionId]
      );

      if (existingReviews.length > 0) {
        throw new Error('REVIEW_ALREADY_EXISTS');
      }

      // Create review
      const reviews = await db.query<any>(
        `INSERT INTO agent_reviews (agent_id, user_id, transaction_id, rating, comment)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id, agent_id, user_id, transaction_id, rating, comment, created_at`,
        [agentId, userId, transactionId, rating, comment || null]
      );

      logger.info('Agent review submitted', { agentId, userId, transactionId, rating });

      return {
        id: reviews[0].id,
        agentId: reviews[0].agent_id,
        userId: reviews[0].user_id,
        transactionId: reviews[0].transaction_id,
        rating: reviews[0].rating,
        comment: reviews[0].comment,
        createdAt: reviews[0].created_at,
      };
    } catch (error) {
      logger.error('Error submitting agent review', error);
      throw error;
    }
  }
}
