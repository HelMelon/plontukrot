# ADR-035: Persistent Crash Logging and Stream Resilience

## Status

Accepted

## Context

After the migration from Firebase to FastAPI (ADR-033), Crashlytics was replaced by in-memory `debugPrint` calls. Consequently, runtime failures and network drops occurring on user devices were not persisted, making post-incident diagnostics impossible without an active debugger.

Additionally, when an error occurred during background data polling or after mutating operations (such as leaf counter changes in `PlantDetailsPage`), `restPollStream` propagated the error to `StreamBuilder`, causing the active UI to be replaced with an infinite loading spinner (`AccessibleProgressIndicator`) rather than retaining cached content or displaying an explicit error state.

## Decision

1. **Persistent Local Logging (`AppCrashReporting`):**
   - Save uncaught errors, caught exceptions, and diagnostic entries into a local log file (`app_errors.log`) using `path_provider` (`getApplicationSupportDirectory` / `getApplicationDocumentsDirectory`).
   - Retain an in-memory ring buffer (up to 200 entries) for immediate inspection across all platforms.
   - Include UTC ISO timestamp, user ID, log level (`FATAL`, `ERROR`, `INFO`), reason tag, message, and formatted stack trace.
   - Automatically cap log file size (512 KB threshold, trimmed to 256 KB) to prevent unbounded storage growth.
   - Automatically record all HTTP 4xx/5xx errors, network socket exceptions, and timeouts directly in `ApiClient`.

2. **Stream UI Resilience (`restPollStream`):**
   - When a polling cycle fails and previous data (`lastValue`) already exists, log the error via `AppCrashReporting` but do not emit `controller.addError(error, stack)`. This keeps active screens rendered with their existing data rather than clearing the UI.
   - For the initial fetch (`!hasValue`), emit `controller.addError` so the view can render an explicit error state.

3. **Explicit Error States (`PlantDetailsPage`):**
   - Handle `snapshot.hasError` with an error icon, localized error message (`l10n.commonError`), and a back navigation button.
   - Differentiate initial loading state (`ConnectionState.waiting`) from empty/deleted data (`l10n.commonNoData`).

## Implementation

- `lib/services/app_crash_reporting.dart`: Added file logging, memory ring buffer, size trimming, `getRecentLogs()`, `getLogFilePath()`, and `clearLogs()`.
- `lib/services/rest_stream.dart`: Integrated error reporting and cached-value retention on polling failures.
- `lib/services/api_client.dart`: Integrated automatic error recording for network exceptions and failing HTTP responses.
- `lib/features/plants/pages/plant_details_page.dart`: Added explicit error and not-found states to `StreamBuilder<Plant?>`.
- `lib/features/plants/widgets/growth/leaf_removal_reason_sheet.dart`: Wrapped leading icons in `ExcludeSemantics`.

## Behavior

- Errors and exceptions are saved to disk with timestamps and stack traces, remaining inspectable after app restarts.
- Failed leaf removal or background polling no longer blanks the plant details screen into an infinite spinner.
- If initial loading fails, users see a clear error message and can navigate back.

## Consequences

- Full error diagnostics are available locally on devices even in release/profile mode without third-party services.
- UI screens powered by `restPollStream` stay stable during temporary connectivity issues.
- Disk usage for logs is strictly bounded to under 512 KB.

## Verification

- `flutter analyze lib/services/app_crash_reporting.dart lib/services/rest_stream.dart lib/services/api_client.dart lib/features/plants/pages/plant_details_page.dart lib/features/plants/widgets/growth/leaf_removal_reason_sheet.dart` — passed with 0 issues.
