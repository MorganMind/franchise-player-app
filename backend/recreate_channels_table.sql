-- Safely recreate channels table with correct schema
-- Run this script in your Supabase SQL editor

-- First, let's backup existing data
CREATE TEMP TABLE channels_backup AS 
SELECT * FROM channels;

-- Show what we're backing up
SELECT 
    'Backing up' as action,
    COUNT(*) as record_count
FROM channels_backup;

-- Drop the existing table (this will also drop all constraints and policies)
DROP TABLE IF EXISTS channels CASCADE;

-- Create the channels table with the correct schema
CREATE TABLE channels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  server_id UUID REFERENCES servers(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT DEFAULT 'text',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE channels ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT ALL ON channels TO authenticated;

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

-- Restore data from backup (only compatible columns)
INSERT INTO channels (id, server_id, name, type, created_at)
SELECT 
    id,
    server_id,
    name,
    COALESCE(type, 'text') as type,
    COALESCE(created_at, NOW()) as created_at
FROM channels_backup;

-- Show restored data
SELECT 
    'Restored' as action,
    COUNT(*) as record_count
FROM channels;

-- Show final schema
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

-- Clean up backup
DROP TABLE channels_backup;

SELECT 'Channels table recreated successfully!' as status; 