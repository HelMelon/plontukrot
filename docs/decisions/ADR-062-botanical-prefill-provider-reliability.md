# ADR-062: AI botanical prefill — provider reliability and response-field loss

## Status

Accepted

## Context

After ADR-061 shipped the AI botanical prefill (`POST /botanical/prefill`), the
user reported that the feature did nothing useful:

- Entering a plant name **in Russian** returned no data and no visible error.
- Entering a name **in English** still required going to Google first to find the
  correct English name — defeating the point of the feature.
- The goal is: type any name — including a Russian common name or a trading name
  (e.g. «Бифоркатум», «Розовый принц») — and have the botanical fields (genus,
  species, cultivar, family, ...) filled automatically.

Server logs showed the real input was «Бифоркатум» and the endpoint answered
`502 Failed to generate botanical prefill … No AI provider returned`. Two
independent defects were found and confirmed against production.

### Defect 1 — the configured free model was unreliable, and the failure was masked

- `OPENROUTER_MODEL` was `nvidia/nemotron-3-ultra-550b-a55b:free`. That model
  frequently answers **HTTP 200 with an `{"error": {...}}` body**
  (`provider_overloaded`, code 503) instead of `choices`.
- The OpenAI-compatible callers only checked `body.get("choices")`; a 200-with-error
  body therefore read as `"No choices returned from LLM API"` — the real provider
  error was hidden, every retry looked identical.
- `DEEPSEEK_API_KEY` is present but the account is unfunded (`HTTP 402 Payment
  Required`), so the configured fallback chain had **no working provider at all**.
- Measured on prod: `gemma-4-31b:free` returned HTTP 429, `thinkingmachines/inkling:free`
  HTTP 403, while `nvidia/nemotron-3-super-120b-a12b:free` answered every Russian and
  English case correctly (transliterations and trading names included).

### Defect 2 — response fields were silently dropped to null

`BotanicalPrefillOut` used Pydantic aliases (`plantFamily`, `tradingName`, `isHybrid`)
but the router constructs the model with the **field names** (`plant_family=…`). In
Pydantic v2 an aliased field accepts only the alias unless `populate_by_name=True`, so
those three fields were dropped to their defaults on **every** response, in every
language — this is why the family was always empty even when the model returned it.

## Decision

1. **OpenRouter model chain with real fallback.** `_openrouter_models()` builds an
   ordered list: `OPENROUTER_FALLBACK_MODELS` (env, comma-separated) → `OPENROUTER_MODEL`
   → built-in free fallbacks (`nvidia/nemotron-3-super-120b-a12b:free`,
   `nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free`, `google/gemma-4-31b-it:free`).
   `_request_openrouter` / the prefill path try each in order and return the first
   success.
2. **Surface provider errors.** A shared `_extract_message_content(body)` raises a
   descriptive `ValueError("provider error (<code>): <message>")` when the body carries
   an `error` object, or when content is empty — no more generic "No choices".
3. **Response schema fixed.** `BotanicalPrefillOut` sets
   `model_config = ConfigDict(populate_by_name=True)`; serialization still honours the
   camelCase aliases the Flutter client expects.
4. **Primary model changed** to `nvidia/nemotron-3-super-120b-a12b:free` in
   `config.py` (code default) and in the systemd unit's `OPENROUTER_MODEL`
   (live value; secrets preserved).

## Implementation

- `backend/app/ai_care.py`: `import os`; new `_extract_message_content`;
  `_openrouter_models`; `_request_openrouter` retries the chain;
  `_request_botanical_prefill_openai_compatible` uses `_extract_message_content`;
  new `_botanical_prefill_via_openrouter`; `generate_botanical_prefill` uses it.
- `backend/app/schemas.py`: `BotanicalPrefillOut.model_config` with `populate_by_name`.
- `backend/app/config.py`: default `OPENROUTER_MODEL` updated.
- Server (not code): `OPENROUTER_MODEL` in `/etc/systemd/system/plontukrot.service`
  replaced in place (all other lines byte-identical; a `.bak_<ts>` copy kept).

## Behavior

- Free-text input in **any** language maps to the botanical fields; Russian common
  names and transliterations work (no need to look up the Latin name first).
- If the first free model is overloaded, the next one answers — the user no longer
  sees a hard failure for a transient provider problem.
- `plantFamily`, `tradingName`, `isHybrid` now actually reach the client.
- Unrecognizable input still returns all-null and the app shows its existing
  "не удалось распознать" message (no fabricated genus).

## Consequences

- Depends on OpenRouter free-tier availability; the env var
  `OPENROUTER_FALLBACK_MODELS` allows adding models without a redeploy.
- Free models can be slower (observed 2–10 s per uncached call); results are cached by
  `(phrase, locale)` so repeats are ~5 ms.
- DeepSeek remains configured but unfunded; it is a no-op fallback until topped up.

## Verification

Live, against production `http://127.0.0.1:8000` through the real auth path
(`create_access_token(owner)`), after deploy:

- 15/15 phrases returned HTTP 200 with populated fields — 12 Russian
  («Бифоркатум»→Platycerium/bifurcatum/Полиподиевые, «монстера»→Monstera/Ароидные,
  «замиокулькас», «толстянка», «фикус каучуконосный»→Ficus/elastica/Тутовые,
  «очиток Моргана»→Sedum/morganianum, «орхидея фаленопсис»→Phalaenopsis/Орхидные, ...)
  and 2 English, plus one nonsense input `asdfqwerty` → graceful all-null (HTTP 200).
- `plantFamily` and `tradingName` confirmed non-null in the HTTP JSON.
- Cache hit on repeat: 0.009 s / 0.005 s, identical body.
- `/health` 200, `systemctl is-active plontukrot` = active, no errors in
  `journalctl -u plontukrot -p err` for the deploy window.

## Note

The two defects were independent: fixing only the model would still have hidden the
family field, and fixing only the schema would still have produced 502s on Russian
input. Both had to be corrected for the feature to work as the user expects.
