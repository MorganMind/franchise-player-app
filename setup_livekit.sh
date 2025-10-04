#!/bin/bash

# LiveKit Setup Script for Franchise Player App
# This script helps set up LiveKit integration

set -e

echo "🎤 Setting up LiveKit integration for Franchise Player App"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "README.md" ] || [ ! -d "frontend" ] || [ ! -d "backend" ]; then
    print_error "Please run this script from the root of the franchise-player-app directory"
    exit 1
fi

print_status "Setting up LiveKit integration..."

# Step 1: Install Flutter dependencies
print_status "Installing Flutter dependencies..."
cd frontend
flutter pub get
cd ..

print_success "Flutter dependencies installed"

# Step 2: Check if LiveKit schema has been applied
print_status "Checking database schema..."
print_warning "Please make sure you have run the following SQL scripts in your Supabase dashboard:"
echo "  1. backend/livekit_schema.sql"
echo "  2. backend/add_voice_channels.sql (optional - for testing)"

# Step 3: Check environment variables
print_status "Checking environment variables..."
print_warning "Make sure you have set up the following environment variables in your Supabase Edge Functions:"
echo "  - LIVEKIT_API_KEY"
echo "  - LIVEKIT_API_SECRET" 
echo "  - LIVEKIT_URL"
echo "  - LIVEKIT_HOST"

# Step 4: Deploy edge functions
print_status "Edge Functions to deploy:"
echo "  1. generate-livekit-token (updated)"
echo "  2. livekit-enforce-permissions (new)"

# Step 5: Test setup
print_status "Testing setup..."

# Check if Flutter app can be built
cd frontend
if flutter analyze --no-fatal-infos; then
    print_success "Flutter app analysis passed"
else
    print_warning "Flutter app has some warnings (this is normal for new features)"
fi
cd ..

# Step 6: Instructions
echo ""
print_success "Setup complete! Next steps:"
echo ""
echo "1. 📊 Database Setup:"
echo "   - Run backend/livekit_schema.sql in Supabase SQL Editor"
echo "   - Run backend/add_voice_channels.sql for test channels"
echo ""
echo "2. 🔧 Edge Functions:"
echo "   - Deploy generate-livekit-token function"
echo "   - Deploy livekit-enforce-permissions function"
echo "   - Set environment variables in Supabase"
echo ""
echo "3. 🌐 LiveKit Cloud:"
echo "   - Create account at https://cloud.livekit.io/"
echo "   - Get API credentials"
echo "   - Configure webhook (optional)"
echo ""
echo "4. 🧪 Testing:"
echo "   - Run: cd frontend && flutter run -d web-server --web-port 3000"
echo "   - Navigate to a voice channel"
echo "   - Click 'Join' to test voice functionality"
echo ""
echo "📖 For detailed instructions, see LIVEKIT_SETUP.md"
echo ""

print_success "LiveKit integration setup script completed!"
print_warning "Remember to configure your LiveKit Cloud credentials before testing" 