-- Update all existing channels with livekit_room_id
-- Run this script in your Supabase SQL editor

-- Update text channels (these don't need livekit_room_id, but we'll set them to NULL for clarity)
UPDATE channels 
SET livekit_room_id = NULL 
WHERE type = 'text' OR type IS NULL OR type = '';

-- Update voice channels with unique livekit_room_id values
UPDATE channels 
SET livekit_room_id = 'voice-room-' || id::text
WHERE type = 'voice';

-- Update any channels that still don't have livekit_room_id (fallback)
UPDATE channels 
SET livekit_room_id = 'voice-room-' || id::text
WHERE livekit_room_id IS NULL;

-- Display summary
SELECT 
  'Channels updated successfully!' as status,
  COUNT(*) as total_channels,
  COUNT(CASE WHEN type = 'voice' THEN 1 END) as voice_channels,
  COUNT(CASE WHEN type = 'text' THEN 1 END) as text_channels
FROM channels;

-- Show all channels with their livekit_room_id
SELECT 
  id,
  name,
  type,
  livekit_room_id,
  server_id
FROM channels 
ORDER BY type, name; 