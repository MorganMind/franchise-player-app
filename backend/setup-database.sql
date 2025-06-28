-- Franchise Player App Database Setup
-- Run this in your Supabase SQL Editor

-- Create the json_uploads table
CREATE TABLE IF NOT EXISTS json_uploads (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    payload JSONB NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create an index on user_id for better query performance
CREATE INDEX IF NOT EXISTS idx_json_uploads_user_id ON json_uploads(user_id);

-- Create an index on uploaded_at for sorting
CREATE INDEX IF NOT EXISTS idx_json_uploads_uploaded_at ON json_uploads(uploaded_at);

-- Enable Row Level Security (RLS)
ALTER TABLE json_uploads ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions to authenticated users
GRANT ALL ON json_uploads TO authenticated;

-- Drop the existing trigger if it exists
DROP TRIGGER IF EXISTS set_user_id_trigger ON json_uploads;

-- Drop the existing function if it exists
DROP FUNCTION IF EXISTS set_user_id();

-- Optional: Create a view for easier querying
CREATE OR REPLACE VIEW user_uploads AS
SELECT 
    id,
    user_id,
    payload,
    uploaded_at,
    created_at
FROM json_uploads
WHERE auth.uid() = user_id;

-- Grant access to the view
GRANT SELECT ON user_uploads TO authenticated;

-- Show the created table structure
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
FROM information_schema.columns 
WHERE table_name = 'json_uploads' 
ORDER BY ordinal_position; 