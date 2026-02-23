# Farm Manager

A beautiful Flutter mobile app for managing Klipper-based 3D printers with Box Turtle AFC (Automatic Filament Changer) support.

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Flutter-02569B?style=for-the-badge&logo=flutter" alt="Platform">
  <img src="https://img.shields.io/badge/Status-Active-4CAF50?style=for-the-badge" alt="Status">
  <img src="https://img.shields.io/badge/License-MIT-FF6B6B?style=for-the-badge" alt="License">
</p>

---

## Features

### 🖨️ Multi-Printer Management
- Connect to multiple Klipper printers over HTTP
- Real-time status monitoring (printing, paused, idle, offline)
- Live webcam streaming
- Temperature graphs with historical data
- Print progress tracking

### 🎯 Box Turtle AFC Support
- **Visual lane management** with Material 3 styled cards
- **Smart load/unload buttons** - context-aware based on filament position
- **Glow animations** for active lanes
- **Quick actions panel**:
  - Eject, Cut, Brush, Poop, Park, Calibrate
  - LED on/off
  - Stats, Quiet mode, Reset

### 🧵 Spoolman Integration
- Browse filament inventory from Spoolman
- Assign spools to printers
- Track remaining filament weight
- Color-coded spool display

### 📊 Dashboard
- At-a-glance printer overview
- Quick access to all printers
- Add printers easily
- Pin favorite printer to home screen widget

### 🎨 Themes
- **Aubergine** - Dark purple theme (default)
- **Material 3 Expressive** - Vibrant Material Design 3
- **Liquid Glass** - Modern glassmorphism style

---

## Screenshots

| Dashboard | Printer Detail | AFC Panel |
|-----------|---------------|-----------|
| Control center with printer list | Temperature, webcam, controls | Lane cards with glow effects |

---

## Architecture

```
lib/
├── main.dart                    # App entry point
├── models/
│   └── printer.dart             # Printer, Spool, AFC data models
├── providers/
│   └── printer_provider.dart    # State management & Moonraker API
├── screens/
│   ├── dashboard_screen.dart    # Main printer list
│   ├── printer_detail_screen.dart # Printer controls & AFC
│   ├── gcode_viewer_screen.dart  # G-code file viewer
│   └── schedule_screen.dart     # Print scheduling
├── services/
│   ├── background_service.dart  # Background tasks
│   ├── notification_service.dart # Push notifications
│   └── database_helper.dart     # Local storage
├── widgets/
│   ├── printer_card.dart       # Printer summary card
│   ├── at_glance.dart         # Dashboard stats
│   ├── motion_deck.dart        # Motion device controls
│   └── afc_widgets.dart       # AFC lane cards, badges, actions
└── theme/
    └── app_theme.dart          # Theme definitions
```

---

## Getting Started

### Prerequisites
- Flutter 3.x SDK
- Android SDK / Xcode (for iOS)
- Klipper printer running Moonraker

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/farm-manager.git
cd farm-manager

# Get dependencies
flutter pub get

# Run the app
flutter run
```

### Build APK

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release
```

---

## Configuration

### Adding a Printer

1. Tap the **+** button on the dashboard
2. Enter printer name and IP address
3. Configure Moonraker port (default: 7125)
4. Save and start monitoring!

### Spoolman Setup

1. Go to Settings (gear icon)
2. Enter your Spoolman URL (e.g., `http://spoolman:8000`)
3. Browse and assign spools to printers

---

## API Integration

The app communicates with [Moonraker](https://github.com/Arksine/moonraker) - the Klipper REST API:

| Endpoint | Usage |
|----------|-------|
| `/printer/status` | Real-time printer state |
| `/printer/objects/query` | Temperature, position, etc. |
| `/server/files/gcodes` | File list & management |
| `/server/job_queue` | Print queue |
| `/machine/services/...` | Service control |

### AFC Commands

| Command | Action |
|---------|--------|
| `load` | Load filament to toolhead |
| `unload` | Unload filament from toolhead |
| `eject` | Eject filament from AFC |
| `cut` | Cut filament tip |
| `brush` | Brush nozzle |
| `park` | Park toolhead |
| `calibration` | Run AFC calibration |

---

## Tech Stack

- **Flutter** - UI framework
- **Provider** - State management
- **Google Fonts** - Typography (Anton, JetBrains Mono)
- **Lucide Icons** - Icon set
- **fl_chart** - Temperature graphs
- **http** - HTTP client for Moonraker API

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

## Acknowledgments

- [Klipper](https://www.klipper3d.org/) - 3D printer firmware
- [Moonraker](https://github.com/Arksine/moonraker) - Klipper REST API
- [Box Turtle](https://github.com/UnchartedBull/box_turtle) - AFC module
- [Spoolman](https://github.com/Donkie/Spoolman) - Filament management
