# Architecture Overview

Living document. Reflects the codebase as of 2026-08. If code and this doc disagree, **fix wins** — update this file.

Related:

- [Architecture audit](ARCHITECTURE_AUDIT.md) (code ↔ docs ↔ rules)
- [Firebase](firebase.md)
- [Data model](data-model.md)
- [Localization](localization.md)
- [Privacy](privacy.md)
- [ADR-001 Architecture](../decisions/ADR-001-architecture.md)
- [ADR-002 Firebase](../decisions/ADR-002-firebase.md)
- Cursor rules: `.cursor/rules/architecture.mdc`, `architecture-status.mdc`, `firebase.mdc`, `flutter-style.mdc`, `models.mdc`

---

## Approach

Pragmatic **feature-first UI** with **shared models** and **shared Firebase services**.

Not Clean Architecture. No `data` / `domain` / `presentation` packages per feature. No repositories, use cases, Bloc, Riverpod, or GetIt.

```
UI (features/*/pages + widgets)
        ↓
Services (lib/services/)  ← Firebase Auth / Firestore / Storage
        ↓
Models (lib/models/)      ← map Firestore docs ↔ Dart objects
```

### Layers (actual)

| Layer | Location | Responsibility |
|-------|----------|----------------|
| Entry / wiring | `lib/main.dart` | Bootstrap, locale, Firebase init, `AuthGate` |
| Features (UI) | `lib/features/*` | Pages, sheets, dialogs, local UI state |
| Core | `lib/core/` | Theme, locale controller, shared dialogs, l10n helpers |
| Models | `lib/models/` | Domain entities + Firestore mapping |
| Services | `lib/services/` | All Firebase I/O and data operations |
| Generated l10n | `lib/l10n/` | ARB-backed `AppLocalizations` |

### Dependency direction

```
features/*
    ↓
core / models / services
```

- Features may depend on `core`, `models`, `services`.
- `core` must not depend on features.
- `models` must not import widgets/pages (exception: see Technical Debt — `Variegation`).
- `services` must not import widgets/pages.
- Feature A widgets should not import Feature B widgets (accepted exception: hub pages compose multiple features).

### Separation of responsibility

| Concern | Owner |
|---------|--------|
| Screens, forms, navigation, SnackBars | Feature UI |
| Firestore paths, queries, writes, denormalized fields | Services |
| Document ↔ object mapping | Models (`fromMap` / `fromFirestore` / `toMap`) |
| Theme / locale preference | Core |
| Auth session → `AppUser` | `AuthService` |

---

## Folder structure (real)

```
lib/
├── main.dart
├── firebase_options.dart
├── core/
│   ├── l10n/app_localizations_x.dart
│   ├── locale/app_locale_controller.dart
│   ├── theme/ (AppTheme, tokens, components, screens)
│   └── widgets/prompt_text_dialog.dart
├── features/
│   ├── auth/pages/
│   ├── home/pages/
│   ├── profile/pages/
│   ├── splash/pages/
│   ├── propagations/pages/
│   ├── wish_list/
│   │   ├── pages/
│   │   └── widgets/sheets/
│   └── plants/
│       ├── pages/
│       └── widgets/
│           ├── cards/
│           ├── dialogs/
│           ├── notes/
│           ├── propagations/
│           ├── search/
│           ├── selectors/
│           ├── sheets/
│           └── tags/
├── l10n/                         # generated + ARB
├── models/
└── services/
```

There is **no** `lib/shared/`, `lib/repositories/`, or `features/*/data|domain|presentation`.

---

## Application Flow

### App start

```
main()
  → AppLocaleController.instance.load()
  → MyApp (MaterialApp + ListenableBuilder for locale)
  → AppStartup
       1. bootstrap: Firebase.initializeApp, date formatting
       2. app: Stack(
            AuthGate → consent → Home/Login  (builds for real under splash),
            SplashCarouselPage overlay until carousel + onContentReady
          )
```

| Step | Class | Layer | Responsibility |
|------|-------|-------|----------------|
| Entry | `main` / `MyApp` | Entry | Theme, l10n delegates, background |
| Boot | `AppStartup` | Entry | Firebase + intl; then overlayed app |
| Splash | `SplashCarouselPage` | Feature splash | Asset carousel over live Auth/Home; holds last frame until ready |
| Warmup | `StartupWarmupService` | Service | Precache Home `listImageUrl` thumbs + avatar before reveal |
| Auth | `AuthGate` | Entry | `StreamBuilder` on `AuthService.watchAuthState()` (+ `initialData`) |
| Signed in | `HomePage` | Feature home | Plant collection hub; `onFirstContentReady` |
| Signed out | `LoginPage` | Feature auth | Google sign-in |

### Auth flow

```
LoginPage
  → AuthService.signInWithGoogle()
  → FirebaseAuth + GoogleSignIn
  → FirestoreService.createUserDocument()
  → authStateChanges → AuthGate → HomePage(AppUser)
```

`AppUser` exposes only `uid` and `photoUrl`. Firebase `User` stays inside `AuthService`.

### Plant care (happy path)

```
HomePage (PlantService.getPlants stream)
  → PlantDetailsPage (PlantService.watchPlant)
  → sheets: watering / fertilizing / repotting / notes / update
  → WateringService | FertilizeService | RepottingService | NoteService | PlantService
  → Firestore (+ StorageService for images)
```

### Propagation flow

```
HomePage / PlantDetailsPage
  → PropagationsPage or AddPropagationSheet / PropagationDetailsSheet
  → PropagationService
  → users/{uid}/propagations (+ stageHistory)
```

### Wish list flow

```
HomePage
  → WishListPage
  → WishListService / AddWishListItemSheet
  → users/{uid}/wishList
  → «Купила» → AddPlantSheet (tradingName ← nameAlt) → delete wish item on success
```

### Locale change

```
ProfilePage
  → AppLocaleController.setPreference
  → SharedPreferences + Firestore users/{uid}.localeCode
  → ListenableBuilder rebuilds MaterialApp.locale
```

---

## Feature Architecture

### auth

**Responsibility:** Google sign-in UI, personal-data consent checkbox, loading/error feedback; consent gate for existing sessions.

**Structure:**

```
features/auth/pages/login_page.dart
features/auth/pages/personal_data_consent_gate_page.dart
```

**Data flow:**

```
LoginPage → AuthService.signInWithGoogle(recordConsent: true) → Firestore personalDataConsentAt
AuthGate → PersonalDataConsentGatePage → HomePage
```

**Public API:** `LoginPage`, `PersonalDataConsentGatePage`.

**Note:** Imports `firebase_auth` only to type `FirebaseAuthException` in catch — accepted leakage.

---

### splash

**Responsibility:** Cold-start progress UI and splash carousel that covers real Auth/Home load and first paint.

**Structure:**

```
features/splash/pages/splash_flow.dart   # AppBootstrapPage, SplashCarouselPage
services/startup_warmup_service.dart     # precache list thumbs before reveal
```

**Data flow:** `AppStartup` shows `AuthGate` under an opaque `SplashCarouselPage`. Home (or Login/consent) signals `onContentReady` after data + image precache + frames. Carousel finishes only when slides are done **and** that signal arrives (or timeout).

**Public API:** `AppBootstrapPage`, `SplashCarouselPage` (`waitFor`).

---

### home

**Responsibility:** Authenticated hub — plant grid/list, filters, sort, multi-select, migrations trigger, navigation to other features.

**Structure:**

```
features/home/pages/home_page.dart
```

**Data flow:**

```
HomePage
  → FirestoreService.watchUserDocumentExists
  → PlantService.getPlants
  → PropagationService.watchActiveParentPlantIds
  → WateringService / PlantService / AuthService (mutations)
  → Navigator → plants pages, PropagationsPage, ProfilePage, sheets
```

**Public API:** `HomePage({required AppUser user})`.

**Accepted exception:** Imports plants widgets/pages and propagations/wish_list/profile pages (hub composition).

---

### plants

**Responsibility:** Plant details, genus/stage filtered views, care history, catalogs (soil/fertilizer components), notes, per-plant propagations UI.

**Structure:**

```
features/plants/
├── pages/
│   ├── plant_details_page.dart
│   ├── plant_genus_details_page.dart
│   └── plant_stage_details_page.dart
└── widgets/
    ├── cards/
    ├── dialogs/
    ├── notes/
    ├── propagations/
    ├── search/
    ├── selectors/
    ├── sheets/
    └── tags/
```

**Data flow:**

```
Page / Sheet / Section
  → PlantService | WateringService | FertilizeService | RepottingService
    | NoteService | SoilService | ComponentService | StorageService
    | PropagationService
  → Firestore / Storage
  → Models
```

**Public API (used outside feature):** pages + selected widgets (`PlantCard`, sheets, `PlantSearchDelegate`) via home hub.

Plant-specific UI stays here — not in `core/widgets`.

---

### propagations

**Responsibility:** Global propagation board (active/archived, year stats).

**Structure:**

```
features/propagations/pages/propagations_page.dart
```

**Data flow:**

```
PropagationsPage → PropagationService streams → Propagation / PropagationYearStats
```

**Public API:** `PropagationsPage`.

---

### wish_list

**Responsibility:** WishLeafs hub — plants the user wants to buy (English + alternative name), export, and handoff into the collection via «Купила».

**Structure:**

```
features/wish_list/pages/wish_list_page.dart
features/wish_list/widgets/sheets/add_wish_list_item_sheet.dart
```

**Data flow:**

```
WishListPage → WishListService → users/{uid}/wishList
WishListPage «Купила» → AddPlantSheet → PlantService + WishListService.delete
```

**Public API:** `WishListPage`.

---

### profile

**Responsibility:** User profile hub — display name/email, plant/propagation stats, language/currency dropdowns, Privacy Policy link, sign-out, full account deletion.

**Structure:**

```
features/profile/pages/profile_page.dart
```

**Data flow:**

```
HomePage avatar → ProfilePage
ProfilePage → AppLocaleController / AppCurrencyController
ProfilePage → PlantService.getPlants + PropagationService.watchActivePropagations
ProfilePage → AuthService.signOut / deleteAccount
```

**Public API:** `ProfilePage`.

---

## State Management

### Approach

| Mechanism | Use |
|-----------|-----|
| `StreamBuilder` + Firestore streams from services | Lists, details, catalogs, auth session |
| `StatefulWidget` + `setState` | Forms, sheets, selection mode, filters |
| `TextEditingController` | Form fields (always dispose) |
| `ChangeNotifier` (`AppLocaleController`) | App-wide locale override only |
| `ListenableBuilder` | Rebuild `MaterialApp` / profile prefs on locale change |

**Not used:** Bloc, Cubit, Riverpod, Provider package, GetIt, Redux.

### Where state lives

- **Remote truth:** Firestore (via service streams).
- **Session:** `AuthService.watchAuthState()` → `AppUser?`.
- **Local UI:** widget fields (`isLoading`, selected IDs, sort/filter).
- **Locale:** `AppLocaleController.instance` + SharedPreferences.

### Rules

**DO**

- Instantiate services inline: `PlantService()`, `WateringService()`.
- Prefer streams from services over caching in UI.
- Keep temporary UI state on the widget — do not invent models for it.

**DON'T**

- Add Bloc / Riverpod / GetIt without an approved ADR.
- Put global mutable app state in statics (except locale controller).
- Store `DocumentSnapshot` / Firebase `User` in widget state.

---

## Repository Pattern

**Status: Not used.**

There are no repository classes. Services (`lib/services/`) are the data access boundary:

- Hide Firestore collection paths and queries.
- Return / accept models (not raw maps when a model exists).
- Own denormalized field updates (`lastWateredAt`, etc.).

Do not introduce repositories unless there is a demonstrated need and an approved architectural change.

---

## Dependency Rules

| Layer | Can depend on | Cannot depend on |
|-------|---------------|------------------|
| `features/*` | `core`, `models`, `services`, Flutter, feature-local widgets | Other feature widgets\* |
| `core` | Flutter, `models` (as needed), packages | `features/*`, Firebase (currently none) |
| `models` | Dart, `cloud_firestore` (mapping), helpers | Widgets / pages / services |
| `services` | Firebase SDKs, `models`, other services | Widgets / pages / `features` |
| `main.dart` | All above, `firebase_core` | — |

\*Exception: hub pages (`HomePage`) may compose pages/widgets from plants, propagations, wish_list, profile.

---

## UI Architecture

### Pages / screens

- Naming: `*_page.dart` → `HomePage`, `PlantDetailsPage`.
- Full pages for major hubs and detail routes only.
- No named routes; use `Navigator.push` + `MaterialPageRoute`.

### Feature widgets

| Kind | Location | Pattern |
|------|----------|---------|
| Cards | `widgets/cards/` | Display |
| Sheets | `widgets/sheets/` | Create / edit / history / manage |
| Dialogs | `widgets/dialogs/` | Composition viewers |
| Sections | `widgets/notes/`, `propagations/` | Embedded on details |
| Selectors / tags / search | matching folders | Reusable within plants |

### Forms & sheets

- Prefer `showModalBottomSheet` for create/edit/history.
- Keyboard: pad with `MediaQuery.viewInsets.bottom`.
- Container style: see `.cursor/rules/ui-conventions.mdc`.

### Shared UI

- `core/widgets/prompt_text_dialog.dart` — generic text prompt only.
- Theme: `AppTheme.theme` + `ThemeExtension` tokens; UI reads `context.colors` / spacing / radii / typography (see ADR-007).
- Brand font: `NordicStyle` (SKÖRD).

### Logic placement

| Logic type | Where |
|------------|--------|
| Validation messages, loading flags, navigation | UI |
| Firestore writes, path rules, denorm sync | Services |
| Parsing timestamps / enums from docs | Models |

Do not put Firestore queries in widgets.

---

## Error Handling

| Pattern | Reality |
|---------|---------|
| Central Failure / Either types | **Not defined yet** |
| Logging service | **Not defined yet** |
| UI feedback | `ScaffoldMessenger` + `SnackBar`, often via `l10n.commonError(...)` |
| Auth errors | `try/catch` on `LoginPage`; `FirebaseAuthException` mapped to message |
| Storage delete | soft-fail `object-not-found` inside `StorageService` |
| Bootstrap failure | `AppStartup` catch still continues to splash |

Services typically propagate exceptions to callers; UI catches and shows SnackBars. No global error boundary.

---

## Development Rules

### DO

- Keep Firebase usage in `lib/services/` (and model mapping).
- Reuse `lib/models/` — never duplicate under features.
- Prefer bottom sheets for create/edit/history.
- Match neighbor file style (imports, naming, sheet verbs: `add_`, `update_`, `manage_`, `*_history_`).
- Extend existing services instead of parallel Firebase wrappers.
- Use `readTimestamp` for Firestore timestamps.
- Keep denormalized plant care fields in sync when writing history.
- Ask before renames, moves, Firebase schema changes, or new architecture layers.

### DON'T

- Import `cloud_firestore` / `firebase_storage` in feature widgets.
- Pass `DocumentSnapshot` / Firebase `User` through UI layers.
- Add Bloc / Riverpod / GetIt / repositories without approval.
- Put plant-specific widgets in `core/`.
- Rename Firestore collections/fields casually (migration impact).
- Expand scope with unrelated refactors during bug fixes.

### Cursor rules source of truth

| Topic | Rule file |
|-------|-----------|
| Layers / boundaries | `architecture.mdc` |
| Firebase paths | `firebase.mdc` |
| Style / state / nav | `flutter-style.mdc` |
| Models | `models.mdc` |
| Product constraints | `project-context.mdc` |
| UI theme / sheets | `ui-conventions.mdc` |

Note: `ui-conventions.mdc` still mentions hardcoded Russian / no ARB — **stale**; app uses ARB + multi-locale (see [localization.md](localization.md)).

---

## Current Technical Debt

1. **Models couple to Firestore** — many models import `cloud_firestore` for `QueryDocumentSnapshot` / `Timestamp` (accepted exception).
2. **Inconsistent serialization** — some models lack `toMap`; writes built inline in services (`WateringEntry`, `Note`, etc.).
3. **`Variegation` imports Flutter** — icons/colors on a model (`models` should not import UI).
4. **Oversized hub** — `home_page.dart` is very large (filters, selection, layout).
5. **Services constructed everywhere** — no shared instance lifecycle; many concurrent stream subscriptions via nested `StreamBuilder`s.
6. **Legacy fields** — readers still accept old keys (`name`, `family`); updates may delete legacy fields.
7. **Login UI types Firebase exception** — only feature-level Firebase package import.
8. **Stale Cursor rules** — Russian-only / no-ARB conventions vs current l10n.
9. **Thin test suite** — see [Testing](../development/testing.md).
10. **Architecture.mdc examples** — names like `PlantModel` / `FertilizerService` do not match code (`Plant` / `FertilizeService`).

---

## Potential Improvements

Not scheduled. Require explicit approval before implementation.

- Split `HomePage` into smaller widgets/controllers without changing data flow.
- Decouple models from `cloud_firestore` types (map in services only).
- Move icon/color out of `Variegation` into UI helpers.
- Centralize user-facing error mapping (still SnackBar-based).
- Add unit tests for mapping helpers and critical service write shapes.
- Align Cursor rules with multi-locale ARB reality.
- Consider DI only if service wiring / testing pain is demonstrated.

Do **not** migrate to Clean Architecture / Bloc solely for pattern purity.
