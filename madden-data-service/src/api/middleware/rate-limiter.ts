import { RateLimiterMemory } from 'rate-limiter-flexible';
import { Request, Response, NextFunction } from 'express';
import { config } from '../../utils/config';
import { logger } from '../../utils/logger';

// Create rate limiter instance
const rateLimiter = new RateLimiterMemory({
  keyPrefix: 'madden_service',
  points: config.rateLimitMaxRequests, // Number of requests
  duration: config.rateLimitWindowMs / 1000, // Per duration in seconds
});

// Rate limiter middleware
export function rateLimiterMiddleware(req: Request, res: Response, next: NextFunction): void {
  const key = req.ip || 'unknown';
  
  rateLimiter.consume(key)
    .then(() => {
      next();
    })
    .catch((rejRes) => {
      const secs = Math.round(rejRes.msBeforeNext / 1000) || 1;
      
      logger.warn('Rate limit exceeded', {
        ip: req.ip,
        method: req.method,
        url: req.url,
        retryAfter: secs,
        timestamp: new Date().toISOString()
      });

      res.set('Retry-After', String(secs));
      res.status(429).json({
        error: 'Too Many Requests',
        message: 'Rate limit exceeded. Please try again later.',
        retryAfter: secs,
        timestamp: new Date().toISOString()
      });
    });
}

// Export the rate limiter instance for use in other parts of the application
export { rateLimiter };
