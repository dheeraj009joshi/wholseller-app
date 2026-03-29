# Wholeseller - B2B Wholesale Marketplace

A complete B2B wholesale marketplace application with Flutter frontend and FastAPI backend.

## Project Structure

```
wholeseller/
├── lib/                    # Flutter application code
│   ├── main.dart
│   ├── screens/           # UI screens
│   │   ├── admin/         # Admin screens
│   │   └── ...            # User screens
│   ├── widgets/           # Reusable widgets
│   ├── services/          # API services
│   └── theme/             # App theme
├── backend/               # FastAPI backend
│   ├── app/
│   │   ├── main.py        # FastAPI app
│   │   ├── database.py    # MongoDB connection
│   │   ├── auth.py        # Authentication logic
│   │   ├── models/        # Pydantic models
│   │   └── routers/       # API routes
│   ├── requirements.txt
│   └── README.md
└── pubspec.yaml
```

## Features

### User Features
- User registration and authentication
- Product browsing and search
- Shopping cart management
- Order placement and tracking
- User profile management

### Admin Features
- Admin dashboard with statistics
- Product management (CRUD)
- Order management and status updates
- User management
- Admin access control

## Getting Started

### Backend Setup

1. **Install MongoDB**
   ```bash
   # macOS
   brew install mongodb-community
   brew services start mongodb-community
   ```

2. **Setup Python Environment**
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate  # Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

3. **Configure Environment**
   ```bash
   cp .env.example .env
   # Edit .env with your MongoDB URL and secret key
   ```

4. **Run Backend**
   ```bash
   python run.py
   ```
   API will be available at `http://localhost:8000`
   API docs at `http://localhost:8000/docs`

### Flutter Setup

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Update API Base URL**
   Edit `lib/services/api_service.dart` and update the `baseUrl` if needed:
   ```dart
   static const String baseUrl = 'http://localhost:8000/api';
   ```
   
   For Android emulator, use: `http://10.0.2.2:8000/api`
   For iOS simulator, use: `http://localhost:8000/api`
   For physical device, use your computer's IP: `http://192.168.x.x:8000/api`

3. **Run Flutter App**
   ```bash
   flutter run
   ```

## Creating Admin User

After starting the backend, create an admin user:

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

Or manually update MongoDB:
```javascript
db.users.updateOne(
  { email: "user@example.com" },
  { $set: { is_admin: true } }
)
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register
- `POST /api/auth/login` - Login
- `GET /api/auth/me` - Get current user

### Products
- `GET /api/products/` - List products
- `GET /api/products/{id}` - Get product
- `POST /api/products/` - Create product (admin)
- `PUT /api/products/{id}` - Update product (admin)
- `DELETE /api/products/{id}` - Delete product (admin)

### Cart
- `GET /api/cart/` - Get cart
- `POST /api/cart/items` - Add to cart
- `PUT /api/cart/items/{id}` - Update cart item
- `DELETE /api/cart/items/{id}` - Remove from cart

### Orders
- `GET /api/orders/` - Get orders
- `POST /api/orders/` - Create order
- `PUT /api/orders/{id}` - Update order (admin)

### Admin
- `GET /api/admin/dashboard/stats` - Dashboard stats
- `GET /api/admin/users` - All users
- `GET /api/admin/orders` - All orders
- `GET /api/admin/products` - All products
- `PUT /api/admin/users/{id}/toggle-admin` - Toggle admin

## Technology Stack

### Frontend
- Flutter
- Material 3 Design
- HTTP for API calls
- SharedPreferences for local storage

### Backend
- FastAPI
- MongoDB with Motor (async driver)
- JWT authentication
- Pydantic for data validation

## Development Notes

- The app uses JWT tokens for authentication
- Admin endpoints require `is_admin: true` in user document
- CORS is enabled for all origins (change in production)
- All prices are in INR (₹)

## Next Steps

- Update Flutter screens to use API instead of dummy data
- Add image upload functionality
- Implement push notifications
- Add payment gateway integration
- Deploy to production
# wholseller-app
