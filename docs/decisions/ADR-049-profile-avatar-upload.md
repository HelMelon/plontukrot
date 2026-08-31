# ADR-049: Profile avatar upload with plant photo crop flow

## Status

Accepted

## Context

User profiles exposed `AppUser.photoUrl` from `/auth/me`, but the backend had no
`photo_url` column and no upload endpoint. Plant photos already use a proven flow:
gallery/camera picker → 1:1 `PlantImageCropPage` → multipart upload to disk.

## Decision

1. Add `users.photo_url` (nullable text) and return it from `GET/PATCH /auth/me`.
2. Add `POST /auth/me/avatar/upload` (multipart `file`) that stores a square JPEG
   under `photos/avatars/{user_id}/` and updates `photo_url` with a cache-busting
   `?v=` query param.
3. Reuse the existing plant picker + crop UI (`pickAndCropPlantPhoto` /
   `PlantImageCropPage`) for profile avatars — same 1:1 framing as list cards.
4. Profile page: tap avatar → pick → crop → upload → `AuthService.reloadCurrentUser()`
   so home chrome and profile reflect the new URL immediately.

## Implementation

- Backend: `auth.py` upload handler; `db.py` auto-migrate; `schema.sql` column.
- Frontend: `StorageService.uploadAvatar`, profile avatar tap target with loading
  overlay, `AuthService._loadMe` reads `photo_url` snake_case fallback.
- L10n: `profileChangePhoto`, `a11yChangeProfilePhoto` (ru/en/de/fr).

## Behavior

- User opens Profile → taps avatar → chooses gallery/camera → crops square →
  confirms → avatar updates across app after upload completes.
- Unsupported file types return HTTP 400; network errors show snackbar.

## Consequences

- Pros: no new crop dependency; consistent UX with plant photos; avatars served
  from the same `/photos` static mount as plant images.
- Cons: friends' cached `from_photo_url` on pending requests is not backfilled
  when avatar changes (existing limitation).

## Verification

- `python -m py_compile backend/app/routers/auth.py`
- `flutter analyze` on touched profile/storage/auth files
