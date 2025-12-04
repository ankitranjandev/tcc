import { Request, Response, NextFunction } from 'express';
import { ApiResponse } from '../types';
import logger from '../utils/logger';
import { ZodError } from 'zod';

export class AppError extends Error {
  constructor(
    public statusCode: number,
    public code: string,
    message: string,
    public details?: any
  ) {
    super(message);
    this.name = 'AppError';
    Error.captureStackTrace(this, this.constructor);
  }
}

export const errorHandler = (
  err: Error,
  req: Request,
  res: Response,
  _next: NextFunction
): Response => {
  logger.error('Error handler caught error', {
    error: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
  });

  // Handle Zod validation errors
  if (err instanceof ZodError) {
    const response: ApiResponse = {
      success: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Request validation failed',
        details: err.errors,
        timestamp: new Date().toISOString(),
      },
    };
    return res.status(422).json(response);
  }

  // Handle custom AppError
  if (err instanceof AppError) {
    const response: ApiResponse = {
      success: false,
      error: {
        code: err.code,
        message: err.message,
        details: err.details,
        timestamp: new Date().toISOString(),
      },
    };
    return res.status(err.statusCode).json(response);
  }

  // Handle database errors
  if (err.name === 'QueryFailedError' || (err as any).code?.startsWith('23')) {
    const response: ApiResponse = {
      success: false,
      error: {
        code: 'DATABASE_ERROR',
        message: 'Database operation failed',
        timestamp: new Date().toISOString(),
      },
    };
    return res.status(500).json(response);
  }

  // Default error response
  const response: ApiResponse = {
    success: false,
    error: {
      code: 'INTERNAL_ERROR',
      message: process.env.NODE_ENV === 'production' ? 'Internal server error' : err.message,
      timestamp: new Date().toISOString(),
    },
  };

  return res.status(500).json(response);
};

export const notFoundHandler = (req: Request, res: Response): Response => {
  const response: ApiResponse = {
    success: false,
    error: {
      code: 'NOT_FOUND',
      message: `Route ${req.method} ${req.path} not found`,
      timestamp: new Date().toISOString(),
    },
  };
  return res.status(404).json(response);
};
