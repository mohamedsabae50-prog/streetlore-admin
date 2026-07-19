insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'place-images',
  'place-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do nothing;

drop policy if exists "place_images_public_read" on storage.objects;
create policy "place_images_public_read"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'place-images');

drop policy if exists "place_images_admin_insert" on storage.objects;
create policy "place_images_admin_insert"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'place-images');

drop policy if exists "place_images_admin_update" on storage.objects;
create policy "place_images_admin_update"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'place-images')
  with check (bucket_id = 'place-images');

drop policy if exists "place_images_admin_delete" on storage.objects;
create policy "place_images_admin_delete"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'place-images');
