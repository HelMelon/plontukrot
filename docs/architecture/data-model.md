# Models and Data Mapping

> ## ⚠️ Firebase removed — see `backend/README.md`
>
> Models map **REST JSON** (snake_case from FastAPI) ↔ Dart objects. Firebase
> snapshot types (`QueryDocumentSnapshot`, `Timestamp`) are gone; the helper is
> now `lib/models/model_helpers.dart` (`readString`, `readInt`, `readDate`,
> `readTimestamp`, `jsonMap`). Data source: the self-hosted backend
> (**backend/README.md**, ADR-033).

Living document. Rules also in `.cursor/rules/models.mdc`.

All domain entities live in **`lib/models/`** only. Never create `features/*/models/`.

---

## Location and ownership

| Kind | Location |
|------|----------|
| Domain entities / value objects | `lib/models/*.dart` |
| JSON/field helper | `lib/models/model_helpers.dart` |
| Temporary UI-only state | private fields / private enums next to the widget (e.g. home sort enums) |
| Image upload DTO | `PlantImageUploadResult` in `storage_service.dart` (not under models) |

Temporary UI state must **not** be promoted to `lib/models/` unless it becomes shared domain data.

---

## Serialization conventions

Match neighboring models. Typical shape:

```dart
factory X.fromMap(Map<String, dynamic> data) { ... }

Map<String, dynamic> toMap() { ... }  // some files use toJson naming — match the file
```

`fromMap` accepts either **camelCase** or **snake_case** keys via helpers
(`readString`, `readInt`, `readDate` in `model_helpers.dart`) — so the same
parser works for legacy camelCase maps and FastAPI snake_case JSON. There is no
`fromFirestore`/`QueryDocumentSnapshot` anymore.

### Timestamps

```dart
createdAt: readDate(data, 'createdAt'),
```

`readDate` / `readTimestamp` accept `null`, ISO-8601 string, or `DateTime`.

### Enums

| Concern | Pattern |
|---------|---------|
| Persist | `.code`, `.storageValue`, or `.name` (file-specific) |
| Read | `fromCode` / `fromStorage` with fallback |
| UI labels | Prefer `AppLocalizations` / `app_localizations_x.dart` helpers; some enums still carry display helpers |

Examples: `Variegation`, `PropagationMethod`, `PropagationStatus`, `FertilizerApplicationMethod`, `FertilizerKind`, `FertilizerDoseUnit`.

Stages: `stage_info.dart` (`stageInfos`, stages 0–4).

---

## Model catalog

| Model | Mapping notes |
|-------|----------------|
| `Plant` | `fromMap` / `toMap`; legacy keys `name`, `family`; `initialLeafCount` defaults to `0` |
| `PlantSpecies` | Global catalog mapping |
| `Note` | `fromMap`; **no** `toMap` (write maps in service) |
| `GrowthEvent` | `fromMap`; helpers `displayLeafCount`, `leafStatsByMonth`; types include leaf + care events; `leafRemoved` may include `reason` (`LeafRemovalReason`); **no** `toMap` |
| `WateringEntry` | `fromMap`; **no** `toMap` |
| `FertilizingEntry` | `fromMap`; nested dose maps |
| `RepottingEntry` | `fromMap` / `toMap` |
| `ManipulationEntry` | `fromMap` / `toMap`; types `pinching`, `rerooting`, `stimulator`; rerooting may include `stageBefore` / `stageAfter` |
| `ManipulationType` | Enum; persist `.code`; UI via l10n |
| `Stimulator` | User catalog; `fromMap` / `toMap` |
| `Propagation` | `fromMap` / `toMap` |
| `PropagationStageEntry` | `fromMap` / `toMap` |
| `Soil` | `fromMap` / `toMap` |
| `SoilComponent` | Embedded in soil; map helpers without snapshot type |
| `CatalogComponent` | `fromMap` |
| `Fertilizer` | `fromMap` / `toMap` |
| `FertilizerIngredient` | `fromMap` |
| `FertilizerDose` | `fromMap` / `toMap` (embedded) |
| `AppUser` | Constructed in AuthService — no map factories |
| `StageInfo` | Const catalog — not REST |
| `PropagationYearStats` | Aggregated via `fromList` |

Models no longer import `cloud_firestore` — they parse plain `Map<String, dynamic>` (REST JSON).

---

## Nullable fields and defaults

Observed patterns (follow the specific model):

- Missing strings → `''` or `null` after trim (`Plant._nullableTrimmed`).
- Missing ints → `0` or `null` depending on field (`stage` defaults to `0`).
- Missing timestamps → `null` (watering required `wateredAt` falls back to `DateTime.now()` on parse — be careful).

Always trim user strings in **services** before write when the neighbor methods do.

---

## REST JSON mapping

1. Service owns the REST resource path and query (via `ApiClient`).
2. JSON map → model via `fromMap`.
3. Writes: either `model.toMap()` or hand-built `Map` in the service method.
4. IDs: resource `id` becomes the model `id`.

Images: plant gallery is `images: [{ id, imageUrl, imageThumbUrl, addedAt }]` (max 5, **newest first** by `addedAt`). Cover fields `imageUrl` / `imageThumbUrl` stay in sync with the newest photo for lists (`Plant.listImageUrl`). Legacy plants with only cover fields are exposed via `Plant.galleryPhotos` without a batch migration; the date chip is hidden for synthetic `legacy` photos.

User resource `users` fields include `name`, `email`, `createdAt`, `localeCode`, `currencyCode`, `personalDataConsentAt` (Privacy Policy acceptance timestamp; see ADR-014), and `collectionVisibility` (`friends` | `private`, default `friends`; see ADR-017).

Plant archive reasons: `merged` | `died` | `sold` | `gifted` (optional `giftedToUid` when gifted).

Social models: `Friendship`, `FriendRequest`, `IncomingGift` / `OutgoingGift`, `CollectionVisibility`.

---

## Backward compatibility

Readers tolerate legacy schema:

| Current | Legacy / alternate |
|---------|-------------------|
| `species` | older `name` on plant |
| `plantFamily` | older `family` |

The one-shot `backend/migrator.py` copied data from the Firebase export to
Postgres. Old Firebase cover/gallery URLs remain in `plant_photos` (dead while
Firebase billing is closed); uploading a new real photo supersedes the legacy
placeholder row.

**Not defined yet:** formal schema version field.

---

## Rules

**DO**

- Search existing models before adding a new class.
- Use `readDate` / `readTimestamp` for time fields.
- Keep enums' storage values stable.

**DON'T**

- Duplicate models under features.
- Put Flutter widgets in new models (existing `Variegation` icon/color is debt — do not spread the pattern).
- Change field names without a migration plan.
