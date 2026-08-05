# ADR-009: Finances hub and currency preference

## Status

Accepted

## Context

Users need to track plant-related money: sale income from propagation batches, purchase expenses (including wishlist buys and catalog materials), and a short rolling summary. Currency should be choosable independently of UI language. Trades/exchanges must not create money records.

## Decision

1. **Feature hub `finances`** with UI under `features/finances/`, model `FinanceEntry` in `lib/models/`, service `FinanceService` in `lib/services/`. No Bloc/router.
2. **Firestore path:** `users/{uid}/financeEntries/{id}` with fields `title`, `amount`, `type` (`income` | `expense`), `source`, `date`, optional `note`, `propagationId`, `wishListItemId`, `quantity`, timestamps. Covered by existing owner rules on `users/{userId}/**`.
3. **Sources that create entries:**
   - manual income/expense from the finances page;
   - propagation **sold** → income (quantity + amount);
   - wishlist **bought** → expense (price), then existing `AddPlantSheet` handoff;
   - manual expense with catalog chips → expense + catalog add:
     - soil component → `ComponentService`;
     - fertilizer ingredient → `FertilizeService.addIngredient`;
     - ready-made fertilizer → `FertilizeService.addFertilizer` (`FertilizerKind.purchased`);
     - ready-made soil mix → `SoilService.addSoil` (name only, empty composition).
4. **Sources that do not create entries:**
   - wishlist **exchanged**;
   - propagation **traded** (optional “for a wish-list plant” → select wish → `AddPlantSheet` only).
5. **Currency:** local-only `AppCurrencyController` (SharedPreferences), default **USD**. Options: USD, EUR, RUB, BYN. Selected on Settings under language. Amounts are stored as bare numbers; display uses the chosen symbol.
6. **Home navigation:** AppBar icon `HugeIcons.strokeRoundedCoins01` after WishLeafs → `FinancesPage`.
7. **Analytics:** last three calendar months on the finances page — income, expense, balance (`income − expense`), plus per-month breakdown. Trades are excluded by not being stored.
8. **CRUD UI:** list edit/delete icons and confirm dialogs match care-history / WishLeafs patterns; create/edit via bottom sheet with selectable date.

## Implementation

- Model/service: `finance_entry.dart`, `finance_service.dart` (stream ordered by `date` desc; month summary helper).
- Currency: `core/currency/app_currency.dart`, `app_currency_controller.dart`; loaded in `main.dart`.
- UI: `FinancesPage`, `AddFinanceEntrySheet`; wishlist `WishListAcquireSheet`, `SelectWishListItemSheet`; propagation sale amount field + trade wish-list chip handled via `MarkPropagationOutcomeResult` in details sheet.
- Theme: `FinancesScreenTheme` card/analytics tokens.
- Localization: RU/EN/DE/FR ARB keys for finances, currency, wishlist acquire/trade, skip/continue.

## Behavior

- User opens Finances from home, sees 3-month analytics and separate income/expense lists.
- Manual entries require title, amount, type, date; expense may also seed soil component, fertilizer ingredient, purchased fertilizer, or ready-made soil catalogs.
- Selling a propagation batch asks for quantity and money and writes an income entry.
- Trading a batch never writes finance; optional wish-list plant selection opens add-plant flow.
- Wishlist “Купила” opens acquire sheet: Bought records expense then add-plant; Exchanged skips finance then add-plant.
- Currency changes on Settings immediately affect formatting via `ListenableBuilder`.

## Consequences

- Amounts are not multi-currency historical — changing preference re-labels existing numbers with the new symbol (no FX conversion).
- Wishlist buy that is cancelled after the expense is saved can leave an orphan expense until the user deletes it.
- Propagation model remains quantity-only; money lives only in `financeEntries`.

## Verification

- `flutter gen-l10n`
- `flutter analyze` on changed finance/currency/wishlist/propagation/home/settings/theme files — no issues
- Device UI not run in this session
