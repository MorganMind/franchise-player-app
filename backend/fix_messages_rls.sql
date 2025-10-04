-- Fix RLS Policies for messages table
-- Run this script in your Supabase SQL editor

-- First, drop existing policies on messages table
DROP POLICY IF EXISTS "Select messages" ON messages;
DROP POLICY IF EXISTS "Insert messages" ON messages;
DROP POLICY IF EXISTS "Update messages" ON messages;
DROP POLICY IF EXISTS "Delete messages" ON messages;

-- Create new, more permissive policies for messages

-- 1. SELECT: Allow users to see messages in channels they're members of and DMs they participate in
CREATE POLICY "Select messages"
  ON messages
  FOR SELECT
  USING (
    -- Channel messages: user must be member of the server
    (channel_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM server_members sm
      JOIN channels c ON c.server_id = sm.server_id
      WHERE c.id = messages.channel_id
      AND sm.user_id = auth.uid()
    ))
    OR
    -- DM messages: user must be participant
    (dm_channel_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM dm_participants dp
      WHERE dp.dm_channel_id = messages.dm_channel_id
      AND dp.user_id = auth.uid()
    ))
  );

-- 2. INSERT: Allow authenticated users to send messages in channels they're members of and DMs they participate in
CREATE POLICY "Insert messages"
  ON messages
  FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL AND
    author_id = auth.uid() AND
    (
      -- Channel messages: user must be member of the server
      (channel_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM server_members sm
        JOIN channels c ON c.server_id = sm.server_id
        WHERE c.id = messages.channel_id
        AND sm.user_id = auth.uid()
      ))
      OR
      -- DM messages: user must be participant
      (dm_channel_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM dm_participants dp
        WHERE dp.dm_channel_id = messages.dm_channel_id
        AND dp.user_id = auth.uid()
      ))
    )
  );

-- 3. UPDATE: Allow users to edit their own messages
CREATE POLICY "Update messages"
  ON messages
  FOR UPDATE
  USING (author_id = auth.uid())
  WITH CHECK (author_id = auth.uid());

-- 4. DELETE: Allow users to delete their own messages (soft delete by setting is_deleted = true)
CREATE POLICY "Delete messages"
  ON messages
  FOR DELETE
  USING (author_id = auth.uid());

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