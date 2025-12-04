import { Response } from 'express';
import { AuthRequest } from '../types';
import { AgentService } from '../services/agent.service';
import { ApiResponseUtil } from '../utils/response';
import logger from '../utils/logger';

export class AgentController {
  /**
   * Register as agent
   */
  static async registerAgent(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { location_lat, location_lng, location_address } = req.body;

      const agent = await AgentService.registerAgent(
        userId,
        location_lat,
        location_lng,
        location_address
      );

      return ApiResponseUtil.created(
        res,
        {
          agent: {
            id: agent.id,
            user_id: agent.user_id,
            wallet_balance: parseFloat(agent.wallet_balance.toString()),
            active_status: agent.active_status,
            verification_status: agent.verification_status,
            location_lat: agent.location_lat,
            location_lng: agent.location_lng,
            location_address: agent.location_address,
            commission_rate: parseFloat(agent.commission_rate.toString()),
            created_at: agent.created_at,
          },
        },
        'Agent registration successful. Your account will be activated after verification.'
      );
    } catch (error: any) {
      logger.error('Register agent error', error);

      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }

      if (error.message === 'ALREADY_REGISTERED_AS_AGENT') {
        return ApiResponseUtil.badRequest(res, 'Already registered as agent');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get agent profile
   */
  static async getProfile(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const profile = await AgentService.getAgentProfile(userId);

      return ApiResponseUtil.success(res, {
        agent: {
          id: profile.id,
          user_id: profile.user_id,
          wallet_balance: profile.wallet_balance,
          active_status: profile.active_status,
          verification_status: profile.verification_status,
          location_lat: profile.location_lat,
          location_lng: profile.location_lng,
          location_address: profile.location_address,
          commission_rate: profile.commission_rate,
          total_commission_earned: profile.total_commission_earned,
          total_transactions_processed: profile.total_transactions_processed,
          verified_at: profile.verified_at,
          created_at: profile.created_at,
          updated_at: profile.updated_at,
          user: profile.user,
          stats: profile.stats,
        },
      });
    } catch (error: any) {
      logger.error('Get agent profile error', error);

      if (error.message === 'AGENT_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Agent profile not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Request wallet credit
   */
  static async requestCredit(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { agent_id, amount, receipt_url, deposit_date, deposit_time, bank_name } = req.body;

      const creditRequest = await AgentService.requestCredit(
        agent_id,
        amount,
        receipt_url,
        deposit_date,
        deposit_time,
        bank_name
      );

      return ApiResponseUtil.created(
        res,
        {
          credit_request: {
            id: creditRequest.id,
            agent_id: creditRequest.agentId,
            amount: creditRequest.amount,
            receipt_url: creditRequest.receiptUrl,
            deposit_date: creditRequest.depositDate,
            deposit_time: creditRequest.depositTime,
            bank_name: creditRequest.bankName,
            status: creditRequest.status,
            created_at: creditRequest.createdAt,
          },
        },
        'Credit request submitted successfully. Your wallet will be credited after admin approval.'
      );
    } catch (error: any) {
      logger.error('Request credit error', error);

      if (error.message === 'AGENT_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Agent not found');
      }

      if (error.message === 'INVALID_AMOUNT') {
        return ApiResponseUtil.badRequest(res, 'Invalid amount');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get credit request history
   */
  static async getCreditRequests(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { agent_id, status, start_date, end_date, page, limit } = req.query;

      const result = await AgentService.getCreditRequests(agent_id as string, {
        status: status as any,
        startDate: start_date as string,
        endDate: end_date as string,
        page: page ? parseInt(page as string) : undefined,
        limit: limit ? parseInt(limit as string) : undefined,
      });

      return ApiResponseUtil.success(
        res,
        {
          credit_requests: result.requests.map((r) => ({
            id: r.id,
            agent_id: r.agentId,
            amount: r.amount,
            receipt_url: r.receiptUrl,
            deposit_date: r.depositDate,
            deposit_time: r.depositTime,
            bank_name: r.bankName,
            status: r.status,
            admin_id: r.adminId,
            rejection_reason: r.rejectionReason,
            approved_at: r.approvedAt,
            rejected_at: r.rejectedAt,
            created_at: r.createdAt,
          })),
        },
        undefined,
        {
          pagination: {
            page: result.page,
            limit: result.limit,
            total: result.total,
            totalPages: Math.ceil(result.total / result.limit),
          },
        }
      );
    } catch (error: any) {
      logger.error('Get credit requests error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Process deposit for user
   */
  static async depositForUser(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { agent_id, user_phone, amount, payment_method } = req.body;

      const transaction = await AgentService.depositForUser(
        agent_id,
        user_phone,
        amount,
        payment_method
      );

      return ApiResponseUtil.created(
        res,
        {
          transaction: {
            id: transaction.id,
            transaction_id: transaction.transaction_id,
            type: transaction.type,
            amount: transaction.amount,
            fee: transaction.fee,
            net_amount: transaction.net_amount,
            status: transaction.status,
            payment_method: transaction.payment_method,
            commission: transaction.commission,
            user: transaction.user,
            created_at: transaction.created_at,
          },
        },
        'Deposit processed successfully'
      );
    } catch (error: any) {
      logger.error('Agent deposit error', error);

      if (error.message === 'AGENT_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Agent not found');
      }

      if (error.message === 'AGENT_NOT_ACTIVE') {
        return ApiResponseUtil.badRequest(res, 'Agent account is not active');
      }

      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }

      if (error.message === 'INVALID_AMOUNT') {
        return ApiResponseUtil.badRequest(res, 'Invalid amount');
      }

      if (error.message === 'INSUFFICIENT_AGENT_BALANCE') {
        return ApiResponseUtil.badRequest(res, 'Insufficient agent wallet balance');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Process withdrawal for user
   */
  static async withdrawForUser(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { agent_id, user_phone, amount } = req.body;

      const transaction = await AgentService.withdrawForUser(agent_id, user_phone, amount);

      return ApiResponseUtil.created(
        res,
        {
          transaction: {
            id: transaction.id,
            transaction_id: transaction.transaction_id,
            type: transaction.type,
            amount: transaction.amount,
            fee: transaction.fee,
            net_amount: transaction.net_amount,
            status: transaction.status,
            payment_method: transaction.payment_method,
            commission: transaction.commission,
            user: transaction.user,
            created_at: transaction.created_at,
          },
        },
        'Withdrawal processed successfully'
      );
    } catch (error: any) {
      logger.error('Agent withdrawal error', error);

      if (error.message === 'AGENT_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Agent not found');
      }

      if (error.message === 'AGENT_NOT_ACTIVE') {
        return ApiResponseUtil.badRequest(res, 'Agent account is not active');
      }

      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }

      if (error.message === 'INVALID_AMOUNT') {
        return ApiResponseUtil.badRequest(res, 'Invalid amount');
      }

      if (error.message === 'INSUFFICIENT_USER_BALANCE') {
        return ApiResponseUtil.badRequest(res, 'Insufficient user wallet balance');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Find nearby agents
   */
  static async getNearbyAgents(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const { latitude, longitude, radius } = req.query;

      if (!latitude || !longitude) {
        return ApiResponseUtil.badRequest(res, 'Latitude and longitude are required');
      }

      const lat = parseFloat(latitude as string);
      const lng = parseFloat(longitude as string);
      const searchRadius = radius ? parseFloat(radius as string) : 10;

      if (isNaN(lat) || isNaN(lng) || isNaN(searchRadius)) {
        return ApiResponseUtil.badRequest(res, 'Invalid coordinates or radius');
      }

      const agents = await AgentService.getNearbyAgents(lat, lng, searchRadius);

      return ApiResponseUtil.success(res, {
        agents: agents.map((agent) => ({
          id: agent.id,
          user_id: agent.userId,
          first_name: agent.firstName,
          last_name: agent.lastName,
          phone: agent.phone,
          profile_picture: agent.profilePicture,
          location: {
            latitude: agent.locationLat,
            longitude: agent.locationLng,
            address: agent.locationAddress,
          },
          distance_km: agent.distance,
          rating: agent.averageRating,
          total_reviews: agent.totalReviews,
          active_status: agent.activeStatus,
          wallet_balance: agent.walletBalance,
        })),
        search_params: {
          latitude: lat,
          longitude: lng,
          radius_km: searchRadius,
        },
        total_found: agents.length,
      });
    } catch (error: any) {
      logger.error('Get nearby agents error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get dashboard statistics
   */
  static async getDashboardStats(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { agent_id } = req.query;

      if (!agent_id) {
        return ApiResponseUtil.badRequest(res, 'Agent ID is required');
      }

      const stats = await AgentService.getDashboardStats(agent_id as string);

      return ApiResponseUtil.success(res, {
        stats: {
          wallet_balance: stats.walletBalance,
          total_transactions: stats.totalTransactions,
          total_commissions_earned: stats.commissionsEarned,
          average_rating: stats.averageRating,
          total_reviews: stats.totalReviews,
          today: {
            transactions: stats.todayTransactions,
            commissions: stats.todayCommissions,
          },
          this_week: {
            transactions: stats.weeklyTransactions,
            commissions: stats.weeklyCommissions,
          },
          this_month: {
            transactions: stats.monthlyTransactions,
            commissions: stats.monthlyCommissions,
          },
        },
      });
    } catch (error: any) {
      logger.error('Get dashboard stats error', error);

      if (error.message === 'AGENT_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Agent not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Update agent location
   */
  static async updateLocation(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { agent_id, latitude, longitude, address } = req.body;

      await AgentService.updateLocation(agent_id, latitude, longitude, address);

      return ApiResponseUtil.success(res, {}, 'Location updated successfully');
    } catch (error: any) {
      logger.error('Update location error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Submit agent review
   */
  static async submitReview(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { agent_id, transaction_id, rating, comment } = req.body;

      const review = await AgentService.submitReview(
        userId,
        agent_id,
        transaction_id,
        rating,
        comment
      );

      return ApiResponseUtil.created(
        res,
        {
          review: {
            id: review.id,
            agent_id: review.agentId,
            user_id: review.userId,
            transaction_id: review.transactionId,
            rating: review.rating,
            comment: review.comment,
            created_at: review.createdAt,
          },
        },
        'Review submitted successfully'
      );
    } catch (error: any) {
      logger.error('Submit review error', error);

      if (error.message === 'AGENT_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Agent not found');
      }

      if (error.message === 'TRANSACTION_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Transaction not found or not authorized');
      }

      if (error.message === 'INVALID_RATING') {
        return ApiResponseUtil.badRequest(res, 'Rating must be between 1 and 5');
      }

      if (error.message === 'REVIEW_ALREADY_EXISTS') {
        return ApiResponseUtil.badRequest(res, 'Review already submitted for this transaction');
      }

      return ApiResponseUtil.internalError(res);
    }
  }
}
