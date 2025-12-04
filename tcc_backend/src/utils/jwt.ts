import jwt from 'jsonwebtoken';
import config from '../config';
import { JWTPayload, UserRole } from '../types';

export class JWTUtils {
  static generateAccessToken(userId: string, role: UserRole, email: string): string {
    const payload: JWTPayload = {
      sub: userId,
      role,
      email,
    };

    return jwt.sign(payload, config.jwt.secret, {
      expiresIn: config.jwt.expiresIn as string,
    } as jwt.SignOptions);
  }

  static generateRefreshToken(userId: string, role: UserRole, email: string): string {
    const payload: JWTPayload = {
      sub: userId,
      role,
      email,
    };

    return jwt.sign(payload, config.jwt.refreshSecret, {
      expiresIn: config.jwt.refreshExpiresIn as string,
    } as jwt.SignOptions);
  }

  static verifyAccessToken(token: string): JWTPayload {
    try {
      return jwt.verify(token, config.jwt.secret) as JWTPayload;
    } catch (error) {
      throw new Error('Invalid or expired token');
    }
  }

  static verifyRefreshToken(token: string): JWTPayload {
    try {
      return jwt.verify(token, config.jwt.refreshSecret) as JWTPayload;
    } catch (error) {
      throw new Error('Invalid or expired refresh token');
    }
  }

  static decodeToken(token: string): JWTPayload | null {
    try {
      return jwt.decode(token) as JWTPayload;
    } catch (error) {
      return null;
    }
  }
}
