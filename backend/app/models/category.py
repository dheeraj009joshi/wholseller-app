from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class CategoryBase(BaseModel):
    name: str
    description: Optional[str] = None
    is_active: bool = True
    image_url: Optional[str] = None
    icon: Optional[str] = None  # Material icon name, e.g. "medication", "favorite"


class CategoryCreate(CategoryBase):
    pass


class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    is_active: Optional[bool] = None
    image_url: Optional[str] = None
    icon: Optional[str] = None


class CategoryResponse(CategoryBase):
    id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
