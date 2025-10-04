-- Quick fix: Add the missing send_franchise_channel_message function
-- Run this in your Supabase SQL editor

-- First, add the franchise_channel_id column if it doesn't exist
ALTER TABLE messages 
ADD COLUMN IF NOT EXISTS franchise_channel_id UUID REFERENCES franchise_channels(id) ON DELETE CASCADE;

-- Create a function to send messages to franchise channels
CREATE OR REPLACE FUNCTION send_franchise_channel_message(
  p_franchise_channel_id uuid,
  p_content text
) RETURNS uuid AS $$
DECLARE
  v_message_id uuid;
BEGIN
  -- Insert the message
  INSERT INTO messages (franchise_channel_id, author_id, content)
  VALUES (p_franchise_channel_id, auth.uid(), p_content)
  RETURNING id INTO v_message_id;
  
  RETURN v_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION send_franchise_channel_message TO authenticated;

-- Display confirmation
SELECT 'send_franchise_channel_message function created!' as status;
