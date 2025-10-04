import dotenv from 'dotenv';

dotenv.config();

export const config = {
  // Service Configuration
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  logLevel: process.env.LOG_LEVEL || 'info',

  // EA Authentication
  eaEmail: process.env.EA_EMAIL || '',
  eaPassword: process.env.EA_PASSWORD || '',
  eaPersonaId: process.env.EA_PERSONA_ID || '',

  // EA Server Configuration
  eaBlazeServerUrl: process.env.EA_BLAZE_SERVER_URL || 'https://blaze.ea.com',
  eaAuthServerUrl: process.env.EA_AUTH_SERVER_URL || 'https://accounts.ea.com',
  eaTimeout: parseInt(process.env.EA_TIMEOUT || '30000', 10),

  // Franchise Player App Integration
  franchiseAppUrl: process.env.FRANCHISE_APP_URL || '',
  franchiseAppKey: process.env.FRANCHISE_APP_KEY || '',
  webhookSecret: process.env.WEBHOOK_SECRET || '',

  // Database Configuration
  supabaseUrl: process.env.SUPABASE_URL || '',
  supabaseServiceKey: process.env.SUPABASE_SERVICE_KEY || '',

  // Rate Limiting
  rateLimitWindowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000', 10),
  rateLimitMaxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100', 10),

  // Retry Configuration
  maxRetryAttempts: parseInt(process.env.MAX_RETRY_ATTEMPTS || '3', 10),
  retryDelayMs: parseInt(process.env.RETRY_DELAY_MS || '1000', 10),
  retryBackoffMultiplier: parseFloat(process.env.RETRY_BACKOFF_MULTIPLIER || '2'),

  // Webhook Configuration
  webhookTimeout: parseInt(process.env.WEBHOOK_TIMEOUT || '10000', 10),
  webhookRetryAttempts: parseInt(process.env.WEBHOOK_RETRY_ATTEMPTS || '3', 10),
} as const;

// Validation
export function validateConfig(): void {
  const required = [
    'eaEmail',
    'eaPassword',
    'eaPersonaId',
    'franchiseAppUrl',
    'franchiseAppKey',
    'webhookSecret'
  ];

  const missing = required.filter(key => !config[key as keyof typeof config]);

  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  }
}

// Development mode check
export const isDevelopment = config.nodeEnv === 'development';
export const isProduction = config.nodeEnv === 'production';
export const isTest = config.nodeEnv === 'test';
