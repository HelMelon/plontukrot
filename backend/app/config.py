"""Application configuration loaded from environment variables and .env file."""
from __future__ import annotations

import os


def _load_env_file(path: str) -> None:
    """Load key-value pairs from a .env file if it exists."""
    if not os.path.isfile(path):
        return
    try:
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                k = k.strip()
                v = v.strip().strip("'\"")
                if k and k not in os.environ:
                    os.environ[k] = v
    except Exception:
        pass


def _bootstrap_env() -> None:
    """Load .env files from backend directory or project root."""
    backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    _load_env_file(os.path.join(backend_dir, ".env"))
    root_dir = os.path.dirname(backend_dir)
    _load_env_file(os.path.join(root_dir, ".env"))
    _load_env_file(".env")


_bootstrap_env()


class Settings:
    """Central configuration. All secrets come from the environment / .env."""

    def __init__(self) -> None:
        # Database
        self.database_url: str = os.environ.get(
            "DATABASE_URL",
            "postgresql://plontukrot:***@127.0.0.1:5432/plontukrot",
        )
        # Auth
        self.secret_key: str = os.environ.get(
            "SECRET_KEY", "change-me-in-production"
        )
        self.access_token_expire_minutes: int = int(
            os.environ.get("ACCESS_TOKEN_EXPIRE_MINUTES", "525600")
        )
        self.algorithm: str = "HS256"
        # Public base URL used to build absolute photo links.
        self.public_base_url: str = os.environ.get(
            "PUBLIC_BASE_URL", "http://127.0.0.1:8000"
        )
        # Directory where uploaded plant photos are stored on disk.
        self.photos_dir: str = os.environ.get(
            "PHOTOS_DIR", "/opt/plontukrot/photos"
        )
        # Shared token used by ESP8266 soil-moisture sensors to post readings.
        self.sensor_token: str = os.environ.get("SENSOR_TOKEN", "")
        # AI / LLM configuration for botanical care guides
        self.deepseek_api_key: str = os.environ.get("DEEPSEEK_API_KEY", "")
        self.yandex_gpt_api_key: str = os.environ.get("YANDEX_GPT_API_KEY", "")
        self.yandex_folder_id: str = os.environ.get("YANDEX_FOLDER_ID", "")
        self.yandex_gpt_model: str = os.environ.get(
            "YANDEX_GPT_MODEL", "yandexgpt-lite"
        )
        self.gemini_api_key: str = os.environ.get("GEMINI_API_KEY", "")
        self.gemini_model: str = os.environ.get(
            "GEMINI_MODEL", "gemini-1.5-flash"
        )
        self.openai_api_key: str = os.environ.get("OPENAI_API_KEY", "")
        self.openai_base_url: str = os.environ.get(
            "OPENAI_BASE_URL", "https://api.openai.com/v1"
        )
        self.openai_model: str = os.environ.get("OPENAI_MODEL", "gpt-4o-mini")
        # Yandex Smart Home skill credentials (filled after registering).
        self.yandex_client_id: str = os.environ.get("YANDEX_CLIENT_ID", "")
        self.yandex_client_secret: str = os.environ.get(
            "YANDEX_CLIENT_SECRET", ""
        )
        # Fixed access token the skill always hands out; survives restarts.
        self.yandex_access_token: str = os.environ.get(
            "YANDEX_ACCESS_TOKEN", ""
        )


settings = Settings()
