import pino from 'pino';
import { config } from './config';

const isDevelopment = config.nodeEnv === 'development';

export function createLogger(name?: string) {
  const logger = pino({
    name: name || 'madden-data-service',
    level: config.logLevel,
    transport: isDevelopment ? {
      target: 'pino-pretty',
      options: {
        colorize: true,
        translateTime: 'SYS:standard',
        ignore: 'pid,hostname'
      }
    } : undefined,
    formatters: {
      level: (label) => {
        return { level: label };
      }
    },
    timestamp: pino.stdTimeFunctions.isoTime,
    base: {
      service: 'madden-data-service',
      version: '1.0.0'
    }
  });

  return logger;
}

export const logger = createLogger();

// Export logger instance for use throughout the application
export default logger;
