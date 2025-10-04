# Discord Integration - User ID Storage

This document describes the implementation of Discord user ID storage in the Franchise Player app.

## Overview

The application now supports storing Discord user IDs for users who sign up or link their Discord accounts. This enables Discord-specific features and account linking capabilities.

## Database Changes

### New Column
- **Table**: `user_profiles`
- **Column**: `discord_id` (TEXT, nullable)
- **Index**: `idx_user_profiles_discord_id` for performance

### Updated Trigger Function
The `handle_new_user()` trigger function has been updated to automatically capture Discord IDs when users sign up with Discord OAuth.

## Implementation Details

### 1. Database Migration
File: `backend/add_discord_id_column.sql`

This migration:
- Adds the `discord_id` column to the `user_profiles` table
- Creates an index for better query performance
- Updates the trigger function to capture Discord IDs
- Backfills existing Discord users with their Discord IDs
- Adds documentation comments

### 2. User Model Updates
File: `frontend/lib/models/user.dart`

The User model now includes:
- `discordId` field (nullable String)
- Updated JSON serialization/deserialization
- Updated `copyWith` method
- Updated `toString` method

### 3. Discord Service
File: `frontend/lib/services/discord_service.dart`

Utility service providing:
- Discord user detection
- Discord ID extraction
- Discord profile information retrieval
- Account linking status checking
- Discord username formatting

### 4. Profile Page Updates
File: `frontend/lib/features/user/presentation/profile_page.dart`

Enhanced profile page with:
- Discord account information display
- Discord linking functionality
- Visual indicators for Discord users
- Discord-themed UI elements

## How Discord ID Capture Works

### For New Users
1. User signs up with Discord OAuth
2. Supabase auth system processes the OAuth flow
3. `handle_new_user()` trigger function executes
4. Discord ID is extracted from `raw_user_meta_data` or `identities`
5. User profile is created with Discord ID stored

### For Existing Users
- The migration includes a backfill script that updates existing Discord users
- Users can link Discord accounts through the profile page

## Discord ID Sources

The system extracts Discord IDs from multiple sources in order of preference:

1. **Direct provider data**: `raw_user_meta_data->>'sub'` when provider is 'discord'
2. **Identities array**: Searches through the `identities` JSONB array for Discord provider
3. **Fallback**: NULL if no Discord identity is found

## Usage Examples

### Check if User is Discord User
```dart
final isDiscordUser = DiscordService.isDiscordUser(authUser);
```

### Get Discord ID
```dart
final discordId = DiscordService.getDiscordId(authUser);
```

### Get Discord Profile Info
```dart
final discordInfo = DiscordService.getDiscordUserInfo(authUser);
```

### Check if Profile Has Discord ID
```dart
final hasDiscordId = DiscordService.hasDiscordId(userProfile);
```

## Testing

### Database Testing
Run the test script to verify implementation:
```sql
-- Run this after applying the migration
\i backend/test_discord_id_capture.sql
```

### Frontend Testing
1. Sign up with Discord OAuth
2. Check profile page for Discord information
3. Verify Discord ID is displayed correctly
4. Test Discord account linking for existing users

## Configuration Requirements

### Supabase Auth Settings
1. Enable Discord OAuth provider in Supabase dashboard
2. Configure Discord OAuth application credentials
3. Set up redirect URLs
4. Enable email linking for Discord users

### Environment Variables
Ensure Discord OAuth credentials are properly configured in your Supabase project.

## Future Enhancements

Potential improvements:
- Discord webhook integration
- Discord role synchronization
- Discord server member verification
- Discord bot integration for server management
- Discord notification system

## Troubleshooting

### Common Issues

1. **Discord ID not captured**
   - Check if Discord OAuth is properly configured
   - Verify trigger function is working
   - Check auth.users table for Discord identities

2. **Profile page errors**
   - Ensure user_profile_provider is working
   - Check Discord service imports
   - Verify Supabase client configuration

3. **Migration failures**
   - Check database permissions
   - Verify table structure
   - Review trigger function syntax

### Debug Queries

```sql
-- Check Discord users
SELECT * FROM user_profiles WHERE discord_id IS NOT NULL;

-- Check auth identities
SELECT id, email, identities FROM auth.users 
WHERE identities IS NOT NULL 
AND EXISTS (
    SELECT 1 FROM jsonb_array_elements(identities) AS identity_data 
    WHERE identity_data->>'provider' = 'discord'
);
```

## Security Considerations

- Discord IDs are stored as plain text (they are public identifiers)
- No sensitive Discord data is stored
- RLS policies protect user profile data
- OAuth tokens are handled by Supabase auth system

## Migration Notes

- The migration is safe to run multiple times (uses `IF NOT EXISTS`)
- Existing Discord users will be backfilled automatically
- No data loss occurs during migration
- The migration can be rolled back by dropping the column and reverting the trigger function


