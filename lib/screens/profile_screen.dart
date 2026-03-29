import 'package:flutter/material.dart';
import 'package:wholeseller/theme/app_theme.dart';
import 'package:wholeseller/screens/landing_screen.dart';
import 'package:wholeseller/screens/orders_screen.dart';
import 'package:wholeseller/screens/admin/admin_dashboard_screen.dart';
import 'package:wholeseller/services/auth_service.dart';
import 'package:wholeseller/widgets/drawer_scope.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUser();
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isAdmin = _user?['is_admin'] ?? false;
    final name = _user?['name'] ?? 'Sarah Johnson';
    final email = _user?['email'] ?? 'sarah.johnson@email.com';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => DrawerScope.of(context).openDrawer(),
        ),
        title: const Text('My Health Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header (Login/Register Style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              color: Colors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: const Icon(Icons.person, size: 30, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Version: 1.3.6(31)', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
                ],
              ),
            ),
            const Divider(height: 1),
            
            _buildListItem(Icons.location_on_outlined, 'Choose Location - 123401', () {}),
            const Divider(height: 1),
            
            _buildListItem(Icons.currency_rupee, 'My Savings', () {}),
            const Divider(height: 1),
            
            _buildListItem(Icons.history, 'My Orders', () {
              final scope = DrawerScope.maybeOf(context);
              if (scope?.switchToTab != null) {
                scope!.switchToTab!(1); // Order History tab
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (c) => const OrdersScreen()));
              }
            }),
            const Divider(height: 1),
            
            _buildListItem(Icons.account_balance_wallet_outlined, 'Wallet', () {}),
            const Divider(height: 1),
            
            _buildListItem(Icons.trending_up, 'Trending Locally', () {}),
            const Divider(height: 1),
            
            _buildListItem(Icons.medication_outlined, 'Generic Medicines', () {}),
            const Divider(height: 1),
            
            _buildListItem(Icons.repeat, 'Buy Again', () {}),
            const Divider(height: 1),

            if (isAdmin)
               _buildListItem(Icons.admin_panel_settings_outlined, 'Pharmacy Admin', () {
                 Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminDashboardScreen()));
               }),
            
            _buildListItem(Icons.help_outline, 'Request Products', () {}),
            const Divider(height: 1),

            const SizedBox(height: 20),
            TextButton(
              onPressed: () => _logout(context), 
              child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
     return Container(); // Removed
  }

  Widget _buildListItem(IconData icon, String text, VoidCallback onTap) {
    return Container(
      color: Colors.white,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.primaryColor, size: 24),
        title: Text(text, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 15, color: Color(0xFF0F172A))),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LandingScreen()),
        (route) => false,
      );
    }
  }
}
