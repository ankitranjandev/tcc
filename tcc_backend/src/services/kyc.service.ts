// @ts-nocheck
import db from '../database';
import { KYCStatus, DocumentType, UserRole } from '../types';
import logger from '../utils/logger';

interface KYCDocument {
  id: string;
  user_id: string;
  document_type: DocumentType;
  document_url: string;
  document_number?: string;
  status: KYCStatus;
  rejection_reason?: string;
  verified_by?: string;
  verified_at?: Date;
  created_at: Date;
  updated_at: Date;
}

interface KYCSubmission {
  id: string;
  user_id: string;
  first_name: string;
  last_name: string;
  email: string;
  phone: string;
  kyc_status: KYCStatus;
  document_type: DocumentType;
  document_url: string;
  document_number?: string;
  document_count: number;
  rejection_reason?: string;
  verified_by?: string;
  verified_by_name?: string;
  verified_at?: Date;
  submitted_at: Date;
  updated_at: Date;
}

interface PaginationParams {
  page: number;
  limit: number;
  offset: number;
}

export class KYCService {
  /**
   * Submit KYC documents for verification
   */
  static async submitKYC(
    userId: string,
    documentType: DocumentType,
    documentNumber: string,
    frontImageUrl: string,
    backImageUrl?: string,
    selfieUrl?: string
  ): Promise<{ submitted: boolean; documents: KYCDocument[] }> {
    try {
      // Check if user already has approved KYC
      const users = await db.query(
        'SELECT kyc_status FROM users WHERE id = $1',
        [userId]
      );

      if (users.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      if (users[0].kyc_status === KYCStatus.APPROVED) {
        throw new Error('KYC_ALREADY_APPROVED');
      }

      // Check if there's a pending submission
      const existingSubmissions = await db.query<KYCDocument>(
        'SELECT id, status FROM kyc_documents WHERE user_id = $1 AND status IN ($2, $3)',
        [userId, KYCStatus.PENDING, KYCStatus.SUBMITTED]
      );

      if (existingSubmissions.length > 0) {
        throw new Error('KYC_ALREADY_SUBMITTED');
      }

      const documents: KYCDocument[] = [];

      // Insert front image document
      const frontDoc = await db.query<KYCDocument>(
        `INSERT INTO kyc_documents (
          user_id, document_type, document_url, document_number, status
        ) VALUES ($1, $2, $3, $4, $5)
        RETURNING *`,
        [userId, documentType, frontImageUrl, documentNumber, KYCStatus.SUBMITTED]
      );
      documents.push(frontDoc[0]);

      // Insert back image document if provided
      if (backImageUrl) {
        const backDoc = await db.query<KYCDocument>(
          `INSERT INTO kyc_documents (
            user_id, document_type, document_url, document_number, status
          ) VALUES ($1, $2, $3, $4, $5)
          RETURNING *`,
          [userId, documentType, backImageUrl, documentNumber, KYCStatus.SUBMITTED]
        );
        documents.push(backDoc[0]);
      }

      // Insert selfie document if provided
      if (selfieUrl) {
        const selfieDoc = await db.query<KYCDocument>(
          `INSERT INTO kyc_documents (
            user_id, document_type, document_url, status
          ) VALUES ($1, $2, $3, $4)
          RETURNING *`,
          [userId, 'NATIONAL_ID', selfieUrl, KYCStatus.SUBMITTED]
        );
        documents.push(selfieDoc[0]);
      }

      // Update user's KYC status to SUBMITTED
      await db.query(
        'UPDATE users SET kyc_status = $1, updated_at = NOW() WHERE id = $2',
        [KYCStatus.SUBMITTED, userId]
      );

      logger.info('KYC documents submitted', { userId, documentType, documentCount: documents.length });

      return { submitted: true, documents };
    } catch (error) {
      logger.error('Error submitting KYC', error);
      throw error;
    }
  }

  /**
   * Get KYC verification status for a user
   */
  static async getKYCStatus(userId: string): Promise<{
    kyc_status: KYCStatus;
    documents: KYCDocument[];
    can_resubmit: boolean;
  }> {
    try {
      // Get user's KYC status
      const users = await db.query(
        'SELECT kyc_status FROM users WHERE id = $1',
        [userId]
      );

      if (users.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      const kycStatus = users[0].kyc_status;

      // Get all KYC documents
      const documents = await db.query<KYCDocument>(
        `SELECT
          kd.id,
          kd.user_id,
          kd.document_type,
          kd.document_url,
          kd.document_number,
          kd.status,
          kd.rejection_reason,
          kd.verified_by,
          kd.verified_at,
          kd.created_at,
          kd.updated_at
        FROM kyc_documents kd
        WHERE kd.user_id = $1
        ORDER BY kd.created_at DESC`,
        [userId]
      );

      // User can resubmit if status is REJECTED or PENDING
      const canResubmit = kycStatus === KYCStatus.REJECTED || kycStatus === KYCStatus.PENDING;

      return {
        kyc_status: kycStatus,
        documents,
        can_resubmit: canResubmit,
      };
    } catch (error) {
      logger.error('Error getting KYC status', error);
      throw error;
    }
  }

  /**
   * Resubmit KYC documents after rejection
   */
  static async resubmitKYC(
    userId: string,
    documentType: DocumentType,
    documentNumber: string,
    frontImageUrl: string,
    backImageUrl?: string,
    selfieUrl?: string
  ): Promise<{ submitted: boolean; documents: KYCDocument[] }> {
    try {
      // Check if user's KYC was rejected
      const users = await db.query(
        'SELECT kyc_status FROM users WHERE id = $1',
        [userId]
      );

      if (users.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      if (users[0].kyc_status !== KYCStatus.REJECTED && users[0].kyc_status !== KYCStatus.PENDING) {
        throw new Error('KYC_RESUBMIT_NOT_ALLOWED');
      }

      // Archive old documents by updating their status
      await db.query(
        'UPDATE kyc_documents SET status = $1 WHERE user_id = $2 AND status IN ($3, $4)',
        ['ARCHIVED', userId, KYCStatus.REJECTED, KYCStatus.PENDING]
      );

      // Submit new documents
      return await this.submitKYC(
        userId,
        documentType,
        documentNumber,
        frontImageUrl,
        backImageUrl,
        selfieUrl
      );
    } catch (error) {
      logger.error('Error resubmitting KYC', error);
      throw error;
    }
  }

  /**
   * Get KYC submissions for admin review
   */
  static async adminGetKYCSubmissions(
    filters: {
      status?: KYCStatus;
      search?: string;
      user_type?: string;
      document_type?: DocumentType;
    },
    pagination: PaginationParams
  ): Promise<{
    submissions: KYCSubmission[];
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  }> {
    try {
      const conditions: string[] = ['1=1'];
      const params: any[] = [];
      let paramCount = 1;

      // Filter by status
      if (filters.status) {
        conditions.push(`u.kyc_status = $${paramCount++}`);
        params.push(filters.status);
      } else {
        // Default to show only submitted and pending
        conditions.push(`u.kyc_status IN ($${paramCount++}, $${paramCount++})`);
        params.push(KYCStatus.SUBMITTED, KYCStatus.PENDING);
      }

      // Filter by user type
      if (filters.user_type) {
        if (filters.user_type === 'consumer') {
          conditions.push(`u.role = $${paramCount++}`);
          params.push(UserRole.USER);
        } else if (filters.user_type === 'agent') {
          conditions.push(`u.role = $${paramCount++}`);
          params.push(UserRole.AGENT);
        }
      }

      // Search by user name, email, or phone
      if (filters.search) {
        conditions.push(`(
          u.first_name ILIKE $${paramCount} OR
          u.last_name ILIKE $${paramCount} OR
          u.email ILIKE $${paramCount} OR
          u.phone ILIKE $${paramCount}
        )`);
        params.push(`%${filters.search}%`);
        paramCount++;
      }

      // Filter by document type
      if (filters.document_type) {
        conditions.push(`kd.document_type = $${paramCount++}`);
        params.push(filters.document_type);
      }

      // Get total count
      const countQuery = `
        SELECT COUNT(DISTINCT u.id) as count
        FROM users u
        INNER JOIN kyc_documents kd ON u.id = kd.user_id
        WHERE ${conditions.join(' AND ')}
      `;

      const countResult = await db.query(countQuery, params);
      const total = parseInt(countResult[0].count, 10);

      // Get paginated submissions
      const query = `
        SELECT DISTINCT ON (u.id)
          kd.id,
          u.id as user_id,
          u.first_name,
          u.last_name,
          u.email,
          u.phone,
          u.kyc_status,
          kd.document_type,
          kd.document_url,
          kd.document_number,
          kd.rejection_reason,
          kd.verified_by,
          kd.verified_at,
          kd.created_at as submitted_at,
          kd.updated_at,
          admin.first_name || ' ' || admin.last_name as verified_by_name,
          (SELECT COUNT(*) FROM kyc_documents WHERE user_id = u.id) as document_count
        FROM users u
        INNER JOIN kyc_documents kd ON u.id = kd.user_id
        LEFT JOIN users admin ON kd.verified_by = admin.id
        WHERE ${conditions.join(' AND ')}
        ORDER BY u.id, kd.created_at DESC
        LIMIT $${paramCount} OFFSET $${paramCount + 1}
      `;

      params.push(pagination.limit, pagination.offset);

      const submissions = await db.query<KYCSubmission>(query, params);

      const totalPages = Math.ceil(total / pagination.limit);

      return {
        submissions,
        total,
        page: pagination.page,
        limit: pagination.limit,
        totalPages,
      };
    } catch (error) {
      logger.error('Error getting KYC submissions for admin', error);
      throw error;
    }
  }

  /**
   * Admin review KYC submission (approve or reject)
   */
  static async adminReviewKYC(
    adminId: string,
    submissionId: string,
    status: 'APPROVED' | 'REJECTED',
    rejectionReason?: string
  ): Promise<{ reviewed: boolean; user_id: string; status: KYCStatus }> {
    try {
      // Verify admin role
      const adminUsers = await db.query(
        'SELECT role FROM users WHERE id = $1',
        [adminId]
      );

      if (adminUsers.length === 0) {
        throw new Error('ADMIN_NOT_FOUND');
      }

      const adminRole = adminUsers[0].role;
      if (adminRole !== UserRole.ADMIN && adminRole !== UserRole.SUPER_ADMIN) {
        throw new Error('UNAUTHORIZED_ADMIN');
      }

      // Get the KYC document
      const documents = await db.query<KYCDocument>(
        'SELECT user_id, status FROM kyc_documents WHERE id = $1',
        [submissionId]
      );

      if (documents.length === 0) {
        throw new Error('KYC_DOCUMENT_NOT_FOUND');
      }

      const document = documents[0];
      const userId = document.user_id;

      // Check if already reviewed
      if (document.status === KYCStatus.APPROVED) {
        throw new Error('KYC_ALREADY_APPROVED');
      }

      const newStatus = status === 'APPROVED' ? KYCStatus.APPROVED : KYCStatus.REJECTED;

      // Use a transaction to update both documents and user status
      await db.transaction(async (client) => {
        // Update all documents for this user
        if (status === 'APPROVED') {
          await client.query(
            `UPDATE kyc_documents
            SET status = $1, verified_by = $2, verified_at = NOW(), updated_at = NOW()
            WHERE user_id = $3 AND status = $4`,
            [newStatus, adminId, userId, KYCStatus.SUBMITTED]
          );

          // Update user's KYC status
          await client.query(
            'UPDATE users SET kyc_status = $1, updated_at = NOW() WHERE id = $2',
            [newStatus, userId]
          );
        } else {
          // For rejection, update the specific document
          await client.query(
            `UPDATE kyc_documents
            SET status = $1, rejection_reason = $2, verified_by = $3, verified_at = NOW(), updated_at = NOW()
            WHERE id = $4`,
            [newStatus, rejectionReason, adminId, submissionId]
          );

          // Update user's KYC status
          await client.query(
            'UPDATE users SET kyc_status = $1, updated_at = NOW() WHERE id = $2',
            [newStatus, userId]
          );
        }

        // Create notification
        const notificationTitle = status === 'APPROVED'
          ? 'KYC Verified'
          : 'KYC Rejected';
        const notificationMessage = status === 'APPROVED'
          ? 'Your KYC verification has been approved. You can now access all features.'
          : `Your KYC verification was rejected. Reason: ${rejectionReason || 'Please contact support for details.'}`;

        await client.query(
          `INSERT INTO notifications (user_id, type, title, message, data)
          VALUES ($1, $2, $3, $4, $5)`,
          [
            userId,
            'KYC',
            notificationTitle,
            notificationMessage,
            JSON.stringify({ status: newStatus, reviewed_by: adminId }),
          ]
        );

        // Log admin action
        await client.query(
          `INSERT INTO admin_audit_logs (
            admin_id, action, entity_type, entity_id, changes
          ) VALUES ($1, $2, $3, $4, $5)`,
          [
            adminId,
            status === 'APPROVED' ? 'APPROVE_KYC' : 'REJECT_KYC',
            'KYC_DOCUMENT',
            submissionId,
            JSON.stringify({
              user_id: userId,
              status: newStatus,
              rejection_reason: rejectionReason,
            }),
          ]
        );
      });

      logger.info('KYC reviewed by admin', {
        adminId,
        submissionId,
        userId,
        status: newStatus
      });

      return {
        reviewed: true,
        user_id: userId,
        status: newStatus,
      };
    } catch (error) {
      logger.error('Error reviewing KYC', error);
      throw error;
    }
  }

  /**
   * Get user details by KYC submission ID (for admin)
   */
  static async adminGetKYCDetails(submissionId: string): Promise<{
    user: any;
    documents: KYCDocument[];
  }> {
    try {
      // Get the KYC document
      const documents = await db.query<KYCDocument>(
        'SELECT user_id FROM kyc_documents WHERE id = $1',
        [submissionId]
      );

      if (documents.length === 0) {
        throw new Error('KYC_DOCUMENT_NOT_FOUND');
      }

      const userId = documents[0].user_id;

      // Get user details
      const users = await db.query(
        `SELECT
          id, first_name, last_name, email, phone, country_code,
          kyc_status, profile_picture_url, created_at
        FROM users WHERE id = $1`,
        [userId]
      );

      if (users.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      // Get all KYC documents for this user
      const allDocuments = await db.query<KYCDocument>(
        `SELECT
          kd.*,
          u.first_name || ' ' || u.last_name as verified_by_name
        FROM kyc_documents kd
        LEFT JOIN users u ON kd.verified_by = u.id
        WHERE kd.user_id = $1
        ORDER BY kd.created_at DESC`,
        [userId]
      );

      return {
        user: users[0],
        documents: allDocuments,
      };
    } catch (error) {
      logger.error('Error getting KYC details', error);
      throw error;
    }
  }
}
