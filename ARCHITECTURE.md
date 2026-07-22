# NeonArena — Architecture

## System overview

Flutter user app + Flutter admin app → Supabase (Postgres + RLS + Realtime + Storage + RPC)

No custom REST API server. Authorization = Row Level Security.

## API structure

| Operation | Mechanism | Who |
|---|---|---|
| Sign in (OTP / Google) | `supabase.auth` | user |
| List tournaments / slots / leaderboard | `select` on views | user |
| Join tournament | **RPC `join_tournament(...)`** | user |
| Upload payment screenshot | Storage `payments/{uid}/{tournamentId}.jpg` | user |
| Room credentials | `select tournament_rooms` (RLS-gated) | approved user |
| Notifications | Realtime subscription | user |
| Approve/reject payments, CRUD | Admin app → service-role or RPC | admin |

## Security model

1. RLS everywhere — anon key only in apps
2. Room secrecy — DB policy requires approved participant row
3. Fake-payment defenses — unique UTR index, private bucket, manual review
4. Privilege escalation blocked — trigger strips is_admin/is_banned/wallet_balance
5. Slot integrity — FOR UPDATE row lock
