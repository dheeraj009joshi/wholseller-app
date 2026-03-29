# Wholeseller - Complete Setup Guide

## ✅ What's Been Implemented

### Backend (FastAPI + MongoDB)
- ✅ Complete REST API with all CRUD operations
- ✅ JWT Authentication & Authorization
- ✅ Azure Blob Storage integration for images
- ✅ Image upload with optimization
- ✅ Address management
- ✅ Cart management
- ✅ Order management
- ✅ Admin endpoints with role-based access

### Frontend (Flutter)
- ✅ All screens updated to use real API data
- ✅ Real-time data refresh (pull-to-refresh)
- ✅ Image upload for products (admin)
- ✅ Address management UI
- ✅ Dynamic cart with real-time updates
- ✅ Complete checkout flow with real data
- ✅ Order tracking with real data
- ✅ Admin dashboard with real statistics
- ✅ Admin product management with image upload
- ✅ Admin order management
- ✅ Admin user management

## 🚀 Quick Start

### 1. Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Setup environment variables
cp .env.example .env
# Edit .env with your MongoDB URL and Azure credentials (optional)

# Start MongoDB (if local)
# macOS: brew services start mongodb-community
# Or use MongoDB Atlas cloud

# Run backend
python run.py
```

Backend will run at `http://localhost:8000`
API docs at `http://localhost:8000/docs`

### 2. Flutter Setup

```bash
# Install dependencies
flutter pub get

# Update API base URL in lib/services/api_service.dart
# For Android emulator: http://10.0.2.2:8000/api
# For iOS simulator: http://localhost:8000/api
# For physical device: http://YOUR_COMPUTER_IP:8000/api

# Run app
flutter run
```

### 3. Create Admin User

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

Or use the Swagger UI at `http://localhost:8000/docs`

## 📱 Features

### User Features
- ✅ Register/Login with JWT authentication
- ✅ Browse products with search and category filters
- ✅ View product details with pricing tiers
- ✅ Add products to cart with quantity management
- ✅ Manage delivery addresses
- ✅ Complete checkout with order placement
- ✅ View order history with status tracking
- ✅ Update profile information

### Admin Features
- ✅ Dashboard with real-time statistics
- ✅ Product management (Create, Read, Update, Delete)
- ✅ Image upload for products (Azure Blob Storage)
- ✅ Order management with status updates
- ✅ User management with admin toggle
- ✅ View all orders with filtering

## 🔧 Configuration

### Azure Blob Storage (Optional)

1. Create Azure Storage Account
2. Get connection string from Azure Portal
3. Add to `.env`:
   ```
   AZURE_STORAGE_CONNECTION_STRING=your_connection_string
   AZURE_STORAGE_CONTAINER_NAME=wholeseller-images
   ```

If not configured, placeholder images will be used.

### API Base URL

Update in `lib/services/api_service.dart`:
- **Android Emulator**: `http://10.0.2.2:8000/api`
- **iOS Simulator**: `http://localhost:8000/api`
- **Physical Device**: `http://YOUR_COMPUTER_IP:8000/api`

## 📊 Data Flow

1. **Products**: Admin creates → Stored in MongoDB → Images uploaded to Azure → Displayed in app
2. **Cart**: User adds items → Stored in MongoDB → Real-time updates → Checkout
3. **Orders**: Created from cart → Stored in MongoDB → Admin manages status → User tracks
4. **Addresses**: User creates → Stored in user document → Used in checkout

## 🔄 Real-Time Updates

- Pull-to-refresh on all list screens
- Automatic refresh after mutations (create/update/delete)
- Real-time cart updates
- Order status updates reflected immediately

## 🎨 UI Features

- Material 3 design
- Cached network images for performance
- Loading states
- Error handling with user-friendly messages
- Empty states
- Pull-to-refresh
- Image carousels
- Form validation

## 📝 API Endpoints

All endpoints are documented at `http://localhost:8000/docs`

Key endpoints:
- `/api/auth/*` - Authentication
- `/api/products/*` - Products
- `/api/cart/*` - Shopping cart
- `/api/orders/*` - Orders
- `/api/addresses/*` - Addresses
- `/api/admin/*` - Admin operations

## 🐛 Troubleshooting

### Backend won't start
- Check MongoDB is running
- Verify `.env` file exists and has correct values
- Check port 8000 is not in use

### Images not uploading
- Verify Azure credentials in `.env`
- Check network connectivity
- Images will use placeholders if Azure not configured

### API connection errors
- Verify backend is running
- Check API base URL in `api_service.dart`
- For physical devices, ensure phone and computer are on same network

### Authentication issues
- Clear app data and re-login
- Check token expiration in backend logs
- Verify user exists in database

## 🎉 Everything is Now Dynamic!

- ✅ All data comes from MongoDB
- ✅ Images stored in Azure Blob Storage
- ✅ Real-time updates throughout the app
- ✅ Admin can manage everything
- ✅ Users can place real orders
- ✅ Complete end-to-end flow working

The app is now fully functional with real data!
