# Firebase → Postgres migration

One-shot migrator that loads the Firebase export
`exports/all_users_backup/users.json` into the Postgres schema defined in
`schema.sql`. It does **not** contact Firebase.

## Prerequisites

- Python 3.12+
- Packages from `backend/requirements.txt` (`psycopg[binary]`, `bcrypt`)
- Schema already applied (`psql $DATABASE_URL -f backend/schema.sql`)
- `DATABASE_URL` set in the environment (never commit credentials)

## Dry-run (safe default)

Runs the full migration inside a transaction and **rolls back**. Nothing is
persisted; temporary passwords are **not** written.

```bash
cd /path/to/plontukrot
set DATABASE_URL=postgresql://USER:PASS@HOST:5432/plontukrot   # Windows cmd
# export DATABASE_URL=postgresql://USER:PASS@HOST:5432/plontukrot  # bash

python backend/migrator.py
# same as:
python backend/migrator.py --dry-run
```

Optional export path:

```bash
python backend/migrator.py --export exports/all_users_backup/users.json
```

### What the log shows

1. **INVENTORY** — counts read from `users.json` per target table.
2. **RESULT COUNTERS** — `inserted` / `skipped_existing` / `inventory` per table.
3. **UID MAP** — `firebase_uid → new UUID`.
4. **WARNINGS** — skipped/broken rows (missing email, bad dates, etc.).
5. Final line: `ROLLED BACK (dry-run)` or `COMMITTED.`

## Commit (persist)

```bash
python backend/migrator.py --commit
```

Side effects on commit:

| File | Contents |
|------|----------|
| `backend/migrated_users.txt` | `email:temporaryPassword` lines (append). Users must change password after first login. |
| `backend/migrated_unmapped.json` | Plant/social fields that exist in the export but have no column in `schema.sql` (archive*, members, giftedToUid, growth `reason`, outgoing `archivedAt`, …). |

Password hashing matches `app.security.hash_password` (bcrypt).

## Idempotency

Safe to re-run. Behaviour:

- `users`: matched by `firebase_uid` or `email` → reuse UUID, skip insert.
- All other tables: `INSERT … ON CONFLICT (id) DO NOTHING`.
- Photo ids are scoped as `{plantId}__{imageId}` because bare `legacy` repeats across plants.

## What is migrated

| Export key | Postgres table |
|------------|----------------|
| `profile` | `users` (+ `firebase_uid`) |
| `plants` | `plants` + `plant_photos` |
| `plants_<id>.notes` | `plant_notes` |
| `plants_<id>.growthEvents` | `plant_growth_events` |
| `plants_<id>.watering` | `plant_waterings` |
| `plants_<id>.fertilizing` | `plant_fertilizings` |
| `plants_<id>.repotting` | `plant_repottings` |
| `plants_<id>.manipulations` | `plant_manipulations` (empty in current export) |
| `propagations` | `propagations` |
| `propagations_<id>.notes` | `propagation_notes` |
| `propagations_<id>.stageHistory` | `propagation_stage_history` |
| `fertilizerComponents` | `fertilizer_components` |
| `soils` | `soils` (`components` → JSONB) |
| `components` | `components` |
| `wishList` | `wish_list_items` |
| `financeEntries` | `finance_entries` |
| `friendRequests` | `friend_requests` |
| `incomingGifts` | `incoming_gifts` |
| `outgoingGifts` | `outgoing_gifts` |

### Not in this export (skipped / reserved)

- `plant_species` (global Firestore collection) — needs a separate dump.
- `fertilizers`, `stimulators`, `friends` — tables exist in schema; absent from `users.json`.

### Enum mapping

Firestore enums from Firestore (`variegation`, growth `type`, propagation `method`/`status`, friend/gift `status`, finance `type`) are stored as **INT** using Dart enum declaration order in `lib/models/`.

### Social UIDs

`fromUid` / `toUid` / `recipientUid` are remapped through `firebase_uid → UUID`. If a UID is not in the export, a placeholder `users` row is created (`placeholder+…@migrated.invalid`) so FK constraints succeed.

### Photos

Only URLs are stored (files are not downloaded — Firebase billing is closed). Gallery (`fields.images[]`) and legacy cover (`fields.imageUrl`) are both written to `plant_photos` with `is_legacy` when id/`legacy` applies.

## Syntax check

```bash
python -m py_compile backend/migrator.py
```
