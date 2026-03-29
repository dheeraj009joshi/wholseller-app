import 'package:flutter/material.dart';
import 'package:wholeseller/theme/app_theme.dart';
import 'package:wholeseller/screens/product_listing_screen.dart';
import 'package:wholeseller/screens/product_detail_screen.dart';
import 'package:wholeseller/screens/cart_screen.dart';
import 'package:wholeseller/services/api_service.dart';

import 'package:wholeseller/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  String? _userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadUser(),
      _loadProducts(),
      _loadCategories(),
    ]);
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (mounted && user != null) {
        setState(() {
          _userName = user['name'];
        });
      }
    } catch (_) {}
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _apiService.getProducts();
      setState(() {
        _products = products.take(6).toList();
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories(activeOnly: true);
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, ${_userName ?? 'User'} 👋', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        const SizedBox(height: 4),
                        const Text('MediCare', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none),
                          onPressed: () {},
                        ),
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.shopping_bag_outlined),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
                              },
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: AppTheme.errorColor, shape: BoxShape.circle),
                                child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 10)),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search medicines, health products...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductListingScreen()));
                  },
                ),
                const SizedBox(height: 24),

                // Health Tip Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Health Tip of the Day', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 8),
                            const Text('Stay Hydrated! 💧', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Drink at least 8 glasses of water daily for optimal health.', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.water_drop, color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Shop by Health Concern
                const Text('Shop by Health Concern', style: AppTheme.titleLarge),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildConcernItem('Diabetes', 'assets/diabetes.png', Icons.bloodtype, Colors.red),
                      _buildConcernItem('Heart Care', 'assets/heart.png', Icons.favorite, Colors.pink),
                      _buildConcernItem('Stomach', 'assets/stomach.png', Icons.spa, Colors.green),
                      _buildConcernItem('Skin Care', 'assets/skin.png', Icons.face, Colors.orange),
                      _buildConcernItem('Baby Care', 'assets/baby.png', Icons.child_care, Colors.blue),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Categories
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Shop by Category', style: AppTheme.titleLarge),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductListingScreen()));
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_categories.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        IconData icon = Icons.medication;
                        if (category['name'].toString().toLowerCase().contains('pain')) icon = Icons.healing;
                        if (category['name'].toString().toLowerCase().contains('vitamin')) icon = Icons.local_pharmacy;
                        if (category['name'].toString().toLowerCase().contains('skin')) icon = Icons.face;
                        if (category['name'].toString().toLowerCase().contains('device')) icon = Icons.monitor_heart;

                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (c) => ProductListingScreen(categoryId: category['id'], categoryName: category['name'])));
                            },
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                  child: Icon(icon, color: AppTheme.primaryColor, size: 28),
                                ),
                                const SizedBox(height: 8),
                                Text(category['name'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),

                // Featured Medicines
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_offer, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        const Text('Popular Medicines', style: AppTheme.titleLarge),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductListingScreen()));
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.78,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final images = product['images'] as List<dynamic>?;
                          final imageUrl = images != null && images.isNotEmpty ? images[0] as String : '';
                          final price = (product['pricing_tiers'] as Map<String, dynamic>?)?.values.first ?? 0;

                          return Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(productId: product['id'])));
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      child: imageUrl.isNotEmpty
                                          ? Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => _placeholder())
                                          : _placeholder(),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(product['name'] ?? 'Medicine', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text('₹${(price as num).toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 15)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildConcernItem(String label, String assetPath, IconData fallbackIcon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: InkWell(
        onTap: () {
           // For now, just go to product listing with search
           Navigator.push(context, MaterialPageRoute(builder: (c) => const ProductListingScreen()));
        },
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(fallbackIcon, color: color, size: 30),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(child: Icon(Icons.medication, size: 40, color: Colors.grey)),
    );
  }
}
