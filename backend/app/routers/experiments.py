"""Experiment endpoints: comparative trials with variants, subjects, logs.

An experiment is a named trial ("Кокос vs грунт") whose variants differ by the
user's own free-text description. Variants hold subjects (a plant or a
propagation batch) and every subject carries its own observation log. This
router owns the whole nested tree — no other feature may attach to it.
"""
import os
import uuid
from typing import Any

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status

from ..config import settings
from ..db import get_pool
from ..feature_flags import FLAG_EXPERIMENTS, require_feature
from ..schemas import (
    _SUBJECT_TYPES,
    ExperimentCreate,
    ExperimentObservationCreate,
    ExperimentObservationOut,
    ExperimentOut,
    ExperimentSubjectIn,
    ExperimentSubjectOut,
    ExperimentUpdate,
    ExperimentVariantCreate,
    ExperimentVariantOut,
    ExperimentVariantUpdate,
)

router = APIRouter(tags=["experiments"])

_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".gif"}


def _new_id() -> str:
    return uuid.uuid4().hex


def _ensure_exp(conn, experiment_id: str, user_id: str) -> None:
    row = conn.execute(
        "SELECT id FROM experiments WHERE id = %s AND user_id = %s",
        (experiment_id, user_id),
    ).fetchone()
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail="Experiment not found")


def _ensure_variant(conn, variant_id: str, user_id: str) -> str:
    """Verify the variant belongs to the caller; return its experiment id."""
    row = conn.execute(
        "SELECT v.experiment_id AS experiment_id "
        "FROM experiment_variants v JOIN experiments e "
        "ON e.id = v.experiment_id "
        "WHERE v.id = %s AND e.user_id = %s",
        (variant_id, user_id),
    ).fetchone()
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail="Variant not found")
    return row["experiment_id"]


def _ensure_subject(conn, subject_id: str, user_id: str) -> str:
    """Verify the subject belongs to the caller; return its variant id."""
    row = conn.execute(
        "SELECT s.variant_id AS variant_id "
        "FROM experiment_subjects s "
        "JOIN experiment_variants v ON v.id = s.variant_id "
        "JOIN experiments e ON e.id = v.experiment_id "
        "WHERE s.id = %s AND e.user_id = %s",
        (subject_id, user_id),
    ).fetchone()
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail="Subject not found")
    return row["variant_id"]


def _insert_subjects(conn, variant_id: str, subjects: list[ExperimentSubjectIn]) -> None:
    for subject in subjects:
        if subject.subject_type not in _SUBJECT_TYPES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported subject type: {subject.subject_type}",
            )
        conn.execute(
            "INSERT INTO experiment_subjects (id, variant_id, subject_type, "
            "subject_id, subject_name) VALUES (%s, %s, %s, %s, %s)",
            (_new_id(), variant_id, subject.subject_type,
             subject.subject_id, subject.subject_name),
        )


def _load_experiments(
    conn, user_id: str, experiment_id: str | None = None
) -> list[ExperimentOut]:
    """Load the full nested tree for the caller in four flat queries.

    Nested resources are fetched with `= ANY(...)` + Python grouping instead of
    one query per variant / subject, so a large board still loads in constant
    round-trips.
    """
    where = "WHERE user_id = %s"
    params: list[Any] = [user_id]
    if experiment_id is not None:
        where += " AND id = %s"
        params.append(experiment_id)
    exp_rows = conn.execute(
        "SELECT id, title, hypothesis, note, started_at, conclusion, "
        "completed_at, archived_at, created_at FROM experiments "
        f"{where} ORDER BY created_at DESC",
        tuple(params),
    ).fetchall()
    if not exp_rows:
        return []
    exp_ids = [r["id"] for r in exp_rows]

    variant_rows = conn.execute(
        "SELECT id, experiment_id, label, description, position, created_at "
        "FROM experiment_variants WHERE experiment_id = ANY(%s) "
        "ORDER BY position, created_at",
        (exp_ids,),
    ).fetchall()
    variant_ids = [r["id"] for r in variant_rows]

    subject_rows = []
    observation_rows = []
    if variant_ids:
        subject_rows = conn.execute(
            "SELECT id, variant_id, subject_type, subject_id, subject_name, "
            "created_at FROM experiment_subjects "
            "WHERE variant_id = ANY(%s) ORDER BY created_at",
            (variant_ids,),
        ).fetchall()
    subject_ids = [r["id"] for r in subject_rows]
    if subject_ids:
        observation_rows = conn.execute(
            "SELECT id, subject_id, observed_at, note, image_url, height_cm, "
            "leaf_count, moisture, created_at FROM experiment_observations "
            "WHERE subject_id = ANY(%s) ORDER BY observed_at",
            (subject_ids,),
        ).fetchall()

    observations_by_subject: dict[str, list[dict]] = {}
    for row in observation_rows:
        observations_by_subject.setdefault(row["subject_id"], []).append(dict(row))

    subjects_by_variant: dict[str, list[dict]] = {}
    for row in subject_rows:
        subjects_by_variant.setdefault(row["variant_id"], []).append(dict(row))

    variants_by_exp: dict[str, list[ExperimentVariantOut]] = {}
    for row in variant_rows:
        subjects = subjects_by_variant.get(row["id"], [])
        observations: list[dict] = []
        for subject in subjects:
            observations.extend(observations_by_subject.get(subject["id"], []))
        observations.sort(key=lambda o: o["observed_at"])
        latest = observations[-1]["observed_at"] if observations else None
        variant = ExperimentVariantOut(
            id=row["id"],
            label=row["label"],
            description=row["description"],
            position=row["position"],
            subjects=[ExperimentSubjectOut(**s) for s in subjects],
            observations=[ExperimentObservationOut(**o) for o in observations],
            observation_count=len(observations),
            latest_observed_at=latest,
        )
        variants_by_exp.setdefault(row["experiment_id"], []).append(variant)

    result: list[ExperimentOut] = []
    for row in exp_rows:
        result.append(ExperimentOut(
            id=row["id"],
            title=row["title"],
            hypothesis=row["hypothesis"],
            note=row["note"],
            started_at=row["started_at"],
            conclusion=row["conclusion"],
            completed_at=row["completed_at"],
            archived_at=row["archived_at"],
            variants=variants_by_exp.get(row["id"], []),
            created_at=row["created_at"],
        ))
    return result


def _get_experiment(conn, user_id: str, experiment_id: str) -> ExperimentOut:
    items = _load_experiments(conn, user_id, experiment_id)
    if not items:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail="Experiment not found")
    return items[0]


# ---- Experiments ----
@router.get("/experiments", response_model=list[ExperimentOut])
def list_experiments(
    user_id: str = Depends(require_feature(FLAG_EXPERIMENTS)),
):
    with get_pool().connection() as conn:
        return _load_experiments(conn, user_id)


@router.post("/experiments", response_model=ExperimentOut, status_code=201)
def create_experiment(
    payload: ExperimentCreate,
    user_id: str = Depends(require_feature(FLAG_EXPERIMENTS)),
):
    title = (payload.title or "").strip()
    if not title:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                            detail="Title must not be empty")
    exp_id = _new_id()
    with get_pool().connection() as conn:
        conn.execute(
            "INSERT INTO experiments (id, user_id, title, hypothesis, note, "
            "started_at, conclusion, completed_at) "
            "VALUES (%s, %s, %s, %s, %s, COALESCE(%s, now()), %s, %s)",
            (exp_id, user_id, title, payload.hypothesis, payload.note,
             payload.started_at, payload.conclusion, payload.completed_at),
        )
        for index, variant in enumerate(payload.variants):
            variant_id = _new_id()
            conn.execute(
                "INSERT INTO experiment_variants (id, experiment_id, label, "
                "description, position) VALUES (%s, %s, %s, %s, %s)",
                (variant_id, exp_id, (variant.label or "").strip(),
                 variant.description,
                 variant.position if variant.position is not None else index),
            )
            _insert_subjects(conn, variant_id, variant.subjects)
        return _get_experiment(conn, user_id, exp_id)


@router.patch("/experiments/{experiment_id}", response_model=ExperimentOut)
def update_experiment(
    experiment_id: str,
    payload: ExperimentUpdate,
    user_id: str = Depends(require_feature(FLAG_EXPERIMENTS)),
):
    data = payload.model_dump(exclude_unset=True)
    fields = []
    values: list[Any] = []
    for key in ("title", "hypothesis", "note", "started_at", "conclusion",
                "completed_at", "archived_at"):
        if key in data:
            fields.append(f"{key} = %s")
            values.append(data[key])
    with get_pool().connection() as conn:
        _ensure_exp(conn, experiment_id, user_id)
        if fields:
            values.extend([experiment_id, user_id])
            conn.execute(
                f"UPDATE experiments SET {', '.join(fields)} "
                "WHERE id = %s AND user_id = %s",
                tuple(values),
            )
        return _get_experiment(conn, user_id, experiment_id)


@router.delete("/experiments/{experiment_id}", status_code=204)
def delete_experiment(
    experiment_id: str,
    user_id: str = Depends(require_feature(FLAG_EXPERIMENTS)),
):
    with get_pool().connection() as conn:
        _ensure_exp(conn, experiment_id, user_id)
        conn.execute("DELETE FROM experiments WHERE id = %s", (experiment_id,))


# ---- Variants ----
@router.post("/experiments/{experiment_id}/variants",
             response_model=ExperimentVariantOut, status_code=201)
def add_variant(
    experiment_id: str,
    payload: ExperimentVariantCreate,
    user_id: str = Depends(require_feature(FLAG_EXPERIMENTS)),
):
    label = (payload.label or "").strip()
    if not label:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                            detail="Variant label must not be empty")
    variant_id = _new_id()
    with get_pool().connection() as conn:
        _ensure_exp(conn, experiment_id, user_id)
        position = payload.position
        if position is None:
            row = conn.execute(
                "SELECT COALESCE(MAX(position), -1) + 1 AS next_position "
                "FROM experiment_variants WHERE experiment_id = %s",
                (experiment_id,),
            ).fetchone()
            position = row["next_position"]
        conn.execute(
            "INSERT INTO experiment_variants (id, experiment_id, label, "
            "description, position) VALUES (%s, %s, %s, %s, %s)",
            (variant_id, experiment_id, label, payload.description, position),
        )
        _insert_subjects(conn, variant_id, payload.subjects)
        row = conn.execute(
            "SELECT id, experiment_id, label, description, position "
            "FROM experiment_variants WHERE id = %s",
            (variant_id,),
        ).fetchone()
    return ExperimentVariantOut(
        id=row["id"], label=row["label"], description=row["description"],
        position=row["position"],
        subjects=[
            ExperimentSubjectOut(**s) for s in _variant_subjects(
                experiment_id, variant_id)
        ],
    )


def _variant_subjects(experiment_id: str, variant_id: str) -> list[dict]:
    """Fetch a variant's subjects (used right after a write, fresh connection)."""
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, subject_type, subject_id, subject_name "
            "FROM experiment_subjects WHERE variant_id = %s ORDER BY created_at",
            (variant_id,),
        ).fetchall()
    return [dict(r) for r in rows]


@router.patch("/variants/{variant_id}", response_model=ExperimentVariantOut)
def update_variant(
    variant_id: str,
    payload: ExperimentVariantUpdate,
    user_id: str = Depends(require_feature(FLAG_EXPERIMENTS)),
):
    data = payload.model_dump(exclude_unset=True)
    fields = []
    values: list[Any] = []
    for key in ("label", "description", "position"):
        if key in data:
            fields.append(f"{key} = %s")
            values.append(data[key])
    with get_pool().connection() as conn:
        _ensure_variant(conn, variant_id, user_id)
        if fields:
            values.append(variant_id)
            conn.execute(
                f"UPDATE experiment_variants SET {', '.join(fields)} "
                "WHERE id = %s",
                tuple(values),
            )
        row = conn.execute(
            "SELECT id, label, description, position FROM experiment_variants "
            "WHERE id = %s",
            (variant_id,),
        ).fetchone()
        subjects = conn.execute(
            "SELECT id, subject_type, subject_id, subject_name "
            "FROM experiment_subjects WHERE variant_id = %s ORDER BY created_at",
            (variant_id,),
        ).fetchall()
    return ExperimentVariantOut(
        id=row["id"], label=row["label"], description=row["description"],
        position=row["position"],
        subjects=[ExperimentSubjectOut(**dict(s)) for s in subjects],
    )


@router.delete("/variants/{variant_id}", status_code=204)
def delete_variant(
    variant_id: str,
    user_id: str = Depends(require_feature(FLAG_EXPERIMENTS)),
):
    with get_pool().connection() as conn:
        _ensure_variant(conn, variant_id, user_id)
        conn.execute("DELETE FROM experiment_variants WHERE id = %s", (variant_id,))


# ---- Subjects ----
@router.post("/variants/{variant_id}/subjects",
             response_model=ExperimentSubjectOut, status_code=201)
def add_subject(
    variant_id: str,
    payload: ExperimentSubjectIn,
    user_id: str = Depends(require_feature(FLAG_EXPERIMENTS)),
):
    if payload.subject_type not in _SUBJECT_TYPES:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                            detail=f"Unsupported subject type: {payload.subject_type}")
    subject_id = _new_id()
    with get_pool().connection() as conn:
        _ensure_variant(conn, variant_id, user_id)
        conn.execute(
            "INSERT INTO experiment_subjects (id, variant_id, subject_type, "
            "subject_id, subject_name) VALUES (%s, %s, %s, %s, %s)",
            (subject_id, variant_id, payload.subject_type, payload.subject_id,
             payload.subject_name),
        )
        row = conn.execute(
            "SELECT id, subject_type, subject_id, subject_name "
            "FROM experiment_subjects WHERE id = %s",
            (subject_id,),
        ).fetchone()
    return ExperimentSubjectOut(**dict(row))


@router.delete("/subjects/{subject_id}", status_code=204)
def delete_subject(
    subject_id: str,
    user_id: str = Depends(require_feature(FLAG_EXPERIMENTS)),
):
    with get_pool().connection() as conn:
        _ensure_subject(conn, subject_id, user_id)
        conn.execute("DELETE FROM experiment_subjects WHERE id = %s", (subject_id,))


# ---- Observations ----
@router.get("/subjects/{subject_id}/observations",
            response_model=list[ExperimentObservationOut])
def list_observations(
    subject_id: str,
    user_id: str = Depends(require_feature(FLAG_EXPERIMENTS)),
):
    with get_pool().connection() as conn:
        _ensure_subject(conn, subject_id, user_id)
        rows = conn.execute(
            "SELECT id, subject_id, observed_at, note, image_url, height_cm, "
            "leaf_count, moisture, created_at FROM experiment_observations "
            "WHERE subject_id = %s ORDER BY observed_at",
            (subject_id,),
        ).fetchall()
    return [ExperimentObservationOut(**r) for r in rows]


@router.post("/subjects/{subject_id}/observations",
             response_model=ExperimentObservationOut, status_code=201)
def add_observation(
    subject_id: str,
    payload: ExperimentObservationCreate,
    user_id: str = Depends(require_feature(FLAG_EXPERIMENTS)),
):
    observation_id = _new_id()
    with get_pool().connection() as conn:
        _ensure_subject(conn, subject_id, user_id)
        conn.execute(
            "INSERT INTO experiment_observations (id, subject_id, observed_at, "
            "note, image_url, height_cm, leaf_count, moisture) "
            "VALUES (%s, %s, COALESCE(%s, now()), %s, %s, %s, %s, %s)",
            (observation_id, subject_id, payload.observed_at, payload.note,
             payload.image_url, payload.height_cm, payload.leaf_count,
             payload.moisture),
        )
        row = conn.execute(
            "SELECT id, subject_id, observed_at, note, image_url, height_cm, "
            "leaf_count, moisture, created_at FROM experiment_observations "
            "WHERE id = %s",
            (observation_id,),
        ).fetchone()
    return ExperimentObservationOut(**row)


@router.delete("/observations/{observation_id}", status_code=204)
def delete_observation(
    observation_id: str,
    user_id: str = Depends(require_feature(FLAG_EXPERIMENTS)),
):
    with get_pool().connection() as conn:
        row = conn.execute(
            "SELECT o.id FROM experiment_observations o "
            "JOIN experiment_subjects s ON s.id = o.subject_id "
            "JOIN experiment_variants v ON v.id = s.variant_id "
            "JOIN experiments e ON e.id = v.experiment_id "
            "WHERE o.id = %s AND e.user_id = %s",
            (observation_id, user_id),
        ).fetchone()
        if row is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                                detail="Observation not found")
        conn.execute("DELETE FROM experiment_observations WHERE id = %s",
                     (observation_id,))


# ---- Observation photo upload ----
@router.post("/subjects/{subject_id}/observations/upload")
def upload_observation_photo(
    subject_id: str,
    file: UploadFile = File(...),
    user_id: str = Depends(require_feature(FLAG_EXPERIMENTS)),
):
    """Store an observation photo and return its URL.

    Only the file is written here; the caller then creates the observation row
    via POST /subjects/{id}/observations with this `image_url`, matching the
    plant-photo flow (one upload → one log entry).
    """
    with get_pool().connection() as conn:
        variant_id = _ensure_subject(conn, subject_id, user_id)
        row = conn.execute(
            "SELECT experiment_id FROM experiment_variants WHERE id = %s",
            (variant_id,),
        ).fetchone()
    experiment_id = row["experiment_id"]
    photo_id = _new_id()
    ext = os.path.splitext(file.filename or "")[1] or ".jpg"
    if ext.lower() not in _IMAGE_EXTENSIONS:
        raise HTTPException(status_code=400, detail="Unsupported image type")
    exp_dir = os.path.join(settings.photos_dir, "experiments", experiment_id)
    os.makedirs(exp_dir, exist_ok=True)
    filename = f"{photo_id}{ext}"
    dest = os.path.join(exp_dir, filename)
    with open(dest, "wb") as out:
        while True:
            chunk = file.file.read(1024 * 1024)
            if not chunk:
                break
            out.write(chunk)
    image_url = (f"{settings.public_base_url}/photos/experiments/"
                 f"{experiment_id}/{filename}")
    return {"image_url": image_url}
