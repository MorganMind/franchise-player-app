-- Delete specific servers by UUID
-- Run this script in your Supabase SQL editor

-- Delete server members first (due to foreign key constraints)
DELETE FROM server_members 
WHERE server_id IN (
    '7e2f2c44-ea7e-4694-9f0b-2130aabcee3a',
    '0fac53c1-565c-4037-a884-6fd6e6565763'
);

-- Delete channels associated with these servers
DELETE FROM channels 
WHERE server_id IN (
    '7e2f2c44-ea7e-4694-9f0b-2130aabcee3a',
    '0fac53c1-565c-4037-a884-6fd6e6565763'
);

-- Delete the servers
DELETE FROM servers 
WHERE id IN (
    '7e2f2c44-ea7e-4694-9f0b-2130aabcee3a',
    '0fac53c1-565c-4037-a884-6fd6e6565763'
);

-- Verify the servers have been deleted
SELECT 
    id,
    name,
    description,
    server_type,
    visibility,
    created_at
FROM servers 
WHERE id IN (
    '7e2f2c44-ea7e-4694-9f0b-2130aabcee3a',
    '0fac53c1-565c-4037-a884-6fd6e6565763'
);

-- Show remaining servers
SELECT 
    id,
    name,
    description,
    server_type,
    visibility,
    created_at
FROM servers 
ORDER BY created_at;
