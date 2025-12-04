import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { authenticate } from '../middleware/auth';
import { validate } from '../middleware/validation';
import { authRateLimiter } from '../middleware/rateLimit';
import { z } from 'zod';

const router = Router();

// Validation schemas
const registerSchema = z.object({
  body: z.object({
    first_name: z.string().min(2).max(100),
    last_name: z.string().min(2).max(100),
    email: z.string().email(),
    phone: z.string().length(10),
    country_code: z.string().regex(/^\+\d{1,4}$/),
    password: z
      .string()
      .min(8)
      .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/),
    role: z.enum(['USER', 'AGENT']).optional(),
    referral_code: z.string().length(8).optional(),
  }),
});

const verifyOTPSchema = z.object({
  body: z.object({
    phone: z.string().length(10),
    country_code: z.string().regex(/^\+\d{1,4}$/),
    otp: z.string().length(6),
    purpose: z.enum(['REGISTRATION', 'LOGIN', 'PHONE_CHANGE', 'PASSWORD_RESET']),
  }),
});

const loginSchema = z.object({
  body: z.object({
    email: z.string().email(),
    password: z.string().min(1),
  }),
});

const resendOTPSchema = z.object({
  body: z.object({
    phone: z.string().length(10),
    country_code: z.string().regex(/^\+\d{1,4}$/),
  }),
});

const forgotPasswordSchema = z.object({
  body: z.object({
    email: z.string().email(),
  }),
});

const resetPasswordSchema = z.object({
  body: z.object({
    phone: z.string().length(10),
    country_code: z.string().regex(/^\+\d{1,4}$/),
    otp: z.string().length(6),
    new_password: z
      .string()
      .min(8)
      .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/),
  }),
});

const refreshTokenSchema = z.object({
  body: z.object({
    refresh_token: z.string().min(1),
  }),
});

const logoutSchema = z.object({
  body: z.object({
    refresh_token: z.string().min(1),
  }),
});

// Routes
router.post(
  '/register',
  authRateLimiter,
  validate(registerSchema),
  AuthController.register
);

router.post(
  '/verify-otp',
  authRateLimiter,
  validate(verifyOTPSchema),
  AuthController.verifyOTP
);

router.post(
  '/login',
  authRateLimiter,
  validate(loginSchema),
  AuthController.login
);

router.post(
  '/resend-otp',
  authRateLimiter,
  validate(resendOTPSchema),
  AuthController.resendOTP
);

router.post(
  '/forgot-password',
  authRateLimiter,
  validate(forgotPasswordSchema),
  AuthController.forgotPassword
);

router.post(
  '/reset-password',
  authRateLimiter,
  validate(resetPasswordSchema),
  AuthController.resetPassword
);

router.post(
  '/refresh',
  validate(refreshTokenSchema),
  AuthController.refreshToken
);

router.post(
  '/logout',
  authenticate,
  validate(logoutSchema),
  AuthController.logout
);

export default router;
