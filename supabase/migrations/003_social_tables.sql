-- =============================================================
-- Streetlore — Social tables (filled by REAL app users)
-- Run this in the Supabase SQL Editor (Dashboard → SQL → New query)
-- These tables power: live place chat, leaderboard, community routes.
-- They start EMPTY and fill up as real people use the app.
-- Note: app users are anonymous (no Supabase Auth in the main app),
-- so inserts are allowed for anon. Reads are public.
-- =============================================================

-- 1) Live chat per place ---------------------------------------------------
create table if not exists public.place_chat (
  id                text primary key,
  place_id          text not null,
  user_id           text not null default '',
  user_name         text not null default '',
  text              text not null default '',
  sent_at           timestamptz not null default now(),
  user_avatar_color text
);

create index if not exists idx_place_chat_place on public.place_chat (place_id, sent_at);

alter table public.place_chat enable row level security;

drop policy if exists "place_chat_public_read" on public.place_chat;
create policy "place_chat_public_read"
  on public.place_chat for select
  to anon, authenticated
  using (true);

drop policy if exists "place_chat_public_insert" on public.place_chat;
create policy "place_chat_public_insert"
  on public.place_chat for insert
  to anon, authenticated
  with check (true);

grant select, insert on public.place_chat to anon;
grant select, insert on public.place_chat to authenticated;

-- 2) Leaderboard (gamification stats per user) ------------------------------
create table if not exists public.leaderboard (
  user_id          text primary key,
  user_name        text not null default '',
  avatar_color_hex text,
  total_points     integer not null default 0,
  places_visited   integer not null default 0,
  reviews_posted   integer not null default 0,
  routes_created   integer not null default 0,
  photos_uploaded  integer not null default 0,
  badges           jsonb not null default '[]'::jsonb,
  level            text not null default 'Explorer'
);

alter table public.leaderboard enable row level security;

drop policy if exists "leaderboard_public_read" on public.leaderboard;
create policy "leaderboard_public_read"
  on public.leaderboard for select
  to anon, authenticated
  using (true);

-- the app upserts a user's own stats anonymously
drop policy if exists "leaderboard_public_insert" on public.leaderboard;
create policy "leaderboard_public_insert"
  on public.leaderboard for insert
  to anon, authenticated
  with check (true);

drop policy if exists "leaderboard_public_update" on public.leaderboard;
create policy "leaderboard_public_update"
  on public.leaderboard for update
  to anon, authenticated
  using (true) with check (true);

grant select, insert, update on public.leaderboard to anon;
grant select, insert, update on public.leaderboard to authenticated;

-- 3) Community routes -------------------------------------------------------
create table if not exists public.user_routes (
  id              text primary key,
  title           text not null default '',
  description     text not null default '',
  author_id       text not null default '',
  author_name     text not null default '',
  place_ids       jsonb not null default '[]'::jsonb,
  likes           integer not null default 0,
  saves           integer not null default 0,
  created_at      timestamptz not null default now(),
  cover_image_url text,
  tags            jsonb not null default '[]'::jsonb
);

create index if not exists idx_user_routes_created on public.user_routes (created_at desc);

alter table public.user_routes enable row level security;

drop policy if exists "user_routes_public_read" on public.user_routes;
create policy "user_routes_public_read"
  on public.user_routes for select
  to anon, authenticated
  using (true);

drop policy if exists "user_routes_public_insert" on public.user_routes;
create policy "user_routes_public_insert"
  on public.user_routes for insert
  to anon, authenticated
  with check (true);

grant select, insert on public.user_routes to anon;
grant select, insert on public.user_routes to authenticated;

-- 4) Safe like counter (users can't update rows directly) -------------------
create or replace function public.increment_route_likes(route_id text)
returns void
language sql
security definer
set search_path = public
as $$
  update public.user_routes
     set likes = likes + 1
   where id = route_id;
$$;

grant execute on function public.increment_route_likes(text) to anon, authenticated;
