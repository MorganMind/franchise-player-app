-- Fix RLS policies for versioned_uploads table
-- Run this if the live_uploads view is not working

-- Drop all existing policies
DROP POLICY IF EXISTS "Users can view their own uploads" ON versioned_uploads;
DROP POLICY IF EXISTS "Public can view live versions" ON versioned_uploads;
DROP POLICY IF EXISTS "Users can insert their own uploads" ON versioned_uploads;
DROP POLICY IF EXISTS "Users can update their own uploads" ON versioned_uploads;
DROP POLICY IF EXISTS "Users can delete their own uploads" ON versioned_uploads;

-- Create simpler policies that allow public access to live versions
-- Allow public read access to live versions (this is the key one for the app)
CREATE POLICY "Public can view live versions" ON versioned_uploads
    FOR SELECT USING (version_status = 'live');

-- Allow authenticated users to view their own uploads
CREATE POLICY "Users can view their own uploads" ON versioned_uploads
    FOR SELECT USING (auth.uid() = user_id);

-- Allow authenticated users to insert their own uploads
CREATE POLICY "Users can insert their own uploads" ON versioned_uploads
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Allow authenticated users to update their own uploads
CREATE POLICY "Users can update their own uploads" ON versioned_uploads
    FOR UPDATE USING (auth.uid() = user_id);

-- Allow authenticated users to delete their own uploads
CREATE POLICY "Users can delete their own uploads" ON versioned_uploads
    FOR DELETE USING (auth.uid() = user_id);

-- Recreate the live_uploads view
DROP VIEW IF EXISTS live_uploads;
CREATE VIEW live_uploads AS
SELECT 
    id,
    user_id,
    franchise_id,
    upload_type,
    payload,
    uploaded_at,
    created_at
FROM versioned_uploads
WHERE version_status = 'live'
ORDER BY uploaded_at DESC;

-- Grant access to the view
GRANT SELECT ON live_uploads TO authenticated;
GRANT SELECT ON live_uploads TO anon;

-- Test the policies
SELECT 
    'Testing public access to live versions' as test,
    COUNT(*) as record_count
FROM versioned_uploads
WHERE version_status = 'live';

-- Show current policies
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'versioned_uploads'
ORDER BY policyname;
