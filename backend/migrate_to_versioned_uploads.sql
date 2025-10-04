-- Migration script to set up versioned uploads and migrate existing data
-- Run this in your Supabase SQL Editor

-- Step 1: Create the new versioned_uploads table
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

-- Step 2: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_versioned_uploads_user_id ON versioned_uploads(user_id);
CREATE INDEX IF NOT EXISTS idx_versioned_uploads_franchise_id ON versioned_uploads(franchise_id);
CREATE INDEX IF NOT EXISTS idx_versioned_uploads_type ON versioned_uploads(upload_type);
CREATE INDEX IF NOT EXISTS idx_versioned_uploads_status ON versioned_uploads(version_status);
CREATE INDEX IF NOT EXISTS idx_versioned_uploads_uploaded_at ON versioned_uploads(uploaded_at);
CREATE INDEX IF NOT EXISTS idx_versioned_uploads_live_versions ON versioned_uploads(franchise_id, upload_type, version_status) WHERE version_status = 'live';

-- Step 3: Enable Row Level Security (RLS)
ALTER TABLE versioned_uploads ENABLE ROW LEVEL SECURITY;

-- Step 4: Grant necessary permissions
GRANT ALL ON versioned_uploads TO authenticated;
GRANT SELECT ON versioned_uploads TO anon; -- Allow public read access for live versions

-- Step 5: Create RLS Policies
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

-- Step 6: Create function to handle versioning
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

-- Step 7: Create trigger to automatically handle versioning
DROP TRIGGER IF EXISTS trigger_handle_upload_versioning ON versioned_uploads;
CREATE TRIGGER trigger_handle_upload_versioning
    BEFORE INSERT ON versioned_uploads
    FOR EACH ROW
    EXECUTE FUNCTION handle_upload_versioning();

-- Step 8: Create views
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

-- Step 9: Migrate existing data from json_uploads to versioned_uploads
-- This will create live versions for all existing uploads
INSERT INTO versioned_uploads (user_id, franchise_id, upload_type, version_status, payload, uploaded_at, created_at)
SELECT 
    user_id,
    'franchise-660e8400-e29b-41d4-a716-446655440002' as franchise_id, -- Use the franchise ID from your existing data
    'roster' as upload_type,
    'live' as version_status,
    payload,
    uploaded_at,
    created_at
FROM json_uploads
WHERE NOT EXISTS (
    SELECT 1 FROM versioned_uploads vu 
    WHERE vu.user_id = json_uploads.user_id 
    AND vu.franchise_id = 'franchise-660e8400-e29b-41d4-a716-446655440002'
    AND vu.upload_type = 'roster'
    AND vu.version_status = 'live'
);

-- Step 10: Verify the migration
SELECT 
    'versioned_uploads' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN version_status = 'live' THEN 1 END) as live_records,
    COUNT(CASE WHEN version_status = 'rollback' THEN 1 END) as rollback_records
FROM versioned_uploads
UNION ALL
SELECT 
    'json_uploads' as table_name,
    COUNT(*) as total_records,
    NULL as live_records,
    NULL as rollback_records
FROM json_uploads;

-- Step 11: Show the migrated data
SELECT 
    id,
    user_id,
    franchise_id,
    upload_type,
    version_status,
    jsonb_array_length(payload) as player_count,
    uploaded_at
FROM versioned_uploads
ORDER BY uploaded_at DESC;
