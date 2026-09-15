# Development journal

A running log of setup steps, problems hit, and how they were solved, for the write-up.

## 2026-09-14 — Environment + backend

**Machine:** MacBook (Apple M1, 16 GB), macOS 26.6.2

### Backend
- Chose Cloudflare Workers + Hono + D1 (details in [ai-log.md](ai-log.md)).
- `wrangler dev` + `scripts/smoke.sh` pass locally, including a live Open-Meteo weather lookup.

### Git / GitHub
- Already logged into both github.com (`carlfakhir`) and github.gatech.edu (`cfakhir3`) via `gh`.
- **Problem:** global git identity was a personal alias/email, so commits would not link to my GT account.
  **Fix:** set a repo-local identity (`git config user.name/user.email`) to `cfakhir3@gatech.edu`, leaving other projects untouched.
- **Problem:** `gh repo create --internal` failed: *"internal repositories can only be created within an organization"*.
  **Fix:** created it as `--public`. On GT Enterprise GitHub that still requires a GT login to view.
- Created labels (`assignment-core`, `exceptional`, `partner`) and Issues #1–#8 as a task board.

### Xcode
- Only Command Line Tools were installed (`xcodebuild` errored: *"requires Xcode, but active developer directory is a command line tools instance"*).
- Installed **Xcode 27.0 (27A266a)** from the Mac App Store.
- **Problem:** `xcodebuild` then refused to run: *"You have not agreed to the Xcode license agreements"*.
  **Fix** (needs admin password, so run in Terminal):
  ```bash
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  sudo xcodebuild -license accept
  sudo xcodebuild -runFirstLaunch
  ```
- Verified: `xcode-select -p` → Xcode, iOS 27.0 device SDK present.
- Installed iOS 27.0 Simulator runtime (`xcodebuild -downloadPlatform iOS`, 8.05 GB) for SwiftUI previews.
- Added Apple ID in Xcode → Settings → Accounts → free **Personal Team** (apps signed this way expire after 7 days).

### iPhone
- Device: iPhone 17 Pro, iOS 26.6.2, paired over USB (`xcrun devicectl list devices`).
- **Problem:** device showed `connected (no DDI)`; `devicectl device info details` reported
  *"The operation failed because Developer Mode is turned off."* The Developer Disk Image can't mount until it's on.
  **Fix:** Settings → Privacy & Security → Developer Mode → On → restart → confirm.

### First app on the iPhone (end-to-end toolchain check)
- Generated a tiny SwiftUI "HelloDevice" app (button + tap counter) with [XcodeGen](https://github.com/yonaskolb/XcodeGen)
  (`brew install xcodegen`) so the project can be described in a text file instead of a binary `.xcodeproj`.
- **Problem:** first `xcodebuild -allowProvisioningUpdates` failed:
  *"Unable to log in with account … The login details … were rejected"* and *"No profiles for 'edu.gatech.cfakhir3.HelloDevice' were found"*.
  **Fix:** opened the project in Xcode and checked Settings → Apple Accounts (account was fine). Retrying the
  command-line build then succeeded. Xcode app refreshed the account session / signing certificate that `xcodebuild` reuses.
- Installed with `xcrun devicectl device install app`.
- **Problem:** launch failed: *"invalid code signature, inadequate entitlements or its profile has not been explicitly trusted by the user"*.
  **Fix:** on the iPhone, Settings → General → VPN & Device Management → trust the developer Apple ID. Launch then worked,
  and the device state changed from `connected (no DDI)` to `connected`.
- Screenshot: [HelloDevice running on iPhone](screenshots/01-HelloDevice-on-iPhone.png), captured with `xcrun devicectl device capture screenshot`.
- **Learned:** with a free Personal Team, signing works but each new developer must be trusted on the device and apps expire after 7 days.

## 2026-09-14 (evening) — Pivot to Quiet Spots

**Decision:** instead of a generic check-in app, build something original on top of a real sample:
*Quiet Spots*, a crowdsourced map of how loud Georgia Tech study spots are, measured with the phone microphone.
Starting point is Apple's SwiftUI **Landmarks** sample ("Handling User Input" chapter), because it already has
a list of places, a detail page with a map, a favorite button, and a filter toggle.

- Renamed the repo `checkin` → `quiet-spots` (`gh repo rename`); GitHub redirects the old URL.
- Commits are attributed only to my GT account (`cfakhir3`), verified via the GitHub API.

### Sample app committed unmodified
- Downloaded `HandlingUserInput.zip` from the Apple tutorial page (found the link by opening the page with Playwright,
  since the "Project files" button is rendered by JavaScript).
- **Problem:** `git push` failed: *"RPC failed; HTTP 400 … the remote end hung up unexpectedly"* (≈5 MB of images).
  **Fix:** `git config http.postBuffer 157286400`, then the push succeeded.
- Built for iOS with my team passed on the command line (`DEVELOPMENT_TEAM=HW9CPN28W6`) so Apple's files stay untouched.
  First attempt failed because the phone was locked/disconnected (`devicectl` showed `unavailable`), so built for
  `generic/platform=iOS` instead.

### Backend reshaped for spots + noise reports
- Migration `0002_quiet_spots.sql` drops check-ins and adds `spots` (12 GT study spots, approximate coordinates)
  and `reports` (dB level, quiet/ok/busy vote, note, distance from spot, weather at that time).
- `GET /spots` computes each spot's average level over the last 2 hours → `quiet` (<45 dB), `moderate`, `loud` (>60 dB).
- `GET /` serves a small **web dashboard**, a second client that reads the same API as the iPhone app.
- **Bug in my own test script:** the "duplicate username returns 409" check passed while the API actually returned 400.
  `bash -x` showed the JSON `{"username":…,"password":…}` inside `"$(…)"` was split by **bash brace expansion**
  into two broken requests, and `expect 400 400 409` compared the wrong arguments. The API was fine; the test was lying.
  **Fix:** build JSON in variables first, and make `expect()` fail if it doesn't get exactly 2 arguments.
- **Dashboard bug** found by screenshotting with Playwright: text read "last measured never measured". Fixed the copy.
- Local smoke test: all checks pass. ![dashboard](screenshots/03-web-dashboard-local.png)
- **Blocked:** `wrangler login` timed out waiting for browser authorization. Deploy is waiting on that.

## iOS Stage 1 — Landmarks → Quiet Spots (local data)
- Renamed the sample's files with `git mv` so history shows each Apple file becoming its Quiet Spots version
  (`Landmark.swift` → `Spot.swift`, `LandmarkList` → `SpotList`, `CircleImage` → `CategoryBadge`, …).
- Replaced the 12 national parks with 12 GT study spots (generated `spotData.json` from the backend's SQL seed so both match).
- Removed the park photos; each spot shows an SF Symbol badge for its category instead.
- Favorites moved out of the JSON into `UserDefaults`, because spot data will soon come from the server.
- Map zoom changed from 0.2° (a whole national park) to 0.004° (a single building).
- **Switched from Apple's `.xcodeproj` to [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`ios/project.yml`).**
  Adding many new Swift files to a hand-maintained `project.pbxproj` is error-prone; XcodeGen regenerates it from a short YAML file.
  The generated project is still committed so anyone can open it in Xcode without installing XcodeGen.
- Accent color set to GT Navy (Tech Gold in dark mode).
- Built and ran in the iOS 27 Simulator. ![stage 1](screenshots/04-stage1-spot-list.png)
