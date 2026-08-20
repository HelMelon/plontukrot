"""Auth endpoints: register, login, current user."""
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from ..db import get_pool
from ..schemas import LoginRequest, RegisterRequest, TokenResponse, UserOut
from ..security import (
    create_access_token,
    decode_access_token,
    hash_password,
    verify_password,
)

router = APIRouter(prefix="/auth", tags=["auth"])
_bearer = HTTPBearer(auto_error=False)

_SELECT_USER = (
    "SELECT id, email, password_hash, name, locale_code, currency_code, "
    "collection_visibility, personal_data_consent_at, created_at "
    "FROM users"
)


def _get_user_by_email(conn, email: str):
    return conn.execute(f"{_SELECT_USER} WHERE email = %s", (email,)).fetchone()


def _row_to_user_out(row) -> UserOut:
    return UserOut(
        id=str(row["id"]),
        email=row["email"],
        name=row["name"],
        locale_code=row["locale_code"],
        currency_code=row["currency_code"],
        collection_visibility=row["collection_visibility"],
        personal_data_consent_at=row["personal_data_consent_at"],
        created_at=row["created_at"],
    )


@router.post("/register", response_model=TokenResponse, status_code=201)
def register(payload: RegisterRequest):
    """Create a user, hash the password, and return a JWT."""
    email = payload.email.lower().strip()
    with get_pool().connection() as conn:
        if _get_user_by_email(conn, email) is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already registered",
            )
        user_id = uuid.uuid4()
        conn.execute(
            "INSERT INTO users (id, email, password_hash, name, locale_code, "
            "currency_code, collection_visibility) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s)",
            (
                user_id,
                email,
                hash_password(payload.password),
                payload.name,
                "ru",
                "BYN",
                "friends",
            ),
        )
        token = create_access_token(str(user_id))
        return TokenResponse(access_token=token)


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest):
    """Verify credentials and return a JWT."""
    email = payload.email.lower().strip()
    with get_pool().connection() as conn:
        row = _get_user_by_email(conn, email)
    if row is None or not verify_password(payload.password, row["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )
    token = create_access_token(str(row["id"]))
    return TokenResponse(access_token=token)


def get_current_user_id(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
) -> str:
    """FastAPI dependency: return the authenticated user id or raise 401."""
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )
    sub = decode_access_token(credentials.credentials)
    if sub is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        )
    return sub


@router.get("/me", response_model=UserOut)
def me(user_id: str = Depends(get_current_user_id)):
    """Return the current authenticated user's profile."""
    with get_pool().connection() as conn:
        row = conn.execute(
            f"{_SELECT_USER} WHERE id = %s",
            (user_id,),
        ).fetchone()
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    return _row_to_user_out(row)
