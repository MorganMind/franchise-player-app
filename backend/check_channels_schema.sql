-- Check current channels table schema
-- Run this in your Supabase SQL editor

-- Show the current schema
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'channels' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check if created_by column exists
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'channels' 
            AND column_name = 'created_by' 
            AND table_schema = 'public'
        ) THEN 'created_by column EXISTS'
        ELSE 'created_by column does NOT exist'
    END as column_status;

-- Show sample data to understand the current structure
SELECT 
    id,
    name,
    type,
    server_id,
    created_at
FROM channels 
LIMIT 3; 