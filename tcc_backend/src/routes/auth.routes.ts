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
    email: z.string().min(1).optional(), // Can be email or phone number
    email_or_phone: z.string().min(1).optional(),
    password: z.string().min(1),
  }),
}).refine((data) => data.body.email || data.body.email_or_phone, {
  message: 'Either email or email_or_phone is required',
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

/**
 * @swagger
 * /auth/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Authentication]
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - first_name
 *               - last_name
 *               - email
 *               - phone
 *               - country_code
 *               - password
 *             properties:
 *               first_name:
 *                 type: string
 *                 minLength: 2
 *                 maxLength: 100
 *                 example: John
 *               last_name:
 *                 type: string
 *                 minLength: 2
 *                 maxLength: 100
 *                 example: Doe
 *               email:
 *                 type: string
 *                 format: email
 *                 example: john.doe@example.com
 *               phone:
 *                 type: string
 *                 length: 10
 *                 example: "1234567890"
 *               country_code:
 *                 type: string
 *                 pattern: '^\+\d{1,4}$'
 *                 example: "+234"
 *               password:
 *                 type: string
 *                 minLength: 8
 *                 description: Must contain at least one uppercase, one lowercase, one digit, and one special character
 *                 example: "Password123!"
 *               role:
 *                 type: string
 *                 enum: [USER, AGENT]
 *                 example: USER
 *               referral_code:
 *                 type: string
 *                 length: 8
 *                 example: "ABC12345"
 *     responses:
 *       200:
 *         description: User registered successfully, OTP sent
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/SuccessResponse'
 *       400:
 *         description: Invalid input or user already exists
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       429:
 *         description: Too many requests
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.post(
  '/register',
  authRateLimiter,
  validate(registerSchema),
  AuthController.register
);

/**
 * @swagger
 * /auth/verify-otp:
 *   post:
 *     summary: Verify OTP for registration or login
 *     tags: [Authentication]
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - phone
 *               - country_code
 *               - otp
 *               - purpose
 *             properties:
 *               phone:
 *                 type: string
 *                 length: 10
 *                 example: "1234567890"
 *               country_code:
 *                 type: string
 *                 pattern: '^\+\d{1,4}$'
 *                 example: "+234"
 *               otp:
 *                 type: string
 *                 length: 6
 *                 example: "123456"
 *               purpose:
 *                 type: string
 *                 enum: [REGISTRATION, LOGIN, PHONE_CHANGE, PASSWORD_RESET]
 *                 example: REGISTRATION
 *     responses:
 *       200:
 *         description: OTP verified successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: object
 *                   properties:
 *                     access_token:
 *                       type: string
 *                     refresh_token:
 *                       type: string
 *                     user:
 *                       type: object
 *       400:
 *         description: Invalid OTP or expired
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.post(
  '/verify-otp',
  authRateLimiter,
  validate(verifyOTPSchema),
  AuthController.verifyOTP
);

/**
 * @swagger
 * /auth/login:
 *   post:
 *     summary: Login user with email/phone and password
 *     tags: [Authentication]
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 example: john.doe@example.com
 *               email_or_phone:
 *                 type: string
 *                 example: "john.doe@example.com or 1234567890"
 *               password:
 *                 type: string
 *                 example: "Password123!"
 *     responses:
 *       200:
 *         description: Login successful, OTP sent
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/SuccessResponse'
 *       401:
 *         description: Invalid credentials
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.post(
  '/login',
  authRateLimiter,
  validate(loginSchema),
  AuthController.login
);

// DEV ONLY: Direct login without OTP
router.post(
  '/login-direct',
  authRateLimiter,
  validate(loginSchema),
  AuthController.loginDirect
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

/**
 * @swagger
 * /auth/refresh:
 *   post:
 *     summary: Refresh access token using refresh token
 *     tags: [Authentication]
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - refresh_token
 *             properties:
 *               refresh_token:
 *                 type: string
 *                 example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
 *     responses:
 *       200:
 *         description: Token refreshed successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: object
 *                   properties:
 *                     access_token:
 *                       type: string
 *                     refresh_token:
 *                       type: string
 *       401:
 *         description: Invalid or expired refresh token
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.post(
  '/refresh',
  validate(refreshTokenSchema),
  AuthController.refreshToken
);

/**
 * @swagger
 * /auth/logout:
 *   post:
 *     summary: Logout user and invalidate tokens
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - refresh_token
 *             properties:
 *               refresh_token:
 *                 type: string
 *                 example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
 *     responses:
 *       200:
 *         description: Logged out successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/SuccessResponse'
 *       401:
 *         description: Unauthorized
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.post(
  '/logout',
  authenticate,
  validate(logoutSchema),
  AuthController.logout
);

export default router;
