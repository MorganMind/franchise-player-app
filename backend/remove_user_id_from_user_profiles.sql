-- Remove user_id column from user_profiles and clean up policies

-- 1. Remove the user_id column
ALTER TABLE user_profiles DROP COLUMN IF EXISTS user_id;

-- 2. Drop all SELECT policies except the open one
DROP POLICY IF EXISTS "Allow users to read their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can search by username" ON user_profiles;
DROP POLICY IF EXISTS "Users can select their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can view profiles of DM participants" ON user_profiles;
DROP POLICY IF EXISTS "Users can view profiles of server members" ON user_profiles;

-- 3. Ensure the open SELECT policy exists
DROP POLICY IF EXISTS "Select all user profiles" ON user_profiles;
CREATE POLICY "Select all user profiles"
  ON user_profiles
  FOR SELECT
  USING (true);

-- 4. Enable RLS (if not already enabled)
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY; 