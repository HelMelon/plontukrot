# ADR-036: Centralized semantic icon tokens

## Status

Accepted

## Context

UI widgets across the application referenced hardcoded `Icons.*` and `HugeIcons.*` directly in presentation and sheets. This violated the theme token architecture guidelines and made it difficult to adjust, replace, or theme icons centrally without mass-editing screens.

Similar to `lesesucht-flutter`, icons should be semantically organized in tokens and accessible via `context.icons` or `AppTheme.icons`.

Certain explicit exceptions exist:
- Domain model `variegation.dart` keeps its own icon metadata.
- Plant details care history `InfoCard` webp asset icons (`assets/icons/watering.webp`, `assets/icons/fertilize.webp`, `assets/icons/potting.webp`, `assets/icons/trimming.webp`) are specific asset illustrations and are intentionally excluded from the icon token set.
- All standard `AppBar`, actions, sheets, dialogs, forms, and cards icons must use semantic tokens.

## Decision

1. **`AppIconTokens`** created under `lib/core/theme/tokens/app_icon_tokens.dart`:
   - Defined semantic icon properties grouped into:
     - Generic actions & controls (`add`, `remove`, `edit`, `editOutlined`, `delete`, `deleteFilled`, `clear`, `close`, `back`, `search`, `copy`, `share`, `uploadFile`, `check`, `checkCircleOutlined`, `chevronRight`, `chevronDown`, `chevronUp`, `arrowDownward`, `arrowUpward`, `radioChecked`, `radioUnchecked`, `selectAll`, `deselectAll`, `removeCircle`, `addCircle`).
     - Dialogs, info & status (`info`, `help`, `error`, `calendar`, `calendarOutlined`).
     - Navigation & main features (`propagations`, `wishlist`, `finances`, `archive`, `archiveAction`, `gift`, `notifications`, `friends`, `profile`, `collection`, `friendRemove`).
     - Botany, plants & photos (`genus`, `species`, `cultivar`, `tradingName`, `family`, `familyHub`, `nickname`, `stage`, `leaf`, `photoAdd`, `photoDelete`, `laurelWreath`, `camera`, `cameraOutlined`, `gallery`, `galleryOutlined`, `image`, `addImage`, `brokenImage`, `addPhotoPlaceholder`, `addPhotoOutlined`, `plantPlaceholder`, `plantSearchIcon`).
     - Care & manipulations (`watering`, `wateringFilled`, `wateringHistory`, `fertilizing`, `fertilizingFilled`, `fertilizingEco`, `repotting`, `repottingAction`, `note`, `noteAction`, `notesOutlined`, `paymentsOutlined`, `merge`, `pinching`, `rerooting`, `stimulator`, `leafCut`, `leafEaten`, `lossDied`, `lossSold`).
     - Auth & inputs (`personOutline`, `email`, `emailUnread`, `lock`, `visibility`, `visibilityOff`, `link`, `translate`).
2. Integrated `AppIconTokens` into `AppThemeTokens`, exposed via `context.icons` extension in `theme_context.dart`, and static alias `AppTheme.icons` in `app_theme.dart`.
3. Updated all UI widgets, pages, and sheets across the app to use `context.icons`.

## Implementation

- **Theme layer:**
  - `lib/core/theme/tokens/app_icon_tokens.dart`
  - `lib/core/theme/app_theme_tokens.dart`
  - `lib/core/theme/theme_context.dart`
  - `lib/core/theme/app_theme.dart`
- **Features migrated:**
  - `lib/core/widgets/app_bar_chrome_actions.dart`
  - `lib/features/home/pages/home_page.dart`
  - `lib/features/plants/pages/plant_details_page.dart`
  - `lib/features/plants/pages/plant_archive_page.dart`
  - `lib/features/plants/widgets/cards/plant_card.dart`
  - `lib/features/plants/widgets/cards/plant_image_card.dart`
  - `lib/features/plants/widgets/cards/plant_info_card.dart`
  - `lib/features/plants/widgets/cards/placeholder_widget.dart`
  - `lib/features/plants/widgets/growth/plant_leaf_counter.dart`
  - `lib/features/plants/widgets/growth/plant_vine_painter.dart`
  - `lib/features/plants/widgets/growth/leaf_removal_reason_sheet.dart`
  - `lib/features/plants/widgets/notes/plant_note_tile.dart`
  - `lib/features/plants/widgets/propagations/plant_propagations_section.dart`
  - `lib/features/plants/widgets/search/plant_search_delegate.dart`
  - `lib/features/plants/widgets/selectors/fertilizing_frequency_field.dart`
  - `lib/features/plants/widgets/common/expandable_side_scroll_list.dart`
  - `lib/features/plants/widgets/common/pick_and_crop_plant_photo.dart`
  - `lib/features/plants/widgets/common/plant_pending_photo_control.dart`
  - `lib/features/plants/widgets/tags/soil_component_tags.dart`
  - `lib/features/plants/widgets/tags/fertilizer_component_tags.dart`
  - `lib/features/plants/widgets/sheets/*.dart` (all sheets: add/update/merge/archive plant, propagations, care histories, fertilizer/stimulator management, etc.)
  - `lib/features/propagations/pages/propagations_page.dart`
  - `lib/features/friends/pages/friends_page.dart`
  - `lib/features/friends/pages/friend_wish_list_page.dart`
  - `lib/features/profile/pages/profile_page.dart`
  - `lib/features/wish_list/pages/wish_list_page.dart`
  - `lib/features/wish_list/widgets/sheets/add_wish_list_item_sheet.dart`
  - `lib/features/finances/pages/finances_page.dart`
  - `lib/features/finances/widgets/finance_receipt_viewer.dart`
  - `lib/features/finances/widgets/sheets/add_finance_entry_sheet.dart`
  - `lib/features/auth/pages/login_page.dart`
  - `lib/features/auth/pages/email_verification_page.dart`
  - `lib/features/auth/widgets/sheets/email_sign_in_sheet.dart`
  - `lib/features/auth/widgets/sheets/email_register_sheet.dart`

## Behavior

- Visual representation of icons is maintained identically to prior design while all icon data references are centralized in theme tokens.
- Changing or upgrading an icon asset or library in the future only requires modifying `AppIconTokens`.
- Care history InfoCards retain their custom `.webp` illustrations.

## Consequences

- Complete compliance with `theme-tokens.mdc` for icons.
- Easier theming, icon pack swapping, and visual consistency audits.
- No direct `IconData` / `HugeIcons` literals scattered across UI widgets.

## Verification

- `flutter analyze` completed with 0 errors/warnings on `lib/`.
