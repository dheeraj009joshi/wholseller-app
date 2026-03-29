import 'package:flutter/material.dart';
import 'package:wholeseller/theme/app_theme.dart';
import 'package:wholeseller/services/api_service.dart';
import 'package:wholeseller/screens/product_detail_screen.dart';
import 'package:wholeseller/screens/cart_screen.dart';
import 'package:wholeseller/screens/product_listing_screen.dart';
import 'package:wholeseller/screens/notifications_screen.dart';
import 'package:wholeseller/screens/profile/address_list_screen.dart';
import 'package:wholeseller/widgets/reference_product_card.dart';
import 'package:wholeseller/widgets/drawer_scope.dart';

IconData _categoryIcon(String? name) {
  const map = <String, IconData>{
    'medication': Icons.medication,
    'favorite': Icons.favorite,
    'eco': Icons.eco,
    'restaurant': Icons.restaurant,
    'monitor_heart': Icons.monitor_heart,
    'spa': Icons.spa,
    'local_hospital': Icons.local_hospital,
    'category': Icons.category,
  };
  return map[name ?? ''] ?? Icons.category;
}

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  Map<String, int> _cartQuantities = {};
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (mounted) setState(() => _errorMessage = null);
    await Future.wait([_loadData(), _loadCart(), _loadCategories()]);
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories(activeOnly: true);
      if (mounted) setState(() {
        _categories = categories;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('Home: load categories failed: $e');
      if (mounted) setState(() {
        _categories = [];
        _errorMessage = _errorMessage ?? 'Could not load categories. Check connection and retry.';
      });
    }
  }

  Future<void> _loadCart() async {
    try {
      final cart = await _apiService.getCart();
      final Map<String, int> quantities = {};
      for (var item in cart['items']) {
        quantities[item['product_id']] = item['quantity'] as int;
      }
      if (mounted) {
        setState(() => _cartQuantities = quantities);
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final products = await _apiService.getProducts(
        search: _searchController.text,
      );
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Home: load products failed: $e');
      if (mounted) setState(() {
        _isLoading = false;
        _products = [];
        _errorMessage = _errorMessage ?? 'Could not load products. Check connection and retry.';
      });
    }
  }

  Future<void> _updateQuantity(String productId, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        await _apiService.removeFromCart(productId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from cart'), backgroundColor: AppTheme.successColor),
          );
        }
      } else {
        try {
          await _apiService.updateCartItem(productId, newQuantity);
        } catch (e) {
          await _apiService.addToCart(productId, newQuantity);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newQuantity == 1 ? 'Added to cart!' : 'Cart updated'),
              backgroundColor: AppTheme.greenColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      _loadCart();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception:', '').trim()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _categoryImageOrIcon(Map<String, dynamic> cat) {
    final imageUrl = cat['image_url'] as String?;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(_categoryIcon(cat['icon'] as String?), color: AppTheme.primaryColor, size: 28),
      );
    }
    return Icon(_categoryIcon(cat['icon'] as String?), color: AppTheme.primaryColor, size: 28);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B)),
          onPressed: () => DrawerScope.of(context).openDrawer(),
        ),
        title: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AddressListScreen())),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Deliver to', style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Row(
                children: [
                  const Text('Home, 123401', style: TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.bold)),
                  Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor, size: 18),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B), size: 20),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const NotificationsScreen())),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryColor, size: 20),
                ),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const CartScreen())).then((_) => _loadCart()),
              ),
              if (_cartQuantities.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFFEF4444), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text('${_cartQuantities.length}', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Search Bar Section
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _loadData(),
                  decoration: InputDecoration(
                    hintText: 'Search for Medicine, Health Products...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () { _searchController.clear(); _loadData(); })
                        : Icon(Icons.mic_none_rounded, color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.05))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.05))),
                  ),
                ),
              ),
            ),

            // Hero Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: AppTheme.primaryColor.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Ink.image(
                            image: const NetworkImage('https://img.freepik.com/premium-photo/science-medical-healthcare-concept-doctor-working-with-digital-medicine-interface-virtual-screen_31965-17684.jpg'),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(AppTheme.primaryColor.withOpacity(0.8), BlendMode.srcOver),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                          child: FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('UPTO 50% OFF', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                ),
                                const SizedBox(height: 8),
                                const Text('Premium Healthcare\nAt Your Doorstep', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.1)),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProductListingScreen())),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.primaryColor,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  ),
                                  child: const Text('Order Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Error banner (connection / load failure)
            if (_errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Material(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.orange.shade800, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                            ),
                          ),
                          TextButton(
                            onPressed: _refresh,
                            child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Shop by Categories (always show section)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Shop by Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 112,
                      child: _categories.isEmpty
                          ? Center(
                              child: Text(
                                _errorMessage != null ? 'Categories could not be loaded.' : 'No categories yet.',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _categories.length,
                              itemBuilder: (context, i) {
                                final cat = _categories[i];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: InkWell(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ProductListingScreen(categoryId: cat['id'], categoryName: cat['name']))),
                                    child: SizedBox(
                                      width: 80,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 64,
                                            height: 64,
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: _categoryImageOrIcon(cat),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            height: 32,
                                            width: 80,
                                            child: Text(
                                              cat['name'] ?? '',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Product Grid Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Top Products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProductListingScreen())),
                      child: const Text('View All', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

            // Product Grid
            _isLoading
                ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                : _products.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage != null ? 'Products could not be loaded.' : 'No products yet.',
                                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                                  textAlign: TextAlign.center,
                                ),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 12),
                                  TextButton.icon(
                                    onPressed: _refresh,
                                    icon: const Icon(Icons.refresh_rounded, size: 20),
                                    label: const Text('Retry'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.58,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = _products[index];
                              final productId = product['id'] as String;
                              return ReferenceProductCard(
                                product: product,
                                initialQuantity: _cartQuantities[productId] ?? 0,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ProductDetailScreen(productId: productId))).then((_) => _loadCart()),
                                onUpdateQuantity: (qty) => _updateQuantity(productId, qty),
                              );
                            },
                            childCount: _products.length,
                          ),
                        ),
                      ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}
