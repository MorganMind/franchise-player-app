-- Check icon_url issue in servers table
-- Run this in your Supabase SQL Editor

-- 1. Check if icon_url column exists
SELECT 
    'Column Check' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'servers' 
    AND column_name IN ('icon', 'icon_url')
ORDER BY column_name;

-- 2. Show current servers with icon_url values
SELECT 
    'Current Servers' as check_type,
    id,
    name,
    icon,
    icon_url,
    created_at
FROM servers
ORDER BY created_at DESC;

-- 3. Check if any servers have icon_url values
SELECT 
    'Icon URL Stats' as check_type,
    COUNT(*) as total_servers,
    COUNT(icon_url) as servers_with_icon_url,
    COUNT(*) - COUNT(icon_url) as servers_without_icon_url
FROM servers;

-- 4. Check storage bucket for uploaded files
SELECT 
    'Storage Files' as check_type,
    name,
    bucket_id,
    created_at
FROM storage.objects 
WHERE bucket_id = 'server-assets'
ORDER BY created_at DESC
LIMIT 10;

-- 5. Check if storage bucket exists
SELECT 
    'Storage Bucket' as check_type,
    id,
    name,
    public,
    file_size_limit
FROM storage.buckets 
WHERE id = 'server-assets';


