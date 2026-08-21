"""Nested plant resources: photos, notes, growth, care, manipulations."""
import os
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status

from ..config import settings
from ..db import get_pool, jsonb
from ..routers.auth import get_current_user_id
from ..schemas import (
    FertilizingCreate,
    FertilizingOut,
    GrowthEventCreate,
    GrowthEventOut,
    ManipulationCreate,
    ManipulationOut,
    ManipulationUpdate,
    PlantNoteCreate,
    PlantNoteOut,
    PlantPhotoCreate,
    PlantPhotoOut,
    RepottingCreate,
    RepottingOut,
    WateringCreate,
    WateringOut,
)

router = APIRouter(prefix="/plants/{plant_id}", tags=["plant-resources"])


def _ensure_owned(plant_id: str, user_id: str) -> None:
    """Raise 404 unless the plant exists and belongs to the user."""
    with get_pool().connection() as conn:
        row = conn.execute(
            "SELECT id FROM plants WHERE id = %s AND user_id = %s",
            (plant_id, user_id),
        ).fetchone()
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail="Plant not found")


# ---- Photos ----
@router.get("/photos", response_model=list[PlantPhotoOut])
def list_photos(plant_id: str, user_id: str = Depends(get_current_user_id)):
    _ensure_owned(plant_id, user_id)
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, plant_id, image_url, image_thumb_url, added_at, "
            "is_legacy FROM plant_photos WHERE plant_id = %s ORDER BY added_at",
            (plant_id,),
        ).fetchall()
    return [PlantPhotoOut(**r) for r in rows]


@router.post("/photos/upload", response_model=PlantPhotoOut, status_code=201)
def upload_photo(plant_id: str, file: UploadFile = File(...),
                 user_id: str = Depends(get_current_user_id)):
    """Save an uploaded photo file to disk and return its URLs.

    This endpoint only stores the file and returns a stable URL. The caller
    (frontend) then creates the `plant_photos` row via POST /photos, so one
    upload maps to exactly one gallery entry and the gallery cap is respected.
    """
    _ensure_owned(plant_id, user_id)
    photo_id = uuid.uuid4().hex
    ext = os.path.splitext(file.filename or "")[1] or ".jpg"
    if ext.lower() not in {".jpg", ".jpeg", ".png", ".webp", ".gif"}:
        raise HTTPException(status_code=400, detail="Unsupported image type")
    # Per-plant folder to avoid one huge directory.
    plant_dir = os.path.join(settings.photos_dir, plant_id)
    os.makedirs(plant_dir, exist_ok=True)
    filename = f"{photo_id}{ext}"
    dest = os.path.join(plant_dir, filename)
    with open(dest, "wb") as out:
        while True:
            chunk = file.file.read(1024 * 1024)
            if not chunk:
                break
            out.write(chunk)
    image_url = f"{settings.public_base_url}/photos/{plant_id}/{filename}"
    return PlantPhotoOut(
        id=photo_id,
        plant_id=plant_id,
        image_url=image_url,
        image_thumb_url=image_url,
        added_at=datetime.now(timezone.utc),
        is_legacy=False,
    )


@router.post("/photos", response_model=PlantPhotoOut, status_code=201)
def add_photo(plant_id: str, payload: PlantPhotoCreate,
              user_id: str = Depends(get_current_user_id)):
    _ensure_owned(plant_id, user_id)
    photo_id = uuid.uuid4().hex
    with get_pool().connection() as conn:
        if not payload.is_legacy:
            # A real gallery photo supersedes any legacy cover (dead Firebase
            # URL placeholder) — drop it so it doesn't show as a 2nd photo.
            conn.execute(
                "DELETE FROM plant_photos WHERE plant_id = %s AND is_legacy",
                (plant_id,),
            )
        conn.execute(
            "INSERT INTO plant_photos (id, plant_id, image_url, "
            "image_thumb_url, is_legacy) VALUES (%s, %s, %s, %s, %s)",
            (photo_id, plant_id, payload.image_url,
             payload.image_thumb_url, payload.is_legacy),
        )
        row = conn.execute(
            "SELECT id, plant_id, image_url, image_thumb_url, added_at, "
            "is_legacy FROM plant_photos WHERE id = %s",
            (photo_id,),
        ).fetchone()
    return PlantPhotoOut(**row)


@router.delete("/photos/{photo_id}", status_code=204)
def delete_photo(plant_id: str, photo_id: str,
                 user_id: str = Depends(get_current_user_id)):
    _ensure_owned(plant_id, user_id)
    with get_pool().connection() as conn:
        conn.execute(
            "DELETE FROM plant_photos WHERE id = %s AND plant_id = %s",
            (photo_id, plant_id),
        )


# ---- Notes ----
@router.get("/notes", response_model=list[PlantNoteOut])
def list_notes(plant_id: str, user_id: str = Depends(get_current_user_id)):
    _ensure_owned(plant_id, user_id)
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, plant_id, text, created_at, updated_at, expires_at "
            "FROM plant_notes WHERE plant_id = %s ORDER BY created_at",
            (plant_id,),
        ).fetchall()
    return [PlantNoteOut(**r) for r in rows]


@router.post("/notes", response_model=PlantNoteOut, status_code=201)
def add_note(plant_id: str, payload: PlantNoteCreate,
             user_id: str = Depends(get_current_user_id)):
    _ensure_owned(plant_id, user_id)
    note_id = uuid.uuid4().hex
    with get_pool().connection() as conn:
        conn.execute(
            "INSERT INTO plant_notes (id, plant_id, text, expires_at) "
            "VALUES (%s, %s, %s, %s)",
            (note_id, plant_id, payload.text, payload.expires_at),
        )
        row = conn.execute(
            "SELECT id, plant_id, text, created_at, updated_at, expires_at "
            "FROM plant_notes WHERE id = %s",
            (note_id,),
        ).fetchone()
    return PlantNoteOut(**row)


@router.delete("/notes/{note_id}", status_code=204)
def delete_note(plant_id: str, note_id: str,
                user_id: str = Depends(get_current_user_id)):
    _ensure_owned(plant_id, user_id)
    with get_pool().connection() as conn:
        conn.execute(
            "DELETE FROM plant_notes WHERE id = %s AND plant_id = %s",
            (note_id, plant_id),
        )


# ---- Growth events ----
@router.get("/growth-events", response_model=list[GrowthEventOut])
def list_growth(plant_id: str, user_id: str = Depends(get_current_user_id)):
    _ensure_owned(plant_id, user_id)
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, plant_id, type, created_at, expires_at "
            "FROM plant_growth_events WHERE plant_id = %s ORDER BY created_at",
            (plant_id,),
        ).fetchall()
    return [GrowthEventOut(**r) for r in rows]


@router.post("/growth-events", response_model=GrowthEventOut, status_code=201)
def add_growth(plant_id: str, payload: GrowthEventCreate,
               user_id: str = Depends(get_current_user_id)):
    _ensure_owned(plant_id, user_id)
    event_id = uuid.uuid4().hex
    with get_pool().connection() as conn:
        conn.execute(
            "INSERT INTO plant_growth_events (id, plant_id, type, expires_at) "
            "VALUES (%s, %s, %s, %s)",
            (event_id, plant_id, payload.type, payload.expires_at),
        )
        row = conn.execute(
            "SELECT id, plant_id, type, created_at, expires_at "
            "FROM plant_growth_events WHERE id = %s",
            (event_id,),
        ).fetchone()
    return GrowthEventOut(**row)


# ---- Watering ----
@router.get("/waterings", response_model=list[WateringOut])
def list_waterings(plant_id: str, user_id: str = Depends(get_current_user_id)):
    _ensure_owned(plant_id, user_id)
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, plant_id, watered_at, next_watering, created_at "
            "FROM plant_waterings WHERE plant_id = %s ORDER BY watered_at",
            (plant_id,),
        ).fetchall()
    return [WateringOut(**r) for r in rows]


@router.post("/waterings", response_model=WateringOut, status_code=201)
def add_watering(plant_id: str, payload: WateringCreate,
                 user_id: str = Depends(get_current_user_id)):
    _ensure_owned(plant_id, user_id)
    w_id = uuid.uuid4().hex
    with get_pool().connection() as conn:
        conn.execute(
            "INSERT INTO plant_waterings (id, plant_id, watered_at, "
            "next_watering) VALUES (%s, %s, %s, %s)",
            (w_id, plant_id, payload.watered_at, payload.next_watering),
        )
        conn.execute(
            "UPDATE plants SET last_watered_at = %s WHERE id = %s",
            (payload.watered_at, plant_id),
        )
        row = conn.execute(
            "SELECT id, plant_id, watered_at, next_watering, created_at "
            "FROM plant_waterings WHERE id = %s",
            (w_id,),
        ).fetchone()
    return WateringOut(**row)


# ---- Fertilizing ----
@router.get("/fertilizings", response_model=list[FertilizingOut])
def list_fertilizings(plant_id: str, user_id: str = Depends(get_current_user_id)):
    _ensure_owned(plant_id, user_id)
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, plant_id, fertilizer_id, fertilizer_name, "
            "application_method, components, water_ml, applied_at, "
            "next_fertilizing, created_at FROM plant_fertilizings "
            "WHERE plant_id = %s ORDER BY applied_at",
            (plant_id,),
        ).fetchall()
    return [FertilizingOut(**r) for r in rows]


@router.post("/fertilizings", response_model=FertilizingOut, status_code=201)
def add_fertilizing(plant_id: str, payload: FertilizingCreate,
                    user_id: str = Depends(get_current_user_id)):
    _ensure_owned(plant_id, user_id)
    f_id = uuid.uuid4().hex
    with get_pool().connection() as conn:
        conn.execute(
            "INSERT INTO plant_fertilizings (id, plant_id, fertilizer_id, "
            "fertilizer_name, application_method, components, water_ml, "
            "applied_at, next_fertilizing) VALUES (%s, %s, %s, %s, %s, %s, "
            "%s, %s, %s)",
            (f_id, plant_id, payload.fertilizer_id, payload.fertilizer_name,
             payload.application_method,
             jsonb(payload.components),
             payload.water_ml, payload.applied_at, payload.next_fertilizing),
        )
        conn.execute(
            "UPDATE plants SET last_fertilized_at = %s WHERE id = %s",
            (payload.applied_at, plant_id),
        )
        row = conn.execute(
            "SELECT id, plant_id, fertilizer_id, fertilizer_name, "
            "application_method, components, water_ml, applied_at, "
            "next_fertilizing, created_at FROM plant_fertilizings WHERE id=%s",
            (f_id,),
        ).fetchone()
    return FertilizingOut(**row)


# ---- Repotting ----
@router.get("/repottings", response_model=list[RepottingOut])
def list_repottings(plant_id: str, user_id: str = Depends(get_current_user_id)):
    _ensure_owned(plant_id, user_id)
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, plant_id, soil_id, soil_name, components, "
            "slow_release_fertilizer, repotted_at, created_at "
            "FROM plant_repottings WHERE plant_id = %s ORDER BY repotted_at",
            (plant_id,),
        ).fetchall()
    return [RepottingOut(**r) for r in rows]


@router.post("/repottings", response_model=RepottingOut, status_code=201)
def add_repotting(plant_id: str, payload: RepottingCreate,
                  user_id: str = Depends(get_current_user_id)):
    _ensure_owned(plant_id, user_id)
    r_id = uuid.uuid4().hex
    with get_pool().connection() as conn:
        conn.execute(
            "INSERT INTO plant_repottings (id, plant_id, soil_id, soil_name, "
            "components, slow_release_fertilizer, repotted_at) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s)",
            (r_id, plant_id, payload.soil_id, payload.soil_name,
             jsonb(payload.components),
             payload.slow_release_fertilizer, payload.repotted_at),
        )
        conn.execute(
            "UPDATE plants SET last_repotted_at = %s WHERE id = %s",
            (payload.repotted_at, plant_id),
        )
        row = conn.execute(
            "SELECT id, plant_id, soil_id, soil_name, components, "
            "slow_release_fertilizer, repotted_at, created_at "
            "FROM plant_repottings WHERE id = %s",
            (r_id,),
        ).fetchone()
    return RepottingOut(**row)


# ---- Manipulations ----
@router.get("/manipulations", response_model=list[ManipulationOut])
def list_manipulations(plant_id: str,
                       user_id: str = Depends(get_current_user_id)):
    _ensure_owned(plant_id, user_id)
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, plant_id, type, applied_at, ended_at, reanimation_tags, "
            "is_greenhouse, note, stage_before, stage_after, stimulator_id, "
            "stimulator_name, dosage, created_at "
            "FROM plant_manipulations WHERE plant_id = %s ORDER BY applied_at DESC",
            (plant_id,),
        ).fetchall()
    return [ManipulationOut(**r) for r in rows]


@router.post("/manipulations", response_model=ManipulationOut, status_code=201)
def add_manipulation(plant_id: str, payload: ManipulationCreate,
                     user_id: str = Depends(get_current_user_id)):
    _ensure_owned(plant_id, user_id)
    m_id = uuid.uuid4().hex
    with get_pool().connection() as conn:
        conn.execute(
            "INSERT INTO plant_manipulations (id, plant_id, type, applied_at, "
            "ended_at, reanimation_tags, is_greenhouse, note, stage_before, "
            "stage_after, stimulator_id, stimulator_name, dosage) VALUES (%s, %s, %s, %s, %s, %s, "
            "%s, %s, %s, %s, %s, %s, %s)",
            (m_id, plant_id, payload.type, payload.applied_at, payload.ended_at,
             jsonb(payload.reanimation_tags), payload.is_greenhouse, payload.note,
             payload.stage_before, payload.stage_after, payload.stimulator_id,
             payload.stimulator_name, payload.dosage),
        )
        conn.execute(
            "UPDATE plants SET last_manipulation_at = %s WHERE id = %s",
            (payload.applied_at, plant_id),
        )
        row = conn.execute(
            "SELECT id, plant_id, type, applied_at, ended_at, reanimation_tags, "
            "is_greenhouse, note, stage_before, stage_after, stimulator_id, "
            "stimulator_name, dosage, created_at "
            "FROM plant_manipulations WHERE id = %s",
            (m_id,),
        ).fetchone()
    return ManipulationOut(**row)


@router.patch("/manipulations/{manipulation_id}", response_model=ManipulationOut)
def update_manipulation(
    plant_id: str,
    manipulation_id: str,
    payload: ManipulationUpdate,
    user_id: str = Depends(get_current_user_id),
):
    _ensure_owned(plant_id, user_id)
    data = payload.model_dump(exclude_unset=True)
    fields = []
    values = []
    for key, val in data.items():
        fields.append(f"{key} = %s")
        if key == "reanimation_tags":
            values.append(jsonb(val))
        else:
            values.append(val)

    with get_pool().connection() as conn:
        existing = conn.execute(
            "SELECT id FROM plant_manipulations WHERE id = %s AND plant_id = %s",
            (manipulation_id, plant_id),
        ).fetchone()
        if not existing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Manipulation not found",
            )
        if fields:
            values.extend([manipulation_id, plant_id])
            conn.execute(
                f"UPDATE plant_manipulations SET {', '.join(fields)} WHERE id = %s AND plant_id = %s",
                tuple(values),
            )
            conn.execute(
                "UPDATE plants SET last_manipulation_at = (SELECT MAX(applied_at) FROM plant_manipulations WHERE plant_id = %s) WHERE id = %s",
                (plant_id, plant_id),
            )
        row = conn.execute(
            "SELECT id, plant_id, type, applied_at, ended_at, reanimation_tags, "
            "is_greenhouse, note, stage_before, stage_after, stimulator_id, "
            "stimulator_name, dosage, created_at "
            "FROM plant_manipulations WHERE id = %s",
            (manipulation_id,),
        ).fetchone()
    return ManipulationOut(**row)


@router.delete("/manipulations/{manipulation_id}", status_code=204)
def delete_manipulation(
    plant_id: str,
    manipulation_id: str,
    user_id: str = Depends(get_current_user_id),
):
    _ensure_owned(plant_id, user_id)
    with get_pool().connection() as conn:
        res = conn.execute(
            "DELETE FROM plant_manipulations WHERE id = %s AND plant_id = %s",
            (manipulation_id, plant_id),
        )
        if res.rowcount == 0:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Manipulation not found",
            )
        conn.execute(
            "UPDATE plants SET last_manipulation_at = (SELECT MAX(applied_at) FROM plant_manipulations WHERE plant_id = %s) WHERE id = %s",
            (plant_id, plant_id),
        )
