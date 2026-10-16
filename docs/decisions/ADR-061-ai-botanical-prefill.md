# ADR-061: AI-powered botanical field prefill

## Status

Accepted

## Context

When users add or edit a plant, they currently type every botanical field by hand: genus, species, cultivar, family, trading name, variegation, and hybrid parent species. For popular plants the same phrases (e.g. "Philodendron Pink Princess", "Hoya carnosa 'Krimson Queen'") are entered repeatedly, which is slow and error-prone.

The backend already generates AI care guides for genera and families (ADR-043, ADR-056) using configured LLM providers. We want to reuse the same provider chain to extract structured botanical data from a free-text phrase and prefill the add/edit plant form.

Because the feature relies on paid/third-party AI providers and may need to be rolled out gradually, it must be gated by a server-driven feature flag.

## Decision

1. **Backend contract**
   - `POST /botanical/prefill` accepts a JSON body `{phrase, locale}` and returns structured botanical fields: `genus`, `species`, `cultivar`, `plantFamily`, `tradingName`, `isHybrid`, `variegation`.
   - The endpoint is gated by the server-driven feature flag `ai_botanical_prefill` (default `false`). When the flag is off, the endpoint returns 403.
   - AI generation reuses the existing provider chain in `ai_care.py` (`generate_botanical_prefill`) with a dedicated prompt that asks the model to return strict JSON.
   - The prompt instructs the model to return genus/species as standard Latin names regardless of input language, localize `plant_family` to the user's locale, and use English enum values for `variegation`.
   - Results are cached in PostgreSQL table `botanical_prefill_cache` keyed by `(phrase, locale)` to reduce redundant AI calls.

2. **Server-driven feature flag**
   - New flag `ai_botanical_prefill` added to `feature_flags.py`, `FeatureFlag` enum on the client, and ADR-055 flag list.
   - Resolution follows the same priority stack as other flags (defaults → env → DB overrides).

3. **Flutter client**
   - Model `BotanicalPrefillResult` (`lib/models/botanical_prefill_result.dart`) maps the API response to typed fields, including `Variegation`.
   - Service `BotanicalPrefillService` (`lib/services/botanical_prefill_service.dart`) calls the new endpoint.
   - Dialog `showBotanicalPrefillDialog` asks the user for a plant phrase and calls the service.
   - `AddPlantSheet` and `UpdatePlantSheet` show a "Заполнить ИИ" text button near the botanical fields when the flag is enabled. On success the form fields are filled and a SnackBar confirms the result.

4. **Localization**
   - New strings added to all four ARB files (RU, EN, DE, FR) and the generated `AppLocalizations` classes.

5. **Prompt boundaries**
   - The AI is asked to return only allowed `variegation` values and to set `is_hybrid` only when the phrase explicitly describes a hybrid.
   - No care-guide content is returned; only the botanical fields needed by the plant form.

## Implementation

- Backend:
  - `backend/app/feature_flags.py`: added `FLAG_AI_BOTANICAL_PREFILL`, default `False`, re-exported in `__all__`.
  - `backend/app/schemas.py`: added `BotanicalPrefillIn` and `BotanicalPrefillOut`.
  - `backend/app/ai_care.py`: added `_botanical_prefill_prompt`, provider-specific callers, and `generate_botanical_prefill` with normalization.
  - `backend/app/routers/botanical.py`: new router with `POST /botanical/prefill`, DB cache read/write, feature-flag dependency, and request/result logging.
  - `backend/app/main.py`: registered `botanical.router`.
  - `backend/app/db.py`: added `botanical_prefill_cache` table to `auto_migrate`.

- Flutter:
  - `lib/core/features/feature_flags.dart`: added `aiBotanicalPrefill` enum value.
  - `lib/models/botanical_prefill_result.dart`: new model.
  - `lib/services/botanical_prefill_service.dart`: new service.
  - `lib/features/plants/widgets/dialogs/botanical_prefill_dialog.dart`: phrase input dialog.
  - `lib/features/plants/widgets/sheets/add_plant_sheet.dart`: prefill helper and button.
  - `lib/features/plants/widgets/sheets/update_plant_sheet.dart`: prefill helper and button (single plants only, not groups).
  - `lib/l10n/app_*.arb` and generated Dart files: new UI strings.

## Behavior

- Opening add/edit plant shows a "Заполнить ИИ" button only when the backend returns `ai_botanical_prefill: true` for the signed-in user.
- Tapping the button opens a dialog where the user enters a plant phrase (species, cultivar, or trading name).
- The app sends the phrase to the backend, which either returns a cached result or asks the configured LLM to extract botanical fields.
- On success, the form fields are pre-filled: genus, species (or hybrid parents), cultivar, family, trading name, variegation. The user can edit the result before saving.
- If the AI returns no identifiable botanical data (genus, species, cultivar, and family are all empty), a dedicated SnackBar tells the user the plant was not recognized and suggests trying a fuller name.
- On error (network, AI provider unavailable, feature flag off), a SnackBar shows the error.

## Consequences

- Reduces manual typing for common plant names by reusing the existing AI provider infrastructure.
- Cached results lower AI token costs for repeated phrases.
- The feature is disabled by default and can be enabled per-user from the admin panel or env, matching the existing feature-flag rollout pattern.
- Future changes must keep the `BotanicalPrefillOut` schema in sync with the plant form fields.

## Verification

- `flutter analyze` on touched Dart files — no issues.
- Python AST parse of touched backend modules — no syntax errors.
- New UI strings added to all four supported locales and generated localization classes.
- Note: full end-to-end API test could not be run in this session because the local shell sandbox is unavailable.
