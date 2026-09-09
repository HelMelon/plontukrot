"""Feature-flag endpoints."""
from fastapi import APIRouter, Depends

from ..feature_flags import resolve_feature_flags
from ..routers.auth import get_current_user_id

router = APIRouter(prefix="/features", tags=["features"])


@router.get("")
def get_features(user_id: str = Depends(get_current_user_id)):
    """Return effective feature flags for the authenticated user.

    Source of truth is the server (defaults + env overrides). Clients must
    not persist these values locally.
    """
    return resolve_feature_flags(user_id)
