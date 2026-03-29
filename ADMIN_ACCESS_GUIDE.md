# Medical Store App - Complete Guide

## 🚀 Quick Start

### 1. Backend Server
The backend is already running! You can verify by checking:
```bash
curl http://localhost:8000/api/health
```

If you need to restart it:
```bash
cd backend
python run.py
```

The backend runs on: **http://localhost:8000**

### 2. Flutter App
Run the Flutter app:
```bash
# For web (Chrome)
flutter run -d chrome

# For Android emulator
flutter run -d android

# For iOS simulator
flutter run -d ios
```

---

## 🌱 Seed Sample Products

If you see "No products found", run the seed script to add categories and sample products:

```bash
cd backend
source venv/bin/activate
python seed_data.py
```

This adds 5 categories and 10 sample medicines. To create an admin user, run `python create_admin.py` and log in with that account to access the Admin Dashboard.

---

## 📱 App Navigation

- **Hamburger Menu (drawer)**: Tap the ☰ icon on any screen to open
  - Choose Location → Address list
  - Cart → Shopping cart
  - My Orders → Order history
  - Categories → Product listing
  - Admin Dashboard (visible only for admin users)
  - Account → Profile
  - Logout

- **Bottom Navigation**: Home | Order History | Order Sheet | Account

- **User Flow**: Login → Home (categories + products) → Product Detail → Add to Cart → Checkout → Place Order

---

## 👤 Creating an Admin User

You have **3 options** to create an admin user:

### Option 1: Using the Helper Script (Recommended)
```bash
cd backend
python create_admin.py
```

Follow the prompts to enter:
- Email
- Password (min 6 characters)
- Name
- Phone
- Business Name

### Option 2: Using API (with is_admin flag)
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

### Option 3: Update Existing User via MongoDB
If you already have a user account, you can make them admin:
```bash
# Connect to MongoDB (adjust connection string as needed)
mongosh

# Then run:
use wholeseller_db
db.users.updateOne(
  { email: "your-email@example.com" },
  { $set: { is_admin: true } }
)
```

---

## 🔐 Accessing the Admin Panel

### Step 1: Login as Admin
1. Open the Flutter app
2. Go to **Login** screen
3. Enter your admin email and password
4. Click **Login**

### Step 2: Navigate to Admin Dashboard
Once logged in:
1. Tap the **Profile** icon (person icon) in the top right
2. Scroll down to see **"Admin Dashboard"** option (only visible for admin users)
3. Tap **"Admin Dashboard"**

### Alternative: Direct Navigation
If you're already logged in as admin, you can also access via:
- Profile Screen → Admin Dashboard menu item

---

## 📋 Admin Panel Features

The Admin Dashboard provides:

### 1. **Dashboard Overview**
- Total Users
- Total Products
- Total Orders
- Total Revenue

### 2. **Quick Actions**
- **Products** - Manage all products
- **Orders** - View and manage all orders
- **Users** - Manage users and toggle admin status
- **Categories** - Create and manage product categories

### 3. **Product Management**
- Create new products
- Edit existing products
- Delete products
- Upload product images
- Set pricing tiers, MOQ, stock

### 4. **Category Management**
- Create categories
- Edit categories
- Delete categories (if no products use them)
- View active/inactive categories

### 5. **Order Management**
- View all orders
- Filter orders by status
- Update order status
- View order details

### 6. **User Management**
- View all users
- Toggle admin status for users
- View user details

---

## 🛠️ Troubleshooting

### Backend Not Running?
```bash
cd backend
python run.py
```

### Can't See Admin Dashboard?
1. Verify you're logged in as admin:
   - Check Profile screen - you should see "Admin Dashboard" option
2. If not visible:
   - Your user might not have `is_admin: true` in database
   - Use one of the methods above to create/update admin user

### Token Issues?
- The app automatically loads tokens on startup
- If you get "Not authenticated" errors:
  - Logout and login again
  - Check backend is running
  - Verify token in SharedPreferences (for debugging)

---

## 📱 Testing the Complete Flow

### As Admin:
1. ✅ Login with admin credentials
2. ✅ Access Admin Dashboard from Profile
3. ✅ Create a category
4. ✅ Create a product with that category
5. ✅ Upload product images
6. ✅ View orders and update status

### As Regular User:
1. ✅ Register/Login
2. ✅ Browse products by category
3. ✅ Add products to cart
4. ✅ Checkout with address
5. ✅ View order history

---

## 🔗 API Endpoints

### Admin Endpoints (require admin token):
- `GET /api/admin/dashboard/stats` - Dashboard statistics
- `GET /api/admin/users` - Get all users
- `GET /api/admin/orders` - Get all orders
- `GET /api/admin/products` - Get all products
- `POST /api/categories/` - Create category
- `PUT /api/categories/{id}` - Update category
- `DELETE /api/categories/{id}` - Delete category
- `POST /api/products/` - Create product
- `PUT /api/products/{id}` - Update product
- `DELETE /api/products/{id}` - Delete product

---

## 📝 Notes

- Admin users see the "Admin Dashboard" option in Profile screen
- Regular users don't see admin options
- All admin operations require authentication token
- Categories must be created before products can use them
- Products reference category IDs (not names)

---

**Happy Admin-ing! 🎉**
