-- Diagnose channels table issue
-- Run this script in your Supabase SQL editor to see what's wrong

-- 1. Check if channels table exists
SELECT 
    'Table exists' as status,
    EXISTS(
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'channels' 
        AND table_schema = 'public'
    ) as channels_table_exists;

-- 2. Show current schema
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'channels' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Check for any constraints
SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'channels' 
AND table_schema = 'public';

-- 4. Check for foreign keys
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'channels';

-- 5. Show sample data
SELECT 
    id,
    name,
    type,
    server_id,
    created_at
FROM channels 
LIMIT 3;

-- 6. Check if there are any RLS policies
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'channels';

-- 7. Check table permissions
SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.role_table_grants 
WHERE table_name = 'channels' 
AND table_schema = 'public'; 