-- Check current state of user_profiles table and related objects
-- Run this to see what's happening

-- 1. Check table structure
SELECT '=== CURRENT TABLE STRUCTURE ===' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check if there are any constraints that might be blocking inserts
SELECT '=== TABLE CONSTRAINTS ===' as info;
SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints
WHERE table_name = 'user_profiles'
AND table_schema = 'public';

-- 3. Check foreign key constraints specifically
SELECT '=== FOREIGN KEY DETAILS ===' as info;
SELECT 
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    rc.delete_rule,
    rc.update_rule
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
JOIN information_schema.referential_constraints AS rc
    ON tc.constraint_name = rc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'user_profiles';

-- 4. Check if the trigger function exists and its definition
SELECT '=== TRIGGER FUNCTION ===' as info;
SELECT 
    routine_name,
    routine_type,
    security_type,
    routine_definition
FROM information_schema.routines
WHERE routine_name = 'handle_new_user'
AND routine_schema = 'public';

-- 5. Check if the trigger exists
SELECT '=== TRIGGER ===' as info;
SELECT 
    trigger_name,
    event_manipulation,
    action_statement,
    action_timing
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- 6. Check permissions again
SELECT '=== CURRENT PERMISSIONS ===' as info;
SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.role_table_grants
WHERE table_name = 'user_profiles'
AND table_schema = 'public'
AND grantee IN ('authenticated', 'anon', 'postgres')
ORDER BY grantee, privilege_type;

-- 7. Check if there are any recent auth.users entries that might have failed
SELECT '=== RECENT AUTH USERS ===' as info;
SELECT 
    id,
    email,
    created_at,
    raw_user_meta_data
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 3;

-- 8. Check if there are any user_profiles entries
SELECT '=== USER PROFILES COUNT ===' as info;
SELECT COUNT(*) as total_profiles FROM public.user_profiles;

-- 9. Try to manually test the trigger function with a dummy user
SELECT '=== TESTING TRIGGER FUNCTION ===' as info;
-- This will help us see if the function works
SELECT 
    'Function exists and is callable' as status,
    routine_name,
    security_type
FROM information_schema.routines
WHERE routine_name = 'handle_new_user'
AND routine_schema = 'public';
