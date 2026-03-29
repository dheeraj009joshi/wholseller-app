import 'package:flutter/material.dart';
import 'package:wholeseller/theme/app_theme.dart';
import 'package:wholeseller/services/api_service.dart';
import 'package:wholeseller/widgets/reference_product_card.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _product;
  int _quantity = 1;
  int _cartQuantity = 0;
  int _selectedVariantIndex = 0;
  bool _isLoading = true;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadCartQuantity() async {
    try {
      final cart = await _apiService.getCart();
      final items = cart['items'] as List<dynamic>? ?? [];
      for (var item in items) {
        if (item['product_id'] == widget.productId) {
          setState(() => _cartQuantity = item['quantity'] as int);
          return;
        }
      }
      setState(() => _cartQuantity = 0);
    } catch (_) {
      setState(() => _cartQuantity = 0);
    }
  }

  Future<void> _updateCartQuantity(int newQty) async {
    try {
      if (newQty <= 0) {
        await _apiService.removeFromCart(widget.productId);
      } else {
        try {
          await _apiService.updateCartItem(widget.productId, newQty);
        } catch (_) {
          await _apiService.addToCart(widget.productId, newQty);
        }
      }
      await _loadCartQuantity();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newQty > 0 ? 'Cart updated' : 'Removed from cart'), backgroundColor: AppTheme.greenColor));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _loadProduct() async {
    try {
      final product = await _apiService.getProduct(widget.productId);
      await _loadCartQuantity();
      setState(() {
        _product = product;
        _quantity = _cartQuantity > 0 ? _cartQuantity : 1;
        _selectedVariantIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Variant: {strength: "250mg", ptr: 50.0, mrp: 65.0}
  List<Map<String, dynamic>> _getVariants() {
    if (_product == null) return [];
    final variants = _product!['variants'] as List<dynamic>?;
    if (variants != null && variants.isNotEmpty) {
      return variants.map((v) {
        final m = v as Map<String, dynamic>;
        final ptr = (m['ptr'] ?? m['price'] ?? 0) as num;
        return {
          'strength': m['strength'] ?? m['label'] ?? '${ptr}',
          'ptr': ptr.toDouble(),
          'mrp': (m['mrp'] ?? ptr * 1.35).toDouble(),
        };
      }).toList();
    }
    final basePrice = _getBasePrice();
    final dosage = (_product!['dosage'] ?? '') as String;
    final name = (_product!['name'] ?? '') as String;
    final match = RegExp(r'(\d+)\s*(mg|g)', caseSensitive: false).firstMatch(dosage.isNotEmpty ? dosage : name);
    final baseMg = match != null ? int.tryParse(match.group(1) ?? '500') ?? 500 : 500;
    return [
      {'strength': '250 mg', 'ptr': basePrice * 0.5, 'mrp': basePrice * 0.5 * 1.35},
      {'strength': '${baseMg} mg', 'ptr': basePrice, 'mrp': basePrice * 1.35},
      {'strength': '1000 mg', 'ptr': basePrice * 1.8, 'mrp': basePrice * 1.8 * 1.35},
    ];
  }

  double _getBasePrice() {
    if (_product == null) return 0.0;
    final tiers = _product!['pricing_tiers'] as Map<String, dynamic>?;
    if (tiers == null || tiers.isEmpty) return 0.0;
    final val = tiers['unit'] ?? tiers['1+ units'] ?? tiers.values.first;
    return (val as num).toDouble();
  }

  double _getPrice() {
    final variants = _getVariants();
    if (variants.isEmpty) return _getBasePrice();
    if (_selectedVariantIndex >= variants.length) return _getBasePrice();
    return variants[_selectedVariantIndex]['ptr'] as double;
  }

  double _getMrp() {
    final variants = _getVariants();
    if (variants.isEmpty) return _getPrice() * 1.35;
    if (_selectedVariantIndex >= variants.length) return _getPrice() * 1.35;
    return variants[_selectedVariantIndex]['mrp'] as double;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_product == null) {
      return const Scaffold(body: Center(child: Text('Medicine not found')));
    }

    final images = _product!['images'] as List<dynamic>? ?? [];
    final name = _product!['name'] ?? 'Medicine';
    final description = _product!['description'] ?? '';
    final price = _getPrice();
    final mrp = _getMrp();
    final inStock = (_product!['stock'] ?? 0) > 0;
    final dosage = _product!['dosage'] ?? '';
    final variants = _getVariants();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined, color: AppTheme.primaryColor), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search, color: AppTheme.primaryColor), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image with Offer Badge
                    Stack(
                      children: [
                        Container(
                          height: 300,
                          width: double.infinity,
                          color: Colors.white,
                          child: images.isNotEmpty
                              ? PageView.builder(
                                  controller: _pageController,
                                  itemCount: images.length,
                                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                                  itemBuilder: (context, index) {
                                    final url = images[index] as String;
                                    return Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Image.network(
                                        url,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => const Center(
                                          child: Icon(Icons.medication, size: 80, color: Colors.grey),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : const Center(child: Icon(Icons.medication, size: 100, color: Colors.grey)),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.percent, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),

                    // Page Indicator
                    if (images.length > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 20,
                            height: 3,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? AppTheme.primaryColor : Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Product Details
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          if (dosage.isNotEmpty)
                            Text(
                              dosage,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            'Manufacturer: ${_product!['manufacturer'] ?? 'Generic Pharma'}',
                            style: const TextStyle(fontSize: 14, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 16),

                          // Variants (mg strength selection)
                          if (variants.isNotEmpty) ...[
                            const Text('Select Strength', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(variants.length, (i) {
                                final v = variants[i];
                                final label = v['strength'] as String;
                                final isSelected = _selectedVariantIndex == i;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedVariantIndex = i),
                                  child: _buildVariantChip(label, isSelected),
                                );
                              }),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Price (dynamic based on variant)
                          if (mrp > price)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                              child: Text('${((1 - price / mrp) * 100).toStringAsFixed(0)}% Off', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          if (mrp > price) const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('PTR : ₹${price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text('MRP : ₹${mrp.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Best Before: Nov 30, 2028', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          const SizedBox(height: 16),

                          GestureDetector(
                            onTap: () {},
                            child: Row(
                              children: const [
                                Text('More Information', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                                Icon(Icons.chevron_right, color: AppTheme.primaryColor),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),

                    // Relevant Products
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Relevant Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 280,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(left: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return ReferenceProductCard(
                        width: 170,
                        product: {
                          'id': 'rel_$index',
                          'name': 'Similar Med ${index + 1}',
                          'dosage': '100 mg',
                          'pricing_tiers': {'unit': 50.0 + index},
                          'images': [],
                        },
                        initialQuantity: 0,
                        onTap: () {},
                        onUpdateQuantity: (q) {},
                      );
                    },
                  ),
                    ),
                    const SizedBox(height: 24),

                    // Description
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(description.isNotEmpty ? description : 'N/A'),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Bottom Bar - Add / Quantity controls (like home screen)
            Container(
              padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2)))),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('PTR : ₹${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('MRP : ₹${mrp.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                  const Spacer(),
                  if (_cartQuantity > 0)
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.greenColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: AppTheme.greenColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_rounded, color: Colors.white, size: 24),
                            onPressed: () => _updateCartQuantity(_cartQuantity - 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('$_cartQuantity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                            onPressed: () => _updateCartQuantity(_cartQuantity + 1),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: 150,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: inStock ? _addToCart : null,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.greenColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Add to Cart', style: TextStyle(color: AppTheme.greenColor, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
        border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.3), width: isSelected ? 2 : 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(color: isSelected ? AppTheme.primaryColor : Colors.black, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
    );
  }

  Future<void> _addToCart() async {
    try {
      await _apiService.addToCart(widget.productId, _quantity);
      await _loadCartQuantity();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Cart!'), backgroundColor: AppTheme.greenColor));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
