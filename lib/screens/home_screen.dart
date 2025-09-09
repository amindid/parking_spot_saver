import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../models/parking_spot.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/navigation_service.dart';
import '../services/routing_service.dart';
import '../services/photo_service.dart';
import '../services/message_service.dart';
import '../config/api_config.dart';
import '../widgets/bottom_sheet_widget.dart';
import '../widgets/save_spot_dialog.dart';
import '../widgets/spot_details_dialog.dart';
import '../screens/parking_spots_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  List<ParkingSpot> _savedParkingSpots = [];
  ParkingSpot? _navigationTargetSpot;
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  bool _isLoading = true;
  bool _locationPermissionDenied = false;
  String? _errorMessage;

  // Manual selection state
  bool _isInSelectionMode = false;
  LatLng? _temporarySelectedLocation;
  
  // Navigation state
  bool _isNavigating = false;
  bool _isLoadingRoute = false;
  RouteResult? _currentRoute;
  double? _navigationDistance;
  double? _navigationBearing;
  String? _navigationDirection;
  double? _remainingDistance;
  double? _estimatedDuration;
  bool _isRoadBased = false;
  String? _routingErrorMessage;
  StreamSubscription<Position>? _navigationLocationSubscription;
  Timer? _navigationUpdateTimer;
  
  // Animation controllers for UI feedback
  late AnimationController _selectionModeController;
  late Animation<double> _selectionModeAnimation;
  late AnimationController _navigationController;
  late Animation<double> _navigationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _selectionModeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _selectionModeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _selectionModeController,
      curve: Curves.easeInOut,
    ));

    _navigationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _navigationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _navigationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _selectionModeController.dispose();
    _navigationController.dispose();
    _navigationLocationSubscription?.cancel();
    _navigationUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _loadSavedParkingSpots();
    await _getCurrentLocation();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadSavedParkingSpots() async {
    try {
      final savedSpots = await StorageService.instance.getAllSpots();
      setState(() {
        _savedParkingSpots = savedSpots;
      });
      _updateMarkers();
    } catch (e) {
      MessageService.showMessage(context, 'Failed to load saved parking spots', isError: true);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _locationPermissionDenied = false;
          _errorMessage = null;
        });
        _updateMarkers();
        if (!_isNavigating) {
          _moveToCurrentLocation();
        }
        
        // Update navigation info if currently navigating
        if (_isNavigating && _navigationTargetSpot != null) {
          _updateNavigationInfo();
        }
      } else {
        setState(() {
          _locationPermissionDenied = true;
          _errorMessage = 'Location permission denied or service unavailable';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get current location: ${e.toString()}';
      });
    }
  }

  void _updateMarkers() {
    final markers = <Marker>[];

    // Add current location marker (blue circle) - only show if not in selection or navigation mode
    if (_currentPosition != null && !_isInSelectionMode && !_isNavigating) {
      markers.add(
        Marker(
          width: 20.0,
          height: 20.0,
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.7),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      );
    }

    // Add navigation current location marker (larger blue circle with pulse effect)
    if (_currentPosition != null && _isNavigating) {
      markers.add(
        Marker(
          width: 30.0,
          height: 30.0,
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          child: AnimatedBuilder(
            animation: _navigationAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.3 + 0.4 * _navigationAnimation.value),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8 * _navigationAnimation.value,
                      spreadRadius: 2 * _navigationAnimation.value,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 16,
                ),
              );
            },
          ),
        ),
      );
    }

    // Add temporary selection marker (orange/yellow marker)
    if (_temporarySelectedLocation != null && _isInSelectionMode) {
      markers.add(
        Marker(
          width: 45.0,
          height: 45.0,
          point: _temporarySelectedLocation!,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.location_pin,
              color: Colors.orange,
              size: 28,
            ),
          ),
        ),
      );
    }

    // Add all saved parking spot markers
    if (_savedParkingSpots.isNotEmpty && !_isInSelectionMode) {
      for (final spot in _savedParkingSpots) {
        final isNavigationTarget = _navigationTargetSpot?.id == spot.id;
        markers.add(
          Marker(
            width: 40.0,
            height: 40.0,
            point: LatLng(spot.latitude, spot.longitude),
            child: GestureDetector(
              onTap: () => _showSpotDetails(spot),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.local_parking,
                  color: isNavigationTarget
                      ? Colors.green
                      : (_isNavigating ? Colors.grey : Colors.red),
                  size: 24,
                ),
              ),
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });

    // Update polylines for navigation
    _updatePolylines();
  }

  void _updatePolylines() {
    final polylines = <Polyline>[];

    // Add navigation route line
    if (_isNavigating && _currentRoute != null && _currentRoute!.route.length >= 2) {
      polylines.add(
        Polyline(
          points: _currentRoute!.route,
          strokeWidth: 5.0,
          color: _currentRoute!.isRoadBased ? Colors.blue : Colors.blue.withOpacity(0.7),
          borderStrokeWidth: 2.0,
          borderColor: Colors.white,
          isDotted: !_currentRoute!.isRoadBased,
        ),
      );
    }

    setState(() {
      _polylines = polylines;
    });
  }

  void _moveToCurrentLocation() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        16.0,
      );
    }
  }

  // Manual selection methods
  void _enterSelectionMode() {
    setState(() {
      _isInSelectionMode = true;
      _temporarySelectedLocation = null;
    });
    _selectionModeController.forward();
    _updateMarkers();
    MessageService.showMessage(context, 'Tap on the map to select parking location');
  }

  void _exitSelectionMode() {
    setState(() {
      _isInSelectionMode = false;
      _temporarySelectedLocation = null;
    });
    _selectionModeController.reverse();
    _updateMarkers();
  }

  void _onMapTapped(TapPosition tapPosition, LatLng point) {
    if (_isInSelectionMode) {
      setState(() {
        _temporarySelectedLocation = point;
      });
      _updateMarkers();
    } else if (!_isNavigating) {
      // Hide keyboard/focus when map is tapped in normal mode
      FocusScope.of(context).unfocus();
    }
  }

  void _confirmManualSelection() {
    if (_temporarySelectedLocation != null) {
      _saveManualLocation();
    }
  }

  Future<void> _saveCurrentLocation() async {
    if (_currentPosition == null) {
      MessageService.showMessage(context, 'Location access needed', isError: true);
      return;
    }

    final location = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    await _showSaveSpotDialog(location);
  }

  Future<void> _saveManualLocation() async {
    if (_temporarySelectedLocation == null) {
      MessageService.showMessage(context, 'No location selected', isError: true);
      return;
    }

    await _showSaveSpotDialog(_temporarySelectedLocation!);
    _exitSelectionMode();
  }

  Future<void> _showSaveSpotDialog(LatLng location) async {
    final result = await showSaveSpotDialog(
      context,
      location,
      onSpotSaved: () {
        _loadSavedParkingSpots();
        _updateMarkers();
      },
    );

    if (result == true) {
      MessageService.showMessage(context, 'Parking spot saved!');
    }
  }

  Future<void> _showSpotDetails(ParkingSpot spot) async {
    await showParkingSpotBottomSheet(
      context: context,
      parkingSpot: spot,
      onClearSpot: () => _deleteSpot(spot),
      onNavigateToSpot: () => _startNavigationToSpot(spot),
    );
  }

  Future<void> _deleteSpot(ParkingSpot spot) async {
    try {
      await StorageService.instance.deleteSpot(spot.id);
      
      // Delete associated photo if it exists
      if (spot.photoPath != null) {
        await PhotoService.instance.deletePhoto(spot.photoPath!);
      }

      // Stop navigation if navigating to deleted spot
      if (_navigationTargetSpot?.id == spot.id) {
        _endNavigation();
      }

      await _loadSavedParkingSpots();
      _updateMarkers();
      MessageService.showMessage(context, 'Parking spot deleted!');
    } catch (e) {
      MessageService.showMessage(context, 'Failed to delete parking spot', isError: true);
    }
  }

  void _openParkingSpotsList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParkingSpotsListScreen(
          onNavigateToSpot: (spot) => _startNavigationToSpot(spot),
          onSpotsChanged: () => _loadSavedParkingSpots(),
        ),
      ),
    );
  }

  // Navigation methods
  Future<void> _startNavigationToSpot(ParkingSpot spot) async {
    if (_currentPosition == null) {
      MessageService.showMessage(context, 'Location access needed', isError: true);
      return;
    }

    setState(() {
      _navigationTargetSpot = spot;
      _isNavigating = true;
      _isLoadingRoute = true;
      _routingErrorMessage = null;
    });

    _navigationController.forward();

    try {
      // Get road-based route
      final currentLatLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      final destinationLatLng = LatLng(spot.latitude, spot.longitude);
      
      final route = await NavigationService.instance.getWalkingRoute(currentLatLng, destinationLatLng);
      
      setState(() {
        _currentRoute = route;
        _remainingDistance = route.distance;
        _estimatedDuration = route.duration;
        _isRoadBased = route.isRoadBased;
        _routingErrorMessage = route.errorMessage;
        _isLoadingRoute = false;
      });

      _updateNavigationInfo();
      _centerMapOnRoute();
      _startLocationTracking();
      
      String message = 'Navigation started';
      if (route.isRoadBased) {
        message += ' with road-based routing';
      } else if (route.errorMessage != null) {
        message = 'Navigation started (${route.errorMessage})';
      }
      
      MessageService.showMessage(context, 'Navigation started!');
    } catch (e) {
      setState(() {
        _isLoadingRoute = false;
        _routingErrorMessage = 'Failed to calculate route';
      });
      MessageService.showMessage(context, 'Failed to start navigation', isError: true);
    }
  }

  void _endNavigation() {
    setState(() {
      _isNavigating = false;
      _isLoadingRoute = false;
      _currentRoute = null;
      _navigationDistance = null;
      _navigationBearing = null;
      _navigationDirection = null;
      _remainingDistance = null;
      _estimatedDuration = null;
      _isRoadBased = false;
      _routingErrorMessage = null;
    });

    _navigationController.reverse();
    _stopLocationTracking();
    _updateMarkers();
    MessageService.showMessage(context, 'Navigation ended');
  }

  void _updateNavigationInfo() {
    if (_currentPosition == null || _navigationTargetSpot == null) return;

    final currentLatLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final destinationLatLng = LatLng(_navigationTargetSpot!.latitude, _navigationTargetSpot!.longitude);

    if (_currentRoute != null && _currentRoute!.route.length >= 2) {
      // Use route-based calculations for more accurate distance
      final remainingDist = NavigationService.instance.calculateRemainingDistance(
        _currentRoute!.route, 
        currentLatLng
      );
      
      setState(() {
        _remainingDistance = remainingDist;
        _navigationDistance = remainingDist;
      });
    } else {
      // Fallback to straight-line calculation
      final distance = NavigationService.instance.calculateDistance(currentLatLng, destinationLatLng);
      setState(() {
        _navigationDistance = distance;
        _remainingDistance = distance;
      });
    }

    // Update bearing and direction
    final bearing = NavigationService.instance.calculateBearing(currentLatLng, destinationLatLng);
    final direction = NavigationService.instance.getDirectionText(bearing);

    setState(() {
      _navigationBearing = bearing;
      _navigationDirection = direction;
    });

    // Check if destination is reached
    if (NavigationService.instance.isDestinationReached(currentLatLng, destinationLatLng)) {
      MessageService.showMessage(context, '🎉 You have arrived at your parking spot!');
      _endNavigation();
    }
  }

  void _centerMapOnRoute() {
    if (_currentPosition == null || _navigationTargetSpot == null) return;

    if (_currentRoute != null && _currentRoute!.route.length >= 2) {
      // Center on the full route
      final bounds = NavigationService.instance.calculateBounds(
        _currentRoute!.route.first,
        _currentRoute!.route.last,
      );
      
      final center = LatLng(
        (bounds['minLat']! + bounds['maxLat']!) / 2,
        (bounds['minLng']! + bounds['maxLng']!) / 2,
      );
      
      final zoom = NavigationService.instance.calculateZoomLevel(
        _currentRoute!.route.first,
        _currentRoute!.route.last,
      );
      
      _mapController.move(center, zoom);
    } else {
      // Fallback to simple center calculation
      final currentLatLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      final destinationLatLng = LatLng(_navigationTargetSpot!.latitude, _navigationTargetSpot!.longitude);

      final center = NavigationService.instance.calculateCenterPoint(currentLatLng, destinationLatLng);
      final zoom = NavigationService.instance.calculateZoomLevel(currentLatLng, destinationLatLng);

      _mapController.move(center, zoom);
    }
  }

  void _startLocationTracking() {
    // Start real-time location updates
    _navigationLocationSubscription = LocationService.instance.getPositionStream().listen(
      (Position position) {
        setState(() {
          _currentPosition = position;
        });
        _updateMarkers();
        _updateNavigationInfo();
      },
      onError: (error) {
        MessageService.showMessage(context, 'Location tracking error', isError: true);
      },
    );

    // Start periodic navigation updates
    _navigationUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isNavigating) {
        _updateNavigationInfo();
      } else {
        timer.cancel();
      }
    });
  }

  void _stopLocationTracking() {
    _navigationLocationSubscription?.cancel();
    _navigationUpdateTimer?.cancel();
    _navigationLocationSubscription = null;
    _navigationUpdateTimer = null;
  }

  Future<void> _clearParkingSpot() async {
    try {
      await StorageService.instance.clearAllSpots();
      setState(() {
        _savedParkingSpots = [];
        _navigationTargetSpot = null;
      });
      
      // End navigation if it was active
      if (_isNavigating) {
        _endNavigation();
      }
      
      _updateMarkers();
      MessageService.showMessage(context, 'Parking spot cleared!');
    } catch (e) {
      MessageService.showMessage(context, 'Failed to clear parking spot', isError: true);
    }
  }


  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'This app needs location permission to save and find your parking spot. Please enable location access in your device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await LocationService.instance.openLocationSettings();
              },
              child: const Text('Settings'),
            ),
          ],
        );
      },
    );
  }

  String _getSelectedLocationText() {
    if (_temporarySelectedLocation == null) return '';
    return '${_temporarySelectedLocation!.latitude.toStringAsFixed(6)}, ${_temporarySelectedLocation!.longitude.toStringAsFixed(6)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNavigating ? 'Navigating to Car' : 'Parking Spot Saver'),
        backgroundColor: _isNavigating ? Colors.green : Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isNavigating)
            IconButton(
              onPressed: _endNavigation,
              icon: const Icon(Icons.close),
              tooltip: 'End Navigation',
            )
          else if (_isInSelectionMode)
            IconButton(
              onPressed: _exitSelectionMode,
              icon: const Icon(Icons.close),
              tooltip: 'Cancel Selection',
            )
          else
            IconButton(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.my_location),
              tooltip: 'Get Current Location',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            )
          : _locationPermissionDenied
              ? _buildLocationPermissionView()
              : Stack(
                  children: [
                    _buildMapView(),
                    if (_isInSelectionMode) _buildSelectionModeOverlay(),
                    if (_isNavigating) _buildNavigationOverlay(),
                    if (_isInSelectionMode && _temporarySelectedLocation != null)
                      _buildConfirmCancelButtons(),
                  ],
                ),
      floatingActionButton: _buildFloatingActionButton(),
      // Remove persistent bottom sheet - use modal instead
    );
  }

  Widget _buildFloatingActionButton() {
    if (_isInSelectionMode || _isNavigating || _currentPosition == null) {
      return const SizedBox.shrink();
    }

    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      buttonSize: const Size(56, 56),
      childrenButtonSize: const Size(56, 56),
      spacing: 12,
      spaceBetweenChildren: 12,
      tooltip: 'Menu',
      children: [
        SpeedDialChild(
          child: const Icon(Icons.my_location),
          label: 'Save Current Location',
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          onTap: _saveCurrentLocation,
        ),
        SpeedDialChild(
          child: const Icon(Icons.map),
          label: 'Select on Map',
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          onTap: _enterSelectionMode,
        ),
        SpeedDialChild(
          child: const Icon(Icons.list),
          label: 'View All Spots',
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          onTap: _openParkingSpotsList,
        ),
      ],
    );
  }

  Widget _buildSelectionModeOverlay() {
    return AnimatedBuilder(
      animation: _selectionModeAnimation,
      builder: (context, child) {
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Transform.translate(
            offset: Offset(0, -50 * (1 - _selectionModeAnimation.value)),
            child: Opacity(
              opacity: _selectionModeAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Select Parking Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap anywhere on the map to choose parking spot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    if (_temporarySelectedLocation != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Selected: ${_getSelectedLocationText()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationOverlay() {
    return AnimatedBuilder(
      animation: _navigationAnimation,
      builder: (context, child) {
        return Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - _navigationAnimation.value)),
            child: Opacity(
              opacity: _navigationAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: _isLoadingRoute ? _buildLoadingRouteUI() : _buildNavigationUI(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingRouteUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Finding best walking route...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (!ApiConfig.isApiKeyConfigured) ...[
          const SizedBox(height: 12),
          Text(
            'Configure OpenRouteService API key for road-based routing',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _endNavigation,
            icon: const Icon(Icons.stop),
            label: const Text('Cancel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationUI() {
    return Column(
      children: [
        // Header with route type indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isRoadBased ? Icons.route : Icons.navigation,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'Navigate to Car',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_currentRoute != null)
                    Text(
                      _isRoadBased ? 'Road-based route' : 'Straight-line route',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Distance, Duration, and Direction Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Distance
            Column(
              children: [
                Text(
                  _remainingDistance != null
                      ? NavigationService.instance.formatDistance(_remainingDistance!)
                      : '--',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Distance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            // Duration (if available)
            if (_estimatedDuration != null)
              Column(
                children: [
                  Text(
                    RoutingService.instance.formatDuration(_estimatedDuration!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Est. Time',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            
            // Direction Arrow
            Column(
              children: [
                Text(
                  _navigationBearing != null
                      ? NavigationService.instance.getDirectionArrow(_navigationBearing!)
                      : '❓',
                  style: const TextStyle(
                    fontSize: 32,
                  ),
                ),
                Text(
                  _navigationDirection ?? '--',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Navigation Instruction
        Text(
          _getNavigationInstruction(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        
        // Error message if any
        if (_routingErrorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _routingErrorMessage!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _endNavigation,
            icon: const Icon(Icons.stop),
            label: const Text('End Navigation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  String _getNavigationInstruction() {
    if (_currentRoute != null && _currentPosition != null && _remainingDistance != null) {
      return NavigationService.instance.getRouteInstruction(
        _currentRoute!.route,
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        _remainingDistance!,
      );
    } else if (_navigationDistance != null && _navigationDirection != null) {
      return NavigationService.instance.getNavigationInstruction(_navigationDistance!, _navigationDirection!);
    } else {
      return 'Calculating route...';
    }
  }

  Widget _buildConfirmCancelButtons() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _exitSelectionMode,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _confirmManualSelection,
              icon: const Icon(Icons.check),
              label: const Text('Confirm Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPermissionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_disabled,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              'Location Access Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Please enable location access to use this app.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showLocationPermissionDialog,
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _getCurrentLocation,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    final initialCenter = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : LatLng(33.5731, -7.5898); // Default to Casablanca, Morocco

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 16.0,
        minZoom: 3.0,
        maxZoom: 18.0,
        onTap: _onMapTapped,
        onLongPress: _isInSelectionMode ? _onMapTapped : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.parkingspotsaver',
          tileBuilder: _selectionModeController.value > 0 ? _selectionModeTileBuilder : null,
        ),
        PolylineLayer(
          polylines: _polylines,
        ),
        MarkerLayer(
          markers: _markers,
        ),
        RichAttributionWidget(
          popupInitialDisplayDuration: const Duration(seconds: 5),
          animationConfig: const ScaleRAWA(),
          showFlutterMapAttribution: false,
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () => {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _selectionModeTileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.orange.withOpacity(0.1),
        BlendMode.overlay,
      ),
      child: tileWidget,
    );
  }
}