import { Response } from 'express';
import { AuthRequest, DocumentType, KYCStatus } from '../types';
import { KYCService } from '../services/kyc.service';
import { ApiResponseUtil } from '../utils/response';
import logger from '../utils/logger';

export class KYCController {
  /**
   * Submit KYC documents
   * POST /api/kyc/submit
   */
  static async submitKYC(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      const {
        document_type,
        document_number,
        front_image_url,
        back_image_url,
        selfie_url,
      } = req.body;

      const result = await KYCService.submitKYC(
        userId,
        document_type as DocumentType,
        document_number,
        front_image_url,
        back_image_url,
        selfie_url
      );

      return ApiResponseUtil.created(
        res,
        {
          submitted: result.submitted,
          documents_count: result.documents.length,
        },
        'KYC documents submitted successfully and are under review'
      );
    } catch (error: any) {
      logger.error('Submit KYC error', error);

      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }
      if (error.message === 'KYC_ALREADY_APPROVED') {
        return ApiResponseUtil.conflict(res, 'KYC already approved');
      }
      if (error.message === 'KYC_ALREADY_SUBMITTED') {
        return ApiResponseUtil.conflict(res, 'KYC already submitted and pending review');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Get KYC status
   * GET /api/kyc/status
   */
  static async getKYCStatus(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      const result = await KYCService.getKYCStatus(userId);

      return ApiResponseUtil.success(res, {
        kyc_status: result.kyc_status,
        documents: result.documents,
        can_resubmit: result.can_resubmit,
      });
    } catch (error: any) {
      logger.error('Get KYC status error', error);

      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Resubmit KYC documents after rejection
   * POST /api/kyc/resubmit
   */
  static async resubmitKYC(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      const {
        document_type,
        document_number,
        front_image_url,
        back_image_url,
        selfie_url,
      } = req.body;

      const result = await KYCService.resubmitKYC(
        userId,
        document_type as DocumentType,
        document_number,
        front_image_url,
        back_image_url,
        selfie_url
      );

      return ApiResponseUtil.success(
        res,
        {
          submitted: result.submitted,
          documents_count: result.documents.length,
        },
        'KYC documents resubmitted successfully'
      );
    } catch (error: any) {
      logger.error('Resubmit KYC error', error);

      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }
      if (error.message === 'KYC_RESUBMIT_NOT_ALLOWED') {
        return ApiResponseUtil.conflict(res, 'KYC resubmission not allowed. Current status must be rejected or pending.');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Admin: Get KYC submissions
   * GET /api/kyc/admin/submissions
   */
  static async adminGetKYCSubmissions(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const adminId = req.user?.id;
      if (!adminId) return ApiResponseUtil.unauthorized(res);

      const {
        status,
        search,
        document_type,
        page = '1',
        limit = '20',
      } = req.query;

      const pageNum = parseInt(page as string, 10);
      const limitNum = parseInt(limit as string, 10);
      const offset = (pageNum - 1) * limitNum;

      const filters: any = {};
      if (status) filters.status = status as KYCStatus;
      if (search) filters.search = search as string;
      if (document_type) filters.document_type = document_type as DocumentType;

      const result = await KYCService.adminGetKYCSubmissions(
        filters,
        { page: pageNum, limit: limitNum, offset }
      );

      return ApiResponseUtil.success(
        res,
        { submissions: result.submissions },
        undefined,
        {
          pagination: {
            page: result.page,
            limit: result.limit,
            total: result.total,
            totalPages: result.totalPages,
          },
        }
      );
    } catch (error: any) {
      logger.error('Admin get KYC submissions error', error);
      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Admin: Get KYC details
   * GET /api/kyc/admin/submissions/:id
   */
  static async adminGetKYCDetails(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const adminId = req.user?.id;
      if (!adminId) return ApiResponseUtil.unauthorized(res);

      const { id } = req.params;

      const result = await KYCService.adminGetKYCDetails(id);

      return ApiResponseUtil.success(res, {
        user: result.user,
        documents: result.documents,
      });
    } catch (error: any) {
      logger.error('Admin get KYC details error', error);

      if (error.message === 'KYC_DOCUMENT_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'KYC submission not found');
      }
      if (error.message === 'USER_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'User not found');
      }

      return ApiResponseUtil.internalError(res);
    }
  }

  /**
   * Admin: Review KYC submission (approve or reject)
   * POST /api/kyc/admin/review/:id
   */
  static async adminReviewKYC(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const adminId = req.user?.id;
      if (!adminId) return ApiResponseUtil.unauthorized(res);

      const { id } = req.params;
      const { status, rejection_reason } = req.body;

      // Validate status
      if (status !== 'APPROVED' && status !== 'REJECTED') {
        return ApiResponseUtil.badRequest(res, 'Status must be APPROVED or REJECTED');
      }

      // Require rejection reason if rejecting
      if (status === 'REJECTED' && !rejection_reason) {
        return ApiResponseUtil.badRequest(res, 'Rejection reason is required when rejecting KYC');
      }

      const result = await KYCService.adminReviewKYC(
        adminId,
        id,
        status,
        rejection_reason
      );

      const message = status === 'APPROVED'
        ? 'KYC submission approved successfully'
        : 'KYC submission rejected';

      return ApiResponseUtil.success(
        res,
        {
          reviewed: result.reviewed,
          user_id: result.user_id,
          status: result.status,
        },
        message
      );
    } catch (error: any) {
      logger.error('Admin review KYC error', error);

      if (error.message === 'ADMIN_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'Admin not found');
      }
      if (error.message === 'UNAUTHORIZED_ADMIN') {
        return ApiResponseUtil.forbidden(res, 'Insufficient permissions to review KYC');
      }
      if (error.message === 'KYC_DOCUMENT_NOT_FOUND') {
        return ApiResponseUtil.notFound(res, 'KYC submission not found');
      }
      if (error.message === 'KYC_ALREADY_APPROVED') {
        return ApiResponseUtil.conflict(res, 'KYC already approved');
      }

      return ApiResponseUtil.internalError(res);
    }
  }
}
