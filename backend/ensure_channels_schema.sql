-- Ensure channels table has the correct schema
-- This script adds missing columns without recreating the table
-- Run this script in your Supabase SQL editor

-- Add missing columns if they don't exist
DO $$
BEGIN
    -- Add type column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'channels' 
        AND column_name = 'type' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE channels ADD COLUMN type TEXT DEFAULT 'text';
        RAISE NOTICE 'Added type column to channels table';
    ELSE
        RAISE NOTICE 'type column already exists';
    END IF;
    
    -- Add created_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'channels' 
        AND column_name = 'created_at' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE channels ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Added created_at column to channels table';
    ELSE
        RAISE NOTICE 'created_at column already exists';
    END IF;
    
    -- Add server_id column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'channels' 
        AND column_name = 'server_id' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE channels ADD COLUMN server_id UUID;
        RAISE NOTICE 'Added server_id column to channels table';
    ELSE
        RAISE NOTICE 'server_id column already exists';
    END IF;
    
    -- Add name column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'channels' 
        AND column_name = 'name' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE channels ADD COLUMN name TEXT;
        RAISE NOTICE 'Added name column to channels table';
    ELSE
        RAISE NOTICE 'name column already exists';
    END IF;
    
    -- Update existing records to have proper defaults
    UPDATE channels SET type = 'text' WHERE type IS NULL;
    UPDATE channels SET created_at = NOW() WHERE created_at IS NULL;
    
    RAISE NOTICE 'Channels table schema check and fix completed!';
END $$;

-- Show the final schema
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'channels' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Show sample data
SELECT 
    id,
    name,
    type,
    server_id,
    created_at
FROM channels 
LIMIT 5; 