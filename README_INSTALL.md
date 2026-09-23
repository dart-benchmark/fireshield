# FireShield AI — Demo Installation Guide

**App:** FireShield AI | EY  
**Package:** com.ey.fireshieldai  
**Version:** 1.0.0-demo  
**Build Date:** June 2026  

---

## Demo Credentials

All roles share the same login screen. Enter any email below, tap **Sign In**, then pick your role from the bottom sheet.

| Role | Email | Password |
|------|-------|----------|
| Safety Manager | rajesh.kumar@refineryco.in | any |
| Safety Manager | meena.patel@cityhospital.in | any |
| Auditor | priya.nair@auditcorp.in | any |
| Org Admin | vikram.mehta@phoenixmalls.com | any |
| Govt Officer | arjun.singh@mfd.gov.in | any |
| Platform Admin | admin@fireaudit.gov.in | any |

> Password field accepts any value — demo mode has no authentication server.

---

## Option A: Install APK on Android (Physical Device)

### Step 1 — Enable Developer Options on the device

1. Go to **Settings > About phone**
2. Tap **Build number** 7 times
3. Return to Settings — a new **Developer options** entry appears
4. Open **Developer options** and enable **USB debugging**

### Step 2 — Enable installation from unknown sources

- **Android 8+:** Settings > Apps > Special app access > Install unknown apps > allow your file manager or Chrome
- **Android 7 and below:** Settings > Security > enable **Unknown sources**

### Step 3 — Transfer the APK to the device

Choose one of:
- USB cable — copy `app-release.apk` to device storage
- Email the APK to yourself and open the attachment on device
- WhatsApp/Telegram — send to yourself and download
- Google Drive / OneDrive — upload and open on device

### Step 4 — Install

1. Open your file manager and navigate to `app-release.apk`
2. Tap the file and tap **Install**
3. If prompted "Play Protect blocked the install" — tap **Install anyway** (demo APK, not Play-verified)
4. App appears on your home screen as **FireShield AI**

---

## Option B: Install as PWA (No APK Needed)

The web version is fully installable as a Progressive Web App — no APK, no app store, works on Android and iPhone.

### Android Chrome

1. Open the hosted URL in **Chrome**
2. Chrome shows a banner: "Add FireShield AI to Home Screen" — tap **Install**
3. If no banner: tap the three-dot menu and tap **Add to Home screen**
4. App icon appears on your home screen and launches in standalone mode

### iPhone / iPad Safari

1. Open the hosted URL in **Safari** (must be Safari, not Chrome)
2. Tap the **Share button** (square with arrow, bottom toolbar)
3. Scroll down and tap **"Add to Home Screen"**
4. Name it **FireShield AI** and tap **Add**
5. App appears on home screen with the FireShield AI icon

### Hosting the PWA (2-minute deploy)

**Netlify Drag and Drop — no account needed for quick testing:**

1. Go to **app.netlify.com/drop**
2. Drag and drop the `fire_audit_platform/demo_app/build/web/` folder
3. Netlify gives you a live HTTPS URL immediately
4. Share that URL for install testing

**Vercel CLI:**
```bash
npm i -g vercel
cd fire_audit_platform/demo_app
vercel --prod
```

---

## Build Instructions (requires Android SDK)

> Only needed to regenerate the APK. Requires Android Studio on the build machine.

### Install Android Studio (one-time, ~15 minutes)

1. Download from **developer.android.com/studio**
2. Run the installer — accept all defaults
3. On first launch, complete the **SDK Setup Wizard** (downloads ~1.5 GB)
4. Verify: run `flutter doctor` in a new terminal — Android toolchain should show a green tick

### Build APK

```bash
cd fire_audit_platform/demo_app
flutter pub get
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build App Bundle (for Play Store upload)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## App Configuration Summary

| Parameter | Value |
|-----------|-------|
| App Name | FireShield AI |
| Package ID | com.ey.fireshieldai |
| Version Name | 1.0.0-demo |
| Min Android | 5.0 (API 21) |
| Target Android | 14 (API 35) |
| Signing | Debug key (demo only) |
| Backend | None — all data embedded |
| Internet required | No (fully offline) |

---

## Demo Screens Available

| Screen | Role |
|--------|------|
| Splash / Login | All |
| Safety Manager Dashboard | Safety Manager |
| Auditor Dashboard | Auditor |
| Org Admin Dashboard | Org Admin |
| Govt Officer Dashboard | Govt Officer |
| Platform Admin Dashboard | Platform Admin |
| Audit Execution (checklist) | Auditor |
| Audit Summary and FRI Score | Auditor |
| Corrective Actions | Safety Manager |
| Equipment Tracker | Safety Manager |
| Reports and Analytics | All |
| Document Intelligence | All |
| AI Assistant | All |
| Notifications | All |
| Register Organisation | Platform Admin |
| Create User | Org Admin |

---

## Known Limitations

- **No persistent storage** — data resets on app restart; all state is in-memory during the session
- **Camera / photo capture** — UI option visible but device camera is not wired in demo mode
- **Push notifications** — notification cards shown; no live push delivery
- **PDF export** — buttons show a demo confirmation; actual file export requires a backend
- **Play Protect warning** — APK signed with debug key, not a Play Store key; "Install anyway" is safe for demo purposes
- **AI responses** — AI Assistant shows pre-scripted responses, not live LLM output
- **OTP / email login** — sign-in accepts any password; no OTP is sent or verified
- **Geolocation features** — map pins are static coordinates; no live GPS

---

## Support

Demo build prepared for internal review — EY FireShield AI Platform.
