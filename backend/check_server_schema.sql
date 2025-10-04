-- Check current server table schema
-- Run this script in your Supabase SQL editor

-- Show all columns in the servers table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'servers' 
ORDER BY ordinal_position;

-- Show current servers with all columns
SELECT 
    id,
    name,
    description,
    server_type,
    visibility,
    icon,
    icon_url,
    color,
    owner_id,
    created_at
FROM servers
ORDER BY created_at DESC
LIMIT 5;

-- Check if RLS is enabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'servers';

-- Check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'servers';
