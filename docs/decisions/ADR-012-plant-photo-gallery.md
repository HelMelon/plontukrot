# ADR-012: Plant photo gallery (up to 5)

## Status

Accepted

## Context

Plants previously supported a single photo (`imageUrl` / `imageThumbUrl`). Users need a short visual history on the plant details page without a full media library.

## Decision

Store up to **5** photos per plant in an `images` array on the plant document. Each entry has `id`, `imageUrl`, `imageThumbUrl`, and `addedAt` (upload time, not user-editable).

Gallery order is **newest first** (by `addedAt`). The details PageView opens on index 0 (latest photo). When a 6th photo is uploaded, the **oldest** photo is removed from Firestore and Storage, then the new one is prepended.

`imageUrl` / `imageThumbUrl` remain as **cover** fields synced to the newest gallery photo so plant lists keep using `listImageUrl` unchanged.

Legacy plants with only cover URLs are read through `Plant.galleryPhotos` as a single synthetic photo (`id: legacy`) until the next gallery write canonicalizes `images`. The date chip is **hidden** for legacy photos because `addedAt` was previously derived from plant `createdAt` and often did not match when the cover was actually set.

Storage paths for new photos: `plants/{uid}/{plantId}/{photoId}.jpg` (+ `_thumb`). Legacy single-file paths are still deleted when needed.

## Implementation

- Model: `PlantPhoto`, `Plant.images`, `Plant.galleryPhotos`, `Plant.maxGalleryPhotos = 5`
- Services: `StorageService.uploadPlantPhoto` / `deletePlantPhoto` / `deleteAllPlantImages`; `PlantService.addPlantPhoto` / `removePlantPhoto`
- UI: `PlantImageCard` PageView slider with date label, add/delete actions on plant details
- Theme: gallery overlay tokens on `PlantDetailsScreenTheme`
- Storage rules: `storage.rules` allows both legacy flat files and nested gallery paths under `plants/{uid}/…`

## Behavior

- Details page: swipe between photos (newest first); date of the current photo is shown (hidden for legacy covers); `+` adds (always); trash deletes current after confirm.
- At 5 photos, adding another silently drops the oldest.
- Lists/search/archive continue to show the newest photo via cover fields.
- Empty gallery shows the existing placeholder; tap adds the first photo.

## Consequences

- Small additive Firestore schema; no subcollection.
- Temporary orphan Storage objects are possible if upload succeeds and Firestore write fails (same class of risk as before).
- No manual cover selection or photo date editing.
- Gallery uploads require deployed Storage rules that match nested paths; legacy-only rules return `storage/unauthorized`.

## Verification

- `flutter gen-l10n`
- `flutter analyze` on changed model/service/UI/theme files — no issues
- Device UI not run in this session
- Follow-up: nested Storage rules added and must be deployed with `firebase deploy --only storage`
