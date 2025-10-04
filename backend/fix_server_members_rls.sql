-- Fix RLS Policies for server_members table
-- Run this script in your Supabase SQL editor

-- First, drop existing policies on server_members table
DROP POLICY IF EXISTS "Select server members" ON server_members;
DROP POLICY IF EXISTS "Insert server members" ON server_members;
DROP POLICY IF EXISTS "Update server members" ON server_members;
DROP POLICY IF EXISTS "Delete server members" ON server_members;

-- Create new, more permissive policies for server_members

-- 1. SELECT: Allow users to see all server members (for discovery and UI)
CREATE POLICY "Select all server members"
  ON server_members
  FOR SELECT
  USING (true);

-- 2. INSERT: Allow authenticated users to join servers
CREATE POLICY "Insert server members"
  ON server_members
  FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL AND
    user_id = auth.uid()
  );

-- 3. UPDATE: Allow users to update their own server memberships (nickname, etc.)
CREATE POLICY "Update own server memberships"
  ON server_members
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- 4. DELETE: Allow users to leave servers (delete their own memberships)
CREATE POLICY "Delete own server memberships"
  ON server_members
  FOR DELETE
  USING (user_id = auth.uid());

-- Ensure RLS is enabled
ALTER TABLE server_members ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT ALL ON server_members TO authenticated;

-- Display confirmation
SELECT 'Server members RLS policies updated successfully! Users can now join servers.' as status;

-- Test the policies by showing current server members
SELECT 
    s.name as server_name,
    up.username,
    up.display_name,
    sm.nickname,
    sm.joined_at
FROM server_members sm
JOIN servers s ON sm.server_id = s.id
JOIN user_profiles up ON sm.user_id = up.id
ORDER BY s.name, up.display_name; 