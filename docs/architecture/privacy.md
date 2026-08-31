# Privacy and access control

Living document. Enforced by Firebase rules in repo root.

---

## Firestore (`firestore.rules`)

| Path | Access |
|------|--------|
| `users/{userId}` and all nested docs | read/write if `request.auth.uid == userId` |
| `plantSpecies/{id}` | authenticated read; authenticated create with field validation; **no** client update/delete |

Unauthenticated access denied.

## Storage (`storage.rules`)

Paths:

- Legacy cover: `plants/{userId}/{fileName}` (e.g. `{plantId}.jpg`, `{plantId}_thumb.jpg`)
- Gallery: `plants/{userId}/{plantId}/{fileName}` (e.g. `{photoId}.jpg`, `{photoId}_thumb.jpg`)

| Action | Rule |
|--------|------|
| read / delete | signed in and `auth.uid == userId` |
| write | owner; filename ends with `.jpg`; size &lt; 5 MB; `contentType` `image/jpeg` |

## Client expectations

- All user plant/care/catalog data is per-uid under `users/{uid}`.
- Shared botanical catalog (`plantSpecies`) is readable by any signed-in user; writes are create-only from clients via `PlantSpeciesService.ensureSpecies`.
- Do not store secrets in Firestore documents.
- PII currently on user doc: `name`, `email` (from Google profile at create time), and `personalDataConsentAt` (timestamp when the user accepted the Privacy Policy).
- Privacy Policy URL: `https://helmelon.github.io/plontukrot/privacy.html` (consent required at Google sign-in; existing sessions without consent are gated).
- Full account deletion (profile page) removes Auth user, `users/{uid}` subtree, and Storage `plants/{uid}/`; it does not remove shared `plantSpecies` entries.

Formal privacy policy document: hosted at the URL above (see ADR-014).

---

## Sensor data, smart-home OAuth, and Telegram (planned)

> ⏳ **Запланировано** — см. `docs/product/roadmap.md`. Эти пункты ещё не реализованы, но политика должна их покрыть, когда появятся.

### Sensor readings (soil moisture, balcony temperature)
- **Что собираем**: показания датчиков — влажность почвы (горшки), температура/влажность воздуха балкона, заряд батареи датчика.
- **Как получаем**: ESP8266-датчики шлют на сервер; температура балкона — через подключённый Яндекс Умный Дом.
- **Зачем**: показ влажности на карточках растений, алерты «пора полить», балконный мониторинг зимовки.
- **Хранение**: история показаний на сервере; срок хранения — уточнить (например, 30 дней).

### Smart-home OAuth (per-user)
- Пользователь подключает свой Яндекс Умный Дом через OAuth.
- Сервер хранит **его** токены доступа (зашифрованными) и читает **его** устройства.
- Токены — чувствительные данные: шифрование обязательно, не логировать.

### Telegram bot
- Пользователь привязывает свой Telegram-чат к аккаунту (deep-link с одноразовым кодом).
- Сервер хранит `chat_id` для доставки алертов.
- Алерты (полив, балкон) отправляются только в привязанный чат.

### Третьи лица
- **Яндекс**: OAuth-авторизация + чтение устройств пользователя.
- **Telegram**: доставка уведомлений через бота.

### Согласие
- Поле `personal_data_consent_at` — явное согласие пользователя, включая подключение умного дома и Telegram.

