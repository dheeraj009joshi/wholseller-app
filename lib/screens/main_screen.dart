import 'package:flutter/material.dart';
import 'package:wholeseller/theme/app_theme.dart';
import 'package:wholeseller/screens/new_home_screen.dart';
import 'package:wholeseller/screens/profile_screen.dart';
import 'package:wholeseller/screens/orders_screen.dart';
import 'package:wholeseller/screens/cart_screen.dart';
import 'package:wholeseller/screens/product_listing_screen.dart';
import 'package:wholeseller/screens/profile/address_list_screen.dart';
import 'package:wholeseller/screens/landing_screen.dart';
import 'package:wholeseller/screens/admin/admin_dashboard_screen.dart';
import 'package:wholeseller/services/auth_service.dart';
import 'package:wholeseller/widgets/drawer_scope.dart';

class MainScreen extends StatefulWidget {
  /// Initial tab index (0=Home, 1=Order History, 2=Order Sheet, 3=Account). Used e.g. after checkout.
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _user;

  final List<Widget> _screens = [
    const NewHomeScreen(),
    const OrdersScreen(),
    const Scaffold(body: Center(child: Text('Order Sheet - Coming Soon'))),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 3);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUser();
    setState(() => _user = user);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LandingScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _user?['is_admin'] ?? false;

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.shopping_bag, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_user?['name'] ?? 'User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(_user?['email'] ?? '', style: AppTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Choose Location'),
                subtitle: const Text('Select delivery address'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const AddressListScreen())).then((_) => _loadUser());
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.shopping_bag_outlined),
                title: const Text('Cart'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const CartScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('My Orders'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Categories'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const ProductListingScreen()));
                },
              ),
              if (isAdmin) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('Admin Dashboard'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminDashboardScreen()));
                  },
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Account'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 3);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppTheme.errorColor),
                title: const Text('Logout', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
                onTap: _handleLogout,
              ),
            ],
          ),
        ),
      ),
      body: DrawerScope(
        openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        switchToTab: (index) => setState(() => _selectedIndex = index.clamp(0, 3)),
        child: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.history), activeIcon: Icon(Icons.history), label: 'Order History'),
              BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Order Sheet'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outlined), activeIcon: Icon(Icons.person), label: 'Account'),
            ],
          ),
        ),
      ),
    );
  }
}
