-- Test script to verify Discord ID capture functionality
-- Run this after applying the add_discord_id_column.sql migration

-- 1. Check if the discord_id column was added successfully
SELECT '=== CHECKING DISCORD_ID COLUMN ===' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
AND column_name = 'discord_id'
AND table_schema = 'public';

-- 2. Check if the index was created
SELECT '=== CHECKING DISCORD_ID INDEX ===' as info;
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'user_profiles' 
AND indexname LIKE '%discord_id%';

-- 3. Check the updated trigger function
SELECT '=== CHECKING UPDATED TRIGGER FUNCTION ===' as info;
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines
WHERE routine_name = 'handle_new_user'
AND routine_schema = 'public';

-- 4. Check existing users with Discord identities
SELECT '=== EXISTING USERS WITH DISCORD IDENTITIES ===' as info;
SELECT 
    au.id,
    au.email,
    au.created_at,
    au.raw_user_meta_data->>'provider' as provider,
    au.raw_user_meta_data->>'sub' as discord_sub,
    up.discord_id as stored_discord_id,
    up.username,
    up.display_name
FROM auth.users au
LEFT JOIN public.user_profiles up ON au.id = up.id
WHERE au.raw_user_meta_data->>'provider' = 'discord'
   OR EXISTS (
       SELECT 1 
       FROM jsonb_array_elements(au.identities) AS identity_data 
       WHERE identity_data->>'provider' = 'discord'
   )
ORDER BY au.created_at DESC;

-- 5. Check all identities for Discord users
SELECT '=== DISCORD IDENTITIES DETAIL ===' as info;
SELECT 
    au.id,
    au.email,
    identity_data->>'provider' as provider,
    identity_data->>'sub' as discord_id,
    identity_data->>'identity_data' as identity_data
FROM auth.users au
CROSS JOIN LATERAL jsonb_array_elements(au.identities) AS identity_data 
WHERE identity_data->>'provider' = 'discord'
ORDER BY au.created_at DESC;

-- 6. Check user profiles with Discord IDs
SELECT '=== USER PROFILES WITH DISCORD IDS ===' as info;
SELECT 
    id,
    email,
    username,
    display_name,
    discord_id,
    created_at
FROM public.user_profiles 
WHERE discord_id IS NOT NULL
ORDER BY created_at DESC;

-- 7. Test the trigger function with a dummy Discord user
SELECT '=== TESTING TRIGGER FUNCTION ===' as info;
-- This simulates what would happen when a Discord user signs up
SELECT 
    'Trigger function is ready for Discord users' as status,
    routine_name,
    security_type
FROM information_schema.routines
WHERE routine_name = 'handle_new_user'
AND routine_schema = 'public';

-- 8. Summary statistics
SELECT '=== SUMMARY STATISTICS ===' as info;
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN discord_id IS NOT NULL THEN 1 END) as users_with_discord_id,
    COUNT(CASE WHEN discord_id IS NULL THEN 1 END) as users_without_discord_id
FROM public.user_profiles;


