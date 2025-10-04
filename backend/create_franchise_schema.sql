-- Franchise Schema for Discord-like App
-- Run this script in your Supabase SQL editor

-- Create franchises table
CREATE TABLE IF NOT EXISTS public.franchises (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  server_id uuid NOT NULL REFERENCES public.servers(id) ON DELETE CASCADE,
  name text NOT NULL,
  external_id text UNIQUE, -- Madden's internal ID
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Create franchise_channels table
CREATE TABLE IF NOT EXISTS public.franchise_channels (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  franchise_id uuid NOT NULL REFERENCES public.franchises(id) ON DELETE CASCADE,
  name text NOT NULL,
  type text NOT NULL CHECK (type IN ('text', 'voice', 'video')),
  position integer NOT NULL DEFAULT 0,
  livekit_room_id text UNIQUE,
  voice_enabled boolean DEFAULT false,
  video_enabled boolean DEFAULT false,
  is_private boolean DEFAULT false,
  max_participants integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Enable RLS on both tables
ALTER TABLE public.franchises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.franchise_channels ENABLE ROW LEVEL SECURITY;

-- Grant permissions to authenticated users
GRANT ALL ON public.franchises TO authenticated;
GRANT ALL ON public.franchise_channels TO authenticated;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_franchises_server_id ON public.franchises(server_id);
CREATE INDEX IF NOT EXISTS idx_franchises_external_id ON public.franchises(external_id);
CREATE INDEX IF NOT EXISTS idx_franchise_channels_franchise_id ON public.franchise_channels(franchise_id);
CREATE INDEX IF NOT EXISTS idx_franchise_channels_position ON public.franchise_channels(franchise_id, position);

-- RLS Policies for franchises table
-- View if member of server
CREATE POLICY "View franchises in server" ON public.franchises
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.server_members sm
      WHERE sm.server_id = franchises.server_id
      AND sm.user_id = auth.uid()
    )
  );

-- Insert if member of server (for now, we'll use the same logic as channels)
CREATE POLICY "Insert franchises in server" ON public.franchises
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.server_members sm
      WHERE sm.server_id = franchises.server_id
      AND sm.user_id = auth.uid()
    )
  );

-- Update if member of server
CREATE POLICY "Update franchises in server" ON public.franchises
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.server_members sm
      WHERE sm.server_id = franchises.server_id
      AND sm.user_id = auth.uid()
    )
  );

-- Delete if member of server
CREATE POLICY "Delete franchises in server" ON public.franchises
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.server_members sm
      WHERE sm.server_id = franchises.server_id
      AND sm.user_id = auth.uid()
    )
  );

-- RLS Policies for franchise_channels table
-- View if user can view the franchise's server
CREATE POLICY "View franchise channels" ON public.franchise_channels
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.franchises f
      JOIN public.server_members sm ON sm.server_id = f.server_id
      WHERE f.id = franchise_channels.franchise_id
      AND sm.user_id = auth.uid()
    )
  );

-- Insert if user can view the franchise's server
CREATE POLICY "Insert franchise channels" ON public.franchise_channels
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.franchises f
      JOIN public.server_members sm ON sm.server_id = f.server_id
      WHERE f.id = franchise_channels.franchise_id
      AND sm.user_id = auth.uid()
    )
  );

-- Update if user can view the franchise's server
CREATE POLICY "Update franchise channels" ON public.franchise_channels
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.franchises f
      JOIN public.server_members sm ON sm.server_id = f.server_id
      WHERE f.id = franchise_channels.franchise_id
      AND sm.user_id = auth.uid()
    )
  );

-- Delete if user can view the franchise's server
CREATE POLICY "Delete franchise channels" ON public.franchise_channels
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.franchises f
      JOIN public.server_members sm ON sm.server_id = f.server_id
      WHERE f.id = franchise_channels.franchise_id
      AND sm.user_id = auth.uid()
    )
  );

-- Create a function to automatically create franchise channels from a template
CREATE OR REPLACE FUNCTION create_franchise_with_default_channels(
  p_server_id uuid,
  p_name text,
  p_external_id text DEFAULT NULL,
  p_metadata jsonb DEFAULT '{}'::jsonb
) RETURNS uuid AS $$
DECLARE
  v_franchise_id uuid;
BEGIN
  -- Create the franchise
  INSERT INTO public.franchises (server_id, name, external_id, metadata)
  VALUES (p_server_id, p_name, p_external_id, p_metadata)
  RETURNING id INTO v_franchise_id;
  
  -- Create default channels for the franchise
  INSERT INTO public.franchise_channels (franchise_id, name, type, position) VALUES
    (v_franchise_id, 'general', 'text', 0),
    (v_franchise_id, 'trades', 'text', 1),
    (v_franchise_id, 'draft', 'text', 2),
    (v_franchise_id, 'game-discussion', 'text', 3),
    (v_franchise_id, 'announcements', 'text', 4),
    (v_franchise_id, 'General Voice', 'voice', 5),
    (v_franchise_id, 'Game Night', 'voice', 6);
  
  RETURN v_franchise_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION create_franchise_with_default_channels TO authenticated;

-- Create a sample franchise for the Madden X server (if it exists)
DO $$
DECLARE
  v_madden_server_id uuid;
  v_franchise_id uuid;
BEGIN
  -- Check if Madden X server exists
  SELECT id INTO v_madden_server_id FROM public.servers WHERE name = 'Madden X' LIMIT 1;
  
  IF v_madden_server_id IS NOT NULL THEN
    -- Create a sample franchise
    SELECT create_franchise_with_default_channels(
      v_madden_server_id,
      'Madden 24 Franchise',
      'madden_24_001',
      '{"game_version": "24", "franchise_type": "connected", "season": 1}'::jsonb
    ) INTO v_franchise_id;
    
    RAISE NOTICE 'Created sample franchise with ID: %', v_franchise_id;
  ELSE
    RAISE NOTICE 'Madden X server not found, skipping sample franchise creation';
  END IF;
END $$; 