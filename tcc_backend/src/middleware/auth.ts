import { Response, NextFunction } from 'express';
import { AuthRequest, UserRole } from '../types';
import { JWTUtils } from '../utils/jwt';
import { ApiResponseUtil } from '../utils/response';
import logger from '../utils/logger';

export const authenticate = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void | Response> => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return ApiResponseUtil.unauthorized(res, 'No token provided');
    }

    const token = authHeader.substring(7);

    try {
      const payload = JWTUtils.verifyAccessToken(token);

      req.user = {
        id: payload.sub,
        role: payload.role,
        email: payload.email,
      };

      next();
    } catch (error) {
      logger.warn('Invalid token attempt', { error });
      return ApiResponseUtil.unauthorized(res, 'Invalid or expired token');
    }
  } catch (error) {
    logger.error('Authentication middleware error', error);
    return ApiResponseUtil.internalError(res);
  }
};

export const authorize = (...roles: UserRole[]) => {
  return (req: AuthRequest, res: Response, next: NextFunction): void | Response => {
    if (!req.user) {
      return ApiResponseUtil.unauthorized(res);
    }

    // Check if user's role is in the allowed roles
    const userRole = req.user.role as string;
    const allowedRoles = roles.map(r => r.toString());

    if (!allowedRoles.includes(userRole)) {
      logger.warn('Unauthorized access attempt', {
        userId: req.user.id,
        userRole: userRole,
        allowedRoles: allowedRoles,
        rawUser: req.user,
      });
      return ApiResponseUtil.forbidden(res, 'You do not have permission to access this resource');
    }

    next();
  };
};

export const optionalAuth = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;

    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);

      try {
        const payload = JWTUtils.verifyAccessToken(token);
        req.user = {
          id: payload.sub,
          role: payload.role,
          email: payload.email,
        };
      } catch (error) {
        // Token is invalid but we don't fail the request
        logger.debug('Optional auth: Invalid token', { error });
      }
    }

    next();
  } catch (error) {
    logger.error('Optional authentication middleware error', error);
    next();
  }
};
