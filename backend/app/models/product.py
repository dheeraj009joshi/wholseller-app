from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from bson import ObjectId


class ProductBase(BaseModel):
    name: str
    description: str
    category: str
    moq: int = Field(..., gt=0)
    images: List[str] = []
    pricing_tiers: Dict[str, float] = {}
    stock: int = 0
    sku: Optional[str] = None
    weight: Optional[float] = 0.0
    shipping_cost: Optional[float] = 0.0
    variants: List[Dict[str, Any]] = []
    is_active: bool = True
    
    # Medical Fields
    dosage: Optional[str] = None
    manufacturer: Optional[str] = None
    pack_size: Optional[str] = None
    requires_prescription: bool = False
    expiry_date: Optional[str] = None


class ProductCreate(ProductBase):
    pass


class ProductUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    moq: Optional[int] = Field(None, gt=0)
    images: Optional[List[str]] = None
    pricing_tiers: Optional[Dict[str, float]] = None
    stock: Optional[int] = None
    sku: Optional[str] = None
    weight: Optional[float] = None
    shipping_cost: Optional[float] = None
    variants: Optional[List[Dict[str, Any]]] = None
    is_active: Optional[bool] = None
    
    # Medical Fields
    dosage: Optional[str] = None
    manufacturer: Optional[str] = None
    pack_size: Optional[str] = None
    requires_prescription: Optional[bool] = None
    expiry_date: Optional[str] = None


class ProductResponse(ProductBase):
    id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
