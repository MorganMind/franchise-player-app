-- Debug server creation and icon_url issues
-- Run this in your Supabase SQL Editor

-- Check the most recent server creation
SELECT 
    'Recent Server Creation' as check_type,
    id,
    name,
    icon_url,
    created_at,
    owner_id
FROM servers
ORDER BY created_at DESC
LIMIT 5;

-- Check if there are any servers with icon_url values
SELECT 
    'Servers with Icon URLs' as check_type,
    id,
    name,
    icon_url,
    created_at
FROM servers
WHERE icon_url IS NOT NULL
ORDER BY created_at DESC;

-- Check the exact structure of the servers table
SELECT 
    'Table Structure' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'servers' 
    AND column_name IN ('icon_url', 'icon', 'name', 'created_at')
ORDER BY ordinal_position;

-- Check RLS policies on servers table
SELECT 
    'RLS Policies' as check_type,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'servers'
ORDER BY policyname;

-- Check if there are any recent storage uploads that might match servers
SELECT 
    'Recent Storage Activity' as check_type,
    name as file_name,
    created_at as file_created,
    'https://your-project.supabase.co/storage/v1/object/public/server-assets/' || name as public_url
FROM storage.objects 
WHERE bucket_id = 'server-assets'
    AND created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;


