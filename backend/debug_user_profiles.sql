-- Debug script to check user_profiles table and related issues
-- Run this in Supabase SQL Editor

-- 1. Check if user_profiles table exists and its structure
SELECT '=== USER_PROFILES TABLE STRUCTURE ===' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check if the table has any data
SELECT '=== USER_PROFILES DATA ===' as info;
SELECT COUNT(*) as total_profiles FROM public.user_profiles;

-- 3. Check RLS policies
SELECT '=== RLS POLICIES ===' as info;
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'user_profiles';

-- 4. Check if trigger exists
SELECT '=== TRIGGER CHECK ===' as info;
SELECT 
    trigger_name,
    event_manipulation,
    action_statement,
    action_timing
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- 5. Check if handle_new_user function exists
SELECT '=== FUNCTION CHECK ===' as info;
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines
WHERE routine_name = 'handle_new_user'
AND routine_schema = 'public';

-- 6. Check auth.users table structure
SELECT '=== AUTH.USERS STRUCTURE ===' as info;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'auth'
ORDER BY ordinal_position;

-- 7. Check if there are any recent auth.users entries
SELECT '=== RECENT AUTH USERS ===' as info;
SELECT 
    id,
    email,
    created_at,
    raw_user_meta_data
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 8. Check for any foreign key constraints
SELECT '=== FOREIGN KEY CONSTRAINTS ===' as info;
SELECT 
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
AND tc.table_name = 'user_profiles';

-- 9. Check table permissions
SELECT '=== TABLE PERMISSIONS ===' as info;
SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.role_table_grants
WHERE table_name = 'user_profiles'
AND table_schema = 'public';
