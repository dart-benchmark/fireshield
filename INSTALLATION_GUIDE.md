# INSTALLATION_GUIDE.md — FireShield AI
**Version:** 1.0.0-demo  
**Package:** com.ey.fireshieldai

---

## Option 1 — Android APK (Recommended for immediate demo)

### Requirements
- Any Android phone running Android 5.0 or later (API 21+)
- "Install unknown apps" permission (one-time setup)

### Step 1 — Transfer the APK

**APK file location:**
```
fire_audit_platform/demo_app/build/app/outputs/flutter-apk/app-release.apk
```
File size: **54.1 MB**

Choose one transfer method:

| Method | How |
|--------|-----|
| USB cable | Connect phone → select File Transfer → copy APK to Downloads |
| Google Drive | Upload APK → share link → open on phone |
| WhatsApp | Send as Document (not image) — tap attach → Document |
| OneDrive | Upload → open shared link on phone |
| Telegram | Send file directly in chat |

### Step 2 — Allow Unknown Sources

On the Android phone:
- Android 8 or later: Settings → Apps → Special app access → Install unknown apps → (your file manager app) → Allow
- Android 7 or earlier: Settings → Security → Unknown sources → Enable

### Step 3 — Install

1. Open the file manager on the phone
2. Navigate to Downloads (or wherever you copied the APK)
3. Tap **app-release.apk**
4. Tap **Install**
5. Tap **Open** when installation completes

### Step 4 — Launch

Tap **FireShield AI** on the home screen.

Login with any demo credential (see credentials section below).

### Troubleshooting

| Problem | Fix |
|---------|-----|
| "App not installed" | Previous version exists — Settings → Apps → FireShield AI → Uninstall, then reinstall |
| "Parse error" | APK file is corrupt — re-transfer the file |
| App crashes on launch | Clear cache: Settings → Apps → FireShield AI → Storage → Clear cache |
| "Blocked by Play Protect" | Tap "Install anyway" — this is expected for sideloaded apps |

---

## Option 2 — iPhone PWA (No App Store required)

Install FireShield AI as a Progressive Web App on iPhone. No Apple Developer account needed.

### Requirements
- iPhone with Safari browser
- The PWA must be hosted at a web URL (local network or public URL)

### Step 1 — Host the PWA

On a Windows PC connected to the same Wi-Fi as the iPhone:

```powershell
# Using Python (already installed on your machine)
cd "C:\Users\lenovo\OneDrive\Desktop\fire_audit_platform\pwa_app\dist"
python -m http.server 8080
```

Find your PC's local IP address:
```powershell
ipconfig | Select-String "IPv4"
# Example output: 192.168.1.105
```

The PWA is now accessible at: `http://192.168.1.105:8080`

### Step 2 — Open in Safari on iPhone

1. Open **Safari** on the iPhone (must be Safari — Chrome on iOS does not support PWA install)
2. Go to: `http://<your-PC-IP>:8080`
3. The FireShield AI app will load in the browser

### Step 3 — Add to Home Screen

1. Tap the **Share** icon (box with arrow pointing up) at the bottom of Safari
2. Scroll down and tap **Add to Home Screen**
3. Name it: `FireShield AI`
4. Tap **Add**

The app icon appears on the iPhone home screen. Tap it to launch in full-screen mode (no Safari address bar).

### PWA Limitations on iPhone

| Limitation | Details |
|-----------|---------|
| Offline after first visit | Works offline once loaded — service worker caches all assets |
| No push notifications | iOS PWA push requires iOS 16.4+ and user permission |
| No camera access | PWA camera requires HTTPS; not available on local HTTP |
| App may be removed | iOS can remove PWA storage after a few weeks of inactivity |

---

## Option 3 — TestFlight (iOS native app)

TestFlight delivers the full native iOS experience. Requires an Apple Developer account and a Mac.

### What You Need

| Requirement | Details |
|-------------|---------|
| Apple Developer account | $99/year — enroll at developer.apple.com |
| Mac with Xcode 15+ | Required for building IPA |
| Apple TestFlight app | Free from App Store — testers install this first |

### High-Level Process

1. **On Mac:** Transfer the `demo_app/` project folder
2. **On Mac:** Run `flutter clean && flutter pub get && cd ios && pod install`
3. **In Xcode:** Open `ios/Runner.xcworkspace` → configure signing with your Apple Developer team
4. **Run:** `flutter build ipa --release`
5. **Upload:** Open Xcode Organizer or Transporter → deliver IPA to App Store Connect
6. **In App Store Connect:** Go to TestFlight → add internal testers by Apple ID
7. **Testers:** Install TestFlight app → accept email invitation → install FireShield AI

**Detailed step-by-step:** See `TESTFLIGHT_SETUP.md`

### Tester Installation (once distributed via TestFlight)

1. Install **TestFlight** from the App Store
2. Open the TestFlight invitation email → tap **View in TestFlight**
3. Tap **Install**
4. Launch **FireShield AI**

---

## Demo Credentials (all platforms)

| Role | Email | Password |
|------|-------|----------|
| Platform Admin | admin@fireaudit.gov.in | admin123 |
| Org Admin | vikram.mehta@phoenixmalls.com | org123 |
| Auditor | priya.nair@auditcorp.in | auditor123 |
| Safety Manager | rajesh.kumar@refineryco.in | sm123 |
| Govt Officer | arjun.singh@mfd.gov.in | govt123 |

> **Note:** Any password works for the above emails. Unknown emails show a "Contact Administrator" dialog with EY support details.

---

## Quick Reference

| Platform | File/URL | Time to Install |
|----------|----------|----------------|
| Android | `app-release.apk` (54.1 MB) | 2 minutes |
| iPhone PWA | Local server URL | 3 minutes |
| iPhone TestFlight | Via email invite | 5 minutes (after build uploaded) |
