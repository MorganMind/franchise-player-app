-- Debug script to check channel and LiveKit setup
-- Run this in your Supabase SQL editor

-- Check all channels and their LiveKit room IDs
SELECT 
  id,
  name,
  type,
  livekit_room_id,
  server_id,
  CASE 
    WHEN type = 'voice' AND livekit_room_id IS NULL THEN '❌ Voice channel missing livekit_room_id'
    WHEN type = 'voice' AND livekit_room_id IS NOT NULL THEN '✅ Voice channel has livekit_room_id'
    WHEN type = 'text' THEN '📝 Text channel (no voice)'
    ELSE '❓ Unknown type'
  END as status
FROM channels 
ORDER BY type, name;

-- Check if voice channels exist
SELECT 
  COUNT(*) as total_channels,
  COUNT(CASE WHEN type = 'voice' THEN 1 END) as voice_channels,
  COUNT(CASE WHEN type = 'voice' AND livekit_room_id IS NOT NULL THEN 1 END) as voice_channels_with_room_id,
  COUNT(CASE WHEN type = 'text' THEN 1 END) as text_channels
FROM channels;

-- Check server members (to verify permissions)
SELECT 
  sm.server_id,
  s.name as server_name,
  sm.user_id,
  up.username,
  COUNT(*) as member_count
FROM server_members sm
JOIN servers s ON sm.server_id = s.id
LEFT JOIN user_profiles up ON sm.user_id = up.id
GROUP BY sm.server_id, s.name, sm.user_id, up.username
ORDER BY s.name, up.username;

-- Check if the check_voice_permissions function exists
SELECT 
  routine_name,
  routine_type,
  data_type
FROM information_schema.routines 
WHERE routine_name = 'check_voice_permissions';

-- Test the check_voice_permissions function with a sample channel
-- (Replace 'your-channel-id' and 'your-user-id' with actual values)
-- SELECT * FROM check_voice_permissions('your-user-id'::uuid, 'your-channel-id'::uuid); 