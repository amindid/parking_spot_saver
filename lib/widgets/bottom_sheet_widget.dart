import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/parking_spot.dart';
import '../services/location_service.dart';

class ParkingSpotBottomSheet extends StatelessWidget {
  final ParkingSpot parkingSpot;
  final VoidCallback onClearSpot;
  final VoidCallback onNavigateToSpot;
  final VoidCallback onExternalNavigation;
  final VoidCallback? onClose;

  const ParkingSpotBottomSheet({
    super.key,
    required this.parkingSpot,
    required this.onClearSpot,
    required this.onNavigateToSpot,
    required this.onExternalNavigation,
    this.onClose,
  });

  Future<void> _navigateWithExternalMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${parkingSpot.latitude},${parkingSpot.longitude}&travelmode=walking',
    );
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<String> _getDistanceText() async {
    final currentPosition = await LocationService.instance.getCurrentPosition();
    if (currentPosition == null) return '';
    
    final distance = LocationService.instance.calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      parkingSpot.latitude,
      parkingSpot.longitude,
    );
    
    if (distance < 1000) {
      return '${distance.round()}m away';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km away';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.15,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Title row with close button
              Row(
                children: [
                  const Icon(
                    Icons.local_parking,
                    color: Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      parkingSpot.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (onClose != null)
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Location details
              _buildDetailRow(
                Icons.location_on,
                'Location',
                parkingSpot.getFormattedCoordinates(),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.access_time,
                'Saved',
                parkingSpot.getFormattedTimestamp(),
              ),
              const SizedBox(height: 12),
              
              // Distance info
              FutureBuilder<String>(
                future: _getDistanceText(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return Column(
                      children: [
                        _buildDetailRow(
                          Icons.straighten,
                          'Distance',
                          snapshot.data!,
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 12),
              
              // Primary navigation button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onNavigateToSpot,
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navigate to Car'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Secondary actions row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _navigateWithExternalMaps,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('External Maps'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showClearConfirmationDialog(context);
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Spot'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showClearConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Parking Spot'),
          content: const Text('Are you sure you want to clear the saved parking spot?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onClearSpot();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
}

/// Show parking spot details in a modal bottom sheet
Future<void> showParkingSpotBottomSheet({
  required BuildContext context,
  required ParkingSpot parkingSpot,
  required VoidCallback onClearSpot,
  required VoidCallback onNavigateToSpot,
  VoidCallback? onExternalNavigation,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ParkingSpotBottomSheet(
      parkingSpot: parkingSpot,
      onClearSpot: () {
        Navigator.of(context).pop();
        onClearSpot();
      },
      onNavigateToSpot: () {
        Navigator.of(context).pop();
        onNavigateToSpot();
      },
      onExternalNavigation: onExternalNavigation ?? () {},
      onClose: () => Navigator.of(context).pop(),
    ),
  );
}