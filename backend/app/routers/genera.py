"""Botanical care guides for plant genera."""
from __future__ import annotations

import logging
from fastapi import APIRouter, Depends, HTTPException, Query

from ..ai_care import generate_care_guide, normalize_locale
from ..db import get_pool
from ..routers.auth import get_current_user_id
from ..schemas import GenusCareGuideOut

logger = logging.getLogger("plontukrot.genera")

router = APIRouter(prefix="/genera", tags=["genera"])


@router.get("/{genus}/care-guide", response_model=GenusCareGuideOut)
def get_genus_care_guide(
    genus: str,
    locale: str = Query(default="ru"),
    force_refresh: bool = Query(default=False, alias="forceRefresh"),
    user_id: str = Depends(get_current_user_id),
):
    """Return botanical overview & care guide for a genus (cached or AI-generated)."""
    trimmed = genus.strip()
    if not trimmed:
        raise HTTPException(status_code=400, detail="Genus name must not be empty")

    normalized_key = trimmed.lower()
    normalized_locale = normalize_locale(locale)

    if not force_refresh:
        with get_pool().connection() as conn:
            row = conn.execute(
                "SELECT genus, genus_name, origin, light, watering, fertilizing, "
                "soil, humidity, toxicity FROM genus_care_guides "
                "WHERE genus = %s AND locale = %s",
                (normalized_key, normalized_locale),
            ).fetchone()

            if row is not None:
                return GenusCareGuideOut(
                    genus=row.get("genus_name") or trimmed,
                    origin=row.get("origin"),
                    light=row.get("light"),
                    watering=row.get("watering"),
                    fertilizing=row.get("fertilizing"),
                    soil=row.get("soil"),
                    humidity=row.get("humidity"),
                    toxicity=row.get("toxicity"),
                )

    # Generate via AI service
    try:
        data = generate_care_guide(trimmed, normalized_locale)
    except Exception as e:
        logger.error(
            "Failed to generate care guide for %s (%s): %s",
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

    # Persist in DB cache for all users (per genus + locale)
    with get_pool().connection() as conn:
        conn.execute(
            """
            INSERT INTO genus_care_guides (
                genus, locale, genus_name, origin, light, watering,
                fertilizing, soil, humidity, toxicity, updated_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, now())
            ON CONFLICT (genus, locale) DO UPDATE SET
                genus_name = EXCLUDED.genus_name,
                origin = EXCLUDED.origin,
                light = EXCLUDED.light,
                watering = EXCLUDED.watering,
                fertilizing = EXCLUDED.fertilizing,
                soil = EXCLUDED.soil,
                humidity = EXCLUDED.humidity,
                toxicity = EXCLUDED.toxicity,
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
            ),
        )

    return GenusCareGuideOut(
        genus=trimmed,
        origin=origin,
        light=light,
        watering=watering,
        fertilizing=fertilizing,
        soil=soil,
        humidity=humidity,
        toxicity=toxicity,
    )


@router.post("/{genus}/care-guide/refresh", response_model=GenusCareGuideOut)
def refresh_genus_care_guide(
    genus: str,
    locale: str = Query(default="ru"),
    user_id: str = Depends(get_current_user_id),
):
    """Force re-generate and update the cached care guide for a genus."""
    return get_genus_care_guide(
        genus,
        locale=locale,
        force_refresh=True,
        user_id=user_id,
    )
