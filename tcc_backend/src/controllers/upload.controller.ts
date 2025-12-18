import { Response } from 'express';
import { AuthRequest } from '../types';
import { fileUploadService, FileType } from '../services/file-upload.service';
import { ApiResponseUtil } from '../utils/response';
import logger from '../utils/logger';
import fs from 'fs';
import path from 'path';

export class UploadController {
  /**
   * Upload single file
   * POST /api/uploads
   */
  static async uploadFile(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      const file = req.file;
      if (!file) {
        return ApiResponseUtil.badRequest(res, 'No file provided');
      }

      const { file_type } = req.body;
      if (!file_type || !Object.values(FileType).includes(file_type)) {
        return ApiResponseUtil.badRequest(res, 'Invalid file_type provided');
      }

      // Save file
      const uploadedFile = await fileUploadService.saveFile(
        file,
        file_type as FileType,
        userId
      );

      return ApiResponseUtil.created(
        res,
        {
          id: uploadedFile.id,
          url: uploadedFile.url,
          filename: uploadedFile.filename,
          size: uploadedFile.size,
          checksum: uploadedFile.checksum,
          uploaded_at: uploadedFile.uploadedAt,
        },
        'File uploaded successfully'
      );
    } catch (error: any) {
      logger.error('File upload error', error);

      if (error.message === 'Invalid file type') {
        return ApiResponseUtil.badRequest(res, 'Invalid file type');
      }
      if (error.message === 'File size exceeds maximum allowed size') {
        return ApiResponseUtil.badRequest(res, 'File size exceeds maximum allowed size');
      }

      return ApiResponseUtil.internalError(res, 'Failed to upload file');
    }
  }

  /**
   * Upload multiple files
   * POST /api/uploads/multiple
   */
  static async uploadMultipleFiles(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      const files = req.files as Express.Multer.File[];
      if (!files || files.length === 0) {
        return ApiResponseUtil.badRequest(res, 'No files provided');
      }

      const { file_type } = req.body;
      if (!file_type || !Object.values(FileType).includes(file_type)) {
        return ApiResponseUtil.badRequest(res, 'Invalid file_type provided');
      }

      // Save all files
      const uploadedFiles = [];
      for (const file of files) {
        const uploadedFile = await fileUploadService.saveFile(
          file,
          file_type as FileType,
          userId
        );
        uploadedFiles.push({
          id: uploadedFile.id,
          url: uploadedFile.url,
          filename: uploadedFile.filename,
          size: uploadedFile.size,
          checksum: uploadedFile.checksum,
        });
      }

      return ApiResponseUtil.created(
        res,
        {
          files: uploadedFiles,
          count: uploadedFiles.length,
        },
        'Files uploaded successfully'
      );
    } catch (error: any) {
      logger.error('Multiple files upload error', error);

      if (error.message === 'Invalid file type') {
        return ApiResponseUtil.badRequest(res, 'Invalid file type');
      }
      if (error.message === 'File size exceeds maximum allowed size') {
        return ApiResponseUtil.badRequest(res, 'File size exceeds maximum allowed size');
      }

      return ApiResponseUtil.internalError(res, 'Failed to upload files');
    }
  }

  /**
   * Download/view file
   * GET /api/uploads/:subDir/:userId/:filename
   */
  static async getFile(req: AuthRequest, res: Response): Promise<Response | void> {
    try {
      const requestingUserId = req.user?.id;
      const requestingUserRole = req.user?.role;

      const { subDir, userId, filename } = req.params;

      // Authorization check
      // Users can only access their own files unless they're admin
      if (requestingUserId !== userId && requestingUserRole !== 'ADMIN' && requestingUserRole !== 'SUPER_ADMIN') {
        return ApiResponseUtil.forbidden(res, 'You do not have permission to access this file');
      }

      // Construct file URL
      const baseUrl = process.env.BASE_URL || 'http://localhost:3000';
      const fileUrl = `${baseUrl}/api/uploads/${subDir}/${userId}/${filename}`;

      // Check if file exists
      const exists = await fileUploadService.fileExists(fileUrl);
      if (!exists) {
        return ApiResponseUtil.notFound(res, 'File not found');
      }

      // Get file path
      const filePath = fileUploadService.getFilePathFromUrl(fileUrl);

      // Get file info
      const fileInfo = await fileUploadService.getFileInfo(fileUrl);
      if (!fileInfo) {
        return ApiResponseUtil.notFound(res, 'File not found');
      }

      // Set appropriate headers
      res.setHeader('Content-Type', fileInfo.mimeType);
      res.setHeader('Content-Length', fileInfo.size);

      // Check if it's a download request
      const download = req.query.download === 'true';
      if (download) {
        res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
      } else {
        res.setHeader('Content-Disposition', `inline; filename="${filename}"`);
      }

      // Stream file
      const fileStream = fs.createReadStream(filePath);
      fileStream.pipe(res);
    } catch (error: any) {
      logger.error('File retrieval error', error);
      return ApiResponseUtil.internalError(res, 'Failed to retrieve file');
    }
  }

  /**
   * Delete file
   * DELETE /api/uploads/:fileId
   */
  static async deleteFile(req: AuthRequest, res: Response): Promise<Response> {
    try {
      const userId = req.user?.id;
      if (!userId) return ApiResponseUtil.unauthorized(res);

      const { fileUrl } = req.body;
      if (!fileUrl) {
        return ApiResponseUtil.badRequest(res, 'File URL is required');
      }

      // Delete file
      const deleted = await fileUploadService.deleteFile(fileUrl, userId);

      if (!deleted) {
        return ApiResponseUtil.notFound(res, 'File not found or already deleted');
      }

      return ApiResponseUtil.success(res, null, 'File deleted successfully');
    } catch (error: any) {
      logger.error('File deletion error', error);
      return ApiResponseUtil.internalError(res, 'Failed to delete file');
    }
  }
}
