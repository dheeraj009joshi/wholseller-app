# Medical Store App - Architecture & Plan

## Overview
Scalable B2B/B2C medical store app for selling medicines online. Based on reference screens (RetailerShakti-style).

## Architecture

### Backend (FastAPI + MongoDB)
- **Auth**: JWT, register, login, token persistence
- **Products**: CRUD, categories, PTR/MRP, variants, offers, images
- **Cart**: Add/update/remove, quantity validation (MOQ)
- **Orders**: Create, list, status updates
- **Addresses**: User addresses for checkout
- **Admin**: Dashboard, users, orders, products, categories

### Frontend (Flutter)
- **Navigation**: Drawer (when logged in) + Bottom Nav (Home, Order History, Order Sheet, Account)
- **Screens**: Landing → Login/Register → MainScreen (with bottom nav)
- **Home**: Search, banners, categories, product sections
- **Product**: List, detail with variants, PTR/MRP, add to cart
- **Cart & Checkout**: Full flow with address
- **Orders**: History, status
- **Profile**: User info, Admin Dashboard (if admin), Addresses

## Data Model (Key Fields)

### Product
- name, description, category (id)
- ptr (Price to Retailer), mrp (Max Retail Price)
- variants: [{size: "450g", ptr: 448, mrp: 653}]
- offer: "BUY 5 GET 1 FREE" or discount %
- images, stock, expiry_date, manufacturer, dosage
- moq (default 1 for retail)

### Category
- name, description, is_active

## Scalability
- Singleton ApiService, shared token
- Modular routers, separation of concerns
- Reusable widgets
- Environment-based config (api_config.dart)
