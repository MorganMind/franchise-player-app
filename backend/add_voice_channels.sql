-- Add sample voice channels to existing servers
-- Run this script in your Supabase SQL editor

-- Add voice channels to Tech Team server
INSERT INTO channels (id, server_id, name, type, created_at) VALUES
(gen_random_uuid(), '660e8400-e29b-41d4-a716-446655440001', 'General Voice', 'voice', NOW()),
(gen_random_uuid(), '660e8400-e29b-41d4-a716-446655440001', 'Gaming', 'voice', NOW()),
(gen_random_uuid(), '660e8400-e29b-41d4-a716-446655440001', 'Meeting Room', 'voice', NOW());

-- Add voice channels to Design Hub server
INSERT INTO channels (id, server_id, name, type, created_at) VALUES
(gen_random_uuid(), '660e8400-e29b-41d4-a716-446655440002', 'Creative Space', 'voice', NOW()),
(gen_random_uuid(), '660e8400-e29b-41d4-a716-446655440002', 'Feedback Session', 'voice', NOW());

-- Update existing channels to have proper type
UPDATE channels 
SET type = 'text' 
WHERE type IS NULL OR type = '';

-- Display summary
SELECT 
  'Voice channels added successfully!' as status,
  COUNT(*) as total_voice_channels
FROM channels 
WHERE type = 'voice';

-- Show all channels by type
SELECT 
  type,
  COUNT(*) as count,
  STRING_AGG(name, ', ') as channel_names
FROM channels 
GROUP BY type 
ORDER BY type; 