-- Link Discord to servers/franchises/teams and record managers/active context

-- Add Discord guild id to servers
alter table if exists public.servers
  add column if not exists discord_guild_id text;

create index if not exists idx_servers_discord_guild_id on public.servers(discord_guild_id);

-- Add Discord franchise role & optional category/channel mapping
alter table if exists public.franchises
  add column if not exists discord_franchise_role_id text,
  add column if not exists discord_category_id text;

-- Add Discord composite role id to teams (e.g., [FR Alpha] KC)
alter table if exists public.teams
  add column if not exists discord_role_id text,
  add column if not exists abbreviation text;

create index if not exists idx_teams_franchise_abbrev on public.teams(franchise_id, abbreviation);

-- Team managers (one row per team per franchise; one primary)
create table if not exists public.team_managers (
  franchise_id uuid references public.franchises(id) on delete cascade,
  team_id uuid references public.teams(id) on delete cascade,
  user_id uuid references public.user_profiles(id) on delete set null,
  discord_id text not null,
  is_primary boolean default true,
  assigned_at timestamptz default now(),
  primary key (franchise_id, team_id)
);

-- Active context per user (for nickname suffix)
create table if not exists public.user_active_context (
  user_id uuid references public.user_profiles(id) on delete cascade primary key,
  franchise_id uuid references public.franchises(id) on delete cascade,
  team_id uuid references public.teams(id) on delete cascade,
  updated_at timestamptz default now()
);

-- Fast lookup by Discord id
create index if not exists idx_user_profiles_discord_id on public.user_profiles(discord_id);


