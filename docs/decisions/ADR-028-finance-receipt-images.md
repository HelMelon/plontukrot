# ADR-028: Finance entry receipt images

## Status

Accepted

## Context

Users want to attach purchase/sale receipts to finance entries. Plant photos already live under Firebase Storage `plants/{uid}/…`. List performance must stay light — no automatic thumbnail loads on the finances page.

## Decision

1. **Storage:** receipt JPEGs under the same plant Storage root: `plants/{uid}/_receipts/{entryId}_{receiptId}.jpg` (existing `storage.rules` gallery path). Covered by account wipe via `deleteAllUserPlantImages`.
2. **Firestore:** `users/{uid}/financeEntries/{id}.receipts` as a list of `{id, url}` (`FinanceReceipt`). Max **5** per entry.
3. **List UI:** if `receipts` is non-empty, show an **image icon** only (`Icons.image_outlined`). Do **not** render network images in the list.
4. **View on demand:** icon opens a dialog that then loads `PlantNetworkImage` (and supports swipe if several).
5. **CRUD:** add/edit sheet can attach from gallery/camera (JPEG compress, no crop). Deleting an entry deletes its Storage objects first.
6. Auto-created finance rows (plant/propagation sale, wishlist) do not require receipts.

## Implementation

- Model: `FinanceReceipt` on `FinanceEntry`
- Service: `StorageService.uploadFinanceReceipt` / `deleteFinanceReceipt(s)`; `FinanceService` upload on add/update, delete on remove
- UI: `AddFinanceEntrySheet` chips; `FinancesPage` icon; `showFinanceReceiptsViewer`

## Behavior

- Save entry with receipt → Storage + Firestore metadata.
- Finances list shows image icon → tap → image loads.
- Remove chip in edit → Storage delete on save; delete entry → Storage cleanup.

## Consequences

- Pros: reuses plant Storage rules/wipe; list stays cheap.
- Cons: unused thumbs are not generated for receipts (full JPEG only); folder `_receipts` shares the plantId path segment convention.

## Verification

- `flutter gen-l10n`
- `flutter analyze` on finances / model / storage files
