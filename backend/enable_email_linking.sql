-- Enable email linking in Supabase Auth
-- This allows users to sign in with Discord even if they have an existing account with the same email

-- Note: Email linking is configured in the Supabase Dashboard
-- Go to Authentication > Settings > Auth Providers
-- Enable "Enable email confirmations" and "Enable email change confirmations"
-- Also ensure "Enable sign up" is enabled for Discord

-- Update the create_user_profile function to handle existing users
CREATE OR REPLACE FUNCTION public.create_user_profile(
    user_id UUID,
    user_email TEXT DEFAULT NULL,
    user_username TEXT DEFAULT NULL,
    user_display_name TEXT DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    -- Try to insert new profile
    INSERT INTO public.user_profiles (id, email, username, display_name)
    VALUES (
        user_id,
        user_email,
        COALESCE(user_username, split_part(user_email, '@', 1)),
        COALESCE(user_display_name, split_part(user_email, '@', 1))
    )
    ON CONFLICT (id) DO UPDATE SET
        -- Update email if it's different
        email = EXCLUDED.email,
        -- Update username if current one is empty or different
        username = CASE 
            WHEN user_profiles.username IS NULL OR user_profiles.username = '' 
            THEN EXCLUDED.username 
            ELSE user_profiles.username 
        END,
        -- Update display_name if current one is empty or different
        display_name = CASE 
            WHEN user_profiles.display_name IS NULL OR user_profiles.display_name = '' 
            THEN EXCLUDED.display_name 
            ELSE user_profiles.display_name 
        END,
        -- Update timestamp
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to check if email exists
CREATE OR REPLACE FUNCTION public.check_email_exists(user_email TEXT)
RETURNS TABLE(email_exists BOOLEAN, user_id UUID) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CASE WHEN up.id IS NOT NULL THEN TRUE ELSE FALSE END as email_exists,
        up.id
    FROM public.user_profiles up
    WHERE up.email = user_email
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.check_email_exists(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_email_exists(TEXT) TO anon;

-- Show updated function
SELECT '=== UPDATED FUNCTIONS ===' as info;
SELECT 
    routine_name,
    routine_type,
    security_type
FROM information_schema.routines
WHERE routine_name IN ('create_user_profile', 'check_email_exists')
AND routine_schema = 'public';
