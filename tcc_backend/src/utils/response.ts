import { Response } from 'express';
import { ApiResponse } from '../types';

export class ApiResponseUtil {
  static success<T>(res: Response, data: T | null = null, message?: string, meta?: any): Response {
    const response: ApiResponse<T> = {
      success: true,
      data: data || undefined,
      message,
      meta,
    };
    return res.status(200).json(response);
  }

  static created<T>(res: Response, data: T, message?: string): Response {
    const response: ApiResponse<T> = {
      success: true,
      data,
      message,
    };
    return res.status(201).json(response);
  }

  static error(
    res: Response,
    code: string,
    message: string,
    statusCode: number = 400,
    details?: any
  ): Response {
    const response: ApiResponse = {
      success: false,
      error: {
        code,
        message,
        details,
        timestamp: new Date().toISOString(),
      },
    };
    return res.status(statusCode).json(response);
  }

  static badRequest(res: Response, message: string = 'Bad request'): Response {
    return this.error(res, 'BAD_REQUEST', message, 400);
  }

  static validationError(res: Response, errors: any): Response {
    return this.error(res, 'VALIDATION_ERROR', 'Request validation failed', 422, errors);
  }

  static unauthorized(res: Response, message: string = 'Unauthorized'): Response {
    return this.error(res, 'UNAUTHORIZED', message, 401);
  }

  static forbidden(res: Response, message: string = 'Forbidden'): Response {
    return this.error(res, 'FORBIDDEN', message, 403);
  }

  static notFound(res: Response, message: string = 'Resource not found'): Response {
    return this.error(res, 'NOT_FOUND', message, 404);
  }

  static conflict(res: Response, message: string = 'Resource conflict'): Response {
    return this.error(res, 'CONFLICT', message, 409);
  }

  static tooManyRequests(res: Response, message: string = 'Too many requests'): Response {
    return this.error(res, 'RATE_LIMIT_EXCEEDED', message, 429);
  }

  static internalError(res: Response, message: string = 'Internal server error'): Response {
    return this.error(res, 'INTERNAL_ERROR', message, 500);
  }
}
