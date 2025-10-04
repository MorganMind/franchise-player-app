-- Comprehensive fix for channels table issues
-- Run this in your Supabase SQL editor

-- Step 1: Check current schema
SELECT 'Current schema check' as step;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'channels' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 2: Remove any problematic columns that shouldn't exist
DO $$
DECLARE
    has_created_by BOOLEAN;
    has_position BOOLEAN;
    has_description BOOLEAN;
BEGIN
    -- Check for created_by column
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'channels' 
        AND column_name = 'created_by' 
        AND table_schema = 'public'
    ) INTO has_created_by;
    
    -- Check for position column
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'channels' 
        AND column_name = 'position' 
        AND table_schema = 'public'
    ) INTO has_position;
    
    -- Check for description column
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'channels' 
        AND column_name = 'description' 
        AND table_schema = 'public'
    ) INTO has_description;
    
    -- Remove problematic columns
    IF has_created_by THEN
        ALTER TABLE channels DROP COLUMN created_by;
        RAISE NOTICE 'Removed created_by column from channels table';
    END IF;
    
    IF has_position THEN
        ALTER TABLE channels DROP COLUMN position;
        RAISE NOTICE 'Removed position column from channels table';
    END IF;
    
    IF has_description THEN
        ALTER TABLE channels DROP COLUMN description;
        RAISE NOTICE 'Removed description column from channels table';
    END IF;
END $$;

-- Step 3: Ensure all required columns exist with correct types
DO $$
BEGIN
    -- Add id column if it doesn't exist (should always exist as primary key)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'channels' 
        AND column_name = 'id' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE channels ADD COLUMN id UUID PRIMARY KEY DEFAULT gen_random_uuid();
        RAISE NOTICE 'Added id column to channels table';
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
END $$;

-- Step 4: Update existing records to have proper defaults
UPDATE channels SET type = 'text' WHERE type IS NULL;
UPDATE channels SET created_at = NOW() WHERE created_at IS NULL;

-- Step 5: Ensure foreign key constraint exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'channels' 
        AND constraint_name LIKE '%server_id%'
        AND constraint_type = 'FOREIGN KEY'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE channels ADD CONSTRAINT channels_server_id_fkey 
        FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added foreign key constraint for server_id';
    END IF;
END $$;

-- Step 6: Ensure RLS is enabled and policies are correct
ALTER TABLE channels ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to recreate them
DROP POLICY IF EXISTS "View channels in server" ON channels;
DROP POLICY IF EXISTS "Insert channels in server" ON channels;
DROP POLICY IF EXISTS "Update channels in server" ON channels;
DROP POLICY IF EXISTS "Delete channels in server" ON channels;

-- Create RLS policies
CREATE POLICY "View channels in server" ON channels
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM server_members sm
      WHERE sm.server_id = channels.server_id
      AND sm.user_id = auth.uid()
    )
  );

CREATE POLICY "Insert channels in server" ON channels
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM server_members sm
      WHERE sm.server_id = channels.server_id
      AND sm.user_id = auth.uid()
    )
  );

CREATE POLICY "Update channels in server" ON channels
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM server_members sm
      WHERE sm.server_id = channels.server_id
      AND sm.user_id = auth.uid()
    )
  );

CREATE POLICY "Delete channels in server" ON channels
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM server_members sm
      WHERE sm.server_id = channels.server_id
      AND sm.user_id = auth.uid()
    )
  );

-- Step 7: Grant permissions
GRANT ALL ON channels TO authenticated;

-- Step 8: Show final schema
SELECT 'Final schema verification' as step;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'channels' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 9: Test insert (this should work now)
SELECT 'Testing insert...' as step;
INSERT INTO channels (name, server_id, type, created_at) 
VALUES ('test-channel', '660e8400-e29b-41d4-a716-446655440001', 'text', NOW())
ON CONFLICT DO NOTHING;

-- Step 10: Show sample data
SELECT 'Sample data' as step;
SELECT 
    id,
    name,
    type,
    server_id,
    created_at
FROM channels 
ORDER BY created_at DESC
LIMIT 5;

-- Step 11: Clean up test data
DELETE FROM channels WHERE name = 'test-channel';

SELECT 'Channels table fix completed successfully!' as status; 