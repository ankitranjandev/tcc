import { Router } from 'express';
import { UploadController } from '../controllers/upload.controller';
import { authenticate } from '../middleware/auth';
import {
  uploadSingle,
  uploadMultiple,
  validateUpload,
  validateMultipleUploads,
  handleUploadError,
} from '../middleware/upload.middleware';
import { FileType } from '../services/file-upload.service';

const router = Router();

/**
 * @route   POST /api/uploads
 * @desc    Upload single file
 * @access  Private
 */
router.post(
  '/',
  authenticate,
  uploadSingle('file'),
  UploadController.uploadFile
);

/**
 * @route   POST /api/uploads/multiple
 * @desc    Upload multiple files
 * @access  Private
 */
router.post(
  '/multiple',
  authenticate,
  uploadMultiple('files', 5),
  UploadController.uploadMultipleFiles
);

/**
 * @route   GET /api/uploads/:subDir/:userId/:filename
 * @desc    Get/download file
 * @access  Private (own files) or Admin
 */
router.get(
  '/:subDir/:userId/:filename',
  authenticate,
  UploadController.getFile
);

/**
 * @route   DELETE /api/uploads
 * @desc    Delete file
 * @access  Private
 */
router.delete(
  '/',
  authenticate,
  UploadController.deleteFile
);

// Error handling middleware for multer errors
router.use(handleUploadError);

export default router;
