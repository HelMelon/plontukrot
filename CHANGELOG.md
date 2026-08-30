# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## 2.5.0 - 2026-08-30

Retroactive baseline from **full git history** (195 commits, Jun 8 – Aug 28 2026).
See ADR-045. Committed `pubspec` was **`1.0.0+1`** (Flutter default) since initial
commit — never bumped in git.

### Added (2.x — since Aug 20 migration)

- Genus AI care guide, filter bottom sheet, bulk manipulations, reanimation tags
- Hybrid/rescue filters, soil-moisture / Yandex Smart Home backend, repotting API
- JWT session persistence, notification permission on profile

### Added (1.x — Jul–Aug, before 2.0.0)

- Repotting + soil builder, propagation, taxonomy, variegation, genus browse
- Wish list, finances + receipts, groups/archive, photo crop, profile + consent
- Friends/gifts, splash, a11y + keyboard (web), fertilizing reminders, bulk notes
- Manipulation journal (Firebase era, completed after cutover)

### Changed

- **2.0.0** (2026-08-20) — self-hosted FastAPI backend; Flutter on REST + JWT

### Fixed

- PlantCard overflow on mobile grids
- Notification permission status on profile; reminder enablement flow
- Auth session persistence (extended JWT lifetime and cached profile)
- Propagation outcome quantity copy; empty default for outcome count
- Calendar dates kept in local day with device time zone sent to backend
