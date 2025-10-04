# Franchise Management Features

This document describes the new franchise management functionality that allows users to create, edit, and manage franchises and their channels with real database operations.

## Features

### 1. Franchise Management
- **Add New Franchises**: Create new franchises with custom names
- **Edit Franchise Names**: Change the name of existing franchises
- **View All Franchises**: See all franchises in the current server
- **Real-time Updates**: Changes are reflected immediately across the application

### 2. Channel Management
- **Add New Channels**: Create text, voice, or video channels within franchises
- **Edit Channel Properties**: Modify channel names and types
- **Delete Channels**: Remove channels from franchises
- **Channel Types**: Support for text, voice, and video channels
- **Channel Properties**: Configure voice/video enabled, private status, and max participants

### 3. Database Integration
- **Real Database Operations**: All operations use Supabase database
- **Row Level Security**: Proper RLS policies ensure data security
- **Cascading Deletes**: Deleting a franchise removes all associated channels
- **Audit Trail**: Created and updated timestamps are automatically managed

## How to Use

### Accessing Franchise Management
1. Navigate to the main application
2. Open the drawer menu (hamburger icon)
3. Click on "Franchise Management" in the menu
4. Or click the business icon in the franchise page header

### Adding a New Franchise
1. Make sure you have selected a server first
2. Click the "+" button in the franchise management page header
3. Enter a franchise name
4. Click "Add" to create the franchise with default channels

### Editing a Franchise
1. Find the franchise you want to edit in the list
2. Click the edit (pencil) icon next to the franchise name
3. Modify the franchise name
4. Click "Update" to save changes

### Adding a Channel
1. Expand a franchise card to see its channels
2. Click the "+" button next to the franchise name or "Add Channel" button
3. Enter a channel name and select the channel type
4. Click "Add" to create the channel

### Editing a Channel
1. Find the channel you want to edit
2. Click the edit (pencil) icon next to the channel
3. Modify the channel name and/or type
4. Click "Update" to save changes

### Deleting a Channel
1. Find the channel you want to delete
2. Click the delete (trash) icon next to the channel
3. Confirm the deletion in the dialog
4. Click "Delete" to remove the channel

## Database Schema

### Franchises Table
```sql
CREATE TABLE public.franchises (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  server_id uuid NOT NULL REFERENCES public.servers(id) ON DELETE CASCADE,
  name text NOT NULL,
  external_id text UNIQUE,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);
```

### Franchise Channels Table
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

## Security

- **Row Level Security (RLS)**: All tables have RLS enabled
- **Server Membership**: Users can only manage franchises in servers they belong to
- **Authentication Required**: All operations require user authentication
- **Cascading Deletes**: Proper foreign key constraints ensure data integrity

## Default Channels

When a new franchise is created, the following default channels are automatically created:
- `general` (text)
- `trades` (text)
- `draft` (text)
- `game-discussion` (text)
- `announcements` (text)
- `General Voice` (voice)
- `Game Night` (voice)

## API Functions

### FranchiseRepository Class
The `FranchiseRepository` class provides the following methods:

- `createFranchise()`: Create a new franchise with default channels
- `createCustomFranchise()`: Create a franchise without default channels
- `updateFranchise()`: Update franchise properties
- `deleteFranchise()`: Delete a franchise and all its channels
- `createFranchiseChannel()`: Create a new channel in a franchise
- `updateFranchiseChannel()`: Update channel properties
- `deleteFranchiseChannel()`: Delete a channel
- `reorderFranchiseChannels()`: Reorder channels within a franchise

## Providers

The following Riverpod providers are available:

- `franchisesProvider`: Stream of franchises for a server
- `franchiseProvider`: Stream of a specific franchise
- `franchiseChannelsProvider`: Stream of channels for a franchise
- `franchiseChannelProvider`: Stream of a specific channel
- `allFranchisesProvider`: Stream of all franchises across all servers
- `allFranchiseChannelsProvider`: Stream of all channels across all franchises

## Error Handling

The application includes comprehensive error handling:
- Network connectivity issues
- Database permission errors
- Validation errors for required fields
- User-friendly error messages
- Loading states during operations

## Future Enhancements

Potential future improvements:
- Channel reordering via drag and drop
- Bulk channel operations
- Channel templates
- Advanced channel permissions
- Channel categories/groups
- Channel statistics and analytics
