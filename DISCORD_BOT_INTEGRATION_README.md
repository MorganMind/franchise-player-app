# Discord Bot Integration - Current App Setup

This document provides a comprehensive overview of the current Franchise Player app architecture and setup to enable a Discord bot to read/write team assignments, set nicknames, and manage composite roles.

## Current App Architecture

### Database Schema (Supabase Postgres)

#### Core Tables

**`user_profiles`** - User identity and Discord integration
```sql
CREATE TABLE public.user_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    username TEXT,
    display_name TEXT,
    avatar_url TEXT,
    discord_id TEXT,  -- Discord user ID (snowflake)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**`servers`** - Discord-like servers/franchises
```sql
CREATE TABLE public.servers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    icon_url TEXT,
    owner_id UUID REFERENCES public.user_profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**`server_members`** - Server membership and roles
```sql
CREATE TABLE public.server_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    server_id UUID REFERENCES public.servers(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member', -- 'owner', 'admin', 'moderator', 'member'
    nickname TEXT,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(server_id, user_id)
);
```

**`franchises`** - Franchise categories within servers
```sql
CREATE TABLE public.franchises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    server_id UUID REFERENCES public.servers(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    color TEXT,
    position INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**`teams`** - Teams within franchises
```sql
CREATE TABLE public.teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    franchise_id UUID REFERENCES public.franchises(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    abbreviation TEXT,
    city TEXT,
    conference TEXT,
    division TEXT,
    primary_color TEXT,
    secondary_color TEXT,
    logo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**`players`** - Player profiles
```sql
CREATE TABLE public.players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id),
    name TEXT NOT NULL,
    position TEXT,
    overall INTEGER,
    jersey_number INTEGER,
    height TEXT,
    weight INTEGER,
    age INTEGER,
    experience INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Authentication & Identity

#### Current Auth Setup
- **Provider**: Supabase Auth
- **Discord OAuth**: Configured and working
- **Email Linking**: Enabled for Discord users
- **User Identity Flow**:
  1. User signs in with Discord OAuth
  2. Supabase creates `auth.users` record
  3. Trigger function creates `user_profiles` record with `discord_id`
  4. Discord ID is extracted from OAuth response

#### Discord ID Storage
- **Location**: `user_profiles.discord_id` (TEXT)
- **Source**: Discord OAuth `sub` field (user snowflake)
- **Index**: `idx_user_profiles_discord_id` for performance
- **Backfill**: Existing Discord users automatically updated

### Current API Structure

#### Supabase Client Setup
```dart
// Frontend uses Supabase Flutter client
final supabase = Supabase.instance.client;

// Service role key available for backend operations
// Environment variable: SUPABASE_SERVICE_ROLE_KEY
```

#### Current Endpoints
- **Auth**: Supabase Auth (Discord OAuth, email/password)
- **Database**: Direct Supabase client queries
- **Real-time**: Supabase real-time subscriptions
- **Storage**: Supabase storage for avatars/logos

### Discord Integration Status

#### ✅ Implemented
- Discord OAuth authentication
- Discord user ID storage
- User profile management
- Server/franchise structure
- Team and player management
- Real-time messaging system

#### 🔄 Ready for Bot Integration
- User identity mapping (Supabase ID ↔ Discord ID)
- Server membership system
- Role-based permissions
- Team assignment structure
- Database schema optimized for Discord operations

### Bot Integration Requirements

#### 1. Discord Bot Setup
- **Bot Token**: Required for Discord API calls
- **Application ID**: For slash command registration
- **Public Key**: For signature verification
- **Permissions**: Manage roles, nicknames, read members

#### 2. Interaction Endpoint
- **URL**: Public HTTPS endpoint (Supabase Edge Function)
- **Method**: POST
- **Verification**: Discord signature verification
- **Response**: Discord interaction response format

#### 3. Database Operations
- **Service Role**: Use Supabase service role key
- **Operations**:
  - Read team assignments from `players` table
  - Update `server_members` for role management
  - Query `user_profiles` for Discord ID mapping
  - Manage `teams` and `franchises` data

#### 4. Discord API Operations
- **Role Management**: Add/remove roles based on team assignments
- **Nickname Updates**: Set nicknames to player names
- **Member Queries**: Get server member information
- **Composite Roles**: Create/manage role hierarchies

### Data Flow for Bot Operations

#### Team Assignment Flow
1. **Discord Command**: `/assign-team @user "Team Name"`
2. **Bot Verification**: Verify Discord signature
3. **Database Query**: Find team by name in `teams` table
4. **User Lookup**: Get Supabase user_id from Discord ID
5. **Assignment**: Update `players` table with team_id
6. **Role Update**: Add Discord role via Discord API
7. **Nickname Update**: Set Discord nickname to player name

#### Role Management Flow
1. **Discord Command**: `/manage-roles`
2. **Database Query**: Get all teams and their Discord roles
3. **Member Sync**: Compare Discord members vs database assignments
4. **Role Updates**: Add/remove roles to sync with database
5. **Response**: Send updated role status

### Security Considerations

#### Current Security Model
- **RLS Policies**: Row-level security on all tables
- **Auth Context**: User can only access their own data
- **Service Role**: Backend operations bypass RLS
- **Discord Verification**: All bot interactions verified

#### Bot Security Requirements
- **Signature Verification**: Verify Discord interaction signatures
- **Service Role Key**: Secure storage of Supabase service key
- **Bot Token Security**: Secure storage of Discord bot token
- **Rate Limiting**: Respect Discord API rate limits

### Environment Variables Needed

#### Supabase
```bash
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
SUPABASE_ANON_KEY=your_anon_key
```

#### Discord Bot
```bash
DISCORD_BOT_TOKEN=your_bot_token
DISCORD_APPLICATION_ID=your_application_id
DISCORD_PUBLIC_KEY=your_public_key
```

### Current File Structure

```
franchise-player-app/
├── backend/
│   ├── add_discord_id_column.sql          # Discord ID migration
│   ├── create_user_profiles_table.sql     # User profiles schema
│   ├── create_franchise_schema.sql        # Franchise/team schema
│   └── test_discord_id_capture.sql        # Discord ID testing
├── frontend/
│   ├── lib/
│   │   ├── models/
│   │   │   └── user.dart                  # User model with Discord ID
│   │   ├── services/
│   │   │   └── discord_service.dart       # Discord utilities
│   │   └── features/
│   │       └── user/
│   │           └── presentation/
│   │               └── profile_page.dart   # Discord profile display
├── supabase/
│   ├── config.toml                        # Supabase configuration
│   └── functions/                         # Edge functions directory
└── DISCORD_INTEGRATION.md                 # Discord integration docs
```

### Recommended Implementation Approach

#### Phase 1: Bot Foundation
1. Create Discord bot application
2. Set up Supabase Edge Function for interactions
3. Implement signature verification
4. Create basic slash command structure

#### Phase 2: Database Integration
1. Create bot-specific database functions
2. Implement team assignment commands
3. Add role management logic
4. Set up nickname synchronization

#### Phase 3: Advanced Features
1. Composite role management
2. Bulk operations
3. Audit logging
4. Error handling and recovery

### Key Integration Points

#### Database Queries for Bot
```sql
-- Get user by Discord ID
SELECT * FROM user_profiles WHERE discord_id = $1;

-- Get team assignments
SELECT p.*, t.name as team_name, f.name as franchise_name 
FROM players p 
JOIN teams t ON p.team_id = t.id 
JOIN franchises f ON t.franchise_id = f.id 
WHERE p.user_id = $1;

-- Get server members with roles
SELECT sm.*, up.discord_id, up.display_name 
FROM server_members sm 
JOIN user_profiles up ON sm.user_id = up.id 
WHERE sm.server_id = $1;
```

#### Discord API Operations
- **Role Management**: `PUT /guilds/{guild.id}/members/{user.id}/roles/{role.id}`
- **Nickname Updates**: `PATCH /guilds/{guild.id}/members/{user.id}`
- **Member Queries**: `GET /guilds/{guild.id}/members`
- **Role Queries**: `GET /guilds/{guild.id}/roles`

This setup provides a solid foundation for Discord bot integration with proper identity management, database structure, and security model already in place.


