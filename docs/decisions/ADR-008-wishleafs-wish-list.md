# ADR-008: WishLeafs wish list hub

## Status

Accepted

## Context

Users need a place to record plants they want to buy before they enter the collection. The list should support an English name plus an alternative name in the user’s own language (not a hardcoded RU/EN pair), simple CRUD, export for shopping/notes, and a direct handoff into “add plant” when the plant is purchased.

## Decision

1. **Feature hub `wish_list`** with UI title **WishLeafs** and code/entity name `wishList`.
2. **Firestore path:** `users/{uid}/wishList/{itemId}` with fields `nameEn`, `nameAlt`, `createdAt`, `updatedAt`. Covered by existing owner rules on `users/{userId}/**`. Legacy `nameRu` is read as a fallback for `nameAlt` and removed on update.
3. **Layers unchanged:** `WishListItem` in `lib/models/`, `WishListService` in `lib/services/`, UI under `features/wish_list/` (page + add/edit sheet). No Bloc/router.
4. **Home navigation:** AppBar icon `HugeIcons.strokeRoundedBookHeart` after propagation → `WishListPage`.
5. **Export:** temporary UTF-8 `.txt` named `wish-list-YYYY-MM-DD.txt`; each line `Alternative | English`; shared via `share_plus` (`SharePlus.instance.share` + `XFile`).
6. **«Купила»:** opens `AddPlantSheet` with `initialTradingName` = `nameAlt` and `wishListItemId`. English wish name is not prefilled. After successful `PlantService.addPlant`, the wish item is deleted. Genus/species remain user-filled.

## Implementation

- Model/service: `wish_list_item.dart`, `wish_list_service.dart` (stream ordered by `createdAt` desc).
- UI: `WishListPage`, `AddWishListItemSheet` (create/edit); list actions mirror care-history edit/delete icons.
- Theme: `WishListScreenTheme` card radius/padding tokens.
- Dependencies: `share_plus`, `path_provider`.
- Localization: RU/EN/DE/FR ARB keys for title, English/alternative fields, bought, export, empty, delete confirm.

## Behavior

- User adds wish entries with required English and alternative names.
- Edit/delete from the list; empty state when none.
- Export opens the system share sheet with the dated txt file.
- «Купила» prefills trading name from the alternative name; saving the plant removes the wish entry. If save fails, the wish entry stays.

## Consequences

- Only `nameAlt` maps to `tradingName`; nickname and botanical fields stay empty for the user to fill.
- English stays as the shared/international label; the alternative field is locale-agnostic free text.
- Export depends on temporary filesystem + share sheet (mobile-oriented; not a cloud export).
- Hub composition on `HomePage` now also imports `wish_list`.

## Verification

- `flutter gen-l10n`
- `dart analyze` on wish_list model/service/UI after rename
- Device UI not run in this session
