import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'screens/home_screen.dart';

/// Entry point for the Parking Spot Saver app with DevicePreview support
/// 
/// DevicePreview Usage:
/// 1. Run: flutter run -d chrome
/// 2. Device preview interface appears in browser
/// 3. Select devices from dropdown (iPhone, Samsung, iPad, etc.)
/// 4. Toggle orientation with rotation button
/// 5. Test on various screen sizes with mouse interaction
/// 6. DevicePreview only enabled in debug mode, disabled in release
void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode, // Only enabled in debug mode
      builder: (context) => const ParkingSpotSaverApp(),
    ),
  );
}

class ParkingSpotSaverApp extends StatelessWidget {
  const ParkingSpotSaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parking Spot Saver',
      
      // DevicePreview integration
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}