#!/bin/bash

# Build Flutter web app locally and prepare for Render deployment
echo "Building Flutter web app..."

# Navigate to frontend directory
cd frontend

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for web
flutter build web --release

echo "Build complete! Files are in frontend/build/web/"
echo "You can now deploy the contents of frontend/build/web/ to any static hosting service."
