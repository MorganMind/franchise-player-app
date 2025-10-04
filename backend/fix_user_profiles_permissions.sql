-- Fix user_profiles permissions for Supabase Auth
-- The issue is that authenticated users don't have INSERT permissions

-- Grant proper permissions to authenticated users
GRANT ALL ON public.user_profiles TO authenticated;
GRANT ALL ON public.user_profiles TO anon;

-- Make sure the trigger function has SECURITY DEFINER
-- This allows it to run with elevated privileges
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, username, display_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure the trigger exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO anon;

-- Verify the fix
SELECT '=== PERMISSIONS AFTER FIX ===' as info;
SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.role_table_grants
WHERE table_name = 'user_profiles'
AND table_schema = 'public'
AND grantee IN ('authenticated', 'anon')
ORDER BY grantee, privilege_type;

SELECT '=== TRIGGER STATUS ===' as info;
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

SELECT '=== FUNCTION STATUS ===' as info;
SELECT 
    routine_name,
    routine_type,
    security_type
FROM information_schema.routines
WHERE routine_name = 'handle_new_user'
AND routine_schema = 'public';


