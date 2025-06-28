-- Users (profile info)
create table if not exists users (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  avatar_url text,
  bio text,
  created_at timestamptz default now()
);

-- Servers
create table if not exists servers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid references users(id) on delete cascade,
  created_at timestamptz default now()
);

-- Server Members
create table if not exists server_members (
  id uuid primary key default gen_random_uuid(),
  server_id uuid references servers(id) on delete cascade,
  user_id uuid references users(id) on delete cascade,
  role text default 'member',
  joined_at timestamptz default now(),
  unique (server_id, user_id)
);

-- Franchises
create table if not exists franchises (
  id uuid primary key default gen_random_uuid(),
  server_id uuid references servers(id) on delete cascade,
  name text not null,
  created_at timestamptz default now()
);

-- Channels
create table if not exists channels (
  id uuid primary key default gen_random_uuid(),
  franchise_id uuid references franchises(id) on delete cascade,
  name text not null,
  type text default 'text',
  created_at timestamptz default now()
);

-- Messages
create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  channel_id uuid references channels(id) on delete cascade,
  user_id uuid references users(id) on delete cascade,
  content text not null,
  created_at timestamptz default now()
);

-- Friends
create table if not exists friends (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  friend_id uuid references users(id) on delete cascade,
  status text check (status in ('pending', 'accepted', 'blocked')),
  created_at timestamptz default now(),
  unique (user_id, friend_id)
);

-- DMs (threads)
create table if not exists dms (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now()
);

-- DM Participants
create table if not exists dm_participants (
  id uuid primary key default gen_random_uuid(),
  dm_id uuid references dms(id) on delete cascade,
  user_id uuid references users(id) on delete cascade,
  joined_at timestamptz default now(),
  unique (dm_id, user_id)
);

-- DM Messages
create table if not exists dm_messages (
  id uuid primary key default gen_random_uuid(),
  dm_id uuid references dms(id) on delete cascade,
  user_id uuid references users(id) on delete cascade,
  content text not null,
  created_at timestamptz default now()
);

-- Roles
create table if not exists roles (
  id uuid primary key default gen_random_uuid(),
  server_id uuid references servers(id) on delete cascade,
  name text not null,
  permissions jsonb,
  created_at timestamptz default now()
);

-- Audit Logs
create table if not exists audit_logs (
  id uuid primary key default gen_random_uuid(),
  server_id uuid references servers(id) on delete cascade,
  user_id uuid references users(id) on delete cascade,
  action text not null,
  details jsonb,
  created_at timestamptz default now()
);

-- RLS policies and indexes would be added here for production 