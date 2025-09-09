import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../models/parking_spot.dart';
import '../services/photo_service.dart';
import '../services/storage_service.dart';
import '../services/message_service.dart';
import 'cross_platform_image.dart';

/// Enhanced dialog for saving parking spots with photo capture and naming
class SaveSpotDialog extends StatefulWidget {
  final LatLng location;
  final VoidCallback? onSpotSaved;

  const SaveSpotDialog({
    Key? key,
    required this.location,
    this.onSpotSaved,
  }) : super(key: key);

  @override
  State<SaveSpotDialog> createState() => _SaveSpotDialogState();
}

class _SaveSpotDialogState extends State<SaveSpotDialog> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  String? _photoPath;
  bool _isSaving = false;
  bool _photoOperationInProgress = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final defaultName = 'Parking ${DateFormat('MMM dd, HH:mm').format(now)}';
    _nameController = TextEditingController(text: defaultName);
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_photoOperationInProgress) return;
    
    setState(() {
      _photoOperationInProgress = true;
    });

    try {
      print('Attempting to capture photo...');
      final photoPath = await PhotoService.instance.capturePhoto();
      print('Photo capture result: $photoPath');
      
      if (photoPath != null && mounted) {
        setState(() {
          _photoPath = photoPath;
        });
        MessageService.showMessage(context, 'Photo added!');
        print('Photo path set: $_photoPath');
      } else if (mounted) {
        MessageService.showMessage(context, 'Camera access needed', isError: true);
        print('Photo capture returned null');
      }
    } catch (e) {
      print('Photo capture error: $e');
      if (mounted) {
        MessageService.showMessage(context, 'Failed to capture photo', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _photoOperationInProgress = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_photoOperationInProgress) return;
    
    setState(() {
      _photoOperationInProgress = true;
    });

    try {
      print('Attempting to pick from gallery...');
      final photoPath = await PhotoService.instance.pickFromGallery();
      print('Gallery pick result: $photoPath');
      
      if (photoPath != null && mounted) {
        setState(() {
          _photoPath = photoPath;
        });
        MessageService.showMessage(context, 'Photo added!');
        print('Photo path set from gallery: $_photoPath');
      } else if (mounted) {
        MessageService.showMessage(context, 'Photo selection cancelled', isError: true);
        print('Gallery pick returned null');
      }
    } catch (e) {
      print('Gallery pick error: $e');
      if (mounted) {
        MessageService.showMessage(context, 'Failed to select photo', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _photoOperationInProgress = false;
        });
      }
    }
  }

  Future<void> _removePhoto() async {
    if (_photoPath == null) return;

    final confirmed = await _showConfirmationDialog(
      'Remove Photo',
      'Are you sure you want to remove the selected photo?',
    );

    if (confirmed && mounted) {
      setState(() {
        _photoPath = null;
      });
      MessageService.showMessage(context, 'Photo removed');
    }
  }

  Future<void> _saveSpot() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      MessageService.showMessage(context, 'Please enter a name for this parking spot', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final spot = ParkingSpot(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        timestamp: DateTime.now(),
        photoPath: _photoPath,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        name: name,
      );

      await StorageService.instance.saveSpot(spot);

      if (mounted) {
        widget.onSpotSaved?.call();
        Navigator.of(context).pop(true);
        MessageService.showMessage(context, 'Parking spot saved!');
      }
    } catch (e) {
      if (mounted) {
        MessageService.showMessage(context, 'Failed to save parking spot', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildPhotoSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_camera, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Photo (Optional)',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              if (_photoPath != null)
                IconButton(
                  onPressed: _removePhoto,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  iconSize: 20,
                  tooltip: 'Remove photo',
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_photoPath != null) ...[
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CrossPlatformImage(
                  imagePath: _photoPath!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 120,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _photoOperationInProgress ? null : _capturePhoto,
                  icon: _photoOperationInProgress
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _photoOperationInProgress ? null : _pickFromGallery,
                  icon: _photoOperationInProgress
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_library, size: 18),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          
          if (_photoPath != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                const Text(
                  'Photo added',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
                const Spacer(),
                FutureBuilder<int>(
                  future: PhotoService.instance.getPhotoSize(_photoPath!),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final size = PhotoService.instance.formatFileSize(snapshot.data!);
                      return Text(
                        size,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ],
        ],
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.add_location_alt, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Save Parking Spot',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Location info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.location.latitude.toStringAsFixed(6)}, ${widget.location.longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Name field
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Spot Name',
                  hintText: 'Enter a name for this parking spot',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              
              // Notes field
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any additional notes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              
              // Photo section
              _buildPhotoSection(),
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveSpot,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save Spot'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
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
}

/// Show the save spot dialog and return whether a spot was saved
Future<bool?> showSaveSpotDialog(
  BuildContext context,
  LatLng location, {
  VoidCallback? onSpotSaved,
}) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => SaveSpotDialog(
      location: location,
      onSpotSaved: onSpotSaved,
    ),
  );
}