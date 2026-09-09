"""Per-user catalog endpoints: fertilizers, soils, soil components,
fertilizer ingredients, stimulators, wish-list, finance entries."""
import uuid

from fastapi import APIRouter, Depends, HTTPException, status

from ..db import get_pool, jsonb
from ..feature_flags import FLAG_FINANCES, FLAG_WISH_LIST, require_feature
from ..routers.auth import get_current_user_id
from ..schemas import (
    ComponentCreate,
    ComponentOut,
    FertilizerCreate,
    FertilizerOut,
    FinanceEntryCreate,
    FinanceEntryOut,
    SoilCreate,
    SoilOut,
    StimulatorCreate,
    StimulatorOut,
    WishListCreate,
    WishListOut,
)

router = APIRouter(tags=["catalogs"])


def _make_id() -> str:
    return uuid.uuid4().hex


# ---- Fertilizers ----
@router.get("/fertilizers", response_model=list[FertilizerOut])
def list_fertilizers(user_id: str = Depends(get_current_user_id)):
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, name, kind, water_ml, components, created_at "
            "FROM fertilizers WHERE user_id = %s ORDER BY created_at",
            (user_id,),
        ).fetchall()
    return [FertilizerOut(**r) for r in rows]


@router.post("/fertilizers", response_model=FertilizerOut, status_code=201)
def create_fertilizer(payload: FertilizerCreate,
                      user_id: str = Depends(get_current_user_id)):
    f_id = _make_id()
    with get_pool().connection() as conn:
        conn.execute(
            "INSERT INTO fertilizers (id, user_id, name, kind, water_ml, "
            "components) VALUES (%s, %s, %s, %s, %s, %s)",
            (f_id, user_id, payload.name, payload.kind, payload.water_ml,
             jsonb(payload.components)),
        )
        row = conn.execute(
            "SELECT id, name, kind, water_ml, components, created_at "
            "FROM fertilizers WHERE id = %s",
            (f_id,),
        ).fetchone()
    return FertilizerOut(**row)


@router.delete("/fertilizers/{fertilizer_id}", status_code=204)
def delete_fertilizer(fertilizer_id: str,
                      user_id: str = Depends(get_current_user_id)):
    with get_pool().connection() as conn:
        conn.execute(
            "DELETE FROM fertilizers WHERE id = %s AND user_id = %s",
            (fertilizer_id, user_id),
        )


# ---- Soils ----
@router.get("/soils", response_model=list[SoilOut])
def list_soils(user_id: str = Depends(get_current_user_id)):
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, name, components, created_at "
            "FROM soils WHERE user_id = %s ORDER BY created_at",
            (user_id,),
        ).fetchall()
    return [SoilOut(**r) for r in rows]


@router.post("/soils", response_model=SoilOut, status_code=201)
def create_soil(payload: SoilCreate,
                user_id: str = Depends(get_current_user_id)):
    s_id = _make_id()
    with get_pool().connection() as conn:
        conn.execute(
            "INSERT INTO soils (id, user_id, name, components) "
            "VALUES (%s, %s, %s, %s)",
            (s_id, user_id, payload.name, jsonb(payload.components)),
        )
        row = conn.execute(
            "SELECT id, name, components, created_at FROM soils WHERE id = %s",
            (s_id,),
        ).fetchone()
    return SoilOut(**row)


@router.delete("/soils/{soil_id}", status_code=204)
def delete_soil(soil_id: str, user_id: str = Depends(get_current_user_id)):
    with get_pool().connection() as conn:
        conn.execute("DELETE FROM soils WHERE id = %s AND user_id = %s",
                     (soil_id, user_id))


# ---- Soil components ----
@router.get("/components", response_model=list[ComponentOut])
def list_components(user_id: str = Depends(get_current_user_id)):
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, name, created_at FROM components "
            "WHERE user_id = %s ORDER BY created_at",
            (user_id,),
        ).fetchall()
    return [ComponentOut(**r) for r in rows]


@router.post("/components", response_model=ComponentOut, status_code=201)
def create_component(payload: ComponentCreate,
                     user_id: str = Depends(get_current_user_id)):
    c_id = _make_id()
    with get_pool().connection() as conn:
        conn.execute(
            "INSERT INTO components (id, user_id, name) VALUES (%s, %s, %s)",
            (c_id, user_id, payload.name),
        )
        row = conn.execute(
            "SELECT id, name, created_at FROM components WHERE id = %s",
            (c_id,),
        ).fetchone()
    return ComponentOut(**row)


@router.patch("/components/{component_id}", response_model=ComponentOut)
def update_component(component_id: str, payload: ComponentCreate,
                     user_id: str = Depends(get_current_user_id)):
    with get_pool().connection() as conn:
        row = conn.execute(
            "UPDATE components SET name = %s "
            "WHERE id = %s AND user_id = %s "
            "RETURNING id, name, created_at",
            (payload.name, component_id, user_id),
        ).fetchone()
        if row is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                                detail="Component not found")
    return ComponentOut(**row)


@router.delete("/components/{component_id}", status_code=204)
def delete_component(component_id: str,
                     user_id: str = Depends(get_current_user_id)):
    with get_pool().connection() as conn:
        conn.execute("DELETE FROM components WHERE id = %s AND user_id = %s",
                     (component_id, user_id))


# ---- Fertilizer ingredients ----
@router.get("/fertilizer-components", response_model=list[ComponentOut])
def list_fertilizer_components(user_id: str = Depends(get_current_user_id)):
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, name, created_at FROM fertilizer_components "
            "WHERE user_id = %s ORDER BY created_at",
            (user_id,),
        ).fetchall()
    return [ComponentOut(**r) for r in rows]


@router.post("/fertilizer-components", response_model=ComponentOut,
             status_code=201)
def create_fertilizer_component(payload: ComponentCreate,
                                user_id: str = Depends(get_current_user_id)):
    c_id = _make_id()
    with get_pool().connection() as conn:
        conn.execute(
            "INSERT INTO fertilizer_components (id, user_id, name) "
            "VALUES (%s, %s, %s)",
            (c_id, user_id, payload.name),
        )
        row = conn.execute(
            "SELECT id, name, created_at FROM fertilizer_components "
            "WHERE id = %s",
            (c_id,),
        ).fetchone()
    return ComponentOut(**row)


@router.patch("/fertilizer-components/{component_id}",
              response_model=ComponentOut)
def update_fertilizer_component(component_id: str, payload: ComponentCreate,
                                user_id: str = Depends(get_current_user_id)):
    with get_pool().connection() as conn:
        row = conn.execute(
            "UPDATE fertilizer_components SET name = %s "
            "WHERE id = %s AND user_id = %s "
            "RETURNING id, name, created_at",
            (payload.name, component_id, user_id),
        ).fetchone()
        if row is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                                detail="Fertilizer component not found")
    return ComponentOut(**row)


@router.delete("/fertilizer-components/{component_id}", status_code=204)
def delete_fertilizer_component(component_id: str,
                                user_id: str = Depends(get_current_user_id)):
    with get_pool().connection() as conn:
        conn.execute(
            "DELETE FROM fertilizer_components "
            "WHERE id = %s AND user_id = %s",
            (component_id, user_id),
        )


# ---- Stimulators ----
@router.get("/stimulators", response_model=list[StimulatorOut])
def list_stimulators(user_id: str = Depends(get_current_user_id)):
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, name, default_dosage, created_at FROM stimulators "
            "WHERE user_id = %s ORDER BY created_at",
            (user_id,),
        ).fetchall()
    return [StimulatorOut(**r) for r in rows]


@router.post("/stimulators", response_model=StimulatorOut, status_code=201)
def create_stimulator(payload: StimulatorCreate,
                      user_id: str = Depends(get_current_user_id)):
    s_id = _make_id()
    with get_pool().connection() as conn:
        conn.execute(
            "INSERT INTO stimulators (id, user_id, name, default_dosage) "
            "VALUES (%s, %s, %s, %s)",
            (s_id, user_id, payload.name, payload.default_dosage),
        )
        row = conn.execute(
            "SELECT id, name, default_dosage, created_at FROM stimulators "
            "WHERE id = %s",
            (s_id,),
        ).fetchone()
    return StimulatorOut(**row)


@router.delete("/stimulators/{stimulator_id}", status_code=204)
def delete_stimulator(stimulator_id: str,
                      user_id: str = Depends(get_current_user_id)):
    with get_pool().connection() as conn:
        conn.execute("DELETE FROM stimulators WHERE id = %s AND user_id = %s",
                     (stimulator_id, user_id))


# ---- Wish list ----
@router.get("/wish-list", response_model=list[WishListOut])
def list_wish_list(user_id: str = Depends(require_feature(FLAG_WISH_LIST))):
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, name_en, name_alt, created_at, updated_at "
            "FROM wish_list_items WHERE user_id = %s ORDER BY created_at",
            (user_id,),
        ).fetchall()
    return [WishListOut(**r) for r in rows]


@router.post("/wish-list", response_model=WishListOut, status_code=201)
def create_wish_list(payload: WishListCreate,
                     user_id: str = Depends(require_feature(FLAG_WISH_LIST))):
    w_id = _make_id()
    with get_pool().connection() as conn:
        conn.execute(
            "INSERT INTO wish_list_items (id, user_id, name_en, name_alt) "
            "VALUES (%s, %s, %s, %s)",
            (w_id, user_id, payload.name_en, payload.name_alt),
        )
        row = conn.execute(
            "SELECT id, name_en, name_alt, created_at, updated_at "
            "FROM wish_list_items WHERE id = %s",
            (w_id,),
        ).fetchone()
    return WishListOut(**row)


@router.delete("/wish-list/{item_id}", status_code=204)
def delete_wish_list(item_id: str,
                     user_id: str = Depends(require_feature(FLAG_WISH_LIST))):
    with get_pool().connection() as conn:
        conn.execute("DELETE FROM wish_list_items WHERE id = %s AND user_id = %s",
                     (item_id, user_id))


# ---- Finance entries ----
@router.get("/finance-entries", response_model=list[FinanceEntryOut])
def list_finance(user_id: str = Depends(require_feature(FLAG_FINANCES))):
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, title, amount, type, source, date, wish_list_item_id, "
            "created_at, updated_at FROM finance_entries "
            "WHERE user_id = %s ORDER BY date",
            (user_id,),
        ).fetchall()
    return [FinanceEntryOut(**r) for r in rows]


@router.post("/finance-entries", response_model=FinanceEntryOut, status_code=201)
def create_finance(payload: FinanceEntryCreate,
                   user_id: str = Depends(require_feature(FLAG_FINANCES))):
    f_id = _make_id()
    with get_pool().connection() as conn:
        conn.execute(
            "INSERT INTO finance_entries (id, user_id, title, amount, type, "
            "source, date, wish_list_item_id) VALUES (%s, %s, %s, %s, %s, "
            "%s, %s, %s)",
            (f_id, user_id, payload.title, payload.amount, payload.type,
             payload.source, payload.date, payload.wish_list_item_id),
        )
        row = conn.execute(
            "SELECT id, title, amount, type, source, date, wish_list_item_id, "
            "created_at, updated_at FROM finance_entries WHERE id = %s",
            (f_id,),
        ).fetchone()
    return FinanceEntryOut(**row)


@router.delete("/finance-entries/{entry_id}", status_code=204)
def delete_finance(entry_id: str,
                   user_id: str = Depends(require_feature(FLAG_FINANCES))):
    with get_pool().connection() as conn:
        conn.execute("DELETE FROM finance_entries WHERE id = %s AND user_id = %s",
                     (entry_id, user_id))
