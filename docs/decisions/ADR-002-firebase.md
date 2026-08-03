# ADR-002: Firebase as backend

Status: Accepted  
Date: 2026-08-03  

## Context

The app needs auth, syncing plant/care data across devices, and image storage. Existing integration uses Firebase Auth (Google), Cloud Firestore, and Firebase Storage.

## Decision

- Keep **Firebase** as the only cloud backend.
- Access Firebase **only through `lib/services/`** (plus model mapping and `main` init).
- Scope personal data under `users/{uid}/...`.
- Use a separate read-mostly global collection `plantSpecies` for shared botanical catalog entries.
- Enforce access with repo `firestore.rules` / `storage.rules`.
- Do not rename collections/fields without an explicit migration plan.

## Consequences

Pros:

- Aligns with shipped client and security rules.
- Services encapsulate paths and denormalized updates.

Cons:

- Models currently depend on Firestore types.
- Offline / multi-backend support not designed.
- Schema evolution requires careful backward-compatible readers.

## References

- [Firebase boundary](../architecture/firebase.md)
- [Data model](../architecture/data-model.md)
- `.cursor/rules/firebase.mdc`
