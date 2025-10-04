-- Update messages table to support both server channels and franchise channels
-- Run this script in your Supabase SQL editor

-- Add franchise_channel_id column to messages table
ALTER TABLE messages 
ADD COLUMN IF NOT EXISTS franchise_channel_id UUID REFERENCES franchise_channels(id) ON DELETE CASCADE;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_messages_franchise_channel_id ON messages(franchise_channel_id);

-- Update RLS policies to include franchise channels
DROP POLICY IF EXISTS "Select messages" ON messages;
DROP POLICY IF EXISTS "Insert messages" ON messages;
DROP POLICY IF EXISTS "Update messages" ON messages;
DROP POLICY IF EXISTS "Delete messages" ON messages;

-- 1. SELECT: Allow users to see messages in channels they're members of, franchise channels, and DMs they participate in
CREATE POLICY "Select messages"
  ON messages
  FOR SELECT
  USING (
    -- Server channel messages: user must be member of the server
    (channel_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM server_members sm
      JOIN channels c ON c.server_id = sm.server_id
      WHERE c.id = messages.channel_id
      AND sm.user_id = auth.uid()
    ))
    OR
    -- Franchise channel messages: user must be member of the server that contains the franchise
    (franchise_channel_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM server_members sm
      JOIN franchises f ON f.server_id = sm.server_id
      JOIN franchise_channels fc ON fc.franchise_id = f.id
      WHERE fc.id = messages.franchise_channel_id
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

-- 2. INSERT: Allow authenticated users to send messages in channels they're members of, franchise channels, and DMs they participate in
CREATE POLICY "Insert messages"
  ON messages
  FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL AND
    author_id = auth.uid() AND
    (
      -- Server channel messages: user must be member of the server
      (channel_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM server_members sm
        JOIN channels c ON c.server_id = sm.server_id
        WHERE c.id = messages.channel_id
        AND sm.user_id = auth.uid()
      ))
      OR
      -- Franchise channel messages: user must be member of the server that contains the franchise
      (franchise_channel_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM server_members sm
        JOIN franchises f ON f.server_id = sm.server_id
        JOIN franchise_channels fc ON fc.franchise_id = f.id
        WHERE fc.id = messages.franchise_channel_id
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
  USING (
    author_id = auth.uid()
  );

-- 4. DELETE: Allow users to delete their own messages
CREATE POLICY "Delete messages"
  ON messages
  FOR DELETE
  USING (
    author_id = auth.uid()
  );

-- Create a function to send messages to franchise channels
CREATE OR REPLACE FUNCTION send_franchise_channel_message(
  p_franchise_channel_id uuid,
  p_content text
) RETURNS uuid AS $$
DECLARE
  v_message_id uuid;
BEGIN
  -- Insert the message
  INSERT INTO messages (franchise_channel_id, author_id, content)
  VALUES (p_franchise_channel_id, auth.uid(), p_content)
  RETURNING id INTO v_message_id;
  
  RETURN v_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION send_franchise_channel_message TO authenticated;

-- Display confirmation
SELECT 'Messages table updated to support franchise channels!' as status;
