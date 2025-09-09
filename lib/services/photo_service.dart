import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling photo capture and gallery selection
/// Manages camera permissions, photo storage, and file management
class PhotoService {
  static PhotoService? _instance;
  static final ImagePicker _picker = ImagePicker();

  PhotoService._internal();

  static PhotoService get instance {
    _instance ??= PhotoService._internal();
    return _instance!;
  }

  /// Capture photo using device camera
  /// Returns path to saved photo or null if cancelled/failed
  Future<String?> capturePhoto() async {
    try {
      developer.log('PhotoService: Starting camera capture');
      print('PhotoService: Starting camera capture');
      
      // Skip permission check for web platforms
      if (!kIsWeb && !Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
        // Check camera permission only on mobile platforms
        developer.log('PhotoService: Checking camera permissions');
        final cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) {
          developer.log('Camera permission denied');
          print('Camera permission denied');
          return null;
        }
        developer.log('PhotoService: Camera permission granted');
      } else {
        developer.log('PhotoService: Skipping permission check for web/desktop');
        print('PhotoService: Skipping permission check for web/desktop');
      }

      developer.log('PhotoService: Calling image picker');
      print('PhotoService: Calling image picker for camera');
      
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );

      developer.log('PhotoService: Image picker returned: ${photo?.path ?? 'null'}');
      print('PhotoService: Image picker returned: ${photo?.path ?? 'null'}');

      if (photo != null) {
        final savedPath = await _savePhotoToAppDirectory(photo);
        developer.log('PhotoService: Photo saved to: $savedPath');
        print('PhotoService: Photo saved to: $savedPath');
        return savedPath;
      } else {
        developer.log('PhotoService: User cancelled camera');
        print('PhotoService: User cancelled camera');
      }
    } catch (e) {
      developer.log('Camera capture error: $e');
      print('Camera capture error: $e');
    }
    return null;
  }

  /// Select photo from device gallery
  /// Returns path to saved photo or null if cancelled/failed
  Future<String?> pickFromGallery() async {
    try {
      developer.log('PhotoService: Starting gallery pick');
      print('PhotoService: Starting gallery pick');
      
      // Skip permission check for web platforms
      if (!kIsWeb && !Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
        // Check photo permission only on mobile platforms
        developer.log('PhotoService: Checking photo permissions');
        final photoStatus = await Permission.photos.request();
        if (!photoStatus.isGranted) {
          // Try storage permission as fallback
          final storageStatus = await Permission.storage.request();
          if (!storageStatus.isGranted) {
            developer.log('Photo/storage permission denied');
            print('Photo/storage permission denied');
            return null;
          }
        }
        developer.log('PhotoService: Photo permission granted');
      } else {
        developer.log('PhotoService: Skipping permission check for web/desktop');
        print('PhotoService: Skipping permission check for web/desktop');
      }

      developer.log('PhotoService: Calling image picker for gallery');
      print('PhotoService: Calling image picker for gallery');
      
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      developer.log('PhotoService: Gallery picker returned: ${photo?.path ?? 'null'}');
      print('PhotoService: Gallery picker returned: ${photo?.path ?? 'null'}');

      if (photo != null) {
        final savedPath = await _savePhotoToAppDirectory(photo);
        developer.log('PhotoService: Photo saved from gallery to: $savedPath');
        print('PhotoService: Photo saved from gallery to: $savedPath');
        return savedPath;
      } else {
        developer.log('PhotoService: User cancelled gallery selection');
        print('PhotoService: User cancelled gallery selection');
      }
    } catch (e) {
      developer.log('Gallery selection error: $e');
      print('Gallery selection error: $e');
    }
    return null;
  }

  /// Save photo from XFile to app's document directory
  /// Returns the absolute path to the saved photo
  Future<String> _savePhotoToAppDirectory(XFile photo) async {
    try {
      if (kIsWeb) {
        // For web, we can't save to filesystem, so return the original path
        // In a real web app, you'd upload to a server or use IndexedDB
        developer.log('Web platform: returning original photo path');
        return photo.path;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/parking_photos');
      
      // Create photos directory if it doesn't exist
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      // Create unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'parking_${timestamp}.jpg';
      final savedPath = '${photosDir.path}/$fileName';

      // Copy photo to app directory
      final photoBytes = await photo.readAsBytes();
      final savedFile = await File(savedPath).writeAsBytes(photoBytes);

      developer.log('Photo saved to: ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      developer.log('Error saving photo: $e');
      throw Exception('Failed to save photo: $e');
    }
  }

  /// Delete photo file from storage
  /// Returns true if successfully deleted
  Future<bool> deletePhoto(String photoPath) async {
    try {
      if (kIsWeb) {
        // On web, we can't delete files from the browser cache
        // In a real web app, you'd send a delete request to the server
        developer.log('Web platform: cannot delete photo file: $photoPath');
        return true; // Return true to avoid errors in UI
      }

      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        developer.log('Photo deleted: $photoPath');
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Error deleting photo: $e');
      return false;
    }
  }

  /// Check if photo file exists at given path
  Future<bool> photoExists(String photoPath) async {
    try {
      if (kIsWeb) {
        // On web, assume photo exists if path is not empty
        return photoPath.isNotEmpty;
      }
      return await File(photoPath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Get file size of photo in bytes
  Future<int> getPhotoSize(String photoPath) async {
    try {
      if (kIsWeb) {
        // On web, we can't easily get file size
        // Return a placeholder size
        return 0;
      }

      final file = File(photoPath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Format file size for display (bytes to KB/MB)
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// Clean up old photos that are no longer referenced
  /// This should be called periodically to free up storage space
  Future<void> cleanupOrphanedPhotos(List<String> referencedPhotoPaths) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/parking_photos');

      if (!await photosDir.exists()) return;

      final files = await photosDir.list().toList();
      int deletedCount = 0;

      for (final file in files) {
        if (file is File && file.path.endsWith('.jpg')) {
          // If photo is not referenced by any parking spot, delete it
          if (!referencedPhotoPaths.contains(file.path)) {
            await file.delete();
            deletedCount++;
            developer.log('Cleaned up orphaned photo: ${file.path}');
          }
        }
      }

      if (deletedCount > 0) {
        developer.log('Cleaned up $deletedCount orphaned photos');
      }
    } catch (e) {
      developer.log('Error during photo cleanup: $e');
    }
  }

  /// Check camera and photo permissions status
  Future<Map<String, bool>> checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final photoStatus = await Permission.photos.status;
    final storageStatus = await Permission.storage.status;

    return {
      'camera': cameraStatus.isGranted,
      'photos': photoStatus.isGranted || storageStatus.isGranted,
    };
  }

  /// Show permission rationale for camera access
  String getCameraPermissionRationale() {
    return 'Camera access is needed to take photos of your parked car location. '
           'This helps you visually identify your parking spot.';
  }

  /// Show permission rationale for photo access
  String getPhotoPermissionRationale() {
    return 'Photo access is needed to select images from your gallery. '
           'You can choose existing photos to associate with parking spots.';
  }
}