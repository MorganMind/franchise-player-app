# Franchise Player App

A comprehensive application for managing Madden franchise data with a Flutter frontend and Node.js backend, powered by Supabase.

## 🏗️ Project Structure

```
franchise-player-app/
├── frontend/          # Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── supabase_client.dart
│   │   ├── login_page.dart
│   │   └── home_page.dart
│   └── pubspec.yaml
├── backend/           # Node.js API
│   ├── index.js
│   ├── package.json
│   └── env.example
└── README.md
```

## 🚀 Quick Start

### Prerequisites

1. **Flutter SDK** - [Install Flutter](https://flutter.dev/docs/get-started/install)
2. **Node.js** (v14 or higher) - [Install Node.js](https://nodejs.org/)
3. **Supabase Account** - [Create Supabase Project](https://supabase.com/)

### Setup Instructions

#### 1. Clone and Setup

```bash
git clone <your-repo-url>
cd franchise-player-app
```

#### 2. Backend Setup

```bash
cd backend
npm install
cp env.example .env
# Edit .env with your Supabase credentials
npm run dev
```

#### 3. Frontend Setup

```bash
cd frontend
flutter pub get
# Edit lib/supabase_client.dart with your Supabase credentials
flutter run
```

## 📱 Frontend (Flutter)

The Flutter app provides:
- Email-based authentication with magic links
- Clean, modern UI
- Ready for franchise data integration

### Features
- ✅ Authentication with Supabase
- ✅ Responsive design
- ✅ Error handling
- 🔄 Dashboard (coming soon)
- 🔄 Data visualization (coming soon)

### Setup
See [frontend/README.md](frontend/README.md) for detailed instructions.

## 🔧 Backend (Node.js)

The Node.js API handles:
- JSON data ingestion from Madden Companion App
- Supabase integration
- RESTful endpoints

### Features
- ✅ JSON upload endpoint
- ✅ Supabase integration
- ✅ CORS enabled
- ✅ Error handling
- ✅ Health check endpoint

### API Endpoints
- `GET /health` - Health check
- `POST /upload` - Upload JSON data
- `GET /uploads` - Get all uploads (testing)

### Setup
See [backend/README.md](backend/README.md) for detailed instructions.

## 🗄️ Database Setup

Create the following table in your Supabase project:

```sql
CREATE TABLE json_uploads (
  id BIGSERIAL PRIMARY KEY,
  payload JSONB NOT NULL,
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 🌐 Deployment

### Backend (Render)
1. Push to GitHub
2. Create Web Service on Render
3. Set build command: `npm install`
4. Set start command: `npm start`
5. Add environment variables

### Frontend (Coming Soon)
- Flutter Web deployment
- Mobile app stores

## 🔧 Configuration

### Environment Variables

#### Backend (.env)
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-service-key
PORT=3000
```

#### Frontend (lib/supabase_client.dart)
```dart
url: 'https://your-project.supabase.co'
anonKey: 'your-anon-public-key'
```

## 🧪 Testing

### Backend API
```bash
# Health check
curl http://localhost:3000/health

# Upload test data
curl -X POST http://localhost:3000/upload \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'
```

### Frontend
```bash
cd frontend
flutter test
```

## 📋 TODO

### Frontend
- [ ] Connect to backend API
- [ ] Implement data visualization
- [ ] Add user profile management
- [ ] Create franchise data dashboard

### Backend
- [ ] Add authentication middleware
- [ ] Implement user-specific data storage
- [ ] Add data validation
- [ ] Create data processing pipelines

### General
- [ ] Add comprehensive testing
- [ ] Implement CI/CD pipeline
- [ ] Add monitoring and logging
- [ ] Performance optimization

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the ISC License.

## 🆘 Support

For support and questions:
- Check the individual README files in `/frontend` and `/backend`
- Review the Supabase documentation
- Open an issue in the repository 