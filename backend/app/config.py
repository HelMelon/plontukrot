"""Application configuration loaded from environment variables."""
import os


class Settings:
    """Central configuration. All secrets come from the environment."""

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
