-- NeonArena — Functions & triggers
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as
$$ select exists (select 1 from public.profiles where id = auth.uid() and is_admin) $$;

create or replace function public.is_approved_participant(p_tournament_id uuid)
returns boolean language sql stable security definer set search_path = public as
$$ select exists (
     select 1 from public.participants
     where tournament_id = p_tournament_id and user_id = auth.uid() and status = 'approved') $$;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username, phone, avatar_url)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data->>'username',''), 'player_' || substr(replace(new.id::text,'-',''),1,8)),
    new.phone,
    new.raw_user_meta_data->>'avatar_url'
  ) on conflict (id) do nothing;
  return new;
end $$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.join_tournament(
  p_tournament_id uuid, p_game_uid text, p_ign text,
  p_utr text, p_screenshot_url text, p_promo_code text default null
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_t public.tournaments%rowtype;
  v_taken int;
  v_fee numeric;
  v_discount numeric := 0;
  v_id uuid;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  if exists (select 1 from public.profiles where id = auth.uid() and is_banned) then
    raise exception 'Your account is banned';
  end if;
  select * into v_t from public.tournaments where id = p_tournament_id for update;
  if not found then raise exception 'Tournament not found'; end if;
  if v_t.status <> 'upcoming' then raise exception 'Registration is closed'; end if;
  if exists (select 1 from public.participants where tournament_id = p_tournament_id and user_id = auth.uid()) then
    raise exception 'You have already joined this tournament';
  end if;
  select count(*) into v_taken from public.participants
  where tournament_id = p_tournament_id and status in ('pending','approved');
  if v_taken >= v_t.total_slots then raise exception 'Tournament is full'; end if;
  v_fee := v_t.entry_fee;
  if p_promo_code is not null and length(trim(p_promo_code)) > 0 then
    update public.promo_codes set used_count = used_count + 1
     where code = upper(trim(p_promo_code)) and is_active
       and (max_uses is null or used_count < max_uses)
       and (expires_at is null or expires_at > now())
    returning case when discount_type = 'flat' then least(discount_value, v_fee)
                   else round(v_fee * discount_value / 100.0, 2) end into v_discount;
    if v_discount is null then raise exception 'Invalid or expired promo code'; end if;
  end if;
  insert into public.participants
    (tournament_id, user_id, game_uid, ign, utr, payment_screenshot_url, promo_code, amount_due, status)
  values
    (p_tournament_id, auth.uid(), p_game_uid, p_ign, nullif(trim(p_utr),''), p_screenshot_url,
     upper(nullif(trim(p_promo_code),'')), greatest(v_fee - coalesce(v_discount,0), 0),
     case when v_t.entry_fee = 0 then 'approved'::public.join_status else 'pending'::public.join_status end)
  returning id into v_id;
  return v_id;
end $$;

create or replace function public.review_payment(
  p_participant_id uuid, p_approve boolean, p_note text default null
) returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Admins only'; end if;
  update public.participants
     set status = case when p_approve then 'approved'::public.join_status else 'rejected'::public.join_status end,
         admin_note = p_note, reviewed_by = auth.uid(), reviewed_at = now()
   where id = p_participant_id and status = 'pending';
  if not found then raise exception 'Request not found or already reviewed'; end if;
end $$;

create or replace function public.apply_referral(p_code text)
returns void language plpgsql security definer set search_path = public as $$
declare v_referrer uuid;
begin
  select id into v_referrer from public.profiles where referral_code = upper(trim(p_code));
  if v_referrer is null or v_referrer = auth.uid() then raise exception 'Invalid referral code'; end if;
  update public.profiles set referred_by = v_referrer where id = auth.uid() and referred_by is null;
  if not found then raise exception 'Referral already applied'; end if;
  insert into public.wallet_transactions (user_id, type, amount, reason)
  values (v_referrer, 'credit', 10, 'referral_bonus');
  update public.profiles set wallet_balance = wallet_balance + 10 where id = v_referrer;
end $$;

create or replace function public.notify_payment_review()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status <> old.status and new.status in ('approved','rejected') then
    insert into public.notifications (user_id, title, body, kind, tournament_id)
    select new.user_id,
           case when new.status = 'approved' then 'Payment approved ✅' else 'Payment rejected ❌' end,
           case when new.status = 'approved' then 'You are in! Room details will appear before the match.'
                else coalesce('Reason: ' || new.admin_note, 'Contact support.') end,
           'payment', new.tournament_id;
  end if;
  return new;
end $$;
create trigger trg_notify_payment_review after update on public.participants
for each row execute function public.notify_payment_review();

create or replace function public.notify_room_published()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications (user_id, title, body, kind, tournament_id)
  select p.user_id, 'Room details released 🎮', 'Room ID & password are now available. Good luck!', 'room', new.tournament_id
  from public.participants p where p.tournament_id = new.tournament_id and p.status = 'approved';
  return new;
end $$;
create trigger trg_notify_room_published after insert on public.tournament_rooms
for each row execute function public.notify_room_published();

create or replace function public.notify_result_added()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications (user_id, title, body, kind, tournament_id)
  values (new.user_id, 'Result announced 🏆', 'You placed #' || new.rank || '. Prize: ₹' || new.prize_amount, 'result', new.tournament_id);
  return new;
end $$;
create trigger trg_notify_result_added after insert on public.results
for each row execute function public.notify_result_added();
