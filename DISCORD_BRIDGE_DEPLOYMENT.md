# Discord Bridge Deployment Guide

This guide covers deploying the Discord Bridge Edge Function and database migrations for the Franchise Player app.

## Prerequisites

- Supabase CLI installed and configured
- Access to your Supabase project
- Discord bot application created

## 1. Database Migration

### Apply the Migration
```bash
# From project root
supabase db push
```

Or manually apply via Supabase Studio:
1. Go to SQL Editor
2. Run the contents of `supabase/migrations/20250826_discord_link.sql`

### Verify Migration
```sql
-- Check new columns were added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'servers' 
AND column_name LIKE '%discord%';

-- Check new tables were created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('team_managers', 'user_active_context');
```

## 2. Environment Variables

### Set FP_BRIDGE_SECRET
1. Go to Supabase Dashboard → Settings → Functions
2. Find the `discord-bridge` function
3. Add environment variable:
   ```
   FP_BRIDGE_SECRET=your-random-long-secret-here
   ```

### Generate a Secure Secret
```bash
# Generate a 64-character random secret
openssl rand -hex 32
```

## 3. Deploy Edge Function

### Deploy the Function
```bash
# From project root
supabase functions deploy discord-bridge
```

### Verify Deployment
```bash
# Check function status
supabase functions list

# Test the endpoint (replace with your actual URL)
curl -X POST https://your-project.supabase.co/functions/v1/discord-bridge/register_franchise \
  -H "Content-Type: application/json" \
  -H "X-FP-Timestamp: $(date +%s)" \
  -H "X-FP-Signature: test" \
  -d '{"test": "data"}'
```

## 4. Function Endpoints

### Base URL
```
https://your-project.supabase.co/functions/v1/discord-bridge
```

### Available Endpoints

#### POST /register_franchise
Registers a franchise and its team roles in Discord.

**Headers Required:**
- `X-FP-Timestamp`: Unix timestamp (seconds)
- `X-FP-Signature`: HMAC-SHA256 signature
- `Content-Type: application/json`

**Request Body:**
```json
{
  "guild_id": "123456789012345678",
  "franchise": {
    "name": "Alpha Franchise"
  },
  "franchise_role_id": "987654321098765432",
  "team_roles": [
    {"team_code": "KC", "role_id": "111111111111111111"},
    {"team_code": "BUF", "role_id": "222222222222222222"}
  ]
}
```

**Response:**
```json
{
  "ok": true,
  "server_id": "uuid-here",
  "franchise_id": "uuid-here"
}
```

#### POST /claim_team
Assigns a Discord user to manage a team.

**Request Body:**
```json
{
  "guild_id": "123456789012345678",
  "franchise_name": "Alpha Franchise",
  "team_code": "KC",
  "discord_user_id": "333333333333333333"
}
```

**Response:**
```json
{
  "ok": true,
  "franchise_id": "uuid-here",
  "team_id": "uuid-here",
  "user_id": "uuid-here",
  "nickname_suffix": "〔KC·Alpha Franchise〕"
}
```

#### POST /set_active
Sets a user's active franchise/team context for nickname display.

**Request Body:**
```json
{
  "discord_user_id": "333333333333333333",
  "guild_id": "123456789012345678",
  "franchise_name": "Alpha Franchise",
  "team_code": "KC"
}
```

**Response:**
```json
{
  "ok": true,
  "nickname_suffix": "〔KC·Alpha Franchise〕"
}
```

## 5. Security Implementation

### HMAC Signature Generation (Python Example)
```python
import hmac
import hashlib
import time
import json

def generate_signature(secret: str, timestamp: int, body: str) -> str:
    message = f"{timestamp}.{body}"
    signature = hmac.new(
        secret.encode('utf-8'),
        message.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()
    return signature

# Usage
timestamp = int(time.time())
body = json.dumps({"test": "data"})
signature = generate_signature("your-secret", timestamp, body)

headers = {
    "X-FP-Timestamp": str(timestamp),
    "X-FP-Signature": signature,
    "Content-Type": "application/json"
}
```

### Security Features
- **Timestamp validation**: Rejects requests older than 300 seconds
- **HMAC verification**: Ensures request authenticity
- **Service role access**: Bypasses RLS for bot operations
- **Input validation**: Validates all required fields

## 6. Testing

### Test Script
Create a test script to verify all endpoints:

```python
import requests
import hmac
import hashlib
import time
import json

BASE_URL = "https://your-project.supabase.co/functions/v1/discord-bridge"
SECRET = "your-fp-bridge-secret"

def make_request(endpoint: str, data: dict):
    timestamp = int(time.time())
    body = json.dumps(data)
    
    # Generate signature
    message = f"{timestamp}.{body}"
    signature = hmac.new(
        SECRET.encode('utf-8'),
        message.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()
    
    headers = {
        "X-FP-Timestamp": str(timestamp),
        "X-FP-Signature": signature,
        "Content-Type": "application/json"
    }
    
    response = requests.post(f"{BASE_URL}/{endpoint}", 
                           headers=headers, 
                           data=body)
    return response.json()

# Test endpoints
print("Testing register_franchise...")
result = make_request("register_franchise", {
    "guild_id": "123456789012345678",
    "franchise": {"name": "Test Franchise"},
    "franchise_role_id": "987654321098765432",
    "team_roles": [
        {"team_code": "KC", "role_id": "111111111111111111"}
    ]
})
print(result)
```

## 7. Monitoring

### Function Logs
```bash
# View function logs
supabase functions logs discord-bridge

# Follow logs in real-time
supabase functions logs discord-bridge --follow
```

### Database Monitoring
```sql
-- Check team managers
SELECT tm.*, up.display_name, t.name as team_name, f.name as franchise_name
FROM team_managers tm
JOIN user_profiles up ON tm.user_id = up.id
JOIN teams t ON tm.team_id = t.id
JOIN franchises f ON tm.franchise_id = f.id;

-- Check active contexts
SELECT uac.*, up.display_name, t.name as team_name, f.name as franchise_name
FROM user_active_context uac
JOIN user_profiles up ON uac.user_id = up.id
JOIN teams t ON uac.team_id = t.id
JOIN franchises f ON uac.franchise_id = f.id;
```

## 8. Troubleshooting

### Common Issues

**401 Unauthorized**
- Check `FP_BRIDGE_SECRET` is set correctly
- Verify timestamp is within 300 seconds
- Ensure signature generation matches the function

**404 Not Found**
- Verify function is deployed: `supabase functions list`
- Check endpoint URL is correct
- Ensure database migration was applied

**400 Bad Request**
- Check request payload format
- Verify all required fields are present
- Ensure Discord user exists in `user_profiles`

### Debug Queries
```sql
-- Check Discord guild mappings
SELECT s.name, s.discord_guild_id, f.name as franchise_name, f.discord_franchise_role_id
FROM servers s
LEFT JOIN franchises f ON s.id = f.server_id;

-- Check team role mappings
SELECT t.name, t.abbreviation, t.discord_role_id, f.name as franchise_name
FROM teams t
JOIN franchises f ON t.franchise_id = f.id
WHERE t.discord_role_id IS NOT NULL;
```

## 9. Integration with Discord Bot

The Discord bot should:

1. **Register franchises** when setting up new franchise channels
2. **Claim teams** when users use team assignment commands
3. **Set active context** when users switch between franchises
4. **Use nickname suffixes** to display user's current team/franchise

### Example Bot Integration
```python
# Register a new franchise
response = make_request("register_franchise", {
    "guild_id": str(interaction.guild_id),
    "franchise": {"name": "Alpha Franchise"},
    "franchise_role_id": str(franchise_role.id),
    "team_roles": [
        {"team_code": "KC", "role_id": str(kc_role.id)},
        {"team_code": "BUF", "role_id": str(buf_role.id)}
    ]
})

# Claim a team
response = make_request("claim_team", {
    "guild_id": str(interaction.guild_id),
    "franchise_name": "Alpha Franchise",
    "team_code": "KC",
    "discord_user_id": str(interaction.user.id)
})

# Set active context
response = make_request("set_active", {
    "discord_user_id": str(interaction.user.id),
    "guild_id": str(interaction.guild_id),
    "franchise_name": "Alpha Franchise",
    "team_code": "KC"
})

# Update nickname with suffix
nickname_suffix = response.get("nickname_suffix", "")
new_nickname = f"{interaction.user.display_name} {nickname_suffix}"
await interaction.guild.get_member(interaction.user.id).edit(nick=new_nickname)
```

This deployment guide provides everything needed to get the Discord Bridge up and running with your Franchise Player app!


