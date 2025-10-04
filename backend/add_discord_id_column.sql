-- Add Discord ID support to user_profiles table
-- This migration adds a discord_id column and updates the trigger function to capture Discord user IDs

-- 1. Add discord_id column to user_profiles table
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS discord_id TEXT;

-- 2. Create index for discord_id for better performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_discord_id ON public.user_profiles(discord_id);

-- 3. Update the trigger function to capture Discord ID
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, username, display_name, avatar_url, discord_id)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        NEW.raw_user_meta_data->>'avatar_url',
        -- Extract Discord ID from identities if available
        CASE 
            WHEN NEW.raw_user_meta_data->>'provider' = 'discord' THEN NEW.raw_user_meta_data->>'sub'
            WHEN NEW.identities IS NOT NULL THEN (
                SELECT identity_data->>'sub' 
                FROM jsonb_array_elements(NEW.identities) AS identity_data 
                WHERE identity_data->>'provider' = 'discord' 
                LIMIT 1
            )
            ELSE NULL
        END
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Update existing user profiles with Discord IDs if they exist
-- This will update users who signed up with Discord but don't have discord_id set
UPDATE public.user_profiles 
SET discord_id = (
    SELECT identity_data->>'sub' 
    FROM auth.users au
    CROSS JOIN LATERAL jsonb_array_elements(au.identities) AS identity_data 
    WHERE au.id = user_profiles.id 
    AND identity_data->>'provider' = 'discord'
    LIMIT 1
)
WHERE discord_id IS NULL 
AND id IN (
    SELECT au.id 
    FROM auth.users au
    WHERE au.identities IS NOT NULL
    AND EXISTS (
        SELECT 1 
        FROM jsonb_array_elements(au.identities) AS identity_data 
        WHERE identity_data->>'provider' = 'discord'
    )
);

-- 5. Add a comment to document the discord_id column
COMMENT ON COLUMN public.user_profiles.discord_id IS 'Discord user ID for users who signed up with Discord OAuth';


