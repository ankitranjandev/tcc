import multer from 'multer';
import { Request, Response, NextFunction } from 'express';
import { FileType, fileUploadService } from '../services/file-upload.service';

// Configure multer for memory storage
const storage = multer.memoryStorage();

const upload = multer({
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB max
  },
});

/**
 * Middleware to handle single file upload
 */
export const uploadSingle = (fieldName: string) => {
  return upload.single(fieldName);
};

/**
 * Middleware to handle multiple file uploads
 */
export const uploadMultiple = (fieldName: string, maxCount: number = 10) => {
  return upload.array(fieldName, maxCount);
};

/**
 * Middleware to handle multiple fields with files
 */
export const uploadFields = (fields: { name: string; maxCount: number }[]) => {
  return upload.fields(fields);
};

/**
 * Middleware to validate uploaded file
 */
export const validateUpload = (allowedFileType: FileType) => {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      const file = req.file;

      if (!file) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'FILE_REQUIRED',
            message: 'No file uploaded',
          },
        });
      }

      // Validate file type
      if (!fileUploadService.validateFileType(file.mimetype, allowedFileType, file.originalname)) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'INVALID_FILE_TYPE',
            message: `Invalid file type. Allowed types: ${getAllowedTypesForFileType(allowedFileType)}`,
          },
        });
      }

      // Validate file size
      if (!fileUploadService.validateFileSize(file.size, allowedFileType)) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'FILE_TOO_LARGE',
            message: `File size exceeds maximum allowed size`,
          },
        });
      }

      next();
    } catch (error) {
      console.error('Upload validation error:', error);
      return res.status(500).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Failed to validate uploaded file',
        },
      });
    }
  };
};

/**
 * Middleware to validate multiple uploaded files
 */
export const validateMultipleUploads = (allowedFileType: FileType) => {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      const files = req.files as Express.Multer.File[];

      if (!files || files.length === 0) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'FILES_REQUIRED',
            message: 'No files uploaded',
          },
        });
      }

      // Validate each file
      for (const file of files) {
        if (!fileUploadService.validateFileType(file.mimetype, allowedFileType, file.originalname)) {
          return res.status(400).json({
            success: false,
            error: {
              code: 'INVALID_FILE_TYPE',
              message: `Invalid file type for ${file.originalname}. Allowed types: ${getAllowedTypesForFileType(allowedFileType)}`,
            },
          });
        }

        if (!fileUploadService.validateFileSize(file.size, allowedFileType)) {
          return res.status(400).json({
            success: false,
            error: {
              code: 'FILE_TOO_LARGE',
              message: `File ${file.originalname} exceeds maximum allowed size`,
            },
          });
        }
      }

      next();
    } catch (error) {
      console.error('Multiple upload validation error:', error);
      return res.status(500).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Failed to validate uploaded files',
        },
      });
    }
  };
};

/**
 * Helper function to get allowed file types as string
 */
function getAllowedTypesForFileType(fileType: FileType): string {
  const types: Record<FileType, string> = {
    [FileType.KYC_DOCUMENT]: 'JPEG, PNG, PDF',
    [FileType.BANK_RECEIPT]: 'JPEG, PNG, PDF',
    [FileType.PROFILE_PICTURE]: 'JPEG, PNG',
    [FileType.SELFIE]: 'JPEG, PNG',
  };
  return types[fileType] || 'JPEG, PNG, PDF';
}

/**
 * Error handling middleware for multer errors
 */
export const handleUploadError = (error: any, req: Request, res: Response, next: NextFunction) => {
  if (error instanceof multer.MulterError) {
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        success: false,
        error: {
          code: 'FILE_TOO_LARGE',
          message: 'File size exceeds the maximum limit of 5MB',
        },
      });
    }

    if (error.code === 'LIMIT_FILE_COUNT') {
      return res.status(400).json({
        success: false,
        error: {
          code: 'TOO_MANY_FILES',
          message: 'Too many files uploaded',
        },
      });
    }

    return res.status(400).json({
      success: false,
      error: {
        code: 'UPLOAD_ERROR',
        message: error.message,
      },
    });
  }

  next(error);
};
