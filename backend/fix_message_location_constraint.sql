-- Fix the message_location constraint to allow franchise_channel_id
-- Run this in your Supabase SQL editor

-- First, let's see what the current constraint looks like
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conname = 'message_location';

-- Drop the existing constraint
ALTER TABLE messages DROP CONSTRAINT IF EXISTS message_location;

-- Create a new constraint that allows franchise_channel_id
ALTER TABLE messages ADD CONSTRAINT message_location 
CHECK (
    (channel_id IS NOT NULL AND dm_channel_id IS NULL AND franchise_channel_id IS NULL) OR
    (channel_id IS NULL AND dm_channel_id IS NOT NULL AND franchise_channel_id IS NULL) OR
    (channel_id IS NULL AND dm_channel_id IS NULL AND franchise_channel_id IS NOT NULL)
);

-- Display confirmation
SELECT 'message_location constraint updated to support franchise channels!' as status;


