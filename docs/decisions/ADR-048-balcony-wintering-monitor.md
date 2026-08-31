# ADR-048: Balcony wintering monitor (temperature alerts + cold-tolerance bands)

## Status

Accepted

## Context

The user wants to winter some houseplants on her balcony. The balcony is a
**warm, glazed** space (not an open one) — in late August it holds ~25°C while
the outside night temperature in Gomel is ~16°C. But in winter it will drop
well below what most tropical houseplants can survive. The user needs to know
**when to bring a plant back inside** before it freezes.

Two hard facts shaped the design:

1. **The Yandex climate sensor on the balcony** (`bf56b858-16fa-4a59-a807-72615cdeb438`,
   model TS0201, in room "Балкон") reports live `temperature`/`humidity`/`battery`.
   It is read via the **Yandex IOT API** (`https://api.iot.yandex.net/v1.0/user/info`,
   `Authorization: OAuth <token>`). The old `iot.quasar.yandex.ru` host 404s on
   everything and must not be used.
2. **The app has no push infrastructure** for arbitrary events. Fertilizing
   reminders are *local* notifications scheduled on-device — they cannot work for
   a live temperature that changes hourly. So the **backend** must poll the sensor
   and deliver alerts.

The user's collection is ~40 plants with very different cold tolerance (плющ
survives −20°C, антуриум needs +15°C). Each plant needs a per-plant cold-tolerance
threshold so the monitor only alerts when *that* plant is at risk.

## Decision

### 1. Per-plant balcony state + cold-tolerance band

- `plants.on_balcony` (bool) — is the plant currently on the balcony.
- `plants.balcony_band` (int) — cold-tolerance band 0..4, mirroring a backend
  `BAND_MIN_TEMP` map:

  | band | min °C | examples |
  |------|--------|----------|
  | 0 frostHardy | −20 | Hedera (плющ) |
  | 1 coldHardy  | −5  | Cycas (саговник), Oxalis (кислица) |
  | 2 cool       | +4  | Dichondra (дихондра) |
  | 3 moderate   | +10 | most tropical houseplants |
  | 4 warm       | +15 | Anthurium (антуриум) |

- Added to `PlantCreate`/`PlantUpdate`/`PlantOut` schemas and the Flutter `Plant`
  model (`onBalcony`, `balconyBand`).

### 2. Backend balcony monitor

- New router `backend/app/routers/balcony.py`:
  - `GET /balcony/status` (JWT) — reads the sensor, returns `{active, temperature,
    needs_inside: [{plant_id, name, band, min_temp}]}`.
  - `check_and_alert()` — one monitor pass: reads temp, finds balcony plants below
    their band minimum, sends a Telegram alert.
- A background `asyncio` loop in `main.py` runs `check_and_alert()` every 30 minutes.
- **Season window**: active only **1 August .. 30 April**. In summer the balcony is
  a full-sun death trap (no shade), so the feature is disabled (`active: false`).
- Telegram delivery uses the same bot token + chat_id already used by the moisture
  sensor (`TELEGRAM_TOKEN`, `TELEGRAM_CHAT_ID`). No separate bot process is needed —
  the ESP8266 moisture sensor already posts to Telegram itself, and the backend posts
  temperature alerts directly.

### 3. Cold-tolerance resolution (frontend)

`lib/models/balcony_band.dart` — `BalconyBandResolver.resolve(plant)`:

1. Plant's stored `balconyBand` (explicitly set).
2. **Built-in genus table** (Latin + Russian names) — authoritative for known
   genera, so the AI can't override e.g. плющ → +15°C.
3. The genus care guide's `min_temp_c` (AI-generated, cached on backend) for
   unknown genera.
4. `moderate` (+10°C) as the safe default.

The toggle (`lib/features/plants/widgets/cards/balcony_toggle.dart`) is shown in the
plant info card; the home screen shows a `BalconyAlertBanner` when the sensor reports
a temperature below a balcony plant's threshold.

### 4. AI provider: OpenRouter free-tier (replaces DeepSeek as primary)

The genus care guide (ADR-043/044) used DeepSeek, which began returning
`402 Payment Required` (unfunded account). The user asked to switch to **OpenRouter
using only free models**.

- `config.py` gains `OPENROUTER_API_KEY` and `OPENROUTER_MODEL`
  (default `nvidia/nemotron-3-ultra-550b-a55b:free`).
- `ai_care.py` adds `_request_openrouter()` and makes OpenRouter the **first**
  provider in the chain; DeepSeek/YandexGPT/Gemini/OpenAI remain as fallbacks.
- The care-guide JSON schema now includes `min_temp_c` (a number), persisted in
  `genus_care_guides.min_temp_c` and exposed on `GenusCareGuideOut`.

### 5. No fabricated data (mock removed)

The previous `_mock_care_guide()` invented care text and `min_temp_c: 10` when no
AI provider answered — this misled the user (e.g. плющ showed +15°C). It is **removed**.
If no provider returns a guide, `generate_care_guide` raises, the endpoint returns
**502**, and **nothing is cached**. The user explicitly wants: no data → show nothing.

## Implementation

- **Backend**
  - `backend/app/config.py` — `YANDEX_IOT_TOKEN`, `BALCONY_SENSOR_ID`,
    `TELEGRAM_TOKEN`, `TELEGRAM_CHAT_ID`, `OPENROUTER_API_KEY`, `OPENROUTER_MODEL`.
  - `backend/app/db.py` — `plants.on_balcony`, `plants.balcony_band`,
    `genus_care_guides.min_temp_c` migrations.
  - `backend/app/schemas.py` — plant balcony fields; `GenusCareGuideOut.min_temp_c`.
  - `backend/app/routers/balcony.py` — new router + `check_and_alert()`.
  - `backend/app/routers/plants.py` — read/write balcony fields.
  - `backend/app/routers/genera.py` — persist/return `min_temp_c`.
  - `backend/app/ai_care.py` — OpenRouter provider, `min_temp_c` in prompt, mock removed.
  - `backend/app/main.py` — background balcony monitor loop.
- **Flutter**
  - `lib/models/balcony_band.dart` — `BalconyBand` enum + `BalconyBandResolver`.
  - `lib/models/plant.dart` — `onBalcony`, `balconyBand`.
  - `lib/models/genus_care_guide.dart` — `minTempC`.
  - `lib/services/plant_service.dart` — `setOnBalcony()`.
  - `lib/features/plants/widgets/cards/balcony_toggle.dart` — the toggle.
  - `lib/features/plants/widgets/cards/plant_info_card.dart` — embeds the toggle.
  - `lib/features/home/widgets/balcony_alert_banner.dart` — home banner.
  - `lib/features/home/pages/home_page.dart` — shows the banner.
  - `lib/l10n/*.arb` — balcony strings (RU/EN/DE/FR).

## Behavior

- Marking a plant "on the balcony" resolves its cold-tolerance band automatically
  (built-in table → AI care guide → +10°C default).
- Every 30 minutes the backend reads the balcony sensor; if a balcony plant's
  temperature drops below its band minimum, a Telegram alert is sent.
- The home screen shows a banner listing plants that need bringing inside.
- The feature is inactive outside 1 Aug .. 30 Apr.
- If the AI provider is down/unfunded, the care guide shows nothing (no fake data).

## Consequences

- The user gets proactive "bring it inside" alerts without manual temperature checks.
- Cold tolerance is per-plant and auto-resolved, including for newly added plants
  via the AI care guide.
- No separate bot process is required — the backend posts to Telegram directly.
- Free-tier OpenRouter keeps AI generation working without DeepSeek funding.
- Removing the mock means an unfunded/unreachable AI provider yields an empty guide
  rather than misleading content.

## Verification

- Confirmed the Yandex IOT API reads the balcony sensor (temp ~25.5°C, season active).
- Confirmed `on_balcony`/`balcony_band` columns exist in the live DB.
- Confirmed OpenRouter free model returns valid JSON with `min_temp_c` for new genera
  (Spathiphyllum, Calathea).
- Confirmed `generate_care_guide` now raises (no mock) when no provider answers.
- `flutter analyze` clean on all touched Dart files.
