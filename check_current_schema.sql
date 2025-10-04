-- Check current database schema
-- Run this in your Supabase SQL Editor

-- Check if versioned_uploads table exists
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'versioned_uploads'
) as versioned_uploads_exists;

-- Check if json_uploads table exists
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'json_uploads'
) as json_uploads_exists;

-- List all tables in the database
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%upload%'
ORDER BY table_name;

-- Check the structure of json_uploads if it exists
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'json_uploads'
ORDER BY ordinal_position;
