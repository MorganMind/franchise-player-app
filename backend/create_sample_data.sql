-- Sample data for Discord-like app
-- Run this script in your Supabase SQL editor

-- Clear existing data (optional - be careful!)
-- DELETE FROM messages;
-- DELETE FROM dm_participants;
-- DELETE FROM dm_channels;
-- DELETE FROM server_members;
-- DELETE FROM channels;
-- DELETE FROM servers;
-- DELETE FROM user_profiles;

-- Create sample user profiles with proper UUIDs
INSERT INTO user_profiles (id, username, display_name, avatar_url, status, created_at) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'alice_dev', 'Alice Developer', 'https://api.dicebear.com/7.x/avataaars/svg?seed=alice', 'online', NOW()),
('550e8400-e29b-41d4-a716-446655440002', 'bob_design', 'Bob Designer', 'https://api.dicebear.com/7.x/avataaars/svg?seed=bob', 'away', NOW()),
('550e8400-e29b-41d4-a716-446655440003', 'charlie_pm', 'Charlie PM', 'https://api.dicebear.com/7.x/avataaars/svg?seed=charlie', 'online', NOW()),
('550e8400-e29b-41d4-a716-446655440004', 'diana_qa', 'Diana QA', 'https://api.dicebear.com/7.x/avataaars/svg?seed=diana', 'dnd', NOW()),
('550e8400-e29b-41d4-a716-446655440005', 'eddie_ux', 'Eddie UX', 'https://api.dicebear.com/7.x/avataaars/svg?seed=eddie', 'offline', NOW()),
('550e8400-e29b-41d4-a716-446655440006', 'fiona_ba', 'Fiona BA', 'https://api.dicebear.com/7.x/avataaars/svg?seed=fiona', 'online', NOW()),
('550e8400-e29b-41d4-a716-446655440007', 'george_dev', 'George Developer', 'https://api.dicebear.com/7.x/avataaars/svg?seed=george', 'away', NOW()),
('550e8400-e29b-41d4-a716-446655440008', 'helen_design', 'Helen Designer', 'https://api.dicebear.com/7.x/avataaars/svg?seed=helen', 'online', NOW());

-- Create sample servers with proper UUIDs
INSERT INTO servers (id, name, description, icon, color, created_at) VALUES
('660e8400-e29b-41d4-a716-446655440001', 'Tech Team', 'Our awesome development team', '🚀', '#FF6B6B', NOW()),
('660e8400-e29b-41d4-a716-446655440002', 'Design Hub', 'Creative design discussions', '🎨', '#4ECDC4', NOW()),
('660e8400-e29b-41d4-a716-446655440003', 'Product Squad', 'Product management and planning', '📊', '#45B7D1', NOW()),
('660e8400-e29b-41d4-a716-446655440004', 'QA Warriors', 'Quality assurance team', '🛡️', '#96CEB4', NOW());

-- Create sample channels with proper UUIDs
INSERT INTO channels (id, server_id, name, description, type, created_at) VALUES
-- Tech Team channels
('770e8400-e29b-41d4-a716-446655440001', '660e8400-e29b-41d4-a716-446655440001', 'general', 'General discussions', 'text', NOW()),
('770e8400-e29b-41d4-a716-446655440002', '660e8400-e29b-41d4-a716-446655440001', 'frontend', 'Frontend development', 'text', NOW()),
('770e8400-e29b-41d4-a716-446655440003', '660e8400-e29b-41d4-a716-446655440001', 'backend', 'Backend development', 'text', NOW()),
('770e8400-e29b-41d4-a716-446655440004', '660e8400-e29b-41d4-a716-446655440001', 'dev-ops', 'DevOps and deployment', 'text', NOW()),
('770e8400-e29b-41d4-a716-446655440005', '660e8400-e29b-41d4-a716-446655440001', 'voice-chat', 'Voice channel', 'voice', NOW()),

-- Design Hub channels
('770e8400-e29b-41d4-a716-446655440006', '660e8400-e29b-41d4-a716-446655440002', 'general', 'General design chat', 'text', NOW()),
('770e8400-e29b-41d4-a716-446655440007', '660e8400-e29b-41d4-a716-446655440002', 'ui-design', 'UI design discussions', 'text', NOW()),
('770e8400-e29b-41d4-a716-446655440008', '660e8400-e29b-41d4-a716-446655440002', 'ux-research', 'UX research and insights', 'text', NOW()),
('770e8400-e29b-41d4-a716-446655440009', '660e8400-e29b-41d4-a716-446655440002', 'design-critique', 'Design feedback and critique', 'text', NOW()),

-- Product Squad channels
('770e8400-e29b-41d4-a716-446655440010', '660e8400-e29b-41d4-a716-446655440003', 'general', 'General product chat', 'text', NOW()),
('770e8400-e29b-41d4-a716-446655440011', '660e8400-e29b-41d4-a716-446655440003', 'roadmap', 'Product roadmap discussions', 'text', NOW()),
('770e8400-e29b-41d4-a716-446655440012', '660e8400-e29b-41d4-a716-446655440003', 'user-feedback', 'User feedback and insights', 'text', NOW()),

-- QA Warriors channels
('770e8400-e29b-41d4-a716-446655440013', '660e8400-e29b-41d4-a716-446655440004', 'general', 'General QA chat', 'text', NOW()),
('770e8400-e29b-41d4-a716-446655440014', '660e8400-e29b-41d4-a716-446655440004', 'bug-reports', 'Bug reports and tracking', 'text', NOW()),
('770e8400-e29b-41d4-a716-446655440015', '660e8400-e29b-41d4-a716-446655440004', 'testing-strategy', 'Testing strategy discussions', 'text', NOW());

-- Add server members
INSERT INTO server_members (server_id, user_id, role, joined_at) VALUES
-- Tech Team members
('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'member', NOW()),
('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002', 'member', NOW()),
('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440003', 'admin', NOW()),
('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440007', 'member', NOW()),

-- Design Hub members
('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', 'admin', NOW()),
('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440005', 'member', NOW()),
('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440008', 'member', NOW()),

-- Product Squad members
('660e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003', 'admin', NOW()),
('660e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440006', 'member', NOW()),

-- QA Warriors members
('660e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440004', 'admin', NOW()),
('660e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440006', 'member', NOW());

-- Create sample messages in channels
INSERT INTO messages (channel_id, author_id, content, created_at) VALUES
-- Tech Team messages
('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440003', 'Welcome everyone to the Tech Team! 🚀', NOW() - INTERVAL '2 hours'),
('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'Thanks Charlie! Excited to be here!', NOW() - INTERVAL '1 hour 50 minutes'),
('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002', 'Hello team! Looking forward to working with everyone.', NOW() - INTERVAL '1 hour 45 minutes'),
('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440007', 'Hey everyone! 👋', NOW() - INTERVAL '1 hour 30 minutes'),

-- Frontend channel messages
('770e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 'Anyone working on the new React components?', NOW() - INTERVAL '1 hour'),
('770e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440007', 'Yes! I''m working on the dashboard components.', NOW() - INTERVAL '45 minutes'),
('770e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 'Great! Let''s sync up on the design system.', NOW() - INTERVAL '30 minutes'),

-- Backend channel messages
('770e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440007', 'API endpoints are ready for testing.', NOW() - INTERVAL '2 hours'),
('770e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440001', 'Perfect! I''ll start integrating them.', NOW() - INTERVAL '1 hour 30 minutes'),

-- Design Hub messages
('770e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440002', 'Welcome to the Design Hub! 🎨', NOW() - INTERVAL '3 hours'),
('770e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440005', 'Thanks Bob! Love the creative energy here.', NOW() - INTERVAL '2 hours 30 minutes'),
('770e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440008', 'Hello designers! 👋', NOW() - INTERVAL '2 hours'),

-- UI Design messages
('770e8400-e29b-41d4-a716-446655440007', '550e8400-e29b-41d4-a716-446655440002', 'New design system components are ready for review.', NOW() - INTERVAL '1 hour'),
('770e8400-e29b-41d4-a716-446655440007', '550e8400-e29b-41d4-a716-446655440008', 'I''ll take a look at them!', NOW() - INTERVAL '45 minutes'),

-- Product Squad messages
('770e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440003', 'Q1 roadmap planning starts next week!', NOW() - INTERVAL '4 hours'),
('770e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440006', 'I''ll prepare the user research data.', NOW() - INTERVAL '3 hours 30 minutes'),

-- QA Warriors messages
('770e8400-e29b-41d4-a716-446655440013', '550e8400-e29b-41d4-a716-446655440004', 'Welcome to QA Warriors! 🛡️', NOW() - INTERVAL '5 hours'),
('770e8400-e29b-41d4-a716-446655440013', '550e8400-e29b-41d4-a716-446655440006', 'Ready to ensure quality! 💪', NOW() - INTERVAL '4 hours 30 minutes');

-- Create DM channels and participants with proper UUIDs
INSERT INTO dm_channels (id, created_at) VALUES
('880e8400-e29b-41d4-a716-446655440001', NOW() - INTERVAL '1 day'),
('880e8400-e29b-41d4-a716-446655440002', NOW() - INTERVAL '12 hours'),
('880e8400-e29b-41d4-a716-446655440003', NOW() - INTERVAL '6 hours'),
('880e8400-e29b-41d4-a716-446655440004', NOW() - INTERVAL '3 hours'),
('880e8400-e29b-41d4-a716-446655440005', NOW() - INTERVAL '1 hour');

-- Add DM participants
INSERT INTO dm_participants (dm_channel_id, user_id) VALUES
-- Alice <-> Bob
('880e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001'),
('880e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002'),

-- Charlie <-> Diana
('880e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440003'),
('880e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440004'),

-- Eddie <-> Fiona
('880e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440005'),
('880e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440006'),

-- George <-> Helen
('880e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440007'),
('880e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440008'),

-- Alice <-> Charlie (work discussion)
('880e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440001'),
('880e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440003');

-- Create sample DM messages
INSERT INTO messages (dm_channel_id, author_id, content, created_at) VALUES
-- Alice <-> Bob conversation
('880e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'Hey Bob! How''s the new design coming along?', NOW() - INTERVAL '1 day'),
('880e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002', 'Hi Alice! It''s going great. I''ll share the mockups soon.', NOW() - INTERVAL '23 hours'),
('880e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'Perfect! Can''t wait to see them.', NOW() - INTERVAL '22 hours'),
('880e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002', 'Just sent them over! Let me know what you think.', NOW() - INTERVAL '21 hours'),
('880e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'These look amazing! Love the new color scheme.', NOW() - INTERVAL '20 hours'),

-- Charlie <-> Diana conversation
('880e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440003', 'Diana, we need to discuss the QA process for the new feature.', NOW() - INTERVAL '12 hours'),
('880e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440004', 'Sure Charlie! When would be a good time?', NOW() - INTERVAL '11 hours 30 minutes'),
('880e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440003', 'How about tomorrow at 2 PM?', NOW() - INTERVAL '11 hours'),
('880e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440004', 'Perfect! I''ll prepare the test cases.', NOW() - INTERVAL '10 hours 30 minutes'),

-- Eddie <-> Fiona conversation
('880e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440005', 'Fiona, I have some UX research findings to share.', NOW() - INTERVAL '6 hours'),
('880e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440006', 'Great! I''m always interested in user insights.', NOW() - INTERVAL '5 hours 30 minutes'),
('880e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440005', 'The users really love the new navigation flow!', NOW() - INTERVAL '5 hours'),
('880e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440006', 'That''s fantastic news! 🎉', NOW() - INTERVAL '4 hours 30 minutes'),

-- George <-> Helen conversation
('880e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440007', 'Helen, can you review my latest design?', NOW() - INTERVAL '3 hours'),
('880e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440008', 'Of course! Send it over.', NOW() - INTERVAL '2 hours 30 minutes'),
('880e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440007', 'Just uploaded it to the design system.', NOW() - INTERVAL '2 hours'),
('880e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440008', 'Looking at it now. Great work!', NOW() - INTERVAL '1 hour 30 minutes'),

-- Alice <-> Charlie work discussion
('880e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440001', 'Charlie, we need to discuss the sprint planning.', NOW() - INTERVAL '1 hour'),
('880e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440003', 'Sure Alice! What''s on your mind?', NOW() - INTERVAL '45 minutes'),
('880e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440001', 'I think we should prioritize the user authentication feature.', NOW() - INTERVAL '30 minutes'),
('880e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440003', 'Agreed! That''s critical for the next release.', NOW() - INTERVAL '15 minutes');

-- Create self-DMs for each user with proper UUIDs
INSERT INTO dm_channels (id, created_at) VALUES
('990e8400-e29b-41d4-a716-446655440001', NOW() - INTERVAL '1 day'),
('990e8400-e29b-41d4-a716-446655440002', NOW() - INTERVAL '1 day'),
('990e8400-e29b-41d4-a716-446655440003', NOW() - INTERVAL '1 day'),
('990e8400-e29b-41d4-a716-446655440004', NOW() - INTERVAL '1 day'),
('990e8400-e29b-41d4-a716-446655440005', NOW() - INTERVAL '1 day'),
('990e8400-e29b-41d4-a716-446655440006', NOW() - INTERVAL '1 day'),
('990e8400-e29b-41d4-a716-446655440007', NOW() - INTERVAL '1 day'),
('990e8400-e29b-41d4-a716-446655440008', NOW() - INTERVAL '1 day');

-- Add self-DM participants
INSERT INTO dm_participants (dm_channel_id, user_id) VALUES
('990e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001'),
('990e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002'),
('990e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003'),
('990e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440004'),
('990e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440005'),
('990e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440006'),
('990e8400-e29b-41d4-a716-446655440007', '550e8400-e29b-41d4-a716-446655440007'),
('990e8400-e29b-41d4-a716-446655440008', '550e8400-e29b-41d4-a716-446655440008');

-- Add welcome messages to self-DMs
INSERT INTO messages (dm_channel_id, author_id, content, created_at) VALUES
('990e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'Welcome to your personal space! You can use this to save notes, reminders, or just chat with yourself.', NOW() - INTERVAL '1 day'),
('990e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', 'Welcome to your personal space! You can use this to save notes, reminders, or just chat with yourself.', NOW() - INTERVAL '1 day'),
('990e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003', 'Welcome to your personal space! You can use this to save notes, reminders, or just chat with yourself.', NOW() - INTERVAL '1 day'),
('990e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440004', 'Welcome to your personal space! You can use this to save notes, reminders, or just chat with yourself.', NOW() - INTERVAL '1 day'),
('990e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440005', 'Welcome to your personal space! You can use this to save notes, reminders, or just chat with yourself.', NOW() - INTERVAL '1 day'),
('990e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440006', 'Welcome to your personal space! You can use this to save notes, reminders, or just chat with yourself.', NOW() - INTERVAL '1 day'),
('990e8400-e29b-41d4-a716-446655440007', '550e8400-e29b-41d4-a716-446655440007', 'Welcome to your personal space! You can use this to save notes, reminders, or just chat with yourself.', NOW() - INTERVAL '1 day'),
('990e8400-e29b-41d4-a716-446655440008', '550e8400-e29b-41d4-a716-446655440008', 'Welcome to your personal space! You can use this to save notes, reminders, or just chat with yourself.', NOW() - INTERVAL '1 day');

-- Add some personal notes to self-DMs
INSERT INTO messages (dm_channel_id, author_id, content, created_at) VALUES
('990e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'Remember to review the React component library tomorrow.', NOW() - INTERVAL '12 hours'),
('990e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'Great meeting with the design team today!', NOW() - INTERVAL '6 hours'),
('990e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', 'Need to update the design system documentation.', NOW() - INTERVAL '8 hours'),
('990e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003', 'Sprint planning meeting scheduled for Friday.', NOW() - INTERVAL '10 hours'),
('990e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440004', 'Test cases for user authentication are ready.', NOW() - INTERVAL '4 hours'),
('990e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440005', 'User research insights: navigation needs improvement.', NOW() - INTERVAL '7 hours'),
('990e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440006', 'Product requirements for Q2 are finalized.', NOW() - INTERVAL '5 hours'),
('990e8400-e29b-41d4-a716-446655440007', '550e8400-e29b-41d4-a716-446655440007', 'API documentation updated with new endpoints.', NOW() - INTERVAL '3 hours'),
('990e8400-e29b-41d4-a716-446655440008', '550e8400-e29b-41d4-a716-446655440008', 'Design review meeting with stakeholders tomorrow.', NOW() - INTERVAL '2 hours');

-- Display summary
SELECT 'Sample data created successfully!' as status;
SELECT COUNT(*) as total_users FROM user_profiles;
SELECT COUNT(*) as total_servers FROM servers;
SELECT COUNT(*) as total_channels FROM channels;
SELECT COUNT(*) as total_dm_channels FROM dm_channels;
SELECT COUNT(*) as total_messages FROM messages; 