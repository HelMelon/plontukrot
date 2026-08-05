# ADR-007: Centralized AppTheme design tokens

## Status

Accepted

## Context

UI widgets contained widespread inline visual constants (`AppColors` static usage mixed with `Colors.*`, magic paddings/radii/font sizes, ad-hoc `TextStyle`). Theme entry was named `AppTheme.darkTheme` despite there being no light/dark switch. Changing a color or spacing required touching many screens.

A new 16-color semantic palette replaced the previous forest/gold set. Product requirements: no visual constants in UI; one place to change look; single app theme (not light/dark).

## Decision

Introduce a layered token system under `lib/core/theme/`:

1. **Foundation tokens** — colors, spacing, radii, dimensions, typography, shadows.
2. **Component themes** — buttons, sheets, inputs, cards, chips, dialogs.
3. **Screen themes** — splash, login, home, plant details, propagations, care history, catalog builder, growth, settings.

Register tokens as `ThemeExtension<AppThemeTokens>` on `AppTheme.theme` (renamed from `darkTheme`).

**Access:**
- UI widgets: `context.colors` / `context.spacing` / … via `theme_context.dart`.
- Painters without `BuildContext`: static aliases `AppTheme.colors` etc. (same instances, no duplicated values).

**Palette (semantic):**
screen, modal, card, divider, primary, primaryHover, onPrimary, secondaryButton, outline, textPrimary, textSecondary, heading, icon, success, warning, error.

**Buttons:** primary CTA uses `primary` + `onPrimary`; secondary uses `secondaryButton` + `outline`; destructive uses `error`. Global `OutlinedButton` is no longer styled as a filled primary.

**Sheets:** unified top radius token (`radii.sheet` = 32).

**Exceptions:**
- `Colors.transparent` for scaffolds over tiled `background.png` (Flutter semantic, not a style token).
- `lib/models/variegation.dart` icon colors left in the domain model (explicitly out of scope).

## Implementation

- Layers: `tokens/`, `components/`, `screens/`, `app_theme_tokens.dart`, `app_theme.dart`, `theme_context.dart`.
- Removed legacy `AppColors` class / `darkTheme` name.
- Migrated feature pages, sheets, and plant widgets to context tokens.
- Cursor rules: `theme-tokens.mdc` (alwaysApply) + updated `ui-conventions.mdc`.

## Behavior

- App still has a single dark-looking theme; no runtime light/dark toggle.
- Visual changes (palette, spacing scale, sheet radius, button styles) are controlled from theme files.
- Primary CTAs appear in the new green primary (`#4A6B5D`) with light on-primary text.

## Consequences

- Benefits: single source of truth; safer restyling; clearer conventions for agents/developers.
- Trade-offs: slightly more verbose widget builds (`final colors = context.colors`); some layout breakpoints/aspect ratios remain outside tokens by design.
- Future: light theme can add a second `AppThemeTokens` instance without renaming the API again.

## Verification

- `flutter analyze` — no issues.
- Manual device UI pass not run in this change set; recommend smoke-checking home, plant details, sheets, propagations, login, splash.
