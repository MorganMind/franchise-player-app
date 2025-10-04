-- Test queries to verify live_uploads view is working
-- Run these in your Supabase SQL Editor

-- Test 1: Check if live_uploads view exists and has data
SELECT 
    'live_uploads view' as source,
    COUNT(*) as record_count
FROM live_uploads
UNION ALL
SELECT 
    'versioned_uploads table' as source,
    COUNT(*) as record_count
FROM versioned_uploads
WHERE version_status = 'live';

-- Test 2: Check the actual data in live_uploads
SELECT 
    id,
    user_id,
    franchise_id,
    upload_type,
    jsonb_array_length(payload) as player_count,
    uploaded_at
FROM live_uploads
ORDER BY uploaded_at DESC;

-- Test 3: Check if there are any RLS issues by querying directly
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

-- Test 4: Check the view definition
SELECT 
    viewname,
    definition
FROM pg_views
WHERE viewname = 'live_uploads';

-- Test 5: Check RLS policies on versioned_uploads
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'versioned_uploads';
