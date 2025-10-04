-- Simple sample data for Discord-like app (no auth dependencies)
-- Run this script in your Supabase SQL editor

-- First, let's create the tables if they don't exist (without auth dependencies)

-- User profiles table (simplified)
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  status TEXT DEFAULT 'online' CHECK (status IN ('online', 'away', 'dnd', 'offline')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Servers table
CREATE TABLE IF NOT EXISTS servers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  color TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Channels table
CREATE TABLE IF NOT EXISTS channels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  server_id UUID REFERENCES servers(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT DEFAULT 'text',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Server members table
CREATE TABLE IF NOT EXISTS server_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  server_id UUID REFERENCES servers(id) ON DELETE CASCADE,
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  nickname TEXT,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (server_id, user_id)
);

-- DM channels table
CREATE TABLE IF NOT EXISTS dm_channels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- DM participants table
CREATE TABLE IF NOT EXISTS dm_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dm_channel_id UUID REFERENCES dm_channels(id) ON DELETE CASCADE,
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (dm_channel_id, user_id)
);

-- Messages table
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

-- Enable RLS
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

-- Create sample user profiles
INSERT INTO user_profiles (id, username, display_name, avatar_url, status, created_at) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'alice_dev', 'Alice Developer', 'https://api.dicebear.com/7.x/avataaars/svg?seed=alice', 'online', NOW()),
('550e8400-e29b-41d4-a716-446655440002', 'bob_design', 'Bob Designer', 'https://api.dicebear.com/7.x/avataaars/svg?seed=bob', 'away', NOW()),
('550e8400-e29b-41d4-a716-446655440003', 'charlie_pm', 'Charlie PM', 'https://api.dicebear.com/7.x/avataaars/svg?seed=charlie', 'online', NOW()),
('550e8400-e29b-41d4-a716-446655440004', 'diana_qa', 'Diana QA', 'https://api.dicebear.com/7.x/avataaars/svg?seed=diana', 'dnd', NOW()),
('550e8400-e29b-41d4-a716-446655440005', 'eddie_ux', 'Eddie UX', 'https://api.dicebear.com/7.x/avataaars/svg?seed=eddie', 'offline', NOW()),
('550e8400-e29b-41d4-a716-446655440006', 'fiona_ba', 'Fiona BA', 'https://api.dicebear.com/7.x/avataaars/svg?seed=fiona', 'online', NOW()),
('550e8400-e29b-41d4-a716-446655440007', 'george_dev', 'George Developer', 'https://api.dicebear.com/7.x/avataaars/svg?seed=george', 'away', NOW()),
('550e8400-e29b-41d4-a716-446655440008', 'helen_design', 'Helen Designer', 'https://api.dicebear.com/7.x/avataaars/svg?seed=helen', 'online', NOW());

-- Create sample servers
INSERT INTO servers (id, name, description, icon, color, created_at) VALUES
('660e8400-e29b-41d4-a716-446655440001', 'Tech Team', 'Our awesome development team', '🚀', '#FF6B6B', NOW()),
('660e8400-e29b-41d4-a716-446655440002', 'Design Hub', 'Creative design discussions', '🎨', '#4ECDC4', NOW());

-- Create sample channels
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

-- Create server memberships (all users in both servers)
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

-- Create DM channels and participants (self-DMs for each user)
INSERT INTO dm_channels (id, created_at) VALUES
('880e8400-e29b-41d4-a716-446655440001', NOW()),
('880e8400-e29b-41d4-a716-446655440002', NOW()),
('880e8400-e29b-41d4-a716-446655440003', NOW()),
('880e8400-e29b-41d4-a716-446655440004', NOW()),
('880e8400-e29b-41d4-a716-446655440005', NOW()),
('880e8400-e29b-41d4-a716-446655440006', NOW()),
('880e8400-e29b-41d4-a716-446655440007', NOW()),
('880e8400-e29b-41d4-a716-446655440008', NOW());

-- Add participants to DM channels (self-DMs)
INSERT INTO dm_participants (dm_channel_id, user_id, joined_at) VALUES
('880e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', NOW()),
('880e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', NOW()),
('880e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003', NOW()),
('880e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440004', NOW()),
('880e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440005', NOW()),
('880e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440006', NOW()),
('880e8400-e29b-41d4-a716-446655440007', '550e8400-e29b-41d4-a716-446655440007', NOW()),
('880e8400-e29b-41d4-a716-446655440008', '550e8400-e29b-41d4-a716-446655440008', NOW());

-- Create sample messages in channels
INSERT INTO messages (channel_id, author_id, content, created_at) VALUES
-- Tech Team general channel messages
('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'Hey everyone! How is the sprint going?', NOW() - INTERVAL '2 hours'),
('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440003', 'Sprint is going well! We should be on track to finish by Friday.', NOW() - INTERVAL '1 hour 45 minutes'),
('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440007', 'I just pushed the latest changes to the feature branch.', NOW() - INTERVAL '1 hour 30 minutes'),
('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440004', 'Great! I will start testing the new features tomorrow.', NOW() - INTERVAL '1 hour'),
-- Design Hub general channel messages
('770e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440002', 'Check out this new design inspiration I found!', NOW() - INTERVAL '3 hours'),
('770e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440005', 'That looks amazing! I love the color palette.', NOW() - INTERVAL '2 hours 30 minutes'),
('770e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440008', 'I think we should incorporate some of these elements into our next project.', NOW() - INTERVAL '2 hours'),
('770e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440006', 'Agreed! Let me create a mood board for our next design review.', NOW() - INTERVAL '1 hour 30 minutes');

-- Create welcome messages in self-DMs
INSERT INTO messages (dm_channel_id, author_id, content, created_at) VALUES
('880e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'Welcome to your personal DM space, Alice! You can use this to save notes, draft messages, or just chat with yourself.', NOW() - INTERVAL '1 day'),
('880e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', 'Welcome to your personal DM space, Bob! You can use this to save notes, draft messages, or just chat with yourself.', NOW() - INTERVAL '1 day'),
('880e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003', 'Welcome to your personal DM space, Charlie! You can use this to save notes, draft messages, or just chat with yourself.', NOW() - INTERVAL '1 day'),
('880e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440004', 'Welcome to your personal DM space, Diana! You can use this to save notes, draft messages, or just chat with yourself.', NOW() - INTERVAL '1 day'),
('880e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440005', 'Welcome to your personal DM space, Eddie! You can use this to save notes, draft messages, or just chat with yourself.', NOW() - INTERVAL '1 day'),
('880e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440006', 'Welcome to your personal DM space, Fiona! You can use this to save notes, draft messages, or just chat with yourself.', NOW() - INTERVAL '1 day'),
('880e8400-e29b-41d4-a716-446655440007', '550e8400-e29b-41d4-a716-446655440007', 'Welcome to your personal DM space, George! You can use this to save notes, draft messages, or just chat with yourself.', NOW() - INTERVAL '1 day'),
('880e8400-e29b-41d4-a716-446655440008', '550e8400-e29b-41d4-a716-446655440008', 'Welcome to your personal DM space, Helen! You can use this to save notes, draft messages, or just chat with yourself.', NOW() - INTERVAL '1 day');

-- Display summary
SELECT 'Sample data created successfully!' as status;
SELECT COUNT(*) as total_users FROM user_profiles;
SELECT COUNT(*) as total_servers FROM servers;
SELECT COUNT(*) as total_channels FROM channels;
SELECT COUNT(*) as total_dm_channels FROM dm_channels;
SELECT COUNT(*) as total_messages FROM messages; 