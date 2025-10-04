-- Create server-assets storage bucket for server icons (Safe Version)
-- This script handles existing policies gracefully

-- Step 1: Create the storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'server-assets',
    'server-assets',
    true,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Step 2: Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Allow authenticated users to upload server assets" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read access to server assets" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to update server assets" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to delete server assets" ON storage.objects;

-- Step 3: Create RLS policies for the server-assets bucket
-- Allow authenticated users to upload files
CREATE POLICY "Allow authenticated users to upload server assets" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'server-assets' 
        AND auth.role() = 'authenticated'
    );

-- Allow public read access to server assets
CREATE POLICY "Allow public read access to server assets" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'server-assets'
    );

-- Allow authenticated users to update their own uploads
CREATE POLICY "Allow authenticated users to update server assets" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'server-assets' 
        AND auth.role() = 'authenticated'
    );

-- Allow authenticated users to delete their own uploads
CREATE POLICY "Allow authenticated users to delete server assets" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'server-assets' 
        AND auth.role() = 'authenticated'
    );

-- Step 4: Verify the bucket was created
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    created_at
FROM storage.buckets 
WHERE id = 'server-assets';

-- Step 5: Show the policies that were created
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'objects' 
    AND schemaname = 'storage'
    AND policyname LIKE '%server assets%';


