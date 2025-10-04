-- Fix RLS policies for servers table
-- Run this script in your Supabase SQL editor

-- First, enable RLS on the servers table if not already enabled
ALTER TABLE servers ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow authenticated users to create servers" ON servers;
DROP POLICY IF EXISTS "Allow users to view servers they are members of" ON servers;
DROP POLICY IF EXISTS "Allow server owners to update their servers" ON servers;
DROP POLICY IF EXISTS "Allow server owners to delete their servers" ON servers;

-- Create policy to allow authenticated users to create servers
CREATE POLICY "Allow authenticated users to create servers" ON servers
    FOR INSERT WITH CHECK (
        auth.role() = 'authenticated' 
        AND auth.uid() = owner_id
    );

-- Create policy to allow users to view servers they are members of
CREATE POLICY "Allow users to view servers they are members of" ON servers
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM server_members 
            WHERE server_id = servers.id 
            AND user_id = auth.uid()
        )
    );

-- Create policy to allow server owners to update their servers
CREATE POLICY "Allow server owners to update their servers" ON servers
    FOR UPDATE USING (
        auth.role() = 'authenticated' 
        AND auth.uid() = owner_id
    );

-- Create policy to allow server owners to delete their servers
CREATE POLICY "Allow server owners to delete their servers" ON servers
    FOR DELETE USING (
        auth.role() = 'authenticated' 
        AND auth.uid() = owner_id
    );

-- Verify the policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'servers'
ORDER BY policyname;
