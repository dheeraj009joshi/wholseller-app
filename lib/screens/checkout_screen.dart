import 'package:flutter/material.dart';
import 'package:wholeseller/theme/app_theme.dart';
import 'package:wholeseller/widgets/primary_button.dart';
import 'package:wholeseller/screens/main_screen.dart';
import 'package:wholeseller/services/api_service.dart';
import 'package:wholeseller/screens/address_management_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final ApiService _apiService = ApiService();
  String _selectedPaymentMethod = 'card';
  Map<String, dynamic>? _cart;
  List<dynamic> _addresses = [];
  Map<String, dynamic>? _selectedAddress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final cart = await _apiService.getCart();
      final addresses = await _apiService.getAddresses();
      setState(() {
        _cart = cart;
        _addresses = addresses;
        _selectedAddress = addresses.isNotEmpty
            ? addresses.firstWhere(
                (addr) => addr['is_default'] == true,
                orElse: () => addresses.first,
              )
            : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    if (_cart == null || (_cart!['items'] as List).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    try {
      // Convert cart items to order items
      final orderItems = (_cart!['items'] as List).map((item) {
        return {
          'product_id': item['product_id'],
          'product_name': item['product_name'],
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'total_price': item['total_price'],
        };
      }).toList();

      // Get current user
      final user = await _apiService.getCurrentUser();

      final orderData = {
        'user_id': user['id'],
        'items': orderItems,
        'shipping_address': _selectedAddress!['address'],
        'city': _selectedAddress!['city'],
        'state': _selectedAddress!['state'],
        'pincode': _selectedAddress!['pincode'],
        'payment_method': _selectedPaymentMethod,
        'subtotal': _cart!['subtotal'],
        'shipping_cost': _cart!['shipping_cost'],
        'total': _cart!['total'],
        'status': 'pending',
      };

      await _apiService.createOrder(orderData);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Order Placed!'),
            content: const Text('Your order has been placed successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainScreen(initialIndex: 1),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery Address Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Delivery Address',
                                style: AppTheme.titleLarge,
                              ),
                              TextButton(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddressManagementScreen(),
                                    ),
                                  );
                                  _loadData();
                                },
                                child: const Text('Manage Addresses'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_addresses.isEmpty)
                            const Text('No addresses saved. Please add an address.')
                          else
                            ..._addresses.map((address) {
                              return RadioListTile<Map<String, dynamic>>(
                                title: Text(address['label'] ?? 'Address'),
                                subtitle: Text(
                                  '${address['address']}, ${address['city']}, ${address['state']} - ${address['pincode']}',
                                ),
                                value: address,
                                groupValue: _selectedAddress,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedAddress = value;
                                  });
                                },
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Payment Method Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Method',
                            style: AppTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          RadioListTile<String>(
                            title: const Row(
                              children: [
                                Icon(Icons.credit_card, size: 24),
                                SizedBox(width: 12),
                                Text('Credit/Debit Card'),
                              ],
                            ),
                            value: 'card',
                            groupValue: _selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethod = value!;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Row(
                              children: [
                                Icon(Icons.account_balance, size: 24),
                                SizedBox(width: 12),
                                Text('Net Banking'),
                              ],
                            ),
                            value: 'netbanking',
                            groupValue: _selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethod = value!;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Row(
                              children: [
                                Icon(Icons.account_balance_wallet, size: 24),
                                SizedBox(width: 12),
                                Text('UPI'),
                              ],
                            ),
                            value: 'upi',
                            groupValue: _selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethod = value!;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Row(
                              children: [
                                Icon(Icons.money, size: 24),
                                SizedBox(width: 12),
                                Text('Cash on Delivery'),
                              ],
                            ),
                            value: 'cod',
                            groupValue: _selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethod = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Order Summary
                  if (_cart != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order Summary',
                              style: AppTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Subtotal',
                                  style: AppTheme.bodyLarge,
                                ),
                                Text(
                                  '₹${((_cart!['subtotal'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                                  style: AppTheme.bodyLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Shipping',
                                  style: AppTheme.bodyMedium,
                                ),
                                Text(
                                  '₹${((_cart!['shipping_cost'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                                  style: AppTheme.bodyMedium,
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹${((_cart!['total'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Place Order',
                    onPressed: _placeOrder,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
