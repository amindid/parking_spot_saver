import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/parking_spot.dart';
import '../services/location_sharing_service.dart';
import '../services/message_service.dart';
import 'cross_platform_image.dart';

/// Dialog showing detailed information about a parking spot
class SpotDetailsDialog extends StatelessWidget {
  final ParkingSpot spot;
  final VoidCallback? onNavigate;
  final VoidCallback? onShare;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SpotDetailsDialog({
    Key? key,
    required this.spot,
    this.onNavigate,
    this.onShare,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • HH:mm').format(dateTime);
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    bool isOutlined = false,
  }) {
    return Expanded(
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color ?? Colors.blue),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
    );
  }


  Future<void> _showSharingOptions(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Coordinates'),
              subtitle: const Text('Copy to clipboard'),
              onTap: () async {
                Navigator.of(context).pop();
                await LocationSharingService.copyCoordinatesToClipboard(spot);
                if (context.mounted) {
                  MessageService.showMessage(context, 'Coordinates copied to clipboard!');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copy Google Maps Link'),
              subtitle: const Text('Copy link to clipboard'),
              onTap: () async {
                Navigator.of(context).pop();
                try {
                  await LocationSharingService.copyGoogleMapsLink(spot);
                  if (context.mounted) {
                    MessageService.showMessage(context, 'Google Maps link copied to clipboard!');
                  }
                } catch (e) {
                  if (context.mounted) {
                    MessageService.showMessage(context, 'Error copying Google Maps link', isError: true);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with photo or icon
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                color: Colors.grey.shade200,
              ),
              child: spot.photoPath != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: CrossPlatformImage(
                        imagePath: spot.photoPath!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 180,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.local_parking,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.local_parking,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and close button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          spot.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        iconSize: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Information rows
                  _buildInfoRow(
                    'Saved',
                    _formatDateTime(spot.timestamp),
                    Icons.access_time,
                  ),
                  _buildInfoRow(
                    'Coordinates',
                    '${spot.latitude.toStringAsFixed(6)}, ${spot.longitude.toStringAsFixed(6)}',
                    Icons.location_on,
                  ),
                  
                  if (spot.notes != null && spot.notes!.isNotEmpty)
                    _buildInfoRow(
                      'Notes',
                      spot.notes!,
                      Icons.notes,
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Primary action buttons
                  Row(
                    children: [
                      if (onNavigate != null) ...[
                        _buildActionButton(
                          label: 'Navigate',
                          icon: Icons.navigation,
                          onPressed: () {
                            Navigator.of(context).pop();
                            onNavigate!();
                          },
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                      ],
                      _buildActionButton(
                        label: 'Share',
                        icon: Icons.share,
                        onPressed: () => _showSharingOptions(context),
                        isOutlined: true,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Secondary action buttons
                  Row(
                    children: [
                      if (onEdit != null) ...[
                        _buildActionButton(
                          label: 'Edit',
                          icon: Icons.edit,
                          onPressed: () {
                            Navigator.of(context).pop();
                            onEdit!();
                          },
                          isOutlined: true,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (onDelete != null)
                        _buildActionButton(
                          label: 'Delete',
                          icon: Icons.delete,
                          onPressed: () {
                            Navigator.of(context).pop();
                            onDelete!();
                          },
                          color: Colors.red,
                          isOutlined: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show the spot details dialog
Future<bool?> showSpotDetailsDialog(
  BuildContext context,
  ParkingSpot spot, {
  VoidCallback? onNavigate,
  VoidCallback? onShare,
  VoidCallback? onEdit,
  VoidCallback? onDelete,
}) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => SpotDetailsDialog(
      spot: spot,
      onNavigate: onNavigate,
      onShare: onShare,
      onEdit: onEdit,
      onDelete: onDelete,
    ),
  );
}