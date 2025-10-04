# Madden Data Service

A TypeScript service that provides real-time Madden NFL franchise data by reverse engineering EA's Blaze servers. This service integrates with the Franchise Player App to provide comprehensive Madden league management.

## 🎯 Overview

This service solves the problem of getting reliable, real-time Madden franchise data by:
- Reverse engineering EA's authentication system (MessageAuth)
- Directly connecting to EA's Blaze servers
- Providing clean APIs for franchise data
- Integrating with Discord bots and web applications

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                 Madden Data Service                         │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   EA Client     │  │  Data Sync      │  │   Webhooks   │ │
│  │ (Reverse Eng.)  │  │   Service       │  │   to App     │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ API Calls
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Franchise Player App                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   Flutter UI    │  │  Discord Bridge │  │   Database   │ │
│  │   (Frontend)    │  │  (Edge Function)│  │ (Supabase)   │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Features

- **Real-time EA Data**: Direct connection to EA's Blaze servers
- **Authentication Management**: Handles EA's complex MessageAuth system
- **Data Transformation**: Converts EA data to standardized format
- **Webhook Integration**: Sends updates to Franchise Player App
- **Error Recovery**: Robust retry logic and error handling
- **Multi-Franchise Support**: Handles multiple leagues simultaneously

## 📋 Prerequisites

- Node.js 18+ 
- TypeScript
- Access to EA account with Madden franchise
- Franchise Player App (for integration)

## 🛠️ Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd madden-data-service
```

2. **Install dependencies**
```bash
npm install
```

3. **Set up environment variables**
```bash
cp env.example .env
```

4. **Configure environment variables**
```env
# EA Authentication
EA_EMAIL=your-ea-email@example.com
EA_PASSWORD=your-ea-password
EA_PERSONA_ID=your-persona-id

# Franchise Player App Integration
FRANCHISE_APP_URL=https://your-project.supabase.co
FRANCHISE_APP_KEY=your-supabase-service-key
WEBHOOK_SECRET=your-webhook-secret

# Database (Optional - for direct DB access)
SUPABASE_URL=your-supabase-url
SUPABASE_SERVICE_KEY=your-supabase-service-key

# Service Configuration
PORT=3000
NODE_ENV=development
LOG_LEVEL=info

# EA Server Configuration
EA_BLAZE_SERVER_URL=https://blaze.ea.com
EA_AUTH_SERVER_URL=https://accounts.ea.com
EA_TIMEOUT=30000

# Rate Limiting
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=100

# Retry Configuration
MAX_RETRY_ATTEMPTS=3
RETRY_DELAY_MS=1000
RETRY_BACKOFF_MULTIPLIER=2

# Webhook Configuration
WEBHOOK_TIMEOUT=10000
WEBHOOK_RETRY_ATTEMPTS=3
```

5. **Build the project**
```bash
npm run build
```

6. **Start the service**
```bash
npm start
```

## 🔧 Development

### Project Structure

```
madden-data-service/
├── src/
│   ├── ea-client/           # EA server integration
│   │   ├── auth-manager.ts  # Authentication handling
│   │   ├── blaze-client.ts  # Blaze server communication
│   │   ├── message-auth.ts  # MessageAuth implementation
│   │   └── types.ts         # EA data types
│   ├── data-sync/           # Data synchronization
│   │   ├── sync-service.ts  # Main sync logic
│   │   ├── data-transformer.ts # EA data transformation
│   │   └── retry-handler.ts # Error handling & retries
│   ├── api/                 # REST API endpoints
│   │   ├── routes/          # API routes
│   │   ├── middleware/      # API middleware
│   │   └── server.ts        # Express server
│   ├── webhooks/            # Webhook handlers
│   │   └── franchise-webhook.ts
│   └── utils/               # Utilities
│       ├── logger.ts        # Logging
│       ├── config.ts        # Configuration
│       └── validation.ts    # Data validation
├── tests/                   # Test files
├── docs/                    # Documentation
├── package.json
├── tsconfig.json
└── README.md
```

### Available Scripts

```bash
# Development
npm run dev          # Start development server with hot reload
npm run build        # Build TypeScript to JavaScript
npm run start        # Start production server

# Testing
npm run test         # Run all tests
npm run test:watch   # Run tests in watch mode
npm run test:coverage # Run tests with coverage

# Code Quality
npm run lint         # Run ESLint
npm run lint:fix     # Fix ESLint issues
npm run format       # Format code with Prettier

# Database
npm run db:migrate   # Run database migrations
npm run db:seed      # Seed database with test data
```

## 📡 API Endpoints

### Authentication
- `POST /api/auth/login` - Login to EA account
- `POST /api/auth/refresh` - Refresh authentication token
- `GET /api/auth/status` - Check authentication status

### Franchise Management
- `GET /api/franchises` - List all franchises
- `GET /api/franchises/:id` - Get specific franchise data
- `POST /api/franchises/:id/sync` - Trigger franchise sync
- `GET /api/franchises/:id/status` - Get sync status

### Data Endpoints
- `GET /api/franchises/:id/teams` - Get franchise teams
- `GET /api/franchises/:id/players` - Get franchise players
- `GET /api/franchises/:id/schedule` - Get game schedule
- `GET /api/franchises/:id/standings` - Get league standings

### Webhooks
- `POST /api/webhooks/franchise-update` - Receive franchise updates
- `POST /api/webhooks/sync-complete` - Handle sync completion

## 🔌 Integration with Franchise Player App

### Webhook Configuration

The service sends data to your Franchise Player App via webhooks:

```typescript
// Example webhook payload
{
  "franchise_id": "uuid",
  "event_type": "franchise_sync",
  "data": {
    "teams": [...],
    "players": [...],
    "schedule": [...],
    "standings": [...]
  },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### Discord Bridge Integration

Your existing Discord Bridge can receive Madden data:

```typescript
// In your discord-bridge Edge Function
if (url.pathname.endsWith("/madden_webhook")) {
  return await handleMaddenWebhook(payload);
}

async function handleMaddenWebhook(payload: any) {
  const { franchise_id, data } = payload;
  
  // Update database
  await supabase.from('madden_teams').upsert(data.teams);
  await supabase.from('madden_players').upsert(data.players);
  
  // Update Discord roles and nicknames
  await updateDiscordIntegration(franchise_id, data);
  
  return Response.json({ success: true });
}
```

## 🧪 Testing

### Unit Tests
```bash
npm run test
```

### Integration Tests
```bash
npm run test:integration
```

### Manual Testing
```bash
# Test EA authentication
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password"}'

# Test franchise sync
curl -X POST http://localhost:3000/api/franchises/123/sync \
  -H "Authorization: Bearer your-token"
```

## 🚀 Deployment

### Vercel (Recommended)
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel --prod
```

### Railway
```bash
# Install Railway CLI
npm i -g @railway/cli

# Deploy
railway up
```

### Docker
```bash
# Build image
docker build -t madden-data-service .

# Run container
docker run -p 3000:3000 --env-file .env madden-data-service
```

## 🔒 Security

- **Environment Variables**: All sensitive data stored in environment variables
- **Webhook Verification**: HMAC signature verification for webhooks
- **Rate Limiting**: Built-in rate limiting for API endpoints
- **Input Validation**: Comprehensive input validation and sanitization
- **Error Handling**: Secure error messages without sensitive data exposure

## 📊 Monitoring

### Health Checks
- `GET /api/health` - Service health status
- `GET /api/health/detailed` - Detailed service metrics

### Logging
- Structured JSON logging
- Configurable log levels
- Request/response logging
- Error tracking

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Troubleshooting

### Common Issues

**Authentication Failures**
- Verify EA credentials are correct
- Check if EA account has 2FA enabled
- Ensure persona ID is correct

**Sync Failures**
- Check network connectivity to EA servers
- Verify franchise ID exists
- Check service logs for detailed error messages

**Webhook Failures**
- Verify webhook URL is accessible
- Check webhook secret configuration
- Ensure Franchise Player App is running

### Debug Mode
```bash
LOG_LEVEL=debug npm run dev
```

## 📚 Documentation

- [API Documentation](docs/api.md)
- [EA Integration Guide](docs/ea-integration.md)
- [Deployment Guide](docs/deployment.md)
- [Troubleshooting Guide](docs/troubleshooting.md)

## 🙏 Acknowledgments

- [Sahith Nallapareddy](https://nallapareddy.com/snallabot-post/) for reverse engineering EA's authentication system
- [SnallaBot](https://github.com/snallapa/snallabot) for inspiration and reference
- EA Sports for making this unnecessarily difficult 😅

## 📞 Support

- Create an issue for bug reports
- Start a discussion for questions
- Join our Discord for real-time support

---

**Note**: This service reverse engineers EA's internal APIs. Use at your own risk and ensure compliance with EA's Terms of Service.
