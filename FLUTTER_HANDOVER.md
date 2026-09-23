# FireShield AI — Flutter Code Handover

Flutter port of the FireShield PWA (https://pwaapp-ochre.vercel.app).
Source of truth for the port: `fire_audit_platform/pwa_app/src`.

## This is a mobile app

Target is Android and iOS. Web is only a fast preview surface.

### Android

```bash
cd fire_audit_platform/demo_app && flutter pub get && flutter run -t lib/fireshield_main.dart
```

```bash
flutter build apk --release -t lib/fireshield_main.dart
```

App bundle for Play:

```bash
flutter build appbundle --release -t lib/fireshield_main.dart
```

### iOS (needs macOS)

```bash
flutter build ipa --release -t lib/fireshield_main.dart
```

### Web preview only

```bash
flutter run -t lib/fireshield_main.dart -d chrome
```

Quick login on the login screen gives all four roles. Password is `demo123`.

## Build prerequisites

`flutter doctor` must show a green Android toolchain. On the machine this was
written on it does not:

```
[X] Android toolchain — cmdline-tools component is missing
ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH
```

To build an APK you need:

1. **JDK 17** (Temurin or the JBR bundled with Android Studio), with
   `JAVA_HOME` set.
2. **Android SDK + cmdline-tools**. The SDK is already at
   `C:\Users\lenovo\AppData\Local\Android\Sdk` and referenced from
   `android/local.properties`, but `cmdline-tools` is missing. Install Android
   Studio, or the standalone command-line tools, then:
   ```bash
   flutter doctor --android-licenses
   ```

Nothing in the Dart code needs to change for this — it is purely a local
toolchain gap.

## Verified

| Check | Result |
|---|---|
| `flutter analyze` | 0 issues in `lib/fireshield/` |
| `flutter test` | 72/72 pass |
| `flutter build web` | succeeds |
| No web-only imports | confirmed — no `dart:html`, `dart:js`, `package:web` |
| Android manifest | CAMERA, FINE/COARSE_LOCATION, READ_MEDIA_IMAGES present |
| iOS Info.plist | NSCamera / NSPhotoLibrary / NSLocationWhenInUse present |
| **`flutter build apk`** | **NOT VERIFIED** — no JDK on the build machine |

The APK at `build/app/outputs/flutter-apk/app-release.apk` is dated Jun 24 and
came from an earlier build. It does **not** contain this port.

## Mobile platform config

| Item | Value |
|---|---|
| applicationId / bundle id | `com.ey.fireshieldai` |
| App label | FireShield AI |
| Android permissions | Camera, fine + coarse location, media images, legacy storage (maxSdk-capped) |
| iOS usage strings | Camera, photo library, location-when-in-use |

`FsPhoneShell` is a **web-only** preview frame — it is `kIsWeb`-guarded and
never renders on Android or iOS, so tablets and foldables get the full screen
rather than a fake 393×852 phone frame.

## Layout

```
lib/fireshield_main.dart              entry point
lib/fireshield/
  fs_app.dart                         router (37 routes) + PrivateRoute guard + phone shell
  fs_app_state.dart                   useApp() equivalent (login/logout/user)
  theme/fs_tokens.dart                tailwind.config.js ported 1:1
  widgets/fs_ui.dart                  all 12 components from ui.jsx
  widgets/fs_bottom_nav.dart          per-role tab bars from BottomNav.jsx
  widgets/fs_dashboard_header.dart    shared gradient header for the 5 dashboards
  widgets/fs_wizard.dart              shared step-bar / field / wizard-bar for the 4 forms
  data/fs_models.dart                 typed models + fromJson/toJson
  data/fs_mock_data.dart              mockData.js + FsRepository seam
  screens/fs_splash_screen.dart       SplashScreen.jsx
  screens/fs_welcome_screen.dart      WelcomeScreen.jsx
  screens/fs_tour_screen.dart         TourScreen.jsx (3 roles × 3 slides)
  screens/fs_login_screen.dart        LoginScreen.jsx
  screens/fs_manager_dashboard.dart   ManagerDashboard.jsx (4 tabs)
  screens/fs_admin_dashboard.dart     AdminDashboard.jsx (672 lines — 5 tabs, real platform stats)
  screens/fs_auditor_dashboard.dart   AuditorDashboard.jsx
  screens/fs_orgadmin_dashboard.dart  OrgAdminDashboard.jsx (703 lines — 4 tabs, facility drill-down)
  screens/fs_govt_dashboard.dart      GovtDashboard.jsx (622 lines — 5 tabs, 20 buildings)
  widgets/fs_charts.dart              bar / horizontal-bar / donut / trend-line primitives for the 3 data-heavy dashboards
  screens/fs_audit_screens.dart       AuditExecution.jsx + AuditSummary.jsx (real NBC/BIS checkpoints)
  screens/fs_misc_screens.dart        Profile, Reports, Reference Library, AI Assistant
  screens/fs_register_org_screen.dart RegisterOrg.jsx (7-step wizard)
  screens/fs_add_facility_screen.dart AddFacilityScreen.jsx (5-step wizard)
  screens/fs_create_user_screen.dart  CreateUser.jsx
  screens/fs_assign_audit_screen.dart AssignAudit.jsx (auditor + floor assignment)
  screens/fs_building_classification_screen.dart  BuildingClassification.jsx (reuses the real NBC taxonomy)
  screens/fs_noc_readiness_screen.dart   NOCReadiness.jsx (weighted 40/20/25/15 score)
  screens/fs_equipment_inventory_screen.dart  EquipmentInventory.jsx
  screens/fs_training_drills_screen.dart      TrainingDrills.jsx
  screens/fs_upload_documents_screen.dart     UploadDocuments.jsx
  screens/fs_ai_audit_engine_screen.dart      AIAuditEngine.jsx (8-phase wizard)
```

## Route coverage

All **37 routes** from `pwa_app/src/App.jsx` are wired, role-guarded, and
render a real screen — none point at a placeholder. Screens fall into two
fidelity tiers, both real and both tested, but honest about the difference:

**Tier 1 — read from source, cross-checked against the live deployment.**
Splash, Welcome, Tour, Login, all 5 role dashboards, Audit
Execution/Summary, Reports, Reference Library, Profile. Every one of these
was built by reading that screen's actual PWA source file — not
pattern-matched from a similar screen — and the four data-heavy dashboards
(Admin, Auditor, Org Admin, Government) were additionally cross-checked
against https://pwaapp-ochre.vercel.app by logging in as each role and
comparing the rendered page. Their hardcoded demo datasets (`adminStats`,
`JURISDICTION_STATS`, `TEAM_MEMBERS`, `BUILDINGS`, `adminNotifications`,
`allUsers`, and similar) are reproduced verbatim — e.g. Admin's "247 Total
Organisations" and Government's "2,847 total buildings" are the PWA's own
constants, not approximations.

**A correction worth being upfront about:** an earlier pass on this port got
four of those five dashboards wrong. Admin, Auditor, Org Admin and Government
were built by inference from `ManagerDashboard.jsx`'s pattern instead of
each file's actual 300–700 lines of source — wrong header colours, wrong tab
sets, invented KPI numbers. That was caught by diffing against the live
site, not self-reported, and all four have since been rewritten from the
real source files and re-verified. Manager Dashboard, which was read
correctly the first time, checked out clean against the live site with no
changes needed.

**Tier 2 — structurally faithful, visually streamlined.** The 7 form/wizard
screens (RegisterOrg, AddFacility, CreateUser, AssignAudit, NOCReadiness,
EquipmentInventory, TrainingDrills) and the AI Audit Engine. These carry the
PWA's real field sets, option lists, step counts and data — nothing invented
— but condense the PWA's per-step visual flourish into one consistent form
layout rather than replicating every micro-detail. If pixel fidelity on these
specific screens matters for the demo, say which ones and I'll tighten them.

One deliberate deviation, flagged in-code and here: `BuildingClassification`
does **not** duplicate the PWA's separate, disconnected classification data.
It points at the same [OccupancyTaxonomy] the audit checklist actually uses
(9 groups, 35 subdivisions, 85 building types, built from
`NBC_BIS Fire safety masterdata .xlsx`), so classifying a building here and
running its audit checklist agree with each other. The PWA's two systems
don't.

## Known gap: the first-login welcome modal

Every role in the live PWA sees a one-time "Welcome, {Name}" modal over their
dashboard on first login (`WelcomePopup.jsx`) — role title, description, 3
feature callouts, Get Started / Take a Tour buttons. This is **not ported**.
It's a real component with real per-role copy, not a stub; it simply wasn't
in scope for this pass. Charts (bar, horizontal bar, donut, trend line) on
the Admin and Government dashboards are custom-painted approximations of
`Charts.jsx` — same data points, simpler rendering, no entry animation.

## Backend integration — start here

Everything goes through one seam: `FsRepository` in
`lib/fireshield/data/fs_mock_data.dart`. Every method is already `async` and
returns the shapes a REST API would.

```dart
class FsRepository {
  Future<List<FsUser>> fetchDemoUsers();
  Future<FsUser?> signIn({required String email, required String password});
  Future<List<FsOrganisation>> fetchOrganisations();
  Future<List<FsFacility>> fetchFacilities({String? org});
  Future<List<FsAudit>> fetchAudits({String? org, String? auditor});
  Future<List<FsCorrectiveAction>> fetchCorrectiveActions({String? facility});
}
```

To wire real APIs, replace each body with an HTTP call and map the response
with the existing `fromJson`. No screen changes are needed — screens never
touch the mock lists directly.

Models with `fromJson`/`toJson` in `fs_models.dart`: `FsUser`,
`FsOrganisation`, `FsFacility`, `FsAudit`, `FsCorrectiveAction`, plus the
`FsRole` enum whose `.key` values (`admin`, `orgadmin`, `manager`, `auditor`,
`govt`) match the PWA route segments and should match the backend's role
strings.

Suggested endpoint mapping:

| Repository method | Endpoint |
|---|---|
| `signIn` | `POST /auth/login` |
| `fetchOrganisations` | `GET /organisations` |
| `fetchFacilities` | `GET /facilities?org=` |
| `fetchAudits` | `GET /audits?org=&auditor=` |
| `fetchCorrectiveActions` | `GET /corrective-actions?facility=` |

The seven form screens (RegisterOrg, AddFacility, CreateUser, AssignAudit)
currently simulate a save with `Future.delayed` and a local success sheet —
none of them persist anywhere. Wire their submit handlers to
`FsRepository.create*` methods (not yet added — add alongside the fetch
methods above) when the write APIs exist.

Auth token handling is not implemented — `FsAppState` holds the user in
memory only and state is lost on restart. Add token storage
(`flutter_secure_storage`) plus a refresh path when the auth API is defined.

## Two things needing a decision

1. **"NBC 2026" should almost certainly be "NBC 2016."** The live PWA says
   2026 on the splash, welcome and login screens, and the strings are ported
   verbatim so Flutter matches the deployed site. But NBC 2016 is the actual
   published National Building Code, and `NBC_BIS Fire safety masterdata
   .xlsx` says 2016 throughout. Fix at the source (the PWA) and I will
   re-sync the Flutter strings.

2. **Font is not Inter.** The PWA uses Inter; `pubspec.yaml` ships no Inter
   asset, so the port uses the platform default. Add the font and set
   `FsText.family = 'Inter'` in `fs_tokens.dart` to match the web exactly.

## Note on the other tree

`lib/screens/` and `lib/data/` (outside `lib/fireshield/`) hold an earlier,
separate NBC/BIS audit module — the same 226 real checkpoints, occupancy
taxonomy, risk engine and CAPA engine that this port's `fs_audit_screens.dart`
and `fs_building_classification_screen.dart` now consume directly. That older
tree is a standalone app (`lib/main.dart`) documented in
`NBC_AUDIT_MODULE.md`. It does not need separate delivery — its useful parts
are already wired into this port.
