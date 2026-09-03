# ADR-052: Pull-to-refresh via ApiRefresh

## Status

Accepted

## Context

ADR-033 specified REST list polling plus manual refresh with
`RefreshIndicator`. After migration, lists only re-fetched on the poll
interval or after mutating writes (`ApiRefresh.ping`). There was no
user gesture that forced a new round-trip to the API/database.

## Decision

- `ApiRefresh` keeps registered handlers from every active
  `restPollStream`.
- `ping()` still fire-and-forgets (post-mutation).
- `refresh()` awaits all registered fetches so UI spinners can wait for
  the database round-trip.
- Home wraps the plant list scroll view in `RefreshIndicator` calling
  `ApiRefresh.instance.refresh()`.

## Implementation

- `lib/services/api_refresh.dart` — register / unregister / ping / refresh
- `lib/services/rest_stream.dart` — register `emit` while listeners are
  attached; serialize concurrent emits so each refresh gets a fresh fetch
- `lib/features/home/pages/home_page.dart` — `RefreshIndicator` +
  `AlwaysScrollableScrollPhysics`

## Behavior

Pulling down on the home plant list triggers a new REST GET for every
active poll stream on that screen (plants, batch counts, rerooting ids,
sensor bindings, etc.). The indicator dismisses when those fetches finish.

## Consequences

- Manual sync without waiting for the 30s poll.
- Other screens can reuse `ApiRefresh.instance.refresh()` the same way.
- A home refresh waits for all currently registered streams app-wide that
  still have listeners, not only plant streams.

## Verification

- `flutter analyze` on touched files
- Device UI not run in this change set
