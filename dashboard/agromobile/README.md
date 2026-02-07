# AgroSmart Mobile (Android)

Flutter mobile app that mirrors the AgroSmart React dashboard with real-time Firebase Realtime Database data, charts, insights, alerts, and local (offline) authentication.

## Setup

1. Place your Firebase config file here:

`android/app/google-services.json`

2. Install dependencies:

```
flutter pub get
```

3. Run on Android:

```
flutter run
```

## Notes

- Authentication is local-only (Hive NoSQL) and does not connect to Firebase Auth.
- Realtime data is read from RTDB paths under `AgroSmart/*`.
- Alerts trigger local notifications when thresholds are breached.
