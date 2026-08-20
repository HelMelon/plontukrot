"""Social endpoints: friends, friend requests, gifts."""
import uuid

from fastapi import APIRouter, Depends, HTTPException, status

from ..db import get_pool, jsonb
from ..routers.auth import get_current_user_id
from ..schemas import FriendRequestCreate, FriendRequestOut, GiftCreate

router = APIRouter(tags=["social"])


def _make_id() -> str:
    return uuid.uuid4().hex


# ---- Friend requests ----
@router.get("/friend-requests", response_model=list[FriendRequestOut])
def list_friend_requests(user_id: str = Depends(get_current_user_id)):
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, from_uid, to_uid, from_display_name, from_photo_url, "
            "status, created_at FROM friend_requests "
            "WHERE from_uid = %s OR to_uid = %s ORDER BY created_at",
            (user_id, user_id),
        ).fetchall()
    return [FriendRequestOut(**r) for r in rows]


@router.post("/friend-requests", response_model=FriendRequestOut,
             status_code=201)
def create_friend_request(payload: FriendRequestCreate,
                          user_id: str = Depends(get_current_user_id)):
    r_id = _make_id()
    with get_pool().connection() as conn:
        conn.execute(
            "INSERT INTO friend_requests (id, from_uid, to_uid, "
            "from_display_name, from_photo_url, status) "
            "VALUES (%s, %s, %s, %s, %s, %s)",
            (r_id, user_id, payload.to_uid, payload.from_display_name,
             payload.from_photo_url, payload.status),
        )
        row = conn.execute(
            "SELECT id, from_uid, to_uid, from_display_name, from_photo_url, "
            "status, created_at FROM friend_requests WHERE id = %s",
            (r_id,),
        ).fetchone()
    return FriendRequestOut(**row)


@router.patch("/friend-requests/{request_id}/status")
def update_friend_request_status(
    request_id: str, status_code: int,
    user_id: str = Depends(get_current_user_id),
):
    with get_pool().connection() as conn:
        row = conn.execute(
            "SELECT id, from_uid, to_uid FROM friend_requests WHERE id = %s",
            (request_id,),
        ).fetchone()
        if row is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                                detail="Request not found")
        # Only the recipient may accept/decline.
        if row["to_uid"] != user_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,
                                detail="Not allowed")
        conn.execute(
            "UPDATE friend_requests SET status = %s WHERE id = %s",
            (status_code, request_id),
        )
        if status_code == 1:  # accepted -> become friends
            conn.execute(
                "INSERT INTO friends (id, user_a, user_b) "
                "VALUES (%s, %s, %s) ON CONFLICT (user_a, user_b) DO NOTHING",
                (_make_id(), row["from_uid"], row["to_uid"]),
            )
    return {"status": "ok"}


# ---- Friends ----
@router.get("/friends")
def list_friends(user_id: str = Depends(get_current_user_id)):
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, user_a, user_b, created_at FROM friends "
            "WHERE user_a = %s OR user_b = %s ORDER BY created_at",
            (user_id, user_id),
        ).fetchall()
    return rows


# ---- Gifts ----
@router.post("/gifts/outgoing", status_code=201)
def send_gift(payload: GiftCreate, user_id: str = Depends(get_current_user_id)):
    g_id = _make_id()
    with get_pool().connection() as conn:
        conn.execute(
            "INSERT INTO outgoing_gifts (id, from_uid, to_uid, from_plant_id, "
            "plant_snapshot, status) VALUES (%s, %s, %s, %s, %s, %s)",
            (g_id, user_id, payload.to_uid, payload.from_plant_id,
             jsonb(payload.plant_snapshot), payload.status),
        )
        conn.execute(
            "INSERT INTO incoming_gifts (id, to_uid, from_uid, from_plant_id, "
            "plant_snapshot, status) VALUES (%s, %s, %s, %s, %s, %s)",
            (_make_id(), payload.to_uid, user_id, payload.from_plant_id,
             jsonb(payload.plant_snapshot), payload.status),
        )
    return {"id": g_id}


@router.get("/gifts/incoming")
def list_incoming_gifts(user_id: str = Depends(get_current_user_id)):
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, to_uid, from_uid, from_display_name, from_plant_id, "
            "plant_snapshot, status, created_at FROM incoming_gifts "
            "WHERE to_uid = %s ORDER BY created_at",
            (user_id,),
        ).fetchall()
    return rows


@router.get("/gifts/outgoing")
def list_outgoing_gifts(user_id: str = Depends(get_current_user_id)):
    with get_pool().connection() as conn:
        rows = conn.execute(
            "SELECT id, from_uid, to_uid, from_display_name, from_plant_id, "
            "plant_snapshot, status, created_at FROM outgoing_gifts "
            "WHERE from_uid = %s ORDER BY created_at",
            (user_id,),
        ).fetchall()
    return rows
