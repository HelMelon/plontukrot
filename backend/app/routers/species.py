"""Global plant species catalog (was Firestore `plantSpecies`)."""
from fastapi import APIRouter, Depends
from pydantic import BaseModel

from ..db import get_pool
from ..routers.auth import get_current_user_id

router = APIRouter(prefix="/species", tags=["species"])


class SpeciesOut(BaseModel):
    id: str
    species: str
    genus: str | None = None
    plant_family: str | None = None


class SpeciesIn(BaseModel):
    species: str
    genus: str | None = None
    plant_family: str | None = None


@router.get("", response_model=list[SpeciesOut])
def list_species(user_id: str = Depends(get_current_user_id)):
    """Return the global catalog (authenticated, but shared across users)."""
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, species, genus, plant_family "
            "FROM plant_species ORDER BY species"
        ).fetchall()
    return [SpeciesOut(**r) for r in rows]


@router.post("", response_model=SpeciesOut, status_code=201)
def ensure_species(payload: SpeciesIn,
                   user_id: str = Depends(get_current_user_id)):
    """Create a species if it does not already exist; return the row either way."""
    sid = payload.species.strip().lower().replace(" ", "-")
    with get_pool().connection() as conn:
        row = conn.execute(
            "SELECT id, species, genus, plant_family FROM plant_species "
            "WHERE id = %s",
            (sid,),
        ).fetchone()
        if row is None:
            conn.execute(
                "INSERT INTO plant_species (id, species, genus, plant_family) "
                "VALUES (%s, %s, %s, %s)",
                (sid, payload.species.strip(), payload.genus,
                 payload.plant_family),
            )
            row = conn.execute(
                "SELECT id, species, genus, plant_family FROM plant_species "
                "WHERE id = %s",
                (sid,),
            ).fetchone()
    return SpeciesOut(**row)

