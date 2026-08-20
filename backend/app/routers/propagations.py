"""Propagations endpoints (top-level + notes + stage history)."""
import uuid

from fastapi import APIRouter, Depends, HTTPException, status

from ..db import get_pool
from ..routers.auth import get_current_user_id
from ..schemas import (
    PropagationCreate,
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
def list_propagations(user_id: str = Depends(get_current_user_id)):
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
                       user_id: str = Depends(get_current_user_id)):
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
                       user_id: str = Depends(get_current_user_id)):
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
                       user_id: str = Depends(get_current_user_id)):
    with get_pool().connection() as conn:
        _ensure_prop(conn, prop_id, user_id)
        conn.execute("DELETE FROM propagations WHERE id = %s", (prop_id,))


# ---- Notes ----
@router.get("/{prop_id}/notes", response_model=list)
def list_prop_notes(prop_id: str, user_id: str = Depends(get_current_user_id)):
    with get_pool().connection() as conn:
        _ensure_prop(conn, prop_id, user_id)
        rows = conn.execute(
            "SELECT id, propagation_id, text, created_at, updated_at, "
            "expires_at FROM propagation_notes WHERE propagation_id = %s "
            "ORDER BY created_at",
            (prop_id,),
        ).fetchall()
    return rows


# ---- Stage history ----
@router.get("/{prop_id}/stage-history", response_model=list[StageHistoryOut])
def list_stage_history(prop_id: str,
                       user_id: str = Depends(get_current_user_id)):
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
                      user_id: str = Depends(get_current_user_id)):
    h_id = uuid.uuid4().hex
    with get_pool().connection() as conn:
        _ensure_prop(conn, prop_id, user_id)
        conn.execute(
            "INSERT INTO propagation_stage_history (id, propagation_id, "
            "stage, quantity_alive, outcome, note) VALUES (%s, %s, %s, %s, "
            "%s, %s)",
            (h_id, prop_id, payload.stage, payload.quantity_alive,
             payload.outcome, payload.note),
        )
        row = conn.execute(
            "SELECT id, propagation_id, stage, quantity_alive, outcome, note, "
            "changed_at FROM propagation_stage_history WHERE id = %s",
            (h_id,),
        ).fetchone()
    return StageHistoryOut(**row)
