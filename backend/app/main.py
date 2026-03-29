from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import database
from app.routers import auth, products, orders, users, admin, cart, addresses, categories
from app.config import settings

app = FastAPI(title="Wholeseller API", version="1.0.0", debug=settings.debug)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins if not settings.debug else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(products.router, prefix="/api/products", tags=["products"])
app.include_router(orders.router, prefix="/api/orders", tags=["orders"])
app.include_router(users.router, prefix="/api/users", tags=["users"])
app.include_router(cart.router, prefix="/api/cart", tags=["cart"])
app.include_router(admin.router, prefix="/api/admin", tags=["admin"])
app.include_router(addresses.router, prefix="/api/addresses", tags=["addresses"])
app.include_router(categories.router, prefix="/api/categories", tags=["categories"])


@app.on_event("startup")
async def startup_db_client():
    await database.connect()


@app.on_event("shutdown")
async def shutdown_db_client():
    await database.disconnect()


@app.get("/")
async def root():
    return {"message": "Wholeseller API", "version": "1.0.0"}


@app.get("/api/health")
async def health_check():
    return {"status": "healthy"}
