-- Test icon_url fix
-- Run this in your Supabase SQL Editor

-- Check the most recent server (should be Trainquill)
SELECT 
    'Latest Server' as check_type,
    id,
    name,
    icon_url,
    created_at
FROM servers
WHERE name = 'Trainquill'
ORDER BY created_at DESC
LIMIT 1;

-- Check if the icon_url is accessible via the server_members join
SELECT 
    'Server Members Join Test' as check_type,
    sm.server_id,
    s.name,
    s.icon_url,
    s.created_at
FROM server_members sm
JOIN servers s ON sm.server_id = s.id
WHERE s.name = 'Trainquill'
ORDER BY s.created_at DESC
LIMIT 1;

-- Show all servers with their icon_url values
SELECT 
    'All Servers with Icon URLs' as check_type,
    id,
    name,
    icon_url,
    created_at
FROM servers
ORDER BY created_at DESC;


