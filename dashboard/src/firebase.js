import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getDatabase } from "firebase/database";
import { getAnalytics } from "firebase/analytics";

/**
 * AgroSmart Hosting-safe Firebase config
 * - Firebase web config is NOT a secret (safe to ship in frontend)
 * - Avoid crashing builds when env vars are missing on Netlify/Vercel
 * - Keep .env ONLY for Weather API / ML API base URL
 */
const firebaseConfig = {
  apiKey: "PASTE_YOUR_API_KEY",
  authDomain: "PASTE_YOUR_AUTH_DOMAIN",
  databaseURL: "PASTE_YOUR_DATABASE_URL",
  projectId: "PASTE_YOUR_PROJECT_ID",
  storageBucket: "PASTE_YOUR_STORAGE_BUCKET",
  messagingSenderId: "PASTE_YOUR_MESSAGING_SENDER_ID",
  appId: "PASTE_YOUR_APP_ID",
};

const app = initializeApp(firebaseConfig);

// Analytics only works in browser contexts (won't crash on SSR/build)
let analytics = null;
try {
  analytics = getAnalytics(app);
} catch (e) {
  console.warn("Firebase analytics not available in this environment", e);
}

// Debug
try {
  console.log("[AgroSmart] Firebase initialized. databaseURL=", firebaseConfig.databaseURL);
} catch (e) {}

export const auth = getAuth(app);
export const database = getDatabase(app);
export { app, analytics };
export default app;
