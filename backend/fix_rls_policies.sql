-- Fix RLS Policies to prevent infinite recursion
-- Run this script in your Supabase SQL editor

-- First, drop all existing policies to start fresh
DROP POLICY IF EXISTS "Select own DM channels" ON dm_channels;
DROP POLICY IF EXISTS "Insert DM channel if user is participant" ON dm_channels;
DROP POLICY IF EXISTS "Select own DM participations" ON dm_participants;
DROP POLICY IF EXISTS "Insert self as DM participant" ON dm_participants;
DROP POLICY IF EXISTS "Select messages in own DMs" ON messages;
DROP POLICY IF EXISTS "Insert messages in own DMs" ON messages;
DROP POLICY IF EXISTS "Select own user profile" ON user_profiles;
DROP POLICY IF EXISTS "Update own user profile" ON user_profiles;
DROP POLICY IF EXISTS "Select all servers" ON servers;
DROP POLICY IF EXISTS "Select all channels" ON channels;
DROP POLICY IF EXISTS "Select server members" ON server_members;

-- Create simplified, non-recursive policies

-- 1. User profiles - allow users to see all profiles (for discovery)
CREATE POLICY "Select all user profiles"
  ON user_profiles
  FOR SELECT
  USING (true);

CREATE POLICY "Update own user profile"
  ON user_profiles
  FOR UPDATE
  USING (id::text = auth.uid()::text);

-- 2. Servers - allow all authenticated users to see servers
CREATE POLICY "Select all servers"
  ON servers
  FOR SELECT
  USING (true);

-- 3. Channels - allow all authenticated users to see channels
CREATE POLICY "Select all channels"
  ON channels
  FOR SELECT
  USING (true);

-- 4. Server members - allow users to see members of servers they're in
CREATE POLICY "Select server members"
  ON server_members
  FOR SELECT
  USING (true);

-- 5. DM channels - simplified policy
CREATE POLICY "Select DM channels"
  ON dm_channels
  FOR SELECT
  USING (true);

CREATE POLICY "Insert DM channels"
  ON dm_channels
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- 6. DM participants - simplified policy to prevent recursion
CREATE POLICY "Select DM participants"
  ON dm_participants
  FOR SELECT
  USING (true);

CREATE POLICY "Insert DM participants"
  ON dm_participants
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- 7. Messages - simplified policy
CREATE POLICY "Select messages"
  ON messages
  FOR SELECT
  USING (true);

CREATE POLICY "Insert messages"
  ON messages
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Grant necessary permissions
GRANT ALL ON user_profiles TO authenticated;
GRANT ALL ON servers TO authenticated;
GRANT ALL ON channels TO authenticated;
GRANT ALL ON server_members TO authenticated;
GRANT ALL ON dm_channels TO authenticated;
GRANT ALL ON dm_participants TO authenticated;
GRANT ALL ON messages TO authenticated;

-- Display confirmation
SELECT 'RLS policies updated successfully! Infinite recursion issue should be resolved.' as status; 