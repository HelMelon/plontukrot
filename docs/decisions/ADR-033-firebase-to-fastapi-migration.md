# ADR-033: Migration from Firebase to self-hosted FastAPI + Postgres on Yandex Cloud

## Status

Accepted — Flutter service layer talks to FastAPI over REST + JWT.
Backend (`backend/`) was already in place; this records the client rewrite.

## Flutter implementation (Phase 5)

- HTTP client: `lib/services/api_client.dart` (`http` package, Bearer JWT).
- Base URL: `lib/config/api_config.dart` via `--dart-define=API_BASE_URL=…`.
- Auth: email/password only; Google sign-in and email-verification gate removed.
- Firestore/Storage services rewritten onto REST; `Stream` APIs kept via 8s polling + refresh-after-write (`ApiRefresh`).
- Models parse camelCase and snake_case; dates are ISO-8601 (no `Timestamp`).
- Crashlytics replaced with local debug logging.
- Photo **display** uses stored URLs; binary upload waits on Object Storage.

See `lib/FRONTEND_MIGRATION.md` for endpoint coverage and backend gaps.

---

## Context

The Firebase project `plant-logger-e0677` is broken: the GCP billing account is
closed, so Firebase Storage refuses to serve the app's photos (HTTP 402/400)
and new uploads fail. Google payments cannot be used from Belarus, and the US
provider may be cut off at any time. The user wants to become independent of
foreign clouds.

The app's data is already fully exported to
`exports/all_users_backup/users.json` (5 users, 49 plants, 12 propagations,
all subcollections, all photo URL references). Photo *files* are still in
Firebase Storage but not downloadable until billing is restored; their URLs
(with download tokens) are preserved in the export.

Decision drivers:

- Self-hosting on **Yandex Cloud** (Belarusian-card friendly, far lower
  sanction risk than US clouds).
- Backend in **Python + FastAPI** — the user has prior Python experience
  (Telegram bots) and backend work is language-agnostic.
- **No Docker** — it does not work on the user's machine, so the whole stack
  must run without containers (direct process / venv on a Yandex VM).
- Minimize foreign-vendor lock-in: plain Postgres + S3-compatible Object
  Storage + our own REST API + our own email/password auth (drop Google
  sign-in entirely).
- Keep the app's `lib/services/` layer as the single seam between Flutter
  and the backend (mirrors ADR-002, which we supersede).

## Scope boundary

- **IN:** Auth (email/password only), Firestore data, photo storage, REST API,
  Postgres schema, Flutter service layer rewrite.
- **OUT (removed):** Google sign-in, Firebase Auth, Firebase Storage,
  Crashlytics (replaced by server-side error logging), realtime Firestore
  streams (replaced by polling or WebSocket; polling chosen for v1).
- **Not decided here:** domain/hosting provider beyond Yandex, exact VM size
  (see Constraints), payment plan details.

## Constraints (fixed)

1. **Yandex Cloud** is the hosting target.
2. **No Docker** anywhere.
3. **Google auth is removed.** Registration + login with email/password only.
4. The user's Raspberry Pi has only **1 GB RAM** and no current local hosting
   path — this plan must keep the Yandex VM the single backend; the Pi is not
   in scope now.
5. Existing exported data (`exports/all_users_backup/users.json`) is the
   source of truth for migration; nothing may be hand-retapped from Firebase.

## Architecture (target)

```
[Flutter app (Android)]
        │  HTTPS + JSON (REST)        │  JWT Bearer token
        ▼                             ▼
[Yandex Cloud VM  ──  FastAPI (uvicorn)]
        │  ── psycopg ──►  [Yandex Managed PostgreSQL]
        │  ── S3 SDK ──►  [Yandex Object Storage (photos)]
```

- Single VM runs the FastAPI app. Postgres and Object Storage are separate
  managed Yandex services the app connects to over the network.
- Auth: email/password registered in our `users` table; password hashed with
  a standard KDF (e.g. `pbkdf2`/`argon2` from the Python stdlib or a small
  lib); a signed JWT issued on login; protected routes require the JWT.
- Photo URLs stored in Postgres as public or signed S3 URLs so the app can
  load them over plain HTTPS (drop the Firebase token query-string model).

## Postgres schema (normalized)

All tables keyed by `user_id` (UUID) except the global `plant_species`.

### Global

- **plant_species** — replaces Firestore `plantSpecies` (44 rows).
  Columns: `id` (text = species lowercased/id), `species`, `genus`,
  `plant_family nullable`, `created_at`.

### Auth / profile

- **users** — replaces `users/{uid}` profile.
  Columns: `id` (UUID pk), `email unique`, `password_hash`, `name`,
  `locale_code`, `currency_code`, `collection_visibility`,
  `personal_data_consent_at nullable`, `created_at`.

### Plants

- **plants** — replaces `users/{uid}/plants`.
  Columns: `id` (text, keep Firestore doc id), `user_id fk`, `genus`,
  `species`, `cultivar nullable`, `trading_name nullable`, `plant_family
  nullable`, `nickname`, `stage int`, `variegation int/enum`,
  `watering_frequency nullable`, `fertilizing_frequency_days nullable`,
  `initial_leaf_count`, `last_watered_at nullable`, `last_fertilized_at
  nullable`, `last_repotted_at nullable`, `created_at`.
  Photos: keep the Firestore shape — either one `image_url`/
  `image_thumb_url` pair (legacy) **or** a `plant_photos` child table
  (gallery). Prefer a child table for both to normalize:
  - **plant_photos**: `id` (text), `plant_id fk`, `image_url`,
    `image_thumb_url`, `added_at`, `is_legacy bool`.

- **plant_notes** — replaces `plants/{id}/notes`.
  Columns: `id`, `plant_id fk`, `text`, `created_at`, `updated_at`,
  `expires_at nullable`.

- **plant_growth_events** — replaces `plants/{id}/growthEvents`.
  Columns: `id`, `plant_id fk`, `type int/enum`, `created_at`,
  `expires_at nullable`.

- **plant_waterings** — replaces `plants/{id}/watering`.
  Columns: `id`, `plant_id fk`, `watered_at`, `next_watering nullable`,
  `created_at`.

- **plant_fertilizings** — replaces `plants/{id}/fertilizing`.
  Columns: `id`, `plant_id fk`, `fertilizer_id nullable`,
  `fertilizer_name nullable`, `application_method`,
  `components jsonb`, `water_ml int`, `applied_at`, `next_fertilizing
  nullable`, `created_at`.

- **plant_repottings** — replaces `plants/{id}/repotting`.
  Columns: `id`, `plant_id fk`, `soil_id nullable`, `soil_name nullable`,
  `components jsonb`, `slow_release_fertilizer bool`, `repotted_at`,
  `created_at`.

- **plant_manipulations** — replaces `plants/{id}/manipulations`.
  Columns: `id`, `plant_id fk`, `type int/enum`, `applied_at`,
  `note nullable`, `stage_before nullable`, `stage_after nullable`,
  `stimulator_id nullable`, `stimulator_name nullable`, `dosage nullable`.

### Propagations

- **propagations** — replaces `users/{uid}/propagations`.
  Columns: `id`, `user_id fk`, `parent_plant_id nullable`,
  `parent_plant_name`, `parent_plant_family nullable`, `method int/enum`,
  `stage int/enum`, `status int/enum`, `quantity`, `quantity_alive`,
  `gifted_quantity`, `sold_quantity`, `traded_quantity`, `lost_quantity`,
  `started_at`, `sold_at nullable`, `created_at`.

- **propagation_notes** — same shape as `plant_notes`, but fk to
  `propagations`.

- **propagation_stage_history** — replaces `propagations/{id}/stageHistory`.
  Columns: `id`, `propagation_id fk`, `stage int/enum`, `quantity_alive`,
  `outcome nullable`, `note nullable`, `changed_at`.

### Reference / per-user catalogs

- **fertilizers** — `id`, `user_id fk`, `name`, `kind int/enum`, `water_ml`,
  `components jsonb`, `created_at`.
- **fertilizer_components** — `id`, `user_id fk`, `name`, `created_at`.
- **stimulators** — `id`, `user_id fk`, `name`, `default_dosage nullable`,
  `created_at`.
- **soils** — `id`, `user_id fk`, `name`, `components jsonb`, `created_at`.
- **soil_components** — shared with `fertilizer_components`? Both use a
  `components` list; decide at migration whether one table or separate.
  Prefer one shared `components` table for v1 simplicity.
- **wish_list_items** — `id`, `user_id fk`, `name_en`, `name_alt nullable`,
  `created_at`, `updated_at`.
- **finance_entries** — `id`, `user_id fk`, `title`, `amount numeric`,
  `type int/enum`, `source`, `date`, `wish_list_item_id nullable`,
  `created_at`, `updated_at`.

### Social / gifts

- **friend_requests** — `id`, `from_uid fk`, `to_uid fk`,
  `from_display_name`, `from_photo_url nullable`, `status int/enum`,
  `created_at`.
- **friends** — `id`, `user_a fk`, `user_b fk` (ordered pair, unique),
  `created_at`.
- **incoming_gifts** — `id`, `to_uid fk`, `from_uid fk`,
  `from_display_name`, `from_plant_id nullable`, `plant_snapshot jsonb`,
  `status int/enum`, `created_at`.
- **outgoing_gifts** — mirror of incoming_gifts from the sender's side.

> Note: `friends`, `fertilizers`, `stimulators` were present as empty or tiny
> collections in the export; include the tables so the app's delete-account
> and service methods keep working unchanged.

## REST API surface (FastAPI)

Auth:
- `POST /auth/register` {email, password, name} → creates user, returns JWT.
- `POST /auth/login` {email, password} → JWT.
- `POST /auth/resend-verification` (optional; email verification deferred —
  see Risks).
- `GET /auth/me` → profile (JWT).
- `DELETE /auth/me` → delete account + all data (JWT).

Plants & care (all JWT-protected, scoped to the caller's `user_id`):
- `GET /plants` · `POST /plants` · `GET /plants/{id}` · `PATCH /plants/{id}`
  · `DELETE /plants/{id}`.
- `GET /plants/{id}/photos` · `POST /plants/{id}/photos` ·
  `DELETE /plants/{id}/photos/{photoId}`.
- `GET /plants/{id}/notes` · `POST/…` · `DELETE /plants/{id}/notes/{id}`.
- `GET /plants/{id}/growth-events` · `POST …/growth-events`.
- `GET /plants/{id}/waterings` · `POST …/waterings`.
- `GET /plants/{id}/fertilizings` · `POST …/fertilizings`.
- `GET /plants/{id}/repottings` · `POST …/repottings`.
- `GET /plants/{id}/manipulations` · `POST …/manipulations`.

Propagations: mirrored `/propagations`, `/propagations/{id}/notes`,
`/propagations/{id}/stage-history`.

Catalogs: `GET/POST/DELETE` for `fertilizers`, `fertilizer-components`,
`stimulators`, `soils`, `components`, `wish-list`, `finance-entries`.

Social: `GET/POST/DELETE` for `friend-requests`, `friends`, `gifts`.

Global: `GET /species` (public read-mostly).

Storage (photos):
- `POST /photos/plant/{plantId}` (multipart) → uploads original + thumb,
  returns URLs. Backend writes to Object Storage, inserts row.
- `DELETE /photos/plant/{plantId}/{photoId}`.

Realtime: **v1 uses polling** — the Flutter app re-fetches lists on a short
interval and on manual refresh (RefreshIndicator). WebSocket endpoint can be
added later without breaking clients.

## Phased execution plan

### Phase 0 — Prep (done / trivial)
- Data exported to `exports/all_users_backup/users.json`. ✅
- Inventory of all collections and fields completed. ✅
- Verify the backup once more and store a copy off-machine (Risks).

### Phase 1 — Yandex Cloud foundation
- Create Yandex Cloud account / billing profile (Belarusian card).
- Provision **Managed PostgreSQL** (smallest tier).
- Provision **Object Storage** bucket `plontukrot-photos`.
- Provision one **VM** (smallest workable — see Constraints/Resources) with
  Python 3.11+, run `uvicorn` directly (no Docker).
- Create a Yandex service-account + keys so the VM can reach Postgres and
  Object Storage securely.

### Phase 2 — Postgres schema + auth backend
- Write `schema.sql` from the Postgres schema above.
- Apply to the managed DB.
- Implement FastAPI app skeleton: app factory, settings from env, Postgres
  connection pool, error handling, logging to a file (replaces Crashlytics).
- Implement auth: `users` table, password hashing, JWT issue/verify,
  protected-route dependency. Drop Google entirely.

### Phase 3 — Data migration (Firestore → Postgres)
- Write a one-off Python migrator reading `users.json` (not Firebase) and
  inserting all 5 users, plants, propagations, subcollections, catalogs,
  social records.
- Map legacy single `imageUrl` plants to `plant_photos` rows with
  `is_legacy=true`; gallery plants to multiple rows.
- Dry-run against a scratch DB; verify row counts match the export; then run
  against the real DB.

### Phase 4 — Photo storage migration
- Photos are currently *not downloadable* from Firebase (billing closed).
  Options in order:
  1. If the user regains Firebase/Storage access, run a script to download
     all files using the tokens in `users.json` and upload to Object Storage,
     then rewrite `plant_photos.image_url` to the new URLs.
  2. If Storage stays closed, re-upload from the user's local copies if any
     exist; otherwise mark those plants photo-less (data loss limited to
     images, not structure).
- Implement `POST /photos/plant/{plantId}` upload + thumb generation on the
  backend (Pillow), writing to Object Storage and returning URLs.

### Phase 5 — Flutter service-layer rewrite
- Add an HTTP client + JWT store to the Flutter app.
- Rewrite each `lib/services/*.dart` to call the REST API instead of
  Firestore/Auth/Storage. Keep public method signatures identical so the UI
  and view models change as little as possible.
- Replace realtime `.snapshots()` streams with polling (periodic re-fetch)
  and manual refresh.
- Remove Google sign-in from `auth_service.dart` and `login_page.dart`;
  keep only email/password.
- Remove Crashlytics calls (or route to a server `/log` endpoint).
- Update `main.dart` bootstrap: replace `Firebase.initializeApp` with an HTTP
  base-URL + token load.

### Phase 6 — Verification & launch
- `flutter analyze` clean.
- Run unit/widget tests; fix ones that depended on Firebase mocks.
- Deploy FastAPI to the VM, point the app at the VM URL.
- Install APK on the phone (adb), verify: register, login, list plants,
  open details, upload photo, watering/notes/fertilizing/repotting,
  propagation, archive, delete account.
- End-to-end: fresh install on the phone logs in and sees the migrated data.

## Resources / sizing (given 1 GB RAM Pi, VM must carry the load)

- **Managed PostgreSQL:** smallest tier (Yandex `b1`/`b2`). Our data is tiny
  (dozens of rows per user) — even the smallest is far more than enough.
- **VM:** smallest available (e.g. `s2.micro` / 1 vCPU, 2 GB RAM) is
  comfortable; a 1 GB RAM VM is workable but tight under a Postgres pool +
  uvicorn. Recommend ≥2 GB RAM for the VM; Postgres is separate/managed so it
  does not share the VM's RAM.
- **Object Storage:** free/low-cost for < 1 GB of photos (58 files today).
- No Docker on any host; uvicorn runs as a systemd service on the VM.

## Risks & mitigations

- **Realtime lost.** Firestore pushed updates; REST+JWT is pull-based. v1
  polls. Mitigate: keep lists small, poll every 5–10 s, refresh on
  RefreshIndicator. Acceptable for this scale.
- **Email verification.** Firebase sent verification emails; our own backend
  needs an SMTP sender (Yandex Mail / external SMTP). Defer to a later phase
  — v1 can accept any confirmed email and add verification later without
  schema change.
- **Photo re-download blocked.** If Firebase Storage stays closed, images may
  be unrecoverable. Mitigation: try token-download in Phase 4; structure is
  preserved regardless; user is warned explicitly before any destructive step.
- **Foreign-vendor exposure reduced but not zero.** Yandex is still a cloud;
  Postgres/S3/REST are open standards, so migrating away later (e.g. to the
  Pi) only needs a new endpoint URL, not a rewrite. This is the independence
  win over Firebase.
- **Scope creep.** 36 Flutter files touch Firestore. Mitigate: Phase 5 in
  small batches, `flutter analyze` after each service, keep method signatures
  stable.
- **Auth is new code** (password hashing, JWT). Mitigate: use stdlib/well-known
  small libs, no hand-rolled crypto, document the scheme.

## Verification gate for each phase

- P1: VM reachable over SSH; Postgres reachable from VM; bucket lists/creates
  an object.
- P2: `curl` register + login returns a JWT; protected route rejects no-token.
- P3: row counts per table match `users.json`; spot-check Helga's 43 plants /
  10 propagations.
- P4: a test photo uploads to the bucket and the app loads it via URL.
- P5: `flutter analyze` clean; all Firebase imports gone from `lib/`.
- P6: device E2E pass list in Phase 6.

## Consequences

Pros:
- Belarusian-card payment path (Yandex).
- Full control of data, schema, and auth — no foreign-cloud lock-in.
- One language for the app, Python for the backend (user's strength).
- No Docker dependency anywhere.
- Open standards (Postgres, S3, REST, JWT) keep the door open to the Pi later.

Cons:
- Largest rewrite of the three options (new backend + 36 Flutter files).
- Real-time updates replaced by polling.
- We own security (auth, hashing, backups) instead of Firebase managing it.
- Email verification and some niceties deferred.

## References / supersedes

- Supersedes **ADR-002** (Firebase as backend).
- Builds on exported data: `exports/all_users_backup/users.json`.
- Follows ADR-001 architecture boundary (services layer as the seam).
- Reuses ADR-023 (email/password registration) intent — now the only method.
