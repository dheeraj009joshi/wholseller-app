from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from app.models.order import OrderCreate, OrderUpdate, OrderResponse, OrderStatus
from app.database import database
from app.auth import get_current_user, get_current_admin_user
from app.email_service import send_order_confirmation_email
from bson import ObjectId
from datetime import datetime

router = APIRouter()


@router.get("/", response_model=List[OrderResponse])
async def get_orders(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    current_user: dict = Depends(get_current_user)
):
    order_collection = database.get_collection("orders")
    query = {}

    # Non-admin users can only see their own orders
    if not current_user.get("is_admin", False):
        query["user_id"] = current_user.get("id") or str(current_user.get("_id", ""))

    cursor = order_collection.find(query).skip(skip).limit(limit).sort("created_at", -1)
    orders = await cursor.to_list(length=limit)

    for order in orders:
        order["id"] = str(order["_id"])
        order["created_at"] = order.get("created_at", datetime.utcnow())
        order["updated_at"] = order.get("updated_at", datetime.utcnow())

    return [OrderResponse(**order) for order in orders]


@router.get("/{order_id}", response_model=OrderResponse)
async def get_order(order_id: str, current_user: dict = Depends(get_current_user)):
    order_collection = database.get_collection("orders")

    if not ObjectId.is_valid(order_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid order ID")

    order = await order_collection.find_one({"_id": ObjectId(order_id)})
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")

    # Check permissions
    current_user_id = current_user.get("id") or str(current_user.get("_id", ""))
    if not current_user.get("is_admin", False) and order["user_id"] != current_user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not enough permissions")

    order["id"] = str(order["_id"])
    order["created_at"] = order.get("created_at", datetime.utcnow())
    order["updated_at"] = order.get("updated_at", datetime.utcnow())

    return OrderResponse(**order)


@router.post("/", response_model=OrderResponse)
async def create_order(order_data: OrderCreate, current_user: dict = Depends(get_current_user)):
    order_collection = database.get_collection("orders")
    cart_collection = database.get_collection("carts")

    # Verify user_id matches current user
    current_user_id = current_user.get("id") or str(current_user.get("_id", ""))
    if order_data.user_id != current_user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Invalid user ID")

    # Clear cart after order creation
    await cart_collection.update_one(
        {"user_id": order_data.user_id},
        {"$set": {"items": [], "updated_at": datetime.utcnow()}}
    )

    try:
        order_dict = order_data.model_dump()
    except AttributeError:
        order_dict = order_data.dict()
    order_dict["created_at"] = datetime.utcnow()
    order_dict["updated_at"] = datetime.utcnow()

    result = await order_collection.insert_one(order_dict)
    order_dict["_id"] = result.inserted_id
    order_dict["id"] = str(result.inserted_id)

    # Send order confirmation email (async, don't wait for it)
    try:
        user_collection = database.get_collection("users")
        user = await user_collection.find_one({"_id": ObjectId(order_data.user_id)})
        if user:
            await send_order_confirmation_email(
                user.get("email", ""),
                user.get("name", ""),
                order_dict["id"],
                order_data.total
            )
    except Exception as e:
        print(f"Error sending order confirmation email: {e}")

    return OrderResponse(**order_dict)


@router.put("/{order_id}", response_model=OrderResponse)
async def update_order(
    order_id: str,
    order_data: OrderUpdate,
    current_user: dict = Depends(get_current_admin_user)
):
    order_collection = database.get_collection("orders")

    if not ObjectId.is_valid(order_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid order ID")

    try:
        order_dict = order_data.model_dump()
    except AttributeError:
        order_dict = order_data.dict()
    update_data = {k: v for k, v in order_dict.items() if v is not None}
    update_data["updated_at"] = datetime.utcnow()

    result = await order_collection.update_one(
        {"_id": ObjectId(order_id)},
        {"$set": update_data}
    )

    if result.matched_count == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")

    order = await order_collection.find_one({"_id": ObjectId(order_id)})
    order["id"] = str(order["_id"])

    return OrderResponse(**order)
