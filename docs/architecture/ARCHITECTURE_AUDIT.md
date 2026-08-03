# Architecture Audit

**Date:** 2026-08-03  
**Scope:** `lib/`, `docs/architecture/`, `docs/decisions/`, `.cursor/rules/`  
**Method:** Compare real code ↔ living docs ↔ Cursor rules. No code was changed.

Legend:

| Severity | Meaning |
|----------|---------|
| **H** | Clear rule violation or blocking contradiction |
| **M** | Soft violation, stale guidance, or under-documented drift |
| **L** | Style / consistency; low architecture risk |
| **A** | Accepted exception (documented in rules and/or docs — do not auto-fix) |

---

## 1. Executive summary

The codebase largely matches the **feature UI + shared models + shared Firebase services** shape described in docs and enforced by project rules. Firebase is mostly out of widgets. There is **no** Clean Architecture layering and **no** Bloc/Riverpod/GetIt — and that is intentional.

Main problems are not “wrong stack”, but:

1. **Internal rule contradictions** (especially localization and cross-feature imports).
2. **Stale Cursor rules** that still describe a Russian-only, hardcoded-string UI.
3. **Hidden couplings** (service→service, model→Flutter, model→Firestore).
4. **Docs understating** one accepted cross-feature edge (`propagations` → `plants` sheets) and omitting `architecture-status.mdc` from the “source of truth” table.

Global Home agent rules (Clean Architecture + flutter_bloc) **conflict** with this project; `.cursor/rules/project-context.mdc` correctly says project rules win.

---

## 2. Alignment matrix

| Topic | Code | Docs | `.cursor/rules` | Verdict |
|-------|------|------|-----------------|---------|
| Feature-first, no data/domain folders | Yes | Accurate | Accurate | Aligned |
| No repositories / Bloc / GetIt | Yes | Accurate | Accurate (`flutter-style`) | Aligned |
| Services own Firebase I/O | Mostly yes | Accurate | Accurate | Aligned + one UI Auth typing leak |
| Models in `lib/models/` only | Yes | Accurate | Accurate | Aligned |
| Models must not import UI | **Violated** (`Variegation`) | Documented as debt | Forbidden in `architecture.mdc` | **H** (also **A** only if treated as debt, not exception formally) |
| Models may map Firestore | Yes | Documented | **A** via `architecture.mdc` + `architecture-status.mdc` | Aligned as accepted |
| Feature A ↛ Feature B widgets | **Violated** (home, propagations) | Partially documented (hub focus) | Forbidden **and** softened | Contradiction (**H** docs/rules; **A** in status rule) |
| UI copy Russian / `Locale('ru')` | **No** — ARB en/ru/de/fr | Accurate (l10n ADR) | **Stale** (`project-context`, `ui-conventions`, `models`) | **H** rules↔code |
| Enum `.label` Russian | **No** — labels via `app_localizations_x` | Accurate | Stale (`models.mdc`) | **M** |
| Named types `PlantModel` / `FertilizerService` / `PlantListPage` | Do not exist | Docs warn about this | Still in `architecture.mdc` examples | **M** |
| Firebase tree includes `plantSpecies` | Yes | Documented in firebase.md | **Missing** from tree in `firebase.mdc` | **M** |
| File size ~200–300 lines | Many files larger | Debt listed for home | `flutter-style` | **L**/`M` |
| Testing | l10n + stub widget | Accurate | Checklist aspirational | Aligned on “thin coverage” |

---

## 3. Violations of architectural rules

### 3.1 Models import UI — **H**

| Rule | `architecture.mdc`: models must never import UI |
| Code | `lib/models/variegation.dart` imports `package:flutter/material.dart` (`IconData`, `Color`, `Icons`, `Colors`) |
| Docs | Listed under Current Technical Debt; not listed under accepted exceptions |
| Status | Real violation. `architecture-status.mdc` does **not** waive it. |

### 3.2 Feature → feature widget imports — **H** vs rule text / **A** vs status

| Source | Import |
|--------|--------|
| `features/home/pages/home_page.dart` | plants sheets/pages/cards/search; `PropagationsPage`; `SettingsPage` |
| `features/propagations/pages/propagations_page.dart` | `features/plants/widgets/sheets/propagation_details_sheet.dart` |

| Rule conflict |
|---------------|
| `architecture.mdc` **Forbidden:** feature A widgets → feature B widgets |
| Same file **Accepted:** hub pages may compose UI from multiple features |
| `architecture-status.mdc` **Accepts:** home **and** propagations cross-feature deps; do not auto-refactor |

| Docs gap |
|----------|
| Overview documents Home hub exception well |
| Overview does **not** clearly mark `propagations → plants` as an accepted second edge (only implies plants public API) |
| Overview “source of truth” table omits `architecture-status.mdc` |

### 3.3 Firebase type in UI — **M** (documentedly accepted leak)

| Rule | Pages/widgets never access Firebase directly |
| Code | `login_page.dart` imports `firebase_auth` and branches on `FirebaseAuthException` |
| Docs | Debt item + firebase.md accepted exception |
| Note | No Firestore/Storage usage under `features/`. Boundary otherwise healthy. |

### 3.4 `currentUser!` inside every service — **A**

Waived explicitly by `architecture-status.mdc`. Docs also describe it. Not a finding to fix.

### 3.5 UI triggers data migrations — **M**

| Code | `HomePage` StreamBuilder calls `PlantService().migrateCareDates` / `migrateBotanicalFields` |
| Rules | Services should contain data operations; migration in UI lifecycle mixes concerns |
| Docs | Called out as technical debt |
| Risk | Side effects on every plants snapshot until flags are set; harder to reason about first paint |

### 3.6 Style: oversized files — **L**→**M**

`flutter-style.mdc`: split when file exceeds ~200–300 lines.

| File | ~Lines |
|------|--------|
| `home_page.dart` | 1147 |
| `add_fertilizing_sheet.dart` | 665 |
| `add_repotting_sheet.dart` | 469 |
| `manage_fertilizers_sheet.dart` | 447 |
| `sell_lose_propagation_sheet.dart` | 411 |
| `plant_info_card.dart` | 380 |
| `propagation_details_sheet.dart` | 375 |
| `propagations_page.dart` | 371 |
| `update_plant_sheet.dart` | 361 |
| `propagation_service.dart` | 352 |

Docs mention only home. Rules apply more broadly.

### 3.7 Theme colors outside `AppColors` — **L**

`ui-conventions.mdc`: colors from `AppColors` only.

Scattered `Colors.grey.shade400`, `Colors.red` / `Colors.redAccent`, `Colors.white` in plants widgets (notes, placeholders, manage sheets, etc.). Not an architecture-layer break; violates UI convention.

---

## 4. Contradictions

### 4.1 Rules ↔ rules

| A | B | Conflict |
|---|---|----------|
| `architecture.mdc` forbids feature→feature widgets | `architecture.mdc` accepts hub composition; `architecture-status.mdc` accepts home **and** propagations | Same codebase has no single “forbidden vs allowed” answer without reading three places |
| `project-context.mdc` + `ui-conventions.mdc`: Russian hardcoded UI, `Locale('ru')` | `ADR-003` + generated `lib/l10n` + `AppLocaleController` | Rules instruct outdated product behavior |
| `models.mdc`: show Russian `.label` on enums | Enums have `.code` / storage; labels live in `core/l10n/app_localizations_x.dart` | Models rule conflicts with l10n architecture |
| `architecture.mdc` examples: `PlantModel`, `WateringModel`, `FertilizerService`, `PlantListPage` | Real names: `Plant`, `WateringEntry`, `FertilizeService`; list hub is `HomePage` | Misleading for new contributors |
| `firebase.mdc` user-tree diagram | Real global `plantSpecies` collection + docs/firebase.md | Rule diagram incomplete |
| Global user rule: Clean Architecture + Bloc + GetIt | Project rules: forbid those | External — project wins |

### 4.2 Docs ↔ rules

| Docs say | Rules say | Notes |
|----------|-----------|-------|
| Multi-locale ARB is source of truth | Several rules still say Russian-only | Docs are ahead of rules |
| Potential Improvements include decoupling models from Firestore | `architecture-status` / accepted exceptions: do not auto-propose that refactor | Docs list as optional improvement — OK if gated by approval |
| Hub exception focuses on `HomePage` | Status rule also covers propagations | Docs incomplete |
| Overview lists rule files but **not** `architecture-status.mdc` | Status file is the waiver list | Docs gap |

### 4.3 Docs ↔ code (small accuracy issues)

| Docs claim | Code |
|------------|------|
| Settings “sign-out may live on home” | Sign-out is **only** on `HomePage` (~line 810); settings is locale-only — wording is cautious but vague |
| Plants “public API” includes sheets used by hub/propagations | True in practice, but **not** an intentional module boundary — it’s leakage, waived by status |
| Serialization convention “toMap on models” | Several write paths still inline maps in services (`WateringService`, notes, etc.) — already marked debt |

No evidence of invented Clean Architecture layers in docs; docs correctly refuse to describe repos/Bloc.

---

## 5. Hidden dependencies

### 5.1 Service → service (not forbidden, but under-documented)

```
AuthService → FirestoreService
PlantService → PlantSpeciesService, StorageService
FertilizeService → WateringService   # auto watering before fertilizing
```

Impact: fertilizing writes have a **care-side effect** on watering history/denorm that UI may not expect. Worth documenting in firebase.md / service notes; not present as a formal rule.

### 5.2 UI → plants widgets from other features

```
home → plants (pages, cards, sheets, search)
home → propagations, settings
propagations → plants (propagation_details_sheet)
```

Features are not independently shippable modules.

### 5.3 Models → infrastructure / UI

```
Many models → cloud_firestore (QueryDocumentSnapshot, Timestamp)
Variegation → flutter/material
firestore_helpers → cloud_firestore
```

Domain types cannot be used in a non-Flutter / non-Firebase isolate without dragging those dependencies.

### 5.4 Core → models + l10n

```
core/l10n/app_localizations_x.dart → models (enums, StageInfo) + generated AppLocalizations
```

Acceptable for this architecture; creates a central coupling hub for all enum display strings.

### 5.5 Implicit Auth session

Services assume `FirebaseAuth.instance.currentUser!` is non-null. No session object is passed from `AuthGate` / `AppUser` into services. Hidden dependency on global Auth singleton (**A** per status rule).

### 5.6 Device I/O in presentation

`PlantDetailsPage` uses `ImagePicker` then `StorageService` / `PlantService`. Allowed (not Firebase), but keeps picker+upload orchestration in the page rather than a single service facade.

### 5.7 Nesting of live streams on Home

```
watchUserDocumentExists → getPlants → watchActiveParentPlantIds
```

Multiple service subscriptions and broadcast streams owned by one oversized page. Runtime coupling / rebuild cost not captured by layer diagrams.

---

## 6. Where code has drifted from described architecture

| Area | Described (rules or older mental model) | Actual code |
|------|----------------------------------------|-------------|
| Locale | Fixed Russian | Dynamic locale override + 4 ARBs |
| Enum labels | Model `.label` | `AppLocalizations` extensions |
| Plant list page | `PlantListPage` in plants feature (`architecture.mdc`) | List lives in **`HomePage`**; plants feature has details/genus/stage only |
| Service naming | `FertilizerService` | `FertilizeService` |
| Model naming | `*Model` suffix | Plain domain names (`Plant`, `Note`, …) |
| Plants widget folders | `sections/` in architecture.mdc | `notes/`, `propagations/` (and others) — no `sections/` |
| Firestore boundary “prefer services; except one-off streams” (`firebase.mdc`) | Soft door for UI Firestore | Currently **no** UI Firestore streams found — stricter than the rule’s soft exception |
| Serialization “match neighbors with toMap” | Uniform | Split: some entities `toMap`, many history types write-only via services |
| Privacy / catalog | User-scoped tree in firebase.mdc | Plus **global** `plantSpecies` (code + firestore.rules + docs) |

Docs (2026-08 overview/firebase/data-model) generally track current code better than older Cursor rule snippets.

---

## 7. What is correctly aligned

- Dependency direction `features → core/models/services` (core does not import features; services do not import widgets).
- No `lib/repositories/`, no feature-local model trees.
- No Bloc / Riverpod / Provider / GetIt in `pubspec` or `lib/`.
- Firebase Auth/Firestore/Storage used from services; UI consumes models/streams.
- Navigation via `Navigator` + modal sheets matches `flutter-style.mdc`.
- Shared Theme (`AppTheme.darkTheme`) and brand font pattern matches conventions (aside from local `Colors.*` slips).
- ADR-001 / ADR-002 / ADR-003 match the running system.
- `architecture-status.mdc` intentionally freezes migration debt and cross-feature edges — team process is coherent if agents follow it.

---

## 8. Priority remediation (docs/rules only — no code required)

Ordered for reducing contributor confusion **without** refactors:

1. **Update stale rules** to ARB multi-locale (`project-context.mdc`, `ui-conventions.mdc`, `models.mdc` labels section).
2. **Reconcile cross-feature rule** in `architecture.mdc` with `architecture-status.mdc` (single allowed list: Home hub + Propagations→plants sheets).
3. **Fix naming examples** in `architecture.mdc` to real types/folders.
4. **Add `plantSpecies`** to `firebase.mdc` diagram.
5. **Add `architecture-status.mdc`** to docs overview “source of truth” table; document propagations→plants as accepted.
6. **Document FertilizeService→WateringService** side effect in firebase.md / overview.
7. Leave `Variegation` / model↔Firestore / migrations as debt under status waiver until explicitly approved.

Optional later (needs approval): split oversized UI files; extract Auth error mapping so login drops `firebase_auth` import.

---

## 9. Audit checklist (quick)

| Check | Result |
|-------|--------|
| UI imports `cloud_firestore` / `firebase_storage` | None found under `features/` |
| UI imports `firebase_auth` | `login_page.dart` only |
| `core` → `features` | None |
| `services` → widgets/pages | None |
| `models` → Flutter UI | `variegation.dart` |
| Repositories / Bloc present | No |
| Docs invent Clean Architecture | No |
| Rules fully match code for l10n | **No** |
| Cross-feature imports | Yes (home, propagations) |
| Hidden service orchestration | Yes (esp. fertilize→watering) |

---

## 10. Sources reviewed

**Code:** `lib/main.dart`, `lib/features/**`, `lib/services/**`, `lib/models/**`, `lib/core/**`, `firestore.rules`, `storage.rules`, `pubspec.yaml`, `test/**`.

**Docs:** `docs/architecture/overview.md`, `firebase.md`, `data-model.md`, `localization.md`, `privacy.md`, `docs/decisions/ADR-001..003`, `docs/development/testing.md`.

**Rules:** `architecture.mdc`, `architecture-status.mdc`, `firebase.mdc`, `flutter-style.mdc`, `models.mdc`, `project-context.mdc`, `ui-conventions.mdc`, `ui-quality.mdc`, `testing.mdc`, `workflow.mdc`.

---

*End of audit. Code unchanged.*
