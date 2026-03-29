from fastapi import APIRouter, Depends, HTTPException, status
from app.models.user import UserUpdate, UserResponse
from app.database import database
from app.auth import get_current_user
from bson import ObjectId
from datetime import datetime

router = APIRouter()


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(current_user: dict = Depends(get_current_user)):
    return UserResponse(**{k: v for k, v in current_user.items() if k != "password"})


@router.put("/me", response_model=UserResponse)
async def update_current_user(
    user_data: UserUpdate,
    current_user: dict = Depends(get_current_user)
):
    user_collection = database.get_collection("users")

    try:
        user_dict = user_data.model_dump()
    except AttributeError:
        user_dict = user_data.dict()
    update_data = {k: v for k, v in user_dict.items() if v is not None}
    update_data["updated_at"] = datetime.utcnow()

    await user_collection.update_one(
        {"_id": current_user["_id"]},
        {"$set": update_data}
    )

    updated_user = await user_collection.find_one({"_id": current_user["_id"]})
    updated_user["id"] = str(updated_user["_id"])

    return UserResponse(**{k: v for k, v in updated_user.items() if k != "password"})
