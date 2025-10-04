-- Create real servers for nashabramsx@gmail.com account
-- Run this in your Supabase SQL editor

-- First, let's find the user ID for nashabramsx@gmail.com
-- You'll need to replace 'USER_ID_HERE' with the actual UUID from auth.users table

-- Step 1: Find the user ID (run this first to get the UUID)
SELECT id, email FROM auth.users WHERE email = 'nashabramsx@gmail.com';

-- Step 2: Create the servers with the actual user ID
-- Let Supabase generate UUIDs automatically by not specifying the id field
WITH new_servers AS (
  INSERT INTO servers (name, description, icon, color, owner_id, created_at, updated_at) VALUES
  ('Madden League Alpha', 'Main competitive league', '🏈', '#FF6B35', 'e050e2da-4b3a-4a7b-91d1-fda1be112ee2', NOW(), NOW()),
  ('Franchise Player Support', 'Support and help server', '🛠️', '#4ECDC4', 'e050e2da-4b3a-4a7b-91d1-fda1be112ee2', NOW(), NOW()),
  ('Casual Gaming', 'Relaxed gameplay server', '🎮', '#45B7D1', 'e050e2da-4b3a-4a7b-91d1-fda1be112ee2', NOW(), NOW())
  RETURNING id, name
)
-- Step 3: Add the user as a member of these servers
INSERT INTO server_members (server_id, user_id, nickname, joined_at)
SELECT id, 'e050e2da-4b3a-4a7b-91d1-fda1be112ee2', NULL, NOW()
FROM new_servers;

-- Step 4: Verify the servers were created
SELECT s.*, sm.user_id 
FROM servers s 
LEFT JOIN server_members sm ON s.id = sm.server_id 
WHERE s.owner_id = 'e050e2da-4b3a-4a7b-91d1-fda1be112ee2';
