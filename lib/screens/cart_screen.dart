import 'package:flutter/material.dart';
import 'package:wholeseller/theme/app_theme.dart';
import 'package:wholeseller/screens/checkout_screen.dart';
import 'package:wholeseller/services/api_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _cart;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final cart = await _apiService.getCart();
      setState(() {
        _cart = cart;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cart: $e')),
        );
      }
    }
  }

  Future<void> _updateQuantity(String productId, int newQuantity) async {
    try {
      await _apiService.updateCartItem(productId, newQuantity);
      _loadCart();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating cart: $e')),
        );
      }
    }
  }

  Future<void> _removeItem(String productId) async {
    try {
      await _apiService.removeFromCart(productId);
      _loadCart();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing item: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCart,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cart == null || (_cart!['items'] as List).isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your cart is empty',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadCart,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: (_cart!['items'] as List).length,
                          itemBuilder: (context, index) {
                            final item = _cart!['items'][index];
                            final quantity = item['quantity'] as int;
                            final unitPrice = (item['unit_price'] as num).toDouble();
                            final total = (item['total_price'] as num).toDouble();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                                border: Border.all(color: Colors.grey.withOpacity(0.05)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: item['product_image'] != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Image.network(
                                              item['product_image'],
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.medication_rounded, color: Color(0xFF94A3B8), size: 30),
                                            ),
                                          )
                                        : const Icon(Icons.medication_rounded, color: Color(0xFF94A3B8), size: 30),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['product_name'] ?? '',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${unitPrice.toStringAsFixed(2)} per unit',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            _buildCartQtyBtn(Icons.remove_rounded, () {
                                              if (quantity > 1) {
                                                _updateQuantity(item['product_id'], quantity - 1);
                                              } else {
                                                _removeItem(item['product_id']);
                                              }
                                            }),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: Text(
                                                '$quantity',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                                              ),
                                            ),
                                            _buildCartQtyBtn(Icons.add_rounded, () {
                                              _updateQuantity(item['product_id'], quantity + 1);
                                            }),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
                                        onPressed: () => _removeItem(item['product_id']),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        '₹${total.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Modern Price Summary
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow('Subtotal', '₹${((_cart!['subtotal'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}'),
                          const SizedBox(height: 12),
                          _buildSummaryRow('Shipping Fee', '₹${((_cart!['shipping_cost'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}'),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                              Text(
                                '₹${((_cart!['total'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                shadowColor: AppTheme.primaryColor.withOpacity(0.5),
                              ),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckoutScreen())),
                              child: const Text('Checkout Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCartQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF64748B), size: 18),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500, fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF111827))),
      ],
    );
  }
}
