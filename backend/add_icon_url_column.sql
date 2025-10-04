-- Add icon_url column to servers table
-- Run this script in your Supabase SQL editor

-- Add icon_url column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'servers' AND column_name = 'icon_url'
    ) THEN
        ALTER TABLE servers ADD COLUMN icon_url TEXT;
        RAISE NOTICE 'Added icon_url column to servers table';
    ELSE
        RAISE NOTICE 'icon_url column already exists in servers table';
    END IF;
END $$;

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
    icon_url,
    color,
    created_at
FROM servers
ORDER BY created_at;
