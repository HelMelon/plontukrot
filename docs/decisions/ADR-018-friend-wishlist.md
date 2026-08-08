# ADR-018: Friend WishLeafs visibility

## Status

Accepted

## Context

Friends could already view another user’s plant collection when `collectionVisibility` is `friends`, but WishLeafs (`users/{uid}/wishList`) remained owner-only. Users want friends to see wish lists under the same privacy control as the collection, without a separate toggle.

## Decision

1. **Same gate as collection** — friends may read `wishList` documents only when `collectionVisibleToFriends` is true (profile `collectionVisibility` missing or `friends`). Private collection also hides the wish list from friends.
2. **No separate visibility field** — do not introduce `wishListVisibility`.
3. **Read-only for friends** — friends can list and view item names only; create/update/delete/acquire/export stay owner-only.
4. **Entry point** — Friends hub: heart (WishLeafs) icon next to the existing collection icon on each friend row.

## Implementation

- Rules: explicit `match /wishList/{itemId}` before the owner-only catch-all in `firestore.rules`
- Service: `WishListService.watchItemsForUser(ownerUid)`
- UI: `FriendWishListPage`; friends list opens it via `friendsOpenWishList`
- l10n: friend wish list title / empty / private strings

## Behavior

- User A sets collection visibility to friends → friend B can open A’s WishLeafs and see `nameAlt` / `nameEn`.
- User A sets collection to private → B sees “wish list is private” and cannot read items (rules deny).
- Owner’s own WishLeafs page (add/edit/delete/acquire/export) is unchanged.

## Consequences

- Pros: one privacy control for social plant data; minimal model change; consistent with ADR-017.
- Cons: cannot hide wish list while showing collection (or vice versa); requires deploying updated Firestore rules.

## Verification

- `flutter gen-l10n`
- `flutter analyze` on changed files
- Device two-account E2E not run in the implementation session
- Rules deploy required before production use
