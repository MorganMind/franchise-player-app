-- LiveKit Integration Schema
-- Run this script in your Supabase SQL editor

-- Add livekit_room_id to existing channels table
ALTER TABLE public.channels 
ADD COLUMN IF NOT EXISTS livekit_room_id text UNIQUE;

-- Add livekit_room_id to existing dm_channels table  
ALTER TABLE public.dm_channels 
ADD COLUMN IF NOT EXISTS livekit_room_id text UNIQUE,
ADD COLUMN IF NOT EXISTS call_active boolean DEFAULT false;

-- Track active participants in LiveKit rooms
CREATE TABLE IF NOT EXISTS public.voice_participants (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  channel_id uuid,
  dm_channel_id uuid,
  franchise_channel_id uuid,
  user_id uuid NOT NULL,
  livekit_participant_sid text NOT NULL, -- LiveKit's session ID
  connection_id text NOT NULL DEFAULT gen_random_uuid()::text,
  joined_at timestamp with time zone DEFAULT now(),
  last_heartbeat timestamp with time zone DEFAULT now(),
  is_speaking boolean DEFAULT false,
  is_muted boolean DEFAULT false,
  is_deafened boolean DEFAULT false,
  is_video_on boolean DEFAULT false,
  is_screen_sharing boolean DEFAULT false,
  metadata jsonb DEFAULT '{}'::jsonb,
  CONSTRAINT voice_participants_pkey PRIMARY KEY (id),
  CONSTRAINT voice_participants_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES public.channels(id) ON DELETE CASCADE,
  CONSTRAINT voice_participants_dm_channel_id_fkey FOREIGN KEY (dm_channel_id) REFERENCES public.dm_channels(id) ON DELETE CASCADE,
  CONSTRAINT voice_participants_franchise_channel_id_fkey FOREIGN KEY (franchise_channel_id) REFERENCES public.franchise_channels(id) ON DELETE CASCADE,
  CONSTRAINT voice_participants_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT voice_participants_channel_check CHECK (
    (channel_id IS NOT NULL AND dm_channel_id IS NULL AND franchise_channel_id IS NULL) OR 
    (channel_id IS NULL AND dm_channel_id IS NOT NULL AND franchise_channel_id IS NULL) OR
    (channel_id IS NULL AND dm_channel_id IS NULL AND franchise_channel_id IS NOT NULL)
  ),
  UNIQUE(user_id, channel_id, connection_id),
  UNIQUE(user_id, dm_channel_id, connection_id),
  UNIQUE(user_id, franchise_channel_id, connection_id)
);

-- Queue for syncing permission changes to LiveKit
CREATE TABLE IF NOT EXISTS public.livekit_sync_queue (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  server_id uuid,
  channel_id uuid,
  dm_channel_id uuid,
  franchise_channel_id uuid,
  action text NOT NULL CHECK (action IN ('remove', 'mute', 'unmute', 'update_permissions')),
  reason text,
  processed boolean DEFAULT false,
  error text,
  created_at timestamp with time zone DEFAULT now(),
  processed_at timestamp with time zone,
  CONSTRAINT livekit_sync_queue_pkey PRIMARY KEY (id),
  CONSTRAINT livekit_sync_queue_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT livekit_sync_queue_server_id_fkey FOREIGN KEY (server_id) REFERENCES public.servers(id),
  CONSTRAINT livekit_sync_queue_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES public.channels(id),
  CONSTRAINT livekit_sync_queue_dm_channel_id_fkey FOREIGN KEY (dm_channel_id) REFERENCES public.dm_channels(id),
  CONSTRAINT livekit_sync_queue_franchise_channel_id_fkey FOREIGN KEY (franchise_channel_id) REFERENCES public.franchise_channels(id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_voice_participants_channel ON public.voice_participants(channel_id) WHERE channel_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_voice_participants_dm_channel ON public.voice_participants(dm_channel_id) WHERE dm_channel_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_voice_participants_franchise_channel ON public.voice_participants(franchise_channel_id) WHERE franchise_channel_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_voice_participants_user ON public.voice_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_livekit_sync_queue_unprocessed ON public.livekit_sync_queue(created_at) WHERE processed = false;

-- Enable RLS
ALTER TABLE public.voice_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.livekit_sync_queue ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT ALL ON public.voice_participants TO authenticated;
GRANT ALL ON public.livekit_sync_queue TO authenticated;

-- Create a function to check voice permissions for channels
CREATE OR REPLACE FUNCTION check_voice_permissions(
  p_user_id uuid,
  p_channel_id uuid
) RETURNS TABLE (
  can_connect boolean,
  can_speak boolean,
  can_video boolean,
  can_share_screen boolean,
  can_priority_speaker boolean
) AS $$
DECLARE
  v_server_id uuid;
  v_member_id uuid;
  v_is_muted boolean;
  v_muted_until timestamptz;
  v_is_banned boolean;
  v_final_allow bigint := 0;
  v_final_deny bigint := 0;
  
  -- Permission bits (Discord-style)
  CONNECT_BIT CONSTANT bigint := 1 << 20;  -- Voice connect
  SPEAK_BIT CONSTANT bigint := 1 << 21;    -- Voice speak
  VIDEO_BIT CONSTANT bigint := 1 << 22;    -- Video
  SCREEN_BIT CONSTANT bigint := 1 << 23;   -- Screen share
  PRIORITY_BIT CONSTANT bigint := 1 << 8;  -- Priority speaker
BEGIN
  -- Get channel's server
  SELECT server_id INTO v_server_id 
  FROM channels WHERE id = p_channel_id;
  
  -- Check if user is a member and not banned
  SELECT id, is_banned, is_muted, muted_until 
  INTO v_member_id, v_is_banned, v_is_muted, v_muted_until
  FROM server_members 
  WHERE server_id = v_server_id AND user_id = p_user_id;
  
  IF v_member_id IS NULL OR v_is_banned THEN
    RETURN QUERY SELECT false, false, false, false, false;
    RETURN;
  END IF;
  
  -- For now, allow all permissions if user is a member
  -- In a full implementation, you'd check role permissions here
  v_final_allow := CONNECT_BIT | SPEAK_BIT | VIDEO_BIT | SCREEN_BIT;
  
  -- Check if currently muted
  IF v_is_muted AND (v_muted_until IS NULL OR v_muted_until > NOW()) THEN
    v_final_deny := v_final_deny | SPEAK_BIT;
  END IF;
  
  RETURN QUERY SELECT
    (v_final_allow & CONNECT_BIT) > 0 AND NOT (v_final_deny & CONNECT_BIT) > 0,
    (v_final_allow & SPEAK_BIT) > 0 AND NOT (v_final_deny & SPEAK_BIT) > 0,
    (v_final_allow & VIDEO_BIT) > 0 AND NOT (v_final_deny & VIDEO_BIT) > 0,
    (v_final_allow & SCREEN_BIT) > 0 AND NOT (v_final_deny & SCREEN_BIT) > 0,
    (v_final_allow & PRIORITY_BIT) > 0 AND NOT (v_final_deny & PRIORITY_BIT) > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to check voice permissions for franchise channels
CREATE OR REPLACE FUNCTION check_franchise_voice_permissions(
  p_user_id uuid,
  p_franchise_channel_id uuid
) RETURNS TABLE (
  can_connect boolean,
  can_speak boolean,
  can_video boolean,
  can_share_screen boolean,
  can_priority_speaker boolean
) AS $$
DECLARE
  v_server_id uuid;
  v_member_id uuid;
BEGIN
  -- Get franchise's server
  SELECT f.server_id INTO v_server_id 
  FROM franchise_channels fc
  JOIN franchises f ON fc.franchise_id = f.id
  WHERE fc.id = p_franchise_channel_id;
  
  -- Check if user is a member
  SELECT id INTO v_member_id
  FROM server_members 
  WHERE server_id = v_server_id AND user_id = p_user_id;
  
  IF v_member_id IS NULL THEN
    RETURN QUERY SELECT false, false, false, false, false;
    RETURN;
  END IF;
  
  -- For franchise channels, allow all permissions if user is a member
  RETURN QUERY SELECT true, true, true, true, false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger when member is banned or muted
CREATE OR REPLACE FUNCTION sync_member_voice_state()
RETURNS TRIGGER AS $$
BEGIN
  -- If member is banned
  IF NEW.is_banned = true AND (OLD.is_banned = false OR OLD.is_banned IS NULL) THEN
    INSERT INTO livekit_sync_queue (user_id, server_id, action, reason)
    VALUES (NEW.user_id, NEW.server_id, 'remove', 'Member banned');
  END IF;
  
  -- If member is muted
  IF NEW.is_muted = true AND (OLD.is_muted = false OR OLD.is_muted IS NULL) THEN
    INSERT INTO livekit_sync_queue (user_id, server_id, action, reason)
    VALUES (NEW.user_id, NEW.server_id, 'mute', 'Member muted');
  ELSIF NEW.is_muted = false AND OLD.is_muted = true THEN
    INSERT INTO livekit_sync_queue (user_id, server_id, action, reason)
    VALUES (NEW.user_id, NEW.server_id, 'unmute', 'Member unmuted');
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'on_member_state_change') THEN
    CREATE TRIGGER on_member_state_change
    AFTER UPDATE ON server_members
    FOR EACH ROW
    EXECUTE FUNCTION sync_member_voice_state();
  END IF;
END $$;

-- RLS Policies for voice_participants
CREATE POLICY "Users can view voice participants in their channels" ON public.voice_participants
  FOR SELECT USING (
    -- Channel participants
    (channel_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM channels c
      JOIN server_members sm ON c.server_id = sm.server_id
      WHERE c.id = voice_participants.channel_id
      AND sm.user_id = auth.uid()
    )) OR
    -- DM participants
    (dm_channel_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM dm_participants dp
      WHERE dp.dm_channel_id = voice_participants.dm_channel_id
      AND dp.user_id = auth.uid()
    )) OR
    -- Franchise channel participants
    (franchise_channel_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM franchise_channels fc
      JOIN franchises f ON fc.franchise_id = f.id
      JOIN server_members sm ON f.server_id = sm.server_id
      WHERE fc.id = voice_participants.franchise_channel_id
      AND sm.user_id = auth.uid()
    ))
  );

CREATE POLICY "Users can insert their own voice participation" ON public.voice_participants
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own voice participation" ON public.voice_participants
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own voice participation" ON public.voice_participants
  FOR DELETE USING (user_id = auth.uid());

-- RLS Policies for livekit_sync_queue (admin only)
CREATE POLICY "Service role can manage sync queue" ON public.livekit_sync_queue
  FOR ALL USING (auth.role() = 'service_role');

-- Display summary
SELECT 'LiveKit schema updated successfully!' as status; 