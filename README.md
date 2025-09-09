# Parking Spot Saver

A complete Flutter mobile application that helps users save and navigate back to their parked car location using GPS coordinates and Google Maps integration.

## Features

- **Two ways to save parking locations:**
  - **GPS-based saving** - Save current location with one tap
  - **Manual selection** - Tap anywhere on map to select parking spot
- **OpenStreetMap integration** showing current location and saved parking spot
- **In-app navigation** with road-based routing that follows actual streets and walkways
- **External navigation fallback** - Option to open Google Maps for detailed directions
- **Local data persistence** using SharedPreferences
- **Real-time location tracking** during navigation with automatic updates
- **Interactive map selection** with visual feedback and confirmation
- **Clean, intuitive user interface** with Material Design

## Screenshots & Features

### Save Parking Location
- **Option 1: GPS Location** - Extended FAB to save current GPS coordinates
- **Option 2: Manual Selection** - Orange FAB to enter map selection mode
- **Interactive selection** - Tap anywhere on map to choose parking spot
- **Selection mode UI** - Orange overlay with instructions and coordinate preview
- **Confirm/Cancel options** - Green confirm and red cancel buttons
- Visual feedback when location is saved
- Auto-update functionality for existing spots

### Map Display
- OpenStreetMap widget showing user's live location (blue circle)
- **Three marker types:**
  - Blue circle: Current user location
  - Orange pin: Temporarily selected location (during selection)
  - Red parking icon: Confirmed saved parking spot
- Auto-center map on user location when app opens
- Real-time location tracking
- **Interactive selection mode** with visual overlay and map tint

### In-App Navigation
- **Road-based routing** - Uses OpenRouteService API for realistic walking routes
- **Route visualization** - Blue line following actual streets and walkways (not through buildings!)
- **Fallback routing** - Automatic fallback to straight-line route if API unavailable
- **Live navigation info** - Distance, estimated walking time, direction, and directional arrows
- **Route type indicators** - Shows "Road-based route" vs "Straight-line route"
- **Smart map centering** - Automatically adjusts zoom and center to show entire route
- **Loading states** - "Finding best walking route..." with progress indication
- **Arrival detection** - Automatic notification when you reach your car (within 10m)
- **Enhanced UI** - AppBar changes color, pulse effect on location marker
- **Error handling** - User-friendly messages for network issues or API problems

### External Navigation Fallback
- **"External Maps" button** - Opens Google Maps for detailed turn-by-turn directions
- **Backup option** - Available in bottom sheet for users who prefer external navigation

### Spot Management
- Bottom sheet UI showing saved spot details
- Display coordinates, timestamp, and distance
- Clear spot functionality with confirmation dialog
- **Dual saving modes**: Both GPS and manually selected locations stored identically
- **Smart UI adaptation**: Bottom sheet hidden during selection mode

## Technical Stack

### Dependencies
- `flutter`: Core Flutter framework
- `geolocator: ^9.0.2`: GPS location services and real-time tracking
- `flutter_map: ^6.1.0`: OpenStreetMap widget with polyline support
- `latlong2: ^0.9.1`: Latitude/longitude calculations
- `http: ^1.1.0`: HTTP requests for map tiles
- `shared_preferences: ^2.2.2`: Local data persistence
- `url_launcher: ^6.2.1`: External app integration (fallback navigation)
- `flutter_polyline_points: ^3.0.1`: Route polyline calculations
- `geolocator_platform_interface: ^4.0.7`: Enhanced location platform interface
- `dio: ^5.3.2`: HTTP client for OpenRouteService API calls

### Architecture
- **Models**: Data models for parking spot information
- **Services**: Location, storage, navigation, and routing service classes
- **Config**: API configuration for OpenRouteService integration
- **Screens**: Main app screens with road-based navigation
- **Widgets**: Reusable UI components including enhanced navigation overlay

## Setup Instructions

### Prerequisites
1. Flutter SDK installed (>=3.10.0)
2. Android Studio or Xcode for platform development
3. Internet connection (for map tiles and routing)

### OpenStreetMap Setup
This app uses OpenStreetMap which is completely **free** and requires **no API keys**:
- Uses OpenStreetMap tile servers: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- No billing or account setup required
- Full attribution to OpenStreetMap contributors included

### OpenRouteService Setup (Optional but Recommended)
For road-based navigation that follows actual streets:

1. **Sign up for free**: Go to [OpenRouteService](https://openrouteservice.org/dev/#/signup)
2. **Create account**: No credit card required, completely free
3. **Get API key**: 5000 requests/day free tier (more than enough for personal use)
4. **Configure app**: 
   - Open `lib/config/api_config.dart`
   - Replace `YOUR_API_KEY_HERE` with your actual API key
   - Restart the app

**Without API key**: App still works with straight-line navigation
**With API key**: Get realistic walking routes that follow streets and avoid buildings

### Platform Configuration
No additional platform configuration needed! The app works out of the box with:
- Location permissions (already configured)
- Internet permissions (already configured)
- Optional API key for enhanced routing

### Installation Steps
1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd parking_spot_saver
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. (Optional) Configure OpenRouteService API key for road-based routing:
   - Edit `lib/config/api_config.dart`
   - Replace `YOUR_API_KEY_HERE` with your actual API key

4. Run the app:
   ```bash
   flutter run
   ```

### Testing on Device
- Ensure GPS is enabled on test device
- Ensure internet connection is available (for map tiles)
- Grant location permissions when prompted
- Test both saving and navigation features
- Verify map displays correctly with current location

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   └── parking_spot.dart        # Parking spot data model
├── services/
│   ├── location_service.dart    # GPS location services
│   └── storage_service.dart     # Local data persistence
├── screens/
│   └── home_screen.dart         # Main app screen
└── widgets/
    └── bottom_sheet_widget.dart # Parking spot details UI

android/
├── app/src/main/
│   ├── AndroidManifest.xml      # Android permissions (no API keys needed)
│   └── kotlin/com/example/parkingspotsaver/
│       └── MainActivity.kt      # Android main activity

ios/
└── Runner/
    ├── Info.plist              # iOS permissions (no API keys needed)
    └── AppDelegate.swift       # iOS app delegate
```

## Key Features Implementation

### Location Services
- GPS coordinate retrieval using `geolocator`
- Permission handling for iOS and Android
- Real-time location updates
- Distance calculations

### Data Persistence
- JSON serialization for parking spot data
- SharedPreferences for local storage
- Automatic data loading on app startup

### Map Integration
- OpenStreetMap widget with custom markers
- Current location display with blue circle marker
- Camera controls and animations
- Tap gesture handling
- Free tile server usage (no API keys)

### Navigation Integration
- URL launcher for Google Maps directions
- Walking directions mode
- External app integration

## Error Handling

The app includes comprehensive error handling for:
- Location permission denials
- GPS service unavailability
- Network connectivity issues
- Storage operation failures
- Map loading errors

## Performance Considerations

- Efficient location service management
- Proper memory management for map resources
- Optimized marker updates
- Background location handling

## Security Features

- No sensitive data stored locally
- API key security recommendations
- Permission-based location access
- User consent for location services

## Future Enhancements

Potential features for future versions:
- Multiple parking spot support
- Parking timer and reminders
- Photo attachment for parking spots
- Offline map support
- Parking history tracking

## Support

For issues and feature requests, please create an issue in the project repository.

## License

This project is open source and available under the MIT License.