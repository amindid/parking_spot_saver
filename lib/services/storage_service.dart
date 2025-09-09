import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/parking_spot.dart';

class StorageService {
  static const String _spotsKey = 'parking_spots';
  static const String _legacySpotKey = 'parking_spot'; // For migration
  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._internal();

  static StorageService get instance {
    _instance ??= StorageService._internal();
    return _instance!;
  }

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _migrateLegacyData();
  }

  /// Migrate old single parking spot to new multiple spots format
  Future<void> _migrateLegacyData() async {
    if (_prefs!.containsKey(_legacySpotKey) && !_prefs!.containsKey(_spotsKey)) {
      final jsonString = _prefs!.getString(_legacySpotKey);
      if (jsonString != null) {
        try {
          final Map<String, dynamic> json = jsonDecode(jsonString);
          
          // Create legacy spot with new required fields
          final legacySpot = ParkingSpot(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            latitude: json['latitude'] as double,
            longitude: json['longitude'] as double,
            timestamp: DateTime.parse(json['timestamp'] as String),
            name: 'Legacy Parking Spot',
            photoPath: null,
            notes: null,
          );
          
          // Save as first spot in new format
          final spots = [legacySpot];
          await _saveAllSpots(spots);
          
          // Remove legacy key
          await _prefs!.remove(_legacySpotKey);
        } catch (e) {
          // Ignore migration errors
        }
      }
    }
  }

  Future<List<ParkingSpot>> getAllSpots() async {
    await _initPrefs();
    final spotsJson = _prefs!.getStringList(_spotsKey) ?? [];
    
    try {
      return spotsJson.map((json) => ParkingSpot.fromJson(jsonDecode(json))).toList();
    } catch (e) {
      // Return empty list if parsing fails
      return [];
    }
  }

  Future<void> saveSpot(ParkingSpot spot) async {
    final spots = await getAllSpots();
    spots.add(spot);
    await _saveAllSpots(spots);
  }

  Future<void> updateSpot(ParkingSpot updatedSpot) async {
    final spots = await getAllSpots();
    final index = spots.indexWhere((spot) => spot.id == updatedSpot.id);
    if (index >= 0) {
      spots[index] = updatedSpot;
      await _saveAllSpots(spots);
    }
  }

  Future<void> deleteSpot(String spotId) async {
    final spots = await getAllSpots();
    spots.removeWhere((spot) => spot.id == spotId);
    await _saveAllSpots(spots);
  }

  Future<ParkingSpot?> getSpotById(String spotId) async {
    final spots = await getAllSpots();
    try {
      return spots.firstWhere((spot) => spot.id == spotId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveAllSpots(List<ParkingSpot> spots) async {
    await _initPrefs();
    final spotsJson = spots.map((spot) => jsonEncode(spot.toJson())).toList();
    await _prefs!.setStringList(_spotsKey, spotsJson);
  }

  Future<bool> hasAnySavedSpots() async {
    final spots = await getAllSpots();
    return spots.isNotEmpty;
  }

  Future<void> clearAllSpots() async {
    await _initPrefs();
    await _prefs!.remove(_spotsKey);
  }

  Future<void> clearAllData() async {
    await _initPrefs();
    await _prefs!.clear();
  }

  // Legacy methods for backward compatibility
  @deprecated
  Future<void> saveParkingSpot(ParkingSpot parkingSpot) async {
    await saveSpot(parkingSpot);
  }

  @deprecated
  Future<ParkingSpot?> loadParkingSpot() async {
    final spots = await getAllSpots();
    return spots.isNotEmpty ? spots.last : null;
  }

  @deprecated
  Future<void> clearParkingSpot() async {
    await clearAllSpots();
  }

  @deprecated
  Future<bool> hasSavedParkingSpot() async {
    return await hasAnySavedSpots();
  }
}