# AGENTS.md

SwiftUI iOS app (Gitea client). Single Xcode project `Gitea.xcodeproj`, scheme `Gitea`, target `Gitea.app`. No Swift Package manifest — dependencies are SPM packages referenced from the Xcode project (`Package.resolved` under `Gitea.xcodeproj/.../swiftpm/`).

## Commands

- Format (tabs, lineLength 200, `format.json`): `./fmt.sh` — runs `swift format -irp --configuration ./format.json ./Gitea`. Run before committing.
- Build: `xcodebuild -project Gitea.xcodeproj -scheme Gitea -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build` — **iPhone 15 Pro is the only available simulator**; `iPhone 16` does not exist in this sim list and fails.
- No test target or test suite exists. No lint/typecheck step beyond `swift format`.

## API client codegen (critical)

The Gitea API client is **generated at build time** by the swift-openapi-generator Xcode build plugin from:
- `Gitea/openapi.json` — API schema, raw download of `https://git.schindlerfelix.de/openapi3.v1.json` (the only committed source of truth; the plugin accepts JSON natively)
- `Gitea/openapi-generator-config.yaml` — generates `types` + `client`, `public` access, idiomatic naming

Generated `Types.swift`/`Client.swift` are **not committed**; never hand-edit them. To change the API surface, regenerate `Gitea/openapi.json` (see README "Regenerate API client": `curl https://git.schindlerfelix.de/openapi3.v1.json > Gitea/openapi.json`), then rebuild. `Gitea/Core/GiteaClient.swift` is the hand-written wrapper (auth token via `Authorization` header).

**Codegen fallout gotcha:** the server spec has no `required` markers — regenerating makes *every* schema property optional (`String?`, `Int64?`, `Date?`, `Bool?`) and turns enum-typed properties into single-value payload structs accessed via `.value1` (e.g. `CreateRepoOption.ObjectFormatNamePayload(value1: .sha1)`, `org.visibility?.value1.rawValue`). `Issue.state` is `StateType?` but `PullRequest.state`/`Milestone.state` are `Payload?` — check the generated `Types.swift` (under DerivedData `Build/.../BuildToolPluginIntermediates/Gitea.output/.../GeneratedSources/`, not `Index.noindex/`) before assuming. Diff/raw-content endpoints return `.ok.body.json(String)` or `.ok.body.binary`, never `.plainText`. After a spec bump, build errors cascade per closure — iterate: `xcodebuild ... build 2>&1 | grep -E 'error|BUILD' | sort -u`, fix, rebuild.

## Releases

Push tag `vX.Y.Z` → `.github/workflows/release.yml` + `.gitea/workflows/release.yml` create releases with body from `changelogs/vX.Y.Z.md`. Release process: bump version in Xcode → add `changelogs/vX.Y.Z.md` → tag and push. Commit convention (from git log): `fix(scope):`, `feat(scope):`, `imp(scope):`, `chore:`, `refactor:`.

## Repo layout

- `Gitea/` — app source. Feature dirs: `Actions`, `Activity`, `Auth` (instances, session, network), `Base` (root views), `Repo`, `Issues`, `Releases`, `Organizations`, `Packages`, `Milestones`, `User`, `General`, `Misc`; `Core/` holds shared helpers (paging, load states, emoji). UI text lives in `Gitea/Localizable.xcstrings` — update it for user-facing strings.
- `ci_scripts/` — Xcode Cloud post-clone hook.
- `Settings.bundle` — app settings, regenerated via `license-plist --config-path license_plist.yml` (only when dependencies change).

Remote is Gitea (`git@git.schindlerfelix.de:Tanuki/gitea-ios.git`); GitHub (`cup-for-gitea`) is a mirror, see README for fetching upstream PRs.
