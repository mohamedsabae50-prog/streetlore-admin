
create table if not exists public.place_photos (
  id          text primary key,
  place_id    text not null references public.places(id) on delete cascade,
  user_name   text not null default 'Streetlore',
  image_url   text not null,
  caption_ar  text not null default '',
  caption_en  text not null default '',
  likes       integer not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_place_photos_updated_at on public.place_photos;
create trigger trg_place_photos_updated_at
  before update on public.place_photos
  for each row execute function public.set_updated_at();

create index if not exists idx_place_photos_place_id
  on public.place_photos (place_id);


alter table public.place_photos enable row level security;

drop policy if exists "place_photos_public_read" on public.place_photos;
create policy "place_photos_public_read"
  on public.place_photos for select
  to anon, authenticated
  using (true);

drop policy if exists "place_photos_admin_insert" on public.place_photos;
create policy "place_photos_admin_insert"
  on public.place_photos for insert
  to authenticated
  with check (true);

drop policy if exists "place_photos_admin_update" on public.place_photos;
create policy "place_photos_admin_update"
  on public.place_photos for update
  to authenticated
  using (true) with check (true);

drop policy if exists "place_photos_admin_delete" on public.place_photos;
create policy "place_photos_admin_delete"
  on public.place_photos for delete
  to authenticated
  using (true);

grant select on public.place_photos to anon;
grant select, insert, update, delete on public.place_photos to authenticated;
