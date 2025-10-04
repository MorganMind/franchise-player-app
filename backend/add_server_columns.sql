-- Add missing columns to servers table
-- Run this script in your Supabase SQL editor

-- Add description column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'servers' AND column_name = 'description'
    ) THEN
        ALTER TABLE servers ADD COLUMN description TEXT;
        RAISE NOTICE 'Added description column to servers table';
    ELSE
        RAISE NOTICE 'description column already exists in servers table';
    END IF;
END $$;

-- Add icon column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'servers' AND column_name = 'icon'
    ) THEN
        ALTER TABLE servers ADD COLUMN icon TEXT;
        RAISE NOTICE 'Added icon column to servers table';
    ELSE
        RAISE NOTICE 'icon column already exists in servers table';
    END IF;
END $$;

-- Add color column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'servers' AND column_name = 'color'
    ) THEN
        ALTER TABLE servers ADD COLUMN color TEXT;
        RAISE NOTICE 'Added color column to servers table';
    ELSE
        RAISE NOTICE 'color column already exists in servers table';
    END IF;
END $$;

-- Update existing servers with default values
UPDATE servers 
SET 
    description = COALESCE(description, 'A great server for collaboration'),
    icon = COALESCE(icon, '🏠'),
    color = COALESCE(color, '#7289DA')
WHERE description IS NULL OR icon IS NULL OR color IS NULL;

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
    icon,
    color,
    owner_id,
    created_at
FROM servers
ORDER BY created_at; 