import 'package:flutter/material.dart';
import 'package:wholeseller/theme/app_theme.dart';
import 'package:wholeseller/screens/landing_screen.dart';
import 'package:wholeseller/screens/main_screen.dart';
import 'package:wholeseller/services/auth_service.dart';
import 'package:wholeseller/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize ApiService and load token
  await ApiService().initialize();
  runApp(const WholesellerApp());
}

class WholesellerApp extends StatefulWidget {
  const WholesellerApp({super.key});

  @override
  State<WholesellerApp> createState() => _WholesellerAppState();
}

class _WholesellerAppState extends State<WholesellerApp> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _setupApiService();
    _checkAuthStatus();
  }

  void _setupApiService() {
    ApiService.onUnauthorized = () {
      if (_isLoggedIn) {
        _handleLogout();
      }
    };
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    setState(() {
      _isLoggedIn = false;
    });
  }

  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wholeseller',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _isLoading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _isLoggedIn
              ? const MainScreen()
              : const LandingScreen(),
    );
  }
}
