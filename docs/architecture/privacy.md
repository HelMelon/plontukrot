# Privacy and access control

Living document. Enforced by Firebase rules in repo root.

---

## Firestore (`firestore.rules`)

| Path | Access |
|------|--------|
| `users/{userId}` and all nested docs | read/write if `request.auth.uid == userId` |
| `plantSpecies/{id}` | authenticated read; authenticated create with field validation; **no** client update/delete |

Unauthenticated access denied.

## Storage (`storage.rules`)

Path: `plants/{userId}/{fileName}` (e.g. `{plantId}.jpg`, `{plantId}_thumb.jpg`).

| Action | Rule |
|--------|------|
| read / delete | signed in and `auth.uid == userId` |
| write | owner; filename ends with `.jpg`; size &lt; 5 MB; `contentType` `image/jpeg` |

## Client expectations

- All user plant/care/catalog data is per-uid under `users/{uid}`.
- Shared botanical catalog (`plantSpecies`) is readable by any signed-in user; writes are create-only from clients via `PlantSpeciesService.ensureSpecies`.
- Do not store secrets in Firestore documents.
- PII currently on user doc: `name`, `email` (from Google profile at create time).

Formal privacy policy / GDPR runbook: **Not defined yet** in this repo docs set (see product docs if added later).
