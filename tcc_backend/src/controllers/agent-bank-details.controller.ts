import { Response } from 'express';
import { AgentBankDetailsService, BankDetailsSubmission } from '../services/agent-bank-details.service';
import logger from '../utils/logger';
import { AuthRequest } from '../types';

export class AgentBankDetailsController {
  /**
   * Submit or update bank details for an agent
   */
  static async submitBankDetails(req: AuthRequest, res: Response) {
    try {
      const agentId = req.params.agentId || req.user?.agentId;

      if (!agentId) {
        return res.status(400).json({
          success: false,
          error: 'Agent ID is required'
        });
      }

      const bankDetails: BankDetailsSubmission = req.body;

      // Validate required fields
      if (!bankDetails.bank_name ||
          !bankDetails.branch_address ||
          !bankDetails.ifsc_code ||
          !bankDetails.account_holder_name) {
        return res.status(400).json({
          success: false,
          error: 'Missing required bank details fields'
        });
      }

      // Validate IFSC code format (Indian banks)
      const ifscRegex = /^[A-Z]{4}0[A-Z0-9]{6}$/;
      if (!ifscRegex.test(bankDetails.ifsc_code)) {
        return res.status(400).json({
          success: false,
          error: 'Invalid IFSC code format'
        });
      }

      const result = await AgentBankDetailsService.submitBankDetails(
        agentId,
        bankDetails
      );

      res.json({
        success: true,
        data: result,
        message: 'Bank details submitted successfully'
      });
    } catch (error: any) {
      logger.error('Error in submitBankDetails controller', error);

      if (error.message === 'AGENT_NOT_FOUND') {
        return res.status(404).json({
          success: false,
          error: 'Agent not found'
        });
      }

      res.status(500).json({
        success: false,
        error: 'Failed to submit bank details'
      });
    }
  }

  /**
   * Get bank details for an agent
   */
  static async getBankDetails(req: AuthRequest, res: Response) {
    try {
      const agentId = req.params.agentId || req.user?.agentId;

      if (!agentId) {
        return res.status(400).json({
          success: false,
          error: 'Agent ID is required'
        });
      }

      const bankDetails = await AgentBankDetailsService.getBankDetails(agentId);

      if (!bankDetails) {
        return res.status(404).json({
          success: false,
          error: 'Bank details not found'
        });
      }

      res.json({
        success: true,
        data: bankDetails
      });
    } catch (error) {
      logger.error('Error in getBankDetails controller', error);
      res.status(500).json({
        success: false,
        error: 'Failed to get bank details'
      });
    }
  }

  /**
   * Admin: Get all bank details for review
   */
  static async getAllBankDetailsForAdmin(req: AuthRequest, res: Response) {
    try {
      // Check if user is admin
      if (req.user?.role !== 'ADMIN' && req.user?.role !== 'SUPER_ADMIN') {
        return res.status(403).json({
          success: false,
          error: 'Access denied. Admin only.'
        });
      }

      const limit = parseInt(req.query.limit as string) || 20;
      const offset = parseInt(req.query.offset as string) || 0;

      const result = await AgentBankDetailsService.getAllBankDetailsForAdmin(
        limit,
        offset
      );

      res.json({
        success: true,
        data: result.details,
        total: result.total,
        limit,
        offset
      });
    } catch (error) {
      logger.error('Error in getAllBankDetailsForAdmin controller', error);
      res.status(500).json({
        success: false,
        error: 'Failed to get bank details'
      });
    }
  }

  /**
   * Admin: Verify bank details
   */
  static async verifyBankDetails(req: AuthRequest, res: Response) {
    try {
      // Check if user is admin
      if (req.user?.role !== 'ADMIN' && req.user?.role !== 'SUPER_ADMIN') {
        return res.status(403).json({
          success: false,
          error: 'Access denied. Admin only.'
        });
      }

      const { bankDetailsId } = req.params;
      const { isVerified, notes } = req.body;
      const adminId = req.user.id;

      if (typeof isVerified !== 'boolean') {
        return res.status(400).json({
          success: false,
          error: 'isVerified must be a boolean'
        });
      }

      const result = await AgentBankDetailsService.verifyBankDetails(
        bankDetailsId,
        adminId,
        isVerified,
        notes
      );

      res.json({
        success: true,
        data: result,
        message: `Bank details ${isVerified ? 'verified' : 'rejected'} successfully`
      });
    } catch (error: any) {
      logger.error('Error in verifyBankDetails controller', error);

      if (error.message === 'BANK_DETAILS_NOT_FOUND') {
        return res.status(404).json({
          success: false,
          error: 'Bank details not found'
        });
      }

      res.status(500).json({
        success: false,
        error: 'Failed to verify bank details'
      });
    }
  }

  /**
   * Delete bank details
   */
  static async deleteBankDetails(req: AuthRequest, res: Response) {
    try {
      const { bankDetailsId } = req.params;
      const agentId = req.user?.agentId;

      if (!agentId) {
        return res.status(400).json({
          success: false,
          error: 'Agent ID is required'
        });
      }

      const deleted = await AgentBankDetailsService.deleteBankDetails(
        bankDetailsId,
        agentId
      );

      if (!deleted) {
        return res.status(404).json({
          success: false,
          error: 'Bank details not found or unauthorized'
        });
      }

      res.json({
        success: true,
        message: 'Bank details deleted successfully'
      });
    } catch (error) {
      logger.error('Error in deleteBankDetails controller', error);
      res.status(500).json({
        success: false,
        error: 'Failed to delete bank details'
      });
    }
  }
}