# AgroSmart — Smart Agriculture Dashboard

This is a Vite + React + Tailwind dashboard for an IoT-based AgroSmart system.

Quick start:

1. Install dependencies

```bash
cd dashboard
npm install
```

2. Create a local env file and add your config (Realtime Database URL must point to US region DB)

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

## Setup & Security

1. Create `.env.local` in the dashboard root (same folder as `package.json`) using `.env.example` as a template.
2. Never commit real keys or secrets. Keep `.env.local` out of git.
3. The ML API should run locally or on a trusted LAN host; do not expose it publicly without proper security.
4. Configure Firebase Realtime Database rules securely for production. Use relaxed rules only for local development.

## Cloud Functions: AI layer

This repo includes a simple Cloud Functions implementation (rule-based v1) under `/functions` which:

- Appends `AgroSmart/currentData` snapshots into `AgroSmart/history/logs/` when currentData changes.
- Computes AI outputs on creation of `AgroSmart/history/logs/{logId}` and writes:
	- `/AgroSmart/ai/currentInsight`
	- `/AgroSmart/ai/suitability`
	- `/AgroSmart/ai/recommendations`
	- `/AgroSmart/ai/history/{logId}`

Deployment steps:

```bash
# go to dashboard root
cd dashboard

# install functions deps
cd functions
npm install

# initialize functions (if not already)
firebase init functions

# deploy only functions
firebase deploy --only functions
```

Notes:
- Functions use Node 18 runtime (`engines.node: 18`).
- The scoring is rule-based and defined in `functions/index.js` as `Rule-based v1`. Tune constants there.

### Option 1 — Client-side AI (development / no-backend)

If you cannot deploy Cloud Functions, the dashboard supports running the AI pipeline in the client. This will:

- Push a copy of `/AgroSmart/currentData` into `/AgroSmart/history/logs` from the authenticated dashboard client.
- Compute suitability, insight, and recommendations client-side (rule-based v1) and write to `/AgroSmart/ai/*`.

Files added for client-side AI:
- `src/ai/computeAI.js` — rule-based scoring utilities.
- `src/hooks/useClientAIWriter.js` — client-side logger and AI writer with dedupe and throttling.

Important: For development only — the authenticated dashboard user must be allowed to write these paths in your Realtime Database Rules. Example (allow authenticated read/write):

```json
{
	"rules": {
		"AgroSmart": {
			"history": {
				"logs": {
					".write": "auth != null",
					".read": "auth != null"
				}
			},
			"ai": {
				".write": "auth != null",
				".read": "auth != null"
			}
		}
	}
}
```

Only use these relaxed rules for local development. For production, tighten rules and prefer server-side functions.

## Analytics: historical seeding & timeseries

The dashboard now supports a client-side admin tool to seed a 90-day historical baseline (Kaggle means) and a continuous analytics timeseries combining historical + sensor records at `/AgroSmart/analytics/timeseries`.

Steps to seed historical data once (client-side):

1. Install dependency:

```bash
cd dashboard
npm install papaparse
```

2. Start the dev server and sign in with an authenticated account.

3. Open the Dashboard → Analytics. The admin widget "Seed Historical Data" will appear for authenticated users. Upload `Crop_recommendation.csv` or let the tool fetch `/src/assets/Crop_recommendation.csv` if included.

4. Select crop (kidneybeans, mungbean, chickpea) and click "Seed historical data". The tool will write 90 days of simulated baseline records to `/AgroSmart/analytics/timeseries` unless historical data already exists.

Notes:
- This is a one-time client-side operation and does NOT require Cloud Functions.
- The analytics feed schema is documented in the project; historical records have `soilMoisture` and `pumpStatus` set to `null`.


