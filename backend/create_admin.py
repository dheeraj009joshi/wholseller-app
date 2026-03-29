#!/usr/bin/env python3
"""
Script to create an admin user
Usage: python create_admin.py
"""
import asyncio
import sys
from app.database import database
from app.auth import get_password_hash
from datetime import datetime

async def create_admin():
    email = input("Enter admin email: ").strip()
    if not email:
        print("Email is required!")
        sys.exit(1)
    
    password = input("Enter admin password (min 6 characters): ").strip()
    if len(password) < 6:
        print("Password must be at least 6 characters!")
        sys.exit(1)
    
    name = input("Enter admin name: ").strip() or "Admin User"
    phone = input("Enter phone number: ").strip() or "0000000000"
    business_name = input("Enter business name: ").strip() or "Admin Business"
    
    await database.connect()
    
    try:
        user_collection = database.get_collection("users")
        
        # Check if user already exists
        existing_user = await user_collection.find_one({"email": email})
        if existing_user:
            # Update existing user to admin
            await user_collection.update_one(
                {"email": email},
                {"$set": {
                    "is_admin": True,
                    "password": get_password_hash(password),
                    "updated_at": datetime.utcnow()
                }}
            )
            print(f"✅ Updated existing user '{email}' to admin")
        else:
            # Create new admin user
            user_dict = {
                "email": email,
                "name": name,
                "phone": phone,
                "business_name": business_name,
                "password": get_password_hash(password),
                "is_admin": True,
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow()
            }
            
            result = await user_collection.insert_one(user_dict)
            print(f"✅ Admin user created successfully!")
            print(f"   Email: {email}")
            print(f"   User ID: {result.inserted_id}")
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
    finally:
        await database.disconnect()

if __name__ == "__main__":
    asyncio.run(create_admin())
