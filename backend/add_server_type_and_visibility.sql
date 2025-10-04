-- Add server_type and visibility fields to servers table
-- Run this script in your Supabase SQL editor

-- Add server_type column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'servers' AND column_name = 'server_type'
    ) THEN
        ALTER TABLE servers ADD COLUMN server_type TEXT DEFAULT 'General' CHECK (server_type IN ('Madden', 'CFB', 'General'));
        RAISE NOTICE 'Added server_type column to servers table';
    ELSE
        RAISE NOTICE 'server_type column already exists in servers table';
    END IF;
END $$;

-- Add visibility column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'servers' AND column_name = 'visibility'
    ) THEN
        ALTER TABLE servers ADD COLUMN visibility TEXT DEFAULT 'Public' CHECK (visibility IN ('Public', 'Private'));
        RAISE NOTICE 'Added visibility column to servers table';
    ELSE
        RAISE NOTICE 'visibility column already exists in servers table';
    END IF;
END $$;

-- Update existing servers with default values
UPDATE servers 
SET 
    server_type = COALESCE(server_type, 'General'),
    visibility = COALESCE(visibility, 'Public')
WHERE server_type IS NULL OR visibility IS NULL;

-- Show the updated table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'servers' 
ORDER BY ordinal_position;

-- Show current servers with their new columns
SELECT 
    id,
    name,
    description,
    server_type,
    visibility,
    icon,
    color,
    created_at
FROM servers
ORDER BY created_at;
