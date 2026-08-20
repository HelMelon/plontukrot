"""FastAPI application entry point."""
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from .config import settings
from .db import get_pool
from .routers import auth, catalogs, plant_care, plants, propagations, social, species


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Open the DB pool on startup, close it on shutdown."""
    os.makedirs(settings.photos_dir, exist_ok=True)
    get_pool().open()
    yield
    get_pool().close()


app = FastAPI(title="plontukrot", version="0.1.0", lifespan=lifespan)

app.include_router(auth.router)
app.include_router(plants.router)
app.include_router(plant_care.router)
app.include_router(propagations.router)
app.include_router(catalogs.router)
app.include_router(social.router)
app.include_router(species.router)

# Serve uploaded photos from disk.
os.makedirs(settings.photos_dir, exist_ok=True)
app.mount("/photos", StaticFiles(directory=settings.photos_dir), name="photos")


@app.get("/health", tags=["meta"])
def health():
    """Liveness probe."""
    return {"status": "ok"}
