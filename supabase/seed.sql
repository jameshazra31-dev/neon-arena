-- Sample data
insert into public.promo_codes (code, discount_type, discount_value, max_uses, expires_at)
values ('WELCOME50','percent',50,100, now() + interval '30 days'),
       ('NEON10','flat',10,null, null);

insert into public.tournaments (name, game, entry_fee, prize_pool, per_kill_prize, start_time, total_slots, map_name, mode, rules, status, is_featured, upi_id)
values
 ('Free Fire Friday Frenzy','free_fire',20,1000,5, now() + interval '2 days',48,'Bermuda','Squad','No emulators. No teaming.','upcoming',true,'neonarena@upi'),
 ('BGMI Erangel Clash','bgmi',30,2000,8, now() + interval '3 days',100,'Erangel','Squad','Level 30+ only.','upcoming',true,'neonarena@upi'),
 ('MLBB 5v5 Showdown','mlbb',50,1500,0, now() + interval '5 days',20,'—','5v5','Rank Epic+.','upcoming',false,'neonarena@upi'),
 ('eFootball Weekend League','efootball',25,800,0, now() + interval '1 day',32,'—','1v1','Any team strength.','upcoming',false,'neonarena@upi');

-- update public.profiles set is_admin = true where id = '<your-uuid>';
