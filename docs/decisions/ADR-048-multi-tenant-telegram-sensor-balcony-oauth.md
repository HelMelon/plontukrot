# ADR-048: Multi-Tenant Telegram Bot, Sensor Bindings, Balcony History and Per-User Yandex OAuth

## Status

Accepted

## Context

Plontukrot was originally a single-user app: one hardcoded `TELEGRAM_CHAT_ID` received
all moisture alerts directly from the ESP8266 firmware, sensor data was not bound to any
plant in the UI, and the Yandex Smart Home token was a single value in the environment
shared by every user. As the app moved toward multi-tenant usage (one Telegram bot for
all users, per-user Yandex accounts), several structural gaps surfaced:

1. **Single-user Telegram alerts.** The firmware posted directly to one hardcoded chat.
   There was no way to route alerts to the correct user, and no binding between a user
   and their Telegram chat.
2. **Sensors not visible in the UI.** `sensor_readings` were stored per `pot` with no
   link to a `plant`, so the app could not show live moisture on plant cards.
3. **No balcony temperature history.** `GET /balcony/status` returned only the current
   reading; there was no table or endpoint for day/night averages over time.
4. **Single shared Yandex OAuth token.** Every user would have shared one token from the
   environment, which is both a privacy problem and a multi-tenant blocker.
5. **Terminology.** The word «горшок» (pot) was used across the app, Telegram and Smart
   Home, but the physical device is a sensor; the user requested a global rename to
   «датчик» (sensor) plus full internationalization (ru/en/de/fr).
6. **Icon tokens.** The sensor icon was hardcoded as `Icons.water_drop`/`Icons.sensors`
   instead of using the design-token system.

## Decision

1. **One Telegram bot for all users** — `@plontukrot_bot` (id `8521219484`), replacing
   the old plant-scanner bot. Binding is done via a deep link `t.me/plontukrot_bot?start=<code>`.
   New tables `telegram_links (user_id, chat_id)` and `telegram_link_codes`; new router
   `routers/telegram.py` with `link`/`confirm`/`status` endpoints and a
   `send_telegram_alert()` helper. Alerts are sent only to bound chats.
2. **Moisture alerts fully server-side.** The firmware no longer posts to Telegram
   directly; it POSTs to the server, which fans out to all bound users. Accepted trade-off:
   if the server is down, no alerts are sent. Threshold changed from `>=20%` to `<20%`
   («полить»).
3. **Sensor↔plant binding.** New table `plant_sensor_bindings (plant_id, pot, user_id)`
   and router `routers/sensor_bindings.py` with `POST/GET/DELETE /plants/{plant_id}/sensor-binding`
   (409 on pot conflict). Frontend: `PlantSensorBinding` model, `PlantSensorService`
   (bind/getBinding/unbind/watchBinding, 30s live stream), `SensorBindingToggle` widget,
   and a moisture badge on `PlantCard` (red when `<20%`), fed by a `StreamBuilder` on
   `home_page.dart` via `GET /plants/sensor-bindings`.
4. **Balcony temperature history.** New table `balcony_temp_readings (user_id, temp_c, read_at)`;
   `GET /balcony/status` writes a reading; new `GET /balcony/history` returns 3-day
   aggregates (day_avg 08:00–21:00, night_avg 21:00–08:00 ending that morning,
   overall_avg, latest). Frontend: `BalconyDayTemp`
   model, `BalconyService`, `BalconyHistorySheet` (3 rows: позавчера/вчера/сегодня) opened
   by a 🕓 button in `BalconyToggle`. The background monitor loop `check_and_alert()` also
   writes readings for the primary user.
5. **Per-user Yandex OAuth.** New table `user_oauth_tokens` with mandatory encryption of
   user tokens (they are third-party access keys). Flow: «Подключить Яндекс» →
   `oauth.yandex.ru` → per-user token → `api.iot.yandex.net/v1.0/user/info`. Correct host
   is `api.iot.yandex.net` (not `iot.quasar.yandex.ru`, which 404s without the IOT scope).
6. **«Горшок» → «датчик» everywhere** (app, Telegram, Smart Home) with l10n across
   ru/en/de/fr. The Kufar bot is explicitly excluded (there «горшок» is a real product).
7. **Icon via design tokens.** The sensor icon uses the humidity token/theme rather than
   a hardcoded `Icons.water_drop`/`Icons.sensors`. Note: no single glyph «капля с %»
   exists in Material Icons or hugeicons; closest is `HugeIcons.strokeRoundedHumidity`
   (drop with a wave). A drop+percent composite can be built with a `Stack` if exact
   fidelity is required.

## Implementation

- `backend/app/db.py`: added `telegram_links`, `telegram_link_codes`,
  `plant_sensor_bindings`, `balcony_temp_readings`, `user_oauth_tokens`.
- `backend/app/config.py`: added `telegram_bot_username`.
- `backend/app/routers/telegram.py` (new): link/confirm/status + `send_telegram_alert()`.
- `backend/app/routers/sensor_bindings.py` (new): plant↔sensor binding.
- `backend/app/routers/balcony.py`: `_maybe_alert` fans out to all bound users;
  `GET /balcony/status` writes history; `GET /balcony/history`; `check_and_alert()` writes.
- `backend/app/routers/sensor.py`: alert on crossing `<20%`, all bound users.
- `backend/app/routers/smart_home.py`: default name «Датчик влажности горшка N».
- `backend/app/main.py`: `sensor_bindings.router` mounted **before** `plants` (see Errors).
- `C:\Users\helga\plants-bot\moisture_sensor\moisture_sensor_server_only.ino` (new):
  server-only firmware, «Датчик 1/2/3», no direct Telegram.
- `plontukrot_bot.py` (deployed to server, systemd `plontukrot-bot`): `/start <code>`,
  `/moisture`, `/name`, `/help` (Latin command names only — Cyrillic is invalid in Telegram).
- Frontend: `plant_sensor_binding.dart`, `plant_sensor_service.dart`,
  `sensor_binding_toggle.dart`, `telegram_service.dart`, `telegram_link_tile.dart`
  (`HugeIcons.strokeRoundedTelegram`), `balcony_day_temp.dart`, `balcony_service.dart`,
  `balcony_history_sheet.dart`; modified `plant_info_card.dart`, `plant_card.dart`,
  `home_page.dart`, `profile_page.dart`, `balcony_toggle.dart`, l10n (4 arb).

## Behavior

- One Telegram bot serves all users; alerts reach only bound chats.
- Live moisture appears on plant cards once a sensor is bound to a plant.
- Balcony history shows day/night averages for the last 3 days.
- Each user connects their own Yandex account; tokens are encrypted at rest.
- Terminology is consistent («датчик») across app, Telegram and Smart Home, localized.

## Consequences

- Alerts depend on server availability (accepted).
- Per-user OAuth requires a privacy-policy update and, for a public Yandex app, likely
  moderation; starting small (personal app) avoids it.
- The old plant-scanner bot (id `8805151008`) can be removed via `/deletebot`.

## Errors & Fixes

- **`GET /plants/sensor-bindings` → 404 «Plant not found»**: the dynamic `plants`
  router (`/{plant_id}`) was mounted before `sensor_bindings`, so the static path was
  captured as a plant id. Fix: mount `sensor_bindings.router` before `plants` in `main.py`.
- **`GET /plants/{id}/sensor-binding` → 500 ResponseValidationError
  `{'type': 'model_attributes_type', 'input': None}`**: `get_binding` returned `None`
  when no binding existed, which the `response_model` rejects. Fix: return 404.
- **Cyrillic `CommandHandler` names are invalid** in Telegram — kept only Latin commands.
- **Deploy failed on `sftp.put` after `rename`** — write directly via `sftp.open(remote,'w')`
  (backups already exist); guard `sftp.rename` on non-existent files with `sftp.stat()`.
- **`pgrep -f uvicorn` grabbed the wrong process** (lesesucht on 8001) — use
  `ss -tlnp | grep ':8000 '` to find the plontukrot pid.
- **`iot.quasar.yandex.ru` → 404** — sign of missing IOT scope; mark «Умный дом (IOT)»
  (`iot:all`) and re-issue the token. Use `api.iot.yandex.net` instead.

## Verification

- Backend and bot syntax checks passed (`ALL OK`, `BOT OK`).
- Full flow tested on the live server: link → confirm → status + alert to the new bot
  (400 on a non-existent chat_id, does not crash); test data cleaned up.
- `flutter analyze lib/` passed with 0 issues.
- APK built (release, ~76MB) and installed on Vivo V2419A (`com.example.plontukrot`).
- `GET /plants/sensor-bindings` and `GET /plants/{id}/sensor-binding` verified live.
