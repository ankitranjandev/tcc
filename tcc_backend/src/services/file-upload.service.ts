import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { promisify } from 'util';

const mkdir = promisify(fs.mkdir);
const unlink = promisify(fs.unlink);
const stat = promisify(fs.stat);

export enum FileType {
  KYC_DOCUMENT = 'KYC_DOCUMENT',
  BANK_RECEIPT = 'BANK_RECEIPT',
  PROFILE_PICTURE = 'PROFILE_PICTURE',
  SELFIE = 'SELFIE',
}

export interface UploadedFile {
  id: string;
  url: string;
  filename: string;
  originalName: string;
  mimeType: string;
  size: number;
  checksum: string;
  fileType: FileType;
  userId: string;
  uploadedAt: Date;
}

class FileUploadService {
  private uploadBasePath: string;
  private baseUrl: string;

  constructor() {
    // Base upload directory - configurable via environment
    this.uploadBasePath = process.env.UPLOAD_PATH || path.join(process.cwd(), 'uploads');
    this.baseUrl = process.env.BASE_URL || 'http://localhost:3000';

    // Ensure upload directory exists
    this.initializeUploadDirectory();
  }

  /**
   * Initialize upload directory structure
   */
  private async initializeUploadDirectory(): Promise<void> {
    try {
      const directories = [
        this.uploadBasePath,
        path.join(this.uploadBasePath, 'kyc'),
        path.join(this.uploadBasePath, 'bank'),
        path.join(this.uploadBasePath, 'profiles'),
        path.join(this.uploadBasePath, 'temp'),
      ];

      for (const dir of directories) {
        try {
          await stat(dir);
        } catch (error) {
          await mkdir(dir, { recursive: true });
        }
      }
    } catch (error) {
      console.error('Failed to initialize upload directories:', error);
      throw new Error('File upload service initialization failed');
    }
  }

  /**
   * Get upload directory based on file type
   */
  private getUploadDirectory(fileType: FileType, userId: string): string {
    let subDir = '';

    switch (fileType) {
      case FileType.KYC_DOCUMENT:
      case FileType.SELFIE:
        subDir = 'kyc';
        break;
      case FileType.BANK_RECEIPT:
        subDir = 'bank';
        break;
      case FileType.PROFILE_PICTURE:
        subDir = 'profiles';
        break;
      default:
        subDir = 'temp';
    }

    return path.join(this.uploadBasePath, subDir, userId);
  }

  /**
   * Generate unique filename
   */
  private generateFilename(originalName: string): string {
    const timestamp = Date.now();
    const randomString = crypto.randomBytes(8).toString('hex');
    const extension = path.extname(originalName);
    return `${timestamp}-${randomString}${extension}`;
  }

  /**
   * Calculate file checksum
   */
  private calculateChecksum(buffer: Buffer): string {
    return crypto.createHash('sha256').update(buffer).digest('hex');
  }

  /**
   * Validate file type
   */
  public validateFileType(mimeType: string, fileType: FileType): boolean {
    const allowedTypes: Record<FileType, string[]> = {
      [FileType.KYC_DOCUMENT]: [
        'image/jpeg',
        'image/jpg',
        'image/png',
        'application/pdf',
      ],
      [FileType.BANK_RECEIPT]: [
        'image/jpeg',
        'image/jpg',
        'image/png',
        'application/pdf',
      ],
      [FileType.PROFILE_PICTURE]: [
        'image/jpeg',
        'image/jpg',
        'image/png',
      ],
      [FileType.SELFIE]: [
        'image/jpeg',
        'image/jpg',
        'image/png',
      ],
    };

    return allowedTypes[fileType]?.includes(mimeType) || false;
  }

  /**
   * Validate file size
   */
  public validateFileSize(size: number, fileType: FileType): boolean {
    const maxSizes: Record<FileType, number> = {
      [FileType.KYC_DOCUMENT]: 5 * 1024 * 1024, // 5MB
      [FileType.BANK_RECEIPT]: 5 * 1024 * 1024, // 5MB
      [FileType.PROFILE_PICTURE]: 2 * 1024 * 1024, // 2MB
      [FileType.SELFIE]: 2 * 1024 * 1024, // 2MB
    };

    return size <= (maxSizes[fileType] || 5 * 1024 * 1024);
  }

  /**
   * Save uploaded file
   */
  public async saveFile(
    file: Express.Multer.File,
    fileType: FileType,
    userId: string
  ): Promise<UploadedFile> {
    try {
      // Validate file
      if (!this.validateFileType(file.mimetype, fileType)) {
        throw new Error('Invalid file type');
      }

      if (!this.validateFileSize(file.size, fileType)) {
        throw new Error('File size exceeds maximum allowed size');
      }

      // Create user-specific directory
      const uploadDir = this.getUploadDirectory(fileType, userId);
      await mkdir(uploadDir, { recursive: true });

      // Generate unique filename
      const filename = this.generateFilename(file.originalname);
      const filePath = path.join(uploadDir, filename);

      // Write file to disk
      await fs.promises.writeFile(filePath, file.buffer);

      // Calculate checksum
      const checksum = this.calculateChecksum(file.buffer);

      // Generate file ID
      const fileId = crypto.randomUUID();

      // Generate accessible URL
      const relativeDir = fileType === FileType.KYC_DOCUMENT || fileType === FileType.SELFIE
        ? 'kyc'
        : fileType === FileType.BANK_RECEIPT
        ? 'bank'
        : 'profiles';
      const url = `${this.baseUrl}/api/uploads/${relativeDir}/${userId}/${filename}`;

      return {
        id: fileId,
        url,
        filename,
        originalName: file.originalname,
        mimeType: file.mimetype,
        size: file.size,
        checksum,
        fileType,
        userId,
        uploadedAt: new Date(),
      };
    } catch (error) {
      console.error('File save error:', error);
      throw error;
    }
  }

  /**
   * Delete file
   */
  public async deleteFile(fileUrl: string, userId: string): Promise<boolean> {
    try {
      // Extract filename from URL
      const urlParts = fileUrl.split('/');
      const filename = urlParts[urlParts.length - 1];
      const subDir = urlParts[urlParts.length - 3]; // kyc, bank, or profiles

      const filePath = path.join(this.uploadBasePath, subDir, userId, filename);

      // Check if file exists
      try {
        await stat(filePath);
      } catch (error) {
        return false; // File doesn't exist
      }

      // Delete file
      await unlink(filePath);
      return true;
    } catch (error) {
      console.error('File deletion error:', error);
      return false;
    }
  }

  /**
   * Get file path from URL
   */
  public getFilePathFromUrl(fileUrl: string): string {
    const urlParts = fileUrl.replace(this.baseUrl, '').split('/');
    const filename = urlParts[urlParts.length - 1];
    const userId = urlParts[urlParts.length - 2];
    const subDir = urlParts[urlParts.length - 3];

    return path.join(this.uploadBasePath, subDir, userId, filename);
  }

  /**
   * Check if file exists
   */
  public async fileExists(fileUrl: string): Promise<boolean> {
    try {
      const filePath = this.getFilePathFromUrl(fileUrl);
      await stat(filePath);
      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * Get file info
   */
  public async getFileInfo(fileUrl: string): Promise<{ size: number; mimeType: string } | null> {
    try {
      const filePath = this.getFilePathFromUrl(fileUrl);
      const stats = await stat(filePath);

      // Determine mime type from extension
      const ext = path.extname(filePath).toLowerCase();
      const mimeTypes: Record<string, string> = {
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.png': 'image/png',
        '.pdf': 'application/pdf',
      };

      return {
        size: stats.size,
        mimeType: mimeTypes[ext] || 'application/octet-stream',
      };
    } catch (error) {
      return null;
    }
  }
}

export const fileUploadService = new FileUploadService();
