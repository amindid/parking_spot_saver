/// API Configuration for external services used in the Parking Spot Saver app
/// 
/// To set up OpenRouteService:
/// 1. Go to https://openrouteservice.org/dev/#/signup
/// 2. Sign up for a free account (no credit card needed)
/// 3. Get your API key (5000 requests/day free)
/// 4. Replace 'YOUR_API_KEY_HERE' with your actual API key
class ApiConfig {
  /// OpenRouteService API key for road-based routing
  /// Free tier: 5000 requests per day
  /// Sign up at: https://openrouteservice.org/dev/#/signup
  /// 
  /// IMPORTANT: Replace this with your actual API key from OpenRouteService
  static const String openRouteServiceApiKey = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjMwNGFlNjE5NGVkZDQ5MzE4YmQzNmU4Y2VlMDQ0YWFlIiwiaCI6Im11cm11cjY0In0=';
  
  /// Base URL for OpenRouteService walking directions API
  static const String openRouteServiceBaseUrl = 'https://api.openrouteservice.org/v2/directions/foot-walking';
  
  /// Request timeout in seconds
  static const int requestTimeoutSeconds = 10;
  
  /// Maximum number of retry attempts for failed requests
  static const int maxRetryAttempts = 2;
  
  /// Check if API key is configured
  static bool get isApiKeyConfigured {
    return openRouteServiceApiKey.isNotEmpty && 
           openRouteServiceApiKey != 'YOUR_API_KEY_HERE';
  }
  
  /// Get setup instructions for users who haven't configured their API key
  static String get setupInstructions {
    return '''
To enable road-based navigation:
1. Visit https://openrouteservice.org/dev/#/signup
2. Create a free account (no credit card required)
3. Get your API key (5000 free requests/day)
4. Add your API key to lib/config/api_config.dart
5. Restart the app to enjoy real road-based routing!
''';
  }
}