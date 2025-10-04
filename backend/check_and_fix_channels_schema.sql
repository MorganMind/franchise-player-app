-- Check and fix channels table schema
-- Run this script in your Supabase SQL editor

-- First, let's see what the current channels table looks like
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'channels' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check if we have the basic required columns
DO $$
DECLARE
    has_id BOOLEAN;
    has_server_id BOOLEAN;
    has_name BOOLEAN;
    has_type BOOLEAN;
    has_created_at BOOLEAN;
BEGIN
    -- Check if required columns exist
    SELECT EXISTS(
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'channels' 
        AND column_name = 'id' 
        AND table_schema = 'public'
    ) INTO has_id;
    
    SELECT EXISTS(
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'channels' 
        AND column_name = 'server_id' 
        AND table_schema = 'public'
    ) INTO has_server_id;
    
    SELECT EXISTS(
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'channels' 
        AND column_name = 'name' 
        AND table_schema = 'public'
    ) INTO has_name;
    
    SELECT EXISTS(
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'channels' 
        AND column_name = 'type' 
        AND table_schema = 'public'
    ) INTO has_type;
    
    SELECT EXISTS(
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'channels' 
        AND column_name = 'created_at' 
        AND table_schema = 'public'
    ) INTO has_created_at;
    
    -- Report what we found
    RAISE NOTICE 'Channels table schema check:';
    RAISE NOTICE '  id column: %', has_id;
    RAISE NOTICE '  server_id column: %', has_server_id;
    RAISE NOTICE '  name column: %', has_name;
    RAISE NOTICE '  type column: %', has_type;
    RAISE NOTICE '  created_at column: %', has_created_at;
    
    -- Add missing columns if needed
    IF NOT has_type THEN
        ALTER TABLE channels ADD COLUMN type TEXT DEFAULT 'text';
        RAISE NOTICE 'Added type column to channels table';
    END IF;
    
    IF NOT has_created_at THEN
        ALTER TABLE channels ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Added created_at column to channels table';
    END IF;
    
    -- Update existing records to have proper type if needed
    UPDATE channels SET type = 'text' WHERE type IS NULL;
    
    RAISE NOTICE 'Channels table schema check completed!';
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

-- Show sample data to verify everything works
SELECT 
    id,
    name,
    type,
    server_id,
    created_at
FROM channels 
LIMIT 5; 