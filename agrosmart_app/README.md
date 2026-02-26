# AgroSmart Mobile App

AgroSmart is a Flutter-based mobile dashboard for smart farming. It streams live IoT sensor data from Firebase Realtime Database, applies simple AI-derived insights, and guides irrigation and crop choices with an attractive dark UI.

## Tech Stack
- Flutter (Dart SDK `>=3.0.0 <4.0.0`), Material Design, portrait-only layout.
- State management: `provider` with a single `AppState` notifier (`lib/services/app_state.dart`).
- Backend: Firebase Core/Auth/Realtime Database (`lib/services/firebase_service.dart`, `lib/firebase_options.dart`).
- Visualization & UI: `fl_chart`, `flutter_animate`, `lottie`, `shimmer`, `font_awesome_flutter`, `google_fonts`, `cached_network_image`.
- Device capabilities: `flutter_local_notifications` for threshold alerts, `shared_preferences` for local settings, `intl` for formatting.

## Architecture
- `main.dart` initializes Firebase, locks orientation, and wraps the app in `ChangeNotifierProvider<AppState>`, using a dark theme from `AppTheme` (`lib/theme/app_theme.dart`).
- `AppState` holds live sensor data, farm profile, AI insight/suitability/recommendation objects, navigation index, dark-mode flag, and last-update timestamps. It subscribes to Firebase streams and triggers local notifications when thresholds are crossed.
- `FirebaseService` (singleton) exposes streams and one-time reads for:
  - `AgroSmart/currentData` → live sensor snapshot.
  - `AgroSmart/history/logs` → historical readings for charts.
  - `AgroSmart/farmProfile` → editable farm details.
  - `AgroSmart/ai/currentInsight`, `/ai/suitability`, `/ai/recommendation` → AI outputs.
- Navigation: `MainShell` uses an `IndexedStack` with a custom bottom nav (Dashboard, Analytics, Insights, Soil, Settings).

## Key Screens
- **Dashboard (`lib/screens/home_screen.dart`)**: Live vitals, irrigation status, quick cards, and a glassmorphism dark gradient.
- **Analytics (`lib/screens/analytics_screen.dart`)**: Tabbed charts (temperature, soil moisture, irrigation activity) powered by `fl_chart` fed from Realtime Database history.
- **Insights (`lib/screens/insights_screen.dart`)**: Displays AI insight, crop suitability, and recommendations.
- **Soil Analysis (`lib/screens/soil_analysis_screen.dart`)**: Uses a built-in crop database (`lib/models/crop_database.dart`) to score crops based on N-P-K, pH, temperature, humidity, and rainfall.
- **Settings (`lib/screens/settings_screen.dart`)**: Farm profile editing, theme toggle, and app info.

## Data Models
- `SensorData`, `SensorHistory`: map Realtime Database payloads to typed objects.
- `FarmProfile`: owner/location/plot details with update support.
- `AIInsight`, `CropSuitability`, `CropRecommendation`: parsed from AI nodes in the database.
- `CropInfo` + `crop_database`: static catalog and scoring logic for recommendations.

## Behavior Highlights
- Portrait-only, transparent status bar with light icons.
- Local notification checks in `AppState._checkNotifications` for temperature, humidity, soil wetness %, light level, and pump status.
- “Live” badge logic considers data fresh if updated within 5 minutes.
- Dark theme only (themeMode: `ThemeMode.dark`) with gradient background and glass borders.

## Assets & Structure
- Assets: `assets/images/` (declared in `pubspec.yaml`).
- Core folders: `lib/screens`, `lib/models`, `lib/services`, `lib/theme`, `lib/widgets`.

## Running the App
1) Install Flutter SDK (3.x), set up an emulator or device.
2) `flutter pub get`
3) Ensure Firebase configuration in `lib/firebase_options.dart` matches your project and Realtime Database has the `AgroSmart` root paths above.
4) `flutter run`

## What to Emphasize in a Viva
- Real-time data flow: Realtime DB streams → `FirebaseService` → `AppState` → UI.
- State management simplicity: single `ChangeNotifier` + `Provider`.
- User value: monitoring environment, AI-backed insights, and actionable irrigation/crop advice with push-like local alerts.
- UI/UX: cohesive dark theme, iconography, charts, animations, and offline-friendly cached images.
