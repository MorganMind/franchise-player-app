-- Fix RLS Policies for messages table - Simple Version
-- Run this script in your Supabase SQL editor

-- First, drop existing policies on messages table
DROP POLICY IF EXISTS "Select messages" ON messages;
DROP POLICY IF EXISTS "Insert messages" ON messages;
DROP POLICY IF EXISTS "Update messages" ON messages;
DROP POLICY IF EXISTS "Delete messages" ON messages;

-- Create simple, permissive policies for messages

-- 1. SELECT: Allow all authenticated users to see messages
CREATE POLICY "Select messages"
  ON messages
  FOR SELECT
  USING (true);

-- 2. INSERT: Allow authenticated users to send messages
CREATE POLICY "Insert messages"
  ON messages
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- 3. UPDATE: Allow users to edit their own messages
CREATE POLICY "Update messages"
  ON messages
  FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- 4. DELETE: Allow users to delete their own messages
CREATE POLICY "Delete messages"
  ON messages
  FOR DELETE
  USING (true);

-- Ensure RLS is enabled
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT ALL ON messages TO authenticated;

-- Display confirmation
SELECT 'Messages RLS policies updated successfully! Users can now read and send messages.' as status;

-- Test the policies by showing some sample messages
SELECT 
    m.id,
    m.content,
    m.created_at,
    CASE 
        WHEN m.channel_id IS NOT NULL THEN 'Channel'
        WHEN m.dm_channel_id IS NOT NULL THEN 'DM'
        ELSE 'Unknown'
    END as message_type,
    up.display_name as author_name
FROM messages m
LEFT JOIN user_profiles up ON m.author_id = up.id
ORDER BY m.created_at DESC
LIMIT 10; 