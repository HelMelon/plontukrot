"""Botanical care guides for plant families."""
from __future__ import annotations

import logging
from fastapi import APIRouter, Depends, HTTPException, Query

from ..ai_care import generate_family_care_guide, normalize_locale
from ..db import get_pool
from ..feature_flags import FLAG_GENUS_CARE, require_feature
from ..schemas import FamilyCareGuideOut

logger = logging.getLogger("plontukrot.families")

router = APIRouter(prefix="/families", tags=["families"])


@router.get("/{family}/care-guide", response_model=FamilyCareGuideOut)
def get_family_care_guide(
    family: str,
    locale: str = Query(default="ru"),
    force_refresh: bool = Query(default=False, alias="forceRefresh"),
    user_id: str = Depends(require_feature(FLAG_GENUS_CARE)),
):
    """Return botanical overview & care guide for a family (cached or AI-generated)."""
    trimmed = family.strip()
    if not trimmed:
        raise HTTPException(status_code=400, detail="Family name must not be empty")

    normalized_key = trimmed.lower()
    normalized_locale = normalize_locale(locale)

    if not force_refresh:
        with get_pool().connection() as conn:
            row = conn.execute(
                "SELECT family, family_name, origin, light, watering, fertilizing, "
                "soil, humidity, toxicity, min_temp_c FROM family_care_guides "
                "WHERE family = %s AND locale = %s",
                (normalized_key, normalized_locale),
            ).fetchone()

            if row is not None:
                return FamilyCareGuideOut(
                    family=row.get("family_name") or trimmed,
                    origin=row.get("origin"),
                    light=row.get("light"),
                    watering=row.get("watering"),
                    fertilizing=row.get("fertilizing"),
                    soil=row.get("soil"),
                    humidity=row.get("humidity"),
                    toxicity=row.get("toxicity"),
                    min_temp_c=row.get("min_temp_c"),
                )

    # Generate via AI service
    try:
        data = generate_family_care_guide(trimmed, normalized_locale)
    except Exception as e:
        logger.error(
            "Failed to generate care guide for family %s (%s): %s",
            trimmed,
            normalized_locale,
            e,
        )
        raise HTTPException(
            status_code=502,
            detail=f"Failed to generate care guide: {e}",
        )

    origin = data.get("origin")
    light = data.get("light")
    watering = data.get("watering")
    fertilizing = data.get("fertilizing")
    soil = data.get("soil")
    humidity = data.get("humidity")
    toxicity = data.get("toxicity")
    min_temp_c = data.get("min_temp_c")

    # Persist in DB cache for all users (per family + locale)
    with get_pool().connection() as conn:
        conn.execute(
            """
            INSERT INTO family_care_guides (
                family, locale, family_name, origin, light, watering,
                fertilizing, soil, humidity, toxicity, min_temp_c, updated_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, now())
            ON CONFLICT (family, locale) DO UPDATE SET
                family_name = EXCLUDED.family_name,
                origin = EXCLUDED.origin,
                light = EXCLUDED.light,
                watering = EXCLUDED.watering,
                fertilizing = EXCLUDED.fertilizing,
                soil = EXCLUDED.soil,
                humidity = EXCLUDED.humidity,
                toxicity = EXCLUDED.toxicity,
                min_temp_c = EXCLUDED.min_temp_c,
                updated_at = now()
            """,
            (
                normalized_key,
                normalized_locale,
                trimmed,
                origin,
                light,
                watering,
                fertilizing,
                soil,
                humidity,
                toxicity,
                min_temp_c,
            ),
        )

    return FamilyCareGuideOut(
        family=trimmed,
        origin=origin,
        light=light,
        watering=watering,
        fertilizing=fertilizing,
        soil=soil,
        humidity=humidity,
        toxicity=toxicity,
        min_temp_c=min_temp_c,
    )


@router.post("/{family}/care-guide/refresh", response_model=FamilyCareGuideOut)
def refresh_family_care_guide(
    family: str,
    locale: str = Query(default="ru"),
    user_id: str = Depends(require_feature(FLAG_GENUS_CARE)),
):
    """Force re-generate and update the cached care guide for a family."""
    return get_family_care_guide(
        family,
        locale=locale,
        force_refresh=True,
        user_id=user_id,
    )
