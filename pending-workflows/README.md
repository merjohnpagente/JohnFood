# MOVE THESE, then delete this folder

These 5 files are staging copies of the CI/CD workflows.
They belong at `.github/workflows/` but the current deploy token
lacks the `workflow` scope, so they cannot be pushed there by automation.

Phone steps (github.com, repo merjohnpagente/JohnFood):
1. Open each file here, copy its full text.
2. Add file → Create new file → name it `.github/workflows/<same-name>.yml`
   → paste → Commit directly to `main`. Repeat for all 5.
3. Delete the auto-added `.github/workflows/dart.yml` (it runs `dart test`,
   which fails on Flutter projects; `ci.yml` already covers analyze+test).
   Delete this `pending-workflows/` folder the same way.
4. OR: send a classic token with `repo` + `workflow` scopes and the
   `workflows-pending` branch gets pushed in one command.

Workflows: build-android (APK + Release), deploy-web (GitHub Pages),
deploy-vercel (johnfoodapp static), deploy-firebase (rules+indexes),
ci (analyze + test + emoji check).
