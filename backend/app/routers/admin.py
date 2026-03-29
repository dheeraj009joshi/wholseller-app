from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List
from app.database import database
from app.auth import get_current_admin_user
from app.models.user import UserResponse
from app.models.product import ProductResponse
from app.models.order import OrderResponse
from bson import ObjectId
from datetime import datetime, timedelta

router = APIRouter()


@router.get("/dashboard/stats")
async def get_dashboard_stats(current_user: dict = Depends(get_current_admin_user)):
    user_collection = database.get_collection("users")
    product_collection = database.get_collection("products")
    order_collection = database.get_collection("orders")

    total_users = await user_collection.count_documents({})
    total_products = await product_collection.count_documents({"is_active": True})
    total_orders = await order_collection.count_documents({})

    # Calculate revenue
    pipeline = [
        {"$group": {"_id": None, "total": {"$sum": "$total"}}}
    ]
    revenue_result = await order_collection.aggregate(pipeline).to_list(length=1)
    total_revenue = revenue_result[0]["total"] if revenue_result else 0.0

    # Orders in last 30 days
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    recent_orders = await order_collection.count_documents({
        "created_at": {"$gte": thirty_days_ago}
    })

    return {
        "total_users": total_users,
        "total_products": total_products,
        "total_orders": total_orders,
        "total_revenue": total_revenue,
        "recent_orders": recent_orders
    }


@router.get("/users", response_model=List[UserResponse])
async def get_all_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    current_user: dict = Depends(get_current_admin_user)
):
    user_collection = database.get_collection("users")
    cursor = user_collection.find({}).skip(skip).limit(limit).sort("created_at", -1)
    users = await cursor.to_list(length=limit)

    for user in users:
        user["id"] = str(user["_id"])

    return [UserResponse(**{k: v for k, v in user.items() if k != "password"}) for user in users]


@router.get("/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: str, current_user: dict = Depends(get_current_admin_user)):
    user_collection = database.get_collection("users")

    if not ObjectId.is_valid(user_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid user ID")

    user = await user_collection.find_one({"_id": ObjectId(user_id)})
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    user["id"] = str(user["_id"])
    return UserResponse(**{k: v for k, v in user.items() if k != "password"})


@router.put("/users/{user_id}/toggle-admin")
async def toggle_admin_status(user_id: str, current_user: dict = Depends(get_current_admin_user)):
    user_collection = database.get_collection("users")

    if not ObjectId.is_valid(user_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid user ID")

    user = await user_collection.find_one({"_id": ObjectId(user_id)})
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    new_admin_status = not user.get("is_admin", False)
    await user_collection.update_one(
        {"_id": ObjectId(user_id)},
        {"$set": {"is_admin": new_admin_status, "updated_at": datetime.utcnow()}}
    )

    return {"message": f"User admin status updated to {new_admin_status}"}


@router.get("/orders", response_model=List[OrderResponse])
async def get_all_orders(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    status_filter: str = Query(None),
    current_user: dict = Depends(get_current_admin_user)
):
    order_collection = database.get_collection("orders")
    query = {}

    if status_filter:
        query["status"] = status_filter

    cursor = order_collection.find(query).skip(skip).limit(limit).sort("created_at", -1)
    orders = await cursor.to_list(length=limit)

    for order in orders:
        order["id"] = str(order["_id"])
        order["created_at"] = order.get("created_at", datetime.utcnow())
        order["updated_at"] = order.get("updated_at", datetime.utcnow())

    return [OrderResponse(**order) for order in orders]


@router.get("/products", response_model=List[ProductResponse])
async def get_all_products_admin(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    current_user: dict = Depends(get_current_admin_user)
):
    product_collection = database.get_collection("products")
    cursor = product_collection.find({}).skip(skip).limit(limit).sort("created_at", -1)
    products = await cursor.to_list(length=limit)

    for product in products:
        product["id"] = str(product["_id"])
        product["created_at"] = product.get("created_at", datetime.utcnow())
        product["updated_at"] = product.get("updated_at", datetime.utcnow())

    return [ProductResponse(**product) for product in products]
