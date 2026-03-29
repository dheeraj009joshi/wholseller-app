from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from app.models.user import Address, AddressCreate
from app.database import database
from app.auth import get_current_user
from bson import ObjectId
from datetime import datetime
from bson import ObjectId as BsonObjectId

router = APIRouter()


@router.get("/", response_model=List[Address])
async def get_addresses(current_user: dict = Depends(get_current_user)):
    user_collection = database.get_collection("users")
    user = await user_collection.find_one({"_id": current_user["_id"]})
    
    if not user:
        return []
    
    addresses = user.get("addresses", [])
    return [Address(**addr) for addr in addresses]


@router.post("/", response_model=Address)
async def create_address(
    address_data: AddressCreate,
    current_user: dict = Depends(get_current_user)
):
    user_collection = database.get_collection("users")
    
    try:
        address_dict = address_data.model_dump()
    except AttributeError:
        address_dict = address_data.dict()
    address_dict["id"] = str(BsonObjectId())
    
    # If this is set as default, unset other defaults
    if address_data.is_default:
        user = await user_collection.find_one({"_id": current_user["_id"]})
        addresses = user.get("addresses", [])
        for addr in addresses:
            addr["is_default"] = False
    
    await user_collection.update_one(
        {"_id": current_user["_id"]},
        {
            "$push": {"addresses": address_dict},
            "$set": {"updated_at": datetime.utcnow()}
        }
    )
    
    return Address(**address_dict)


@router.put("/{address_id}", response_model=Address)
async def update_address(
    address_id: str,
    address_data: AddressCreate,
    current_user: dict = Depends(get_current_user)
):
    user_collection = database.get_collection("users")
    user = await user_collection.find_one({"_id": current_user["_id"]})
    
    addresses = user.get("addresses", [])
    address_found = False
    
    # If setting as default, unset other defaults
    if address_data.is_default:
        for addr in addresses:
            if addr["id"] != address_id:
                addr["is_default"] = False
    
    for addr in addresses:
        if addr["id"] == address_id:
            try:
                addr.update(address_data.model_dump())
            except AttributeError:
                addr.update(address_data.dict())
            address_found = True
            break
    
    if not address_found:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Address not found")
    
    await user_collection.update_one(
        {"_id": current_user["_id"]},
        {
            "$set": {"addresses": addresses, "updated_at": datetime.utcnow()}
        }
    )
    
    updated_address = next(addr for addr in addresses if addr["id"] == address_id)
    return Address(**updated_address)


@router.delete("/{address_id}")
async def delete_address(address_id: str, current_user: dict = Depends(get_current_user)):
    user_collection = database.get_collection("users")
    user = await user_collection.find_one({"_id": current_user["_id"]})
    
    addresses = [addr for addr in user.get("addresses", []) if addr["id"] != address_id]
    
    await user_collection.update_one(
        {"_id": current_user["_id"]},
        {
            "$set": {"addresses": addresses, "updated_at": datetime.utcnow()}
        }
    )
    
    return {"message": "Address deleted successfully"}
