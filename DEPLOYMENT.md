# NeonArena — Deployment Guide

## 1. Supabase
1. Create project at supabase.com (Singapore region)
2. SQL Editor → run 001_schema.sql → 002_functions_triggers.sql → 003_rls_policies.sql → 004_storage.sql → seed.sql
3. Authentication → Providers → Phone (Twilio) + Google (OAuth)
4. First admin: `update public.profiles set is_admin = true where id = '<uuid>';`

## 2. User app (mobile/)
```bash
cd mobile && cp .env.example .env   # fill SUPABASE_URL + ANON_KEY + Google client IDs
flutter pub get && flutter gen-l10n && flutter run
# Release: flutter build apk --release
```

## 3. Admin app (admin_app/)
```bash
cd admin_app && cp .env.example .env   # fill SUPABASE_URL + ANON_KEY
flutter pub get && flutter run
# Release: flutter build apk --release
```

## 4. GitHub Actions APK
Push to main → Actions → 'Build APKs' workflow auto-runs → download artifacts.

## 5. Post-launch
- Enable pg_cron for tournament reminders
- Supabase daily backups
- OTP rate limits + CAPTCHA
- FCM/OneSignal for OS push
