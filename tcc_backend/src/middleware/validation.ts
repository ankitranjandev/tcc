import { Request, Response, NextFunction } from 'express';
import { ZodSchema, ZodError } from 'zod';
import { ApiResponseUtil } from '../utils/response';

export const validate = (schema: ZodSchema) => {
  return async (req: Request, res: Response, next: NextFunction): Promise<void | Response> => {
    try {
      await schema.parseAsync({
        body: req.body,
        query: req.query,
        params: req.params,
      });
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        const formattedErrors = error.errors.map((err) => ({
          path: err.path.join('.'),
          message: err.message,
        }));
        return ApiResponseUtil.validationError(res, formattedErrors);
      }
      next(error);
    }
  };
};

// Alias for backward compatibility
export const validateRequest = validate;
