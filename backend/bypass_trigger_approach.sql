-- Alternative approach: Remove trigger dependency and handle in app code
-- This approach is more reliable and easier to debug

-- 1. Drop the trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 2. Ensure user_profiles table exists with correct structure
DROP TABLE IF EXISTS public.user_profiles CASCADE;

CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY,
    email TEXT,
    username TEXT,
    display_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS policies
CREATE POLICY "Users can view their own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid()::text = id::text);

CREATE POLICY "Users can update their own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid()::text = id::text);

CREATE POLICY "Users can insert their own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid()::text = id::text);

-- 5. Grant permissions
GRANT ALL ON public.user_profiles TO authenticated;
GRANT ALL ON public.user_profiles TO anon;

-- 6. Create indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_username ON public.user_profiles(username);

-- 7. Create a function to manually create user profile
CREATE OR REPLACE FUNCTION public.create_user_profile(
    user_id UUID,
    user_email TEXT DEFAULT NULL,
    user_username TEXT DEFAULT NULL,
    user_display_name TEXT DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, username, display_name)
    VALUES (
        user_id,
        user_email,
        COALESCE(user_username, split_part(user_email, '@', 1)),
        COALESCE(user_display_name, split_part(user_email, '@', 1))
    )
    ON CONFLICT (id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.create_user_profile(UUID, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_user_profile(UUID, TEXT, TEXT, TEXT) TO anon;

-- 9. Show final structure
SELECT '=== FINAL SETUP ===' as info;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT '=== POLICIES ===' as info;
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'user_profiles';

SELECT '=== FUNCTION ===' as info;
SELECT 
    routine_name,
    routine_type,
    security_type
FROM information_schema.routines
WHERE routine_name = 'create_user_profile'
AND routine_schema = 'public';


