# ADR-017: Friends, friend collections, and plant gifts

## Status

Accepted

## Context

Users need light social interaction without a messenger: add friends, view a friend’s plant collection, and gift a plant into the friend’s collection. All user data was previously owner-only under `users/{uid}`. Clients cannot write into another user’s `plants/` under that model.

## Decision

1. **Friends** — mutual friendship via pending requests mirrored under both users (`friendRequests`), then symmetric `friends/{friendUid}` docs on accept. Discovery in v1 is by pasting the friend’s Auth UID (shown/copied on the Friends page).

2. **Collection visibility** — profile field `collectionVisibility`: `friends` (default) or `private`. Friends may read plant documents when visibility is `friends`. Care subcollections stay owner-only. UI shows only non-archived plants.

3. **Gifts without Cloud Functions** — sender writes `users/{recipient}/incomingGifts/{id}` (plant card snapshot + image URLs) and `users/{sender}/outgoingGifts/{id}`. Recipient accepts → creates own plant, re-downloads photos over HTTPS and re-uploads to own Storage, marks both gift docs accepted. Sender’s app archives the source plant with `archiveReason: gifted` via `GiftService.processAcceptedOutgoingGifts()` (on authenticated shell start). Decline leaves the sender’s plant active.

4. **Gift payload** — card fields and gallery URLs only; no watering / fertilizing / notes / growthEvents / propagations.

5. **No chat** in this ADR.

## Implementation

- Models: `Friendship`, `FriendRequest`, `IncomingGift` / `OutgoingGift`, `CollectionVisibility`; `PlantArchiveReason.gifted`; optional `Plant.giftedToUid`
- Services: `FriendsService`, `GiftService`; `PlantService.getPlantsForUser` / `watchPlantForUser`; `addPlant` returns id and accepts `members`
- Rules: [`firestore.rules`](../../firestore.rules) — friend reads for profile/plants; constrained writes for requests/friends/gifts
- UI: Profile → Friends hub; friend collection + read-only details; plant details «Gift»; gift bottom sheet
- Dependency: direct `http` for photo download on accept

## Behavior

- User A copies ID → B sends request → A accepts → both appear in friends lists.
- B opens A’s collection when A’s visibility is friends; otherwise sees private message.
- A gifts a plant to B → B accepts in Friends inbox → plant appears in B’s collection; when A next opens the app (or already has shell running after refresh), A’s plant is archived as gifted.

## Consequences

- Pros: no Cloud Functions; fits existing services architecture; archive reason aligns with ADR-010.
- Cons: gift completion for the sender requires the sender client to process outgoing gifts; half-failed photo copy can leave a plant without images; friend plant list rule allows reading archived plant docs (UI filters them) to keep list queries valid; Storage remains owner-only (gift uses download URLs).

## Verification

- `flutter gen-l10n`
- `flutter analyze` on changed friends/gift/plant/profile/service files — no issues
- Device/emulator end-to-end gift flow not run in this session (requires two accounts)
- Deploy `firestore.rules` required before production use
