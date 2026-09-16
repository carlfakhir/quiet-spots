# References

CS 4261 / 8803 MAS · Assignment 1 · Carl Fakhir · Quiet Spots

Listed in the order I used them, with what I used each one for and what I learned.

> Honest split: **"Used directly"** means the resource was actually opened, downloaded, or run.
> **"Framework documentation"** lists the official docs for the APIs in the code. These pages were not read
> page by page during the project; they're listed so every API in the code can be looked up.
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
5. **[GitHub CLI](https://cli.github.com/)**. Created the repo, labels, and issues from the terminal (first on GT GitHub, then on my personal GitHub).
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

### Virtual teammate
11. Required disclosure for work done with tool assistance: see the companion document *"Quiet Spots — Virtual Teammate (AI) Log"*, submitted with this assignment.
