from pydantic import BaseModel, Field
from typing import List, Optional


class CartItem(BaseModel):
    product_id: str
    product_name: str
    product_image: Optional[str] = None
    quantity: int = Field(..., gt=0)
    unit_price: float = Field(..., gt=0)
    total_price: float = Field(..., gt=0)


class CartBase(BaseModel):
    user_id: str
    items: List[CartItem] = []


class CartResponse(CartBase):
    subtotal: float = 0.0
    shipping_cost: float = 500.0
    total: float = 0.0

    class Config:
        from_attributes = True


class CartItemCreate(BaseModel):
    product_id: str
    quantity: int = Field(..., gt=0)


class CartItemUpdate(BaseModel):
    quantity: int = Field(..., gt=0)
