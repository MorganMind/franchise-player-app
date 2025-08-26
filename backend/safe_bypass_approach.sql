-- Safe bypass approach: Keep existing data, just add the function
-- This approach preserves existing user_profiles data

-- 1. Drop the problematic trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 2. Ensure user_profiles table has the right structure (without dropping)
-- Add missing columns if they don't exist
DO $$ 
BEGIN
    -- Add email column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'email' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.user_profiles ADD COLUMN email TEXT;
    END IF;

    -- Add username column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'username' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.user_profiles ADD COLUMN username TEXT;
    END IF;

    -- Add display_name column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'display_name' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.user_profiles ADD COLUMN display_name TEXT;
    END IF;

    -- Add avatar_url column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'avatar_url' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.user_profiles ADD COLUMN avatar_url TEXT;
    END IF;

    -- Add created_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'created_at' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.user_profiles ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;

    -- Add updated_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'updated_at' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.user_profiles ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- 3. Enable RLS if not already enabled
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- 4. Drop existing policies and recreate them
DROP POLICY IF EXISTS "Users can view their own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.user_profiles;

-- 5. Create RLS policies
CREATE POLICY "Users can view their own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid()::text = id::text);

CREATE POLICY "Users can update their own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid()::text = id::text);

CREATE POLICY "Users can insert their own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid()::text = id::text);

-- 6. Grant permissions
GRANT ALL ON public.user_profiles TO authenticated;
GRANT ALL ON public.user_profiles TO anon;

-- 7. Create indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_username ON public.user_profiles(username);

-- 8. Create a function to manually create user profile
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

-- 9. Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.create_user_profile(UUID, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_user_profile(UUID, TEXT, TEXT, TEXT) TO anon;

-- 10. Show final structure
SELECT '=== FINAL SETUP ===' as info;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT '=== EXISTING PROFILES COUNT ===' as info;
SELECT COUNT(*) as total_profiles FROM public.user_profiles;

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
