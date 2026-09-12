# My Chain Link

**MyChainLink.ca** — A social platform built around authentic, camera-first connections. Get connected. Stay connected.

> Your content. Your price. **You're worth it.**

---

## What This Is

A full-stack social web app where users:
- Create profiles and connect with others
- Post camera-captured content (no gallery uploads)
- Set their own subscription price for premium content
- Send DMs with media
- Go live / stream
- Customize fonts, colors, conversation themes, and profile songs

Premium features include colored fonts, live streaming, profile songs, custom conversation themes, verification badges, and more.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Single-file HTML app (vanilla JS, inline CSS) |
| Backend | Supabase (PostgreSQL + Auth + Realtime + Storage) |
| Auth | Supabase Auth (email/password + Google OAuth + Facebook OAuth) |
| Hosting | GitHub Pages (deploys automatically on `git push`) |
| Email | Resend API |
| Payments | PayPal integration |
| Domain | mychainlink.ca |

---

## File Structure

```
My chain link/
├── index.html          # Main app (single file, ~220KB)
├── login.html          # Standalone login page
├── terms.html          # Terms of Service
├── privacy.html        # Privacy Policy
├── purchase-terms.html # Terms of Purchase
├── complete_schema.sql # Full Supabase database schema
├── posts_table.sql     # Posts table schema (subset)
├── transactions_table.sql # Transactions schema (subset)
├── feature-comparison.html  # Free vs Premium reference doc
├── site-map.html       # Complete page map reference
├── database-schema.html # Database schema reference
├── logo-v4.png         # App logo
├── MY_CREDENTIALS.txt  # ⚠️ PRIVATE — never commit this
└── README.md           # This file
```

---

## Key Features

### Core
- [x] Email/password signup & login
- [x] Google OAuth sign-in
- [x] Facebook OAuth sign-in
- [x] "Stay logged in" / "Remember me"
- [x] Multi-account switcher
- [x] Forgot password (security question + PIN)
- [x] 2FA PIN protection
- [x] Profile creation with avatar (camera capture)

### Social
- [x] Create posts with camera-captured photos/videos
- [x] Text posts with custom fonts & colors (Premium)
- [x] Like, dislike, love, repost, comment
- [x] Follow / Connect system
- [x] Direct messaging with real-time updates
- [x] Notifications (likes, follows, messages, mentions)
- [x] User search by name, handle, email, hashtag
- [x] View user profiles

### Premium (Creator Plan — $10.99/month)
- [x] Set your own subscription price (keep 100%)
- [x] Colored fonts for posts
- [x] Go live / stream
- [x] Send camera media in DMs
- [x] Verification badge
- [x] Profile songs
- [x] Custom conversation themes
- [x] 7-day free trial

### Monetization
- [x] PayPal integration for subscriptions
- [x] Fans pay creators for exclusive content
- [x] Creator subscription pricing

---

## Database Schema (Supabase)

### Tables
1. **profiles** — User profiles (extends auth.users)
2. **posts** — User posts
3. **likes** — Relational likes
4. **comments** — Relational comments
5. **follows** — Connects/follows
6. **conversations** — DM threads
7. **messages** — DM messages (realtime enabled)
8. **notifications** — User notifications
9. **transactions** — PayPal payments
10. **user_songs** — Profile songs (Premium)

### Storage Buckets
- `avatars` — Profile photos
- `media` — Post media
- `photos` — Camera captures
- `songs` — Profile songs

### Auth Trigger
- Auto-creates profile row on new user signup

---

## Deployment

### How It Works
1. Push to `main` branch on GitHub
2. GitHub Pages auto-deploys to `mychainlink.ca`
3. Done — no manual deployment step

### To Deploy Changes
```bash
cd ~/mychainlink
git add .
git commit -m "what you changed"
git push origin main
```

### Custom Domain
- Configured in GitHub Pages settings
- DNS via Website.com nameservers
- HTTPS enforced

---

## Environment Variables (for Supabase / Render)

| Variable | Value |
|----------|-------|
| `SUPABASE_URL` | `https://vjaevzohcnejkaduvtno.supabase.co` |
| `SUPABASE_ANON_KEY` | (see MY_CREDENTIALS.txt) |
| `SUPABASE_SERVICE_ROLE_KEY` | (see MY_CREDENTIALS.txt) |
| `RESEND_API_KEY` | (see MY_CREDENTIALS.txt) |

---

## Important Notes for Future Developers

### Single-File Architecture
The entire app lives in `index.html`. All CSS, JS, and HTML are inline. This is intentional — it makes deployment trivial (one file to GitHub Pages).

### Local + Supabase Hybrid
The app works both offline (localStorage) and online (Supabase):
- Posts, users, follows sync to Supabase when online
- Falls back to localStorage when offline
- Auth works with both Supabase and local accounts

### Camera-First Design
- Posts require camera capture — no gallery uploads allowed
- Camera page uses `getUserMedia()` with front/back toggle
- Video recording supported

### Premium Gating
Most premium features check `isUserPremium(userId)` which looks at:
1. `localStorage` trial/premium flags
2. Supabase `profiles.is_premium` field
3. Subscription status from transactions

### Known Quirks
- **Quote rotation** on landing page cycles every 3.5 seconds with fade transition
- **Landing page** is hidden via CSS injection in `<head>` for logged-in users (prevents flash)
- **Annual plan** is disabled ("Coming Soon" badge) — only Monthly active
- **Bottom nav** uses `.mit` class buttons with `navTo()` function
- **Pages** use `.page` / `.page.active` CSS toggle system

---

## Contact

- **Creator:** Kendal Symes
- **Email:** Kendalchaincreator@proton.me
- **Domain:** mychainlink.ca
- **Slogan:** Get connected. Stay connected.

---

## License

© 2026 Kendal Symes. All rights reserved.
