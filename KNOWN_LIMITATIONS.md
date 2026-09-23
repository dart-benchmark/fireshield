# Known Limitations — Fire Audit Platform Demo App

## Backend & Data

- **No backend connection.** All data is hardcoded in `lib/data/mock_data.dart`. There are no API calls, no database reads/writes, and no real authentication.
- **Mock data is static.** Corrective actions, audits, equipment status, and notifications do not change between sessions.
- **Form submissions are simulated.** Register Org, Create User, Add Equipment, and Mark CA Complete show a success snackbar but do not persist data.
- **AI Assistant responses are pattern-matched.** Responses to questions about hospitals, detectors, and extinguishers are hardcoded strings. All other queries return a generic response. There is no real Azure OpenAI integration.
- **Document Intelligence is fully simulated.** The upload flow runs a timed animation and always produces the same pre-defined extraction result for Phoenix Marketcity regardless of the document selected.
- **Evidence capture is simulated.** Photo/video/audio capture buttons display a snackbar but do not access device camera or file system.

## Build & Deployment

- **Android APK cannot be built on this machine** — Android SDK is not installed. Use the web build instead (`flutter build web --release`).
- **Web build output** is located at `build/web/` inside the demo_app directory.
- **PWA (pwa_app)** — A separate Progressive Web App build exists at `fire_audit_platform/pwa_app/dist/`. This is a distinct build artifact.

## Navigation Dead-Ends

- The **"Forgot Password?"** button on the login screen is a no-op (empty `onPressed`).
- The **"Evidence Capture"** quick action in the Auditor dashboard is a no-op.
- The **"Offline Mode"** and **"Scan Tag"** quick actions in the Auditor dashboard are no-ops.
- Several profile menu items (Edit Profile, Change Password, Biometric Settings, Language, Offline Data, About) are no-ops.
- Government dashboard **"Inspect"** and **"View Details"** buttons on facility cards are no-ops.
- The Org Admin dashboard's **"Schedule Audit"** and **"View Details"** facility buttons are no-ops.
- The **"Documents"** quick action in the Safety Manager dashboard routes to nothing (empty callback) — use `/doc-intelligence` route directly.

## Known Data Limitations

- `mockFacilities` contains 4 facilities, `mockAudits` contains 5 audits, `mockCAs` contains 8 corrective actions, `mockEquipment` contains 7 items.
- Audit Execution screen always loads the same audit (`mockAudits[0]` — Jamnagar Refinery).
- Audit Summary screen always shows the same pre-defined Phoenix Marketcity audit data.
- Safety Manager dashboard always shows `demoUsers[0]` (Rajesh Kumar) and `demoUsers[1]` (Meena Patel) data regardless of who logged in.
- Government dashboard always shows `demoUsers[2]` (Arjun Singh) data.

## UI / UX Notes

- The mobile frame is only shown on desktop/wide screens (width > 430px). On narrow screens (real mobile), the app fills the screen normally.
- The dynamic island and status bar overlay in the mobile frame are decorative only.
- Some `StatusBadge` statuses like `'ACTIVE'`, `'CONNECTED'`, `'INACTIVE'`, `'On Leave'` display with the default gray style since they are not in the predefined switch cases — this is intentional fallback behavior.
