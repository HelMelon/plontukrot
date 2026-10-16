# ADR-064: Prefill must resolve trade/folk names to the true botanical genus

## Status

Accepted

## Context

The user typed «кротон петра» and the app filled genus **«Кротон»**. But the potted
houseplant sold as "croton" is ***Codiaeum variegatum*** — genus **Codiaeum (Кодиеум)** —
NOT the genus *Croton* (a different Euphorbiaceae). The model was taking the words
literally instead of resolving the trade name to the plant actually sold under it.

A wider probe found the same literal-matching failure across common folk names:

| input | filled (wrong) | should be |
|---|---|---|
| кротон петра | Кротон | **Кодиеум** variegatum |
| восковой плющ | Плющ / helix | **Хойя** carnosa |
| фиалка | Фиалка | **Сенполия** |
| паучник | Паучник | **Хлорофитум** comosum |
| щучий хвост | (empty) | **Сансевиерия** trifasciata |

Genus is stored as free text **and is the grouping key** (`PlantGenusDetailsPage`
filters by exact `plant.genus`), so a wrong genus both mislabels the plant and creates
a bogus genus page.

## Decision

Strengthen the prefill system prompt (`_botanical_prefill_prompt`) so the model
resolves the *real* plant rather than the words:

1. A `CRITICAL — do NOT take the words literally` section stating that many houseplants
   are sold under trade/folk names that disagree with their true genus.
2. An explicit mapping list of the common Russian/English traps (кротон→Кодиеум,
   декабрист/рождественник→Шлюмбергера, тещин язык/щучий хвост→Сансевиерия,
   денежное дерево→Толстянка, восковой плющ→Хойя, фиалка→Сенполия,
   герань→Пеларгония, паучник→Хлорофитум, кислица→Oxalis).
3. Few-shot examples (`_botanical_prefill_examples`, per language) showing the exact
   JSON output for the hardest cases — cheap models follow examples far better than
   prose rules.
4. When the trade name is the only thing given, it goes into `trading_name`.

## Implementation

- `backend/app/ai_care.py`:
  - new `_botanical_prefill_examples(locale)` — RU and (fallback) EN example blocks.
  - `_botanical_prefill_prompt` — appends the anti-literal section + examples; the
    genus description now says "the TRUE botanical genus".

## Behavior

- «кротон петра» → genus Кодиеум, species variegatum, cultivar петра, family Молочайные,
  trading_name «кротон петра». Stable across repeated (forceRefresh) calls.
- «восковой плющ» → Хойя carnosa; «фиалка» → Сенполия; «паучник» → Хлорофитум comosum;
  «декабрист»/«рождественник» → Шлюмбергера; «герань» → Пеларгония.
- English: "Croton Petra" → Codiaeum variegatum.
- Normal names are unaffected; nonsense input still returns all-null.

## Consequences

- The examples block lengthens the prompt (more input tokens); acceptable given the
  free-tier budget and the accuracy gain.
- Only the common traps are enumerated — an unlisted trade name can still be guessed
  literally. The list is the extension point: add rows as new mistakes appear.
- The model still occasionally invents a non-standard Russian family name («Апокниевые»
  for Hoya); genus is far more reliable than family. A family catalog would be a
  separate task.

## Verification

Live against production through the real auth path after deploy:

- Trade/folk names (RU): кротон петра→Кодиеум/variegatum/петра/Молочайные (5/5 stable);
  кротон→Кодиеум/variegatum; декабрист & рождественник→Шлюмбергера;
  щучий хвост & тещин язык→Сансевиерия trifasciata; денежное дерево→Толстянка ovata;
  восковой плющ→Хойя carnosa; кислица→Кислица; паучник→Хлорофитум comosum;
  фиалка→Сенполия; герань→Пеларгония.
- Regression (unchanged): монстера→Монстера, замиокулькас→Замиокулькас,
  фикус каучуконосный→Фикус elastica, орхидея фаленопсис→Фаленопсис,
  Бифоркатум→Платицериум bifurcatum, Хойя Кримсон Квин→Хойя carnosa.
- EN: Monstera→Monstera, Ficus elastica→Ficus elastica, Croton Petra→Codiaeum.
- asdfqwerty → all fields null (graceful).
- `/health` 200, service active, `journalctl -u plontukrot -p err` empty.
