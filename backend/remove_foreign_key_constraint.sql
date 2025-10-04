-- Remove foreign key constraint from user_profiles and add sample data
-- Run this script in your Supabase SQL editor

-- First, let's check the current constraint
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    SELECT tc.constraint_name INTO constraint_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_name = 'user_profiles' 
    AND tc.constraint_type = 'FOREIGN KEY'
    AND kcu.column_name = 'id';
    
    IF constraint_name IS NOT NULL THEN
        RAISE NOTICE 'Found foreign key constraint: %', constraint_name;
    ELSE
        RAISE NOTICE 'No foreign key constraint found on user_profiles.id';
    END IF;
END $$;

-- Remove the foreign key constraint if it exists
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
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
        RAISE NOTICE 'No foreign key constraint to remove';
    END IF;
END $$;

-- Now let's add the missing columns to servers table if they don't exist
DO $$
DECLARE
    column_exists BOOLEAN;
BEGIN
    -- Check if 'icon' column exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'servers' AND column_name = 'icon'
    ) INTO column_exists;
    
    IF NOT column_exists THEN
        ALTER TABLE servers ADD COLUMN icon TEXT;
        RAISE NOTICE 'Added icon column to servers table';
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
    
    -- Check if 'description' column exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'servers' AND column_name = 'description'
    ) INTO column_exists;
    
    IF NOT column_exists THEN
        ALTER TABLE servers ADD COLUMN description TEXT;
        RAISE NOTICE 'Added description column to servers table';
    END IF;
END $$;

-- Add missing columns to user_profiles table if they don't exist
DO $$
DECLARE
    column_exists BOOLEAN;
BEGIN
    -- Check if 'status' column exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_profiles' AND column_name = 'status'
    ) INTO column_exists;
    
    IF NOT column_exists THEN
        ALTER TABLE user_profiles ADD COLUMN status TEXT DEFAULT 'online' CHECK (status IN ('online', 'away', 'dnd', 'offline'));
        RAISE NOTICE 'Added status column to user_profiles table';
    END IF;
    
    -- Check if 'display_name' column exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_profiles' AND column_name = 'display_name'
    ) INTO column_exists;
    
    IF NOT column_exists THEN
        ALTER TABLE user_profiles ADD COLUMN display_name TEXT;
        -- Set display_name to username if it doesn't exist
        UPDATE user_profiles SET display_name = username WHERE display_name IS NULL;
        RAISE NOTICE 'Added display_name column to user_profiles table';
    END IF;
    
    -- Check if 'updated_at' column exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_profiles' AND column_name = 'updated_at'
    ) INTO column_exists;
    
    IF NOT column_exists THEN
        ALTER TABLE user_profiles ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column to user_profiles table';
    END IF;
END $$;

-- Now add sample data only if it doesn't already exist
-- Check if we have any sample users, and if not, add them
DO $$
DECLARE
    sample_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO sample_count FROM user_profiles WHERE username LIKE '%_dev' OR username LIKE '%_design';
    
    IF sample_count = 0 THEN
        -- Add sample user profiles only if none exist
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

-- Add sample servers only if they don't exist
DO $$
DECLARE
    server_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO server_count FROM servers;
    
    IF server_count = 0 THEN
        INSERT INTO servers (id, name, description, icon, color, owner_id, created_at) VALUES
        ('660e8400-e29b-41d4-a716-446655440001', 'Tech Team', 'Our awesome development team', '🚀', '#FF6B6B', '550e8400-e29b-41d4-a716-446655440001', NOW()),
        ('660e8400-e29b-41d4-a716-446655440002', 'Design Hub', 'Creative design discussions', '🎨', '#4ECDC4', '550e8400-e29b-41d4-a716-446655440002', NOW());
        
        RAISE NOTICE 'Added 2 sample servers';
    ELSE
        RAISE NOTICE 'Servers already exist, skipping...';
    END IF;
END $$;

-- Create channels table if it doesn't exist
CREATE TABLE IF NOT EXISTS channels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  server_id UUID REFERENCES servers(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT DEFAULT 'text',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add sample channels only if they don't exist
DO $$
DECLARE
    channel_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO channel_count FROM channels;
    
    IF channel_count = 0 THEN
        INSERT INTO channels (id, server_id, name, type, created_at) VALUES
        -- Tech Team channels
        ('770e8400-e29b-41d4-a716-446655440001', '660e8400-e29b-41d4-a716-446655440001', 'general', 'text', NOW()),
        ('770e8400-e29b-41d4-a716-446655440002', '660e8400-e29b-41d4-a716-446655440001', 'random', 'text', NOW()),
        ('770e8400-e29b-41d4-a716-446655440003', '660e8400-e29b-41d4-a716-446655440001', 'announcements', 'text', NOW()),
        ('770e8400-e29b-41d4-a716-446655440004', '660e8400-e29b-41d4-a716-446655440001', 'help', 'text', NOW()),
        -- Design Hub channels
        ('770e8400-e29b-41d4-a716-446655440005', '660e8400-e29b-41d4-a716-446655440002', 'general', 'text', NOW()),
        ('770e8400-e29b-41d4-a716-446655440006', '660e8400-e29b-41d4-a716-446655440002', 'inspiration', 'text', NOW()),
        ('770e8400-e29b-41d4-a716-446655440007', '660e8400-e29b-41d4-a716-446655440002', 'feedback', 'text', NOW()),
        ('770e8400-e29b-41d4-a716-446655440008', '660e8400-e29b-41d4-a716-446655440002', 'resources', 'text', NOW());
        
        RAISE NOTICE 'Added 8 sample channels';
    ELSE
        RAISE NOTICE 'Channels already exist, skipping...';
    END IF;
END $$;

-- Create server_members table if it doesn't exist
CREATE TABLE IF NOT EXISTS server_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  server_id UUID REFERENCES servers(id) ON DELETE CASCADE,
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  nickname TEXT,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (server_id, user_id)
);

-- Add server memberships only if they don't exist
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

-- Create dm_channels table if it doesn't exist
CREATE TABLE IF NOT EXISTS dm_channels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create dm_participants table if it doesn't exist
CREATE TABLE IF NOT EXISTS dm_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dm_channel_id UUID REFERENCES dm_channels(id) ON DELETE CASCADE,
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (dm_channel_id, user_id)
);

-- Add DM channels and participants only if they don't exist
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

-- Create messages table if it doesn't exist
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID REFERENCES channels(id) ON DELETE CASCADE,
  dm_channel_id UUID REFERENCES dm_channels(id) ON DELETE CASCADE,
  author_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_deleted BOOLEAN DEFAULT FALSE,
  edited_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add sample messages only if they don't exist
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

-- Enable RLS on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE servers ENABLE ROW LEVEL SECURITY;
ALTER TABLE channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE server_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE dm_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE dm_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT ALL ON user_profiles TO authenticated;
GRANT ALL ON servers TO authenticated;
GRANT ALL ON channels TO authenticated;
GRANT ALL ON server_members TO authenticated;
GRANT ALL ON dm_channels TO authenticated;
GRANT ALL ON dm_participants TO authenticated;
GRANT ALL ON messages TO authenticated;

-- Display summary
SELECT 'Foreign key constraint removed and sample data added successfully!' as status;
SELECT COUNT(*) as total_users FROM user_profiles;
SELECT COUNT(*) as total_servers FROM servers;
SELECT COUNT(*) as total_channels FROM channels;
SELECT COUNT(*) as total_dm_channels FROM dm_channels;
SELECT COUNT(*) as total_messages FROM messages; 