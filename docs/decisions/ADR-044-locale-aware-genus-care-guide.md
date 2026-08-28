# ADR-044: Locale-aware genus care guide generation

## Status

Accepted

## Context

The genus AI care guide feature (ADR-043) generated and cached botanical text only in Russian. UI labels were localized via ARB files, but the guide body (`origin`, `light`, `watering`, etc.) stayed Russian when the app language was switched to English, German, or French.

Users expect system-generated reference content to follow the active app locale, similar to other localized UI copy.

## Decision

1. **Client passes locale** — `GenusCareService.getCareGuide` sends the active BCP-47 language code (`en`, `ru`, `de`, `fr`) as the `locale` query parameter.
2. **Backend generates in requested language** — LLM system/user prompts include the target language derived from `locale`.
3. **Cache is per genus + locale** — PostgreSQL primary key becomes `(genus, locale)`; existing rows are migrated with `locale = 'ru'`.
4. **Card reloads on locale change** — `GenusCareGuideCard` reloads in `didChangeDependencies` when the widget locale changes.

Supported locales match the app: `en`, `ru`, `de`, `fr`. Unknown codes fall back to `en`.

## Implementation

- **Backend**
  - `backend/app/ai_care.py` — `normalize_locale`, `system_prompt(locale)`, locale-aware generation and mock fallbacks.
  - `backend/app/routers/genera.py` — `locale` query param on GET/POST care-guide endpoints; cache lookup/insert by `(genus, locale)`.
  - `backend/schema.sql`, `backend/app/db.py` — composite primary key and migration for existing tables.
- **Flutter**
  - `lib/services/genus_care_service.dart` — locale in API query and in-memory cache key.
  - `lib/features/plants/widgets/cards/genus_care_guide_card.dart` — pass locale, reload when language changes.

## Behavior

- Opening a genus page in English requests `/genera/{genus}/care-guide?locale=en`.
- If no English cache exists, the backend generates English text via the configured LLM and stores it separately from the Russian version.
- Switching app language on the genus page triggers a new fetch for the new locale.
- Retry/refresh regenerates content for the current locale only.

## Consequences

- Each genus may have up to four cached variants (one per supported locale).
- First request per locale incurs one LLM call; subsequent requests are served from DB cache.
- Existing Russian caches remain valid after migration (`locale = 'ru'`).
- User-generated plant notes and nicknames are unchanged (ADR-003 UGC rule still applies).

## Verification

- Inspected backend prompt, router, schema migration, and Flutter service/card changes.
- Confirmed cache keys and API query wiring include locale.
- `flutter analyze` on touched Dart files (when available in environment).
