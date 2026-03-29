import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  static const String _tokenKey = 'auth_token';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      final token = response['access_token'] as String;

      // Save token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);

      _apiService.setToken(token);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.register(userData);
      final token = response['access_token'] as String;

      // Save token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);

      _apiService.setToken(token);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      _apiService.setToken(token);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _apiService.setToken(null);
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      return await _apiService.getCurrentUser();
    } catch (e) {
      return null;
    }
  }
}
