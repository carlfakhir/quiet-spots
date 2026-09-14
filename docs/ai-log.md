# AI / virtual teammate log

The assignment allows virtual teammates if their use is documented. This file records how I used
**Claude Code** (Anthropic's CLI coding agent, model Claude Opus 5) and what I learned.

| Date | What I asked for | What the AI did | What I checked / learned |
|---|---|---|---|
| 2026-09-14 | Help plan and build the assignment on iPhone, partner in separate repo, use my GT GitHub | Checked installed tools (no Xcode yet), proposed SwiftUI + Cloudflare Workers/D1 backend. Found I was already logged into github.gatech.edu as `cfakhir3` and set a repo-local git identity so commits are attributed to my GT account | Why Workers + D1 over Render (free tier sleeps and loses disk) or Firebase Functions (needs a paid plan) |
| 2026-09-14 | Write the backend | Generated the Hono API (`backend/src/index.ts`), D1 schema, and `scripts/smoke.sh`. Ran it locally with `wrangler dev`; all smoke tests passed, including live Open-Meteo weather for Georgia Tech | How JWT bearer auth and PBKDF2 password hashing work; D1 migrations; that Workers caps PBKDF2 at 100k iterations |
| 2026-09-14 | Install the `frontend-design` Claude Code skill from anthropics/claude-code | Downloaded `SKILL.md` into `~/.claude/skills/`, reviewed it (design guidance only, no scripts) | Skills are prompt instructions an agent loads on demand; worth reading before installing |
| 2026-09-14 | Help me set up Xcode | Checked disk space/OS compatibility, opened the App Store page, watched for install to finish, diagnosed the license error and gave me the `sudo` commands to run myself, verified SDKs, started simulator runtime download | Which steps need admin rights and why the AI can't/shouldn't run them; what `xcode-select` actually switches |
| 2026-09-14 | Get a first app running on my iPhone | Installed XcodeGen, wrote a one-screen SwiftUI test app, built/installed/launched it from the command line, diagnosed the Apple ID login and "untrusted developer" errors and told me the on-device steps | The chain: code signing → provisioning profile → install → user trust → launch, and which parts need a human on the device |
