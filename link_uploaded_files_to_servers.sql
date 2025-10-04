-- Link uploaded files to servers and update icon_url
-- Run this in your Supabase SQL Editor

-- Step 1: Show all uploaded files with their public URLs
SELECT 
    'Uploaded Files' as check_type,
    name as file_name,
    bucket_id,
    created_at,
    'https://your-project.supabase.co/storage/v1/object/public/' || bucket_id || '/' || name as public_url
FROM storage.objects 
WHERE bucket_id = 'server-assets'
ORDER BY created_at DESC;

-- Step 2: Show current servers with their creation times
SELECT 
    'Current Servers' as check_type,
    id,
    name,
    icon_url,
    created_at
FROM servers
ORDER BY created_at DESC;

-- Step 3: Manual update example (you'll need to replace the IDs)
-- This shows how to update a server's icon_url manually
-- Replace 'SERVER_ID_HERE' with the actual server ID
-- Replace 'FILE_NAME_HERE' with the actual file name from storage

/*
UPDATE servers 
SET icon_url = 'https://your-project.supabase.co/storage/v1/object/public/server-assets/FILE_NAME_HERE'
WHERE id = 'SERVER_ID_HERE';
*/

-- Step 4: Generate update statements for you to run manually
-- This will help you match files to servers based on creation time
SELECT 
    'Suggested Update' as check_type,
    'UPDATE servers SET icon_url = ''' || 
    'https://your-project.supabase.co/storage/v1/object/public/server-assets/' || 
    s.name || ''' WHERE id = ''' || 
    ser.id || ''';' as update_statement,
    ser.name as server_name,
    s.name as file_name,
    ser.created_at as server_created,
    s.created_at as file_created
FROM storage.objects s
CROSS JOIN servers ser
WHERE s.bucket_id = 'server-assets'
    AND s.name LIKE 'server_icons/%'
    AND ser.icon_url IS NULL
    AND ABS(EXTRACT(EPOCH FROM (ser.created_at - s.created_at))) < 300  -- Within 5 minutes
ORDER BY ser.created_at DESC, s.created_at DESC;


