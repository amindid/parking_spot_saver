import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A widget that displays images correctly on both mobile and web platforms
class CrossPlatformImage extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const CrossPlatformImage({
    Key? key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // On web, use Network.image for URLs or Image.asset for local assets
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        return Image.network(
          imagePath,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: errorBuilder ??
              (context, error, stackTrace) {
                return Container(
                  width: width,
                  height: height,
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                  ),
                );
              },
        );
      } else {
        // For web, treat as blob URL or data URL
        return Image.network(
          imagePath,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: errorBuilder ??
              (context, error, stackTrace) {
                return Container(
                  width: width,
                  height: height,
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                  ),
                );
              },
        );
      }
    } else {
      // On mobile platforms, use File
      return Image.file(
        File(imagePath),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder ??
            (context, error, stackTrace) {
              return Container(
                width: width,
                height: height,
                color: Colors.grey.shade200,
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                ),
              );
            },
      );
    }
  }
}

/// A cross-platform image provider that works on both mobile and web
ImageProvider getCrossPlatformImageProvider(String imagePath) {
  if (kIsWeb) {
    // On web platforms, use NetworkImage
    return NetworkImage(imagePath);
  } else {
    // On mobile platforms, use FileImage
    return FileImage(File(imagePath));
  }
}