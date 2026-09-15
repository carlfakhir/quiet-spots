# Quiet Spots

CS 4261 / 8803 MAS — Assignment 1 · Carl Fakhir (`cfakhir3`)

An iPhone app for finding a quiet place to study at Georgia Tech. Students measure how loud a study spot is with
their phone's microphone, and everyone sees live noise levels on a list, a campus map, and a web dashboard.

It started as Apple's SwiftUI **Landmarks** sample app ("Handling User Input") and was changed step by step:
parks became study spots, the bundled JSON became a REST API, and the favorite button now drives quiet-spot alerts.

**Live API:** https://quiet-spots-api.cfakhir3.workers.dev · [web dashboard](https://quiet-spots-api.cfakhir3.workers.dev/) · [endpoint list](https://quiet-spots-api.cfakhir3.workers.dev/api)

| Part | Tech | Folder |
|------|------|--------|
| iOS app | SwiftUI, AVFoundation (mic), CoreLocation, MapKit, UserNotifications, BackgroundTasks | [`ios/`](ios/) |
| Backend REST API | Cloudflare Workers + Hono + D1 (SQLite) | [`backend/`](backend/) |
| Web dashboard | Plain HTML/JS served by the API | [`backend/src/dashboard.ts`](backend/src/dashboard.ts) |
| Third-party data | [Open-Meteo](https://open-meteo.com/) weather | called by the API |

## What it does
- **Browse spots**: 12 campus study spots, sorted quietest first, with a favorites filter (from the original sample).
- **Measure noise**: 5-second microphone reading converted to approximate dB, plus an optional quiet/okay/busy vote and note.
  No audio is recorded.
- **Location check**: GPS shows how far you were from the spot; reports taken on site get a badge.
- **Shared reports**: everyone's reports appear on each spot's page; you can delete your own.
- **Accounts**: sign up / sign in; posting requires a token (stored in the Keychain).
- **Weather**: current conditions at each spot from Open-Meteo.
- **Map tab**: campus map with pins colored by noise level.
- **Quiet alerts**: local notification when a starred spot turns quiet, checked on refresh and during background app refresh.
- **Web dashboard**: a second client on the same API.
- **Usage analytics**: screen views and actions logged to `POST /events`, summarized at [`/stats`](https://quiet-spots-api.cfakhir3.workers.dev/stats).

## Run the iOS app
Requires a Mac with Xcode 16+ (built with Xcode 27) and an iPhone on iOS 18+.
```bash
git clone https://github.com/carlfakhir/quiet-spots.git
open quiet-spots/ios/QuietSpots.xcodeproj
```
1. Select the **QuietSpots** target → **Signing & Capabilities** → choose your own Team
   (and change the bundle identifier if Xcode says it's taken).
2. Pick your iPhone as the run destination and press **⌘R**.
3. First run on a new device: on the iPhone, Settings → General → VPN & Device Management → trust your developer account.

A physical iPhone talks to the live API. The **Simulator** talks to `http://localhost:8787`, so start the backend
locally first (below). If you add Swift files, regenerate the project with `brew install xcodegen && cd ios && xcodegen`.

UI test (creates an account, measures, posts a report): **⌘U** in Xcode, with the local backend running.

## Run the backend locally
Requires Node 20+.
```bash
cd backend
npm install
cp .dev.vars.example .dev.vars        # set JWT_SECRET
npm run db:migrate:local
npm run dev                           # http://localhost:8787
npm run smoke                         # end-to-end API test, in another terminal
```

## Deploy the backend
```bash
npx wrangler login
npx wrangler d1 create quiet-spots-db     # paste database_id into wrangler.toml
npm run db:migrate:remote
npx wrangler secret put JWT_SECRET
npm run deploy
bash scripts/smoke.sh https://quiet-spots-api.<your-subdomain>.workers.dev
```

## API
| Method | Path | Auth | Body / notes |
|---|---|---|---|
| GET | `/health` | – | liveness |
| POST | `/auth/register` | – | `{username, password}` → `{token, user}` |
| POST | `/auth/login` | – | `{username, password}` → `{token, user}` |
| GET | `/me` | ✔ | report count and recent reports |
| GET | `/spots` | – | all spots with 2-hour average dB and level (`quiet` < 45, `moderate`, `loud` ≥ 60) |
| GET | `/spots/:id` | optional | spot + weather + recent reports (`mine` flag when signed in) |
| POST | `/spots/:id/reports` | ✔ | `{db, vote?: quiet\|ok\|busy, note?, lat?, lon?}` |
| DELETE | `/reports/:id` | ✔ | owner only |
| GET | `/weather?lat=&lon=` | – | Open-Meteo proxy |
| POST | `/events` | optional | `{name, props?, platform?}` |
| GET | `/stats` | – | users, reports per spot, events, platforms |

Send auth as `Authorization: Bearer <token>`.

## Project docs
- [`docs/dev-journal.md`](docs/dev-journal.md) — step-by-step log with problems hit and how they were solved
- [`docs/ai-log.md`](docs/ai-log.md) — how AI tools were used (required for the references section)
- [`docs/screenshots/`](docs/screenshots/) — screenshots referenced in the journal
- Tasks and bugs: this repo's **Issues**

## Credits
- Starting point: Apple, [SwiftUI Tutorials — Handling User Input](https://developer.apple.com/tutorials/swiftui/handling-user-input)
  (sample code license in [`ios/LICENSE/LICENSE.txt`](ios/LICENSE/LICENSE.txt)). Files derived from it say so in their header.
- Weather data: [Open-Meteo](https://open-meteo.com/) (CC BY 4.0)
