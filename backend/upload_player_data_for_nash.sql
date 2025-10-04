-- Upload player data for Madden League Alpha server
-- Run this AFTER creating the servers with the previous script

-- Step 1: Get the server ID for Madden League Alpha
SELECT id, name FROM servers 
WHERE name = 'Madden League Alpha' 
AND owner_id = 'e050e2da-4b3a-4a7b-91d1-fda1be112ee2';

-- Step 2: Insert player data for Madden League Alpha
INSERT INTO json_uploads (user_id, payload, uploaded_at) VALUES (
  'e050e2da-4b3a-4a7b-91d1-fda1be112ee2',
  '[
    {
      "id": "mahomes",
      "firstName": "Patrick",
      "lastName": "Mahomes",
      "position": "QB",
      "playerBestOvr": 99,
      "playerSchemeOvr": 99,
      "age": 28,
      "team": "Chiefs",
      "isFreeAgent": false,
      "teamId": 1,
      "franchiseId": "franchise-1",
      "speedRating": 88,
      "throwPowerRating": 99,
      "awareRating": 98,
      "height": 75,
      "weight": 225,
      "college": "Texas Tech"
    },
    {
      "id": "kelce",
      "firstName": "Travis",
      "lastName": "Kelce",
      "position": "TE",
      "playerBestOvr": 98,
      "playerSchemeOvr": 98,
      "age": 34,
      "team": "Chiefs",
      "isFreeAgent": false,
      "teamId": 1,
      "franchiseId": "franchise-1",
      "speedRating": 85,
      "catchRating": 98,
      "awareRating": 96,
      "height": 77,
      "weight": 260,
      "college": "Cincinnati"
    },
    {
      "id": "jones",
      "firstName": "Chris",
      "lastName": "Jones",
      "position": "DT",
      "playerBestOvr": 96,
      "playerSchemeOvr": 96,
      "age": 29,
      "team": "Chiefs",
      "isFreeAgent": false,
      "teamId": 1,
      "franchiseId": "franchise-1",
      "speedRating": 75,
      "strengthRating": 95,
      "awareRating": 92,
      "height": 78,
      "weight": 310,
      "college": "Mississippi State"
    },
    {
      "id": "purdy",
      "firstName": "Brock",
      "lastName": "Purdy",
      "position": "QB",
      "playerBestOvr": 87,
      "playerSchemeOvr": 87,
      "age": 24,
      "team": "49ers",
      "isFreeAgent": false,
      "teamId": 2,
      "franchiseId": "franchise-1",
      "speedRating": 82,
      "throwPowerRating": 85,
      "awareRating": 84,
      "height": 73,
      "weight": 220,
      "college": "Iowa State"
    },
    {
      "id": "mccaffrey",
      "firstName": "Christian",
      "lastName": "McCaffrey",
      "position": "RB",
      "playerBestOvr": 97,
      "playerSchemeOvr": 97,
      "age": 27,
      "team": "49ers",
      "isFreeAgent": false,
      "teamId": 2,
      "franchiseId": "franchise-1",
      "speedRating": 95,
      "awareRating": 95,
      "height": 71,
      "weight": 205,
      "college": "Stanford"
    },
    {
      "id": "bosa",
      "firstName": "Nick",
      "lastName": "Bosa",
      "position": "DE",
      "playerBestOvr": 98,
      "playerSchemeOvr": 98,
      "age": 26,
      "team": "49ers",
      "isFreeAgent": false,
      "teamId": 2,
      "franchiseId": "franchise-1",
      "speedRating": 84,
      "strengthRating": 92,
      "awareRating": 94,
      "height": 76,
      "weight": 266,
      "college": "Ohio State"
    },
    {
      "id": "hurts",
      "firstName": "Jalen",
      "lastName": "Hurts",
      "position": "QB",
      "playerBestOvr": 88,
      "playerSchemeOvr": 88,
      "age": 25,
      "team": "Eagles",
      "isFreeAgent": false,
      "teamId": 3,
      "franchiseId": "franchise-1",
      "speedRating": 89,
      "throwPowerRating": 88,
      "awareRating": 87,
      "height": 73,
      "weight": 223,
      "college": "Alabama/Oklahoma"
    },
    {
      "id": "brown",
      "firstName": "A.J.",
      "lastName": "Brown",
      "position": "WR",
      "playerBestOvr": 94,
      "playerSchemeOvr": 94,
      "age": 26,
      "team": "Eagles",
      "isFreeAgent": false,
      "teamId": 3,
      "franchiseId": "franchise-1",
      "speedRating": 92,
      "catchRating": 95,
      "awareRating": 92,
      "height": 73,
      "weight": 226,
      "college": "Ole Miss"
    }
  ]'::jsonb,
  NOW()
);

-- Step 3: Verify the data was uploaded
SELECT id, user_id, server_id, data_type, uploaded_at 
FROM json_uploads 
WHERE user_id = 'e050e2da-4b3a-4a7b-91d1-fda1be112ee2';
