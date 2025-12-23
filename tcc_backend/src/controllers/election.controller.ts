import { Response } from 'express';
import { AuthRequest, ApiResponse } from '../types';
import electionService from '../services/election.service';
import { AppError } from '../middleware/errorHandler';

export class ElectionController {
  // Admin: Create new election
  async createElection(req: AuthRequest, res: Response): Promise<void> {
    try {
      const adminId = req.user?.id;
      if (!adminId) {
        throw new AppError(401, 'UNAUTHORIZED', 'Unauthorized');
      }

      const election = await electionService.createElection(adminId, req.body);

      const response: ApiResponse = {
        success: true,
        data: election,
        message: 'Election created successfully'
      };

      res.status(201).json(response);
    } catch (error) {
      throw error;
    }
  }

  // Admin: Update election
  async updateElection(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { electionId } = req.params;
      const election = await electionService.updateElection(electionId, req.body);

      const response: ApiResponse = {
        success: true,
        data: election,
        message: 'Election updated successfully'
      };

      res.json(response);
    } catch (error) {
      throw error;
    }
  }

  // Admin: End election
  async endElection(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { electionId } = req.params;
      const election = await electionService.endElection(electionId);

      const response: ApiResponse = {
        success: true,
        data: election,
        message: 'Election ended successfully'
      };

      res.json(response);
    } catch (error) {
      throw error;
    }
  }

  // Admin: Pause election
  async pauseElection(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { electionId } = req.params;
      const election = await electionService.pauseElection(electionId);

      const response: ApiResponse = {
        success: true,
        data: election,
        message: 'Election paused successfully'
      };

      res.json(response);
    } catch (error) {
      throw error;
    }
  }

  // Admin: Resume election
  async resumeElection(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { electionId } = req.params;
      const election = await electionService.resumeElection(electionId);

      const response: ApiResponse = {
        success: true,
        data: election,
        message: 'Election resumed successfully'
      };

      res.json(response);
    } catch (error) {
      throw error;
    }
  }

  // Admin: Get election statistics
  async getElectionStats(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { electionId } = req.params;
      const stats = await electionService.getElectionStats(electionId);

      const response: ApiResponse = {
        success: true,
        data: stats
      };

      res.json(response);
    } catch (error) {
      throw error;
    }
  }

  // Admin: Get all elections
  async getAllElections(req: AuthRequest, res: Response): Promise<void> {
    try {
      const elections = await electionService.getAllElections();

      const response: ApiResponse = {
        success: true,
        data: elections
      };

      res.json(response);
    } catch (error) {
      throw error;
    }
  }

  // Admin: Delete election
  async deleteElection(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { electionId } = req.params;
      await electionService.deleteElection(electionId);

      const response: ApiResponse = {
        success: true,
        message: 'Election deleted successfully'
      };

      res.json(response);
    } catch (error) {
      throw error;
    }
  }

  // User: Get active elections
  async getActiveElections(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        throw new AppError(401, 'UNAUTHORIZED', 'Unauthorized');
      }

      const elections = await electionService.getActiveElections(userId);

      const response: ApiResponse = {
        success: true,
        data: elections
      };

      res.json(response);
    } catch (error) {
      throw error;
    }
  }

  // User: Get closed elections
  async getClosedElections(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        throw new AppError(401, 'UNAUTHORIZED', 'Unauthorized');
      }

      const elections = await electionService.getClosedElections(userId);

      const response: ApiResponse = {
        success: true,
        data: elections
      };

      res.json(response);
    } catch (error) {
      throw error;
    }
  }

  // User: Cast vote
  async castVote(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        throw new AppError(401, 'UNAUTHORIZED', 'Unauthorized');
      }

      const vote = await electionService.castVote(userId, req.body);

      const response: ApiResponse = {
        success: true,
        data: vote,
        message: 'Vote cast successfully'
      };

      res.status(201).json(response);
    } catch (error) {
      throw error;
    }
  }

  // Get single election
  async getElection(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { electionId } = req.params;
      const election = await electionService.getElectionById(electionId);

      const response: ApiResponse = {
        success: true,
        data: election
      };

      res.json(response);
    } catch (error) {
      throw error;
    }
  }
}

export default new ElectionController();
