from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File
from typing import List, Optional
from app.models.product import ProductCreate, ProductUpdate, ProductResponse
from app.database import database
from app.auth import get_current_user
from app.azure_storage import upload_image_to_azure, delete_image_from_azure
from bson import ObjectId
from datetime import datetime

router = APIRouter()


@router.get("/", response_model=List[ProductResponse])
async def get_products(
    category: Optional[str] = None,
    search: Optional[str] = None,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100)
):
    product_collection = database.get_collection("products")
    query = {"is_active": True}

    if category:
        query["category"] = category

    if search:
        query["$or"] = [
            {"name": {"$regex": search, "$options": "i"}},
            {"description": {"$regex": search, "$options": "i"}}
        ]

    cursor = product_collection.find(query).skip(skip).limit(limit).sort("created_at", -1)
    products = await cursor.to_list(length=limit)

    for product in products:
        product["id"] = str(product["_id"])
        product["created_at"] = product.get("created_at", datetime.utcnow())
        product["updated_at"] = product.get("updated_at", datetime.utcnow())

    return [ProductResponse(**product) for product in products]


@router.get("/{product_id}", response_model=ProductResponse)
async def get_product(product_id: str):
    product_collection = database.get_collection("products")

    if not ObjectId.is_valid(product_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid product ID")

    product = await product_collection.find_one({"_id": ObjectId(product_id)})
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    product["id"] = str(product["_id"])
    product["created_at"] = product.get("created_at", datetime.utcnow())
    product["updated_at"] = product.get("updated_at", datetime.utcnow())

    return ProductResponse(**product)


@router.post("/", response_model=ProductResponse, dependencies=[Depends(get_current_user)])
async def create_product(
    product_data: ProductCreate,
    current_user: dict = Depends(get_current_user)
):
    if not current_user.get("is_admin", False):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not enough permissions")

    product_collection = database.get_collection("products")
    try:
        product_dict = product_data.model_dump()
    except AttributeError:
        product_dict = product_data.dict()
    product_dict["created_at"] = datetime.utcnow()
    product_dict["updated_at"] = datetime.utcnow()

    result = await product_collection.insert_one(product_dict)
    product_dict["_id"] = result.inserted_id
    product_dict["id"] = str(result.inserted_id)

    return ProductResponse(**product_dict)


@router.post("/{product_id}/images", dependencies=[Depends(get_current_user)])
async def upload_product_image(
    product_id: str,
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user)
):
    if not current_user.get("is_admin", False):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not enough permissions")

    product_collection = database.get_collection("products")

    if not ObjectId.is_valid(product_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid product ID")

    product = await product_collection.find_one({"_id": ObjectId(product_id)})
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    # Read file content
    file_content = await file.read()
    
    # Upload to Azure
    image_url = await upload_image_to_azure(file_content, file.filename, folder="products")
    
    if not image_url:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to upload image")

    # Add image URL to product
    images = product.get("images", [])
    images.append(image_url)
    
    await product_collection.update_one(
        {"_id": ObjectId(product_id)},
        {"$set": {"images": images, "updated_at": datetime.utcnow()}}
    )

    return {"image_url": image_url, "message": "Image uploaded successfully"}


@router.put("/{product_id}", response_model=ProductResponse, dependencies=[Depends(get_current_user)])
async def update_product(
    product_id: str,
    product_data: ProductUpdate,
    current_user: dict = Depends(get_current_user)
):
    if not current_user.get("is_admin", False):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not enough permissions")

    product_collection = database.get_collection("products")

    if not ObjectId.is_valid(product_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid product ID")

    try:
        product_dict = product_data.model_dump()
    except AttributeError:
        product_dict = product_data.dict()
    update_data = {k: v for k, v in product_dict.items() if v is not None}
    update_data["updated_at"] = datetime.utcnow()

    result = await product_collection.update_one(
        {"_id": ObjectId(product_id)},
        {"$set": update_data}
    )

    if result.matched_count == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    product = await product_collection.find_one({"_id": ObjectId(product_id)})
    product["id"] = str(product["_id"])

    return ProductResponse(**product)


@router.delete("/{product_id}", dependencies=[Depends(get_current_user)])
async def delete_product(product_id: str, current_user: dict = Depends(get_current_user)):
    if not current_user.get("is_admin", False):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not enough permissions")

    product_collection = database.get_collection("products")

    if not ObjectId.is_valid(product_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid product ID")

    result = await product_collection.update_one(
        {"_id": ObjectId(product_id)},
        {"$set": {"is_active": False, "updated_at": datetime.utcnow()}}
    )

    if result.matched_count == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    return {"message": "Product deleted successfully"}
