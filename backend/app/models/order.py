from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from enum import Enum


class OrderStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    SHIPPED = "shipped"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"


class OrderItem(BaseModel):
    product_id: str
    product_name: str
    quantity: int = Field(..., gt=0)
    unit_price: float = Field(..., gt=0)
    total_price: float = Field(..., gt=0)


class OrderBase(BaseModel):
    user_id: str
    items: List[OrderItem]
    shipping_address: str
    city: str
    state: str
    pincode: str
    payment_method: str
    subtotal: float = Field(..., gt=0)
    shipping_cost: float = Field(..., ge=0)
    total: float = Field(..., gt=0)
    status: OrderStatus = OrderStatus.PENDING


class OrderCreate(OrderBase):
    pass


class OrderUpdate(BaseModel):
    status: Optional[OrderStatus] = None
    shipping_address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None


class OrderResponse(OrderBase):
    id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
