-- NeonArena — Storage buckets & policies
insert into storage.buckets (id, name, public) values
  ('banners','banners', true),
  ('avatars','avatars', true),
  ('payments','payments', false),
  ('results','results', true)
on conflict (id) do nothing;

create policy "banners admin write" on storage.objects for insert with check (bucket_id = 'banners' and public.is_admin());
create policy "banners admin delete" on storage.objects for delete using (bucket_id = 'banners' and public.is_admin());

create policy "avatars user write own" on storage.objects for insert with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "avatars user update own" on storage.objects for update using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "payments user upload own" on storage.objects for insert with check (bucket_id = 'payments' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "payments owner or admin read" on storage.objects for select using (bucket_id = 'payments' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));

create policy "results admin write" on storage.objects for insert with check (bucket_id = 'results' and public.is_admin());
