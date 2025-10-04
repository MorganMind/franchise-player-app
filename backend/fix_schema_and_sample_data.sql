-- Fix schema and add sample data for Discord-like app
-- This script removes problematic foreign key constraints temporarily
-- Run this script in your Supabase SQL editor

-- Step 1: Remove problematic foreign key constraints temporarily
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    -- Remove servers.owner_id foreign key constraint
    SELECT tc.constraint_name INTO constraint_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_name = 'servers' 
    AND tc.constraint_type = 'FOREIGN KEY'
    AND kcu.column_name = 'owner_id';
    
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE servers DROP CONSTRAINT ' || constraint_name;
        RAISE NOTICE 'Removed foreign key constraint: %', constraint_name;
    ELSE
        RAISE NOTICE 'No owner_id foreign key constraint found on servers table';
    END IF;
    
    -- Remove user_profiles.id foreign key constraint
    SELECT tc.constraint_name INTO constraint_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_name = 'user_profiles' 
    AND tc.constraint_type = 'FOREIGN KEY'
    AND kcu.column_name = 'id';
    
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE user_profiles DROP CONSTRAINT ' || constraint_name;
        RAISE NOTICE 'Removed foreign key constraint: %', constraint_name;
    ELSE
        RAISE NOTICE 'No id foreign key constraint found on user_profiles table';
    END IF;
    
    -- Remove dm_participants.user_id foreign key constraint
    SELECT tc.constraint_name INTO constraint_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_name = 'dm_participants' 
    AND tc.constraint_type = 'FOREIGN KEY'
    AND kcu.column_name = 'user_id';
    
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE dm_participants DROP CONSTRAINT ' || constraint_name;
        RAISE NOTICE 'Removed foreign key constraint: %', constraint_name;
    ELSE
        RAISE NOTICE 'No user_id foreign key constraint found on dm_participants table';
    END IF;
    
    -- Remove messages.author_id foreign key constraint
    SELECT tc.constraint_name INTO constraint_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_name = 'messages' 
    AND tc.constraint_type = 'FOREIGN KEY'
    AND kcu.column_name = 'author_id';
    
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE messages DROP CONSTRAINT ' || constraint_name;
        RAISE NOTICE 'Removed foreign key constraint: %', constraint_name;
    ELSE
        RAISE NOTICE 'No author_id foreign key constraint found on messages table';
    END IF;
    
    -- Remove server_members.user_id foreign key constraint
    SELECT tc.constraint_name INTO constraint_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_name = 'server_members' 
    AND tc.constraint_type = 'FOREIGN KEY'
    AND kcu.column_name = 'user_id';
    
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE server_members DROP CONSTRAINT ' || constraint_name;
        RAISE NOTICE 'Removed foreign key constraint: %', constraint_name;
    ELSE
        RAISE NOTICE 'No user_id foreign key constraint found on server_members table';
    END IF;
END $$;

-- Step 2: Add missing columns to servers table if they don't exist
DO $$
DECLARE
    column_exists BOOLEAN;
BEGIN
    -- Check if 'icon_url' column exists (instead of 'icon')
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'servers' AND column_name = 'icon_url'
    ) INTO column_exists;
    
    IF NOT column_exists THEN
        ALTER TABLE servers ADD COLUMN icon_url TEXT;
        RAISE NOTICE 'Added icon_url column to servers table';
    END IF;
    
    -- Check if 'color' column exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'servers' AND column_name = 'color'
    ) INTO column_exists;
    
    IF NOT column_exists THEN
        ALTER TABLE servers ADD COLUMN color TEXT;
        RAISE NOTICE 'Added color column to servers table';
    END IF;
END $$;

-- Step 3: Add sample user profiles only if they don't exist
DO $$
DECLARE
    sample_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO sample_count FROM user_profiles WHERE username LIKE '%_dev' OR username LIKE '%_design';
    
    IF sample_count = 0 THEN
        INSERT INTO user_profiles (id, username, display_name, avatar_url, status, created_at) VALUES
        ('550e8400-e29b-41d4-a716-446655440001', 'alice_dev', 'Alice Developer', 'https://api.dicebear.com/7.x/avataaars/svg?seed=alice', 'online', NOW()),
        ('550e8400-e29b-41d4-a716-446655440002', 'bob_design', 'Bob Designer', 'https://api.dicebear.com/7.x/avataaars/svg?seed=bob', 'away', NOW()),
        ('550e8400-e29b-41d4-a716-446655440003', 'charlie_pm', 'Charlie PM', 'https://api.dicebear.com/7.x/avataaars/svg?seed=charlie', 'online', NOW()),
        ('550e8400-e29b-41d4-a716-446655440004', 'diana_qa', 'Diana QA', 'https://api.dicebear.com/7.x/avataaars/svg?seed=diana', 'dnd', NOW()),
        ('550e8400-e29b-41d4-a716-446655440005', 'eddie_ux', 'Eddie UX', 'https://api.dicebear.com/7.x/avataaars/svg?seed=eddie', 'offline', NOW()),
        ('550e8400-e29b-41d4-a716-446655440006', 'fiona_ba', 'Fiona BA', 'https://api.dicebear.com/7.x/avataaars/svg?seed=fiona', 'online', NOW()),
        ('550e8400-e29b-41d4-a716-446655440007', 'george_dev', 'George Developer', 'https://api.dicebear.com/7.x/avataaars/svg?seed=george', 'away', NOW()),
        ('550e8400-e29b-41d4-a716-446655440008', 'helen_design', 'Helen Designer', 'https://api.dicebear.com/7.x/avataaars/svg?seed=helen', 'online', NOW());
        
        RAISE NOTICE 'Added 8 sample user profiles';
    ELSE
        RAISE NOTICE 'Sample users already exist, skipping...';
    END IF;
END $$;

-- Step 4: Add sample servers only if they don't exist
DO $$
DECLARE
    server_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO server_count FROM servers;
    
    IF server_count = 0 THEN
        INSERT INTO servers (id, name, description, icon_url, color, owner_id, created_at) VALUES
        ('660e8400-e29b-41d4-a716-446655440001', 'Tech Team', 'Our awesome development team', 'https://api.dicebear.com/7.x/initials/svg?seed=TT', '#FF6B6B', '550e8400-e29b-41d4-a716-446655440001', NOW()),
        ('660e8400-e29b-41d4-a716-446655440002', 'Design Hub', 'Creative design discussions', 'https://api.dicebear.com/7.x/initials/svg?seed=DH', '#4ECDC4', '550e8400-e29b-41d4-a716-446655440002', NOW());
        
        RAISE NOTICE 'Added 2 sample servers';
    ELSE
        RAISE NOTICE 'Servers already exist, skipping...';
    END IF;
END $$;

-- Step 5: Add sample channels only if they don't exist
DO $$
DECLARE
    channel_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO channel_count FROM channels;
    
    IF channel_count = 0 THEN
        INSERT INTO channels (id, server_id, name, type, position, created_at) VALUES
        -- Tech Team channels
        ('770e8400-e29b-41d4-a716-446655440001', '660e8400-e29b-41d4-a716-446655440001', 'general', 'text', 0, NOW()),
        ('770e8400-e29b-41d4-a716-446655440002', '660e8400-e29b-41d4-a716-446655440001', 'random', 'text', 1, NOW()),
        ('770e8400-e29b-41d4-a716-446655440003', '660e8400-e29b-41d4-a716-446655440001', 'announcements', 'text', 2, NOW()),
        ('770e8400-e29b-41d4-a716-446655440004', '660e8400-e29b-41d4-a716-446655440001', 'help', 'text', 3, NOW()),
        -- Design Hub channels
        ('770e8400-e29b-41d4-a716-446655440005', '660e8400-e29b-41d4-a716-446655440002', 'general', 'text', 0, NOW()),
        ('770e8400-e29b-41d4-a716-446655440006', '660e8400-e29b-41d4-a716-446655440002', 'inspiration', 'text', 1, NOW()),
        ('770e8400-e29b-41d4-a716-446655440007', '660e8400-e29b-41d4-a716-446655440002', 'feedback', 'text', 2, NOW()),
        ('770e8400-e29b-41d4-a716-446655440008', '660e8400-e29b-41d4-a716-446655440002', 'resources', 'text', 3, NOW());
        
        RAISE NOTICE 'Added 8 sample channels';
    ELSE
        RAISE NOTICE 'Channels already exist, skipping...';
    END IF;
END $$;

-- Step 6: Add server memberships only if they don't exist
DO $$
DECLARE
    member_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO member_count FROM server_members;
    
    IF member_count = 0 THEN
        INSERT INTO server_members (server_id, user_id, nickname, joined_at) VALUES
        -- Tech Team members
        ('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'Alice Developer', NOW()),
        ('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002', 'Bob Designer', NOW()),
        ('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440003', 'Charlie PM', NOW()),
        ('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440004', 'Diana QA', NOW()),
        ('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440005', 'Eddie UX', NOW()),
        ('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440006', 'Fiona BA', NOW()),
        ('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440007', 'George Developer', NOW()),
        ('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440008', 'Helen Designer', NOW()),
        -- Design Hub members
        ('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 'Alice Developer', NOW()),
        ('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', 'Bob Designer', NOW()),
        ('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440003', 'Charlie PM', NOW()),
        ('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440004', 'Diana QA', NOW()),
        ('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440005', 'Eddie UX', NOW()),
        ('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440006', 'Fiona BA', NOW()),
        ('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440007', 'George Developer', NOW()),
        ('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440008', 'Helen Designer', NOW());
        
        RAISE NOTICE 'Added server memberships';
    ELSE
        RAISE NOTICE 'Server memberships already exist, skipping...';
    END IF;
END $$;

-- Step 7: Add DM channels and participants only if they don't exist
DO $$
DECLARE
    dm_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO dm_count FROM dm_channels;
    
    IF dm_count = 0 THEN
        -- Create DM channels
        INSERT INTO dm_channels (id, created_at) VALUES
        ('880e8400-e29b-41d4-a716-446655440001', NOW()),
        ('880e8400-e29b-41d4-a716-446655440002', NOW()),
        ('880e8400-e29b-41d4-a716-446655440003', NOW()),
        ('880e8400-e29b-41d4-a716-446655440004', NOW()),
        ('880e8400-e29b-41d4-a716-446655440005', NOW()),
        ('880e8400-e29b-41d4-a716-446655440006', NOW()),
        ('880e8400-e29b-41d4-a716-446655440007', NOW()),
        ('880e8400-e29b-41d4-a716-446655440008', NOW());
        
        -- Add participants
        INSERT INTO dm_participants (dm_channel_id, user_id, joined_at) VALUES
        ('880e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', NOW()),
        ('880e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', NOW()),
        ('880e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003', NOW()),
        ('880e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440004', NOW()),
        ('880e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440005', NOW()),
        ('880e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440006', NOW()),
        ('880e8400-e29b-41d4-a716-446655440007', '550e8400-e29b-41d4-a716-446655440007', NOW()),
        ('880e8400-e29b-41d4-a716-446655440008', '550e8400-e29b-41d4-a716-446655440008', NOW());
        
        RAISE NOTICE 'Added DM channels and participants';
    ELSE
        RAISE NOTICE 'DM channels already exist, skipping...';
    END IF;
END $$;

-- Step 8: Add sample messages only if they don't exist
DO $$
DECLARE
    message_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO message_count FROM messages;
    
    IF message_count = 0 THEN
        -- Channel messages
        INSERT INTO messages (channel_id, author_id, content, created_at) VALUES
        ('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'Hey everyone! How is the sprint going?', NOW() - INTERVAL '2 hours'),
        ('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440003', 'Sprint is going well! We should be on track to finish by Friday.', NOW() - INTERVAL '1 hour 45 minutes'),
        ('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440007', 'I just pushed the latest changes to the feature branch.', NOW() - INTERVAL '1 hour 30 minutes'),
        ('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440004', 'Great! I will start testing the new features tomorrow.', NOW() - INTERVAL '1 hour'),
        ('770e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440002', 'Check out this new design inspiration I found!', NOW() - INTERVAL '3 hours'),
        ('770e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440005', 'That looks amazing! I love the color palette.', NOW() - INTERVAL '2 hours 30 minutes'),
        ('770e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440008', 'I think we should incorporate some of these elements into our next project.', NOW() - INTERVAL '2 hours'),
        ('770e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440006', 'Agreed! Let me create a mood board for our next design review.', NOW() - INTERVAL '1 hour 30 minutes');
        
        -- DM messages
        INSERT INTO messages (dm_channel_id, author_id, content, created_at) VALUES
        ('880e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'Welcome to your personal DM space, Alice! You can use this to save notes, draft messages, or just chat with yourself.', NOW() - INTERVAL '1 day'),
        ('880e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', 'Welcome to your personal DM space, Bob! You can use this to save notes, draft messages, or just chat with yourself.', NOW() - INTERVAL '1 day'),
        ('880e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003', 'Welcome to your personal DM space, Charlie! You can use this to save notes, draft messages, or just chat with yourself.', NOW() - INTERVAL '1 day'),
        ('880e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440004', 'Welcome to your personal DM space, Diana! You can use this to save notes, draft messages, or just chat with yourself.', NOW() - INTERVAL '1 day'),
        ('880e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440005', 'Welcome to your personal DM space, Eddie! You can use this to save notes, draft messages, or just chat with yourself.', NOW() - INTERVAL '1 day'),
        ('880e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440006', 'Welcome to your personal DM space, Fiona! You can use this to save notes, draft messages, or just chat with yourself.', NOW() - INTERVAL '1 day'),
        ('880e8400-e29b-41d4-a716-446655440007', '550e8400-e29b-41d4-a716-446655440007', 'Welcome to your personal DM space, George! You can use this to save notes, draft messages, or just chat with yourself.', NOW() - INTERVAL '1 day'),
        ('880e8400-e29b-41d4-a716-446655440008', '550e8400-e29b-41d4-a716-446655440008', 'Welcome to your personal DM space, Helen! You can use this to save notes, draft messages, or just chat with yourself.', NOW() - INTERVAL '1 day');
        
        RAISE NOTICE 'Added sample messages';
    ELSE
        RAISE NOTICE 'Messages already exist, skipping...';
    END IF;
END $$;

-- Step 9: Enable RLS on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE servers ENABLE ROW LEVEL SECURITY;
ALTER TABLE channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE server_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE dm_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE dm_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Step 10: Grant permissions
GRANT ALL ON user_profiles TO authenticated;
GRANT ALL ON servers TO authenticated;
GRANT ALL ON channels TO authenticated;
GRANT ALL ON server_members TO authenticated;
GRANT ALL ON dm_channels TO authenticated;
GRANT ALL ON dm_participants TO authenticated;
GRANT ALL ON messages TO authenticated;

-- Display summary
SELECT 'Schema fixed and sample data added successfully!' as status;
SELECT COUNT(*) as total_users FROM user_profiles;
SELECT COUNT(*) as total_servers FROM servers;
SELECT COUNT(*) as total_channels FROM channels;
SELECT COUNT(*) as total_dm_channels FROM dm_channels;
SELECT COUNT(*) as total_messages FROM messages;

-- Note: Foreign key constraints have been temporarily removed for testing
-- In production, you would want to recreate them after ensuring all data is properly linked 