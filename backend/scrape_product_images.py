#!/usr/bin/env python3
"""
Scrape 3-4 product images per medicine, upload to Azure, and reseed DB with:
- 5 categories only
- 3-4 products per category (15-20 total)
- Each product has 3-4 image URLs (downloaded then uploaded to Azure).

Uses Pexels API if PEXELS_API_KEY is set (medicine-themed images), else picsum.photos placeholders.
Requires: AZURE_STORAGE_CONNECTION_STRING for uploads; MONGODB_URL for DB.
"""
import asyncio
import os
import hashlib
import random
import time
from datetime import datetime, timezone
from typing import List, Optional

import requests
from dotenv import load_dotenv

load_dotenv()

# Add app to path when running as script
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.database import database
from app.azure_storage import upload_image_to_azure
from app.config import settings


# --- 5 categories, 3-4 products per category ---
# image_url: picsum seed from name; icon: Material icon name for fallback
CATEGORIES = [
    {"name": "Ayurvedic & Herbal", "description": "Natural and holistic wellness", "icon": "eco"},
    {"name": "Cardiac Care", "description": "Heart health and blood pressure", "icon": "favorite"},
    {"name": "Diabetes Care", "description": "Glucose monitoring and management", "icon": "monitor_heart"},
    {"name": "Digestive Health", "description": "Gastric and digestive care", "icon": "restaurant"},
    {"name": "Vitamins & Supplements", "description": "Daily health and immunity", "icon": "medication"},
]

PRODUCTS_BY_CATEGORY = {
    "Ayurvedic & Herbal": [
        {"name": "Ashwagandha 500mg Tablet", "description": "Stress relief and vitality", "base_price": 180},
        {"name": "Triphala Churna 100g", "description": "Digestive and detox support", "base_price": 120},
        {"name": "Giloy 500mg Tablet", "description": "Immunity and fever support", "base_price": 95},
        {"name": "Turmeric Curcumin 500mg", "description": "Anti-inflammatory wellness", "base_price": 220},
    ],
    "Cardiac Care": [
        {"name": "Aspirin 75mg Tablet", "description": "Blood thinner, heart care", "base_price": 35},
        {"name": "Atorvastatin 10mg Tablet", "description": "Cholesterol management", "base_price": 85},
        {"name": "Amlodipine 5mg Tablet", "description": "Blood pressure control", "base_price": 42},
        {"name": "Metoprolol 25mg Tablet", "description": "Heart rate and BP management", "base_price": 55},
    ],
    "Diabetes Care": [
        {"name": "Metformin 500mg Tablet", "description": "Blood sugar management", "base_price": 48},
        {"name": "Glimepiride 2mg Tablet", "description": "Type 2 diabetes support", "base_price": 65},
        {"name": "Glucometer Strips 50s", "description": "Blood glucose testing", "base_price": 320},
    ],
    "Digestive Health": [
        {"name": "Omeprazole 20mg Capsule", "description": "Acid reflux and heartburn", "base_price": 45},
        {"name": "Pantoprazole 40mg Tablet", "description": "Stomach acid reducer", "base_price": 52},
        {"name": "Dicyclomine 10mg Tablet", "description": "Irritable bowel relief", "base_price": 38},
        {"name": "Digene Gel 150ml", "description": "Antacid and digestive", "base_price": 65},
    ],
    "Vitamins & Supplements": [
        {"name": "Vitamin D3 60K IU Capsule", "description": "Bone and immunity support", "base_price": 95},
        {"name": "Vitamin B Complex Tablet", "description": "Energy and metabolism", "base_price": 75},
        {"name": "Multivitamin Daily Tablet", "description": "Complete daily nutrition", "base_price": 110},
        {"name": "Calcium + Vitamin D Tablet", "description": "Bone strength", "base_price": 88},
    ],
}

MANUFACTURERS = ["Sun Pharma", "Lupin Ltd", "Cipla", "Dr. Reddy's", "Zydus"]
PACK_SIZES = ["10 Tablets/Strip", "15 Capsules/Strip", "30 Tablets/Bottle", "100ml Bottle"]


def fetch_image_urls_pexels(query: str, count: int = 4) -> List[str]:
    """Fetch image URLs from Pexels API (medicine-themed). Returns list of URL strings."""
    api_key = os.getenv("PEXELS_API_KEY", "").strip()
    if not api_key:
        return []
    url = "https://api.pexels.com/v1/search"
    headers = {"Authorization": api_key}
    params = {"query": query, "per_page": min(count, 15)}
    try:
        r = requests.get(url, headers=headers, params=params, timeout=10)
        r.raise_for_status()
        data = r.json()
        urls = []
        for p in data.get("photos", [])[:count]:
            # Prefer medium size for faster download
            u = p.get("src", {}).get("medium") or p.get("src", {}).get("large") or p.get("src", {}).get("original")
            if u:
                urls.append(u)
        return urls
    except Exception as e:
        print(f"   Pexels API error: {e}")
        return []


def fetch_image_urls_picsum(product_name: str, count: int = 4) -> List[str]:
    """Fallback: deterministic placeholder image URLs from picsum.photos (no API key)."""
    seed = hashlib.md5(product_name.encode()).hexdigest()[:8]
    return [f"https://picsum.photos/seed/{seed}{i}/600/600" for i in range(count)]


def download_image_bytes(url: str) -> Optional[bytes]:
    """Download image from URL; returns bytes or None."""
    try:
        r = requests.get(url, timeout=15, headers={"User-Agent": "WholesellerScraper/1.0"})
        r.raise_for_status()
        return r.content
    except Exception as e:
        print(f"   Download failed {url[:50]}...: {e}")
        return None


async def get_product_image_urls(product_name: str, category_name: str, count: int = 4) -> List[str]:
    """
    Get 3-4 image URLs for a product. Try Pexels first (medicine/pharmacy query), else picsum.
    Then download each image and upload to Azure; return list of Azure blob URLs.
    """
    # Prefer medicine-themed search for first category term
    search_query = "medicine pill" if "Ayurvedic" in category_name or "Vitamin" in category_name else "pharmacy medicine"
    urls = fetch_image_urls_pexels(search_query, count=count)
    if not urls:
        urls = fetch_image_urls_picsum(product_name, count=count)

    uploaded = []
    for i, img_url in enumerate(urls[:count]):
        content = download_image_bytes(img_url)
        if not content or len(content) < 500:
            continue
        # Upload to Azure (or use source URL when Azure not configured)
        ext = "jpg"
        filename = f"{hashlib.md5((product_name + str(i)).encode()).hexdigest()[:12]}.{ext}"
        azure_url = await upload_image_to_azure(content, filename, folder="products")
        if azure_url and "via.placeholder.com" not in azure_url:
            uploaded.append(azure_url)
        else:
            # Azure not configured: store the actual image URL we downloaded from (picsum/Pexels)
            uploaded.append(img_url)
        time.sleep(0.3)  # Be nice to external servers
    return uploaded


async def run():
    print("🔄 Connecting to MongoDB...")
    await database.connect()

    category_collection = database.get_collection("categories")
    product_collection = database.get_collection("products")

    # --- 1. Remove all existing products and categories ---
    print("🗑️  Removing existing products and categories...")
    await product_collection.delete_many({})
    await category_collection.delete_many({})
    print("   Done.")

    # --- 2. Insert 5 categories (with image_url and icon) ---
    print("📁 Inserting 5 categories...")
    cat_id_by_name = {}
    for c in CATEGORIES:
        seed = hashlib.md5(c["name"].encode()).hexdigest()[:10]
        image_url = f"https://picsum.photos/seed/{seed}/200/200"
        doc = {
            "name": c["name"],
            "description": c.get("description", ""),
            "is_active": True,
            "image_url": image_url,
            "icon": c.get("icon"),
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc),
        }
        r = await category_collection.insert_one(doc)
        cat_id_by_name[c["name"]] = str(r.inserted_id)
    print(f"   Inserted {len(CATEGORIES)} categories (with image_url + icon).")

    # --- 3. Insert products (3-4 per category) and attach 3-4 images each ---
    total_products = 0
    for cat_name, products in PRODUCTS_BY_CATEGORY.items():
        cat_id = cat_id_by_name[cat_name]
        for p in products:
            print(f"   Product: {p['name']} ...", end=" ")
            # Fetch 3-4 images: download + upload to Azure
            image_urls = await get_product_image_urls(p["name"], cat_name, count=4)
            print(f" {len(image_urls)} images")

            doc = {
                "name": p["name"],
                "description": p["description"],
                "category": cat_id,
                "moq": 1,
                "images": image_urls,
                "pricing_tiers": {
                    "unit": round(p["base_price"], 2),
                    "1+ units": round(p["base_price"], 2),
                    "50+ units": round(p["base_price"] * 0.95, 2),
                    "100+ units": round(p["base_price"] * 0.9, 2),
                },
                "stock": random.randint(50, 300),
                "variants": [],
                "dosage": next((w for w in p["name"].split() if "mg" in w or "IU" in w), None),
                "manufacturer": random.choice(MANUFACTURERS),
                "pack_size": random.choice(PACK_SIZES),
                "is_active": True,
                "created_at": datetime.now(timezone.utc),
                "updated_at": datetime.now(timezone.utc),
            }
            await product_collection.insert_one(doc)
            total_products += 1

    print(f"✅ Done. {len(CATEGORIES)} categories, {total_products} products with scraped images.")
    await database.disconnect()


if __name__ == "__main__":
    if not os.getenv("AZURE_STORAGE_CONNECTION_STRING"):
        print("⚠️  AZURE_STORAGE_CONNECTION_STRING not set: image URLs will be placeholders (see app/azure_storage.py).")
    if not os.getenv("PEXELS_API_KEY"):
        print("ℹ️  PEXELS_API_KEY not set: using picsum.photos placeholder images (get free key at pexels.com/api).")
    asyncio.run(run())
