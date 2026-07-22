# 🎮 NeonArena — Esports Tournament Platform

**PLAY • COMPETE • WIN**

A complete tournament platform for **Free Fire, BGMI/PUBG, MLBB, and eFootball**
built as **two separate mobile apps** + one shared Supabase backend:

| App | Who | Folder | Stack |
|---|---|---|---|
| 🎯 **NeonArena** (user app) | Players | `mobile/` | Flutter |
| 🛡️ **NeonArena Admin** (admin panel app) | Admins only | `admin_app/` | Flutter |
| 🗄️ Backend | — | `supabase/` | Supabase (Postgres + RLS, Auth, Realtime, Storage) |
| 🖥️ Web admin dashboard (optional bonus) | Admins | `admin/` | Next.js 14 + Tailwind |

## User app (`mobile/`)

- Phone OTP + Google login, profile with per-game IDs (FF UID/IGN, BGMI UID/IGN, MLBB ID/IGN, eFootball ID/Team)
- Home: featured banner carousel, game filter, Upcoming / Live / Completed tabs
- Tournament details: fees, prize pool, slots, rules, map/mode
- Join flow: confirm game ID → pay via admin UPI QR → upload screenshot + UTR → pending approval
- Room ID/Password visible **only after admin approval** (enforced by RLS, not just UI)
- My matches, payment status, results & winnings, leaderboard, realtime notifications
- Dark neon glassmorphism theme, English + Bengali

## Admin panel app (`admin_app/`)

A **separate installable app for admins only** (email + password login; non-admin
accounts are rejected and every query is RLS-checked server-side):

- **Dashboard** — total users, tournaments, revenue, pending payments, active matches
- **Tournaments** — create/edit/delete: game, banner, entry fee, prize pool, per-kill, slots, rules, schedule, featured, UPI settings
- **Payments** — view screenshots (signed URLs from the private bucket), user + game ID + UTR, approve/reject with note
- **Rooms** — publish Room ID/Password; approved players get instant notifications
- **Players** — search, ban/unban
- **Results** — add winners (rank/kills/prize), mark prizes paid, leaderboard updates automatically

## Quick start

```bash
# 1. Backend
supabase link --project-ref YOUR_REF && supabase db push

# 2. User app
cd mobile && cp .env.example .env && flutter pub get && flutter gen-l10n && flutter run

# 3. Admin app
cd admin_app && cp .env.example .env && flutter pub get && flutter run

# First admin (SQL editor):
# update public.profiles set is_admin = true where id = '<auth-user-uuid>';
```

See `ARCHITECTURE.md` for system design and `DEPLOYMENT.md` for full deployment steps.

## Security highlights

- RLS on every table; both apps ship only the anon key
- Room credentials readable only by approved participants
- Unique UTR index + private screenshots bucket + manual review = fake-payment protection
- Trigger blocks users from editing `is_admin`, `is_banned`, `wallet_balance`
- Atomic slot locking prevents overselling under concurrent joins
