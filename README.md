# Plöntukrot

Трекер коллекции комнатных растений (бренд **SKÖRD**) — iOS, Android и web.

Приложение ведёт карточки растений и черенков, расписание полива и ухода,
карантин новых поступлений, фото и напоминания. Интерфейс полностью на русском,
тёмная тема — основная.

## Стек

- **Flutter / Dart** — iOS, Android, web из одной кодовой базы
- **Бэкенд:** self-hosted **FastAPI + PostgreSQL** (`backend/`), приложение ходит в него
  по REST через `ApiClient`; миграция с Firebase — [ADR-033](docs/decisions/ADR-033-firebase-to-fastapi-migration.md)
- Локальные уведомления и часовые пояса, пайплайн изображений (сжатие, кроп),
  локализация через `l10n`

## Запуск

```bash
flutter pub get
flutter run -d chrome        # web
flutter run                  # android / ios
```

Бэкенд — см. [`backend/README.md`](backend/README.md) (нужен PostgreSQL и `DATABASE_URL`).

## Структура

```
lib/            # фичи, core, сервисы, темы
backend/        # FastAPI + PostgreSQL, мигратор с Firebase
docs/           # продукт, архитектура, ADR, исследования
test/           # unit и widget тесты
```

Проект ведётся с документацией: решения фиксируются в `docs/decisions/`,
архитектурный обзор — в [`docs/architecture/overview.md`](docs/architecture/overview.md).

## Документация

| Область | С чего начать |
|------|-----------|
| Продукт | [docs/product/](docs/product/) |
| **Архитектура** | [docs/architecture/overview.md](docs/architecture/overview.md) |
| Аудит архитектуры | [docs/architecture/ARCHITECTURE_AUDIT.md](docs/architecture/ARCHITECTURE_AUDIT.md) |
| Firebase (историческое) | [docs/architecture/firebase.md](docs/architecture/firebase.md) |
| Модель данных | [docs/architecture/data-model.md](docs/architecture/data-model.md) |
| Разработка | [docs/development/](docs/development/) |
| ADR | [docs/decisions/](docs/decisions/) |
| Исследования | [docs/research/](docs/research/) |

Cursor agent rules (для контрибьюторов в Cursor): `.cursor/rules/`.
