# Franchise System Implementation

This document describes the implementation of the franchise system in the Franchise Player app, which adds Discord-like franchise categories to the existing server structure.

## 🏗️ Architecture Overview

The franchise system extends the existing Discord-like architecture with:

- **Franchises**: Special categories that represent Madden franchises
- **Franchise Channels**: Text, voice, and video channels within franchises
- **Nested Structure**: Franchises contain channels, similar to Discord categories

## 📊 Database Schema

### New Tables

#### `franchises`
```sql
CREATE TABLE public.franchises (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  server_id uuid NOT NULL REFERENCES public.servers(id) ON DELETE CASCADE,
  name text NOT NULL,
  external_id text UNIQUE, -- Madden's internal ID
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);
```

#### `franchise_channels`
```sql
CREATE TABLE public.franchise_channels (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  franchise_id uuid NOT NULL REFERENCES public.franchises(id) ON DELETE CASCADE,
  name text NOT NULL,
  type text NOT NULL CHECK (type IN ('text', 'voice', 'video')),
  position integer NOT NULL DEFAULT 0,
  livekit_room_id text UNIQUE,
  voice_enabled boolean DEFAULT false,
  video_enabled boolean DEFAULT false,
  is_private boolean DEFAULT false,
  max_participants integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);
```

### Key Features

- **External ID**: Links to Madden's internal franchise ID
- **Metadata**: JSONB field for flexible franchise data storage
- **Channel Types**: Support for text, voice, and video channels
- **LiveKit Integration**: Ready for voice/video calls
- **Positioning**: Channels can be reordered within franchises

## 🔐 Security & Permissions

### Row Level Security (RLS)
- All tables have RLS enabled
- Users can only access franchises in servers they're members of
- Same permission model as regular channels

### RLS Policies
```sql
-- View franchises if member of server
CREATE POLICY "View franchises in server" ON public.franchises
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.server_members sm
      WHERE sm.server_id = franchises.server_id
      AND sm.user_id = auth.uid()
    )
  );

-- View franchise channels if member of server
CREATE POLICY "View franchise channels" ON public.franchise_channels
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.franchises f
      JOIN public.server_members sm ON sm.server_id = f.server_id
      WHERE f.id = franchise_channels.franchise_id
      AND sm.user_id = auth.uid()
    )
  );
```

## 🚀 Setup Instructions

### 1. Database Setup

Run the SQL scripts in order:

```bash
# 1. Create the franchise schema
backend/create_franchise_schema.sql

# 2. Create the Madden X server (if not exists)
backend/create_madden_x_server.sql

# 3. Create a test franchise
backend/create_test_franchise.sql
```

### 2. Flutter Setup

The Flutter implementation includes:

#### Models
- `Franchise`: Core franchise entity
- `FranchiseChannel`: Channel within a franchise

#### Providers
- `serverFranchisesProvider`: Stream of franchises in a server
- `franchiseChannelsProvider`: Stream of channels in a franchise
- `FranchiseRepository`: CRUD operations for franchises

#### UI Components
- `FranchiseSidebar`: Shows franchises in the channel sidebar
- `FranchiseContentPage`: Main content area for franchises
- `FranchiseHeaderNav`: Header navigation for franchises

## 🎨 UI/UX Design

### Franchise Sidebar
- Fixed "Franchises" section in channel sidebar
- Expandable/collapsible franchise items
- Nested channel display
- Visual indicators for channel types (text/voice/video)

### Franchise Content
- Header navigation with franchise info
- Breadcrumb navigation
- Channel-specific content areas
- Placeholder for voice/video call integration

### Visual Hierarchy
```
📁 Franchises
  🏈 Madden 24 Franchise
    # general
    # trades
    # draft
    # game-discussion
    # announcements
    🔊 General Voice
    🔊 Game Night
```

## 🔧 API Functions

### Database Functions

#### `create_franchise_with_default_channels()`
Creates a franchise with a standard set of channels:

```sql
SELECT create_franchise_with_default_channels(
  'server_id',
  'Franchise Name',
  'external_id',
  '{"metadata": "value"}'::jsonb
);
```

Default channels created:
- `general` (text)
- `trades` (text)
- `draft` (text)
- `game-discussion` (text)
- `announcements` (text)
- `General Voice` (voice)
- `Game Night` (voice)

### Flutter Repository Methods

```dart
// Create franchise with default channels
await FranchiseRepository.createFranchise(
  serverId: 'server_id',
  name: 'Franchise Name',
  externalId: 'external_id',
  metadata: {'key': 'value'},
);

// Create custom franchise
await FranchiseRepository.createCustomFranchise(
  serverId: 'server_id',
  name: 'Franchise Name',
);

// Create franchise channel
await FranchiseRepository.createFranchiseChannel(
  franchiseId: 'franchise_id',
  name: 'Channel Name',
  type: 'text', // or 'voice', 'video'
);
```

## 🔄 Data Flow

### 1. Server Selection
User clicks on a server → Load franchises for that server

### 2. Franchise Selection
User clicks on a franchise → Load franchise channels → Show franchise overview

### 3. Channel Selection
User clicks on a franchise channel → Show channel-specific content

### 4. Real-time Updates
All data streams automatically update when changes occur in Supabase

## 🎯 Future Enhancements

### Planned Features
- [ ] Voice/video call integration with LiveKit
- [ ] Franchise templates for different game modes
- [ ] Franchise statistics and analytics
- [ ] Franchise-specific permissions
- [ ] Franchise import/export functionality
- [ ] Integration with Madden API for real-time data

### LiveKit Integration
The schema is prepared for LiveKit integration:
- `livekit_room_id` field in franchise_channels
- Voice/video channel types
- Room management ready for implementation

## 🧪 Testing

### Manual Testing Steps

1. **Database Setup**
   ```sql
   -- Run in Supabase SQL editor
   \i backend/create_franchise_schema.sql
   \i backend/create_madden_x_server.sql
   \i backend/create_test_franchise.sql
   ```

2. **Flutter Testing**
   - Start the Flutter app
   - Navigate to the Madden X server
   - Look for the "Franchises" section in the sidebar
   - Click on "Test Franchise 2024"
   - Expand/collapse the franchise
   - Click on different channels

3. **Expected Behavior**
   - Franchises section appears in sidebar
   - Franchise expands/collapses on click
   - Channels show with appropriate icons
   - Franchise content page loads
   - Channel content pages load

## 🐛 Troubleshooting

### Common Issues

1. **Franchises not showing**
   - Check if user is a member of the server
   - Verify RLS policies are working
   - Check Supabase logs for errors

2. **Channels not loading**
   - Verify franchise exists
   - Check franchise_channels table
   - Ensure proper foreign key relationships

3. **Permission errors**
   - Verify user authentication
   - Check server membership
   - Review RLS policies

### Debug Queries

```sql
-- Check franchises in a server
SELECT * FROM franchises WHERE server_id = 'your_server_id';

-- Check franchise channels
SELECT * FROM franchise_channels WHERE franchise_id = 'your_franchise_id';

-- Check user permissions
SELECT * FROM server_members WHERE user_id = auth.uid() AND server_id = 'your_server_id';
```

## 📝 Notes

- The franchise system follows the same patterns as the existing channel system
- All UI components use `SelectableText` for accessibility
- The system is designed to be extensible for future Madden API integration
- Voice/video functionality is prepared but not yet implemented
- The system supports both user-created and auto-generated franchises

## 🔗 Related Files

- `backend/create_franchise_schema.sql` - Database schema
- `frontend/lib/models/franchise.dart` - Flutter models
- `frontend/lib/providers/franchise_providers.dart` - Data providers
- `frontend/lib/features/franchise/` - UI components
- `backend/create_test_franchise.sql` - Test data 