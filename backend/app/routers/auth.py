from fastapi import APIRouter, Depends, HTTPException, status
from datetime import timedelta, datetime
from app.models.user import UserCreate, UserLogin, UserResponse, Token
from app.database import database
from app.auth import (
    verify_password,
    get_password_hash,
    create_access_token,
    get_current_user,
)
from app.config import settings
from app.email_service import send_welcome_email
from bson import ObjectId

router = APIRouter()


@router.post("/register", response_model=Token)
async def register(user_data: UserCreate):
    try:
        user_collection = database.get_collection("users")

        # Check if user already exists
        existing_user = await user_collection.find_one({"email": user_data.email})
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )

        # Create user document - use model_dump() for Pydantic v2
        try:
            user_dict = user_data.model_dump()
        except AttributeError:
            # Fallback for Pydantic v1
            user_dict = user_data.dict()
        
        # Hash password - ensure it's a string
        password = user_dict.pop("password")
        if not isinstance(password, str):
            password = str(password)
        
        # Validate password length
        if len(password) < 6:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Password must be at least 6 characters"
            )
        
        user_dict["password"] = get_password_hash(password)
        
        # Add timestamps
        now = datetime.utcnow()
        user_dict["created_at"] = now
        user_dict["updated_at"] = now

        # Insert user
        result = await user_collection.insert_one(user_dict)
        inserted_id = result.inserted_id
        user_dict["_id"] = inserted_id
        user_dict["id"] = str(inserted_id)

        # Create access token
        access_token_expires = timedelta(minutes=settings.access_token_expire_minutes)
        access_token = create_access_token(
            data={"sub": str(inserted_id)}, expires_delta=access_token_expires
        )

        # Prepare user response - get fresh data from DB to ensure all fields
        saved_user = await user_collection.find_one({"_id": inserted_id})
        if not saved_user:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="User created but could not be retrieved"
            )
        
        # Convert ObjectId to string and prepare response
        user_response_dict = {
            "id": str(saved_user["_id"]),
            "email": saved_user.get("email", ""),
            "name": saved_user.get("name", ""),
            "phone": saved_user.get("phone", ""),
            "business_name": saved_user.get("business_name", ""),
            "gst_number": saved_user.get("gst_number"),
            "address": saved_user.get("address"),
            "city": saved_user.get("city"),
            "state": saved_user.get("state"),
            "pincode": saved_user.get("pincode"),
            "is_admin": saved_user.get("is_admin", False),
            "created_at": saved_user.get("created_at", now),
            "updated_at": saved_user.get("updated_at", now),
        }
        
        user_response = UserResponse(**user_response_dict)
        
        # Send welcome email (async, don't wait for it)
        try:
            await send_welcome_email(user_data.email, user_data.name)
        except Exception as e:
            print(f"Error sending welcome email: {e}")
        
        return Token(access_token=access_token, token_type="bearer", user=user_response)
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"Registration error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Registration failed: {str(e)}"
        )


@router.post("/login", response_model=Token)
async def login(credentials: UserLogin):
    try:
        user_collection = database.get_collection("users")
        user = await user_collection.find_one({"email": credentials.email})

        if not user or not verify_password(credentials.password, user.get("password", "")):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password"
            )

        # Create access token
        access_token_expires = timedelta(minutes=settings.access_token_expire_minutes)
        access_token = create_access_token(
            data={"sub": str(user["_id"])}, expires_delta=access_token_expires
        )

        # Prepare user response
        user["id"] = str(user["_id"])
        user_response_dict = {
            k: v for k, v in user.items() 
            if k not in ["password", "_id"]
        }
        # Ensure datetime fields exist
        if "created_at" not in user_response_dict:
            user_response_dict["created_at"] = datetime.utcnow()
        if "updated_at" not in user_response_dict:
            user_response_dict["updated_at"] = datetime.utcnow()
        
        user_response = UserResponse(**user_response_dict)
        return Token(access_token=access_token, token_type="bearer", user=user_response)
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"Login error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Login failed: {str(e)}"
        )


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(current_user: dict = Depends(get_current_user)):
    user_dict = {
        k: v for k, v in current_user.items() 
        if k not in ["password", "_id"]
    }
    # Ensure required fields exist
    if "id" not in user_dict:
        user_dict["id"] = str(current_user.get("_id", ""))
    if "created_at" not in user_dict:
        user_dict["created_at"] = current_user.get("created_at", datetime.utcnow())
    if "updated_at" not in user_dict:
        user_dict["updated_at"] = current_user.get("updated_at", datetime.utcnow())
    
    return UserResponse(**user_dict)
