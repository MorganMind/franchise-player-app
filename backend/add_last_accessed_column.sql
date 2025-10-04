-- Add last_accessed_at column to server_members table for tracking recent server access
-- Run this script in your Supabase SQL editor

-- Add last_accessed_at column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'server_members' AND column_name = 'last_accessed_at'
    ) THEN
        ALTER TABLE server_members ADD COLUMN last_accessed_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Added last_accessed_at column to server_members table';
    ELSE
        RAISE NOTICE 'last_accessed_at column already exists in server_members table';
    END IF;
END $$;

-- Update existing server members with current timestamp as last_accessed_at
UPDATE server_members 
SET last_accessed_at = NOW()
WHERE last_accessed_at IS NULL;

-- Show the updated table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'server_members' 
ORDER BY ordinal_position;

-- Show current server members with their last_accessed_at
SELECT 
    sm.user_id,
    sm.server_id,
    s.name as server_name,
    sm.last_accessed_at,
    sm.joined_at
FROM server_members sm
JOIN servers s ON sm.server_id = s.id
ORDER BY sm.last_accessed_at DESC NULLS LAST;
