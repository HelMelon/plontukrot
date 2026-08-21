"""Plants endpoints (JWT-protected, scoped to the caller)."""
import uuid

from fastapi import APIRouter, Depends, HTTPException, status

from ..db import get_pool
from ..routers.auth import get_current_user_id
from ..schemas import PlantCreate, PlantOut, PlantPhotoOut, PlantUpdate

router = APIRouter(prefix="/plants", tags=["plants"])

# Map Firestore-style field names to column names.
_FIELDS = {
    "genus": "genus",
    "species": "species",
    "cultivar": "cultivar",
    "trading_name": "trading_name",
    "plant_family": "plant_family",
    "nickname": "nickname",
    "stage": "stage",
    "variegation": "variegation",
    "watering_frequency": "watering_frequency",
    "fertilizing_frequency_days": "fertilizing_frequency_days",
    "initial_leaf_count": "initial_leaf_count",
}


@router.get("", response_model=list[PlantOut])
def list_plants(user_id: str = Depends(get_current_user_id)):
    """Return all plants belonging to the current user, with their photos.

    Photos are fetched in a single JOIN (no N+1) so the home grid loads in one
    request instead of one request per plant.
    """
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, genus, species, cultivar, trading_name, plant_family, "
            "nickname, stage, variegation, watering_frequency, "
            "fertilizing_frequency_days, initial_leaf_count, last_watered_at, "
            "last_fertilized_at, last_repotted_at, created_at "
            "FROM plants WHERE user_id = %s ORDER BY created_at",
            (user_id,),
        ).fetchall()
        photos = conn.execute(
            "SELECT id, plant_id, image_url, image_thumb_url, added_at, "
            "is_legacy FROM plant_photos "
            "WHERE plant_id = ANY(%s) ORDER BY added_at DESC",
            ([r["id"] for r in rows],),
        ).fetchall()
    by_plant: dict[str, list[dict]] = {}
    for p in photos:
        by_plant.setdefault(p["plant_id"], []).append(dict(p))
    result = []
    for r in rows:
        plant = _row_to_plant(r)
        plant.photos = [
            PlantPhotoOut(**p) for p in by_plant.get(r["id"], [])
        ]
        result.append(plant)
    return result


@router.post("", response_model=PlantOut, status_code=201)
def create_plant(payload: PlantCreate, user_id: str = Depends(get_current_user_id)):
    plant_id = uuid.uuid4().hex[:20]
    values = {
        "id": plant_id,
        "user_id": user_id,
    }
    for schema_field, column in _FIELDS.items():
        val = getattr(payload, schema_field, None)
        if val is not None:
            values[column] = val
    if payload.stage is None:
        values["stage"] = 0
    if payload.initial_leaf_count is None:
        values["initial_leaf_count"] = 0

    columns = ", ".join(values.keys())
    placeholders = ", ".join(["%s"] * len(values))
    with get_pool().connection() as conn:
        conn.execute(
            f"INSERT INTO plants ({columns}) VALUES ({placeholders})",
            tuple(values.values()),
        )
        row = conn.execute(
            "SELECT id, genus, species, cultivar, trading_name, plant_family, "
            "nickname, stage, variegation, watering_frequency, "
            "fertilizing_frequency_days, initial_leaf_count, last_watered_at, "
            "last_fertilized_at, last_repotted_at, created_at "
            "FROM plants WHERE id = %s",
            (plant_id,),
        ).fetchone()
    return _row_to_plant(row)


@router.get("/{plant_id}", response_model=PlantOut)
def get_plant(plant_id: str, user_id: str = Depends(get_current_user_id)):
    with get_pool().connection() as conn:
        row = conn.execute(
            "SELECT id, genus, species, cultivar, trading_name, plant_family, "
            "nickname, stage, variegation, watering_frequency, "
            "fertilizing_frequency_days, initial_leaf_count, last_watered_at, "
            "last_fertilized_at, last_repotted_at, created_at "
            "FROM plants WHERE id = %s AND user_id = %s",
            (plant_id, user_id),
        ).fetchone()
        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Plant not found",
            )
        photos = conn.execute(
            "SELECT id, plant_id, image_url, image_thumb_url, added_at, "
            "is_legacy FROM plant_photos "
            "WHERE plant_id = %s ORDER BY added_at DESC",
            (plant_id,),
        ).fetchall()
    plant = _row_to_plant(row)
    plant.photos = [
        PlantPhotoOut(**p) for p in photos
    ]
    return plant


@router.patch("/{plant_id}", response_model=PlantOut)
def update_plant(
    plant_id: str,
    payload: PlantUpdate,
    user_id: str = Depends(get_current_user_id),
):
    data = payload.model_dump(exclude_unset=True)
    fields = []
    values = []
    for key, val in data.items():
        if key in _FIELDS:
            fields.append(f"{_FIELDS[key]} = %s")
            values.append(val)
        elif key in ("last_watered_at", "last_fertilized_at", "last_repotted_at"):
            fields.append(f"{key} = %s")
            values.append(val)

    with get_pool().connection() as conn:
        existing = conn.execute(
            "SELECT id FROM plants WHERE id = %s AND user_id = %s",
            (plant_id, user_id),
        ).fetchone()
        if not existing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Plant not found",
            )

        if fields:
            values.extend([plant_id, user_id])
            conn.execute(
                f"UPDATE plants SET {', '.join(fields)} WHERE id = %s AND user_id = %s",
                tuple(values),
            )

        row = conn.execute(
            "SELECT id, genus, species, cultivar, trading_name, plant_family, "
            "nickname, stage, variegation, watering_frequency, "
            "fertilizing_frequency_days, initial_leaf_count, last_watered_at, "
            "last_fertilized_at, last_repotted_at, created_at "
            "FROM plants WHERE id = %s",
            (plant_id,),
        ).fetchone()
        photos = conn.execute(
            "SELECT id, plant_id, image_url, image_thumb_url, added_at, "
            "is_legacy FROM plant_photos "
            "WHERE plant_id = %s ORDER BY added_at DESC",
            (plant_id,),
        ).fetchall()

    plant = _row_to_plant(row)
    plant.photos = [
        PlantPhotoOut(**p) for p in photos
    ]
    return plant


@router.delete("/{plant_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_plant(plant_id: str, user_id: str = Depends(get_current_user_id)):
    with get_pool().connection() as conn:
        res = conn.execute(
            "DELETE FROM plants WHERE id = %s AND user_id = %s",
            (plant_id, user_id),
        )
        if res.rowcount == 0:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Plant not found",
            )


def _row_to_plant(row) -> PlantOut:
    return PlantOut(
        id=row["id"],
        genus=row["genus"],
        species=row["species"],
        cultivar=row["cultivar"],
        trading_name=row["trading_name"],
        plant_family=row["plant_family"],
        nickname=row["nickname"],
        stage=row["stage"],
        variegation=row["variegation"],
        watering_frequency=row["watering_frequency"],
        fertilizing_frequency_days=row["fertilizing_frequency_days"],
        initial_leaf_count=row["initial_leaf_count"],
        last_watered_at=row["last_watered_at"],
        last_fertilized_at=row["last_fertilized_at"],
        last_repotted_at=row["last_repotted_at"],
        created_at=row["created_at"],
    )
