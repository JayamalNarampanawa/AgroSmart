# AgroSmart — Smart Agriculture Dashboard

This is a Vite + React + Tailwind dashboard for an IoT-based AgroSmart system.

Quick start:

1. Install dependencies

```bash
cd dashboard
npm install
```

2. Add your Firebase config in `src/firebase.js` (Realtime Database URL must point to US region DB)

3. Run locally

```bash
npm run dev
```

4. Build & deploy to Firebase Hosting (optional)

This project includes real-time listeners, authentication (Email/Password), charts (Recharts), and responsive Tailwind UI.

Files of interest:
- src/firebase.js — initialize app, `auth`, `database`
- src/hooks/useSensorData.js — Realtime listeners for `AgroSmart/currentData` and `AgroSmart/history/logs`
- src/pages/Dashboard.jsx — main layout and components

Replace Firebase placeholders before running.  
