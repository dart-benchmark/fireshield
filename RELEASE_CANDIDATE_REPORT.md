# RELEASE_CANDIDATE_REPORT.md — FireShield AI
**Version:** 1.0.0-demo  
**Date:** June 2026  
**Package:** com.ey.fireshieldai  
**Flutter:** 3.44.2 stable  
**Reviewer:** Final pre-demo release check

---

## Overall Readiness Summary

| Platform | Status | Blocker? |
|----------|--------|---------|
| Android APK | ✅ READY | None — APK built and verified |
| iOS (TestFlight) | ⚠️ MAC REQUIRED | Needs Mac + Apple Developer account |
| PWA (Web) | ✅ READY | Deployed dist/ folder exists |
| Flutter Analyze | ✅ CLEAN | 0 errors, 0 warnings, 18 info-level lint hints |

**Demo Readiness Score: 8.0 / 10**  
**Production Readiness Score: 1 / 10** *(demo only — no backend, no auth, no persistence)*

---

## Android Readiness

| Item | Status | Detail |
|------|--------|--------|
| APK built | ✅ | `build/app/outputs/flutter-apk/app-release.apk` |
| APK size | ✅ | 54.1 MB |
| Min Android | ✅ | Android 5.0 (API 21) |
| Target Android | ✅ | Android 16 (API 36) |
| Package name | ✅ | `com.ey.fireshieldai` |
| Signing | ✅ | Debug key (demo sideload) |
| App icon | ✅ | 5 mipmap densities (mdpi → xxxhdpi) |
| Splash screen | ✅ | EY-branded dark navy background |
| Launcher label | ✅ | "FireShield AI" |
| Internet permission | ✅ | Declared (no backend calls made) |
| Camera permission | ✅ | Declared with usage description |
| Offline mode | ✅ | 100% mock data, zero API calls |

**Android Verdict: Ready for sideload distribution and manager demo.**

### Android SHA Fingerprints (debug key)
| Algorithm | Fingerprint |
|-----------|-------------|
| SHA-1 | `0B:93:4F:87:1D:86:7D:2E:97:D2:38:17:64:CA:14:85:42:B4:05:40` |
| SHA-256 | `B5:D5:D4:49:9A:22:BC:BB:5C:34:0F:43:1E:58:72:04:95:26:74:7F:32:00:10:28:45:E5:2A:A5:58:D2:E9:C4` |

---

## iOS Readiness

| Item | Status | Detail |
|------|--------|--------|
| iOS folder | ✅ | Created — `ios/Runner.xcodeproj` + `ios/Runner.xcworkspace` |
| Bundle Identifier | ✅ | `com.ey.fireshieldai` |
| Display name | ✅ | `FireShield AI` |
| Deployment target | ✅ | iOS 13.0 (iPhone 8 and later) |
| App icons | ✅ | 15 sizes generated (iPhone + iPad + App Store 1024×1024) |
| Launch screen | ✅ | EY-branded storyboard with tagline and "Developed by EY" |
| Info.plist permissions | ✅ | Camera, Photo Library, Location — with proper usage strings |
| Portrait orientation | ✅ | Locked to portrait on iPhone |
| Xcode signing | ❌ | Requires Apple Developer Team — must configure on Mac |
| CocoaPods install | ❌ | Must run `pod install` on Mac |
| IPA built | ❌ | Requires Mac + Xcode — cannot build on Windows |
| TestFlight upload | ❌ | Requires IPA + Apple Developer account |

**iOS Verdict: Project fully configured. IPA requires a Mac. Follow TESTFLIGHT_SETUP.md.**

---

## PWA Readiness

| Item | Status | Detail |
|------|--------|--------|
| Build output | ✅ | `pwa_app/dist/` exists |
| index.html | ✅ | Present, dated June 22 2026 |
| Service worker | ✅ | `sw.js` + `workbox-9c191d2f.js` present |
| Manifest | ✅ | `manifest.webmanifest` present |
| Offline capability | ✅ | Workbox caching configured |
| 200.html fallback | ✅ | SPA routing fallback present |
| Assets | ✅ | `assets/` and `icons/` directories present |

**PWA Verdict: Ready. Host the `dist/` folder on any static server or CDN.**  
iPhone users can install via Safari → Share → Add to Home Screen.

---

## Remaining Blockers

### Blocking for iOS IPA (must resolve on Mac)
1. **Apple Developer Account** — $99/year enrollment required
2. **Distribution Certificate** — generate on Mac via Keychain Access
3. **Provisioning Profile** — `com.ey.fireshieldai` App Store profile
4. **pod install** — must run on Mac before Xcode build
5. **Xcode signing** — set Team in Xcode Signing & Capabilities

### Non-Blocking (known demo limitations — accepted)
- CA detail screen does not exist (tapping CA card does nothing)
- Equipment detail screen does not exist
- Notifications do not deep-link
- Filter buttons throughout are stubs
- PDF export shows dialog only — no actual file
- Document Intelligence upload is a timer animation

---

## Known Limitations

| # | Limitation | Impact | Workaround |
|---|-----------|--------|-----------|
| 1 | CA detail screen missing | Medium | Do not tap CA cards during demo |
| 2 | Equipment detail screen missing | Low | Scroll list only; do not tap cards |
| 3 | Notifications do not navigate | Low | Show notification list; do not tap individual items |
| 4 | Audit always loads Phoenix Mall | Low | Scripted demo always uses Phoenix Mall flow |
| 5 | Checklist state resets on back-nav | Medium | Complete audit in one session without back-navigating |
| 6 | PDF/export is dialog only | Medium | Mention "full export in production" during demo |
| 7 | AI is keyword matcher (17 topics) | Medium | Stay within the scripted AI questions in DEMO_SCRIPT.md |
| 8 | Document upload is timer animation | Medium | Frame as "processing in progress" during demo |
| 9 | Status bar always shows 9:41 | Low | Cosmetic — ignore |
| 10 | No logout button on most dashboards | Low | Use device back button to reach login |
| 11 | Filter icons are stubs | Low | Do not tap filter/sort icons |
| 12 | Register Org — no confirmation screen | Low | End the step at "Add Facility" button |

---

## Demo Flow (Validated)

Follow this exact sequence. All steps below are verified to work:

| Step | Action | What It Shows |
|------|--------|--------------|
| 1 | Launch app → Splash auto-advances | FireShield AI branding |
| 2 | Login: `priya.nair@auditcorp.in` → any password → Priya Nair (Auditor) | Role-based login |
| 3 | Auditor Dashboard → tap Phoenix Mall audit → Start Audit | Assigned audit queue |
| 4 | Checklist tabs: NBC 2016, IS 2190, IS 2189 → respond YES/NO/PARTIAL | Live audit execution |
| 5 | Non-compliant badge count updates on tabs | Real-time compliance tracking |
| 6 | Tap Submit → Audit Summary screen | FRI score, findings, recommendations |
| 7 | Back to Login → `rajesh.kumar@refineryco.in` → Safety Manager | Role switch |
| 8 | SM Dashboard: KPI cards, Compliance tab, Facility FRI list | Operational overview |
| 9 | Navigate to Corrective Actions → show CA list, tabs | CA management |
| 10 | Navigate to AI Assistant → type scripted query | NBC/IS compliance reference |
| 11 | Navigate to Document Intelligence → Floor Plan → Upload | AI extraction simulation |
| 12 | Back to Login → `admin@fireaudit.gov.in` → Platform Admin | Governance view |
| 13 | Admin: KPI cards (48 orgs, 312 facilities) → Register Org (multi-step) | Platform management |
| 14 | Back to Login → `arjun.singh@mfd.gov.in` → Govt Officer | Regulatory view |
| 15 | Govt Dashboard: compliance overview, facility risk list | Government oversight |

**Total scripted time: 8–10 minutes**

---

## Test Credentials

| Role | Name | Email | Password |
|------|------|-------|----------|
| Auditor | Priya Nair | priya.nair@auditcorp.in | auditor123 *(any works)* |
| Safety Manager | Rajesh Kumar | rajesh.kumar@refineryco.in | sm123 *(any works)* |
| Platform Admin | Admin | admin@fireaudit.gov.in | admin123 *(any works)* |
| Org Admin | Vikram Mehta | vikram.mehta@phoenixmalls.com | org123 *(any works)* |
| Govt Officer | Arjun Singh | arjun.singh@mfd.gov.in | govt123 *(any works)* |
| Safety Manager | Dr. Meena Patel | meena.patel@cityhospital.in | sm123 *(any works)* |

> The login accepts any password for known demo emails. Unknown emails show a "Contact Administrator" dialog.

---

## App Routes (All Verified)

| Route | Screen | Status |
|-------|--------|--------|
| `/` | SplashScreen | ✅ |
| `/login` | LoginScreen | ✅ |
| `/auditor` | AuditorDashboard | ✅ |
| `/audit-execution` | AuditExecutionScreen | ✅ |
| `/audit-summary` | AuditSummaryScreen | ✅ |
| `/safety-manager` | SafetyManagerDashboard | ✅ |
| `/corrective-actions` | CorrectiveActionsScreen | ✅ |
| `/equipment` | EquipmentScreen | ✅ |
| `/ai-assistant` | AiAssistantScreen | ✅ |
| `/doc-intelligence` | DocumentIntelligenceScreen | ✅ |
| `/reports` | ReportsScreen | ✅ |
| `/notifications` | NotificationsScreen | ✅ |
| `/admin` | AdminDashboard | ✅ |
| `/register-org` | RegisterOrgScreen | ✅ |
| `/org-admin` | OrgAdminDashboard | ✅ |
| `/create-user` | CreateUserScreen | ✅ |
| `/government` | GovernmentDashboard | ✅ |
