-- Create franchise tables if they don't exist
-- Run this script in your Supabase SQL editor

-- Create franchises table
CREATE TABLE IF NOT EXISTS franchises (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    server_id UUID NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    external_id TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create franchise_channels table
CREATE TABLE IF NOT EXISTS franchise_channels (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    franchise_id UUID NOT NULL REFERENCES franchises(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'text' CHECK (type IN ('text', 'voice', 'video', 'category')),
    position INTEGER DEFAULT 0,
    livekit_room_id TEXT,
    voice_enabled BOOLEAN DEFAULT false,
    video_enabled BOOLEAN DEFAULT false,
    is_private BOOLEAN DEFAULT false,
    max_participants INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_franchises_server_id ON franchises(server_id);
CREATE INDEX IF NOT EXISTS idx_franchise_channels_franchise_id ON franchise_channels(franchise_id);
CREATE INDEX IF NOT EXISTS idx_franchise_channels_type ON franchise_channels(type);

-- Enable Row Level Security
ALTER TABLE franchises ENABLE ROW LEVEL SECURITY;
ALTER TABLE franchise_channels ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for franchises
CREATE POLICY "Allow users to view franchises in their servers" ON franchises
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM server_members 
            WHERE server_id = franchises.server_id 
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Allow server owners to create franchises" ON franchises
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM servers 
            WHERE id = franchises.server_id 
            AND owner_id = auth.uid()
        )
    );

CREATE POLICY "Allow server owners to update franchises" ON franchises
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM servers 
            WHERE id = franchises.server_id 
            AND owner_id = auth.uid()
        )
    );

CREATE POLICY "Allow server owners to delete franchises" ON franchises
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM servers 
            WHERE id = franchises.server_id 
            AND owner_id = auth.uid()
        )
    );

-- Create RLS policies for franchise_channels
CREATE POLICY "Allow users to view channels in their franchises" ON franchise_channels
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM franchises f
            JOIN server_members sm ON f.server_id = sm.server_id
            WHERE f.id = franchise_channels.franchise_id 
            AND sm.user_id = auth.uid()
        )
    );

CREATE POLICY "Allow server owners to create channels" ON franchise_channels
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM franchises f
            JOIN servers s ON f.server_id = s.id
            WHERE f.id = franchise_channels.franchise_id 
            AND s.owner_id = auth.uid()
        )
    );

CREATE POLICY "Allow server owners to update channels" ON franchise_channels
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM franchises f
            JOIN servers s ON f.server_id = s.id
            WHERE f.id = franchise_channels.franchise_id 
            AND s.owner_id = auth.uid()
        )
    );

CREATE POLICY "Allow server owners to delete channels" ON franchise_channels
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM franchises f
            JOIN servers s ON f.server_id = s.id
            WHERE f.id = franchise_channels.franchise_id 
            AND s.owner_id = auth.uid()
        )
    );

-- Create function to create franchise with default channels
CREATE OR REPLACE FUNCTION create_franchise_with_default_channels(
    p_server_id UUID,
    p_name TEXT,
    p_external_id TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'
) RETURNS UUID AS $$
DECLARE
    v_franchise_id UUID;
BEGIN
    -- Create the franchise
    INSERT INTO franchises (server_id, name, external_id, metadata)
    VALUES (p_server_id, p_name, p_external_id, p_metadata)
    RETURNING id INTO v_franchise_id;
    
    -- Create default channels
    INSERT INTO franchise_channels (franchise_id, name, type, position) VALUES
        (v_franchise_id, 'general', 'text', 0),
        (v_franchise_id, 'announcements', 'text', 1),
        (v_franchise_id, 'rules', 'text', 2),
        (v_franchise_id, 'lobby', 'voice', 3);
    
    RETURN v_franchise_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verify tables were created
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('franchises', 'franchise_channels')
ORDER BY table_name, ordinal_position;
