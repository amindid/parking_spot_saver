import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../config/api_config.dart';

/// Service for calculating road-based walking routes using OpenRouteService API
/// Provides free routing with 5000 requests/day limit
class RoutingService {
  static RoutingService? _instance;
  late final Dio _dio;

  RoutingService._internal() {
    _dio = Dio(BaseOptions(
      connectTimeout: Duration(seconds: ApiConfig.requestTimeoutSeconds),
      receiveTimeout: Duration(seconds: ApiConfig.requestTimeoutSeconds),
      sendTimeout: Duration(seconds: ApiConfig.requestTimeoutSeconds),
    ));
  }

  static RoutingService get instance {
    _instance ??= RoutingService._internal();
    return _instance!;
  }

  /// Get walking route between two points using OpenRouteService API
  /// Returns list of LatLng points that follow actual roads and walkways
  /// Falls back to straight line if API fails
  Future<RouteResult> getWalkingRoute(LatLng start, LatLng end) async {
    // Check if API key is configured
    if (!ApiConfig.isApiKeyConfigured) {
      developer.log('OpenRouteService API key not configured, falling back to straight line');
      return RouteResult(
        route: [start, end],
        distance: _calculateStraightLineDistance(start, end),
        duration: _estimateStraightLineDuration(start, end),
        isRoadBased: false,
        errorMessage: 'API key not configured. Using straight-line route.',
      );
    }

    try {
      // Attempt to get real road-based route
      return await _fetchRouteFromApi(start, end);
    } catch (e) {
      developer.log('Routing API error: $e');
      
      // Fallback to straight line route
      return RouteResult(
        route: [start, end],
        distance: _calculateStraightLineDistance(start, end),
        duration: _estimateStraightLineDuration(start, end),
        isRoadBased: false,
        errorMessage: 'Network error. Using straight-line route.',
      );
    }
  }

  /// Fetch route from OpenRouteService API with retry logic
  Future<RouteResult> _fetchRouteFromApi(LatLng start, LatLng end) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < ApiConfig.maxRetryAttempts) {
      try {
        attempts++;
        
        final response = await _dio.get(
          ApiConfig.openRouteServiceBaseUrl,
          queryParameters: {
            'api_key': ApiConfig.openRouteServiceApiKey,
            'start': '${start.longitude},${start.latitude}',
            'end': '${end.longitude},${end.latitude}',
            'format': 'json',
          },
        );

        if (response.statusCode == 200) {
          return _parseRouteResponse(response.data, start, end);
        } else {
          throw Exception('API returned status code: ${response.statusCode}');
        }
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        if (attempts == ApiConfig.maxRetryAttempts) {
          break;
        }
        
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempts));
      }
    }

    throw lastException ?? Exception('Unknown error');
  }

  /// Parse the API response and extract route information
  RouteResult _parseRouteResponse(Map<String, dynamic> data, LatLng start, LatLng end) {
    try {
      final features = data['features'] as List;
      if (features.isEmpty) {
        throw Exception('No route found in API response');
      }

      final feature = features[0] as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List;
      
      // Convert coordinates to LatLng list
      final route = coordinates.map((coord) {
        final coordList = coord as List;
        return LatLng(coordList[1] as double, coordList[0] as double);
      }).toList();

      // Extract route summary information
      final properties = feature['properties'] as Map<String, dynamic>;
      final summary = properties['summary'] as Map<String, dynamic>;
      
      final distance = (summary['distance'] as num).toDouble(); // in meters
      final duration = (summary['duration'] as num).toDouble(); // in seconds

      return RouteResult(
        route: route,
        distance: distance,
        duration: duration,
        isRoadBased: true,
        errorMessage: null,
      );
    } catch (e) {
      developer.log('Error parsing route response: $e');
      
      // Fallback to straight line
      return RouteResult(
        route: [start, end],
        distance: _calculateStraightLineDistance(start, end),
        duration: _estimateStraightLineDuration(start, end),
        isRoadBased: false,
        errorMessage: 'Failed to parse route data. Using straight-line route.',
      );
    }
  }

  /// Calculate straight-line distance between two points
  double _calculateStraightLineDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Estimate walking duration for straight-line distance
  /// Assumes average walking speed of 5 km/h
  double _estimateStraightLineDuration(LatLng start, LatLng end) {
    final distanceKm = _calculateStraightLineDistance(start, end) / 1000;
    const walkingSpeedKmh = 5.0;
    return (distanceKm / walkingSpeedKmh) * 3600; // Convert to seconds
  }

  /// Get route information without full route coordinates (lighter API call)
  Future<RouteInfo> getRouteInfo(LatLng start, LatLng end) async {
    final result = await getWalkingRoute(start, end);
    return RouteInfo(
      distance: result.distance,
      duration: result.duration,
      isRoadBased: result.isRoadBased,
      errorMessage: result.errorMessage,
    );
  }

  /// Check if routing service is available (API key configured and network accessible)
  Future<bool> isServiceAvailable() async {
    if (!ApiConfig.isApiKeyConfigured) {
      return false;
    }

    try {
      // Test API with a simple request (same location to same location)
      final testLocation = LatLng(0.0, 0.0);
      final response = await _dio.get(
        ApiConfig.openRouteServiceBaseUrl,
        queryParameters: {
          'api_key': ApiConfig.openRouteServiceApiKey,
          'start': '${testLocation.longitude},${testLocation.latitude}',
          'end': '${testLocation.longitude},${testLocation.latitude}',
          'format': 'json',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Format walking duration into human-readable string
  String formatDuration(double durationSeconds) {
    final duration = Duration(seconds: durationSeconds.round());
    
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = (duration.inMinutes % 60);
      return '${hours}h ${minutes}min';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} min';
    } else {
      return '< 1 min';
    }
  }

  /// Format distance into human-readable string
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }
}

/// Result of a routing calculation
class RouteResult {
  final List<LatLng> route;
  final double distance; // in meters
  final double duration; // in seconds
  final bool isRoadBased;
  final String? errorMessage;

  const RouteResult({
    required this.route,
    required this.distance,
    required this.duration,
    required this.isRoadBased,
    this.errorMessage,
  });

  /// Get formatted distance string
  String get formattedDistance => RoutingService.instance.formatDistance(distance);

  /// Get formatted duration string
  String get formattedDuration => RoutingService.instance.formatDuration(duration);

  /// Check if this is a valid road-based route
  bool get isValid => route.length >= 2;

  /// Get route type description
  String get routeType => isRoadBased ? 'Road-based route' : 'Straight-line route';
}

/// Light-weight route information without full coordinates
class RouteInfo {
  final double distance;
  final double duration;
  final bool isRoadBased;
  final String? errorMessage;

  const RouteInfo({
    required this.distance,
    required this.duration,
    required this.isRoadBased,
    this.errorMessage,
  });

  /// Get formatted distance string
  String get formattedDistance => RoutingService.instance.formatDistance(distance);

  /// Get formatted duration string
  String get formattedDuration => RoutingService.instance.formatDuration(duration);
}