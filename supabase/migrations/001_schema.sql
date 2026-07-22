-- ============================================================
-- NeonArena — Core schema
-- ============================================================
create extension if not exists "pgcrypto";

-- ---------- Enums ----------
create type public.game_type as enum ('free_fire','bgmi','mlbb','efootball');
create type public.tournament_status as enum ('upcoming','live','completed','cancelled');
create type public.join_status as enum ('pending','approved','rejected');
create type public.prize_status as enum ('pending','paid');
create type public.wallet_tx_type as enum ('credit','debit');

-- ---------- Profiles ----------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  phone text,
  avatar_url text,
  is_admin boolean not null default false,
  is_banned boolean not null default false,
  referral_code text unique not null default upper(substr(encode(gen_random_bytes(6),'hex'),1,8)),
  referred_by uuid references public.profiles(id),
  wallet_balance numeric(12,2) not null default 0 check (wallet_balance >= 0),
  language text not null default 'en' check (language in ('en','bn')),
  created_at timestamptz not null default now()
);

create table public.game_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  game public.game_type not null,
  game_uid text not null,
  ign text not null,
  team_name text,
  unique (user_id, game)
);

create table public.tournaments (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  game public.game_type not null,
  banner_url text,
  entry_fee numeric(10,2) not null default 0 check (entry_fee >= 0),
  prize_pool numeric(12,2) not null default 0,
  per_kill_prize numeric(10,2) not null default 0,
  start_time timestamptz not null,
  total_slots int not null check (total_slots > 0),
  map_name text,
  mode text,
  rules text,
  status public.tournament_status not null default 'upcoming',
  is_featured boolean not null default false,
  upi_id text,
  upi_qr_url text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
create index idx_tournaments_status on public.tournaments (status, start_time);
create index idx_tournaments_game on public.tournaments (game);

create table public.tournament_rooms (
  tournament_id uuid primary key references public.tournaments(id) on delete cascade,
  room_id text not null,
  room_password text not null,
  match_time timestamptz,
  published_at timestamptz not null default now()
);

create table public.participants (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  game_uid text not null,
  ign text not null,
  payment_screenshot_url text,
  utr text,
  promo_code text,
  amount_due numeric(10,2) not null default 0,
  status public.join_status not null default 'pending',
  admin_note text,
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  unique (tournament_id, user_id)
);
create index idx_participants_status on public.participants (status);
create index idx_participants_user on public.participants (user_id);
create unique index idx_participants_utr_unique on public.participants (utr) where utr is not null;

create table public.results (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  rank int not null check (rank > 0),
  kills int not null default 0,
  prize_amount numeric(12,2) not null default 0,
  prize_status public.prize_status not null default 'pending',
  screenshot_url text,
  created_at timestamptz not null default now(),
  unique (tournament_id, user_id)
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  kind text not null check (kind in ('reminder','payment','room','result','general')),
  tournament_id uuid references public.tournaments(id) on delete set null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);
create index idx_notifications_user on public.notifications (user_id, is_read, created_at desc);

create table public.promo_codes (
  code text primary key,
  discount_type text not null check (discount_type in ('flat','percent')),
  discount_value numeric(10,2) not null check (discount_value > 0),
  max_uses int,
  used_count int not null default 0,
  expires_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type public.wallet_tx_type not null,
  amount numeric(12,2) not null check (amount > 0),
  reason text not null,
  tournament_id uuid references public.tournaments(id) on delete set null,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create view public.tournament_slots with (security_invoker = true) as
select t.id as tournament_id,
       t.total_slots,
       count(p.id) filter (where p.status in ('pending','approved'))::int as taken_slots,
       (t.total_slots - count(p.id) filter (where p.status in ('pending','approved')))::int as available_slots
from public.tournaments t
left join public.participants p on p.tournament_id = t.id
group by t.id;

create view public.leaderboard with (security_invoker = true) as
select pr.id as user_id, pr.username, pr.avatar_url,
       count(r.id)::int as tournaments_won,
       coalesce(sum(r.kills),0)::int as total_kills,
       coalesce(sum(r.prize_amount),0) as total_winnings
from public.profiles pr
join public.results r on r.user_id = pr.id
group by pr.id
order by total_winnings desc;
