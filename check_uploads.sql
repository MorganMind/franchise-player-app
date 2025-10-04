-- Check uploaded roster data in Supabase
-- Run this in your Supabase SQL Editor

-- Get all uploads with basic info
SELECT 
    id,
    user_id,
    uploaded_at,
    jsonb_array_length(payload) as player_count
FROM json_uploads 
ORDER BY uploaded_at DESC;

-- Get detailed breakdown by franchise for each upload
WITH upload_details AS (
    SELECT 
        id as upload_id,
        user_id,
        uploaded_at,
        jsonb_array_elements(payload) as player
    FROM json_uploads
)
SELECT 
    upload_id,
    user_id,
    uploaded_at,
    player->>'franchiseId' as franchise_id,
    COUNT(*) as player_count,
    MIN(CONCAT(player->>'firstName', ' ', player->>'lastName')) as sample_player
FROM upload_details 
GROUP BY upload_id, user_id, uploaded_at, player->>'franchiseId'
ORDER BY uploaded_at DESC, franchise_id;

-- Get total players by franchise across all uploads
WITH all_players AS (
    SELECT 
        jsonb_array_elements(payload) as player
    FROM json_uploads
)
SELECT 
    player->>'franchiseId' as franchise_id,
    COUNT(*) as total_players,
    COUNT(DISTINCT player->>'team') as unique_teams,
    AVG((player->>'playerBestOvr')::int) as avg_overall_rating,
    MIN(CONCAT(player->>'firstName', ' ', player->>'lastName')) as sample_player
FROM all_players 
GROUP BY player->>'franchiseId'
ORDER BY total_players DESC;

-- Get recent uploads with player samples
SELECT 
    id,
    user_id,
    uploaded_at,
    jsonb_array_length(payload) as total_players,
    jsonb_array_elements(payload)->>'franchiseId' as franchise_id,
    CONCAT(jsonb_array_elements(payload)->>'firstName', ' ', jsonb_array_elements(payload)->>'lastName') as player_name,
    jsonb_array_elements(payload)->>'position' as position,
    jsonb_array_elements(payload)->>'playerBestOvr' as overall_rating
FROM json_uploads 
ORDER BY uploaded_at DESC
LIMIT 50;
