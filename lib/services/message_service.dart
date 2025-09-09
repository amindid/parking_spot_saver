import 'dart:async';
import 'package:flutter/material.dart';

/// Clean message service with overlay-based positioning at 30% from top
class MessageService {
  static OverlayEntry? _currentOverlay;
  
  /// Show message at 30% from top (70% from bottom) with automatic removal
  static void showMessage(BuildContext context, String message, {bool isError = false}) {
    // Remove any existing overlay first
    _removeExistingOverlay();
    
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.3, // 30% from top = 70% from bottom
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isError ? Colors.red.shade600 : Colors.green.shade600,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isError ? Icons.error : Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    // Auto remove after 3 seconds
    Timer(const Duration(seconds: 3), () {
      overlayEntry.remove();
      _currentOverlay = null;
    });
    
    _currentOverlay = overlayEntry;
  }
  
  /// Remove any existing overlay message
  static void _removeExistingOverlay() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
  
  /// Force remove any message (if needed)
  static void clearMessage() {
    _removeExistingOverlay();
  }
}