insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'place-images',
  'place-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do nothing;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select is_admin from public.profiles where user_id = auth.uid()),
    false
  );
$$;

revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

drop policy if exists "place_images_public_read" on storage.objects;
create policy "place_images_public_read"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'place-images');

drop policy if exists "place_images_admin_insert" on storage.objects;
create policy "place_images_admin_insert"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'place-images' and public.is_admin());

drop policy if exists "place_images_admin_update" on storage.objects;
create policy "place_images_admin_update"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'place-images' and public.is_admin())
  with check (bucket_id = 'place-images' and public.is_admin());

drop policy if exists "place_images_admin_delete" on storage.objects;
create policy "place_images_admin_delete"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'place-images' and public.is_admin());
