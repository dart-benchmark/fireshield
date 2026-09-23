# TESTFLIGHT_SETUP.md — FireShield AI
**Version:** 1.0.0-demo  
**Bundle ID:** com.ey.fireshieldai  
**Developer:** EY

---

## Prerequisites — What You Need Before Starting

| Requirement | Details | Where to Get |
|-------------|---------|--------------|
| Apple Developer Account | $99/year individual or free enterprise | developer.apple.com |
| Mac computer | macOS 13+ (Ventura or later) | Required — IPA cannot be built on Windows |
| Xcode 15 or later | Free from Mac App Store | Mac App Store |
| Flutter SDK | Already installed | flutter.dev |
| Apple ID enrolled in Developer Program | Must be paid tier for TestFlight | developer.apple.com/enroll |

> **Critical:** Building an IPA for TestFlight is only possible on a Mac with Xcode. The project files are fully configured — transfer the `demo_app/` folder to a Mac and follow the steps below.

---

## Step 1 — Register the App ID on Apple Developer Portal

1. Go to [developer.apple.com](https://developer.apple.com) → **Certificates, IDs & Profiles**
2. Click **Identifiers** → `+`
3. Select **App IDs** → **App**
4. Fill in:
   - Description: `FireShield AI`
   - Bundle ID (Explicit): `com.ey.fireshieldai`
5. Enable capabilities: **Push Notifications** (optional for demo)
6. Click **Register**

---

## Step 2 — Create a Distribution Certificate

1. On your Mac, open **Keychain Access** → Certificate Assistant → **Request a Certificate from a Certificate Authority**
   - Email: your Apple ID email
   - Common Name: `EY FireShield AI`
   - Save to disk
2. In Apple Developer Portal → **Certificates** → `+`
3. Select **Apple Distribution**
4. Upload the `.certSigningRequest` file → **Generate**
5. Download the `.cer` file → double-click to install in Keychain

---

## Step 3 — Create a Provisioning Profile

1. Apple Developer Portal → **Profiles** → `+`
2. Select **App Store Connect** (for TestFlight)
3. Select App ID: `com.ey.fireshieldai`
4. Select the Distribution Certificate from Step 2
5. Name the profile: `FireShield AI AppStore`
6. Download → double-click to install

---

## Step 4 — Transfer Project to Mac

Copy the entire `demo_app/` folder to the Mac. On the Mac, run:

```bash
cd /path/to/demo_app
flutter clean
flutter pub get
```

Install CocoaPods if not already installed:
```bash
sudo gem install cocoapods
cd ios
pod install
cd ..
```

---

## Step 5 — Open in Xcode and Configure Signing

```bash
open ios/Runner.xcworkspace
```

In Xcode:
1. Select the **Runner** project in the sidebar
2. Select the **Runner** target → **Signing & Capabilities**
3. Set **Team** to your Apple Developer team
4. Set **Bundle Identifier**: `com.ey.fireshieldai`
5. Set **Signing Certificate**: Apple Distribution
6. Set **Provisioning Profile**: `FireShield AI AppStore`

---

## Step 6 — Build and Archive (IPA)

### Option A — Flutter CLI (recommended)

```bash
flutter build ipa --release
```

Output:
```
build/ios/ipa/fire_audit_demo.ipa
```

### Option B — Xcode Archive

1. In Xcode: **Product → Archive**
2. Wait for archive to complete (5–15 minutes first time)
3. **Organizer** window opens automatically
4. Click **Distribute App** → **App Store Connect** → **Upload**

---

## Step 7 — Upload to TestFlight

### Via Xcode Organizer (Option B above — automatic after archive)

### Via Transporter (standalone tool)
1. Download **Transporter** from the Mac App Store
2. Open Transporter → sign in with your Apple ID
3. Drag the `.ipa` file → click **Deliver**

### Via Flutter CLI
```bash
xcrun altool --upload-app -f build/ios/ipa/fire_audit_demo.ipa \
  -t ios --apiKey <YOUR_KEY_ID> --apiIssuer <YOUR_ISSUER_ID>
```

---

## Step 8 — Configure TestFlight in App Store Connect

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Select **FireShield AI** (or create the app if first upload)
3. Navigate to **TestFlight** tab
4. Wait for build processing (5–30 minutes)
5. Add **Internal Testers** (up to 100 Apple IDs)
6. Add **External Testers** — requires App Review approval (1–2 business days)

---

## Step 9 — Tester Installation

Testers receive an email invitation.

1. Install **TestFlight** app from App Store on their iPhone
2. Open the email invitation link
3. Accept → Install

No additional steps required — TestFlight handles distribution.

---

## Demo Credentials (include in TestFlight test notes)

| Role | Email | Password |
|------|-------|----------|
| Platform Admin | admin@fireaudit.gov.in | admin123 |
| Org Admin | org.admin@refineryco.in | org123 |
| Auditor | priya.nair@auditcorp.in | auditor123 |
| Safety Manager | rajesh.kumar@refineryco.in | sm123 |
| Govt Officer | arjun.singh@mfd.gov.in | govt123 |

**Paste these into the TestFlight "What to Test" notes so testers don't need separate documents.**

---

## Estimated Timeline

| Task | Effort | Who |
|------|--------|-----|
| Apple Developer enrollment | 1 day (instant if already enrolled) | EY account |
| Certificates + profiles setup | 30 minutes | Mac + Developer Portal |
| Transfer project to Mac | 5 minutes | Copy demo_app folder |
| flutter pub get + pod install | 10 minutes | Terminal |
| flutter build ipa --release | 10–20 minutes | Terminal |
| Upload + TestFlight processing | 30–60 minutes | Xcode / Transporter |
| Tester invitation | 5 minutes | App Store Connect |
| **Total** | **~2–3 hours** (assuming Apple account exists) | |

If Apple Developer account needs to be purchased and enrolled: add 1–2 business days for Apple verification.

---

## Known Limitations for TestFlight Build

1. **Signed with distribution certificate** — testers install via TestFlight only (not sideload)
2. **Camera / Photo Library** — permission strings are set; feature stubs show "next release" snackbar
3. **Location** — permission string is set; not used in current demo flow
4. **No push notifications** — notification screen shows mock data only
5. **Offline only** — no backend; works without any network connectivity
6. **iOS 13+ required** — deployment target is iOS 13.0
