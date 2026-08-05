# Models and Data Mapping

Living document. Rules also in `.cursor/rules/models.mdc`.

All domain entities live in **`lib/models/`** only. Never create `features/*/models/`.

---

## Location and ownership

| Kind | Location |
|------|----------|
| Domain entities / value objects | `lib/models/*.dart` |
| Timestamp helper | `lib/models/firestore_helpers.dart` |
| Temporary UI-only state | private fields / private enums next to the widget (e.g. home sort enums) |
| Image upload DTO | `PlantImageUploadResult` in `storage_service.dart` (not under models) |

Temporary UI state must **not** be promoted to `lib/models/` unless it becomes shared domain data.

---

## Serialization conventions

Match neighboring models. Typical shape:

```dart
factory X.fromMap(String id, Map<String, dynamic> data) { ... }

factory X.fromFirestore(QueryDocumentSnapshot doc) =>
    X.fromMap(doc.id, doc.data() as Map<String, dynamic>);

// Optional:
factory X.fromDocument(DocumentSnapshot doc) => ...

Map<String, dynamic> toMap() { ... }  // some files use toFirestore naming — match the file
```

### Timestamps

```dart
createdAt: readTimestamp(data['createdAt']),
```

`readTimestamp` accepts `null`, `Timestamp`, or `DateTime`.

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
| `Plant` | `fromMap` / `fromFirestore` / `fromDocument` / `toMap`; legacy keys `name`, `family`; `initialLeafCount` defaults to `0` |
| `PlantSpecies` | Global catalog mapping |
| `Note` | `fromMap` / `fromFirestore`; **no** `toMap` (write maps in service) |
| `GrowthEvent` | `fromMap` / `fromFirestore`; helpers `displayLeafCount`, `leafStatsByMonth`; types include leaf + care events; `leafRemoved` may include `reason` (`LeafRemovalReason`); **no** `toMap` |
| `WateringEntry` | `fromMap` / `fromFirestore`; **no** `toMap` |
| `FertilizingEntry` | `fromMap` / `fromFirestoreData`; nested dose maps |
| `RepottingEntry` | `fromMap` / `fromFirestore` / `toMap` |
| `Propagation` | `fromMap` / `fromFirestore` / `toMap` |
| `PropagationStageEntry` | `fromMap` / `fromFirestore` / `toMap` |
| `Soil` | `fromMap` / `fromFirestore` / `toMap` |
| `SoilComponent` | Embedded in soil; map helpers without snapshot type |
| `CatalogComponent` | `fromMap` / `fromFirestore` |
| `Fertilizer` | `fromMap` / `fromFirestore` / `toMap` |
| `FertilizerIngredient` | `fromMap` / `fromFirestore` |
| `FertilizerDose` | `fromMap` / `toMap` (embedded) |
| `AppUser` | Constructed in AuthService — no Firestore factories |
| `StageInfo` | Const catalog — not Firestore |
| `PropagationYearStats` | Aggregated via `fromList` |

Many models import `cloud_firestore` for snapshot types — **accepted today**; target long-term: map in services only.

---

## Nullable fields and defaults

Observed patterns (follow the specific model):

- Missing strings → `''` or `null` after trim (`Plant._nullableTrimmed`).
- Missing ints → `0` or `null` depending on field (`stage` defaults to `0`).
- Missing bools → `false` for migration flags.
- Missing timestamps → `null` (watering required `wateredAt` falls back to `DateTime.now()` on parse — be careful).

Always trim user strings in **services** before write when the neighbor methods do.

---

## Firebase document mapping

1. Service owns collection reference and query.
2. Snapshot map → model via `fromFirestore` / `fromDocument`.
3. Writes: either `model.toMap()` or hand-built `Map` in the service method.
4. IDs: document id is model `id`; not stored as a field inside the map unless needed.

Images: plant gallery is `images: [{ id, imageUrl, imageThumbUrl, addedAt }]` (max 5). Cover fields `imageUrl` / `imageThumbUrl` stay in sync with the newest photo for lists (`Plant.listImageUrl`). Legacy plants with only cover fields are exposed via `Plant.galleryPhotos` without a batch migration.

---

## Backward compatibility

Readers tolerate legacy schema:

| Current | Legacy / alternate |
|---------|-------------------|
| `species` | older `name` on plant |
| `plantFamily` | older `family` |
| Botanical / care migration flags | backfill denorm fields and botanical naming |

Writers may `FieldValue.delete()` obsolete keys when updating. Do not remove read fallbacks until data is confirmed migrated for all users.

**Not defined yet:** formal schema version field or migration runbook beyond in-app `migrate*` methods.

---

## Rules

**DO**

- Search existing models before adding a new class.
- Use `readTimestamp` for Firestore times.
- Keep enums' storage values stable.

**DON'T**

- Duplicate models under features.
- Put Flutter widgets in new models (existing `Variegation` icon/color is debt — do not spread the pattern).
- Change field names without migration plan.
