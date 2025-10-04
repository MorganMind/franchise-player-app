-- Check if franchise tables exist and show their structure
-- Run this script in your Supabase SQL editor

-- Check if franchises table exists
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'franchises' 
ORDER BY ordinal_position;

-- Check if franchise_channels table exists
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'franchise_channels' 
ORDER BY ordinal_position;

-- Show current franchises (if any)
SELECT 
    id,
    server_id,
    name,
    external_id,
    created_at,
    updated_at
FROM franchises
ORDER BY created_at;

-- Show current franchise channels (if any)
SELECT 
    id,
    franchise_id,
    name,
    type,
    position,
    created_at,
    updated_at
FROM franchise_channels
ORDER BY franchise_id, position;
