import express from 'express';
import helmet from 'helmet';
import dotenv from 'dotenv';
import { createLogger } from './utils/logger';
import { errorHandler } from './api/middleware/error-handler';
import { rateLimiter } from './api/middleware/rate-limiter';
import { authRoutes } from './api/routes/auth';
import { franchiseRoutes } from './api/routes/franchise';
import { webhookRoutes } from './api/routes/webhooks';
import { healthRoutes } from './api/routes/health';
import { config } from './utils/config';

// Load environment variables
dotenv.config();

const app = express();
const logger = createLogger();
const PORT = config.port;

// Security middleware
app.use(helmet());

// Rate limiting
app.use(rateLimiter);

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Request logging
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    timestamp: new Date().toISOString()
  });
  next();
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/franchises', franchiseRoutes);
app.use('/api/webhooks', webhookRoutes);
app.use('/api/health', healthRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    service: 'Madden Data Service',
    version: '1.0.0',
    status: 'running',
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.method} ${req.originalUrl} not found`,
    timestamp: new Date().toISOString()
  });
});

// Error handling
app.use(errorHandler);

// Start server
app.listen(PORT, () => {
  logger.info(`Madden Data Service started on port ${PORT}`, {
    port: PORT,
    environment: config.nodeEnv,
    timestamp: new Date().toISOString()
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  process.exit(0);
});

export default app;
