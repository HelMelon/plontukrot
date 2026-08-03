# Localization

Living document. Decision: [ADR-003](../decisions/ADR-003-localization.md).

---

## Stack

- `flutter_localizations`
- `intl`
- `generate: true` + ARB (`lib/l10n/app_*.arb`)
- Generated: `lib/l10n/app_localizations*.dart`
- Helpers: `lib/core/l10n/app_localizations_x.dart`
- Preference: `AppLocaleController` (`shared_preferences`)

## Supported locales

`en`, `ru`, `de`, `fr` (+ system / device resolution via `AppLocaleController.resolveLocale`).

## Rules

- UI strings → ARB / `AppLocalizations`.
- User-generated content (nicknames, notes, fertilizer names, etc.) is **never** localized.
- Dates: `intl` + initialized date symbols for the resolved language.

## Stale guidance

`.cursor/rules/ui-conventions.mdc` and parts of `project-context.mdc` may still say “hardcoded Russian / Locale('ru')”. **Code and ADR-003 supersede that** — update rules when touching them; do not reintroduce hardcoded-only Russian UI.
