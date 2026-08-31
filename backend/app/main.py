"""FastAPI application entry point."""
import asyncio
import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .config import settings
from .db import auto_migrate, get_pool
from .routers import (
    auth,
    balcony,
    catalogs,
    genera,
    manipulations,
    plant_care,
    plants,
    propagations,
    sensor,
    sensor_bindings,
    smart_home,
    social,
    species,
    telegram,
)

log = logging.getLogger(__name__)

# Balcony monitor: check the temperature every 30 minutes.
_BALCONY_INTERVAL_SECONDS = 30 * 60


async def _balcony_monitor_loop() -> None:
    """Periodically check the balcony temperature and alert when a plant
    needs bringing inside. Runs for the life of the process."""
    while True:
        try:
            result = balcony.check_and_alert()
            if result.get("alerted"):
                log.info("Balcony alert sent: %s", result.get("needs_inside"))
        except Exception:
            log.exception("balcony monitor pass failed")
        await asyncio.sleep(_BALCONY_INTERVAL_SECONDS)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Open the DB pool on startup, run migrations, close it on shutdown."""
    os.makedirs(settings.photos_dir, exist_ok=True)
    get_pool().open()
    auto_migrate()
    monitor_task = asyncio.create_task(_balcony_monitor_loop())
    yield
    monitor_task.cancel()
    get_pool().close()


app = FastAPI(title="plontukrot", version="0.1.0", lifespan=lifespan)

# Allow the Flutter web build (any origin) to call the REST API. Web requests
# from a browser are blocked by CORS unless the server explicitly allows the
# origin. We allow all origins so `flutter run -d chrome` works out of the box;
# tighten this to a fixed domain list if the web build is ever deployed to a
# public hostname.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
# sensor_bindings must come BEFORE plants so its static /sensor-bindings
# path is matched before plants' dynamic /{plant_id}.
app.include_router(sensor_bindings.router)
app.include_router(plants.router)
app.include_router(plant_care.router)
app.include_router(propagations.router)
app.include_router(catalogs.router)
app.include_router(social.router)
app.include_router(species.router)
app.include_router(genera.router)
app.include_router(manipulations.router)
app.include_router(sensor.router)
app.include_router(smart_home.router)
app.include_router(balcony.router)
app.include_router(telegram.router)

# Serve uploaded photos from disk.
os.makedirs(settings.photos_dir, exist_ok=True)
app.mount("/photos", StaticFiles(directory=settings.photos_dir), name="photos")


@app.get("/health", tags=["meta"])
def health():
    """Liveness probe."""
    return {"status": "ok"}
