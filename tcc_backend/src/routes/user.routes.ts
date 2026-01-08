import { Router } from 'express';
import { UserController } from '../controllers/user.controller';
import { authenticate } from '../middleware/auth';
import { validate } from '../middleware/validation';
import { uploadSingle, validateUpload } from '../middleware/upload.middleware';
import { FileType } from '../services/file-upload.service';
import { z } from 'zod';

const router = Router();

// All routes require authentication
router.use(authenticate);

// Validation schemas
const updateProfileSchema = z.object({
  body: z.object({
    first_name: z.string().min(2).max(100).optional(),
    last_name: z.string().min(2).max(100).optional(),
    email: z.string().email().optional(),
    profile_picture: z.string().optional(),
  }),
});

const changePhoneSchema = z.object({
  body: z.object({
    new_phone: z.string().length(10),
    country_code: z.string().regex(/^\+\d{1,4}$/),
    password: z.string().min(1),
  }),
});

const changePasswordSchema = z.object({
  body: z.object({
    current_password: z.string().min(1),
    new_password: z
      .string()
      .min(8)
      .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/),
    confirm_password: z.string().min(1),
  }).refine((data) => data.new_password === data.confirm_password, {
    message: "Passwords don't match",
    path: ['confirm_password'],
  }),
});

const addBankAccountSchema = z.object({
  body: z.object({
    bank_name: z.string().min(1).max(255),
    account_number: z.string().min(5).max(50),
    account_holder_name: z.string().min(1).max(255),
    branch_address: z.string().max(500).optional(),
    is_primary: z.boolean().optional(),
  }),
});

const verifyPhoneSchema = z.object({
  body: z.object({
    phone: z.string().min(10).max(15),
    country_code: z.string().regex(/^\+\d{1,4}$/),
  }),
});

const fcmTokenSchema = z.object({
  body: z.object({
    fcm_token: z.string().min(1),
  }),
});

// Routes
router.get('/profile', UserController.getProfile);
router.patch('/profile', validate(updateProfileSchema), UserController.updateProfile);
router.post(
  '/profile-picture',
  uploadSingle('profile_picture'),
  validateUpload(FileType.PROFILE_PICTURE),
  UserController.uploadProfilePicture
);
router.post('/change-phone', validate(changePhoneSchema), UserController.changePhone);
router.post('/change-password', validate(changePasswordSchema), UserController.changePassword);
router.post('/delete-account', UserController.deleteAccount);
router.post('/cancel-deletion', UserController.cancelDeletion);
router.post('/bank-accounts', validate(addBankAccountSchema), UserController.addBankAccount);
router.get('/bank-accounts', UserController.getBankAccounts);
router.post('/verify-phone', validate(verifyPhoneSchema), UserController.verifyPhone);

// FCM token management
router.post('/fcm-token', validate(fcmTokenSchema), UserController.registerFCMToken);
router.delete('/fcm-token', UserController.removeFCMToken);

export default router;
