# Assignment 1 Submission — Quiet Spots

> **Draft.** Sections marked ✏️ need your own words (why you chose this, what you learned, the partner story).
> Sections marked 📱 need your phone. Everything else is filled in from the repo, journal, and screenshots.

## Name
Carl Fakhir (GT username `cfakhir3`)

## What I built
**Quiet Spots** is an iPhone app for finding a quiet place to study at Georgia Tech.

- Browse 12 campus study spots, sorted quietest first, with a favorites filter
- Measure how loud a spot is: the phone's microphone listens for 5 seconds and converts the level to approximate decibels
  (nothing is recorded), then you can vote quiet / okay / busy and add a note
- The app checks your GPS location and marks reports taken on site
- Everyone's reports appear on each spot's page, averaged over the last 2 hours into Quiet / Moderate / Loud
- Accounts: sign up / sign in, required to post; you can delete your own reports
- Current weather at each spot (Open-Meteo)
- Campus map with pins colored by noise level
- Notifications when a starred spot turns quiet, including checks during background app refresh
- Spanish translation of the whole UI and permission prompts
- A web dashboard (a second client on the same API) showing live levels and usage stats
- Usage analytics: app opens, screens viewed, reports posted, alerts delivered

It began as Apple's SwiftUI **Landmarks** sample ("Handling User Input") and was changed in stages, so the git history
shows a real sample app being built on and modified: national parks → study spots, bundled JSON → REST API,
favorite button → quiet alerts.

✏️ **Why I chose this and what I hoped to learn:**
_(Your words. Prompts: finding a quiet study spot on campus is a real problem you've had? You wanted to try iOS/Swift,
device sensors, and deploying a real backend? What did you know before, and what was new?)_

## Requirement checklist

| # | Requirement | Evidence |
|---|---|---|
| 1 | Install a dev environment | Xcode 27 + iOS 27 SDK, Simulator, free Personal Team signing. [Journal: Xcode](dev-journal.md#xcode) · [HelloDevice on my iPhone](screenshots/01-HelloDevice-on-iPhone.png) |
| 2 | Build an existing sample on a device, with user input | Apple Landmarks sample committed unmodified (`82533c5`), built from that exact commit and run on my iPhone 17 Pro: [screenshot](screenshots/02-landmarks-sample-on-iphone.png). User input: favorite button and "Favorites only" toggle. |
| 3 | Git account, check in code, track tasks/bugs | [github.gatech.edu/cfakhir3/quiet-spots](https://github.gatech.edu/cfakhir3/quiet-spots), 14+ commits, [Issues](https://github.gatech.edu/cfakhir3/quiet-spots/issues) with labels, [dev journal](dev-journal.md) |
| 4 | Partner swap both ways | ✏️ _Partner's PR to my repo + my PR to theirs (links, screenshots)._ |
| 5 | Deployed web service with REST API, in git | [quiet-spots-api.cfakhir3.workers.dev](https://quiet-spots-api.cfakhir3.workers.dev/api), code in [`backend/`](../backend/), smoke test passes in production |

| Exceptional item | Evidence |
|---|---|
| Authentication | PBKDF2-hashed passwords, JWT bearer tokens, Keychain storage, owner-only delete |
| Third-party data | Open-Meteo weather on spot pages and saved with each report |
| Sensor / native feature | Microphone (AVFoundation), GPS (CoreLocation), MapKit, background refresh |
| User content shown to others | Noise reports, votes, and notes visible to everyone |
| UI experiments | Tab navigation (list / map / account), sign-in sheet that continues into measuring, Spanish localization |
| Another platform on the same backend | Web dashboard at `/` |
| Notifications | Local notifications + background app refresh, with a comparison to APNs / Firebase push in the journal |
| Activity data collection | `POST /events` from the app, summarized at `/stats` and on the dashboard |
| Testing | API smoke test script; XCUITest suite (sign up → measure → post; map → alerts) |

## Screenshots

| | |
|---|---|
| ![](screenshots/01-HelloDevice-on-iPhone.png) | **First app on my iPhone.** Tiny SwiftUI app to prove signing and install worked end to end. |
| ![](screenshots/02-landmarks-sample-on-iphone.png) | **Required sample app, unmodified, running on my iPhone.** Apple's Landmarks (Handling User Input), built from commit `82533c5` before any changes. |
| ![](screenshots/04-stage1-spot-list.png) | **Stage 1.** Landmarks list turned into GT study spots, with category badges replacing park photos. |
| ![](screenshots/05-stage2-live-levels.png) | **Stage 2.** Live noise levels from the REST API, sorted quietest first. |
| ![](screenshots/06-stage3-measure-flow.png) | **Stage 3.** Spot page with weather → measuring → result with vote and location check → report posted. Captured by the automated UI test. |
| ![](screenshots/08-stage4-map-and-alerts.png) | **Stage 4.** Campus map, alert settings, and a quiet-spot notification. |
| ![](screenshots/09-spanish.png) | **Stage 5.** The app in Spanish. |
| ![](screenshots/10-web-dashboard-live.png) | **Web dashboard** on the deployed API with usage stats. |
| 📱 _Quiet Spots on iPhone measuring a real room_ | **Final app on the device**, ideally a short screen recording. |

## References (in the order I used them)

### Setting up
1. **Mac App Store: Xcode** — installed Xcode 27. Learned the command-line tools alone can't build apps, and that
   `xcode-select`, license acceptance, and `-runFirstLaunch` need admin rights.
2. **Apple: [Running your app in Simulator or on a device](https://developer.apple.com/documentation/xcode/running-your-app-in-simulator-or-on-a-device)** —
   Developer Mode, Personal Team signing, trusting the developer profile on the phone.
3. **Course resource docs** ([Canvas references page](https://docs.google.com/document/d/1QMMM9BTS7GB3WujJDrXqdTqGYNvx3_rp1TzdKJ4vfM8/edit),
   [second resource doc](https://docs.google.com/document/d/1ImiDiXD3tflsosJKj1U_nRopTYPDRFVImCj4UQjnKS0/edit)) — read to choose a platform.
   The iOS Core Motion / sensors entry pointed me toward using a device sensor. The Kodeco "Your First iOS and SwiftUI App" link
   turned out to be from 2019 (Xcode 11) with materials behind a sign-in, so I used Apple's current tutorial instead.
4. **[GitHub CLI](https://cli.github.com/)** with GT Enterprise GitHub — creating the repo, labels, and issues from the terminal.

### Building the app
5. **Apple: [SwiftUI Tutorials — Handling User Input](https://developer.apple.com/tutorials/swiftui/handling-user-input)** —
   the sample app I started from (list, detail with map, favorite button, filter toggle). ✏️ _Note which chapters you read._
6. **[XcodeGen](https://github.com/yonaskolb/XcodeGen)** — generates the Xcode project from `ios/project.yml` so new files
   don't require hand-editing `project.pbxproj`.
7. **Apple: [AVAudioRecorder metering](https://developer.apple.com/documentation/avfaudio/avaudiorecorder)** — reading mic level
   in dBFS; learned why a fixed offset is needed to approximate dB SPL and why decibels are averaged in the power domain.
8. **Apple: [CoreLocation](https://developer.apple.com/documentation/corelocation)**, **[MapKit for SwiftUI](https://developer.apple.com/documentation/mapkit/mapkit-for-swiftui)** —
   one-shot location, distance to spot, map annotations.
9. **Apple: [UserNotifications](https://developer.apple.com/documentation/usernotifications)** and
   **[BackgroundTasks / `backgroundTask(_:action:)`](https://developer.apple.com/documentation/swiftui/scene/backgroundtask(_:action:))** — local alerts and
   background refresh; compared with **[APNs](https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns)** and
   **[Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging/ios/client)**.
10. **Apple: [Localizing with String Catalogs](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)** — Spanish translation.
11. **Apple: [XCTest UI testing](https://developer.apple.com/documentation/xctest/user-interface-tests)** — automated end-to-end tests and screenshot attachments.

### Backend
12. **[Cloudflare Workers](https://developers.cloudflare.com/workers/)**, **[D1](https://developers.cloudflare.com/d1/)**, and
    **[Wrangler](https://developers.cloudflare.com/workers/wrangler/)** — hosting, SQLite database, migrations, secrets, deploy.
    Chosen because it's free without a credit card and doesn't sleep (Heroku is no longer free; Firebase server code needs a paid plan).
13. **[Hono](https://hono.dev/)** — routing, CORS, JWT helpers for the API.
14. **[Open-Meteo](https://open-meteo.com/en/docs)** — free weather API, no key; WMO weather codes.
15. **[Playwright](https://playwright.dev/)** — opened resource pages that need JavaScript and screenshotted the web dashboard to check it.

### AI / virtual teammate
16. **Claude Code (Anthropic), model Claude Opus 5** — used as a virtual teammate throughout. It substantively:
    checked my environment and walked me through Xcode and device setup; proposed the architecture; wrote most of the
    backend, the iOS code on top of Apple's sample, the tests, and the Spanish translations; ran builds, tests, and the deploy;
    and debugged the problems listed below. Full, dated log of what I asked for, what it did, and what I checked:
    [`docs/ai-log.md`](ai-log.md).
    ✏️ _How you directed it, what you verified or changed yourself, and what you learned from working this way._

## Problems I had to debug
Details and fixes for each are in the [dev journal](dev-journal.md).

| Problem | What was going on | Fix |
|---|---|---|
| `xcodebuild` refused to run | Xcode license not accepted | `sudo xcodebuild -license accept` |
| Command-line signing: "login details were rejected" | `xcodebuild` couldn't reuse the Xcode account session | Opened Xcode's account settings, retried |
| App wouldn't launch on iPhone | Developer profile not trusted on the device | Settings → VPN & Device Management → Trust |
| `git push` HTTP 400 | ~5 MB of sample images over the default HTTPS buffer | `git config http.postBuffer` |
| API test "passed" when it shouldn't | Bash brace expansion split JSON into two bad requests | Build JSON in variables; stricter `expect()` |
| `'Tab' is only available in iOS 18` | Sample targeted iOS 17 | Raised deployment target |
| `wrangler login` timed out twice | OAuth page waits ~2 minutes | Re-ran while at the browser |
| Deploy: "register a workers.dev subdomain" | Interactive prompt in a non-interactive shell | Registered via Cloudflare API |
| TLS handshake failure on new URL | Certificate still being issued | Waited |
| Local "no such table: users" | Local DB keyed by database id changed | Re-ran local migrations |
| UI test typed 1 of 11 password characters | iOS strong-password suggestion ate keystrokes | Skip content type under `-uiTesting` |
| UI test couldn't find banner that was visible | Wrong element type in the query; found by watching the test's screen recording | Query any element type |
| Mixed-up commit | `git add -A` swept in unfinished files | Split with `git reset --soft`, force-push before anyone cloned |

## Repository and API
- **Repo:** https://github.gatech.edu/cfakhir3/quiet-spots
- **API:** https://quiet-spots-api.cfakhir3.workers.dev (endpoints: [`/api`](https://quiet-spots-api.cfakhir3.workers.dev/api), stats: [`/stats`](https://quiet-spots-api.cfakhir3.workers.dev/stats))
- **Dashboard:** https://quiet-spots-api.cfakhir3.workers.dev/
- **Download and run:** see the [README](../README.md#run-the-ios-app): clone, open `ios/QuietSpots.xcodeproj`, pick your team and iPhone, ⌘R.
  Backend: `cd backend && npm install && npm run db:migrate:local && npm run dev`.

## Git history

```
f5df4b7  Sep 14 18:21  Add CheckIn backend API (Workers + Hono + D1) and project docs
a30880e  Sep 14 19:07  Add dev journal for Xcode and GitHub setup
62cc64c  Sep 14 19:10  Log simulator install, Apple ID team, and iPhone pairing
3aa8abc  Sep 14 19:38  Log first successful build and launch on iPhone
aa21b6a  Sep 14 19:39  Add screenshot of test app running on iPhone
82533c5  Sep 14 20:02  Add Apple's SwiftUI Landmarks sample (Handling User Input), unmodified
41f06f4  Sep 14 20:07  Reshape backend for Quiet Spots: study spots, noise reports, web dashboard
6a7f43c  Sep 14 20:11  Turn Landmarks sample into Quiet Spots with Georgia Tech study spots
7be6b84  Sep 14 20:14  Load spots from the REST API and add sign in / create account
6b49b48  Sep 14 20:40  Deploy API to Cloudflare Workers
e365519  Sep 14 20:53  Measure noise with the microphone and post reports
912571a  Sep 14 20:56  Add campus map tab and quiet-spot alerts
997f6c3  Sep 14 20:58  Add Spanish localization
c121050  Sep 14 20:59  Show usage analytics on the web dashboard
```
✏️ _Update with `git log --oneline` after the partner swap, and add a screenshot of the network graph or the merged PRs._

Evidence of git practice: renaming with `git mv` so history follows files from the Apple sample, one commit per stage,
a history rewrite that was fixed before anyone cloned, and Issues closed with commit references.

### Working with my partner ✏️
_(Fill in after tomorrow.)_
- **Who and how we met / communicated:** _(Chatter? In person? Text?)_
- **Plan:** _(e.g. each added the other as a collaborator; partner adds a study spot or changes a label in my app via a pull request;
  I do a similar change in theirs.)_
- **What they changed in my repo:** _(PR link, what it did, screenshot of it running on my phone after I pulled)_
- **What I changed in theirs:** _(PR link, what it did, how I built and tested it)_
- **Problems we debugged together:** _(e.g. signing team / bundle ID conflicts when building someone else's Xcode project,
  merge conflicts in `project.pbxproj`)_
- **What I learned about working with others:**
- **What I'd do differently next time:**
