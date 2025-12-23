import db from '../database';
import {
  Election,
  ElectionWithOptions,
  ElectionOption,
  ElectionVote,
  ElectionResult,
  ElectionStats,
  CreateElectionDTO,
  UpdateElectionDTO,
  CastVoteDTO,
  ElectionStatus,
  TransactionType,
  TransactionStatus
} from '../types';
import { AppError } from '../middleware/errorHandler';

export class ElectionService {
  // Admin: Create new election/poll
  async createElection(adminId: string, data: CreateElectionDTO): Promise<ElectionWithOptions> {
    const client = await db.getClient();

    try {
      await client.query('BEGIN');

      // Validate end time is in the future
      const endTime = new Date(data.end_time);
      if (endTime <= new Date()) {
        throw new AppError(400, 'VALIDATION_ERROR', 'End time must be in the future');
      }

      // Validate at least 2 options
      if (!data.options || data.options.length < 2) {
        throw new AppError(400, 'VALIDATION_ERROR', 'Election must have at least 2 options');
      }

      // Create election
      const electionResult = await client.query(
        `INSERT INTO elections (title, question, voting_charge, end_time, created_by, status)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING *`,
        [data.title, data.question, data.voting_charge, endTime, adminId, ElectionStatus.ACTIVE]
      );

      const election = electionResult.rows[0];

      // Create options
      const options: ElectionOption[] = [];
      for (const optionText of data.options) {
        const optionResult = await client.query(
          `INSERT INTO election_options (election_id, option_text)
           VALUES ($1, $2)
           RETURNING *`,
          [election.id, optionText]
        );
        options.push(optionResult.rows[0]);
      }

      await client.query('COMMIT');

      return {
        ...election,
        options
      };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  // Admin: Update election (only before any votes are cast)
  async updateElection(electionId: string, data: UpdateElectionDTO): Promise<ElectionWithOptions> {
    const client = await db.getClient();

    try {
      await client.query('BEGIN');

      // Check if election exists
      const electionCheck = await client.query(
        'SELECT * FROM elections WHERE id = $1',
        [electionId]
      );

      if (electionCheck.rows.length === 0) {
        throw new AppError(404, 'NOT_FOUND', 'Election not found');
      }

      const election = electionCheck.rows[0];

      // Check if any votes have been cast
      const voteCheck = await client.query(
        'SELECT COUNT(*) as count FROM election_votes WHERE election_id = $1',
        [electionId]
      );

      if (parseInt(voteCheck.rows[0].count) > 0) {
        throw new AppError(400, 'VALIDATION_ERROR', 'Cannot modify election after votes have been cast');
      }

      // Update election
      const updateFields: string[] = [];
      const updateValues: any[] = [];
      let paramCount = 1;

      if (data.title !== undefined) {
        updateFields.push(`title = $${paramCount++}`);
        updateValues.push(data.title);
      }
      if (data.question !== undefined) {
        updateFields.push(`question = $${paramCount++}`);
        updateValues.push(data.question);
      }
      if (data.voting_charge !== undefined) {
        updateFields.push(`voting_charge = $${paramCount++}`);
        updateValues.push(data.voting_charge);
      }
      if (data.end_time !== undefined) {
        const endTime = new Date(data.end_time);
        if (endTime <= new Date()) {
          throw new AppError(400, 'VALIDATION_ERROR', 'End time must be in the future');
        }
        updateFields.push(`end_time = $${paramCount++}`);
        updateValues.push(endTime);
      }

      if (updateFields.length > 0) {
        updateFields.push(`updated_at = CURRENT_TIMESTAMP`);
        updateValues.push(electionId);

        await client.query(
          `UPDATE elections SET ${updateFields.join(', ')} WHERE id = $${paramCount}`,
          updateValues
        );
      }

      // Update options if provided
      if (data.options && data.options.length >= 2) {
        // Delete existing options
        await client.query('DELETE FROM election_options WHERE election_id = $1', [electionId]);

        // Create new options
        for (const optionText of data.options) {
          await client.query(
            'INSERT INTO election_options (election_id, option_text) VALUES ($1, $2)',
            [electionId, optionText]
          );
        }
      }

      await client.query('COMMIT');

      // Fetch updated election with options
      return await this.getElectionById(electionId);
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  // Admin: End election before scheduled time
  async endElection(electionId: string): Promise<Election> {
    const result = await db.query<Election>(
      `UPDATE elections
       SET status = $1, ended_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
       WHERE id = $2 AND status = $3
       RETURNING *`,
      [ElectionStatus.ENDED, electionId, ElectionStatus.ACTIVE]
    );

    if (result.length === 0) {
      throw new AppError(404, 'NOT_FOUND', 'Election not found or already ended');
    }

    return result[0];
  }

  // Admin: Pause election
  async pauseElection(electionId: string): Promise<Election> {
    const result = await db.query<Election>(
      `UPDATE elections
       SET status = $1, updated_at = CURRENT_TIMESTAMP
       WHERE id = $2 AND status = $3
       RETURNING *`,
      [ElectionStatus.PAUSED, electionId, ElectionStatus.ACTIVE]
    );

    if (result.length === 0) {
      throw new AppError(404, 'NOT_FOUND', 'Election not found or not active');
    }

    return result[0];
  }

  // Admin: Resume paused election
  async resumeElection(electionId: string): Promise<Election> {
    const result = await db.query<Election>(
      `UPDATE elections
       SET status = $1, updated_at = CURRENT_TIMESTAMP
       WHERE id = $2 AND status = $3
       RETURNING *`,
      [ElectionStatus.ACTIVE, electionId, ElectionStatus.PAUSED]
    );

    if (result.length === 0) {
      throw new AppError(404, 'NOT_FOUND', 'Election not found or not paused');
    }

    return result[0];
  }

  // Admin: Get election statistics with voters
  async getElectionStats(electionId: string): Promise<ElectionStats> {
    const client = await db.getClient();

    try {
      // Get election
      const electionResult = await client.query(
        'SELECT * FROM elections WHERE id = $1',
        [electionId]
      );

      if (electionResult.rows.length === 0) {
        throw new AppError(404, 'NOT_FOUND', 'Election not found');
      }

      const election = electionResult.rows[0];

      // Get options with vote counts
      const optionsResult = await client.query(
        'SELECT * FROM election_options WHERE election_id = $1 ORDER BY id',
        [electionId]
      );

      const totalVotes = election.total_votes || 0;
      const options = optionsResult.rows.map(option => ({
        ...option,
        percentage: totalVotes > 0 ? (option.vote_count / totalVotes) * 100 : 0
      }));

      // Get voters with their choices
      const votersResult = await client.query(
        `SELECT
          ev.user_id,
          u.first_name,
          u.last_name,
          ev.option_id,
          eo.option_text,
          ev.voted_at,
          ev.vote_charge
         FROM election_votes ev
         JOIN users u ON ev.user_id = u.id
         JOIN election_options eo ON ev.option_id = eo.id
         WHERE ev.election_id = $1
         ORDER BY ev.voted_at DESC`,
        [electionId]
      );

      return {
        ...election,
        options,
        voters: votersResult.rows
      };
    } finally {
      client.release();
    }
  }

  // Admin: Get all elections (active and previous)
  async getAllElections(): Promise<ElectionWithOptions[]> {
    const client = await db.getClient();

    try {
      // Auto-end expired elections
      await this.autoEndElections();

      // Get all elections ordered by status and end time
      const electionsResult = await client.query(
        `SELECT * FROM elections
         ORDER BY
           CASE status
             WHEN 'active' THEN 1
             WHEN 'paused' THEN 2
             WHEN 'ended' THEN 3
           END,
           end_time DESC`
      );

      const elections = [];
      for (const election of electionsResult.rows) {
        const optionsResult = await client.query(
          'SELECT * FROM election_options WHERE election_id = $1 ORDER BY id',
          [election.id]
        );

        elections.push({
          ...election,
          options: optionsResult.rows
        });
      }

      return elections;
    } finally {
      client.release();
    }
  }

  // User: Get active elections
  async getActiveElections(userId: string): Promise<ElectionResult[]> {
    const client = await db.getClient();

    try {
      // Auto-end expired elections
      await this.autoEndElections();

      // Get active elections
      const electionsResult = await client.query(
        `SELECT * FROM elections
         WHERE status = $1
         ORDER BY end_time ASC`,
        [ElectionStatus.ACTIVE]
      );

      const elections = [];
      for (const election of electionsResult.rows) {
        // Get options
        const optionsResult = await client.query(
          'SELECT * FROM election_options WHERE election_id = $1 ORDER BY id',
          [election.id]
        );

        // Check if user has voted
        const voteResult = await client.query(
          'SELECT option_id, voted_at FROM election_votes WHERE election_id = $1 AND user_id = $2',
          [election.id, userId]
        );

        elections.push({
          ...election,
          options: optionsResult.rows,
          user_vote: voteResult.rows.length > 0 ? voteResult.rows[0] : undefined
        });
      }

      return elections;
    } finally {
      client.release();
    }
  }

  // User: Get closed elections (that user participated in)
  async getClosedElections(userId: string): Promise<ElectionResult[]> {
    const client = await db.getClient();

    try {
      // Get elections user voted in that are now ended
      const electionsResult = await client.query(
        `SELECT DISTINCT e.*
         FROM elections e
         JOIN election_votes ev ON e.id = ev.election_id
         WHERE ev.user_id = $1 AND e.status = $2
         ORDER BY e.ended_at DESC`,
        [userId, ElectionStatus.ENDED]
      );

      const elections = [];
      for (const election of electionsResult.rows) {
        // Get options with vote counts
        const optionsResult = await client.query(
          'SELECT * FROM election_options WHERE election_id = $1 ORDER BY vote_count DESC',
          [election.id]
        );

        // Get user's vote
        const voteResult = await client.query(
          'SELECT option_id, voted_at, vote_charge FROM election_votes WHERE election_id = $1 AND user_id = $2',
          [election.id, userId]
        );

        elections.push({
          ...election,
          options: optionsResult.rows,
          user_vote: voteResult.rows.length > 0 ? voteResult.rows[0] : undefined
        });
      }

      return elections;
    } finally {
      client.release();
    }
  }

  // User: Cast vote
  async castVote(userId: string, data: CastVoteDTO): Promise<ElectionVote> {
    const client = await db.getClient();

    try {
      await client.query('BEGIN');

      // Check if election exists and is active
      const electionResult = await client.query(
        'SELECT * FROM elections WHERE id = $1',
        [data.election_id]
      );

      if (electionResult.rows.length === 0) {
        throw new AppError(404, 'NOT_FOUND', 'Election not found');
      }

      const election = electionResult.rows[0];

      if (election.status !== ElectionStatus.ACTIVE) {
        throw new AppError(400, 'VALIDATION_ERROR', 'Election is not active');
      }

      if (new Date(election.end_time) < new Date()) {
        throw new AppError(400, 'VALIDATION_ERROR', 'Election has ended');
      }

      // Check if user has already voted
      const existingVoteResult = await client.query(
        'SELECT * FROM election_votes WHERE election_id = $1 AND user_id = $2',
        [data.election_id, userId]
      );

      if (existingVoteResult.rows.length > 0) {
        throw new AppError(400, 'VALIDATION_ERROR', 'You have already voted in this election');
      }

      // Check if option exists
      const optionResult = await client.query(
        'SELECT * FROM election_options WHERE id = $1 AND election_id = $2',
        [data.option_id, data.election_id]
      );

      if (optionResult.rows.length === 0) {
        throw new AppError(400, 'VALIDATION_ERROR', 'Invalid option selected');
      }

      // Check if user has sufficient balance
      const walletResult = await client.query(
        'SELECT balance FROM wallets WHERE user_id = $1',
        [userId]
      );

      if (walletResult.rows.length === 0) {
        throw new AppError(404, 'NOT_FOUND', 'Wallet not found');
      }

      const balance = parseFloat(walletResult.rows[0].balance);
      const votingCharge = parseFloat(election.voting_charge);

      if (balance < votingCharge) {
        throw new AppError(400, 'INSUFFICIENT_BALANCE', 'Insufficient balance to cast vote');
      }

      // Deduct voting charge from wallet
      await client.query(
        'UPDATE wallets SET balance = balance - $1, updated_at = CURRENT_TIMESTAMP WHERE user_id = $2',
        [votingCharge, userId]
      );

      // Create transaction record
      await client.query(
        `INSERT INTO transactions (
          type, from_user_id, amount, fee, net_amount, status, description, metadata
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [
          TransactionType.VOTE,
          userId,
          votingCharge,
          0,
          votingCharge,
          TransactionStatus.COMPLETED,
          `Vote cast for election: ${election.title}`,
          JSON.stringify({ election_id: data.election_id, option_id: data.option_id })
        ]
      );

      // Record vote
      const voteResult = await client.query(
        `INSERT INTO election_votes (election_id, option_id, user_id, vote_charge)
         VALUES ($1, $2, $3, $4)
         RETURNING *`,
        [data.election_id, data.option_id, userId, votingCharge]
      );

      await client.query('COMMIT');

      return voteResult.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  // Get single election by ID
  async getElectionById(electionId: string): Promise<ElectionWithOptions> {
    const client = await db.getClient();

    try {
      const electionResult = await client.query(
        'SELECT * FROM elections WHERE id = $1',
        [electionId]
      );

      if (electionResult.rows.length === 0) {
        throw new AppError(404, 'NOT_FOUND', 'Election not found');
      }

      const optionsResult = await client.query(
        'SELECT * FROM election_options WHERE election_id = $1 ORDER BY id',
        [electionId]
      );

      return {
        ...electionResult.rows[0],
        options: optionsResult.rows
      };
    } finally {
      client.release();
    }
  }

  // Auto-end expired elections
  async autoEndElections(): Promise<void> {
    await db.query(`
      UPDATE elections
      SET status = $1, ended_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
      WHERE status = $2 AND end_time <= CURRENT_TIMESTAMP
    `, [ElectionStatus.ENDED, ElectionStatus.ACTIVE]);
  }

  // Delete election (admin only, only if no votes)
  async deleteElection(electionId: string): Promise<void> {
    const client = await db.getClient();

    try {
      await client.query('BEGIN');

      // Check if any votes exist
      const voteCheck = await client.query(
        'SELECT COUNT(*) as count FROM election_votes WHERE election_id = $1',
        [electionId]
      );

      if (parseInt(voteCheck.rows[0].count) > 0) {
        throw new AppError(400, 'VALIDATION_ERROR', 'Cannot delete election with votes');
      }

      // Delete options (CASCADE will handle this, but being explicit)
      await client.query('DELETE FROM election_options WHERE election_id = $1', [electionId]);

      // Delete election
      const result = await client.query('DELETE FROM elections WHERE id = $1', [electionId]);

      if (result.rowCount === 0) {
        throw new AppError(404, 'NOT_FOUND', 'Election not found');
      }

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}

export default new ElectionService();
