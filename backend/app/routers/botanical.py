"""AI-powered botanical field prefill from a free-text plant phrase."""
from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException, Query

from ..ai_care import generate_botanical_prefill, normalize_locale
from ..db import get_pool
from ..feature_flags import FLAG_AI_BOTANICAL_PREFILL, require_feature
from ..schemas import BotanicalPrefillIn, BotanicalPrefillOut

logger = logging.getLogger("plontukrot.botanical")

router = APIRouter(prefix="/botanical", tags=["botanical"])


@router.post("/prefill", response_model=BotanicalPrefillOut)
def botanical_prefill(
    body: BotanicalPrefillIn,
    force_refresh: bool = Query(default=False, alias="forceRefresh"),
    user_id: str = Depends(require_feature(FLAG_AI_BOTANICAL_PREFILL)),
):
    """Extract botanical fields (genus, species, cultivar, family, ...) from a
    free-text plant phrase using AI.

    Results are cached by (phrase, locale) to reduce redundant AI calls for
    common cultivars and trading names.
    """
    trimmed = body.phrase.strip()
    if not trimmed:
        raise HTTPException(status_code=400, detail="Plant phrase must not be empty")

    normalized_locale = normalize_locale(body.locale)
    normalized_key = trimmed.lower()

    logger.info(
        "Botanical prefill request: phrase=%s locale=%s force_refresh=%s",
        trimmed,
        normalized_locale,
        force_refresh,
    )

    if not force_refresh:
        with get_pool().connection() as conn:
            row = conn.execute(
                "SELECT genus, species, cultivar, plant_family, trading_name, "
                "is_hybrid, variegation FROM botanical_prefill_cache "
                "WHERE phrase = %s AND locale = %s",
                (normalized_key, normalized_locale),
            ).fetchone()

            if row is not None:
                logger.info("Botanical prefill cache hit: %s (%s)", trimmed, normalized_locale)
                return BotanicalPrefillOut(
                    genus=row.get("genus"),
                    species=row.get("species"),
                    cultivar=row.get("cultivar"),
                    plant_family=row.get("plant_family"),
                    trading_name=row.get("trading_name"),
                    is_hybrid=bool(row.get("is_hybrid", False)),
                    variegation=row.get("variegation"),
                )

    logger.info("Botanical prefill cache miss, calling AI: %s (%s)", trimmed, normalized_locale)
    try:
        data = generate_botanical_prefill(trimmed, normalized_locale)
    except Exception as e:
        logger.error(
            "Failed to generate botanical prefill for %s (%s): %s",
            trimmed,
            normalized_locale,
            e,
        )
        raise HTTPException(
            status_code=502,
            detail=f"Failed to generate botanical prefill: {e}",
        )

    genus = data.get("genus")
    species = data.get("species")
    cultivar = data.get("cultivar")
    plant_family = data.get("plant_family")
    trading_name = data.get("trading_name")
    is_hybrid = bool(data.get("is_hybrid", False))
    variegation = data.get("variegation")

    with get_pool().connection() as conn:
        conn.execute(
            """
            INSERT INTO botanical_prefill_cache (
                phrase, locale, genus, species, cultivar, plant_family,
                trading_name, is_hybrid, variegation, updated_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, now())
            ON CONFLICT (phrase, locale) DO UPDATE SET
                genus = EXCLUDED.genus,
                species = EXCLUDED.species,
                cultivar = EXCLUDED.cultivar,
                plant_family = EXCLUDED.plant_family,
                trading_name = EXCLUDED.trading_name,
                is_hybrid = EXCLUDED.is_hybrid,
                variegation = EXCLUDED.variegation,
                updated_at = now()
            """,
            (
                normalized_key,
                normalized_locale,
                genus,
                species,
                cultivar,
                plant_family,
                trading_name,
                is_hybrid,
                variegation,
            ),
        )

    logger.info(
        "Botanical prefill result: phrase=%s genus=%s species=%s cultivar=%s family=%s hybrid=%s variegation=%s",
        trimmed,
        genus,
        species,
        cultivar,
        plant_family,
        is_hybrid,
        variegation,
    )

    return BotanicalPrefillOut(
        genus=genus,
        species=species,
        cultivar=cultivar,
        plant_family=plant_family,
        trading_name=trading_name,
        is_hybrid=is_hybrid,
        variegation=variegation,
    )
