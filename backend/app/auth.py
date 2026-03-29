from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from app.database import database
from app.models.user import UserResponse
from app.config import settings
from bson import ObjectId

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/login")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        # Ensure password is a string and not too long
        if isinstance(plain_password, bytes):
            plain_password = plain_password.decode('utf-8')
        # Bcrypt has 72 byte limit, but we'll let passlib handle it
        return pwd_context.verify(plain_password, hashed_password)
    except Exception as e:
        print(f"Password verification error: {e}")
        return False


def get_password_hash(password: str) -> str:
    try:
        # Ensure password is a string
        if isinstance(password, bytes):
            password = password.decode('utf-8')
        
        # Bcrypt has 72 byte limit - truncate if necessary
        # But passlib should handle this, so we'll just ensure it's a string
        password_str = str(password)
        
        # Truncate to 72 bytes if needed (though this shouldn't be necessary for normal passwords)
        if len(password_str.encode('utf-8')) > 72:
            password_bytes = password_str.encode('utf-8')[:72]
            password_str = password_bytes.decode('utf-8', errors='ignore')
        
        return pwd_context.hash(password_str)
    except Exception as e:
        print(f"Password hashing error: {e}")
        raise


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.access_token_expire_minutes)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)
    return encoded_jwt


async def get_current_user(token: str = Depends(oauth2_scheme)) -> dict:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user_collection = database.get_collection("users")
    # Convert user_id string to ObjectId
    if not ObjectId.is_valid(user_id):
        raise credentials_exception
    
    user = await user_collection.find_one({"_id": ObjectId(user_id)})
    if user is None:
        raise credentials_exception

    user["id"] = str(user["_id"])
    return user


async def get_current_admin_user(current_user: dict = Depends(get_current_user)) -> dict:
    if not current_user.get("is_admin", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    return current_user
