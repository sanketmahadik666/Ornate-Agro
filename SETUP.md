# Setup & Quick Start Guide

## Prerequisites

1. **Install Flutter**
   ```bash
   # Option 1: Using snap (recommended for Ubuntu/Linux)
   sudo snap install flutter --classic
   
   # Option 2: Manual installation
   # Follow: https://docs.flutter.dev/get-started/install/linux
   ```

2. **Verify Installation**
   ```bash
   flutter doctor
   ```

3. **Install Android Studio / VS Code** (for Android/iOS development)
   - Android Studio: https://developer.android.com/studio
   - VS Code: https://code.visualstudio.com/
   - Install Flutter and Dart extensions in VS Code

## Project Setup

1. **Navigate to project directory**
   ```bash
   cd /home/sanket/Ornate-Agro
   ```

2. **Get dependencies**
   ```bash
   flutter pub get
   ```

3. **Verify setup**
   ```bash
   flutter analyze
   ```

## Running the App

### Option 1: Run on Connected Device/Emulator
```bash
# List available devices
flutter devices

# Run on first available device
flutter run

# Run on specific device
flutter run -d <device-id>
```

### Option 2: Run in Chrome (Web)
```bash
flutter run -d chrome
```

### Option 3: Run in Release Mode
```bash
flutter run --release
```

## Available Routes

Once the app is running, you can navigate to:

- `/login` - Login page (default)
- `/dashboard` - Main dashboard
- `/farmers` - Farmers list
- `/farmers/categories` - **Farmers by category** (with sorting, filtering, bulk actions, export)
- `/distribution` - Seed distribution log
- `/yield` - Yield tracking
- `/contact-log` - Contact log
- `/crop-config` - Crop configuration
- `/reports` - Reports
- `/backtesting` - Backtesting interface

## Features to Test

### Farmer Categorization (Enhanced)
1. Navigate to Farmers → Category icon
2. Test sorting: App bar → Sort menu
3. Test filtering: App bar → Filter icon
4. Test bulk actions: Select farmers → Bulk actions icon
5. Test export: App bar → Export menu

### Backtesting
1. Navigate to Backtesting from dashboard
2. Upload input sheet (Excel/CSV)
3. Enable debug logs toggle
4. Start backtest and watch live logs
5. Monitor progress tracker

## Troubleshooting

### Flutter not found
```bash
# Add Flutter to PATH (if installed manually)
export PATH="$PATH:/path/to/flutter/bin"
```

### Dependencies issues
```bash
flutter clean
flutter pub get
```

### Build errors
```bash
flutter doctor -v
flutter upgrade
```

## Development Notes

- **State Management**: Using `flutter_bloc` for state management
- **Local Database**: `sqflite` for offline storage
- **File Parsing**: `excel` and `csv` packages for input sheets
- **Export**: `csv` and `share_plus` for exporting data

## Next Steps

1. Install Flutter using one of the methods above
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app
4. Test the features!
