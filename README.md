# CheckIn

CS 4261 / 8803 MAS — Assignment 1 (Carl Fakhir, `cfakhir3`)

An iPhone app where signed-in users post short "check-ins" (note + mood), automatically tagged with
their location, today's step count, and the current weather. Everyone sees a shared feed.

| Part | Tech | Folder |
|------|------|--------|
| iOS app | SwiftUI, CoreLocation, CoreMotion | [`ios/`](ios/) |
| Backend REST API | Cloudflare Workers + Hono + D1 (SQLite) | [`backend/`](backend/) |
| Third-party data | [Open-Meteo](https://open-meteo.com/) weather API | called from backend |

**Live API:** _TBD after deploy_

## Features
- Accounts with username/password → PBKDF2-hashed passwords, JWT bearer tokens
- Post / list / delete check-ins (only the author can delete)
- Location + weather lookup (third-party API) on each check-in
- Step count from the phone's motion coprocessor (CoreMotion)
- Shared feed = user content displayed to other users
- Usage analytics (`POST /events`, `GET /stats`)

## Run the backend locally
Requires Node 20+.
```bash
cd backend
npm install
cp .dev.vars.example .dev.vars        # set JWT_SECRET
npm run db:migrate:local
npm run dev                           # http://localhost:8787
npm run smoke                         # end-to-end test in another terminal
```

## Deploy the backend
```bash
npx wrangler login
npx wrangler d1 create checkin-db     # paste database_id into wrangler.toml
npm run db:migrate:remote
npx wrangler secret put JWT_SECRET
npm run deploy
bash scripts/smoke.sh https://checkin-api.<subdomain>.workers.dev
```

## API
| Method | Path | Auth | Body / notes |
|---|---|---|---|
| GET | `/health` | – | liveness |
| POST | `/auth/register` | – | `{username, password}` → `{token, user}` |
| POST | `/auth/login` | – | `{username, password}` → `{token, user}` |
| GET | `/me` | ✔ | profile + check-in count |
| GET | `/checkins?limit=50` | ✔ | shared feed, newest first |
| POST | `/checkins` | ✔ | `{note, mood: great\|good\|meh\|bad, lat?, lon?, steps?}` |
| DELETE | `/checkins/:id` | ✔ | owner only |
| GET | `/weather?lat=&lon=` | – | proxy to Open-Meteo |
| POST | `/events` | optional | `{name, props?, platform?}` |
| GET | `/stats` | – | counts of users, check-ins, moods, events |

Send auth as `Authorization: Bearer <token>`.

## Run the iOS app
_Coming once Xcode is installed — see [`ios/`](ios/)._

## Project docs
- [`docs/ai-log.md`](docs/ai-log.md) — how AI (Claude Code) was used, for the references section
- Tasks and bugs are tracked in this repo's **Issues**
