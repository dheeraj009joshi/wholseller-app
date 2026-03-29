from fastapi import APIRouter, Depends, HTTPException, status
from app.models.cart import CartResponse, CartItemCreate, CartItemUpdate
from app.database import database
from app.auth import get_current_user
from bson import ObjectId
from datetime import datetime

router = APIRouter()


async def get_or_create_cart(user_id: str) -> dict:
    cart_collection = database.get_collection("carts")
    cart = await cart_collection.find_one({"user_id": user_id})

    if not cart:
        cart = {
            "user_id": user_id,
            "items": [],
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        result = await cart_collection.insert_one(cart)
        cart["_id"] = result.inserted_id

    return cart


def calculate_cart_totals(items: list) -> dict:
    subtotal = sum(item.get("total_price", 0) for item in items)
    shipping_cost = 500.0 if subtotal > 0 else 0.0
    total = subtotal + shipping_cost
    return {"subtotal": subtotal, "shipping_cost": shipping_cost, "total": total}


@router.get("/", response_model=CartResponse)
async def get_cart(current_user: dict = Depends(get_current_user)):
    cart = await get_or_create_cart(str(current_user["_id"]))
    totals = calculate_cart_totals(cart.get("items", []))

    return CartResponse(
        user_id=cart["user_id"],
        items=cart.get("items", []),
        **totals
    )


@router.post("/items", response_model=CartResponse)
async def add_to_cart(
    item_data: CartItemCreate,
    current_user: dict = Depends(get_current_user)
):
    cart_collection = database.get_collection("carts")
    product_collection = database.get_collection("products")

    # Get product details
    if not ObjectId.is_valid(item_data.product_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid product ID")

    product = await product_collection.find_one({"_id": ObjectId(item_data.product_id)})
    if not product or not product.get("is_active", False):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    # MOQ Enforcement Removed per user request
    # if item_data.quantity < product.get("moq", 1):
    #     raise HTTPException(
    #         status_code=status.HTTP_400_BAD_REQUEST,
    #         detail=f"Minimum order quantity is {product.get('moq', 1)} units"
    #     )

    # Calculate price based on pricing tiers
    pricing_tiers = product.get("pricing_tiers", {})
    unit_price = 0.0
    if pricing_tiers:
        # Handle "unit", "1+ units", "50+ units" etc.
        tier_pairs = []
        for tier_key, price in pricing_tiers.items():
            key = str(tier_key).strip()
            try:
                if "+" in key:
                    min_qty = int(key.split("+")[0].strip())
                elif key.lower() == "unit":
                    min_qty = 1
                else:
                    min_qty = int(key)
                tier_pairs.append((min_qty, float(price)))
            except (ValueError, IndexError):
                if key.lower() == "unit":
                    tier_pairs.append((1, float(price)))
        tier_pairs.sort(key=lambda x: x[0], reverse=True)
        for min_qty, price in tier_pairs:
            if item_data.quantity >= min_qty:
                unit_price = price
                break
        if unit_price == 0 and tier_pairs:
            unit_price = tier_pairs[-1][1]  # Use lowest tier as fallback

    total_price = unit_price * item_data.quantity

    cart = await get_or_create_cart(str(current_user["_id"]))

    # Check if item already exists in cart
    items = cart.get("items", [])
    item_exists = False
    for item in items:
        if item["product_id"] == item_data.product_id:
            item["quantity"] = item_data.quantity
            item["unit_price"] = unit_price
            item["total_price"] = total_price
            item_exists = True
            break

    if not item_exists:
        items.append({
            "product_id": item_data.product_id,
            "product_name": product["name"],
            "product_image": product.get("images", [""])[0] if product.get("images") else None,
            "quantity": item_data.quantity,
            "unit_price": unit_price,
            "total_price": total_price
        })

    await cart_collection.update_one(
        {"user_id": str(current_user["_id"])},
        {"$set": {"items": items, "updated_at": datetime.utcnow()}}
    )

    totals = calculate_cart_totals(items)
    return CartResponse(user_id=str(current_user["_id"]), items=items, **totals)


@router.put("/items/{product_id}", response_model=CartResponse)
async def update_cart_item(
    product_id: str,
    item_data: CartItemUpdate,
    current_user: dict = Depends(get_current_user)
):
    cart_collection = database.get_collection("carts")
    product_collection = database.get_collection("products")

    cart = await get_or_create_cart(str(current_user["_id"]))
    items = cart.get("items", [])

    # Find and update item
    item_found = False
    for item in items:
        if item["product_id"] == product_id:
            # Get product to recalculate price
            product = await product_collection.find_one({"_id": ObjectId(product_id)})
            if not product:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

            # MOQ Enforcement Removed per user request
            # if item_data.quantity < product.get("moq", 1):
            #     raise HTTPException(
            #         status_code=status.HTTP_400_BAD_REQUEST,
            #         detail=f"Minimum order quantity is {product.get('moq', 1)} units"
            #     )

            # Recalculate price
            pricing_tiers = product.get("pricing_tiers", {})
            unit_price = 0.0
            if pricing_tiers:
                tier_pairs = []
                for tier_key, price in pricing_tiers.items():
                    key = str(tier_key).strip()
                    try:
                        if "+" in key:
                            min_qty = int(key.split("+")[0].strip())
                        elif key.lower() == "unit":
                            min_qty = 1
                        else:
                            min_qty = int(key)
                        tier_pairs.append((min_qty, float(price)))
                    except (ValueError, IndexError):
                        if key.lower() == "unit":
                            tier_pairs.append((1, float(price)))
                tier_pairs.sort(key=lambda x: x[0], reverse=True)
                for min_qty, price in tier_pairs:
                    if item_data.quantity >= min_qty:
                        unit_price = price
                        break
                if unit_price == 0 and tier_pairs:
                    unit_price = tier_pairs[-1][1]

            item["quantity"] = item_data.quantity
            item["unit_price"] = unit_price
            item["total_price"] = unit_price * item_data.quantity
            item_found = True
            break

    if not item_found:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item not found in cart")

    await cart_collection.update_one(
        {"user_id": str(current_user["_id"])},
        {"$set": {"items": items, "updated_at": datetime.utcnow()}}
    )

    totals = calculate_cart_totals(items)
    return CartResponse(user_id=str(current_user["_id"]), items=items, **totals)


@router.delete("/items/{product_id}", response_model=CartResponse)
async def remove_from_cart(product_id: str, current_user: dict = Depends(get_current_user)):
    cart_collection = database.get_collection("carts")

    cart = await get_or_create_cart(str(current_user["_id"]))
    items = [item for item in cart.get("items", []) if item["product_id"] != product_id]

    await cart_collection.update_one(
        {"user_id": str(current_user["_id"])},
        {"$set": {"items": items, "updated_at": datetime.utcnow()}}
    )

    totals = calculate_cart_totals(items)
    return CartResponse(user_id=str(current_user["_id"]), items=items, **totals)


@router.delete("/", response_model=CartResponse)
async def clear_cart(current_user: dict = Depends(get_current_user)):
    cart_collection = database.get_collection("carts")

    await cart_collection.update_one(
        {"user_id": str(current_user["_id"])},
        {"$set": {"items": [], "updated_at": datetime.utcnow()}}
    )

    return CartResponse(user_id=str(current_user["_id"]), items=[], subtotal=0.0, shipping_cost=0.0, total=0.0)
