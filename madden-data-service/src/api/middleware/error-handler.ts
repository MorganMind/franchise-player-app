import { Request, Response, NextFunction } from 'express';
import { logger } from '../../utils/logger';

export interface AppError extends Error {
  statusCode?: number;
  isOperational?: boolean;
}

export class CustomError extends Error implements AppError {
  public statusCode: number;
  public isOperational: boolean;

  constructor(message: string, statusCode: number = 500, isOperational: boolean = true) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = isOperational;

    Error.captureStackTrace(this, this.constructor);
  }
}

export function errorHandler(
  error: AppError,
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const statusCode = error.statusCode || 500;
  const message = error.message || 'Internal Server Error';

  // Log error
  logger.error('Error occurred', {
    error: {
      message: error.message,
      stack: error.stack,
      statusCode
    },
    request: {
      method: req.method,
      url: req.url,
      ip: req.ip,
      userAgent: req.get('User-Agent')
    },
    timestamp: new Date().toISOString()
  });

  // Don't leak error details in production
  const response = {
    error: {
      message: isProduction ? 'Internal Server Error' : message,
      statusCode,
      timestamp: new Date().toISOString()
    }
  };

  // Add stack trace in development
  if (!isProduction && error.stack) {
    response.error.stack = error.stack;
  }

  res.status(statusCode).json(response);
}

// Async error wrapper
export function asyncHandler(fn: Function) {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

// Common error types
export const BadRequestError = (message: string) => new CustomError(message, 400);
export const UnauthorizedError = (message: string) => new CustomError(message, 401);
export const ForbiddenError = (message: string) => new CustomError(message, 403);
export const NotFoundError = (message: string) => new CustomError(message, 404);
export const ConflictError = (message: string) => new CustomError(message, 409);
export const InternalServerError = (message: string) => new CustomError(message, 500);

const isProduction = process.env.NODE_ENV === 'production';
