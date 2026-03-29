import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import for Platform
import 'api_config_stub.dart'
    if (dart.library.io) 'api_config_mobile.dart' as platform;

class ApiConfig {
  // Base URL configuration for different platforms
  static String get baseUrl {
    // For web platform, use localhost
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }
    
    // For mobile platforms
    final platformType = platform.getPlatformType();
    
    if (platformType == 'android') {
      // For Android Emulator
      return 'http://10.0.2.2:8000/api';
      // For physical Android device, uncomment and set your computer's IP:
      // return 'http://192.168.1.XXX:8001/api';
    } else if (platformType == 'ios') {
      // For iOS Simulator
      return 'http://localhost:8000/api';
      // For physical iOS device, uncomment and set your computer's IP:
      // return 'http://192.168.1.XXX:8001/api';
    }
    
    // Default fallback
    return 'http://localhost:8000/api';
  }
  
  // To find your computer's IP for physical devices:
  // macOS/Linux: ifconfig | grep "inet " | grep -v 127.0.0.1
  // Windows: ipconfig
}
