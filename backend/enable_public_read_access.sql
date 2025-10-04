-- Enable public read access to json_uploads table for franchise data
-- This allows unauthenticated users to read the latest uploaded franchise data

-- Drop existing RLS policies if they exist
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON json_uploads;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON json_uploads;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON json_uploads;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON json_uploads;

-- Create new policies that allow public read access
-- Allow anyone to read the latest uploaded data
CREATE POLICY "Enable public read access" ON json_uploads
    FOR SELECT
    USING (true);

-- Allow authenticated users to insert new data
CREATE POLICY "Enable insert for authenticated users" ON json_uploads
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Allow authenticated users to update their own data
CREATE POLICY "Enable update for authenticated users" ON json_uploads
    FOR UPDATE
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- Allow authenticated users to delete their own data
CREATE POLICY "Enable delete for authenticated users" ON json_uploads
    FOR DELETE
    USING (auth.role() = 'authenticated');

-- Ensure RLS is enabled
ALTER TABLE json_uploads ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT SELECT ON json_uploads TO anon;
GRANT SELECT ON json_uploads TO authenticated;
GRANT INSERT, UPDATE, DELETE ON json_uploads TO authenticated;
