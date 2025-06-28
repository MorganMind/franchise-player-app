# Franchise Player - Backend API

This is the Node.js backend API for the Franchise Player app that receives JSON data from the Madden Companion App and stores it in Supabase.

## Features

- JSON data ingestion endpoint with user authentication
- Supabase integration for data storage
- Row Level Security (RLS) for data protection
- CORS enabled for frontend integration
- Health check endpoint
- Error handling and validation
- User-specific data access

## Setup Instructions

### Prerequisites
1. Node.js (v14 or higher)
2. A Supabase project

### Installation

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Set up environment variables:
   ```bash
   cp env.example .env
   ```
   
   Then edit `.env` and add your Supabase credentials:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_SERVICE_KEY=your-service-key
   PORT=3000
   ```

4. **Set up the database** (choose one method):

   **Method A: Automated Setup (Recommended)**
   ```bash
   npm run setup-db
   ```

   **Method B: Manual SQL Setup**
   - Go to your Supabase project dashboard
   - Navigate to the SQL Editor
   - Copy and paste the contents of `setup-database.sql`
   - Run the script

5. Start the development server:
   ```bash
   npm run dev
   ```

## Database Setup

The setup script will create:
- `json_uploads` table with proper structure
- Performance indexes
- Row Level Security (RLS) policies
- User authentication integration

### Table Structure
```sql
CREATE TABLE json_uploads (
  id BIGSERIAL PRIMARY KEY,
  payload JSONB NOT NULL,
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## API Endpoints

### Health Check
- **GET** `/health`
- Returns server status (no authentication required)

### Upload JSON Data
- **POST** `/upload`
- **Authentication**: Required (Bearer token)
- Accepts JSON data in request body
- Stores data in Supabase `json_uploads` table
- Associates data with authenticated user

### Get User's Uploads
- **GET** `/uploads`
- **Authentication**: Required (Bearer token)
- Returns all uploads for the authenticated user

### Get Specific Upload
- **GET** `/uploads/:id`
- **Authentication**: Required (Bearer token)
- Returns a specific upload by ID (user's own uploads only)

### Delete Upload
- **DELETE** `/uploads/:id`
- **Authentication**: Required (Bearer token)
- Deletes a specific upload by ID (user's own uploads only)

## Authentication

All data endpoints require authentication using Supabase JWT tokens:

```bash
curl -X POST http://localhost:3000/upload \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN" \
  -d '{"test": "data"}'
```

## Testing the API

### Health Check
```bash
curl http://localhost:3000/health
```

### Upload JSON (with authentication)
```bash
# First, get a JWT token from your Flutter app or Supabase
curl -X POST http://localhost:3000/upload \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"franchise": "example", "players": []}'
```

### Get Uploads (with authentication)
```bash
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:3000/uploads
```

## Deployment to Render

1. Push your code to GitHub
2. Create a new Web Service on Render
3. Connect your GitHub repository
4. Configure the service:
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Environment Variables**: Add your `.env` variables in Render's dashboard

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `SUPABASE_URL` | Your Supabase project URL | Yes |
| `SUPABASE_SERVICE_KEY` | Your Supabase service key | Yes |
| `PORT` | Server port (default: 3000) | No |
| `NODE_ENV` | Environment (development/production) | No |

## Project Structure

- `index.js` - Main server file with authentication
- `setup-database.js` - Automated database setup script
- `setup-database.sql` - Manual SQL setup script
- `package.json` - Dependencies and scripts
- `env.example` - Environment variables template
- `README.md` - This file

## Security Features

- **Row Level Security (RLS)**: Users can only access their own data
- **JWT Authentication**: Secure token-based authentication
- **Input Validation**: JSON validation and sanitization
- **CORS Protection**: Configured for frontend integration

## Next Steps

- Add rate limiting
- Implement data validation schemas
- Add file upload support
- Create data processing pipelines
- Add analytics and monitoring 