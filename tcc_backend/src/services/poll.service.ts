// @ts-nocheck
import { PoolClient } from 'pg';
import db from '../database';
import { OTPService } from './otp.service';
import logger from '../utils/logger';
import { PollStatus, TransactionType, TransactionStatus, UserRole } from '../types';

interface PollOption {
  id: string;
  text: string;
  votes: number;
  revenue: number;
}

interface Poll {
  id: string;
  title: string;
  question: string;
  options: any;
  voting_charge: number;
  start_time: Date;
  end_time: Date;
  status: PollStatus;
  created_by_admin_id: string;
  total_votes: number;
  total_revenue: number;
  results: any;
  created_at: Date;
  updated_at: Date;
}

interface Vote {
  id: string;
  poll_id: string;
  user_id: string;
  selected_option: string;
  amount_paid: number;
  transaction_id: string;
  voted_at: Date;
}

export class PollService {
  /**
   * Get all active polls with options and their details
   */
  static async getActivePolls(userId?: string): Promise<any[]> {
    try {
      const polls = await db.query<Poll>(
        `SELECT
          id, title, question, options, voting_charge,
          start_time, end_time, status, total_votes, total_revenue,
          created_at, updated_at
         FROM polls
         WHERE status = $1
           AND start_time <= NOW()
           AND end_time > NOW()
         ORDER BY created_at DESC`,
        [PollStatus.ACTIVE]
      );

      // For each poll, check if user has already voted
      const pollsWithVoteStatus = await Promise.all(
        polls.map(async (poll) => {
          let hasVoted = false;
          let userVote = null;

          if (userId) {
            const votes = await db.query<Vote>(
              `SELECT selected_option, voted_at
               FROM votes
               WHERE poll_id = $1 AND user_id = $2`,
              [poll.id, userId]
            );

            if (votes.length > 0) {
              hasVoted = true;
              userVote = {
                selected_option: votes[0].selected_option,
                voted_at: votes[0].voted_at,
              };
            }
          }

          // Parse options from JSONB
          const options = Array.isArray(poll.options) ? poll.options : [];

          return {
            id: poll.id,
            title: poll.title,
            question: poll.question,
            options: options,
            voting_charge: parseFloat(poll.voting_charge.toString()),
            start_time: poll.start_time,
            end_time: poll.end_time,
            status: poll.status,
            total_votes: poll.total_votes,
            has_voted: hasVoted,
            user_vote: userVote,
            created_at: poll.created_at,
          };
        })
      );

      return pollsWithVoteStatus;
    } catch (error) {
      logger.error('Error getting active polls', error);
      throw error;
    }
  }

  /**
   * Get poll details with current results
   * Results are only visible to users who have voted or after poll ends
   */
  static async getPollDetails(pollId: string, userId?: string): Promise<any> {
    try {
      const polls = await db.query<Poll>(
        `SELECT
          id, title, question, options, voting_charge,
          start_time, end_time, status, total_votes, total_revenue,
          results, created_by_admin_id, created_at, updated_at
         FROM polls
         WHERE id = $1`,
        [pollId]
      );

      if (polls.length === 0) {
        throw new Error('POLL_NOT_FOUND');
      }

      const poll = polls[0];

      // Check if user has voted
      let hasVoted = false;
      let userVote = null;

      if (userId) {
        const votes = await db.query<Vote>(
          `SELECT selected_option, amount_paid, voted_at
           FROM votes
           WHERE poll_id = $1 AND user_id = $2`,
          [pollId, userId]
        );

        if (votes.length > 0) {
          hasVoted = true;
          userVote = {
            selected_option: votes[0].selected_option,
            amount_paid: parseFloat(votes[0].amount_paid.toString()),
            voted_at: votes[0].voted_at,
          };
        }
      }

      // Parse options and results
      const options = Array.isArray(poll.options) ? poll.options : [];
      const results = poll.results || {};

      // Determine if results should be shown
      const isPollEnded = new Date(poll.end_time) < new Date();
      const showResults = hasVoted || isPollEnded || poll.status === PollStatus.CLOSED;

      // Calculate percentages for results
      let processedResults = null;
      if (showResults && poll.total_votes > 0) {
        processedResults = options.map((option: string) => {
          const votes = results[option] || 0;
          const percentage = (votes / poll.total_votes) * 100;

          return {
            option: option,
            votes: votes,
            percentage: parseFloat(percentage.toFixed(2)),
          };
        });
      }

      return {
        id: poll.id,
        title: poll.title,
        question: poll.question,
        options: options,
        voting_charge: parseFloat(poll.voting_charge.toString()),
        start_time: poll.start_time,
        end_time: poll.end_time,
        status: poll.status,
        total_votes: poll.total_votes,
        total_revenue: parseFloat(poll.total_revenue.toString()),
        has_voted: hasVoted,
        user_vote: userVote,
        results: processedResults,
        show_results: showResults,
        created_at: poll.created_at,
        updated_at: poll.updated_at,
      };
    } catch (error) {
      logger.error('Error getting poll details', error);
      throw error;
    }
  }

  /**
   * Cast a vote on a poll (requires payment from wallet)
   */
  static async vote(
    userId: string,
    pollId: string,
    selectedOption: string,
    otp: string
  ): Promise<any> {
    try {
      // Get user details for OTP verification
      const users = await db.query(
        'SELECT phone, country_code FROM users WHERE id = $1',
        [userId]
      );

      if (users.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      const user = users[0];

      // Verify OTP
      const otpResult = await OTPService.verifyOTP(
        user.phone,
        user.country_code,
        otp,
        'VOTE'
      );

      if (!otpResult.valid) {
        throw new Error(otpResult.error || 'INVALID_OTP');
      }

      // Get poll details
      const polls = await db.query<Poll>(
        `SELECT id, title, question, options, voting_charge,
                start_time, end_time, status, results
         FROM polls
         WHERE id = $1`,
        [pollId]
      );

      if (polls.length === 0) {
        throw new Error('POLL_NOT_FOUND');
      }

      const poll = polls[0];

      // Validate poll is active and within time range
      if (poll.status !== PollStatus.ACTIVE) {
        throw new Error('POLL_NOT_ACTIVE');
      }

      const now = new Date();
      if (new Date(poll.start_time) > now) {
        throw new Error('POLL_NOT_STARTED');
      }

      if (new Date(poll.end_time) < now) {
        throw new Error('POLL_ENDED');
      }

      // Validate selected option exists
      const options = Array.isArray(poll.options) ? poll.options : [];
      if (!options.includes(selectedOption)) {
        throw new Error('INVALID_OPTION');
      }

      // Check if user has already voted
      const existingVotes = await db.query(
        'SELECT id FROM votes WHERE poll_id = $1 AND user_id = $2',
        [pollId, userId]
      );

      if (existingVotes.length > 0) {
        throw new Error('ALREADY_VOTED');
      }

      // Get user's wallet balance
      const wallets = await db.query(
        'SELECT balance FROM wallets WHERE user_id = $1',
        [userId]
      );

      if (wallets.length === 0) {
        throw new Error('WALLET_NOT_FOUND');
      }

      const wallet = wallets[0];
      const votingCharge = parseFloat(poll.voting_charge.toString());

      // Check sufficient balance
      if (parseFloat(wallet.balance) < votingCharge) {
        throw new Error('INSUFFICIENT_BALANCE');
      }

      // Process vote in transaction
      const result = await db.transaction(async (client: PoolClient) => {
        // Generate transaction ID
        const transactionId = this.generateTransactionId();

        // Create transaction record
        const transactions = await client.query(
          `INSERT INTO transactions (
            transaction_id, type, from_user_id, amount, fee, net_amount,
            status, description, metadata, processed_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
          RETURNING id, transaction_id, amount, status, created_at`,
          [
            transactionId,
            TransactionType.VOTE,
            userId,
            votingCharge,
            0,
            votingCharge,
            TransactionStatus.COMPLETED,
            `Vote for poll: ${poll.title}`,
            JSON.stringify({
              poll_id: pollId,
              selected_option: selectedOption,
            }),
          ]
        );

        const transaction = transactions[0];

        // Deduct from wallet
        await client.query(
          `UPDATE wallets
           SET balance = balance - $1,
               last_transaction_at = NOW(),
               updated_at = NOW()
           WHERE user_id = $2`,
          [votingCharge, userId]
        );

        // Record the vote
        const votes = await client.query(
          `INSERT INTO votes (
            poll_id, user_id, selected_option, amount_paid, transaction_id
          ) VALUES ($1, $2, $3, $4, $5)
          RETURNING id, poll_id, selected_option, amount_paid, voted_at`,
          [pollId, userId, selectedOption, votingCharge, transaction.id]
        );

        const vote = votes[0];

        // Update poll statistics
        const currentResults = poll.results || {};
        currentResults[selectedOption] = (currentResults[selectedOption] || 0) + 1;

        await client.query(
          `UPDATE polls
           SET total_votes = total_votes + 1,
               total_revenue = total_revenue + $1,
               results = $2,
               updated_at = NOW()
           WHERE id = $3`,
          [votingCharge, JSON.stringify(currentResults), pollId]
        );

        return {
          vote,
          transaction,
          poll_title: poll.title,
        };
      });

      logger.info('Vote cast successfully', {
        userId,
        pollId,
        selectedOption,
        amount: votingCharge,
      });

      return {
        vote: {
          id: result.vote.id,
          poll_id: result.vote.poll_id,
          selected_option: result.vote.selected_option,
          amount_paid: parseFloat(result.vote.amount_paid),
          voted_at: result.vote.voted_at,
        },
        transaction: {
          id: result.transaction.id,
          transaction_id: result.transaction.transaction_id,
          amount: parseFloat(result.transaction.amount),
          status: result.transaction.status,
          created_at: result.transaction.created_at,
        },
        poll_title: result.poll_title,
      };
    } catch (error) {
      logger.error('Error casting vote', error);
      throw error;
    }
  }

  /**
   * Get user's voting history
   */
  static async getUserVotes(userId: string): Promise<any[]> {
    try {
      const votes = await db.query(
        `SELECT
          v.id, v.poll_id, v.selected_option, v.amount_paid, v.voted_at,
          p.title as poll_title, p.question as poll_question,
          p.status as poll_status, p.end_time as poll_end_time,
          t.transaction_id
         FROM votes v
         JOIN polls p ON v.poll_id = p.id
         JOIN transactions t ON v.transaction_id = t.id
         WHERE v.user_id = $1
         ORDER BY v.voted_at DESC`,
        [userId]
      );

      return votes.map((vote) => ({
        id: vote.id,
        poll_id: vote.poll_id,
        poll_title: vote.poll_title,
        poll_question: vote.poll_question,
        poll_status: vote.poll_status,
        poll_end_time: vote.poll_end_time,
        selected_option: vote.selected_option,
        amount_paid: parseFloat(vote.amount_paid),
        transaction_id: vote.transaction_id,
        voted_at: vote.voted_at,
      }));
    } catch (error) {
      logger.error('Error getting user votes', error);
      throw error;
    }
  }

  /**
   * Admin: Create a new poll
   */
  static async adminCreatePoll(
    adminId: string,
    title: string,
    description: string,
    voteCharge: number,
    options: string[],
    startDate: Date,
    endDate: Date
  ): Promise<any> {
    try {
      // Validate admin role
      const admins = await db.query(
        `SELECT role FROM users WHERE id = $1 AND role IN ($2, $3)`,
        [adminId, UserRole.ADMIN, UserRole.SUPER_ADMIN]
      );

      if (admins.length === 0) {
        throw new Error('UNAUTHORIZED_ADMIN');
      }

      // Validate inputs
      if (!title || title.trim().length === 0) {
        throw new Error('INVALID_TITLE');
      }

      if (!description || description.trim().length === 0) {
        throw new Error('INVALID_DESCRIPTION');
      }

      if (voteCharge < 0) {
        throw new Error('INVALID_VOTE_CHARGE');
      }

      if (!options || options.length < 2) {
        throw new Error('MINIMUM_TWO_OPTIONS_REQUIRED');
      }

      if (options.length > 10) {
        throw new Error('MAXIMUM_TEN_OPTIONS_ALLOWED');
      }

      // Validate dates
      const start = new Date(startDate);
      const end = new Date(endDate);

      if (end <= start) {
        throw new Error('END_DATE_MUST_BE_AFTER_START_DATE');
      }

      // Create poll
      const polls = await db.query(
        `INSERT INTO polls (
          title, question, options, voting_charge,
          start_time, end_time, status, created_by_admin_id
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING id, title, question, options, voting_charge,
                  start_time, end_time, status, total_votes, total_revenue,
                  created_at, updated_at`,
        [
          title,
          description,
          JSON.stringify(options),
          voteCharge,
          start,
          end,
          PollStatus.DRAFT,
          adminId,
        ]
      );

      const poll = polls[0];

      logger.info('Poll created by admin', { adminId, pollId: poll.id });

      return {
        id: poll.id,
        title: poll.title,
        question: poll.question,
        options: JSON.parse(poll.options),
        voting_charge: parseFloat(poll.voting_charge),
        start_time: poll.start_time,
        end_time: poll.end_time,
        status: poll.status,
        total_votes: poll.total_votes,
        total_revenue: parseFloat(poll.total_revenue),
        created_at: poll.created_at,
        updated_at: poll.updated_at,
      };
    } catch (error) {
      logger.error('Error creating poll', error);
      throw error;
    }
  }

  /**
   * Admin: Publish a poll (change status from DRAFT to ACTIVE)
   */
  static async adminPublishPoll(adminId: string, pollId: string): Promise<any> {
    try {
      // Validate admin role
      const admins = await db.query(
        `SELECT role FROM users WHERE id = $1 AND role IN ($2, $3)`,
        [adminId, UserRole.ADMIN, UserRole.SUPER_ADMIN]
      );

      if (admins.length === 0) {
        throw new Error('UNAUTHORIZED_ADMIN');
      }

      // Get poll
      const polls = await db.query<Poll>(
        `SELECT id, title, status, start_time, end_time, created_by_admin_id
         FROM polls
         WHERE id = $1`,
        [pollId]
      );

      if (polls.length === 0) {
        throw new Error('POLL_NOT_FOUND');
      }

      const poll = polls[0];

      // Check if poll is in DRAFT status
      if (poll.status !== PollStatus.DRAFT) {
        throw new Error('POLL_NOT_IN_DRAFT_STATUS');
      }

      // Update status to ACTIVE
      const updated = await db.query(
        `UPDATE polls
         SET status = $1, updated_at = NOW()
         WHERE id = $2
         RETURNING id, title, question, options, voting_charge,
                   start_time, end_time, status, total_votes, total_revenue,
                   created_at, updated_at`,
        [PollStatus.ACTIVE, pollId]
      );

      const updatedPoll = updated[0];

      logger.info('Poll published by admin', { adminId, pollId });

      return {
        id: updatedPoll.id,
        title: updatedPoll.title,
        question: updatedPoll.question,
        options: JSON.parse(updatedPoll.options),
        voting_charge: parseFloat(updatedPoll.voting_charge),
        start_time: updatedPoll.start_time,
        end_time: updatedPoll.end_time,
        status: updatedPoll.status,
        total_votes: updatedPoll.total_votes,
        total_revenue: parseFloat(updatedPoll.total_revenue),
        created_at: updatedPoll.created_at,
        updated_at: updatedPoll.updated_at,
      };
    } catch (error) {
      logger.error('Error publishing poll', error);
      throw error;
    }
  }

  /**
   * Admin: Get revenue analytics per option for a poll
   */
  static async adminGetPollRevenue(adminId: string, pollId: string): Promise<any> {
    try {
      // Validate admin role
      const admins = await db.query(
        `SELECT role FROM users WHERE id = $1 AND role IN ($2, $3)`,
        [adminId, UserRole.ADMIN, UserRole.SUPER_ADMIN]
      );

      if (admins.length === 0) {
        throw new Error('UNAUTHORIZED_ADMIN');
      }

      // Get poll details
      const polls = await db.query<Poll>(
        `SELECT id, title, question, options, voting_charge,
                start_time, end_time, status, total_votes, total_revenue, results
         FROM polls
         WHERE id = $1`,
        [pollId]
      );

      if (polls.length === 0) {
        throw new Error('POLL_NOT_FOUND');
      }

      const poll = polls[0];
      const options = JSON.parse(poll.options);
      const results = poll.results || {};
      const voteCharge = parseFloat(poll.voting_charge);

      // Calculate revenue per option
      const revenueByOption = options.map((option: string) => {
        const votes = results[option] || 0;
        const revenue = votes * voteCharge;
        const percentage = poll.total_votes > 0 ? (votes / poll.total_votes) * 100 : 0;

        return {
          option: option,
          votes: votes,
          percentage: parseFloat(percentage.toFixed(2)),
          revenue: parseFloat(revenue.toFixed(2)),
        };
      });

      // Get vote details by date
      const votesByDate = await db.query(
        `SELECT
          DATE(voted_at) as vote_date,
          COUNT(*) as votes_count,
          SUM(amount_paid) as revenue
         FROM votes
         WHERE poll_id = $1
         GROUP BY DATE(voted_at)
         ORDER BY vote_date DESC`,
        [pollId]
      );

      logger.info('Poll revenue analytics retrieved', { adminId, pollId });

      return {
        poll: {
          id: poll.id,
          title: poll.title,
          question: poll.question,
          status: poll.status,
          start_time: poll.start_time,
          end_time: poll.end_time,
          voting_charge: voteCharge,
        },
        summary: {
          total_votes: poll.total_votes,
          total_revenue: parseFloat(poll.total_revenue),
          average_revenue_per_vote: poll.total_votes > 0
            ? parseFloat((parseFloat(poll.total_revenue) / poll.total_votes).toFixed(2))
            : 0,
        },
        revenue_by_option: revenueByOption,
        votes_by_date: votesByDate.map((row) => ({
          date: row.vote_date,
          votes: parseInt(row.votes_count),
          revenue: parseFloat(row.revenue),
        })),
      };
    } catch (error) {
      logger.error('Error getting poll revenue', error);
      throw error;
    }
  }

  /**
   * Request OTP for voting
   */
  static async requestVoteOTP(userId: string): Promise<{ otpSent: boolean; phone: string; otpExpiresIn: number }> {
    try {
      const users = await db.query(
        'SELECT phone, country_code FROM users WHERE id = $1',
        [userId]
      );

      if (users.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      const user = users[0];

      // Generate and send OTP
      const { expiresIn } = await OTPService.createOTP(
        user.phone,
        user.country_code,
        'VOTE'
      );
      await OTPService.sendOTP(user.phone, user.country_code, user.phone);

      const maskedPhone = `****${user.phone.slice(-4)}`;

      logger.info('Vote OTP sent', { userId });

      return {
        otpSent: true,
        phone: maskedPhone,
        otpExpiresIn: expiresIn,
      };
    } catch (error) {
      logger.error('Error sending vote OTP', error);
      throw error;
    }
  }

  /**
   * Generate unique transaction ID
   */
  private static generateTransactionId(): string {
    const date = new Date();
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const dateStr = `${year}${month}${day}`;
    const randomDigits = Math.floor(100000 + Math.random() * 900000);
    return `TXN${dateStr}${randomDigits}`;
  }
}
