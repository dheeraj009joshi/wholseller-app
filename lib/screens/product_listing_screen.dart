import 'package:flutter/material.dart';
import 'package:wholeseller/theme/app_theme.dart';
import 'package:wholeseller/widgets/reference_product_card.dart';
import 'package:wholeseller/screens/product_detail_screen.dart';
import 'package:wholeseller/services/api_service.dart';

class ProductListingScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryName;

  const ProductListingScreen({super.key, this.categoryId, this.categoryName});

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _products = [];
  Map<String, int> _cartQuantities = {};
  bool _isLoading = true;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final cart = await _apiService.getCart();
      final Map<String, int> quantities = {};
      for (var item in cart['items']) {
        quantities[item['product_id']] = item['quantity'] as int;
      }
      if (mounted) setState(() => _cartQuantities = quantities);
    } catch (_) {}
  }

  Future<void> _updateQuantity(String productId, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        await _apiService.removeFromCart(productId);
      } else {
        try {
          await _apiService.updateCartItem(productId, newQuantity);
        } catch (_) {
          await _apiService.addToCart(productId, newQuantity);
        }
      }
      _loadCart();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newQuantity > 0 ? 'Cart updated' : 'Removed from cart'), backgroundColor: AppTheme.greenColor));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final products = await _apiService.getProducts(
        category: widget.categoryId,
        search: _searchQuery,
      );
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text.isEmpty ? null : _searchController.text;
    });
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName ?? 'Products'),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch();
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadProducts,
                ),
              ],
            ),
          ),
          // Product List - Grid with cart integration (same as home screen)
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadProducts();
                await _loadCart();
              },
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _products.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.textSecondary),
                              const SizedBox(height: 16),
                              Text('No products found', style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondary)),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.58,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            final productId = product['id'] as String;
                            return ReferenceProductCard(
                              product: product,
                              initialQuantity: _cartQuantities[productId] ?? 0,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ProductDetailScreen(productId: productId))).then((_) => _loadCart()),
                              onUpdateQuantity: (qty) => _updateQuantity(productId, qty),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
