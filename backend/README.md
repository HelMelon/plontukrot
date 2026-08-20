# Plöntukrot Backend — self-hosted FastAPI + PostgreSQL

The self-hosted backend that replaced **Firebase** (Auth, Firestore, Storage,
Crashlytics, Hosting) in 2026-08. See
[ADR-033](../docs/decisions/ADR-033-firebase-to-fastapi-migration.md) for the
migration decision and `backend/MIGRATION.md` for the one-shot data migrator.

The Flutter app talks to this server over plain **HTTP/REST** through
`ApiClient` (`lib/services/api_client.dart`). No Firebase SDKs are used.

---

## Stack

| Concern | Technology |
|---------|-----------|
| Framework | Python **FastAPI** |
| Web server | `uvicorn` |
| Database | **PostgreSQL** (via `psycopg`) |
| Auth | email/password, **bcrypt** hashes + **JWT** (HS256) |
| Photos | stored on server disk, served via static files |
| Process manager | **systemd** service (`plontukrot`) |

One language for the whole stack would have been Dart, but the owner knows
Python well and FastAPI is purpose-built for backends, so **Python + FastAPI**
was chosen (faster to build, no syntax/mental switch).

---

## Repository layout

```
backend/
├── app/
│   ├── main.py               # FastAPI app, static /photos mount, /health
│   ├── config.py             # Settings from env vars
│   ├── db.py                 # psycopg connection pool (+ jsonb helper)
│   ├── security.py           # bcrypt hashing + JWT create/decode
│   ├── schemas.py            # Pydantic request/response models
│   └── routers/
│       ├── auth.py           # register / login / me
│       ├── plants.py         # plant CRUD
│       ├── plant_care.py     # photos / notes / growth / care / manipulations
│       ├── propagations.py   # propagation CRUD + notes + stage-history
│       ├── catalogs.py       # fertilizers / soils / components / stimulators / wish-list / finance
│       ├── social.py         # friends / friend-requests / gifts
│       └── species.py        # global plant-species catalog
├── schema.sql                # 24-table Postgres schema
├── requirements.txt
├── MIGRATION.md              # the one-shot Firebase → Postgres migrator
└── migrator.py               # migrator itself
```

---

## Deploy (current)

- **Server IP:** `91.149.167.7`
- **Base URL:** `http://91.149.167.7:8000`
- **Code:** `/opt/plontukrot/backend/`
- **Photos:** `/opt/plontukrot/photos/<plant_id>/<photo_id>.jpg`
- **Service:** `plontukrot` (systemd) — `uvicorn app.main:app --host 0.0.0.0 --port 8000`

```bash
systemctl status plontukrot     # active (running)
systemctl restart plontukrot    # after deploying new code
journalctl -u plontukrot -f     # live logs
```

## Environment variables

Set in `/etc/systemd/system/plontukrot.service` (never in code/commit):

| Var | Purpose |
|-----|---------|
| `DATABASE_URL` | `postgresql://user:pass@127.0.0.1:5432/plontukrot` |
| `SECRET_KEY` | JWT signing secret — **change from the provisional value** |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | token lifetime (default 60) |
| `PUBLIC_BASE_URL` | base used to build absolute photo URLs (e.g. `http://91.149.167.7:8000`) |
| `PHOTOS_DIR` | disk dir for uploaded photos (default `/opt/plontukrot/photos`) |

---

## Auth

- `POST /auth/register` `{email, password, name?}` → creates user (bcrypt hash) + JWT
- `POST /auth/login` `{email, password}` → JWT
- `GET /auth/me` (Bearer) → profile

Most routes require `Authorization: Bearer <token>`. Passwords are stored only
as bcrypt hashes. **Google sign-in was removed** — only email/password remains.
`users.firebase_uid` column keeps the old Firebase id for migration mapping only.

---

## Database (24 tables)

`users`, `plants`, `plant_photos`, `plant_notes`, `plant_growth_events`,
`plant_waterings`, `plant_fertilizings`, `plant_repottings`,
`plant_manipulations`, `propagations`, `propagation_notes`,
`propagation_stage_history`, `fertilizers`, `fertilizer_components`,
`stimulators`, `soils`, `components`, `wish_list_items`, `finance_entries`,
`friends`, `friend_requests`, `incoming_gifts`, `outgoing_gifts`,
`plant_species`.

JSON list/dict fields (e.g. soil `components`) are stored as **JSONB** — the
backend serializes them explicitly via `db.jsonb()`.

## API surface

FastAPI auto-generates OpenAPI docs at `/docs` (Swagger) and `/redoc`.

| Area | Base | Endpoints |
|------|------|-----------|
| Auth | `/auth` | `register`, `login`, `me` |
| Plants | `/plants` | CRUD + `/plants/{id}/photos` (list/create/delete/`upload`) |
| Plant care | `/plants/{id}/…` | `waterings`, `fertilizings`, `repottings`, `growth-events`, `manipulations`, `notes` |
| Propagations | `/propagations` | CRUD + `/{id}/notes`, `/{id}/stage-history` |
| Catalogs | `/` | `fertilizers`, `soils`, `components`, `stimulators`, `wish-list`, `finance-entries` |
| Social | `/` | `friends`, `friend-requests`, `gifts/incoming`, `gifts/outgoing` |
| Species | `/plant-species` | global catalog |

### Photo upload flow (important — one photo = one gallery entry)

1. `POST /plants/{id}/photos/upload` (multipart `file`) — **only stores the file**
   on disk and returns a URL. Does **not** insert into `plant_photos`.
2. `POST /plants/{id}/photos` `{image_url, ...}` — inserts the gallery row.

This split means one upload maps to exactly one gallery entry, and the gallery
cap (`plants.maxGalleryPhotos`, 5) is respected. When a real photo is added,
legacy `is_legacy` placeholder rows (dead Firebase URLs) are deleted so they do
not show up as a second "photo".

---

## Realtime

Firestore realtime streams are replaced by **polling** (ADR-033 v1): the Flutter
client polls every 8s via `restPollStream` (`lib/services/rest_stream.dart`),
a **broadcast** stream with a replay cache so multiple `StreamBuilder`s can
subscribe safely without "already been listened to" errors.

---

## Deployment / update loop

```bash
# from a machine with the code
scp backend/app/** root@91.149.167.7:/opt/plontukrot/backend/app/
ssh root@91.149.167.7 "systemctl restart plontukrot"
```

Verify: `curl http://127.0.0.1:8000/health` → `{"status":"ok"}`.

---

## Security notes

- Currently served over **plain HTTP** (no domain/HTTPS) — intentionally left
  off for now (owner declined domain/external access this cycle). Before
  exposing to real users over untrusted networks, add HTTPS (needs a domain for
  a Let's Encrypt cert) and rotate `SECRET_KEY`.
- Never commit credentials: secrets come from the environment/systemd unit only.
