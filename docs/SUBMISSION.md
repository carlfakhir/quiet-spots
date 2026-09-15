# Assignment 1 Submission — Quiet Spots

> **Draft.** Remaining: ✏️ partner section (after the swap) and 📱 on-device measuring screenshots.

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

### Background
I had experience with programming, backends, and Git before this project, but less experience with Swift and iOS development.

### Why I chose this and what I hoped to learn
I wanted to build something original rather than just run a sample. Quiet Spots came out of brainstorming app ideas with
Claude, and I chose it because it addresses a practical campus problem: helping Georgia Tech students find quieter places
to study using shared noise reports. I wanted to explore how an iPhone app could combine microphone readings, location,
and a backend, and since I was newer to Swift and iOS, it was a way to learn the platform while building on backend and
Git skills I already had.

### What I learned
- How an iOS interface, device features (microphone, GPS, maps, notifications), and a backend fit together into one product.
- Real devices add steps a simulator hides: code signing, Developer Mode, trusting the developer profile, permission prompts.
- Using AI for coding still requires clear direction and hands-on testing. Next time I would spend more time understanding
  each change as it is introduced instead of reviewing larger batches afterward.

## Requirement checklist

| # | Requirement | Evidence |
|---|---|---|
| 1 | Install a dev environment | Xcode 27 + iOS 27 SDK, Simulator, free Personal Team signing. [Journal: Xcode](dev-journal.md#xcode) · [HelloDevice on my iPhone](screenshots/01-HelloDevice-on-iPhone.png) |
| 2 | Build an existing sample on a device, with user input | Apple Landmarks sample committed unmodified (`82533c5`), built from that exact commit and run on my iPhone 17 Pro: [screenshot](screenshots/02-landmarks-sample-on-iphone.png). User input: favorite button and "Favorites only" toggle. |
| 3 | Git account, check in code, track tasks/bugs | [github.gatech.edu/cfakhir3/quiet-spots](https://github.gatech.edu/cfakhir3/quiet-spots), 17+ commits, [Issues](https://github.gatech.edu/cfakhir3/quiet-spots/issues) with labels, [dev journal](dev-journal.md) |
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
| ![](screenshots/11-device-spot-list.png) | **Quiet Spots on my iPhone.** Spot list loaded from the live API (production had no reports yet). |
| ![](screenshots/12-device-spot-detail-weather.png) | **Spot page on the device** with live Open-Meteo weather (29 °C, clear) and the Measure button. |
| ![](screenshots/13-device-sign-in-to-measure.png) | **Protected action.** Tapping Measure while signed out opens sign-in first, since posting requires an account. |
| ![](screenshots/14-device-map.png) | **Campus map on the device** with a pin per study spot and the noise legend. |
| ![](screenshots/15-device-account.png) | **Account tab** with sign in / create account. |
| 📱 _Measuring a real room on the iPhone (+ posted report, quiet alert)_ | ✏️ _Still to capture: create an account on the phone, measure a spot, post, and ideally screen-record it._ |

## References (in the order I used them)

> Honest split: **"Used directly"** means the resource was actually opened, downloaded, or run.
> **"Framework documentation"** lists the official docs for the APIs in the code. The code was written by Claude Code
> from its own knowledge of these frameworks, not by reading these pages during the project.
> I did not work through the SwiftUI tutorial pages step by step; I started from Apple's finished project and learned by
> modifying it and testing each stage.

### Used directly
1. **Mac App Store: Xcode 27**. Installed the IDE. Learned the command-line tools alone can't build apps, and that
   `xcode-select`, license acceptance, and `-runFirstLaunch` need admin rights.
2. **Course resource docs** ([resource doc 1](https://docs.google.com/document/d/1QMMM9BTS7GB3WujJDrXqdTqGYNvx3_rp1TzdKJ4vfM8/edit),
   [resource doc 2](https://docs.google.com/document/d/1ImiDiXD3tflsosJKj1U_nRopTYPDRFVImCj4UQjnKS0/edit)). I downloaded and read both to choose a direction;
   the "iOS Core Motion / sensors" entry pointed toward using a device sensor.
3. **Kodeco, [Your First iOS and SwiftUI App](https://www.kodeco.com/4919757-your-first-ios-and-swiftui-app)** (from the course list).
   Used as a beginner reference for SwiftUI app structure. I didn't build its project: it targets Xcode 11 / iOS 13 (2019)
   and the materials need a sign-in, so Apple's current sample became the starting point instead.
4. **Apple, [SwiftUI Tutorials: Handling User Input](https://developer.apple.com/tutorials/swiftui/handling-user-input)**.
   Downloaded the completed project (`HandlingUserInput.zip`) and used it as the starting point: built it unmodified on my
   iPhone, then modified it into Quiet Spots.
5. **[GitHub CLI](https://cli.github.com/)** on GT Enterprise GitHub. Created the repo, labels, and issues from the terminal.
6. **[XcodeGen](https://github.com/yonaskolb/XcodeGen)**. Installed with Homebrew; generates the Xcode project from `ios/project.yml`.
7. **[Wrangler](https://developers.cloudflare.com/workers/wrangler/)** (Cloudflare CLI). Local dev server, D1 database, migrations, secrets, deploy.
   Its error messages guided the workers.dev subdomain fix.
8. **[Cloudflare REST API](https://developers.cloudflare.com/api/)**. Registered the workers.dev subdomain when Wrangler's interactive prompt couldn't run.
9. **[Open-Meteo API](https://open-meteo.com/)**. Called live by the backend for weather (no API key).
10. **[Playwright](https://playwright.dev/)**. Opened pages that need JavaScript (found the sample's download link) and screenshotted the web dashboard to check its layout.

### Framework documentation (APIs used in the code)
- Apple: [SwiftUI](https://developer.apple.com/documentation/swiftui), [AVAudioRecorder](https://developer.apple.com/documentation/avfaudio/avaudiorecorder) (microphone metering),
  [CoreLocation](https://developer.apple.com/documentation/corelocation), [MapKit for SwiftUI](https://developer.apple.com/documentation/mapkit/mapkit-for-swiftui),
  [UserNotifications](https://developer.apple.com/documentation/usernotifications), [BackgroundTasks](https://developer.apple.com/documentation/backgroundtasks),
  [Keychain Services](https://developer.apple.com/documentation/security/keychain-services),
  [String Catalogs](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog),
  [XCTest UI testing](https://developer.apple.com/documentation/xctest/user-interface-tests)
- Push comparison: [APNs](https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns), [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging/ios/client)
- Backend: [Cloudflare Workers](https://developers.cloudflare.com/workers/), [D1](https://developers.cloudflare.com/d1/), [Hono](https://hono.dev/)

### AI / virtual teammate
- **Claude Code (Anthropic), model Claude Opus 5**, used as a virtual teammate throughout. It substantively:
  checked my environment and walked me through Xcode and device setup; proposed the architecture; wrote the backend,
  the iOS changes on top of Apple's sample, the tests, and the Spanish translations; ran builds, tests, and the deploy;
  and debugged the problems listed below. Dated log of what I asked for, what it did, and what I checked:
  [`docs/ai-log.md`](ai-log.md).

  **How I used it:** I chose the app idea, directed the features and design choices (for example: build on a real sample so
  the modification is visible, make it original, keep commits under my account), personally tested the app on my iPhone,
  and gave feedback. Claude provided substantial coding assistance; I guided what we were building and checked how it worked.
  **What I learned:** AI can move quickly, but it needs clear direction and hands-on testing, and I'd review each change as
  it's introduced next time.

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
06bf75b  Sep 14 21:02  Run unmodified Landmarks sample on iPhone and draft submission
11ea1ee  Sep 14 21:05  Add screenshots of Quiet Spots running on iPhone
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
