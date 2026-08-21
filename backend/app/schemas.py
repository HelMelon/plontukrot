"""Pydantic schemas for auth."""
from __future__ import annotations

from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class RegisterRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    email: EmailStr
    password: str = Field(min_length=6)
    name: Optional[str] = None
    personal_data_consent_at: Optional[datetime] = Field(default=None, alias="personalDataConsentAt")

class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    email: str
    name: Optional[str] = None
    locale_code: Optional[str] = None
    currency_code: Optional[str] = None
    collection_visibility: Optional[str] = None
    personal_data_consent_at: Optional[datetime] = None
    created_at: datetime


class UserUpdate(BaseModel):
    model_config = ConfigDict(extra="ignore", populate_by_name=True)

    name: Optional[str] = None
    locale_code: Optional[str] = Field(default=None, alias="localeCode")
    currency_code: Optional[str] = Field(default=None, alias="currencyCode")
    collection_visibility: Optional[str] = Field(default=None, alias="collectionVisibility")
    personal_data_consent_at: Optional[datetime] = Field(default=None, alias="personalDataConsentAt")


class PlantCreate(BaseModel):
    model_config = ConfigDict(extra="ignore", populate_by_name=True)

    genus: Optional[str] = None
    species: Optional[str] = None
    cultivar: Optional[str] = None
    trading_name: Optional[str] = Field(default=None, alias="tradingName")
    plant_family: Optional[str] = Field(default=None, alias="plantFamily")
    nickname: Optional[str] = None
    stage: Optional[int] = None
    variegation: Optional[int] = None
    watering_frequency: Optional[int] = Field(default=None, alias="wateringFrequency")
    fertilizing_frequency_days: Optional[int] = Field(default=None, alias="fertilizingFrequencyDays")
    initial_leaf_count: Optional[int] = Field(default=None, alias="initialLeafCount")
    last_watered_at: Optional[datetime] = Field(default=None, alias="lastWateredAt")
    last_fertilized_at: Optional[datetime] = Field(default=None, alias="lastFertilizedAt")
    last_repotted_at: Optional[datetime] = Field(default=None, alias="lastRepottedAt")
    last_manipulation_at: Optional[datetime] = Field(default=None, alias="lastManipulationAt")
    members: Optional[list[Any]] = None
    archived_at: Optional[datetime] = Field(default=None, alias="archivedAt")
    expires_at: Optional[datetime] = Field(default=None, alias="expiresAt")
    archive_reason: Optional[str] = Field(default=None, alias="archiveReason")
    archive_note: Optional[str] = Field(default=None, alias="archiveNote")
    merged_into_plant_id: Optional[str] = Field(default=None, alias="mergedIntoPlantId")
    gifted_to_uid: Optional[str] = Field(default=None, alias="giftedToUid")


class PlantUpdate(BaseModel):
    model_config = ConfigDict(extra="ignore", populate_by_name=True)

    genus: Optional[str] = None
    species: Optional[str] = None
    cultivar: Optional[str] = None
    trading_name: Optional[str] = Field(default=None, alias="tradingName")
    plant_family: Optional[str] = Field(default=None, alias="plantFamily")
    nickname: Optional[str] = None
    stage: Optional[int] = None
    variegation: Optional[int] = None
    watering_frequency: Optional[int] = Field(default=None, alias="wateringFrequency")
    fertilizing_frequency_days: Optional[int] = Field(default=None, alias="fertilizingFrequencyDays")
    initial_leaf_count: Optional[int] = Field(default=None, alias="initialLeafCount")
    last_watered_at: Optional[datetime] = Field(default=None, alias="lastWateredAt")
    last_fertilized_at: Optional[datetime] = Field(default=None, alias="lastFertilizedAt")
    last_repotted_at: Optional[datetime] = Field(default=None, alias="lastRepottedAt")
    last_manipulation_at: Optional[datetime] = Field(default=None, alias="lastManipulationAt")
    members: Optional[list[Any]] = None
    archived_at: Optional[datetime] = Field(default=None, alias="archivedAt")
    expires_at: Optional[datetime] = Field(default=None, alias="expiresAt")
    archive_reason: Optional[str] = Field(default=None, alias="archiveReason")
    archive_note: Optional[str] = Field(default=None, alias="archiveNote")
    merged_into_plant_id: Optional[str] = Field(default=None, alias="mergedIntoPlantId")
    gifted_to_uid: Optional[str] = Field(default=None, alias="giftedToUid")


class PlantOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    genus: Optional[str] = None
    species: Optional[str] = None
    cultivar: Optional[str] = None
    trading_name: Optional[str] = None
    plant_family: Optional[str] = None
    nickname: Optional[str] = None
    stage: int
    variegation: Optional[int] = None
    watering_frequency: Optional[int] = None
    fertilizing_frequency_days: Optional[int] = None
    initial_leaf_count: int
    last_watered_at: Optional[datetime] = None
    last_fertilized_at: Optional[datetime] = None
    last_repotted_at: Optional[datetime] = None
    last_manipulation_at: Optional[datetime] = None
    members: Optional[list[Any]] = None
    archived_at: Optional[datetime] = None
    expires_at: Optional[datetime] = None
    archive_reason: Optional[str] = None
    archive_note: Optional[str] = None
    merged_into_plant_id: Optional[str] = None
    gifted_to_uid: Optional[str] = None
    created_at: datetime
    photos: list[PlantPhotoOut] = []


class PlantPhotoCreate(BaseModel):
    image_url: str
    image_thumb_url: Optional[str] = None
    is_legacy: bool = False


class PlantPhotoOut(BaseModel):
    id: str
    plant_id: str
    image_url: str
    image_thumb_url: Optional[str] = None
    added_at: datetime
    is_legacy: bool


class PlantNoteCreate(BaseModel):
    text: str
    expires_at: Optional[datetime] = None


class PlantNoteOut(BaseModel):
    id: str
    plant_id: str
    text: str
    created_at: datetime
    updated_at: datetime
    expires_at: Optional[datetime] = None


class GrowthEventCreate(BaseModel):
    type: int
    expires_at: Optional[datetime] = None


class GrowthEventOut(BaseModel):
    id: str
    plant_id: str
    type: int
    created_at: datetime
    expires_at: Optional[datetime] = None


class WateringCreate(BaseModel):
    watered_at: Optional[datetime] = None
    next_watering: Optional[datetime] = None


class WateringOut(BaseModel):
    id: str
    plant_id: str
    watered_at: Optional[datetime] = None
    next_watering: Optional[datetime] = None
    created_at: datetime


class FertilizingCreate(BaseModel):
    fertilizer_id: Optional[str] = None
    fertilizer_name: Optional[str] = None
    application_method: Optional[str] = None
    components: Optional[list] = None
    water_ml: Optional[int] = None
    applied_at: datetime
    next_fertilizing: Optional[datetime] = None


class FertilizingOut(BaseModel):
    id: str
    plant_id: str
    fertilizer_id: Optional[str] = None
    fertilizer_name: Optional[str] = None
    application_method: Optional[str] = None
    components: Optional[list] = None
    water_ml: Optional[int] = None
    applied_at: datetime
    next_fertilizing: Optional[datetime] = None
    created_at: datetime


class RepottingCreate(BaseModel):
    soil_id: Optional[str] = None
    soil_name: Optional[str] = None
    components: Optional[list] = None
    slow_release_fertilizer: bool = False
    repotted_at: datetime


class RepottingOut(BaseModel):
    id: str
    plant_id: str
    soil_id: Optional[str] = None
    soil_name: Optional[str] = None
    components: Optional[list] = None
    slow_release_fertilizer: bool
    repotted_at: datetime
    created_at: datetime


class ManipulationCreate(BaseModel):
    model_config = ConfigDict(extra="ignore", populate_by_name=True)

    type: int
    applied_at: datetime = Field(alias="appliedAt")
    ended_at: Optional[datetime] = Field(default=None, alias="endedAt")
    reanimation_tags: Optional[list[str]] = Field(default=None, alias="reanimationTags")
    is_greenhouse: bool = Field(default=False, alias="isGreenhouse")
    note: Optional[str] = None
    stage_before: Optional[int] = Field(default=None, alias="stageBefore")
    stage_after: Optional[int] = Field(default=None, alias="stageAfter")
    stimulator_id: Optional[str] = Field(default=None, alias="stimulatorId")
    stimulator_name: Optional[str] = Field(default=None, alias="stimulatorName")
    dosage: Optional[str] = None


class ManipulationUpdate(BaseModel):
    model_config = ConfigDict(extra="ignore", populate_by_name=True)

    type: Optional[int] = None
    applied_at: Optional[datetime] = Field(default=None, alias="appliedAt")
    ended_at: Optional[datetime] = Field(default=None, alias="endedAt")
    reanimation_tags: Optional[list[str]] = Field(default=None, alias="reanimationTags")
    is_greenhouse: Optional[bool] = Field(default=None, alias="isGreenhouse")
    note: Optional[str] = None
    stage_before: Optional[int] = Field(default=None, alias="stageBefore")
    stage_after: Optional[int] = Field(default=None, alias="stageAfter")
    stimulator_id: Optional[str] = Field(default=None, alias="stimulatorId")
    stimulator_name: Optional[str] = Field(default=None, alias="stimulatorName")
    dosage: Optional[str] = None


class ManipulationOut(BaseModel):
    id: str
    plant_id: str
    type: int
    applied_at: datetime
    ended_at: Optional[datetime] = None
    reanimation_tags: Optional[list[str]] = None
    is_greenhouse: bool = False
    note: Optional[str] = None
    stage_before: Optional[int] = None
    stage_after: Optional[int] = None
    stimulator_id: Optional[str] = None
    stimulator_name: Optional[str] = None
    dosage: Optional[str] = None
    created_at: datetime


class PropagationCreate(BaseModel):
    parent_plant_id: Optional[str] = None
    parent_plant_name: Optional[str] = None
    parent_plant_family: Optional[str] = None
    method: int = 0
    stage: int = 0
    status: int = 0
    quantity: int = 0
    quantity_alive: int = 0
    gifted_quantity: int = 0
    sold_quantity: int = 0
    traded_quantity: int = 0
    lost_quantity: int = 0
    started_at: datetime
    sold_at: Optional[datetime] = None


class PropagationOut(BaseModel):
    id: str
    parent_plant_id: Optional[str] = None
    parent_plant_name: Optional[str] = None
    parent_plant_family: Optional[str] = None
    method: int
    stage: int
    status: int
    quantity: int
    quantity_alive: int
    gifted_quantity: int
    sold_quantity: int
    traded_quantity: int
    lost_quantity: int
    started_at: datetime
    sold_at: Optional[datetime] = None
    created_at: datetime


class StageHistoryCreate(BaseModel):
    stage: int
    quantity_alive: int = 0
    outcome: Optional[str] = None
    note: Optional[str] = None


class StageHistoryOut(BaseModel):
    id: str
    propagation_id: str
    stage: int
    quantity_alive: int
    outcome: Optional[str] = None
    note: Optional[str] = None
    changed_at: datetime


# ---- Catalogs (per-user) ----
class FertilizerCreate(BaseModel):
    name: str
    kind: int = 0
    water_ml: int = 0
    components: Optional[list] = None


class FertilizerOut(BaseModel):
    id: str
    name: str
    kind: int
    water_ml: int
    components: Optional[list] = None
    created_at: datetime


class SoilCreate(BaseModel):
    name: str
    components: Optional[list] = None


class SoilOut(BaseModel):
    id: str
    name: str
    components: Optional[list] = None
    created_at: datetime


class ComponentCreate(BaseModel):
    name: str


class ComponentOut(BaseModel):
    id: str
    name: str
    created_at: datetime


class StimulatorCreate(BaseModel):
    name: str
    default_dosage: Optional[str] = None


class StimulatorOut(BaseModel):
    id: str
    name: str
    default_dosage: Optional[str] = None
    created_at: datetime


class WishListCreate(BaseModel):
    name_en: str
    name_alt: Optional[str] = None


class WishListOut(BaseModel):
    id: str
    name_en: str
    name_alt: Optional[str] = None
    created_at: datetime
    updated_at: datetime


class FinanceEntryCreate(BaseModel):
    title: str
    amount: float
    type: int = 0
    source: Optional[str] = None
    date: datetime
    wish_list_item_id: Optional[str] = None


class FinanceEntryOut(BaseModel):
    id: str
    title: str
    amount: float
    type: int
    source: Optional[str] = None
    date: datetime
    wish_list_item_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime


# ---- Social ----
class FriendRequestCreate(BaseModel):
    to_uid: str
    from_display_name: Optional[str] = None
    from_photo_url: Optional[str] = None
    status: int = 0


class FriendRequestOut(BaseModel):
    id: str
    from_uid: str
    to_uid: str
    from_display_name: Optional[str] = None
    from_photo_url: Optional[str] = None
    status: int
    created_at: datetime


class GiftCreate(BaseModel):
    to_uid: str
    from_plant_id: Optional[str] = None
    plant_snapshot: Optional[dict] = None
    status: int = 0



