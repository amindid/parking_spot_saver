# 🚗 Parking Spot Saver

A Flutter mobile app that helps you save and navigate back to your parked car location using GPS and OpenStreetMap.

## Features

- **Save parking spots** - Current GPS location or manually select on map
- **Multiple parking spots** - Save and manage multiple locations
- **Photo attachments** - Add photos to remember your parking spot
- **Road-based navigation** - Follow actual streets and walkways to your car
- **Share locations** - Copy coordinates or Google Maps links
- **Device preview** - Test on multiple screen sizes in development

## Screenshots

The app includes:
- Interactive map with your current location and saved parking spots
- SpeedDial menu for quick access to save options
- Bottom sheet with spot details and navigation options
- Photo capture and gallery selection
- Clean message system with proper positioning

## How to Run

### Prerequisites
- Flutter SDK (>=3.10.0)
- Device with GPS capability

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd parking_spot_saver
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

### Device Preview (Development)

For multi-device testing in VS Code:
```bash
flutter run -d chrome
```
This opens a device preview interface where you can test different screen sizes and orientations.

## Permissions

The app automatically requests:
- **Location permission** - To find and save your parking location
- **Camera permission** - To add photos to parking spots (optional)

## Technology Stack

- **Flutter** - Cross-platform mobile framework
- **OpenStreetMap** - Free map tiles (no API key needed)
- **Geolocator** - GPS location services
- **Image Picker** - Camera and gallery access
- **Shared Preferences** - Local data storage

## Project Structure

```
lib/
├── main.dart                    # App entry point with device preview
├── models/                      # Data models
├── services/                    # Location, storage, photo, navigation services
├── screens/                     # App screens
└── widgets/                     # Reusable UI components
```