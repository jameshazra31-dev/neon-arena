-- NeonArena — Row Level Security
alter table public.profiles enable row level security;
alter table public.game_profiles enable row level security;
alter table public.tournaments enable row level security;
alter table public.tournament_rooms enable row level security;
alter table public.participants enable row level security;
alter table public.results enable row level security;
alter table public.notifications enable row level security;
alter table public.promo_codes enable row level security;
alter table public.wallet_transactions enable row level security;

create policy "profiles: read own or admin" on public.profiles for select using (id = auth.uid() or public.is_admin());
create policy "profiles: update own" on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());
create policy "profiles: admin update" on public.profiles for update using (public.is_admin());

create or replace function public.protect_profile_fields() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then
    new.is_admin := old.is_admin;
    new.is_banned := old.is_banned;
    new.wallet_balance := old.wallet_balance;
    new.referral_code := old.referral_code;
  end if;
  return new;
end $$;
create trigger trg_protect_profile_fields before update on public.profiles for each row execute function public.protect_profile_fields();

create policy "game_profiles: own or admin read" on public.game_profiles for select using (user_id = auth.uid() or public.is_admin());
create policy "game_profiles: own write" on public.game_profiles for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "tournaments: authenticated read" on public.tournaments for select using (auth.uid() is not null);
create policy "tournaments: admin write" on public.tournaments for all using (public.is_admin()) with check (public.is_admin());

create policy "rooms: approved players or admin" on public.tournament_rooms for select using (public.is_admin() or public.is_approved_participant(tournament_id));
create policy "rooms: admin write" on public.tournament_rooms for all using (public.is_admin()) with check (public.is_admin());

create policy "participants: own or admin read" on public.participants for select using (user_id = auth.uid() or public.is_admin());
create policy "participants: admin update" on public.participants for update using (public.is_admin());

create policy "results: authenticated read" on public.results for select using (auth.uid() is not null);
create policy "results: admin write" on public.results for all using (public.is_admin()) with check (public.is_admin());

create policy "notifications: own read" on public.notifications for select using (user_id = auth.uid());
create policy "notifications: own mark-read" on public.notifications for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "notifications: admin insert" on public.notifications for insert with check (public.is_admin());

create policy "promo_codes: admin all" on public.promo_codes for all using (public.is_admin()) with check (public.is_admin());

create policy "wallet: own or admin read" on public.wallet_transactions for select using (user_id = auth.uid() or public.is_admin());
create policy "wallet: admin insert" on public.wallet_transactions for insert with check (public.is_admin());

alter publication supabase_realtime add table public.notifications;
alter publication supabase_realtime add table public.tournaments;
alter publication supabase_realtime add table public.participants;
