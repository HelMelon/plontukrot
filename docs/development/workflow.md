# Development workflow

Practical process for changing this repo. Companion: `.cursor/rules/workflow.mdc`.

---

## Before editing

1. Identify the few files that must change.
2. Prefer the smallest patch that solves the request.
3. Do not scan or rewrite unrelated folders.

## Approval required before

- Moving / renaming major structures
- Changing feature boundaries or adding architecture layers (repos, Bloc, DI, …)
- Changing shared models broadly or Firebase schema
- Large-scale refactoring

Local bug fixes and isolated UI fixes that do not change architecture or data contracts can ship without a new ADR.

## After implementation

1. `flutter analyze`
2. Manual checks for affected flows (see [testing.md](testing.md))
3. Note remaining risks if device UI was not verified

Commit format: Conventional Commits (`feat`, `fix`, `refactor`, `chore`, `docs`, `test`).

## Setup / release

- Setup steps: **Not defined yet** in [setup.md](setup.md) (use Flutter + Firebase configs already in repo).
- Release process: **Not defined yet** in [release.md](release.md).
