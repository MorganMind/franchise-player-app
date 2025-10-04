-- Add voice-specific columns to channels table
-- Run this in your Supabase SQL editor

-- Add voice_enabled column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'channels' 
        AND column_name = 'voice_enabled' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE channels ADD COLUMN voice_enabled boolean DEFAULT false;
        RAISE NOTICE 'Added voice_enabled column to channels table';
    ELSE
        RAISE NOTICE 'voice_enabled column already exists';
    END IF;
END $$;

-- Add video_enabled column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'channels' 
        AND column_name = 'video_enabled' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE channels ADD COLUMN video_enabled boolean DEFAULT false;
        RAISE NOTICE 'Added video_enabled column to channels table';
    ELSE
        RAISE NOTICE 'video_enabled column already exists';
    END IF;
END $$;

-- Add max_participants column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'channels' 
        AND column_name = 'max_participants' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE channels ADD COLUMN max_participants integer DEFAULT 0;
        RAISE NOTICE 'Added max_participants column to channels table';
    ELSE
        RAISE NOTICE 'max_participants column already exists';
    END IF;
END $$;

-- Update existing voice channels to have voice_enabled = true
UPDATE channels 
SET voice_enabled = true 
WHERE type = 'voice' AND voice_enabled IS NULL;

-- Show the updated schema
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'channels' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Show sample voice channels
SELECT 
  id,
  name,
  type,
  voice_enabled,
  video_enabled,
  max_participants,
  created_at
FROM channels 
WHERE type = 'voice'
ORDER BY name; 