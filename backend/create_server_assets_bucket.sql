-- Create server-assets storage bucket for server icons
-- Run this script in your Supabase SQL editor

-- Insert the storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'server-assets',
    'server-assets',
    true,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Create RLS policies for the server-assets bucket
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

-- Verify the bucket was created
SELECT * FROM storage.buckets WHERE id = 'server-assets';
