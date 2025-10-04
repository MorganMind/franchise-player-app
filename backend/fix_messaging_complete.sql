-- Complete fix for messaging issues
-- Run this script in your Supabase SQL editor

-- Step 1: Fix RLS policies for messages table
DROP POLICY IF EXISTS "Select messages" ON messages;
DROP POLICY IF EXISTS "Insert messages" ON messages;
DROP POLICY IF EXISTS "Update messages" ON messages;
DROP POLICY IF EXISTS "Delete messages" ON messages;

-- Create simple, permissive policies for messages
CREATE POLICY "Select messages"
  ON messages
  FOR SELECT
  USING (true);

CREATE POLICY "Insert messages"
  ON messages
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Update messages"
  ON messages
  FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Delete messages"
  ON messages
  FOR DELETE
  USING (true);

-- Step 2: Create a function to get or create user profile
CREATE OR REPLACE FUNCTION get_or_create_user_profile(auth_user_id UUID)
RETURNS UUID AS $$
DECLARE
    profile_id UUID;
BEGIN
    -- Try to find existing profile
    SELECT id INTO profile_id
    FROM user_profiles
    WHERE id = auth_user_id;
    
    -- If profile doesn't exist, create one
    IF profile_id IS NULL THEN
        INSERT INTO user_profiles (id, username, display_name, status)
        VALUES (
            auth_user_id,
            'user_' || substr(auth_user_id::text, 1, 8),
            'User ' || substr(auth_user_id::text, 1, 8),
            'online'
        )
        RETURNING id INTO profile_id;
    END IF;
    
    RETURN profile_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Create a trigger to automatically create user profiles
CREATE OR REPLACE FUNCTION create_user_profile_on_auth()
RETURNS TRIGGER AS $$
BEGIN
    -- Create user profile when auth user is created
    INSERT INTO user_profiles (id, username, display_name, status)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'User ' || substr(NEW.id::text, 1, 8)),
        'online'
    )
    ON CONFLICT (id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger if it doesn't exist
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_user_profile_on_auth();

-- Step 4: Update existing auth users to have profiles
INSERT INTO user_profiles (id, username, display_name, status)
SELECT 
    au.id,
    COALESCE(au.raw_user_meta_data->>'username', 'user_' || substr(au.id::text, 1, 8)),
    COALESCE(au.raw_user_meta_data->>'full_name', 'User ' || substr(au.id::text, 1, 8)),
    'online'
FROM auth.users au
LEFT JOIN user_profiles up ON au.id = up.id
WHERE up.id IS NULL;

-- Step 5: Ensure RLS is enabled and permissions are granted
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
GRANT ALL ON messages TO authenticated;
GRANT ALL ON user_profiles TO authenticated;

-- Step 6: Create a function to send messages with proper user mapping
CREATE OR REPLACE FUNCTION send_message(
    p_channel_id UUID,
    p_content TEXT
)
RETURNS UUID AS $$
DECLARE
    message_id UUID;
    user_profile_id UUID;
BEGIN
    -- Get or create user profile
    user_profile_id := get_or_create_user_profile(auth.uid());
    
    -- Insert message
    INSERT INTO messages (channel_id, author_id, content)
    VALUES (p_channel_id, user_profile_id, p_content)
    RETURNING id INTO message_id;
    
    RETURN message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Display confirmation
SELECT 'Messaging system fixed successfully!' as status;

-- Show current user profiles
SELECT 
    id,
    username,
    display_name,
    status,
    created_at
FROM user_profiles
ORDER BY created_at DESC
LIMIT 10; 