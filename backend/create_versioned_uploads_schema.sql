-- Versioned Uploads Schema for Franchise Player App
-- This replaces the simple json_uploads table with a proper versioning system

-- Drop the old table if it exists (backup first!)
-- CREATE TABLE json_uploads_backup AS SELECT * FROM json_uploads;
-- DROP TABLE IF EXISTS json_uploads;

-- Create the new versioned uploads table
CREATE TABLE IF NOT EXISTS versioned_uploads (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    franchise_id TEXT NOT NULL, -- e.g., 'franchise-server-1'
    upload_type TEXT NOT NULL CHECK (upload_type IN ('roster', 'teams', 'stats', 'trades', 'awards')),
    version_status TEXT NOT NULL CHECK (version_status IN ('live', 'rollback')) DEFAULT 'live',
    payload JSONB NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure only one live version per franchise/type combination
    UNIQUE(franchise_id, upload_type, version_status)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_versioned_uploads_user_id ON versioned_uploads(user_id);
CREATE INDEX IF NOT EXISTS idx_versioned_uploads_franchise_id ON versioned_uploads(franchise_id);
CREATE INDEX IF NOT EXISTS idx_versioned_uploads_type ON versioned_uploads(upload_type);
CREATE INDEX IF NOT EXISTS idx_versioned_uploads_status ON versioned_uploads(version_status);
CREATE INDEX IF NOT EXISTS idx_versioned_uploads_uploaded_at ON versioned_uploads(uploaded_at);
CREATE INDEX IF NOT EXISTS idx_versioned_uploads_live_versions ON versioned_uploads(franchise_id, upload_type, version_status) WHERE version_status = 'live';

-- Enable Row Level Security (RLS)
ALTER TABLE versioned_uploads ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT ALL ON versioned_uploads TO authenticated;
GRANT SELECT ON versioned_uploads TO anon; -- Allow public read access for live versions

-- RLS Policies
-- Allow users to view their own uploads
CREATE POLICY "Users can view their own uploads" ON versioned_uploads
    FOR SELECT USING (auth.uid() = user_id);

-- Allow public read access to live versions
CREATE POLICY "Public can view live versions" ON versioned_uploads
    FOR SELECT USING (version_status = 'live');

-- Allow users to insert their own uploads
CREATE POLICY "Users can insert their own uploads" ON versioned_uploads
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own uploads
CREATE POLICY "Users can update their own uploads" ON versioned_uploads
    FOR UPDATE USING (auth.uid() = user_id);

-- Allow users to delete their own uploads
CREATE POLICY "Users can delete their own uploads" ON versioned_uploads
    FOR DELETE USING (auth.uid() = user_id);

-- Function to handle versioning when inserting new uploads
CREATE OR REPLACE FUNCTION handle_upload_versioning()
RETURNS TRIGGER AS $$
BEGIN
    -- If this is a new live version, move the existing live version to rollback
    IF NEW.version_status = 'live' THEN
        -- Update existing live version to rollback
        UPDATE versioned_uploads 
        SET version_status = 'rollback'
        WHERE franchise_id = NEW.franchise_id 
        AND upload_type = NEW.upload_type 
        AND version_status = 'live'
        AND user_id = NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically handle versioning
DROP TRIGGER IF EXISTS trigger_handle_upload_versioning ON versioned_uploads;
CREATE TRIGGER trigger_handle_upload_versioning
    BEFORE INSERT ON versioned_uploads
    FOR EACH ROW
    EXECUTE FUNCTION handle_upload_versioning();

-- View for easy access to live versions only
CREATE OR REPLACE VIEW live_uploads AS
SELECT 
    id,
    user_id,
    franchise_id,
    upload_type,
    payload,
    uploaded_at,
    created_at
FROM versioned_uploads
WHERE version_status = 'live'
ORDER BY uploaded_at DESC;

-- Grant access to the view
GRANT SELECT ON live_uploads TO authenticated;
GRANT SELECT ON live_uploads TO anon;

-- View for user's upload history
CREATE OR REPLACE VIEW user_upload_history AS
SELECT 
    id,
    user_id,
    franchise_id,
    upload_type,
    version_status,
    jsonb_array_length(payload) as player_count,
    uploaded_at,
    created_at
FROM versioned_uploads
WHERE auth.uid() = user_id
ORDER BY uploaded_at DESC;

-- Grant access to the view
GRANT SELECT ON user_upload_history TO authenticated;

-- Function to get rollback version for a franchise/type
CREATE OR REPLACE FUNCTION get_rollback_version(p_franchise_id TEXT, p_upload_type TEXT)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    franchise_id TEXT,
    upload_type TEXT,
    payload JSONB,
    uploaded_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        vu.id,
        vu.user_id,
        vu.franchise_id,
        vu.upload_type,
        vu.payload,
        vu.uploaded_at
    FROM versioned_uploads vu
    WHERE vu.franchise_id = p_franchise_id
    AND vu.upload_type = p_upload_type
    AND vu.version_status = 'rollback'
    AND vu.user_id = auth.uid()
    ORDER BY vu.uploaded_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_rollback_version(TEXT, TEXT) TO authenticated;

-- Show the created table structure
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
FROM information_schema.columns 
WHERE table_name = 'versioned_uploads' 
ORDER BY ordinal_position;
