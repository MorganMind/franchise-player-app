-- Create Madden X Server with Channels and User Memberships
-- Run this script in your Supabase SQL editor

-- Step 1: Create the Madden X server (if it doesn't exist)
DO $$
DECLARE
    server_exists BOOLEAN;
    madden_server_id UUID;
    first_user_id UUID;
    members_added INTEGER;
BEGIN
    -- Check if Madden X server already exists
    SELECT EXISTS(SELECT 1 FROM servers WHERE name = 'Madden X') INTO server_exists;
    
    -- Get the first user as owner (or use a default UUID if no users exist)
    SELECT id INTO first_user_id FROM user_profiles LIMIT 1;
    
    IF first_user_id IS NULL THEN
        -- If no users exist, create a default owner ID
        first_user_id := '550e8400-e29b-41d4-a716-446655440001';
    END IF;
    
    IF NOT server_exists THEN
        -- Create the Madden X server (using all available columns)
        INSERT INTO servers (id, name, description, icon, color, owner_id, created_at) 
        VALUES (
            gen_random_uuid(), 
            'Madden X', 
            'Madden Franchise Community - Join the ultimate Madden gaming experience!',
            '🏈',
            '#1E90FF',
            first_user_id,
            NOW()
        ) RETURNING id INTO madden_server_id;
        
        RAISE NOTICE 'Created Madden X server with ID: %', madden_server_id;
    ELSE
        -- Get existing server ID
        SELECT id INTO madden_server_id FROM servers WHERE name = 'Madden X';
        RAISE NOTICE 'Madden X server already exists with ID: %', madden_server_id;
        
        -- Update existing server with Madden X branding if columns exist
        UPDATE servers 
        SET 
            description = 'Madden Franchise Community - Join the ultimate Madden gaming experience!',
            icon = '🏈',
            color = '#1E90FF'
        WHERE name = 'Madden X';
    END IF;
    
    -- Step 2: Create channels for Madden X server (if they don't exist)
    IF NOT EXISTS(SELECT 1 FROM channels WHERE server_id = madden_server_id AND name = 'announcements') THEN
        INSERT INTO channels (id, server_id, name, type, created_at) 
        VALUES (gen_random_uuid(), madden_server_id, 'announcements', 'text', NOW());
        RAISE NOTICE 'Created announcements channel';
    ELSE
        RAISE NOTICE 'announcements channel already exists';
    END IF;
    
    IF NOT EXISTS(SELECT 1 FROM channels WHERE server_id = madden_server_id AND name = 'general') THEN
        INSERT INTO channels (id, server_id, name, type, created_at) 
        VALUES (gen_random_uuid(), madden_server_id, 'general', 'text', NOW());
        RAISE NOTICE 'Created general channel';
    ELSE
        RAISE NOTICE 'general channel already exists';
    END IF;
    
    -- Step 3: Add all existing users as members to the Madden X server
    -- This will add all users from user_profiles table to the server
    INSERT INTO server_members (server_id, user_id, nickname, joined_at)
    SELECT 
        madden_server_id,
        up.id,
        up.display_name,
        NOW()
    FROM user_profiles up
    WHERE NOT EXISTS (
        SELECT 1 FROM server_members sm 
        WHERE sm.server_id = madden_server_id AND sm.user_id = up.id
    );
    
    GET DIAGNOSTICS members_added = ROW_COUNT;
    RAISE NOTICE 'Added % users as members to Madden X server', members_added;
    
END $$;

-- Step 4: Display the results
SELECT 'Madden X server setup completed!' as status;

-- Show the created server
SELECT 
    s.id as server_id,
    s.name as server_name,
    s.description,
    s.icon,
    s.color,
    s.owner_id,
    s.created_at
FROM servers s 
WHERE s.name = 'Madden X';

-- Show the channels in Madden X server
SELECT 
    c.id as channel_id,
    c.name as channel_name,
    c.type,
    c.created_at
FROM channels c
JOIN servers s ON c.server_id = s.id
WHERE s.name = 'Madden X'
ORDER BY c.name;

-- Show the members of Madden X server
SELECT 
    up.username,
    up.display_name,
    up.avatar_url,
    up.status,
    sm.nickname,
    sm.joined_at
FROM server_members sm
JOIN servers s ON sm.server_id = s.id
JOIN user_profiles up ON sm.user_id = up.id
WHERE s.name = 'Madden X'
ORDER BY up.display_name;

-- Summary counts
SELECT 
    (SELECT COUNT(*) FROM servers WHERE name = 'Madden X') as madden_servers,
    (SELECT COUNT(*) FROM channels c JOIN servers s ON c.server_id = s.id WHERE s.name = 'Madden X') as madden_channels,
    (SELECT COUNT(*) FROM server_members sm JOIN servers s ON sm.server_id = s.id WHERE s.name = 'Madden X') as madden_members; 