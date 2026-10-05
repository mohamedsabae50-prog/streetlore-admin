-- =============================================================
-- Streetlore — Admin Tour Management
-- Run this in the Supabase SQL Editor (Dashboard → SQL → New query).
-- Idempotent: safe to re-run. Existing rows are not touched.
--
-- 1. Adds bilingual + category fields to `public.tours`
--    (mirrors the localization on `public.places`):
--      title_ar        text  — Arabic tour title
--      description_ar  text  — Arabic tour description
--      duration_ar     text  — Arabic duration label
--                              (e.g. "يوم كامل", "3 ساعات")
--      category        text  — single-theme picker
--                              (e.g. "Historical", "Coastal", "Spiritual")
--      category_ar     text  — Arabic category label
--
-- 2. Enables RLS + admin policies on `public.tours` and
--    `public.tour_places`. Reads stay public (anon). Writes require
--    `authenticated` (the admin signs in with Supabase Auth).
--
-- 3. Recreates `public.tours_with_places` so the view exposes every
--    new column. The Flutter admin service reads this view.
-- =============================================================

-- 1) Localized columns on tours --------------------------------------------
alter table public.tours
  add column if not exists title_ar       text not null default '',
  add column if not exists description_ar text not null default '',
  add column if not exists duration_ar    text not null default '',
  add column if not exists category       text not null default 'General',
  add column if not exists category_ar    text not null default '';

-- Helpful for sort + filter by category
create index if not exists idx_tours_category
  on public.tours (category);

-- 2) RLS on tours -----------------------------------------------------------
alter table public.tours enable row level security;

drop policy if exists "tours_public_read"   on public.tours;
drop policy if exists "tours_admin_insert"  on public.tours;
drop policy if exists "tours_admin_update"  on public.tours;
drop policy if exists "tours_admin_delete"  on public.tours;

create policy "tours_public_read"
  on public.tours for select
  to anon, authenticated
  using (true);

create policy "tours_admin_insert"
  on public.tours for insert
  to authenticated
  with check (true);

create policy "tours_admin_update"
  on public.tours for update
  to authenticated
  using (true) with check (true);

create policy "tours_admin_delete"
  on public.tours for delete
  to authenticated
  using (true);

grant select on public.tours to anon;
grant select, insert, update, delete on public.tours to authenticated;

-- 3) RLS on tour_places ------------------------------------------------------
alter table public.tour_places enable row level security;

drop policy if exists "tour_places_public_read"   on public.tour_places;
drop policy if exists "tour_places_admin_insert"  on public.tour_places;
drop policy if exists "tour_places_admin_update"  on public.tour_places;
drop policy if exists "tour_places_admin_delete"  on public.tour_places;

create policy "tour_places_public_read"
  on public.tour_places for select
  to anon, authenticated
  using (true);

create policy "tour_places_admin_insert"
  on public.tour_places for insert
  to authenticated
  with check (true);

create policy "tour_places_admin_update"
  on public.tour_places for update
  to authenticated
  using (true) with check (true);

create policy "tour_places_admin_delete"
  on public.tour_places for delete
  to authenticated
  using (true);

grant select on public.tour_places to anon;
grant select, insert, update, delete on public.tour_places to authenticated;

-- 4) Recreate tours_with_places so it exposes the new columns --------------
-- Drop first because CREATE OR REPLACE VIEW can't change the column list.
drop view if exists public.tours_with_places;

create view public.tours_with_places
with (security_invoker = true) as
select
  t.id,
  t.title,
  t.title_ar,
  t.description,
  t.description_ar,
  t.duration,
  t.duration_ar,
  t.category,
  t.category_ar,
  t.image_url,
  coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'id',           p.id,
          'name',         p.name,
          'name_ar',      p.name_ar,
          'description',  p.description,
          'description_ar', p.description_ar,
          'image_url',    p.image_url,
          'image_urls',   p.image_urls,
          'rating',       p.rating,
          'category',     p.category,
          'category_ar',  p.category_ar,
          'lat',          p.lat,
          'lng',          p.lng,
          'address',      p.address,
          'address_ar',   p.address_ar,
          'open_hours',   p.open_hours,
          'review_count', p.review_count,
          'price_level',  p.price_level,
          'price_note',   p.price_note,
          'is_hidden_gem', p.is_hidden_gem,
          'is_featured',  p.is_featured,
          'price_local_egp',   p.price_local_egp,
          'price_foreigner_egp', p.price_foreigner_egp,
          'display_order', p.display_order,
          'enable_chat',     p.enable_chat,
          'enable_gallery',  p.enable_gallery,
          'stop_position',   tp.position
        ) order by tp.position
    )
    from public.tour_places tp
    join public.places p on p.id = tp.place_id
    where tp.tour_id = t.id
  ),
  '[]'::jsonb
) as places
from public.tours t;

grant select on public.tours_with_places to anon, authenticated;