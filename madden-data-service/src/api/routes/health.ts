import { Router, Request, Response } from 'express';
import { logger } from '../../utils/logger';

const router = Router();

// Health check endpoint
router.get('/', async (req: Request, res: Response) => {
  try {
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      version: '1.0.0',
      environment: process.env.NODE_ENV || 'development'
    };

    logger.debug('Health check requested', { health });
    res.json(health);
  } catch (error) {
    logger.error('Health check failed', { error });
    res.status(500).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: 'Health check failed'
    });
  }
});

// Detailed health check
router.get('/detailed', async (req: Request, res: Response) => {
  try {
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      cpu: process.cpuUsage(),
      version: '1.0.0',
      environment: process.env.NODE_ENV || 'development',
      dependencies: {
        // Add dependency health checks here
        eaConnection: 'unknown', // TODO: Implement EA connection check
        database: 'unknown', // TODO: Implement database health check
        webhooks: 'unknown' // TODO: Implement webhook health check
      }
    };

    logger.debug('Detailed health check requested', { health });
    res.json(health);
  } catch (error) {
    logger.error('Detailed health check failed', { error });
    res.status(500).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: 'Detailed health check failed'
    });
  }
});

export { router as healthRoutes };
