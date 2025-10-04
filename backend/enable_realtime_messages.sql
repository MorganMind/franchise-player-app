-- Enable real-time updates for messages table
-- Run this script in your Supabase SQL editor

-- Enable real-time on the messages table
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- Verify real-time is enabled
SELECT 
    schemaname,
    tablename,
    pubname
FROM pg_publication_tables 
WHERE tablename = 'messages';

-- Also enable real-time on user_profiles for completeness
ALTER PUBLICATION supabase_realtime ADD TABLE user_profiles;

-- Display confirmation
SELECT 'Real-time enabled for messages and user_profiles tables!' as status; 