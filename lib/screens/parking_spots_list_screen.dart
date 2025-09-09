import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/parking_spot.dart';
import '../services/storage_service.dart';
import '../services/location_sharing_service.dart';
import '../services/photo_service.dart';
import '../services/message_service.dart';
import '../widgets/spot_details_dialog.dart';
import '../widgets/cross_platform_image.dart';

/// Screen displaying all saved parking spots with management options
class ParkingSpotsListScreen extends StatefulWidget {
  final Function(ParkingSpot)? onNavigateToSpot;
  final VoidCallback? onSpotsChanged;

  const ParkingSpotsListScreen({
    Key? key,
    this.onNavigateToSpot,
    this.onSpotsChanged,
  }) : super(key: key);

  @override
  State<ParkingSpotsListScreen> createState() => _ParkingSpotsListScreenState();
}

class _ParkingSpotsListScreenState extends State<ParkingSpotsListScreen> {
  List<ParkingSpot> _spots = [];
  bool _isLoading = true;
  String _searchQuery = '';
  ParkingSpotSortType _sortType = ParkingSpotSortType.newest;

  @override
  void initState() {
    super.initState();
    _loadSpots();
  }

  Future<void> _loadSpots() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final spots = await StorageService.instance.getAllSpots();
      if (mounted) {
        setState(() {
          _spots = spots;
          _sortSpots();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        MessageService.showMessage(context, 'Failed to load parking spots', isError: true);
      }
    }
  }

  void _sortSpots() {
    switch (_sortType) {
      case ParkingSpotSortType.newest:
        _spots.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case ParkingSpotSortType.oldest:
        _spots.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case ParkingSpotSortType.alphabetical:
        _spots.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
  }

  List<ParkingSpot> get _filteredSpots {
    if (_searchQuery.isEmpty) return _spots;
    
    final query = _searchQuery.toLowerCase();
    return _spots.where((spot) {
      return spot.name.toLowerCase().contains(query) ||
             (spot.notes?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Future<void> _deleteSpot(ParkingSpot spot) async {
    final confirmed = await _showConfirmationDialog(
      'Delete Parking Spot',
      'Are you sure you want to delete "${spot.name}"? This action cannot be undone.',
    );

    if (!confirmed) return;

    try {
      await StorageService.instance.deleteSpot(spot.id);
      
      // Delete associated photo if it exists
      if (spot.photoPath != null) {
        await PhotoService.instance.deletePhoto(spot.photoPath!);
      }

      if (mounted) {
        _loadSpots();
        widget.onSpotsChanged?.call();
        MessageService.showMessage(context, 'Parking spot deleted!');
      }
    } catch (e) {
      if (mounted) {
        MessageService.showMessage(context, 'Failed to delete parking spot', isError: true);
      }
    }
  }

  Future<void> _shareSpot(ParkingSpot spot) async {
    try {
      await LocationSharingService.copyGoogleMapsLink(spot);
      if (mounted) {
        MessageService.showMessage(context, 'Google Maps link copied to clipboard!');
      }
    } catch (e) {
      if (mounted) {
        MessageService.showMessage(context, 'Error copying Google Maps link', isError: true);
      }
    }
  }

  Future<void> _copyCoordinates(ParkingSpot spot) async {
    try {
      await LocationSharingService.copyCoordinatesToClipboard(spot);
      if (mounted) {
        MessageService.showMessage(context, 'Coordinates copied to clipboard!');
      }
    } catch (e) {
      if (mounted) {
        MessageService.showMessage(context, 'Error copying coordinates', isError: true);
      }
    }
  }

  void _navigateToSpot(ParkingSpot spot) {
    widget.onNavigateToSpot?.call(spot);
    Navigator.of(context).pop();
  }

  Future<void> _showSpotDetails(ParkingSpot spot) async {
    final result = await showSpotDetailsDialog(
      context,
      spot,
      onNavigate: () => _navigateToSpot(spot),
      onShare: () => _shareSpot(spot),
      onDelete: () => _deleteSpot(spot),
    );

    if (result == true) {
      _loadSpots();
      widget.onSpotsChanged?.call();
    }
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }


  Widget _buildSearchAndSort() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search field
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search parking spots...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          
          // Sort options
          Row(
            children: [
              const Text(
                'Sort by:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SegmentedButton<ParkingSpotSortType>(
                  segments: const [
                    ButtonSegment(
                      value: ParkingSpotSortType.newest,
                      label: Text(
                        'Newest',
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      icon: Icon(Icons.access_time, size: 16),
                    ),
                    ButtonSegment(
                      value: ParkingSpotSortType.oldest,
                      label: Text(
                        'Oldest',
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      icon: Icon(Icons.history, size: 16),
                    ),
                    ButtonSegment(
                      value: ParkingSpotSortType.alphabetical,
                      label: Text(
                        'A-Z',
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      icon: Icon(Icons.sort_by_alpha, size: 16),
                    ),
                  ],
                  selected: {_sortType},
                  onSelectionChanged: (selected) {
                    setState(() {
                      _sortType = selected.first;
                      _sortSpots();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpotCard(ParkingSpot spot) {
    final timeAgo = _getTimeAgoString(spot.timestamp);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showSpotDetails(spot),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Photo or icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
                child: spot.photoPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CrossPlatformImage(
                          imagePath: spot.photoPath!,
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.local_parking,
                              color: Colors.grey,
                              size: 30,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.local_parking,
                        color: Colors.grey,
                        size: 30,
                      ),
              ),
              const SizedBox(width: 16),
              
              // Spot details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    if (spot.notes != null && spot.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        spot.notes!,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Action menu
              PopupMenuButton<String>(
                onSelected: (action) async {
                  switch (action) {
                    case 'navigate':
                      _navigateToSpot(spot);
                      break;
                    case 'share':
                      await _shareSpot(spot);
                      break;
                    case 'copy':
                      await _copyCoordinates(spot);
                      break;
                    case 'delete':
                      await _deleteSpot(spot);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'navigate',
                    child: Row(
                      children: [
                        Icon(Icons.navigation),
                        SizedBox(width: 8),
                        Text('Navigate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'copy',
                    child: Row(
                      children: [
                        Icon(Icons.copy),
                        SizedBox(width: 8),
                        Text('Copy Coordinates'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.link),
                        SizedBox(width: 8),
                        Text('Copy Google Maps Link'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgoString(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_parking_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No parking spots saved yet'
                : 'No spots match your search',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Start by saving a parking location'
                : 'Try a different search term',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Parking Spots'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadSpots,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchAndSort(),
                Expanded(
                  child: _filteredSpots.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: _filteredSpots.length,
                          itemBuilder: (context, index) {
                            return _buildSpotCard(_filteredSpots[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Back to Map',
        child: const Icon(Icons.map),
      ),
    );
  }
}

enum ParkingSpotSortType {
  newest,
  oldest,
  alphabetical,
}