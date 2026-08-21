"""FastAPI application entry point."""
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .config import settings
from .db import auto_migrate, get_pool
from .routers import auth, catalogs, plant_care, plants, propagations, social, species


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Open the DB pool on startup, run migrations, close it on shutdown."""
    os.makedirs(settings.photos_dir, exist_ok=True)
    get_pool().open()
    auto_migrate()
    yield
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
