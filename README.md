# 🚗 Parking Spot Saver

A Flutter mobile app that helps you save and navigate back to your parked car location using GPS and OpenStreetMap.

---

## ✨ Features

- **Save parking spots** - Current GPS location or manually select on map
- **Multiple parking spots** - Save and manage multiple locations
- **Photo attachments** - Add photos to remember your parking spot
- **Road-based navigation** - Follow actual streets and walkways to your car
- **Share locations** - Copy coordinates or Google Maps links
- **Device preview** - Test on multiple screen sizes in development

---

## 📸 Screenshots

<p align="center">
  <a href="https://github.com/user-attachments/assets/3f27286b-b2dc-4e3b-9f68-ca479e9a98b5">
    <img width="220" src="https://github.com/user-attachments/assets/3f27286b-b2dc-4e3b-9f68-ca479e9a98b5" />
  </a>
  <a href="https://github.com/user-attachments/assets/4cb1605b-c394-480a-8c12-28ebca06c950">
    <img width="220" src="https://github.com/user-attachments/assets/4cb1605b-c394-480a-8c12-28ebca06c950" />
  </a>
  <a href="https://github.com/user-attachments/assets/8ea5d4bc-82f9-49b7-bd75-3ba1d1b6a4ae">
    <img width="220" src="https://github.com/user-attachments/assets/8ea5d4bc-82f9-49b7-bd75-3ba1d1b6a4ae" />
  </a>
</p>

<p align="center">
  <a href="https://github.com/user-attachments/assets/0a42c4f9-aa71-4a27-8d23-37d339b14b12">
    <img width="220" src="https://github.com/user-attachments/assets/0a42c4f9-aa71-4a27-8d23-37d339b14b12" />
  </a>
  <a href="https://github.com/user-attachments/assets/7b0270ab-a7ae-4687-a5e4-d62833a687a0">
    <img width="220" src="https://github.com/user-attachments/assets/7b0270ab-a7ae-4687-a5e4-d62833a687a0" />
  </a>
</p>

---

## 🛠 How to Run

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

---

## 🔐 Permissions

The app automatically requests:
- **Location permission** - To find and save your parking location
- **Camera permission** - To add photos to parking spots (optional)

---

## 🧑‍💻 Technology Stack

- **Flutter** - Cross-platform mobile framework
- **OpenStreetMap** - Free map tiles (no API key needed)
- **Geolocator** - GPS location services
- **Image Picker** - Camera and gallery access
- **Shared Preferences** - Local data storage

---

## 📂 Project Structure

```
lib/
├── main.dart                    # App entry point with device preview
├── models/                      # Data models
├── services/                    # Location, storage, photo, navigation services
├── screens/                     # App screens
└── widgets/                     # Reusable UI components
```