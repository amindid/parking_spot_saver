import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'routing_service.dart';

class NavigationService {
  static NavigationService? _instance;
  NavigationService._internal();
  
  static NavigationService get instance {
    _instance ??= NavigationService._internal();
    return _instance!;
  }

  /// Calculate straight-line distance between two points in meters
  double calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Calculate bearing from start to end point in degrees (0-360)
  double calculateBearing(LatLng start, LatLng end) {
    return Geolocator.bearingBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Convert bearing to readable direction text
  String getDirectionText(double bearing) {
    // Normalize bearing to 0-360
    bearing = bearing % 360;
    if (bearing < 0) bearing += 360;

    if (bearing >= 337.5 || bearing < 22.5) return "North";
    if (bearing >= 22.5 && bearing < 67.5) return "Northeast";
    if (bearing >= 67.5 && bearing < 112.5) return "East";
    if (bearing >= 112.5 && bearing < 157.5) return "Southeast";
    if (bearing >= 157.5 && bearing < 202.5) return "South";
    if (bearing >= 202.5 && bearing < 247.5) return "Southwest";
    if (bearing >= 247.5 && bearing < 292.5) return "West";
    if (bearing >= 292.5 && bearing < 337.5) return "Northwest";
    return "Unknown";
  }

  /// Format distance for display
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Get navigation instruction based on distance
  String getNavigationInstruction(double meters, String direction) {
    if (meters < 10) {
      return 'You have arrived!';
    } else if (meters < 50) {
      return 'You are very close - ${formatDistance(meters)}';
    } else {
      return 'Head ${direction.toLowerCase()} - ${formatDistance(meters)}';
    }
  }

  /// Calculate bounds that include both points with some padding
  Map<String, double> calculateBounds(LatLng point1, LatLng point2, {double padding = 0.001}) {
    final minLat = math.min(point1.latitude, point2.latitude) - padding;
    final maxLat = math.max(point1.latitude, point2.latitude) + padding;
    final minLng = math.min(point1.longitude, point2.longitude) - padding;
    final maxLng = math.max(point1.longitude, point2.longitude) + padding;
    
    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLng': minLng,
      'maxLng': maxLng,
    };
  }

  /// Calculate center point between two locations
  LatLng calculateCenterPoint(LatLng point1, LatLng point2) {
    final centerLat = (point1.latitude + point2.latitude) / 2;
    final centerLng = (point1.longitude + point2.longitude) / 2;
    return LatLng(centerLat, centerLng);
  }

  /// Calculate appropriate zoom level for displaying both points
  double calculateZoomLevel(LatLng point1, LatLng point2) {
    final distance = calculateDistance(point1, point2);
    
    // Zoom levels based on distance
    if (distance < 100) return 18.0;      // Very close
    if (distance < 500) return 17.0;      // Close
    if (distance < 1000) return 16.0;     // Nearby
    if (distance < 2000) return 15.0;     // Same area
    if (distance < 5000) return 14.0;     // Same neighborhood
    if (distance < 10000) return 13.0;    // Same district
    return 12.0;                          // Wider area
  }

  /// Check if destination is reached (within 10 meters)
  bool isDestinationReached(LatLng current, LatLng destination, {double threshold = 10.0}) {
    return calculateDistance(current, destination) <= threshold;
  }

  /// Get direction arrow emoji based on bearing
  String getDirectionArrow(double bearing) {
    // Normalize bearing to 0-360
    bearing = bearing % 360;
    if (bearing < 0) bearing += 360;

    if (bearing >= 337.5 || bearing < 22.5) return "⬆️";    // North
    if (bearing >= 22.5 && bearing < 67.5) return "↗️";     // Northeast
    if (bearing >= 67.5 && bearing < 112.5) return "➡️";    // East
    if (bearing >= 112.5 && bearing < 157.5) return "↘️";   // Southeast
    if (bearing >= 157.5 && bearing < 202.5) return "⬇️";   // South
    if (bearing >= 202.5 && bearing < 247.5) return "↙️";   // Southwest
    if (bearing >= 247.5 && bearing < 292.5) return "⬅️";   // West
    if (bearing >= 292.5 && bearing < 337.5) return "↖️";   // Northwest
    return "❓";                                              // Unknown
  }

  /// Get walking route using road-based routing when available
  /// Falls back to straight-line route if road routing fails
  Future<RouteResult> getWalkingRoute(LatLng start, LatLng end) async {
    return await RoutingService.instance.getWalkingRoute(start, end);
  }

  /// Get route information (distance and duration) without full route
  Future<RouteInfo> getRouteInfo(LatLng start, LatLng end) async {
    return await RoutingService.instance.getRouteInfo(start, end);
  }

  /// Check if road-based routing is available
  Future<bool> isRoadRoutingAvailable() async {
    return await RoutingService.instance.isServiceAvailable();
  }

  /// Calculate distance along a route (sum of segments)
  double calculateRouteDistance(List<LatLng> route) {
    if (route.length < 2) return 0.0;
    
    double totalDistance = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      totalDistance += calculateDistance(route[i], route[i + 1]);
    }
    return totalDistance;
  }

  /// Find the closest point on a route to a given location
  /// Returns the index of the closest point and the distance to it
  RoutePosition findClosestPointOnRoute(List<LatLng> route, LatLng location) {
    if (route.isEmpty) {
      return RoutePosition(index: 0, distance: double.infinity);
    }

    int closestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < route.length; i++) {
      final distance = calculateDistance(route[i], location);
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return RoutePosition(index: closestIndex, distance: minDistance);
  }

  /// Calculate remaining distance from current position to end of route
  double calculateRemainingDistance(List<LatLng> route, LatLng currentPosition) {
    final closestPoint = findClosestPointOnRoute(route, currentPosition);
    
    if (closestPoint.index >= route.length - 1) {
      return calculateDistance(currentPosition, route.last);
    }

    // Distance from current position to closest point on route
    double remainingDistance = calculateDistance(currentPosition, route[closestPoint.index]);
    
    // Add distance for remaining route segments
    for (int i = closestPoint.index; i < route.length - 1; i++) {
      remainingDistance += calculateDistance(route[i], route[i + 1]);
    }

    return remainingDistance;
  }

  /// Get turn-by-turn instruction based on route progress
  String getRouteInstruction(List<LatLng> route, LatLng currentPosition, double remainingDistance) {
    if (remainingDistance < 10) {
      return 'You have arrived!';
    } else if (remainingDistance < 50) {
      return 'You are very close - ${formatDistance(remainingDistance)}';
    } else {
      final closestPoint = findClosestPointOnRoute(route, currentPosition);
      if (closestPoint.index < route.length - 1) {
        final nextPoint = route[closestPoint.index + 1];
        final bearing = calculateBearing(currentPosition, nextPoint);
        final direction = getDirectionText(bearing);
        return 'Continue ${direction.toLowerCase()} - ${formatDistance(remainingDistance)}';
      } else {
        final destination = route.last;
        final bearing = calculateBearing(currentPosition, destination);
        final direction = getDirectionText(bearing);
        return 'Head ${direction.toLowerCase()} - ${formatDistance(remainingDistance)}';
      }
    }
  }
}

/// Position on a route
class RoutePosition {
  final int index;
  final double distance;

  const RoutePosition({
    required this.index,
    required this.distance,
  });
}