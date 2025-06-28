# 🗄️ Supabase Database Setup Guide

This guide will walk you through setting up your Supabase database for the Franchise Player app.

## 🎯 Quick Setup (3 Methods)

### Method 1: Automated Setup (Easiest)
```bash
cd backend
npm run setup-db
```

### Method 2: SQL Editor (Manual)
1. Go to your Supabase dashboard
2. Click "SQL Editor" in the left sidebar
3. Copy and paste the SQL from `backend/setup-database.sql`
4. Click "Run"

### Method 3: Step-by-Step (Detailed)

## 📋 Step-by-Step Manual Setup

### Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Sign up or log in
3. Click "New Project"
4. Fill in:
   - **Name**: `franchise-player`
   - **Database Password**: Choose a strong password
   - **Region**: Choose closest to you
5. Click "Create new project"
6. Wait 2-3 minutes for setup

### Step 2: Get Your Credentials

1. In your Supabase dashboard, go to **Settings** → **API**
2. Copy these values:
   - **Project URL**: `https://your-project.supabase.co`
   - **anon public key**: Starts with `eyJ...`
   - **service_role key**: Starts with `eyJ...`

### Step 3: Create the Database Table

1. In your Supabase dashboard, click **SQL Editor**
2. Click **New query**
3. Copy and paste this SQL:

```sql
-- Create the json_uploads table
CREATE TABLE IF NOT EXISTS json_uploads (
  id BIGSERIAL PRIMARY KEY,
  payload JSONB NOT NULL,
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_json_uploads_user_id ON json_uploads(user_id);
CREATE INDEX IF NOT EXISTS idx_json_uploads_uploaded_at ON json_uploads(uploaded_at);
CREATE INDEX IF NOT EXISTS idx_json_uploads_created_at ON json_uploads(created_at);

-- Enable Row Level Security
ALTER TABLE json_uploads ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own uploads" ON json_uploads
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own uploads" ON json_uploads
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own uploads" ON json_uploads
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own uploads" ON json_uploads
  FOR DELETE USING (auth.uid() = user_id);

-- Insert a test record
INSERT INTO json_uploads (payload, uploaded_at) 
VALUES (
  '{"test": "data", "message": "Database setup successful", "timestamp": "' || NOW() || '"}',
  NOW()
);
```

4. Click **Run**

### Step 4: Verify Setup

1. Go to **Table Editor** in your Supabase dashboard
2. You should see the `json_uploads` table
3. Click on it to see the test record

### Step 5: Configure Your App

1. **Backend Configuration**:
   ```bash
   cd backend
   cp env.example .env
   ```
   
   Edit `.env`:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_SERVICE_KEY=your-service-role-key
   PORT=3000
   ```

2. **Frontend Configuration**:
   - Open `frontend/lib/supabase_client.dart`
   - Replace `<your-supabase-url>` with your Project URL
   - Replace `<your-anon-public-key>` with your anon public key

## 🧪 Test Your Setup

### Test Backend Connection
```bash
cd backend
npm run setup-db
```

You should see:
```
🚀 Setting up Franchise Player database...
✅ json_uploads table created successfully
✅ Indexes created successfully
✅ Row Level Security configured successfully
✅ Test record inserted successfully
🎉 Database setup completed successfully!
```

### Test API Endpoints
```bash
# Health check
curl http://localhost:3000/health

# Start the server
npm run dev
```

## 🔍 What Gets Created

### Table Structure
- **id**: Auto-incrementing primary key
- **payload**: JSONB field for storing franchise data
- **uploaded_at**: Timestamp when data was uploaded
- **user_id**: Links to authenticated user
- **created_at**: Record creation timestamp

### Security Features
- **Row Level Security (RLS)**: Users can only access their own data
- **Authentication Required**: All data operations require valid JWT tokens
- **Cascade Deletes**: When a user is deleted, their data is removed

### Performance Optimizations
- **Indexes**: Fast queries on user_id and timestamps
- **JSONB**: Efficient JSON storage and querying
- **Optimized Queries**: User-specific data filtering

## 🚨 Troubleshooting

### "Table already exists" errors
- This is normal if you run the setup multiple times
- The `IF NOT EXISTS` clause prevents errors

### "Permission denied" errors
- Make sure you're using the **service_role** key (not anon key)
- Check that your Supabase project is active

### "Connection failed" errors
- Verify your SUPABASE_URL is correct
- Check that your service key is valid
- Ensure your Supabase project is not paused

## 🎉 Success!

Once you see the success messages, your database is ready! You can now:

1. **Run the backend**: `npm run dev`
2. **Run the frontend**: `flutter run`
3. **Upload franchise data**: Use the API endpoints
4. **View data**: Check the Supabase dashboard

---

**Need help?** Check the main `SETUP.md` file or open an issue in the repository. 