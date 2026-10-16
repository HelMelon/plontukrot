# ADR-063: Genus localized to the app language (Russian)

## Status

Accepted

## Context

ADR-061/062 shipped AI botanical prefill with the prompt instructing the model to
return **genus and species as standard Latin names**. In practice the plant card and
the genus page display `plant.genus` directly, so a Russian user saw «Monstera»,
«Ficus», «Philodendron» — Latin — even though the rest of the care guide is Russian.

Her own data already showed the split: `plants.genus` holds both forms —
«Алоказия» (15) alongside `Alocasia` (6), `Monstera` (6) alongside «Монстеры» (2),
`Ficus` (5) alongside «Фикус» (1). She asked for the genus to be filled in the app
language.

Russian gardeners do use Russian genus names (Монстера, Фикус, Филодендрон). English
gardeners do NOT localize — they say "Ficus", and a naive `{language}` instruction
made the model return the common noun "Fig", which is wrong.

Species has no established Russian form, so it stays Latin regardless of locale.

## Decision

1. For **locale `ru`**, the prefill prompt asks for the **localized Russian genus**
   («Монстера», «Алоказия», «Фикус», «Замиокулькас», «Филодендрон»), and a rule
   states it is shown directly to the user.
2. For **every other locale** (en/de/fr), the prompt asks for the **standard Latin
   genus** — no localization, because English practice uses the Latin name.
3. `genus` and `plant_family` are capitalized on first letter in
   `_normalize_botanical_prefill` (the model was inconsistent: «фикус» vs «Фикус»).
4. `species` remains lowercase Latin in all locales.

## Implementation

- `backend/app/ai_care.py`:
  - `_botanical_prefill_prompt`: locale-aware `genus_desc` / `genus_rule`
    (Russian localized vs Latin).
  - `_normalize_botanical_prefill`: first-letter capitalization of `genus` and
    `plant_family`.
  - `_looks_script_mashed`: penalizes a Cyrillic field that contains Latin letters
    (e.g. «Апocinовые») so a script-clean answer is preferred.
  - `_botanical_prefill_via_openrouter`: sequential "first complete, script-clean
    answer wins", keeping the best partial otherwise. **Majority voting across models
    was tried and rejected** — the weak free models make correlated mistakes (two
    agreed on «Бифоркатум» → Монстера), so a vote picks the wrong genus; the
    sequential walk is both more accurate and faster (~3-5 s typical).

## Behavior

- Russian UI input yields a Russian genus and Russian family; English UI keeps Latin.
- Species is always Latin (`bifurcatum`, `elastica`, `deliciosa`).

## Consequences — data duplication (IMPORTANT)

Genus is a **free-text field and also the grouping key**. `PlantGenusDetailsPage`
filters plants by exact `plant.genus` match, so plants saved as «Алоказия» and as
`Alocasia` form **two separate genus pages**. Making prefill always produce the
Russian form does not merge her existing split — it adds to the Russian side. This was
surfaced to the user; consolidating the existing data (or adding genus aliasing) is a
separate task and was NOT done here.

Family naming is the free model's weak spot: it sometimes invents a non-standard
Russian family name (e.g. «Апокниевые» instead of «Кутровые» for Hoya). Genus is far
more reliable than family.

## Verification

Live against production, through the real auth path after deploy:

- RU: «монстера»→Монстера/Ароидные, «замиокулькас»→Замиокулькас/Ароидные,
  «фикус каучуконосный»→Фикус/elastica/Тутовые,
  «орхидея фаленопсис»→Фаленопсис/Орхидные,
  «Пинк принцесс»→Филодендрон/erubescens/Ароидные,
  «Хойя Кримсон Квин»→Хойя/Кримсон Квин,
  «Бифоркатум»→Платицериум/bifurcatum/Полиподиевые.
- EN: «Monstera»→Monstera/Araceae, «Ficus elastica»→Ficus/elastica/Moraceae
  (NOT "Fig"), «Philodendron Pink Princess»→Philodendron/erubescens/Araceae.
- Latency mostly 2-9 s uncached, ~5 ms on cache hit.
- `/health` 200, service active, no errors in `journalctl -u plontukrot -p err`.
