"""FastAPI application entry point."""
from contextlib import asynccontextmanager

from fastapi import FastAPI

from .db import get_pool
from .routers import auth, catalogs, plant_care, plants, propagations, social, species


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Open the DB pool on startup, close it on shutdown."""
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


@app.get("/health", tags=["meta"])
def health():
    """Liveness probe."""
    return {"status": "ok"}
