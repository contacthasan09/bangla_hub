



// lib/config/api_keys.dart
import 'dart:io';

class ApiKeys {
  // ✅ Replace with your actual Android API key
  static const String androidKey = 'AIzaSyBxJfMon9tMNqAH_xKBC8JMLS5o9zS1WYU';
  
  // ✅ Replace with your actual iOS API key
  static const String iosKey = 'AIzaSyDw-QLRFJrFCKUxNapNwjp2UhK_xk7aEiU';
  
  static String get googleMapsKey {
    if (Platform.isAndroid) {
      return androidKey;
    } else if (Platform.isIOS) {
      return iosKey;
    }
    return androidKey;
  }
  
  // For debugging - check if key is valid
  static bool get isKeyValid {
    final key = googleMapsKey;
    return key.isNotEmpty && 
           key != 'AIzaSyBxJfMon9tMNqAH_xKBC8JMLS5o9zS1WYU' && 
           key != 'AIzaSyDw-QLRFJrFCKUxNapNwjp2UhK_xk7aEiU' &&
           key.startsWith('AIza');
  }
}