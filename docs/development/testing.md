# Testing Strategy

Living document. Checklist also in `.cursor/rules/testing.mdc` and `ui-quality.mdc`.

---

## Current coverage

| Kind | Status | Location |
|------|--------|----------|
| Unit tests (services / models) | **Mostly absent** | — |
| Widget tests | Placeholder only | `test/widget_test.dart` (`expect(true, isTrue)`) |
| Localization tests | Present | `test/l10n_test.dart` |
| Integration / Firebase | **Absent** | — |

### `test/l10n_test.dart`

Covers:

- Supported locales `en` / `ru` / `de` / `fr`
- Sample keys and pluralization (`daysCount`)
- Interpolation behavior
- Unsupported locale lookup behavior

### `test/widget_test.dart`

Does **not** pump `MyApp` or exercise Firebase. Treat as stub.

---

## Recommended manual checks (before merge)

Per project rules:

- App starts without errors
- Modified screen opens; navigation / back works
- Loading, empty, and long-content cases where applicable
- Forms usable with keyboard; no obvious RenderFlex overflow
- Run `flutter analyze`

Device UI verification: preferred; if unavailable, document risk (do not claim full UI verification).

---

## Future (not implemented)

**Not defined yet** as mandatory CI gates beyond what the repo currently runs.

Candidates when approved:

- Pure unit tests for `readTimestamp`, enum `fromCode`, model `fromMap` legacy keys.
- Widget tests for pure presentation widgets with fake data (no Firebase).
- Fake/mock service interfaces — requires DI or constructor injection (architecture change).

Do not block small fixes solely for missing automated coverage until a testing ADR expands requirements.
