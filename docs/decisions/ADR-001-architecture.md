# ADR-001: Application architecture

Status: Accepted  
Date: 2026-08-03  
Supersedes: —  

## Context

Plöntukrot / SKÖRD is a Flutter plant journal with Firebase Auth, Firestore, and Storage. The codebase grew feature-first with shared services. Team constraints forbid large rewrites and unnecessary abstractions.

## Decision

Adopt and keep:

1. **Feature-first UI** under `lib/features/*` (pages + widgets).
2. **Shared models** in `lib/models/`.
3. **Shared services** in `lib/services/` as the Firebase boundary.
4. **Thin core** for theme, locale, shared dialogs.
5. **No** repositories, use cases, Bloc, Riverpod, or GetIt unless a future ADR approves them for a demonstrated problem.

Dependency direction: `features → core | models | services`.

UI reads data via service streams + `StreamBuilder`; local UI state via `setState`.

## Consequences

Pros:

- Matches implemented code; low ceremony.
- Clear place for Firebase (`services`) and entities (`models`).
- Incremental evolution without migration tax.

Cons:

- No formal domain layer — business rules can leak into UI or services.
- Services are concrete and Firebase-coupled — harder to unit test in isolation.
- Hub pages may grow large and cross feature imports.

## References

- [Architecture overview](../architecture/overview.md)
- `.cursor/rules/architecture.mdc`
- `.cursor/rules/flutter-style.mdc`
