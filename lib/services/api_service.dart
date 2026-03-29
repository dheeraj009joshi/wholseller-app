import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wholeseller/config/api_config.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static String get baseUrl => ApiConfig.baseUrl;
  static const String _tokenKey = 'auth_token';
  String? _token;

  // Initialize token from SharedPreferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  void setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    } else {
      await prefs.remove(_tokenKey);
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static void Function()? onUnauthorized;

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      onUnauthorized?.call();
      throw Exception('Unauthorized');
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return json.decode(response.body);
    } else {
      try {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'An error occurred');
      } catch (e) {
        throw Exception('An error occurred: ${response.statusCode}');
      }
    }
  }

  // Auth endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: json.encode({'email': email, 'password': password}),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: json.encode(userData),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers,
    );
    return await _handleResponse(response);
  }

  // Product endpoints
  Future<List<dynamic>> getProducts({String? category, String? search}) async {
    final queryParams = <String, String>{};
    if (category != null && category.isNotEmpty) queryParams['category'] = category;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse('$baseUrl/products/').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 401) {
      onUnauthorized?.call();
      throw Exception('Unauthorized');
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return List<dynamic>.from(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'An error occurred');
    }
  }

  Future<Map<String, dynamic>> getProduct(String productId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/$productId'),
      headers: _headers,
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products/'),
      headers: _headers,
      body: json.encode(productData),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateProduct(String productId, Map<String, dynamic> productData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/$productId'),
      headers: _headers,
      body: json.encode(productData),
    );
    return await _handleResponse(response);
  }

  Future<void> deleteProduct(String productId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/products/$productId'),
      headers: _headers,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'An error occurred');
    }
  }

  // Cart endpoints
  Future<Map<String, dynamic>> getCart() async {
    final response = await http.get(
      Uri.parse('$baseUrl/cart/'),
      headers: _headers,
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> addToCart(String productId, int quantity) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cart/items'),
      headers: _headers,
      body: json.encode({'product_id': productId, 'quantity': quantity}),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateCartItem(String productId, int quantity) async {
    final response = await http.put(
      Uri.parse('$baseUrl/cart/items/$productId'),
      headers: _headers,
      body: json.encode({'quantity': quantity}),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> removeFromCart(String productId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/cart/items/$productId'),
      headers: _headers,
    );
    return await _handleResponse(response);
  }

  // Order endpoints
  Future<List<dynamic>> getOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/'),
      headers: _headers,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = json.decode(response.body);
      if (body is List) {
        return List<dynamic>.from(body);
      } else {
        // Handle error response
        throw Exception(body['detail'] ?? 'Invalid response format');
      }
    } else {
      try {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'An error occurred');
      } catch (e) {
        throw Exception('An error occurred: ${response.statusCode}');
      }
    }
  }

  Future<Map<String, dynamic>> getOrder(String orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: _headers,
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/'),
      headers: _headers,
      body: json.encode(orderData),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateOrder(String orderId, Map<String, dynamic> orderData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: _headers,
      body: json.encode(orderData),
    );
    return await _handleResponse(response);
  }

  // User endpoints
  Future<Map<String, dynamic>> updateUser(Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
      body: json.encode(userData),
    );
    return await _handleResponse(response);
  }

  // Admin endpoints
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/dashboard/stats'),
      headers: _headers,
    );
    return await _handleResponse(response);
  }

  Future<List<dynamic>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: _headers,
    );
    return List<dynamic>.from(json.decode(response.body));
  }

  Future<List<dynamic>> getAllOrders({String? status}) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status_filter'] = status;

    final uri = Uri.parse('$baseUrl/admin/orders').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    return List<dynamic>.from(json.decode(response.body));
  }

  Future<List<dynamic>> getAllProductsAdmin() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/products'),
      headers: _headers,
    );
    return List<dynamic>.from(json.decode(response.body));
  }

  Future<void> toggleUserAdmin(String userId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/users/$userId/toggle-admin'),
      headers: _headers,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'An error occurred');
    }
  }

  // Image upload
  Future<String> uploadProductImage(String productId, List<int> imageBytes, String filename) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/products/$productId/images'),
    );
    request.headers.addAll({
      if (_token != null) 'Authorization': 'Bearer $_token',
    });
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: filename,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body);
      return data['image_url'] as String;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'An error occurred');
    }
  }

  // Category endpoints
  Future<List<dynamic>> getCategories({bool activeOnly = true}) async {
    final queryParams = <String, String>{};
    if (activeOnly) queryParams['active_only'] = 'true';

    final uri = Uri.parse('$baseUrl/categories/').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 401) {
      onUnauthorized?.call();
      throw Exception('Unauthorized');
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return List<dynamic>.from(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'An error occurred');
    }
  }

  Future<Map<String, dynamic>> getCategory(String categoryId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories/$categoryId'),
      headers: _headers,
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> categoryData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories/'),
      headers: _headers,
      body: json.encode(categoryData),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateCategory(String categoryId, Map<String, dynamic> categoryData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$categoryId'),
      headers: _headers,
      body: json.encode(categoryData),
    );
    return await _handleResponse(response);
  }

  Future<void> deleteCategory(String categoryId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$categoryId'),
      headers: _headers,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'An error occurred');
    }
  }

  // Address endpoints
  Future<List<dynamic>> getAddresses() async {
    final response = await http.get(
      Uri.parse('$baseUrl/addresses/'),
      headers: _headers,
    );
    if (response.statusCode == 401) {
      onUnauthorized?.call();
      throw Exception('Unauthorized');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return List<dynamic>.from(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'An error occurred');
    }
  }

  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> addressData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/addresses/'),
      headers: _headers,
      body: json.encode(addressData),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateAddress(String addressId, Map<String, dynamic> addressData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/addresses/$addressId'),
      headers: _headers,
      body: json.encode(addressData),
    );
    return await _handleResponse(response);
  }

  Future<void> deleteAddress(String addressId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/addresses/$addressId'),
      headers: _headers,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'An error occurred');
    }
  }
}
