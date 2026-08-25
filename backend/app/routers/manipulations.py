"""Глобальные манипуляции (не вложенные в растение).

Нужен главной странице, чтобы одним запросом получить все активные
переукоренения (тип rerooting) и показать фильтр «на реанимации».
"""
from fastapi import APIRouter, Depends

from ..db import get_pool
from ..routers.auth import get_current_user_id
from ..schemas import ManipulationOut

router = APIRouter(prefix="/manipulations", tags=["manipulations"])


@router.get("", response_model=list[ManipulationOut])
def list_all_manipulations(user_id: str = Depends(get_current_user_id)):
    """Все манипуляции текущего пользователя, свежие сверху."""
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT m.id, m.plant_id, m.type, m.applied_at, m.ended_at, "
            "m.reanimation_tags, m.is_greenhouse, m.note, m.stage_before, "
            "m.stage_after, m.stimulator_id, m.stimulator_name, m.dosage, "
            "m.created_at FROM plant_manipulations m "
            "JOIN plants p ON p.id = m.plant_id "
            "WHERE p.user_id = %s "
            "ORDER BY m.applied_at DESC",
            (user_id,),
        ).fetchall()
    return [ManipulationOut(**r) for r in rows]
