import 'package:flutter/material.dart';
import 'package:wholeseller/theme/app_theme.dart';
import 'package:wholeseller/services/api_service.dart';
import 'package:wholeseller/screens/admin/admin_products_screen.dart';
import 'package:wholeseller/screens/admin/admin_orders_screen.dart';
import 'package:wholeseller/screens/admin/admin_users_screen.dart';
import 'package:wholeseller/screens/admin/admin_add_product_screen.dart';
import 'package:wholeseller/screens/admin/admin_categories_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _apiService.getDashboardStats();
      setState(() {
        _stats = stats;
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
      appBar: AppBar(
        title: const Text('Pharmacy Admin', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard('Total Sales', '₹${(_stats?['total_revenue'] ?? 0).toStringAsFixed(0)}', Icons.currency_rupee, AppTheme.primaryColor),
                      _buildStatCard('Orders', _stats?['total_orders']?.toString() ?? '0', Icons.shopping_bag, Colors.green),
                      _buildStatCard('Medicines', _stats?['total_products']?.toString() ?? '0', Icons.medication, Colors.purple),
                      _buildStatCard('Customers', _stats?['total_users']?.toString() ?? '0', Icons.people, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Low Stock Alert
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.warning_amber, color: Colors.orange),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Low Stock Alert', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('5 medicines are running low on stock', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                             Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminProductsScreen()));
                          },
                          child: const Text('View'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent Orders
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Orders', style: AppTheme.titleLarge),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminOrdersScreen())),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildOrderTile('Paracetamol 500mg', 'Order #1234', '₹250', 'Delivered', Colors.green),
                  _buildOrderTile('Vitamin D3 Capsules', 'Order #1235', '₹450', 'Processing', Colors.orange),
                  _buildOrderTile('Cough Syrup 100ml', 'Order #1236', '₹120', 'Pending', Colors.blue),

                  const SizedBox(height: 24),

                  // Quick Actions
                  const Text('Quick Actions', style: AppTheme.titleLarge),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildActionButton(Icons.add_circle, 'Add Medicine', () {
                        Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminAddProductScreen()));
                      })),
                      const SizedBox(width: 12),
                      Expanded(child: _buildActionButton(Icons.inventory_2, 'Inventory', () {
                        Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminProductsScreen()));
                      })),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildActionButton(Icons.receipt_long, 'Orders', () {
                        Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminOrdersScreen()));
                      })),
                      const SizedBox(width: 12),
                      Expanded(child: _buildActionButton(Icons.category, 'Categories', () {
                         Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminCategoriesScreen()));
                      })),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildActionButton(Icons.people_outline, 'Patients', () {
                        Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminUsersScreen()));
                      })),
                       const SizedBox(width: 12),
                       Expanded(child: Opacity(opacity: 0, child: _buildActionButton(Icons.analytics, 'Analytics', () {}))), // Placeholder for alignment
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTile(String medicine, String orderId, String price, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.medication, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medicine, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(orderId, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
