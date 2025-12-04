import { Response } from 'express';
import { AuthRequest } from '../types';
import { PollService } from '../services/poll.service';
import { ApiResponseUtil } from '../utils/response';
import logger from '../utils/logger';

export class PollController {
  /**
   * Get all active polls
   */
  static async getActivePolls(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      const polls = await PollService.getActivePolls(userId);

      return ApiResponseUtil.success(res, {
        polls,
        count: polls.length,
      });
    } catch (error: any) {
      logger.error('Get active polls error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get poll details with results (visible after voting)
   */
  static async getPollDetails(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      const { pollId } = req.params;

      const poll = await PollService.getPollDetails(pollId, userId);

      return ApiResponseUtil.success(res, { poll });
    } catch (error: any) {
      logger.error('Get poll details error', error);

      if (error.message === 'POLL_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Poll not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Request OTP for voting
   */
  static async requestVoteOTP(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const result = await PollService.requestVoteOTP(userId);

      return ApiResponseUtil.success(
        res,
        {
          otp_sent: result.otpSent,
          phone: result.phone,
          otp_expires_in: result.otpExpiresIn,
        },
        'OTP sent to your registered phone number'
      );
    } catch (error: any) {
      logger.error('Request vote OTP error', error);

      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Cast a vote on a poll
   */
  static async vote(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { poll_id, selected_option, otp } = req.body;

      const result = await PollService.vote(userId, poll_id, selected_option, otp);

      return ApiResponseUtil.created(
        res,
        {
          vote: result.vote,
          transaction: result.transaction,
          poll_title: result.poll_title,
        },
        'Vote cast successfully'
      );
    } catch (error: any) {
      logger.error('Vote error', error);

      if (error.message === 'POLL_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Poll not found');
      }

      if (error.message === 'POLL_NOT_ACTIVE') {
        return ApiResponseUtil.badRequest(res, 'Poll is not active');
      }

      if (error.message === 'POLL_NOT_STARTED') {
        return ApiResponseUtil.badRequest(res, 'Poll has not started yet');
      }

      if (error.message === 'POLL_ENDED') {
        return ApiResponseUtil.badRequest(res, 'Poll has ended');
      }

      if (error.message === 'INVALID_OPTION') {
        return ApiResponseUtil.badRequest(res, 'Invalid option selected');
      }

      if (error.message === 'ALREADY_VOTED') {
        return ApiResponseUtil.badRequest(res, 'You have already voted on this poll');
      }

      if (error.message === 'INSUFFICIENT_BALANCE') {
        return ApiResponseUtil.badRequest(res, 'Insufficient wallet balance to cast vote');
      }

      if (error.message === 'INVALID_OTP' || error.message.includes('OTP')) {
        return ApiResponseUtil.badRequest(res, error.message);
      }

      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }

      if (error.message === 'WALLET_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Wallet not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get user's voting history
   */
  static async getUserVotes(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const votes = await PollService.getUserVotes(userId);

      return ApiResponseUtil.success(res, {
        votes,
        count: votes.length,
      });
    } catch (error: any) {
      logger.error('Get user votes error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Admin: Create a new poll
   */
  static async adminCreatePoll(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const adminId = req.user?.id;

      if (!adminId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { title, description, vote_charge, options, start_date, end_date } = req.body;

      const poll = await PollService.adminCreatePoll(
        adminId,
        title,
        description,
        vote_charge,
        options,
        new Date(start_date),
        new Date(end_date)
      );

      return ApiResponseUtil.created(
        res,
        { poll },
        'Poll created successfully. Publish it to make it active.'
      );
    } catch (error: any) {
      logger.error('Admin create poll error', error);

      if (error.message === 'UNAUTHORIZED_ADMIN') {
        return ApiResponseUtil.forbidden(res, 'Admin access required');
      }

      if (error.message === 'INVALID_TITLE') {
        return ApiResponseUtil.badRequest(res, 'Invalid poll title');
      }

      if (error.message === 'INVALID_DESCRIPTION') {
        return ApiResponseUtil.badRequest(res, 'Invalid poll description');
      }

      if (error.message === 'INVALID_VOTE_CHARGE') {
        return ApiResponseUtil.badRequest(res, 'Invalid vote charge amount');
      }

      if (error.message === 'MINIMUM_TWO_OPTIONS_REQUIRED') {
        return ApiResponseUtil.badRequest(res, 'At least 2 options are required');
      }

      if (error.message === 'MAXIMUM_TEN_OPTIONS_ALLOWED') {
        return ApiResponseUtil.badRequest(res, 'Maximum 10 options allowed');
      }

      if (error.message === 'END_DATE_MUST_BE_AFTER_START_DATE') {
        return ApiResponseUtil.badRequest(res, 'End date must be after start date');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Admin: Publish a poll (DRAFT -> ACTIVE)
   */
  static async adminPublishPoll(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const adminId = req.user?.id;

      if (!adminId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { pollId } = req.params;

      const poll = await PollService.adminPublishPoll(adminId, pollId);

      return ApiResponseUtil.success(res, { poll }, 'Poll published successfully');
    } catch (error: any) {
      logger.error('Admin publish poll error', error);

      if (error.message === 'UNAUTHORIZED_ADMIN') {
        return ApiResponseUtil.forbidden(res, 'Admin access required');
      }

      if (error.message === 'POLL_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Poll not found');
      }

      if (error.message === 'POLL_NOT_IN_DRAFT_STATUS') {
        return ApiResponseUtil.badRequest(res, 'Only draft polls can be published');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Admin: Get poll revenue analytics
   */
  static async adminGetPollRevenue(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const adminId = req.user?.id;

      if (!adminId) {
        return ApiResponseUtil.unauthorized(res);
      }

      const { pollId } = req.params;

      const analytics = await PollService.adminGetPollRevenue(adminId, pollId);

      return ApiResponseUtil.success(res, { analytics });
    } catch (error: any) {
      logger.error('Admin get poll revenue error', error);

      if (error.message === 'UNAUTHORIZED_ADMIN') {
        return ApiResponseUtil.forbidden(res, 'Admin access required');
      }

      if (error.message === 'POLL_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Poll not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }
}
