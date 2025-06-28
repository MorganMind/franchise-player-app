# 🚀 Franchise Player - Complete Setup Guide

This guide will walk you through setting up the entire Franchise Player application from scratch.

## 📋 Prerequisites

1. **Node.js** (v14 or higher) - [Download here](https://nodejs.org/)
2. **Flutter SDK** - [Install here](https://flutter.dev/docs/get-started/install)
3. **Supabase Account** - [Sign up here](https://supabase.com/)

## 🎯 Step-by-Step Setup

### Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign up/login
2. Click "New Project"
3. Choose your organization
4. Enter project details:
   - **Name**: `franchise-player`
   - **Database Password**: Choose a strong password
   - **Region**: Choose closest to you
5. Click "Create new project"
6. Wait for setup to complete (2-3 minutes)

### Step 2: Get Supabase Credentials

1. In your Supabase dashboard, go to **Settings** → **API**
2. Copy these values:
   - **Project URL** (looks like: `https://xyz.supabase.co`)
   - **anon public** key (starts with `eyJ...`)
   - **service_role** key (starts with `eyJ...`)

### Step 3: Set Up Backend

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create environment file:
   ```bash
   cp env.example .env
   ```

4. Edit `.env` with your Supabase credentials:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_SERVICE_KEY=your-service-role-key
   PORT=3000
   ```

5. Set up the database:
   ```bash
   npm run setup-db
   ```

6. Start the backend:
   ```bash
   npm run dev
   ```

7. Test the backend:
   ```bash
   curl http://localhost:3000/health
   ```

### Step 4: Set Up Frontend

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Update Supabase configuration:
   - Open `lib/supabase_client.dart`
   - Replace `<your-supabase-url>` with your Project URL
   - Replace `<your-anon-public-key>` with your anon public key

4. Run the Flutter app:
   ```bash
   flutter run
   ```

## 🧪 Testing Your Setup

### Backend Testing

1. **Health Check**:
   ```bash
   curl http://localhost:3000/health
   ```

2. **Test Upload** (requires authentication token):
   ```bash
   # You'll need to get a JWT token from the Flutter app first
   curl -X POST http://localhost:3000/upload \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     -d '{"test": "data"}'
   ```

### Frontend Testing

1. Open the Flutter app
2. Enter your email address
3. Check your email for the magic link
4. Click the link to authenticate
5. You should see the "Coming Soon" dashboard

## 🌐 Deployment

### Backend to Render

1. Push your code to GitHub
2. Go to [render.com](https://render.com) and sign up
3. Click "New Web Service"
4. Connect your GitHub repository
5. Configure the service:
   - **Name**: `franchise-player-api`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Environment Variables**: Add your `.env` variables
6. Click "Create Web Service"

### Frontend (Coming Soon)

- **Flutter Web**: Deploy to Firebase Hosting or Netlify
- **Mobile Apps**: Submit to App Store and Google Play

## 🔧 Troubleshooting

### Common Issues

1. **"supabaseUrl is required" error**:
   - Make sure your `.env` file is in the backend directory
   - Check that SUPABASE_URL is correct

2. **"Cannot find module" errors**:
   - Run `npm install` in the backend directory
   - Make sure you're in the correct directory

3. **Flutter "command not found"**:
   - Install Flutter SDK
   - Add Flutter to your PATH
   - Run `flutter doctor` to verify installation

4. **Authentication errors**:
   - Check that your Supabase keys are correct
   - Verify the database setup completed successfully

### Getting Help

- Check the individual README files in `/frontend` and `/backend`
- Review the [Supabase documentation](https://supabase.com/docs)
- Open an issue in the repository

## 🎉 Next Steps

Once everything is working:

1. **Customize the UI**: Update colors, fonts, and layout
2. **Add Features**: Implement data visualization
3. **Connect Madden App**: Set up the JSON upload from your Madden Companion App
4. **Deploy**: Push to production
5. **Monitor**: Set up logging and analytics

## 📞 Support

If you need help:
1. Check this setup guide
2. Review the README files
3. Check the troubleshooting section
4. Open an issue in the repository

---

**Happy coding! 🚀** 