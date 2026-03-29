# Wholeseller Backend API

FastAPI backend with MongoDB for the B2B wholesale marketplace application.

## Setup Instructions

### 1. Install MongoDB

Make sure MongoDB is installed and running on your system:

```bash
# macOS (using Homebrew)
brew install mongodb-community
brew services start mongodb-community

# Or use MongoDB Atlas (cloud) and update MONGODB_URL in .env
```

### 2. Install Python Dependencies

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 3. Configure Environment Variables

Create a `.env` file in the `backend` directory:

```bash
cp .env.example .env
```

Edit `.env` and update the values:

```
MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=wholeseller_db
SECRET_KEY=your-secret-key-change-this-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

### 4. Run the Server

```bash
python run.py
```

Or using uvicorn directly:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`

API documentation (Swagger UI) will be available at `http://localhost:8000/docs`

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user info

### Products
- `GET /api/products/` - Get all products (with optional category/search filters)
- `GET /api/products/{product_id}` - Get product details
- `POST /api/products/` - Create product (admin only)
- `PUT /api/products/{product_id}` - Update product (admin only)
- `DELETE /api/products/{product_id}` - Delete product (admin only)

### Cart
- `GET /api/cart/` - Get user's cart
- `POST /api/cart/items` - Add item to cart
- `PUT /api/cart/items/{product_id}` - Update cart item quantity
- `DELETE /api/cart/items/{product_id}` - Remove item from cart
- `DELETE /api/cart/` - Clear cart

### Orders
- `GET /api/orders/` - Get user's orders
- `GET /api/orders/{order_id}` - Get order details
- `POST /api/orders/` - Create order
- `PUT /api/orders/{order_id}` - Update order status (admin only)

### Users
- `GET /api/users/me` - Get current user
- `PUT /api/users/me` - Update current user

### Admin
- `GET /api/admin/dashboard/stats` - Get dashboard statistics
- `GET /api/admin/users` - Get all users
- `GET /api/admin/users/{user_id}` - Get user details
- `PUT /api/admin/users/{user_id}/toggle-admin` - Toggle user admin status
- `GET /api/admin/orders` - Get all orders (with optional status filter)
- `GET /api/admin/products` - Get all products (including inactive)

## Creating an Admin User

To create an admin user, you can either:

1. Use the API directly:
```bash
curl -X POST "http://localhost:8000/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "admin123",
    "name": "Admin User",
    "phone": "1234567890",
    "business_name": "Admin Business",
    "is_admin": true
  }'
```

2. Or manually update MongoDB:
```javascript
db.users.updateOne(
  { email: "user@example.com" },
  { $set: { is_admin: true } }
)
```

## Database Schema

### Users Collection
```javascript
{
  _id: ObjectId,
  email: String,
  name: String,
  password: String (hashed),
  phone: String,
  business_name: String,
  gst_number: String (optional),
  address: String (optional),
  city: String (optional),
  state: String (optional),
  pincode: String (optional),
  is_admin: Boolean,
  created_at: DateTime,
  updated_at: DateTime
}
```

### Products Collection
```javascript
{
  _id: ObjectId,
  name: String,
  description: String,
  category: String,
  moq: Number,
  images: [String],
  pricing_tiers: {
    "50+ units": Number,
    "100+ units": Number,
    "500+ units": Number
  },
  stock: Number,
  is_active: Boolean,
  created_at: DateTime,
  updated_at: DateTime
}
```

### Orders Collection
```javascript
{
  _id: ObjectId,
  user_id: String,
  items: [{
    product_id: String,
    product_name: String,
    quantity: Number,
    unit_price: Number,
    total_price: Number
  }],
  shipping_address: String,
  city: String,
  state: String,
  pincode: String,
  payment_method: String,
  subtotal: Number,
  shipping_cost: Number,
  total: Number,
  status: String (pending/processing/shipped/delivered/cancelled),
  created_at: DateTime,
  updated_at: DateTime
}
```

### Carts Collection
```javascript
{
  _id: ObjectId,
  user_id: String,
  items: [{
    product_id: String,
    product_name: String,
    product_image: String,
    quantity: Number,
    unit_price: Number,
    total_price: Number
  }],
  created_at: DateTime,
  updated_at: DateTime
}
```

## Testing

You can test the API using the Swagger UI at `http://localhost:8000/docs` or using curl/Postman.

Example login:
```bash
curl -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password123"}'
```

## Notes

- The API uses JWT tokens for authentication
- Tokens are sent in the `Authorization: Bearer <token>` header
- Admin endpoints require the user to have `is_admin: true`
- CORS is enabled for all origins (change in production)
