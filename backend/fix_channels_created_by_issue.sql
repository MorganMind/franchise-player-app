-- Fix channels table created_by column issue
-- Run this in your Supabase SQL editor

-- First, let's check if created_by column exists
DO $$
DECLARE
    has_created_by BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'channels' 
        AND column_name = 'created_by' 
        AND table_schema = 'public'
    ) INTO has_created_by;
    
    IF has_created_by THEN
        -- Remove the created_by column if it exists
        ALTER TABLE channels DROP COLUMN created_by;
        RAISE NOTICE 'Removed created_by column from channels table';
    ELSE
        RAISE NOTICE 'created_by column does not exist, no action needed';
    END IF;
END $$;

-- Ensure we have all the required columns
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
    END IF;
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

-- Verify the table structure matches what the Flutter app expects
SELECT 
    'Schema verification' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channels' AND column_name = 'id') THEN '✓ id column exists'
        ELSE '✗ id column missing'
    END as id_check,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channels' AND column_name = 'server_id') THEN '✓ server_id column exists'
        ELSE '✗ server_id column missing'
    END as server_id_check,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channels' AND column_name = 'name') THEN '✓ name column exists'
        ELSE '✗ name column missing'
    END as name_check,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channels' AND column_name = 'type') THEN '✓ type column exists'
        ELSE '✗ type column missing'
    END as type_check,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channels' AND column_name = 'created_at') THEN '✓ created_at column exists'
        ELSE '✗ created_at column missing'
    END as created_at_check,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'channels' AND column_name = 'created_by') THEN '✗ created_by column still exists (should be removed)'
        ELSE '✓ created_by column does not exist (correct)'
    END as created_by_check; 