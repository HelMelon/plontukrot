"""Propagations endpoints (top-level + notes + stage history)."""
import uuid

from fastapi import APIRouter, Depends, HTTPException, status

from ..db import get_pool
from ..feature_flags import FLAG_PROPAGATIONS, require_feature
from ..schemas import (
    PropagationCreate,
    PropagationNoteCreate,
    PropagationNoteOut,
    PropagationNoteUpdate,
    PropagationOut,
    StageHistoryCreate,
    StageHistoryOut,
)

router = APIRouter(prefix="/propagations", tags=["propagations"])


def _ensure_prop(conn, prop_id: str, user_id: str) -> None:
    row = conn.execute(
        "SELECT id FROM propagations WHERE id = %s AND user_id = %s",
        (prop_id, user_id),
    ).fetchone()
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail="Propagation not found")


@router.get("", response_model=list[PropagationOut])
def list_propagations(user_id: str = Depends(require_feature(FLAG_PROPAGATIONS))):
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, parent_plant_id, parent_plant_name, "
            "parent_plant_family, method, stage, status, quantity, "
            "quantity_alive, gifted_quantity, sold_quantity, traded_quantity, "
            "lost_quantity, started_at, sold_at, created_at "
            "FROM propagations WHERE user_id = %s ORDER BY created_at",
            (user_id,),
        ).fetchall()
    return [PropagationOut(**r) for r in rows]


@router.post("", response_model=PropagationOut, status_code=201)
def create_propagation(payload: PropagationCreate,
                       user_id: str = Depends(require_feature(FLAG_PROPAGATIONS))):
    prop_id = uuid.uuid4().hex
    with get_pool().connection() as conn:
        conn.execute(
            "INSERT INTO propagations (id, user_id, parent_plant_id, "
            "parent_plant_name, parent_plant_family, method, stage, status, "
            "quantity, quantity_alive, gifted_quantity, sold_quantity, "
            "traded_quantity, lost_quantity, started_at, sold_at) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, "
            "%s, %s, %s)",
            (prop_id, user_id, payload.parent_plant_id,
             payload.parent_plant_name, payload.parent_plant_family,
             payload.method, payload.stage, payload.status, payload.quantity,
             payload.quantity_alive, payload.gifted_quantity,
             payload.sold_quantity, payload.traded_quantity,
             payload.lost_quantity, payload.started_at, payload.sold_at),
        )
        row = conn.execute(
            "SELECT id, parent_plant_id, parent_plant_name, "
            "parent_plant_family, method, stage, status, quantity, "
            "quantity_alive, gifted_quantity, sold_quantity, traded_quantity, "
            "lost_quantity, started_at, sold_at, created_at "
            "FROM propagations WHERE id = %s",
            (prop_id,),
        ).fetchone()
    return PropagationOut(**row)


@router.patch("/{prop_id}", response_model=PropagationOut)
def update_propagation(prop_id: str, payload: PropagationCreate,
                       user_id: str = Depends(require_feature(FLAG_PROPAGATIONS))):
    with get_pool().connection() as conn:
        _ensure_prop(conn, prop_id, user_id)
        conn.execute(
            "UPDATE propagations SET parent_plant_id=%s, "
            "parent_plant_name=%s, parent_plant_family=%s, method=%s, "
            "stage=%s, status=%s, quantity=%s, quantity_alive=%s, "
            "gifted_quantity=%s, sold_quantity=%s, traded_quantity=%s, "
            "lost_quantity=%s, started_at=%s, sold_at=%s WHERE id=%s",
            (payload.parent_plant_id, payload.parent_plant_name,
             payload.parent_plant_family, payload.method, payload.stage,
             payload.status, payload.quantity, payload.quantity_alive,
             payload.gifted_quantity, payload.sold_quantity,
             payload.traded_quantity, payload.lost_quantity,
             payload.started_at, payload.sold_at, prop_id),
        )
        row = conn.execute(
            "SELECT id, parent_plant_id, parent_plant_name, "
            "parent_plant_family, method, stage, status, quantity, "
            "quantity_alive, gifted_quantity, sold_quantity, traded_quantity, "
            "lost_quantity, started_at, sold_at, created_at "
            "FROM propagations WHERE id = %s",
            (prop_id,),
        ).fetchone()
    return PropagationOut(**row)


@router.delete("/{prop_id}", status_code=204)
def delete_propagation(prop_id: str,
                       user_id: str = Depends(require_feature(FLAG_PROPAGATIONS))):
    with get_pool().connection() as conn:
        _ensure_prop(conn, prop_id, user_id)
        conn.execute("DELETE FROM propagations WHERE id = %s", (prop_id,))


# ---- Notes ----
@router.get("/{prop_id}/notes", response_model=list[PropagationNoteOut])
def list_prop_notes(prop_id: str, user_id: str = Depends(require_feature(FLAG_PROPAGATIONS))):
    with get_pool().connection() as conn:
        _ensure_prop(conn, prop_id, user_id)
        rows = conn.execute(
            "SELECT id, propagation_id, text, created_at, updated_at, "
            "expires_at FROM propagation_notes WHERE propagation_id = %s "
            "ORDER BY created_at",
            (prop_id,),
        ).fetchall()
    return [PropagationNoteOut(**r) for r in rows]


@router.post("/{prop_id}/notes", response_model=PropagationNoteOut, status_code=201)
def add_prop_note(
    prop_id: str,
    payload: PropagationNoteCreate,
    user_id: str = Depends(require_feature(FLAG_PROPAGATIONS)),
):
    text = (payload.text or "").strip()
    if not text:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Note text must not be empty",
        )
    note_id = uuid.uuid4().hex
    with get_pool().connection() as conn:
        _ensure_prop(conn, prop_id, user_id)
        conn.execute(
            "INSERT INTO propagation_notes (id, propagation_id, text, expires_at) "
            "VALUES (%s, %s, %s, %s)",
            (note_id, prop_id, text, payload.expires_at),
        )
        row = conn.execute(
            "SELECT id, propagation_id, text, created_at, updated_at, expires_at "
            "FROM propagation_notes WHERE id = %s",
            (note_id,),
        ).fetchone()
    return PropagationNoteOut(**row)


@router.patch("/{prop_id}/notes/{note_id}", response_model=PropagationNoteOut)
def update_prop_note(
    prop_id: str,
    note_id: str,
    payload: PropagationNoteUpdate,
    user_id: str = Depends(require_feature(FLAG_PROPAGATIONS)),
):
    with get_pool().connection() as conn:
        _ensure_prop(conn, prop_id, user_id)
        existing = conn.execute(
            "SELECT id FROM propagation_notes "
            "WHERE id = %s AND propagation_id = %s",
            (note_id, prop_id),
        ).fetchone()
        if existing is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Note not found",
            )

        if payload.text is not None:
            text = payload.text.strip()
            if not text:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Note text must not be empty",
                )
            conn.execute(
                "UPDATE propagation_notes SET text = %s, updated_at = now() "
                "WHERE id = %s AND propagation_id = %s",
                (text, note_id, prop_id),
            )
        if payload.expires_at is not None:
            conn.execute(
                "UPDATE propagation_notes SET expires_at = %s, updated_at = now() "
                "WHERE id = %s AND propagation_id = %s",
                (payload.expires_at, note_id, prop_id),
            )

        row = conn.execute(
            "SELECT id, propagation_id, text, created_at, updated_at, expires_at "
            "FROM propagation_notes WHERE id = %s",
            (note_id,),
        ).fetchone()
    return PropagationNoteOut(**row)


@router.delete("/{prop_id}/notes/{note_id}", status_code=204)
def delete_prop_note(
    prop_id: str,
    note_id: str,
    user_id: str = Depends(require_feature(FLAG_PROPAGATIONS)),
):
    with get_pool().connection() as conn:
        _ensure_prop(conn, prop_id, user_id)
        conn.execute(
            "DELETE FROM propagation_notes WHERE id = %s AND propagation_id = %s",
            (note_id, prop_id),
        )


# ---- Stage history ----
@router.get("/{prop_id}/stage-history", response_model=list[StageHistoryOut])
def list_stage_history(prop_id: str,
                       user_id: str = Depends(require_feature(FLAG_PROPAGATIONS))):
    with get_pool().connection() as conn:
        _ensure_prop(conn, prop_id, user_id)
        rows = conn.execute(
            "SELECT id, propagation_id, stage, quantity_alive, outcome, note, "
            "changed_at FROM propagation_stage_history WHERE propagation_id=%s "
            "ORDER BY changed_at",
            (prop_id,),
        ).fetchall()
    return [StageHistoryOut(**r) for r in rows]


@router.post("/{prop_id}/stage-history", response_model=StageHistoryOut,
             status_code=201)
def add_stage_history(prop_id: str, payload: StageHistoryCreate,
                      user_id: str = Depends(require_feature(FLAG_PROPAGATIONS))):
    h_id = uuid.uuid4().hex
    with get_pool().connection() as conn:
        _ensure_prop(conn, prop_id, user_id)
        conn.execute(
            "INSERT INTO propagation_stage_history (id, propagation_id, "
            "stage, quantity_alive, outcome, note, changed_at) VALUES (%s, %s, %s, %s, "
            "%s, %s, COALESCE(%s, now()))",
            (h_id, prop_id, payload.stage, payload.quantity_alive,
             payload.outcome, payload.note, payload.changed_at),
        )
        row = conn.execute(
            "SELECT id, propagation_id, stage, quantity_alive, outcome, note, "
            "changed_at FROM propagation_stage_history WHERE id = %s",
            (h_id,),
        ).fetchone()
    return StageHistoryOut(**row)
