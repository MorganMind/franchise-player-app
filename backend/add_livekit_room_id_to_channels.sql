-- Add livekit_room_id column to channels table
-- Run this in your Supabase SQL editor

-- Add livekit_room_id column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'channels' 
        AND column_name = 'livekit_room_id' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE channels ADD COLUMN livekit_room_id text UNIQUE;
        RAISE NOTICE 'Added livekit_room_id column to channels table';
    ELSE
        RAISE NOTICE 'livekit_room_id column already exists';
    END IF;
END $$;

-- Update existing voice channels with livekit_room_id
UPDATE channels 
SET livekit_room_id = 'voice-room-' || id::text
WHERE type = 'voice' AND livekit_room_id IS NULL;

-- Show the updated channels
SELECT 
  id,
  name,
  type,
  livekit_room_id,
  server_id
FROM channels 
WHERE type = 'voice'
ORDER BY name; 