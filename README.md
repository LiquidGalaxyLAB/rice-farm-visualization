# Rice Farm Agriculture Visualization on Liquid Galaxy

An interactive geospatial storytelling platform that visualizes India's rice agriculture data across a multi-screen Liquid Galaxy rig using Google Earth and KML overlays.

## Overview

This Flutter mobile controller app transforms agricultural datasets into immersive multi-screen visualizations. The app connects to a Liquid Galaxy rig via SSH/SFTP and renders colored KML overlays, 3D polygons, guided tours with voice narration, and real-time map synchronization.

## Features

- **All-India Production Heatmap** — 36 states color-coded by rice production volume (green = high, red = low, grey = negligible)
- **Major Rice Regions** — Fly-to and orbit the top 10 rice-producing states with production data
- **Seasonal Crop Cycle** — Kharif/Rabi season toggle with 4-stage timeline (Sowing → Transplanting → Growth → Harvest)
- **Irrigation & Rainfall** — Blue-gradient visualization of rainfall patterns and irrigation infrastructure
- **3 Guided Tours** — Automated storytelling with KML visualizations and TTS narration:
  - India's Rice Belt Tour (7 steps)
  - Irrigation Systems Tour (5 steps)
  - Seasonal Farming Tour (5 steps)
- **Synced Navigation** — Real-time Google Maps to Liquid Galaxy camera synchronization
- **Side Screen Dashboards** — Project logo on left screen, auto-updating stats dashboard on right screen
- **Orbit Camera** — 360° cinematic rotation around any location
- **TTS Narration** — Indian English voice narration for all states and tours

## Tech Stack

- **Flutter** — Mobile controller app
- **KML** — Map visualizations and overlays
- **Google Earth** — Geospatial rendering engine
- **Liquid Galaxy** — Multi-screen display platform
- **SSH/SFTP (dartssh2)** — Rig communication
- **Flutter TTS** — Text-to-speech narration
- **Google Maps Flutter** — Synced navigation
- **Riverpod** — State management

## Data Sources

| Data | Source |
|------|--------|
| State Production | data.gov.in, ICAR-CRRI |
| State Boundaries | Datameet GitHub (GeoJSON, ODbL) |
| Crop Cycles | ICAR-CRRI, Directorate of Rice Development |
| Rainfall | India Meteorological Department (IMD) |
| Irrigation | Ministry of Water Resources |
| Export Data | APEDA |

## Project Structure

```
lib/
├── controllers/     # LG connection, SSH, settings
├── services/        # KML builder, tour engine, TTS
├── models/          # Data structures
├── data/            # Static datasets
├── screens/         # UI screens
├── widgets/         # Reusable components
├── helpers/         # Utilities
└── theme/           # App theme
```

## Setup

### Prerequisites
- Flutter SDK (stable channel)
- Android device or emulator
- Liquid Galaxy rig (3+ screens) with SSH access
- Google Maps API key

### Installation

1. Clone the repository:
```bash
git clone https://github.com/LiquidGalaxyLAB/rice-farm-visualization.git
cd rice-farm-visualization
```

2. Install dependencies:
```bash
flutter pub get
```

3. Add your Google Maps API key to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY"/>
```

4. Run the app:
```bash
flutter run
```

5. Connect to your LG rig:
   - Open Settings in the app
   - Enter your LG master IP, port (22), username, and password
   - Tap Connect

## How It Works

1. The app generates KML XML from static agriculture datasets
2. KML files are uploaded to the LG web server via SFTP
3. The file URL is written to `kmls.txt` which Google Earth polls
4. Camera commands are sent via `query.txt` for fly-to and orbit
5. Side screens are updated by writing to `slave_X.kml` files
6. TTS narration plays on the phone while visuals render on LG

## Screenshots

*Screenshots of the app running on a 3-screen LG rig*

## GSoC 2026

- **Contributor:** Vinayak Dhaka
- **Mentor:** Vedant Singh, Dev Gadani
- **Organization:** Liquid Galaxy Lab
- **Program:** Google Summer of Code 2026

## License

This project is part of the Liquid Galaxy GSoC 2026 program.
