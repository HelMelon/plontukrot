# ADR-046: Offline Disk Cache for Genus Care Guides

## Status

Accepted

## Context

Genus care guides are generated on the FastAPI backend (DeepSeek and other LLM providers) and persisted in PostgreSQL keyed by `(genus, locale)` — see ADR-043 and ADR-044.

The Flutter client previously kept guides only in an in-memory `Map` inside `GenusCareService`. After app restart or without network, the genus page had to call the API again and showed a loading state even when the user had already fetched the same guide in a prior session.

Users need offline access to previously loaded genus care content and instant display without loading flicker on repeat visits.

## Decision

Add a **client-side JSON file cache** in the application documents directory. Do **not** introduce SQLite or `shared_preferences` for this data.

Cache lookup order in `GenusCareService`:

1. In-memory map (hydrated from disk at startup)
2. REST API (`GET /genera/{genus}/care-guide`)
3. On network/API failure — fall back to the last cached guide for that `(genus, locale)` unless `forceRefresh` is requested

Persistence rules:

- File: `genus_care_guides.json` under `getApplicationDocumentsDirectory()`
- Key: `{genus_lower}|{locale}` (same as memory cache)
- Value: serialized `GenusCareGuide.toMap()` wrapped in `{ "version": 1, "entries": { ... } }`
- Write after every successful non-empty API response
- `GenusCareService.warmDiskCache()` loads the file during app bootstrap before the main UI is shown
- `GenusCareService.peekCached()` allows UI to render cached content synchronously without a loading frame

Backend PostgreSQL remains the shared source of truth across users; the client file is a device-local offline copy only.

## Implementation

- `lib/services/genus_care_disk_cache.dart` — read/write/clear JSON file
- `lib/services/genus_care_service.dart` — memory + disk + API orchestration, offline fallback
- `lib/features/plants/widgets/cards/genus_care_guide_card.dart` — uses `peekCached` before network fetch
- `lib/main.dart` — `await GenusCareService.warmDiskCache()` during bootstrap
- `test/genus_care_disk_cache_test.dart` — disk roundtrip tests with temp file injection

## Behavior

- First visit to a genus (online): loading indicator, API fetch, guide shown, entry saved to disk
- Repeat visit (same session or after restart, offline OK): guide appears immediately from memory/disk, no loading flicker
- Retry / force refresh while offline: shows error UI; cached content is not replaced
- Locale change: separate cache entries per locale (`monstera|ru`, `monstera|en`, …)

## Consequences

- Offline access to previously fetched genus guides
- No extra dependencies (`path_provider` already in project)
- Small JSON file size; no relational queries needed on device
- Stale client cache possible until user retries online or opens genus again with network — acceptable for reference content
- `clearCache()` clears both memory and disk (for tests or future settings)

## Verification

- `flutter analyze` on touched files
- `flutter test test/genus_care_disk_cache_test.dart`
- `flutter test test/genus_care_guide_test.dart`

Manual offline verification on device was not performed in this session.
