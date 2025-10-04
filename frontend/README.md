# Franchise Player - Flutter Frontend

This is the Flutter frontend for the Franchise Player app that uses Supabase for authentication and data storage.

## Setup Instructions

### Prerequisites
1. Install Flutter SDK (https://flutter.dev/docs/get-started/install)
2. Install Android Studio or VS Code with Flutter extensions
3. Set up a Supabase project

### Installation
1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Update Supabase configuration:
   - Open `lib/supabase_client.dart`
   - Replace `<your-supabase-url>` with your actual Supabase URL
   - Replace `<your-anon-public-key>` with your actual Supabase anon key

4. Run the app:
   ```bash
   flutter run
   ```

## Features
- Email-based authentication with magic links
- Clean, modern UI
- Ready for franchise data integration

## Project Structure
- `lib/main.dart` - App entry point
- `lib/supabase_client.dart` - Supabase configuration
- `lib/login_page.dart` - Authentication page
- `lib/home_page.dart` - Dashboard (placeholder)

## Development Rules

### 🚫 NO MOCK DATA POLICY
**NEVER use mock data, hardcoded data, or placeholder data as a crutch or temporary fix.**
- All data must come from the real Supabase database
- Use real providers and database queries
- If data doesn't exist, create it in the database or handle the empty state properly
- Mock data is forbidden - it creates technical debt and masks real issues

## Next Steps
- Connect to backend API for data upload
- Implement franchise data visualization
- Add user profile management 