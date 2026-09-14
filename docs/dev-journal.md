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
- **Learned:** with a free Personal Team, signing works but each new developer must be trusted on the device and apps expire after 7 days.
