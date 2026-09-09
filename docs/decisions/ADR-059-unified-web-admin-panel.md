# ADR-059: Unified web admin panel for plontukrot + lesesucht (plan)

## Status

Proposed

## Context

plontukrot and lesesucht are two FastAPI backends on the same server
(`91.149.167.7`, ports 8000 / 8001) sharing one PostgreSQL database
(`plontukrot`) but using **separate user tables and id schemes**:

| | plontukrot | lesesucht |
|---|---|---|
| Schema | `public` | `lesesucht` |
| Users table | `public.users` | `lesesucht.users` |
| User id | uuid | bigint |
| Owner/admin | `OWNER_IOT_USER_ID` (uuid) | `admin_emails` = `helga@lesesucht.by` |
| Ban/archive tables | `user_bans`, `user_deletions` (exist) | none |

The owner wants **one admin panel covering both apps**: user statuses
(moderator / admin), ban and archive-delete with a required reason, a user
list with copyable ids, and full JSON export of a user's data. Admin access
is restricted to the owner's account plus anyone the owner promotes to admin;
moderators get a read-only view for now.

## Decision

Build a **third, separate FastAPI web app** (`admin.service`, port 8002) that
reads/writes both DB schemas directly. It does not modify the existing
backends' code paths (except one small lesesucht ban check).

### Architecture

```
91.149.167.7
├── plontukrot.service   :8000  (schema public)
├── lesesucht.service    :8001  (schema lesesucht)
└── admin.service        :8002  (NEW — reads both schemas)
```

Direct DB access (not via the two APIs) because the apps have different user
tables and ids; a unified view is simpler and more reliable from SQL.

### Identity bridge (the core problem)

A person may exist in both apps under different ids. New `admin` schema:

```sql
admin.identities (
  id             uuid PRIMARY KEY,
  plontukrot_uid uuid,          -- -> public.users.id
  lesesucht_uid  bigint,        -- -> lesesucht.users.id
  email          text UNIQUE,   -- shared login email
  role           text NOT NULL DEFAULT 'user',  -- user | moderator | admin
  created_at     timestamptz NOT NULL DEFAULT now()
)
```

The owner is one identity row with both uids and `role = 'admin'`. Promoting
a moderator/admin = editing `role`.

### Roles

- **admin** (owner + promoted): everything — statuses, ban, archive, export, list.
- **moderator**: read-only user list for now (feature-gated; to be expanded later).
- **user**: no admin access.

Enforced by `Depends(require_role("admin"))` / `require_role("moderator")`.

### User statuses

```sql
admin.user_statuses (
  identity_id uuid REFERENCES admin.identities(id),
  status      text NOT NULL DEFAULT 'active',  -- active | moderator | admin | banned | archived
  reason      text,                            -- required for ban/archive
  changed_by  uuid,
  changed_at  timestamptz NOT NULL DEFAULT now()
)
```

### Ban (with required reason)

- `POST /admin/identities/{id}/ban` body `{ "reason": "..." }` — reason required (422 if empty).
- Writes `admin.user_statuses` (banned) **and** existing `public.user_bans` so the plontukrot backend actually blocks login.
- lesesucht has no ban table yet — add a check in its `get_current_user_id` (small, separate change).
- Cannot ban an admin or self (same guards as `user_bans.ban_user`).

### Archive-delete (90-day retention)

- `POST /admin/identities/{id}/archive` body `{ "reason": "..." }` — soft-delete, not physical.
- Writes `admin.user_statuses` (archived) + existing `public.user_deletions`.
- **Auto-purge after 3 months**: cron/systemd-timer daily deletes rows where
  `changed_at < now() - 3 months`; FK `ON DELETE CASCADE` already removes all
  user data in both schemas.
- `POST /admin/identities/{id}/restore` returns the account to `active`.

### User list + copy id

- `GET /admin/identities` — unified list: email, name, role, status, reason,
  `plontukrot_uid`, `lesesucht_uid`, dates.
- Web front: copy-id button per row (`navigator.clipboard`).
- Filters: by app, status, role; search by email/name.

### JSON export

- `GET /admin/identities/{id}/export` — collects all data for the identity
  from both schemas:
  - plontukrot: profile, plants, waterings, fertilizings, repottings,
    manipulations, notes, photo metadata, finances, friends, gifts.
  - lesesucht: profile, books, book notes, characters, relationships.
- One JSON object `{ identity, plontukrot: {...}, lesesucht: {...} }`, served
  as a downloadable file (Content-Disposition attachment). Admin only.

### Web front

Minimal single-page HTML+JS (or Swagger UI). Tabs:
- **Users** — table, copy id, ban/archive/restore/promote (with reason modal).
- **Export** — download JSON per user.
- **Logs** (optional) — who changed what.

### Domain & HTTPS

- New `admin.iam.by` (or `/admin` path on the existing `plontukrot.iam.by`),
  nginx proxy `admin.iam.by -> 127.0.0.1:8002`, TLS via certbot (LE).
- Without a domain the panel is only reachable at `http://91.149.167.7:8002` —
  inconvenient from a phone and no HTTPS (password in clear). Domain recommended.

### Security

- Login by email+password (bcrypt, as in both backends), JWT.
- All admin endpoints require role admin/moderator.
- Self-ban / self-archive rejected.
- Reason required for ban/archive.
- Panel not exposed without HTTPS.

## Implementation

- New `admin` schema + tables (`identities`, `user_statuses`) + migration.
- FastAPI backend: auth, roles, ban/archive/restore, list, export.
- Web front: table, copy-id, modals, export.
- lesesucht: add ban check in `get_current_user_id`.
- systemd `admin.service` + nginx + domain + HTTPS.
- Tests + deploy.

## Behavior

- Owner logs into the panel, sees users from both apps in one list.
- Ban/archive require a reason; archived users are purged after 3 months.
- Copy-id button copies the relevant uid.
- Export downloads a full JSON of a user's data across both apps.

## Consequences

- **Benefits:** one panel, unified roles/statuses/export across both apps.
- **Trade-offs:** admin panel reads DB directly (bypasses app business logic);
  a person's two app accounts must be linked manually in `identities`.
- **Limitations:** moderator functionality deferred; lesesucht ban check is a
  small change to that backend; photos on disk are not cleaned on purge.

## Verification

- Not yet implemented — this is a plan. Effort estimate ~11-14 h.
- Open questions: domain confirmation, owner identity linkage, admin login
  credentials.

## Open questions (owner to confirm)

1. Domain: `admin.iam.by` ok? DNS already points to the server?
2. Confirm `OWNER_IOT_USER_ID` (plontukrot) and `helga@lesesucht.by` (lesesucht)
   are the same person, to seed the admin identity.
3. Admin login: separate password, or reuse the plontukrot email+password?
