# Discord Bot Bridge - Complete Code Files

## Overview
This document contains all the code files needed to integrate a Discord bot with the Franchise Player app, including the Supabase Edge Function bridge, database schema, and bot implementation.

---

## 1. Supabase Edge Function - Discord Bridge

**File: `supabase/functions/discord-bridge/index.ts`**

```typescript
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

// HMAC-SHA256 signature verification
async function hmacSha256(message: string, secret: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(message));
  return Array.from(new Uint8Array(signature))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}

async function verify(req: Request): Promise<boolean> {
  const signature = req.headers.get("x-discord-signature");
  const timestamp = req.headers.get("x-discord-timestamp");
  
  if (!signature || !timestamp) return false;
  
  const body = await req.text();
  const expectedSignature = await hmacSha256(timestamp + body, Deno.env.get("DISCORD_BOT_SECRET")!);
  
  return signature === expectedSignature;
}

async function handleRegisterFranchise(req: Request) {
  const { server_id, franchise_name, franchise_id } = await req.json();
  
  const { data, error } = await supabase
    .from('franchises')
    .insert({
      id: franchise_id,
      server_id: server_id,
      name: franchise_name,
      created_at: new Date().toISOString()
    });
    
  if (error) throw error;
  return { ok: true, franchise: data };
}

async function handleClaimTeam(req: Request) {
  const { franchise_id, team_name, discord_user_id } = await req.json();
  
  // Get or create user profile
  const { data: userProfile } = await supabase
    .from('user_profiles')
    .select('*')
    .eq('discord_id', discord_user_id)
    .single();
    
  if (!userProfile) {
    throw new Error('User profile not found');
  }
  
  // Create team
  const { data: team, error } = await supabase
    .from('teams')
    .insert({
      franchise_id: franchise_id,
      name: team_name,
      owner_id: userProfile.id
    })
    .select()
    .single();
    
  if (error) throw error;
  return { ok: true, team };
}

async function handleSetActive(req: Request) {
  const { franchise_id, discord_user_id } = await req.json();
  
  const { data: userProfile } = await supabase
    .from('user_profiles')
    .select('*')
    .eq('discord_id', discord_user_id)
    .single();
    
  if (!userProfile) {
    throw new Error('User profile not found');
  }
  
  // Update user's active franchise
  const { error } = await supabase
    .from('user_profiles')
    .update({ active_franchise_id: franchise_id })
    .eq('id', userProfile.id);
    
  if (error) throw error;
  return { ok: true };
}

serve(async (req) => {
  try {
    const url = new URL(req.url);
    
    if (req.method === "OPTIONS") {
      return new Response(null, {
        status: 200,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-discord-signature, x-discord-timestamp",
          "Access-Control-Allow-Methods": "POST, GET, OPTIONS, PUT, DELETE",
        },
      });
    }

    // Verify Discord signature
    if (!(await verify(req))) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (req.method === "POST" && url.pathname.endsWith("/register_franchise")) {
      const result = await handleRegisterFranchise(req);
      return new Response(JSON.stringify(result), {
        headers: { "Content-Type": "application/json" },
      });
    }

    if (req.method === "POST" && url.pathname.endsWith("/claim_team")) {
      const result = await handleClaimTeam(req);
      return new Response(JSON.stringify(result), {
        headers: { "Content-Type": "application/json" },
      });
    }

    if (req.method === "POST" && url.pathname.endsWith("/set_active")) {
      const result = await handleSetActive(req);
      return new Response(JSON.stringify(result), {
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ error: "Not found" }), {
      status: 404,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
```

---

## 2. Database Schema

**File: `supabase/migrations/20250826_discord_link.sql`**

```sql
-- Create user_profiles table
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  discord_id TEXT UNIQUE,
  username TEXT,
  display_name TEXT,
  avatar_url TEXT,
  active_franchise_id UUID REFERENCES public.franchises(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create servers table
CREATE TABLE IF NOT EXISTS public.servers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  discord_server_id TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  icon_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create server_members table
CREATE TABLE IF NOT EXISTS public.server_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  server_id UUID REFERENCES public.servers(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member',
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(server_id, user_id)
);

-- Create franchises table
CREATE TABLE IF NOT EXISTS public.franchises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  server_id UUID REFERENCES public.servers(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create teams table
CREATE TABLE IF NOT EXISTS public.teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  franchise_id UUID REFERENCES public.franchises(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  owner_id UUID REFERENCES public.user_profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create players table
CREATE TABLE IF NOT EXISTS public.players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  position TEXT NOT NULL,
  overall INTEGER,
  age INTEGER,
  dev_trait TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.servers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.server_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.franchises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own profile" ON public.user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Server members can view server data" ON public.servers
  FOR SELECT USING (
    id IN (
      SELECT server_id FROM public.server_members 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Server members can view franchises" ON public.franchises
  FOR SELECT USING (
    server_id IN (
      SELECT server_id FROM public.server_members 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Team owners can manage their teams" ON public.teams
  FOR ALL USING (owner_id = auth.uid());

CREATE POLICY "Team owners can manage their players" ON public.players
  FOR ALL USING (
    team_id IN (
      SELECT id FROM public.teams WHERE owner_id = auth.uid()
    )
  );
```

---

## 3. Discord Bot Implementation

**File: `bot/index.js`**

```javascript
const { Client, GatewayIntentBits, EmbedBuilder } = require('discord.js');
const crypto = require('crypto');

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMembers,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent
  ]
});

// Configuration
const CONFIG = {
  SUPABASE_URL: process.env.FRANCHISE_SUPABASE_URL,
  SUPABASE_ANON_KEY: process.env.FRANCHISE_SUPABASE_ANON_KEY,
  BRIDGE_URL: process.env.FRANCHISE_SUPABASE_URL + '/functions/v1/discord-bridge',
  VALUATION_URL: process.env.FRANCHISE_SUPABASE_URL + '/functions/v1/valuation',
  BOT_SECRET: process.env.DISCORD_BOT_SECRET
};

// HMAC signature generation
function generateSignature(timestamp, body, secret) {
  return crypto.createHmac('sha256', secret).update(timestamp + body).digest('hex');
}

// Make authenticated request to bridge
async function makeBridgeRequest(endpoint, data) {
  const timestamp = Math.floor(Date.now() / 1000).toString();
  const body = JSON.stringify(data);
  const signature = generateSignature(timestamp, body, CONFIG.BOT_SECRET);
  
  const response = await fetch(CONFIG.BRIDGE_URL + endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-discord-signature': signature,
      'x-discord-timestamp': timestamp
    },
    body: body
  });
  
  return await response.json();
}

// Make request to valuation function
async function calculatePlayerValue(ovr, age, position, devTrait) {
  const response = await fetch(CONFIG.VALUATION_URL + '/compute', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${CONFIG.SUPABASE_ANON_KEY}`
    },
    body: JSON.stringify({
      ovr: ovr,
      age: age,
      pos: position,
      dev: devTrait
    })
  });
  
  return await response.json();
}

// Bot commands
client.on('interactionCreate', async (interaction) => {
  if (!interaction.isChatInputCommand()) return;

  if (interaction.commandName === 'register-franchise') {
    const franchiseName = interaction.options.getString('name');
    const franchiseId = crypto.randomUUID();
    
    try {
      const result = await makeBridgeRequest('/register_franchise', {
        server_id: interaction.guild.id,
        franchise_name: franchiseName,
        franchise_id: franchiseId
      });
      
      const embed = new EmbedBuilder()
        .setTitle('Franchise Registered!')
        .setDescription(`Franchise "${franchiseName}" has been registered successfully.`)
        .setColor(0x00ff00);
        
      await interaction.reply({ embeds: [embed] });
    } catch (error) {
      await interaction.reply({ content: `Error: ${error.message}`, ephemeral: true });
    }
  }

  if (interaction.commandName === 'claim-team') {
    const teamName = interaction.options.getString('name');
    const franchiseId = interaction.options.getString('franchise-id');
    
    try {
      const result = await makeBridgeRequest('/claim_team', {
        franchise_id: franchiseId,
        team_name: teamName,
        discord_user_id: interaction.user.id
      });
      
      const embed = new EmbedBuilder()
        .setTitle('Team Claimed!')
        .setDescription(`You have successfully claimed "${teamName}".`)
        .setColor(0x00ff00);
        
      await interaction.reply({ embeds: [embed] });
    } catch (error) {
      await interaction.reply({ content: `Error: ${error.message}`, ephemeral: true });
    }
  }

  if (interaction.commandName === 'value-player') {
    const ovr = interaction.options.getInteger('overall');
    const age = interaction.options.getInteger('age');
    const position = interaction.options.getString('position');
    const devTrait = interaction.options.getString('dev-trait');
    
    try {
      const result = await calculatePlayerValue(ovr, age, position, devTrait);
      
      if (result.ok) {
        const embed = new EmbedBuilder()
          .setTitle('Player Valuation')
          .addFields(
            { name: 'Value', value: `${result.value.toFixed(1)} points`, inline: true },
            { name: 'Draft Pick', value: `Round ${result.round}, Pick ${result.pick_in_round}`, inline: true },
            { name: 'Overall Pick', value: `#${result.nearest_pick}`, inline: true }
          )
          .setColor(0x0099ff);
          
        await interaction.reply({ embeds: [embed] });
      } else {
        await interaction.reply({ content: `Error: ${result.error}`, ephemeral: true });
      }
    } catch (error) {
      await interaction.reply({ content: `Error: ${error.message}`, ephemeral: true });
    }
  }
});

// Bot ready event
client.once('ready', () => {
  console.log(`Bot is ready! Logged in as ${client.user.tag}`);
});

// Login
client.login(process.env.DISCORD_BOT_TOKEN);
```

---

## 4. Bot Package.json

**File: `bot/package.json`**

```json
{
  "name": "franchise-player-bot",
  "version": "1.0.0",
  "description": "Discord bot for Franchise Player app integration",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js"
  },
  "dependencies": {
    "discord.js": "^14.14.1",
    "node-fetch": "^2.7.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.2"
  },
  "engines": {
    "node": ">=16.0.0"
  }
}
```

---

## 5. Bot Environment Variables

**File: `bot/.env`**

```bash
# Discord Bot Configuration
DISCORD_BOT_TOKEN=your_discord_bot_token
DISCORD_BOT_SECRET=your_discord_bot_secret

# Main Franchise Player App Supabase
FRANCHISE_SUPABASE_URL=https://fxbpsuisqzffyggihvin.supabase.co
FRANCHISE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ4YnBzdWlzcXpmZnlnZ2lodmluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEwMzkwNTMsImV4cCI6MjA2NjYxNTA1M30.HxGXe3Jn7HV6GFeLXtvi5tTeqPYG092ZstmrEkpA8mw

# Bot's Own Supabase (if different)
BOT_SUPABASE_URL=https://your-bot-project.supabase.co
BOT_SUPABASE_ANON_KEY=your_bot_anon_key
BOT_SUPABASE_SERVICE_KEY=your_bot_service_key

# Valuation Function URL
VALUATION_FUNCTION_URL=https://fxbpsuisqzffyggihvin.supabase.co/functions/v1/valuation
```

---

## 6. Bot Slash Commands Registration

**File: `bot/register-commands.js`**

```javascript
const { REST, Routes } = require('discord.js');

const commands = [
  {
    name: 'register-franchise',
    description: 'Register a new franchise',
    options: [
      {
        name: 'name',
        description: 'Name of the franchise',
        type: 3, // STRING
        required: true
      }
    ]
  },
  {
    name: 'claim-team',
    description: 'Claim a team in a franchise',
    options: [
      {
        name: 'name',
        description: 'Name of the team',
        type: 3, // STRING
        required: true
      },
      {
        name: 'franchise-id',
        description: 'ID of the franchise',
        type: 3, // STRING
        required: true
      }
    ]
  },
  {
    name: 'value-player',
    description: 'Calculate player value',
    options: [
      {
        name: 'overall',
        description: 'Player overall rating',
        type: 4, // INTEGER
        required: true
      },
      {
        name: 'age',
        description: 'Player age',
        type: 4, // INTEGER
        required: true
      },
      {
        name: 'position',
        description: 'Player position',
        type: 3, // STRING
        required: true,
        choices: [
          { name: 'QB', value: 'QB' },
          { name: 'HB', value: 'HB' },
          { name: 'WR', value: 'WR' },
          { name: 'TE', value: 'TE' },
          { name: 'LT', value: 'LT' },
          { name: 'LG', value: 'LG' },
          { name: 'C', value: 'C' },
          { name: 'RG', value: 'RG' },
          { name: 'RT', value: 'RT' },
          { name: 'LE', value: 'LE' },
          { name: 'RE', value: 'RE' },
          { name: 'DT', value: 'DT' },
          { name: 'LOLB', value: 'LOLB' },
          { name: 'MLB', value: 'MLB' },
          { name: 'ROLB', value: 'ROLB' },
          { name: 'CB', value: 'CB' },
          { name: 'FS', value: 'FS' },
          { name: 'SS', value: 'SS' },
          { name: 'K', value: 'K' },
          { name: 'P', value: 'P' }
        ]
      },
      {
        name: 'dev-trait',
        description: 'Development trait',
        type: 3, // STRING
        required: true,
        choices: [
          { name: 'Normal', value: 'Normal' },
          { name: 'Star', value: 'Star' },
          { name: 'Superstar', value: 'Superstar' },
          { name: 'X-Factor', value: 'X-Factor' }
        ]
      }
    ]
  }
];

const rest = new REST({ version: '10' }).setToken(process.env.DISCORD_BOT_TOKEN);

(async () => {
  try {
    console.log('Started refreshing application (/) commands.');

    await rest.put(
      Routes.applicationCommands(process.env.DISCORD_CLIENT_ID),
      { body: commands },
    );

    console.log('Successfully reloaded application (/) commands.');
  } catch (error) {
    console.error(error);
  }
})();
```

---

## 7. Flutter Discord Service

**File: `frontend/lib/services/discord_service.dart`**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class DiscordService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Check if the current user signed up with Discord
  static bool isDiscordUser(User? user) {
    return user?.appMetadata['provider'] == 'discord';
  }

  /// Get Discord ID for the current user
  static String? getDiscordId(User? user) {
    if (user?.appMetadata['provider'] == 'discord') {
      return user?.userMetadata['sub'] as String?;
    }
    return null;
  }

  /// Get Discord username from user metadata
  static String? getDiscordUsername(User? user) {
    return user?.userMetadata['preferred_username'] as String?;
  }

  /// Get Discord avatar URL from user metadata
  static String? getDiscordAvatar(User? user) {
    return user?.userMetadata['avatar_url'] as String?;
  }

  /// Get Discord full name from user metadata
  static String? getDiscordFullName(User? user) {
    return user?.userMetadata['full_name'] as String?;
  }

  /// Check if a user profile has a Discord ID
  static bool hasDiscordId(Map<String, dynamic> userProfile) {
    return userProfile['discord_id'] != null && userProfile['discord_id'].toString().isNotEmpty;
  }

  /// Format Discord username with discriminator if available
  static String formatDiscordUsername(String? username, String? discriminator) {
    if (username == null) return 'Unknown User';
    if (discriminator != null && discriminator != '0') {
      return '$username#$discriminator';
    }
    return username;
  }

  /// Get Discord user info from Supabase auth user
  static Map<String, dynamic> getDiscordUserInfo(User? user) {
    return {
      'is_discord_user': isDiscordUser(user),
      'discord_id': getDiscordId(user),
      'username': getDiscordUsername(user),
      'full_name': getDiscordFullName(user),
      'avatar_url': getDiscordAvatar(user),
    };
  }

  /// Check if the current user can link Discord account
  static Future<bool> canLinkDiscord() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Check if user already has Discord linked
      final response = await _supabase
          .from('user_profiles')
          .select('discord_id')
          .eq('id', user.id)
          .single();

      return response['discord_id'] == null;
    } catch (e) {
      print('Error checking Discord link status: $e');
      return false;
    }
  }

  /// Get Discord profile information for display
  static Map<String, String> getDiscordProfileInfo(User? user) {
    final info = getDiscordUserInfo(user);
    return {
      'username': info['username'] ?? 'Not linked',
      'discord_id': info['discord_id'] ?? 'Not linked',
      'avatar_url': info['avatar_url'] ?? '',
    };
  }
}
```

---

## 8. Deployment Script

**File: `deploy-bot.sh`**

```bash
#!/bin/bash

# Deploy Discord Bot Bridge
echo "Deploying Discord Bot Bridge..."
supabase functions deploy discord-bridge

# Deploy Valuation Function
echo "Deploying Valuation Function..."
supabase functions deploy valuation

# Apply database migrations
echo "Applying database migrations..."
supabase db push

# Register Discord slash commands
echo "Registering Discord commands..."
cd bot
node register-commands.js

echo "Deployment complete!"
```

---

## 9. Docker Configuration for Bot

**File: `bot/Dockerfile`**

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

---

## 10. Bot Docker Compose

**File: `bot/docker-compose.yml`**

```yaml
version: '3.8'

services:
  bot:
    build: .
    container_name: franchise-player-bot
    restart: unless-stopped
    environment:
      - DISCORD_BOT_TOKEN=${DISCORD_BOT_TOKEN}
      - DISCORD_BOT_SECRET=${DISCORD_BOT_SECRET}
      - FRANCHISE_SUPABASE_URL=${FRANCHISE_SUPABASE_URL}
      - FRANCHISE_SUPABASE_ANON_KEY=${FRANCHISE_SUPABASE_ANON_KEY}
      - BOT_SUPABASE_URL=${BOT_SUPABASE_URL}
      - BOT_SUPABASE_ANON_KEY=${BOT_SUPABASE_ANON_KEY}
    volumes:
      - ./logs:/app/logs
```

---

## Setup Instructions

1. **Deploy Supabase Functions:**
   ```bash
   supabase functions deploy discord-bridge
   supabase functions deploy valuation
   ```

2. **Apply Database Schema:**
   ```bash
   supabase db push
   ```

3. **Setup Discord Bot:**
   ```bash
   cd bot
   npm install
   cp .env.example .env
   # Edit .env with your tokens
   node register-commands.js
   npm start
   ```

4. **Environment Variables:**
   - Set `DISCORD_BOT_TOKEN` in Supabase Edge Function secrets
   - Set `DISCORD_BOT_SECRET` in Supabase Edge Function secrets
   - Configure bot's `.env` file with all required variables

5. **Test Integration:**
   - Use `/register-franchise` command in Discord
   - Use `/claim-team` command to claim a team
   - Use `/value-player` command to test valuation integration
