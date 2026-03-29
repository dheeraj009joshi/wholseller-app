from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from app.models.category import CategoryCreate, CategoryUpdate, CategoryResponse
from app.database import database
from app.auth import get_current_user, get_current_admin_user
from bson import ObjectId
from datetime import datetime

router = APIRouter()


@router.get("/", response_model=List[CategoryResponse])
async def get_categories(
    active_only: bool = Query(True, description="Return only active categories")
):
    category_collection = database.get_collection("categories")
    query = {}
    if active_only:
        query["is_active"] = True

    cursor = category_collection.find(query).sort("name", 1)
    categories = await cursor.to_list(length=1000)

    for category in categories:
        category["id"] = str(category["_id"])
        category["created_at"] = category.get("created_at", datetime.utcnow())
        category["updated_at"] = category.get("updated_at", datetime.utcnow())

    return [CategoryResponse(**category) for category in categories]


@router.get("/{category_id}", response_model=CategoryResponse)
async def get_category(category_id: str):
    category_collection = database.get_collection("categories")

    if not ObjectId.is_valid(category_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid category ID")

    category = await category_collection.find_one({"_id": ObjectId(category_id)})
    if not category:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")

    category["id"] = str(category["_id"])
    category["created_at"] = category.get("created_at", datetime.utcnow())
    category["updated_at"] = category.get("updated_at", datetime.utcnow())

    return CategoryResponse(**category)


@router.post("/", response_model=CategoryResponse, dependencies=[Depends(get_current_admin_user)])
async def create_category(
    category_data: CategoryCreate,
    current_user: dict = Depends(get_current_admin_user)
):
    category_collection = database.get_collection("categories")

    # Check if category with same name already exists
    existing = await category_collection.find_one({"name": category_data.name})
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Category with this name already exists"
        )

    try:
        category_dict = category_data.model_dump()
    except AttributeError:
        category_dict = category_data.dict()
    category_dict["created_at"] = datetime.utcnow()
    category_dict["updated_at"] = datetime.utcnow()

    result = await category_collection.insert_one(category_dict)
    category_dict["_id"] = result.inserted_id
    category_dict["id"] = str(result.inserted_id)

    return CategoryResponse(**category_dict)


@router.put("/{category_id}", response_model=CategoryResponse, dependencies=[Depends(get_current_admin_user)])
async def update_category(
    category_id: str,
    category_data: CategoryUpdate,
    current_user: dict = Depends(get_current_admin_user)
):
    category_collection = database.get_collection("categories")

    if not ObjectId.is_valid(category_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid category ID")

    # Check if name is being updated and if it conflicts with existing category
    try:
        category_dict = category_data.model_dump(exclude_unset=True)
    except AttributeError:
        category_dict = category_data.dict(exclude_unset=True)
    
    if "name" in category_dict:
        existing = await category_collection.find_one({
            "name": category_dict["name"],
            "_id": {"$ne": ObjectId(category_id)}
        })
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Category with this name already exists"
            )

    update_data = {k: v for k, v in category_dict.items() if v is not None}
    update_data["updated_at"] = datetime.utcnow()

    result = await category_collection.update_one(
        {"_id": ObjectId(category_id)},
        {"$set": update_data}
    )

    if result.matched_count == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")

    category = await category_collection.find_one({"_id": ObjectId(category_id)})
    category["id"] = str(category["_id"])

    return CategoryResponse(**category)


@router.delete("/{category_id}", dependencies=[Depends(get_current_admin_user)])
async def delete_category(
    category_id: str,
    current_user: dict = Depends(get_current_admin_user)
):
    category_collection = database.get_collection("categories")
    product_collection = database.get_collection("products")

    if not ObjectId.is_valid(category_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid category ID")

    # Check if any products are using this category
    products_count = await product_collection.count_documents({"category": category_id})
    if products_count > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot delete category: {products_count} product(s) are using it"
        )

    result = await category_collection.update_one(
        {"_id": ObjectId(category_id)},
        {"$set": {"is_active": False, "updated_at": datetime.utcnow()}}
    )

    if result.matched_count == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")

    return {"message": "Category deleted successfully"}
