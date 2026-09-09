"""Plant ↔ sensor (pot) bindings.

Lets a user attach a soil-moisture pot (1..N) to a specific plant so the
app can show that plant's live moisture. A pot can be bound to at most one
plant at a time; a plant can have at most one pot.
"""
from fastapi import APIRouter, Depends, HTTPException, status

from ..db import get_pool
from ..feature_flags import FLAG_SOIL_SENSORS, require_feature
from ..schemas import PlantSensorBindingCreate, PlantSensorBindingOut

router = APIRouter(prefix="/plants", tags=["sensor-bindings"])


def _latest_for_pot(conn, pot: int) -> dict | None:
    """Latest sensor reading for a pot, or None."""
    return conn.execute(
        "SELECT moisture, raw, read_at FROM sensor_readings "
        "WHERE pot = %s ORDER BY read_at DESC LIMIT 1",
        (pot,),
    ).fetchone()


# NOTE: static paths (/sensor-bindings) MUST be declared before dynamic
# paths (/{plant_id}/...) or FastAPI matches "sensor-bindings" as a plant_id.
@router.get("/sensor-bindings", response_model=list[PlantSensorBindingOut])
def list_bindings(user_id: str = Depends(require_feature(FLAG_SOIL_SENSORS))):
    """All of the user's plant↔pot bindings with latest moisture.

    Used by the home grid so it can show each plant's moisture in one
    request instead of one per plant.
    """
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT b.plant_id, b.pot, b.created_at, "
            "sr.moisture, sr.raw, sr.read_at "
            "FROM plant_sensor_bindings b "
            "LEFT JOIN LATERAL ("
            "  SELECT moisture, raw, read_at FROM sensor_readings "
            "  WHERE pot = b.pot ORDER BY read_at DESC LIMIT 1"
            ") sr ON true "
            "WHERE b.user_id = %s",
            (user_id,),
        ).fetchall()
    return [
        PlantSensorBindingOut(
            plant_id=r["plant_id"],
            pot=r["pot"],
            moisture=r["moisture"],
            raw=r["raw"],
            read_at=r["read_at"],
            created_at=r["created_at"],
        )
        for r in rows
    ]


@router.post("/{plant_id}/sensor-binding",
             response_model=PlantSensorBindingOut, status_code=201)
def bind_sensor(
    plant_id: str,
    payload: PlantSensorBindingCreate,
    user_id: str = Depends(require_feature(FLAG_SOIL_SENSORS)),
):
    """Bind a pot to a plant. Fails if the pot is already bound to another
    plant, or if the plant already has a different pot bound."""
    pot = payload.pot
    if pot < 1:
        raise HTTPException(status_code=422, detail="pot must be >= 1")
    with get_pool().connection() as conn:
        plant = conn.execute(
            "SELECT id FROM plants WHERE id = %s AND user_id = %s",
            (plant_id, user_id),
        ).fetchone()
        if not plant:
            raise HTTPException(status_code=404, detail="Plant not found")
        # Pot already bound to a different plant?
        existing = conn.execute(
            "SELECT plant_id FROM plant_sensor_bindings WHERE pot = %s "
            "AND user_id = %s",
            (pot, user_id),
        ).fetchone()
        if existing and existing["plant_id"] != plant_id:
            raise HTTPException(
                status_code=409,
                detail="Pot already bound to another plant",
            )
        conn.execute(
            "INSERT INTO plant_sensor_bindings (plant_id, pot, user_id) "
            "VALUES (%s, %s, %s) "
            "ON CONFLICT (plant_id) DO UPDATE SET pot = EXCLUDED.pot",
            (plant_id, pot, user_id),
        )
        row = conn.execute(
            "SELECT plant_id, pot, created_at FROM plant_sensor_bindings "
            "WHERE plant_id = %s",
            (plant_id,),
        ).fetchone()
        latest = _latest_for_pot(conn, pot)
    return PlantSensorBindingOut(
        plant_id=row["plant_id"],
        pot=row["pot"],
        moisture=latest["moisture"] if latest else None,
        raw=latest["raw"] if latest else None,
        read_at=latest["read_at"] if latest else None,
        created_at=row["created_at"],
    )


@router.get("/{plant_id}/sensor-binding", response_model=PlantSensorBindingOut)
def get_binding(plant_id: str, user_id: str = Depends(require_feature(FLAG_SOIL_SENSORS))):
    """The plant's current pot binding + latest moisture, if any."""
    with get_pool().connection() as conn:
        plant = conn.execute(
            "SELECT id FROM plants WHERE id = %s AND user_id = %s",
            (plant_id, user_id),
        ).fetchone()
        if not plant:
            raise HTTPException(status_code=404, detail="Plant not found")
        row = conn.execute(
            "SELECT plant_id, pot, created_at FROM plant_sensor_bindings "
            "WHERE plant_id = %s",
            (plant_id,),
        ).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="No sensor binding")
        latest = _latest_for_pot(conn, row["pot"])
    return PlantSensorBindingOut(
        plant_id=row["plant_id"],
        pot=row["pot"],
        moisture=latest["moisture"] if latest else None,
        raw=latest["raw"] if latest else None,
        read_at=latest["read_at"] if latest else None,
        created_at=row["created_at"],
    )


@router.delete("/{plant_id}/sensor-binding", status_code=status.HTTP_204_NO_CONTENT)
def unbind_sensor(plant_id: str, user_id: str = Depends(require_feature(FLAG_SOIL_SENSORS))):
    """Remove the plant's pot binding."""
    with get_pool().connection() as conn:
        plant = conn.execute(
            "SELECT id FROM plants WHERE id = %s AND user_id = %s",
            (plant_id, user_id),
        ).fetchone()
        if not plant:
            raise HTTPException(status_code=404, detail="Plant not found")
        conn.execute(
            "DELETE FROM plant_sensor_bindings WHERE plant_id = %s",
            (plant_id,),
        )
    return None
