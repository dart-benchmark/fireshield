# BUILD_APK.md — FireShield AI Android Build Guide

**App:** FireShield AI | EY  
**Package:** com.ey.fireshieldai  
**Version:** 1.0.0-demo  

This document covers everything needed to produce `app-release.apk` and `app-release.aab`
from the existing Flutter project after Android Studio is installed.

---

## Pre-Build Verification (Already Confirmed)

| Check | Status |
|-------|--------|
| `namespace` / `applicationId` | `com.ey.fireshieldai` |
| `versionName` | `1.0.0-demo` |
| `versionCode` | `1` |
| `minSdk` | `21` (Android 5.0+) |
| `targetSdk` | Flutter default (35) |
| Signing config | debug key (demo build) |
| `android:label` | `FireShield AI` |
| `MainActivity.kt` package | `com.ey.fireshieldai` |
| Launcher icons | 5 mipmap densities (mdpi–xxxhdpi) |
| Splash screen | `#0D0D1A` deep navy |
| `flutter pub get` | Clean — no errors |
| `flutter analyze` | No issues found |
| Demo data | Fully embedded in `lib/data/mock_data.dart` |
| Backend dependency | None — fully offline |

---

## Step 1 — Install Android Studio

1. Download **Android Studio** from:
   `https://developer.android.com/studio`

2. Run the installer — accept all defaults.

3. On first launch, the **Android SDK Setup Wizard** appears automatically.
   - Click **Next** through all steps.
   - Accept the license agreements.
   - Let it download the Android SDK (~1.5 GB). This takes 5–15 minutes.

4. Once the wizard finishes, close Android Studio.

---

## Step 2 — Accept Android Licenses

Open a terminal (Command Prompt or PowerShell) and run:

```
flutter doctor --android-licenses
```

Expected prompt:
```
Accept? (y/N): 
```

Type `y` and press Enter for each license (typically 5–7 prompts).

Expected final output:
```
All SDK package licenses accepted.
```

---

## Step 3 — Verify the Toolchain

```
flutter doctor
```

Expected output (all relevant lines should be green):

```
[✓] Flutter (Channel stable, 3.44.x)
[✓] Windows Version
[✓] Android toolchain - develop for Android devices
      Android SDK at C:\Users\<you>\AppData\Local\Android\Sdk
      Platform android-35, build-tools 35.0.0
      Java binary at: ...
      Java version OpenJDK ...
[✓] Android Studio (version 2024.x)
[✓] Connected device (if a device is plugged in)
[✓] Network resources
```

> If `Android toolchain` still shows `[X]`, open Android Studio, go to
> **SDK Manager** (top-right gear icon), install **Android SDK Platform 35**
> and **Android SDK Build-Tools 35.0.0**, then re-run `flutter doctor`.

---

## Step 4 — Get Dependencies

```
cd fire_audit_platform/demo_app
flutter pub get
```

Expected output:
```
Got dependencies!
```

---

## Step 5 — Build Release APK

```
flutter build apk --release
```

Expected output:
```
Running Gradle task 'assembleRelease'...          
Built build\app\outputs\flutter-apk\app-release.apk (XX.X MB).
```

> First build downloads Gradle dependencies and takes 3–8 minutes.
> Subsequent builds complete in under 2 minutes.

**Output file:**
```
fire_audit_platform/demo_app/build/app/outputs/flutter-apk/app-release.apk
```

---

## Step 6 — Build Release App Bundle (optional, for Play Store)

```
flutter build appbundle --release
```

Expected output:
```
Running Gradle task 'bundleRelease'...
Built build\app\outputs\bundle\release\app-release.aab (XX.X MB).
```

**Output file:**
```
fire_audit_platform/demo_app/build/app/outputs/bundle/release/app-release.aab
```

---

## All Commands at a Glance

Run these in order after Android Studio is installed:

```
flutter doctor --android-licenses
flutter doctor
cd fire_audit_platform/demo_app
flutter pub get
flutter build apk --release
flutter build appbundle --release
```

---

## Install APK on a Physical Device

1. **Enable Unknown Sources** on the target device:
   - Android 8+: Settings > Apps > Special app access > Install unknown apps > allow File Manager
   - Android 7: Settings > Security > Unknown sources (toggle on)

2. **Transfer the APK** to the device:
   - USB cable (copy `app-release.apk` to device storage), or
   - Email attachment, or
   - WhatsApp/Telegram file share, or
   - Google Drive / OneDrive

3. Open the file manager on the device, locate `app-release.apk`, tap it, and tap **Install**.

4. If "Play Protect blocked the install" appears, tap **Install anyway**.
   The APK is signed with a debug key for demo purposes — this warning is expected.

5. The app installs as **FireShield AI** and appears on the home screen.

---

## Troubleshooting

| Error | Fix |
|-------|-----|
| `Android SDK not found` | Re-run Android Studio SDK wizard; check `flutter doctor` |
| `Licenses not accepted` | Run `flutter doctor --android-licenses` and type `y` for each |
| `Gradle build failed` — JDK error | Ensure Android Studio's bundled JDK is used: in Android Studio > Settings > Build > Gradle > Gradle JDK, select the bundled JDK |
| `Gradle build failed` — network timeout | Run again; first build downloads Gradle wrapper (~120 MB) |
| `Play Protect blocked install` | Tap "Install anyway" — expected for debug-signed demo APK |
| `App not installed` — version conflict | Uninstall any previous version of the app, then install again |
| `flutter: command not found` | Add Flutter SDK `bin` folder to PATH; restart terminal |

---

## Demo Credentials (post-install)

| Role | Email | Password |
|------|-------|----------|
| Safety Manager | rajesh.kumar@refineryco.in | any |
| Auditor | priya.nair@auditcorp.in | any |
| Org Admin | vikram.mehta@phoenixmalls.com | any |
| Govt Officer | arjun.singh@mfd.gov.in | any |
| Platform Admin | admin@fireaudit.gov.in | any |

Password accepts any value — demo mode, no authentication server.

---

## Notes

- The release build uses the **debug signing key** — appropriate for demo distribution.
  For a production Play Store release, generate a proper keystore with `keytool`.
- Minification (`isMinifyEnabled`) and resource shrinking (`isShrinkResources`) are
  disabled to ensure all demo screens and assets are retained in the build.
- All demo data is embedded in `lib/data/mock_data.dart` — no internet connection required.
