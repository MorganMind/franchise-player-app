-- Check versioned upload data in Supabase
-- Run this in your Supabase SQL Editor after running create_versioned_uploads_schema.sql

-- Get all live versions (current active data)
SELECT 
    id,
    user_id,
    franchise_id,
    upload_type,
    version_status,
    jsonb_array_length(payload) as player_count,
    uploaded_at
FROM versioned_uploads 
WHERE version_status = 'live'
ORDER BY uploaded_at DESC;

-- Get all rollback versions (previous versions)
SELECT 
    id,
    user_id,
    franchise_id,
    upload_type,
    version_status,
    jsonb_array_length(payload) as player_count,
    uploaded_at
FROM versioned_uploads 
WHERE version_status = 'rollback'
ORDER BY uploaded_at DESC;

-- Get upload history for a specific user
SELECT 
    id,
    franchise_id,
    upload_type,
    version_status,
    jsonb_array_length(payload) as player_count,
    uploaded_at
FROM versioned_uploads
WHERE user_id = 'e050e2da-4b3a-4a7b-91d1-fda1be112ee2' -- Replace with your user ID
ORDER BY uploaded_at DESC;

-- Get live versions with player samples
SELECT 
    id,
    user_id,
    franchise_id,
    upload_type,
    version_status,
    jsonb_array_length(payload) as total_players,
    CONCAT(jsonb_array_elements(payload)->>'firstName', ' ', jsonb_array_elements(payload)->>'lastName') as player_name,
    jsonb_array_elements(payload)->>'position' as position,
    jsonb_array_elements(payload)->>'playerBestOvr' as overall_rating
FROM versioned_uploads 
WHERE version_status = 'live'
ORDER BY uploaded_at DESC
LIMIT 50;

-- Get summary by franchise and upload type
SELECT 
    franchise_id,
    upload_type,
    version_status,
    COUNT(*) as upload_count,
    SUM(jsonb_array_length(payload)) as total_players,
    MAX(uploaded_at) as latest_upload
FROM versioned_uploads
GROUP BY franchise_id, upload_type, version_status
ORDER BY franchise_id, upload_type, version_status;

-- Get live versions summary (what's currently active)
SELECT 
    franchise_id,
    upload_type,
    jsonb_array_length(payload) as player_count,
    uploaded_at as live_since
FROM versioned_uploads
WHERE version_status = 'live'
ORDER BY uploaded_at DESC;

-- Check if there are any rollback versions available
SELECT 
    franchise_id,
    upload_type,
    COUNT(*) as rollback_count,
    MAX(uploaded_at) as most_recent_rollback
FROM versioned_uploads
WHERE version_status = 'rollback'
GROUP BY franchise_id, upload_type
ORDER BY franchise_id, upload_type;
