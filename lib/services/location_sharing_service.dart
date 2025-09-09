import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/parking_spot.dart';

/// Service for sharing parking spot locations and coordinates
/// Simplified to only provide Copy Coordinates and Share Google Maps Link
class LocationSharingService {
  static LocationSharingService? _instance;

  LocationSharingService._internal();

  static LocationSharingService get instance {
    _instance ??= LocationSharingService._internal();
    return _instance!;
  }

  /// Copy coordinates to clipboard
  static Future<void> copyCoordinatesToClipboard(ParkingSpot spot) async {
    final coordinates = '${spot.latitude.toStringAsFixed(6)}, ${spot.longitude.toStringAsFixed(6)}';
    await Clipboard.setData(ClipboardData(text: coordinates));
    developer.log('Coordinates copied to clipboard: $coordinates');
  }

  /// Copy Google Maps link to clipboard
  static Future<void> copyGoogleMapsLink(ParkingSpot spot) async {
    final googleMapsUrl = 'https://maps.google.com/?q=${spot.latitude},${spot.longitude}';
    await Clipboard.setData(ClipboardData(text: googleMapsUrl));
    developer.log('Google Maps link copied to clipboard for spot: ${spot.name}');
  }
}