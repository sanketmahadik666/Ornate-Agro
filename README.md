# Ornate Agro

**Flutter-based Vendor Seed Distribution Management Application**

A comprehensive mobile application for managing seed distribution to farmers, tracking yield returns, and automatically classifying farmers based on their behavior and contact history.

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.2.0 or higher)
- Dart SDK
- Android Studio / VS Code (for development)

### Installation

1. **Install Flutter** (if not already installed):
   ```bash
   sudo snap install flutter --classic
   ```

2. **Get dependencies**:
   ```bash
   cd /home/sanket/Ornate-Agro
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   # Quick start script
   ./QUICK_START.sh
   
   # Or manually
   flutter run -d chrome  # For web
   flutter run            # For connected device
   ```

See [SETUP.md](SETUP.md) for detailed setup instructions.

---

## 📋 Features

### Core Features (Requirements 1-10)

1. **User Authentication & Role Management** ✅
   - Login with username/password
   - Role-based access (Authority/Staff)
   - Session timeout

2. **Farmer Profile Management** ✅
   - Create/edit farmer profiles
   - Searchable and filterable list
   - Unique farmer ID assignment

3. **Seed Distribution Log** ✅
   - Log seed distributions
   - Automatic yield due date calculation
   - Immutable log entries

4. **Yield Return Tracking** ✅
   - Track yield returns
   - Status: Pending/Due/Fulfilled/Partially/Overdue

5. **Farmer Classification System** ✅
   - Automatic classification: Regular, Sleepy, Blacklist, Reminder
   - Based on yield return and contact history
   - Manual override with audit log

6. **Contact Log Management** ✅
   - Log all farmer interactions
   - Contact method tracking
   - Alert system for no-contact farmers

7. **Dashboard & Reporting** ✅
   - Summary statistics
   - Filterable reports
   - PDF/CSV export

8. **Crop Type Configuration** ✅
   - Configure crop types
   - Set growing periods
   - Auto-calculate yield due dates

9. **Notifications & Alerts** ✅
   - In-app notifications
   - Yield due alerts
   - Classification change notifications

10. **Data Persistence & Offline** ✅
    - Local database (encrypted)
    - Offline mode support
    - Automatic sync when online

### Enhanced Features

- **Farmer Categorization Interface** 🎨
  - Beautiful tabbed interface by category
  - Sorting (name, date, village)
  - Filtering (village, crop type, date range)
  - Bulk actions (classification change, contact log, export, delete)
  - CSV export functionality

- **Backtesting System** 📊
  - Excel/CSV input sheet parsing
  - Live log streaming with categorization
  - Debug mode toggle
  - Progress tracking with ETA
  - Template management

---

## 📁 Project Structure

```
lib/
├── main.dart
├── app/                    # Bootstrap, MaterialApp, routes
├── core/                   # Theme, routes, constants, utils, data
│   ├── theme/
│   ├── routes/
│   ├── constants/
│   ├── utils/
│   └── data/              # Database, sync
├── features/              # Feature modules
│   ├── auth/              # Authentication
│   ├── farmers/           # Farmer management + categorization
│   ├── distribution/      # Seed distribution
│   ├── yield_tracking/    # Yield return tracking
│   ├── contact_log/       # Contact logging
│   ├── dashboard/         # Dashboard
│   ├── crop_config/       # Crop configuration
│   ├── notifications/     # Notifications
│   ├── reports/           # Reporting
│   └── backtesting/       # Backtesting system
└── shared/                # Shared entities
    └── domain/entities/
```

---

## 🛠️ Technology Stack

- **Framework**: Flutter 3.2.0+
- **State Management**: flutter_bloc
- **Local Database**: sqflite
- **File Parsing**: excel, csv
- **Export**: csv, share_plus, pdf
- **Security**: flutter_secure_storage

---

## 📚 Documentation

- [Requirements](requirement/requirements.md) - Complete requirements document
- [Requirements Map](docs/REQUIREMENTS_MAP.md) - Quick reference for requirements → code
- [Setup Guide](SETUP.md) - Detailed setup instructions
- [Backtesting UI/UX Design](docs/BACKTESTING_UI_UX_DESIGN.md) - Backtesting design spec
- [Backtesting Implementation](docs/BACKTESTING_IMPLEMENTATION.md) - Implementation details
- [Farmer Categorization UI](docs/FARMER_CATEGORIZATION_UI.md) - Category interface docs
- [Farmer Categorization Enhancements](docs/FARMER_CATEGORIZATION_ENHANCEMENTS.md) - Sorting, filtering, bulk actions

---

## 🎯 Key Routes

- `/login` - Login page
- `/dashboard` - Main dashboard
- `/farmers` - Farmers list
- `/farmers/categories` - **Farmers by category** (enhanced)
- `/distribution` - Distribution log
- `/yield` - Yield tracking
- `/contact-log` - Contact log
- `/crop-config` - Crop configuration
- `/reports` - Reports
- `/backtesting` - Backtesting interface

---

## 🧪 Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

---

## 📦 Building

### Android APK
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

---

## 🤝 Contributing

1. Follow Flutter style guide
2. Use BLoC pattern for state management
3. Write tests for new features
4. Update documentation

---

## 📝 License

This project is proprietary software for vendor seed distribution management.

---

## 🆘 Support

For setup issues, see [SETUP.md](SETUP.md) or run:
```bash
flutter doctor -v
```

---

**Status**: ✅ Ready for Development & Testing
