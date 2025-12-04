import rateLimit from 'express-rate-limit';
import config from '../config';
import { ApiResponse } from '../types';

export const generalRateLimiter = rateLimit({
  windowMs: config.rateLimit.windowMs,
  max: config.rateLimit.maxRequests,
  message: {
    success: false,
    error: {
      code: 'RATE_LIMIT_EXCEEDED',
      message: 'Too many requests from this IP, please try again later',
      timestamp: new Date().toISOString(),
    },
  } as ApiResponse,
  standardHeaders: true,
  legacyHeaders: false,
});

export const authRateLimiter = rateLimit({
  windowMs: config.rateLimit.windowMs,
  max: config.rateLimit.authMaxRequests,
  message: {
    success: false,
    error: {
      code: 'RATE_LIMIT_EXCEEDED',
      message: 'Too many authentication attempts, please try again later',
      timestamp: new Date().toISOString(),
    },
  } as ApiResponse,
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: false,
});

export const strictRateLimiter = rateLimit({
  windowMs: 60000, // 1 minute
  max: 10,
  message: {
    success: false,
    error: {
      code: 'RATE_LIMIT_EXCEEDED',
      message: 'Too many requests, please slow down',
      timestamp: new Date().toISOString(),
    },
  } as ApiResponse,
  standardHeaders: true,
  legacyHeaders: false,
});
