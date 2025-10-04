-- Create a test franchise for the Madden X server
-- Run this script in your Supabase SQL editor

-- First, check if the Madden X server exists
DO $$
DECLARE
    v_madden_server_id uuid;
    v_franchise_id uuid;
BEGIN
    -- Get the Madden X server ID
    SELECT id INTO v_madden_server_id FROM public.servers WHERE name = 'Madden X' LIMIT 1;
    
    IF v_madden_server_id IS NULL THEN
        RAISE NOTICE 'Madden X server not found. Please run the create_madden_x_server.sql script first.';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Found Madden X server with ID: %', v_madden_server_id;
    
    -- Create a test franchise using the function
    SELECT create_franchise_with_default_channels(
        v_madden_server_id,
        'Test Franchise 2024',
        'test_franchise_001',
        '{"game_version": "24", "franchise_type": "test", "season": 1, "owner": "test_user"}'::jsonb
    ) INTO v_franchise_id;
    
    RAISE NOTICE 'Created test franchise with ID: %', v_franchise_id;
    
    -- Add some sample metadata to the franchise
    UPDATE public.franchises 
    SET metadata = jsonb_build_object(
        'game_version', '24',
        'franchise_type', 'test',
        'season', 1,
        'owner', 'test_user',
        'created_date', now()::text,
        'description', 'A test franchise for development and testing purposes'
    )
    WHERE id = v_franchise_id;
    
    RAISE NOTICE 'Updated franchise metadata';
    
    -- Show the created franchise and its channels
    RAISE NOTICE 'Franchise details:';
    RAISE NOTICE '  Name: Test Franchise 2024';
    RAISE NOTICE '  External ID: test_franchise_001';
    RAISE NOTICE '  Server ID: %', v_madden_server_id;
    RAISE NOTICE '  Franchise ID: %', v_franchise_id;
    
    RAISE NOTICE 'Default channels created:';
    RAISE NOTICE '  - general (text)';
    RAISE NOTICE '  - trades (text)';
    RAISE NOTICE '  - draft (text)';
    RAISE NOTICE '  - game-discussion (text)';
    RAISE NOTICE '  - announcements (text)';
    RAISE NOTICE '  - General Voice (voice)';
    RAISE NOTICE '  - Game Night (voice)';
    
END $$; 