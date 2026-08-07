# Firebase Boundary Rules

Living document. Source of truth for paths also: `.cursor/rules/firebase.mdc`, `firestore.rules`, `storage.rules`.

See also: [Architecture overview](overview.md), [Data model](data-model.md), [ADR-002](../decisions/ADR-002-firebase.md).

---

## Layer boundaries

| Layer | Allowed | Forbidden |
|-------|---------|-----------|
| **UI (`features/*`)** | Call services; consume models / streams | `cloud_firestore`, `firebase_storage`, Firebase `User`, `DocumentSnapshot`, raw maps as domain |
| **Models** | `fromMap` / `fromFirestore` / `toMap`; `Timestamp` via `readTimestamp` | UI widgets; service orchestration |
| **Services** | Auth, Firestore, Storage SDKs; compose other services | Widgets / pages; SnackBars |
| **Entry (`main.dart`)** | `firebase_core` init | Business queries |

### Quick matrix

```
UI:
  ❌ cloud_firestore (queries)
  ❌ Firebase User in widget state
  ❌ DocumentSnapshot

Models:
  ✅ Firestore mapping (current accepted exception)
  ❌ Widget imports (target; see debt: Variegation)

Services / AuthService:
  ✅ FirebaseAuth, Firestore, Storage
  ✅ Map Auth User → AppUser before UI
```

**Accepted exceptions**

- `main.dart` initializes Firebase.
- `AuthService` uses `FirebaseAuth` / `GoogleSignIn` internally.
- Models contain Firestore mapping factories.
- `LoginPage` imports `firebase_auth` for `FirebaseAuthException` typing only.
- Prefer service methods over raw Firestore in UI; do not scatter new one-off Firestore calls in widgets.

---

## Auth boundary

| Concern | Owner |
|---------|--------|
| Sign-in / sign-out | `AuthService` |
| Session stream | `AuthService.watchAuthState()` → `Stream<AppUser?>` |
| Create `users/{uid}` on first login | `FirestoreService.createUserDocument()` (called from AuthService) |
| UI session switch | `AuthGate` in `main.dart` |

**Rules**

- UI receives `AppUser` (`uid`, `photoUrl`), not Firebase `User`.
- Services read `FirebaseAuth.instance.currentUser!.uid` for scoping (assume signed-in inside authenticated screens).
- Web uses `signInWithPopup`; mobile uses `GoogleSignIn` + credential.

---

## Firestore boundary

### Access pattern

```dart
class PlantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Stream<List<Plant>> getPlants() {
    return _plantsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Plant.fromFirestore).toList());
  }
}
```

- Extend existing services; do not add parallel Firebase wrapper layers.
- Return models from streams/futures when a model exists.
- Keep path strings inside services.

### User-scoped tree

```
users/{uid}
  plants/{plantId}
    watering/{id}
    fertilizing/{id}
    repotting/{id}
    notes/{id}
    growthEvents/{id}
  fertilizers/{id}
  fertilizerComponents/{id}
  soils/{id}
  components/{id}
  propagations/{id}
    stageHistory/{id}
```

### Global catalog (not under user)

```
plantSpecies/{docId}   # PlantSpeciesService — shared botanical catalog
```

Security: authenticated read; client create-only; no client update/delete (`firestore.rules`).

### Denormalized plant fields

When writing care history, services must keep plant doc in sync:

- `lastWateredAt`
- `lastFertilizedAt` / `lastFertilizerName`
- `lastRepottedAt`

Leaf growth baseline (not care denorm): `initialLeafCount` — edited via `PlantService.updatePlant`, not derived from `growthEvents`.

`growthEvents` documents: `type`, `createdAt`, `expiresAt`; for `leafRemoved` also optional `reason` (`cutForRooting` | `eaten` | `dried`). Monthly stats count `newLeaf` as gained and all `leafRemoved` as lost.

### Timestamps

Use `readTimestamp` from `lib/models/firestore_helpers.dart` — handles `Timestamp`, `DateTime`, null.

Writes typically use `FieldValue.serverTimestamp()` or stored `Timestamp` values from services.

### Safety

- Never rename collections, fields, or paths without documenting migration impact and getting approval.
- Prefer additive schema changes with backward-compatible reads (see [data-model.md](data-model.md)).

---

## Storage boundary

| Concern | Owner |
|---------|--------|
| Upload / delete plant images | `StorageService` |
| Persist gallery + cover URLs | `PlantService.addPlantPhoto` / `removePlantPhoto` / delete hooks |

**Paths**

```
plants/{uid}/{plantId}.jpg                 # legacy single cover
plants/{uid}/{plantId}_thumb.jpg           # legacy thumb
plants/{uid}/{plantId}/{photoId}.jpg       # gallery full
plants/{uid}/{plantId}/{photoId}_thumb.jpg # gallery thumb
```

Compression via `flutter_image_compress` inside `StorageService`. UI uses `image_picker`, then calls the service — UI must not talk to Storage SDK directly.

---

## Mapping responsibility

| Step | Layer |
|------|-------|
| Query / write documents | Service |
| `doc.id` + `doc.data()` → model | Model factory (`fromFirestore` / `fromDocument` / `fromMap`) |
| Model → map for write | Model `toMap` **or** inline map in service (inconsistent today) |
| Auth User → AppUser | `AuthService._mapUser` |

Details: [data-model.md](data-model.md).

---

## Service inventory

| Service | Firebase surface |
|---------|------------------|
| `AuthService` | Auth + Google Sign-In |
| `FirestoreService` | `users/{uid}` document |
| `PlantService` | `users/{uid}/plants` |
| `StartupWarmupService` | Auth session + plant list thumbs precache (startup only) |
| `PlantSpeciesService` | `plantSpecies` |
| `StorageService` | Storage plant images |
| `WateringService` | watering subcollection + denorm |
| `FertilizeService` | fertilizers, fertilizerComponents, fertilizing |
| `RepottingService` | repotting + denorm |
| `NoteService` | notes |
| `GrowthEventService` | growthEvents (+ client purge by `expiresAt`) |
| `ComponentService` | components |
| `SoilService` | soils |
| `PropagationService` | propagations + stageHistory |

Instantiation: `ServiceName()` at call site — **no DI container**.

---

## Crashlytics

Mobile (Android/iOS) crash and non-fatal reporting via `firebase_crashlytics`, wrapped by `AppCrashReporting` (`lib/services/app_crash_reporting.dart`).

| Concern | Behavior |
|---------|----------|
| Platform | Android / iOS only; web is a no-op |
| Collection | Enabled when `!kDebugMode` |
| Init | After `Firebase.initializeApp` in bootstrap (`main.dart`) |
| Fatals | `FlutterError.onError`, `PlatformDispatcher.onError` |
| Non-fatals | Bootstrap failure, splash ready timeout, auth sign-in/delete (not user cancel), photo upload failures |
| User id | Set from Auth session; cleared on sign-out / account delete |

Enable Crashlytics in Firebase Console → Crashlytics if not already. Verify with a release/profile build on a device (debug collection is off).

See [ADR-016](../decisions/ADR-016-firebase-crashlytics.md).

---

## Web hosting

Flutter web is served via Firebase Hosting (`firebase.json` → `public: build/web`).

```bash
flutter build web --release
firebase deploy --only hosting
```

Live URL (default site): https://plant-logger-e0677.web.app  

Also: https://plant-logger-e0677.firebaseapp.com  

After first deploy, add both hostnames under Firebase Console → Authentication → Settings → Authorized domains (if not already present) so Google sign-in works on web.

---

## One-shot ops scripts (`tools/`)

CLI scripts talk to Firestore REST with Application Default Credentials (`gcloud auth application-default login`) or `FIREBASE_ACCESS_TOKEN`. Project default: `plant-logger-e0677`.

| Script | Purpose |
|--------|---------|
| `tools/export_plants.dart` | Backup `users/{uid}/plants` (+ subcollections) to JSON |
| `tools/cleanup_migration_flags.dart` | Delete obsolete `careHistoryMigrated` / `botanicalFieldsMigrated` on plant docs |

Cleanup (preview, then apply):

```bash
dart run tools/cleanup_migration_flags.dart --dry-run
dart run tools/cleanup_migration_flags.dart
dart run tools/cleanup_migration_flags.dart --uid=<uid>
```

Does not remove legacy plant keys `name` / `family` (readers still accept them).
