-- Test the exact query the app is making
-- This simulates what the Flutter app is trying to do

-- Test 1: Direct query to versioned_uploads (fallback)
SELECT 
    'Direct versioned_uploads query' as query_type,
    COUNT(*) as record_count
FROM versioned_uploads
WHERE version_status = 'live'
AND upload_type = 'roster';

-- Test 2: Query to live_uploads view (primary)
SELECT 
    'live_uploads view query' as query_type,
    COUNT(*) as record_count
FROM live_uploads
WHERE upload_type = 'roster';

-- Test 3: Show the actual data from both queries
SELECT 
    'Direct versioned_uploads' as source,
    id,
    franchise_id,
    jsonb_array_length(payload) as player_count,
    uploaded_at
FROM versioned_uploads
WHERE version_status = 'live'
AND upload_type = 'roster'
ORDER BY uploaded_at DESC;

-- Test 4: Show data from live_uploads view
SELECT 
    'live_uploads view' as source,
    id,
    franchise_id,
    jsonb_array_length(payload) as player_count,
    uploaded_at
FROM live_uploads
WHERE upload_type = 'roster'
ORDER BY uploaded_at DESC;

-- Test 5: Check if there are any permission issues
-- This should return the same as Test 1 if permissions are working
SELECT 
    'Permission test' as test_type,
    COUNT(*) as accessible_records
FROM versioned_uploads
WHERE version_status = 'live'
AND upload_type = 'roster';
