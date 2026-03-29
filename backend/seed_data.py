#!/usr/bin/env python3
"""Seed categories and a few sample products for the medical store app."""
import asyncio
import random
from datetime import datetime
from app.database import database

async def seed_data():
    print("🚀 Seeding categories and products...")
    await database.connect()
    
    try:
        category_collection = database.get_collection("categories")
        product_collection = database.get_collection("products")
        
        # Check if we already have categories
        existing_cats = await category_collection.find({}).to_list(length=100)
        cat_name_to_id = {}
        if existing_cats:
            print("📁 Categories already exist. Adding products only (if any missing)...")
            category_ids = [str(c["_id"]) for c in existing_cats]
            cat_id_to_name = {str(c["_id"]): c["name"] for c in existing_cats}
            cat_name_to_id = {c["name"]: str(c["_id"]) for c in existing_cats}
        else:
            cat_name_to_id = {}
            # 1. Seed Categories
            print("📁 Seeding categories...")
            categories_data = [
                {"name": "General Wellness", "description": "Daily health and immunity supplements"},
                {"name": "Pain Relief", "description": "Management for body pain and fever"},
                {"name": "Digestive Care", "description": "Gastric and digestive health"},
                {"name": "Diabetes Care", "description": "Glucose monitoring and management"},
                {"name": "Ayurvedic & Herbal", "description": "Natural and holistic wellness"},
            ]
            category_ids = []
            cat_id_to_name = {}
            for cat_data in categories_data:
                cat_data["is_active"] = True
                cat_data["created_at"] = datetime.utcnow()
                cat_data["updated_at"] = datetime.utcnow()
                r = await category_collection.insert_one(cat_data)
                cat_id = str(r.inserted_id)
                category_ids.append(cat_id)
                cat_id_to_name[cat_id] = cat_data["name"]
        
        # 2. Migrate products: if any have category as name, update to category id
        products_with_name_cat = await product_collection.find({"category": {"$nin": category_ids}}).to_list(length=1000)
        if products_with_name_cat and cat_name_to_id:
            print(f"📝 Migrating {len(products_with_name_cat)} products to use category IDs...")
            for p in products_with_name_cat:
                cat_name = p.get("category")
                if isinstance(cat_name, str) and cat_name in cat_name_to_id:
                    await product_collection.update_one(
                        {"_id": p["_id"]},
                        {"$set": {"category": cat_name_to_id[cat_name]}}
                    )
            print("✅ Migration done.")
        
        # 3. Seed a few products (only if none exist)
        existing_products = await product_collection.count_documents({})
        if existing_products > 0:
            print(f"💊 {existing_products} products already exist. Skipping product seed.")
        else:
            print("💊 Adding sample products...")
            product_list = [
                {"name": "Paracetamol 500mg Tablet", "desc": "Fever and pain relief", "base_price": 25.0},
                {"name": "Amoxicillin 250mg Capsule", "desc": "Antibiotic for bacterial infections", "base_price": 45.0},
                {"name": "Ibuprofen 400mg Tablet", "desc": "Anti-inflammatory pain relief", "base_price": 35.0},
                {"name": "Metformin 500mg Tablet", "desc": "Diabetes management", "base_price": 55.0},
                {"name": "Omeprazole 20mg Capsule", "desc": "Acid reflux and heartburn", "base_price": 42.0},
                {"name": "Cetirizine 10mg Tablet", "desc": "Allergy relief", "base_price": 18.0},
                {"name": "Vitamin C 1000mg Tablet", "desc": "Immunity and wellness", "base_price": 95.0},
                {"name": "Hand Sanitizer 200ml", "desc": "Alcohol-based sanitization", "base_price": 120.0},
                {"name": "Cough Syrup 100ml", "desc": "Dry cough relief", "base_price": 85.0},
                {"name": "Ashwagandha 500mg Tablet", "desc": "Ayurvedic stress relief", "base_price": 150.0},
            ]
            products = []
            manufacturers = ["Sun Pharma", "Lupin Ltd", "Cipla", "Dr. Reddy's", "Generic Pharma"]
            pack_sizes = ["10 Tablets/Strip", "15 Capsules/Strip", "100ml Bottle", "200ml Bottle"]
            for p in product_list:
                cat_id = random.choice(category_ids)
                prod_data = {
                    "name": p["name"],
                    "description": p["desc"],
                    "category": cat_id,
                    "moq": 1,
                    "dosage": p["name"].split()[-1] if "mg" in p["name"] else "N/A",
                    "manufacturer": random.choice(manufacturers),
                    "pack_size": random.choice(pack_sizes),
                    "pricing_tiers": {
                        "unit": round(p["base_price"], 2),
                        "1+ units": round(p["base_price"], 2),
                        "50+ units": round(p["base_price"] * 0.95, 2),
                        "100+ units": round(p["base_price"] * 0.9, 2),
                    },
                    "stock": random.randint(50, 500),
                    "images": [],
                    "is_active": True,
                    "created_at": datetime.utcnow(),
                    "updated_at": datetime.utcnow(),
                }
                products.append(prod_data)
            await product_collection.insert_many(products)
            print(f"✅ Added {len(products)} products.")
        
        print(f"✅ Seeding complete!")
        
    except Exception as e:
        print(f"❌ Error during seeding: {e}")
    finally:
        await database.disconnect()

if __name__ == "__main__":
    asyncio.run(seed_data())
