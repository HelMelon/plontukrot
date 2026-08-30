# ADR-045: Application versioning (SemVer + cider)

## Status

Accepted

## Context

The app lived at `1.0.0+1` in `pubspec.yaml` while history grew to ~195 commits
with ~36 `feat` and ~48 `fix` Conventional Commits. There were no git tags,
no CHANGELOG, and no release workflow. Store uploads require a monotonically
increasing build number (`+N` in Flutter).

We need:

- a user-visible **SemVer** (`MAJOR.MINOR.PATCH`);
- an automatic **build number** tied to git;
- bumps driven by commit types since the last tag;
- a repeatable release command for future uploads.

## Decision

Adopt **Semantic Versioning** with **[cider](https://pub.dev/packages/cider)** as
the tooling layer:

| Part | Rule |
|------|------|
| `MAJOR.MINOR.PATCH` | SemVer; decided at release time from commits since last tag |
| `+BUILD` | Set to `git rev-list --count HEAD` on each release |
| `feat` since tag | → **minor** bump |
| `fix` / `perf` since tag | → **patch** bump (when no `feat`) |
| `BREAKING CHANGE` / `type!:` | → **major** bump |
| Git tag | Annotated tag `vX.Y.Z` on each release commit |

**Baseline (retroactive, 2026-08-30 — revised from full git log):**

Version **`2.5.0+195`**.

**What git actually shows for `pubspec.yaml`:** only `version: 1.0.0+1` since
`cf88b2e` (2026-06-08 initial commit). No manual bump was ever committed — the
`Fix: update versions for ios build` commits changed dependencies/SDK, not app
version. The user's «на шару» value is the untouched Flutter template.

**Counting mistake in earlier baselines:**

| Pass | What was counted | Result |
|------|------------------|--------|
| 1st | 9 `feat:` after migration only | 1.3.0 |
| 2nd | 36 `feat:` total | 2.3.0 |
| **3rd** | **Full log**: 36 `feat:` + ~50 early commits (`propagation feature`, `Add WishLeafs`, `add bulk plant actions`, …) | **2.5.0** |

**Timeline from commit history** (minor = shipped batch, not single commit):

| Version | When (2026) | From git history |
|---------|-------------|------------------|
| **1.0.0** | Jun 8 | initial commit; `1.0.0+1` in pubspec (placeholder) |
| **1.1.0** | Jul 27–28 | repotting + soil, propagation, home redesign, bulk/sort |
| **1.2.0** | Jul 29–Aug 4 | taxonomy, variegation, genus, growth, propagation lifecycle |
| **1.3.0** | Aug 5 | wish list, finances, groups/archive, crop |
| **1.4.0** | Aug 7–10 | profile, splash, friends, a11y, keyboard, receipts |
| **1.5.0** | Aug 14 | fertilizing reminders, bulk notes |
| **2.0.0** | Aug 20 | FastAPI backend + Flutter REST migration (`cbff992`) |
| **2.1.0** | Aug 20–21 | manipulations UI, photos on disk, CORS, reanimation |
| **2.2.0** | Aug 25 | hybrid, rescue, manipulations API, Yandex sensor skill |
| **2.3.0** | Aug 26 | repotting PATCH/DELETE, timezone, required plant name |
| **2.4.0** | Aug 28 | filter bottom sheet, JWT persistence, profile notifications |
| **2.5.0** | Aug 28 | genus AI care guide (current baseline) |

Build **`195`** = `git rev-list --count HEAD`.

## Implementation

- `pubspec.yaml` — `version: 2.5.0+195`; `cider` in `dev_dependencies`
- `CHANGELOG.md` — Keep a Changelog format; `## Unreleased` for pending notes
- `tool/version_report.ps1` — read-only analysis and suggested next bump
- `scripts/release.ps1` — bump, changelog release, commit, tag
- `scripts/release.ps1 -Baseline` — one-time annotated tag when tree is clean

Release flow (after baseline tag exists):

```powershell
# inspect
.\tool\version_report.ps1

# release (auto-detect patch/minor/major from commits since last tag)
.\scripts\release.ps1 -Bump auto

git push; git push --tags
```

Manual changelog entries before release (optional):

```powershell
dart run cider log added "Short user-facing summary in Russian or English"
dart run cider log fixed "Bug fix summary"
```

## Behavior

- **Between releases:** developers keep using Conventional Commits; version in
  `pubspec.yaml` stays at the last release until `release.ps1` runs.
- **On release:** build number always syncs to current commit count; tag name
  matches semver without build (`v1.4.0`, not `v1.4.0+200`).
- **Stores:** Google Play / App Store see increasing `+BUILD`; users see
  `1.4.0` (or whatever semver was bumped to).

## Consequences

**Benefits**

- Version reflects feature/fix batches, not raw commit count.
- One script for bump + changelog + tag; cider keeps `pubspec.yaml` in sync.
- `version_report.ps1` answers “what should the next version be?” without edits.

**Trade-offs**

- Baseline minors (`1.1`–`1.3`) are grouped by feature waves, not automatic
  per-commit math — document new waves in CHANGELOG when releasing.
- `release.ps1` commits and tags; run only on clean `main` (or release branch).
- Changelog is not fully auto-generated from git; use `cider log` or edit
  `## Unreleased` before `cider release`.

**Future**

- CI can run `version_report.ps1` on PRs and fail if release notes are missing.
- Optional: GitHub Action on tag push to build store artifacts.

## Verification

- `dart pub get` — cider resolves
- `dart run cider version` — prints `2.5.0+195`
- `dart run cider list` — lists `2.5.0`
- `.\tool\version_report.ps1` — runs without modifying files
- `flutter analyze` — no new issues from versioning files

Baseline git tag `v2.5.0` is created by the maintainer after committing these
files: `.\scripts\release.ps1 -Baseline` (clean tree).
