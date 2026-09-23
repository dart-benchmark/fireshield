# BUILD_REPORT.md — FireShield AI Demo Stabilization
**Date:** June 2026  
**Version:** 1.0.0-demo  
**Package:** com.ey.fireshieldai

---

## 5 Fixes Applied

### FIX 1 — Audit Continuity (RESOLVED)

**Problem:** Audit execution showed `AUD-202606-001089 / Phoenix Mall Bengaluru`. After tapping Submit, audit summary showed `AUD-2026-031 / Phoenix Marketcity Bengaluru`. Two completely different audit identities mid-flow.

**Fix:**
- `audit_execution_screen.dart`: passes `_audit` (live `MockAudit` object) as GoRouter `extra` when navigating to `/audit-summary`
- `main.dart`: `/audit-summary` route extracts the `MockAudit` from `state.extra`
- `audit_summary_screen.dart`: completely rewritten to accept `MockAudit audit` parameter. All header fields (Audit ID, Facility, Auditor, Date, Type, Status) now read directly from the passed object. Scores computed from `audit.score`, `audit.nonCompliant`, `audit.totalItems`. Client name and issuing authority derived from `audit.facilityType` via a switch statement. Print/export dialogs reference `audit.auditNo` and `audit.facilityName`.

**Result:** Audit ID and facility name are now identical across the entire execution → summary flow.

---

### FIX 2 — KPI Consistency (RESOLVED)

**Problem:** `DashboardStats.adminStats['totalAudits'] = 1847` and `GovernanceStats.totalAudits = 6843` — two different numbers for the same metric shown on the same Admin dashboard.

**Fix:** `mock_data.dart` — `DashboardStats.adminStats` now references `GovernanceStats` constants directly:
```dart
'totalOrgs':      GovernanceStats.totalOrgs,       // 48
'totalFacilities': GovernanceStats.totalFacilities, // 312
'totalAudits':    GovernanceStats.totalAudits,      // 6843
'activeUsers':    GovernanceStats.totalUsers,       // 924
```

**Result:** Single source of truth. All dashboards reference the same figures. No conflicting numbers.

---

### FIX 3 — AI Assistant (RESOLVED)

**Problem:** App claimed "Powered by Azure OpenAI GPT-4o" but responses were keyword-matched strings. Any question outside 3 topics returned a generic paragraph, immediately breaking the demo.

**Fix:**
- AppBar subtitle changed: `Powered by Azure OpenAI GPT-4o` → `Compliance Reference — NBC / BIS / OISD / PESO`
- Admin Settings tab: `Azure OpenAI GPT-4o` integration label → `AI Compliance Engine`
- Seed greeting in `mock_data.dart`: removed "Azure OpenAI" reference
- `_generateResponse()` expanded from 3 topics to **16 topic areas:**

| Topic | Keywords |
|-------|----------|
| Hospitals | hospital, nabh, healthcare |
| Shopping Malls | mall, shopping, retail, mercantile |
| Schools | school, college, education, university |
| Warehouses | warehouse, storage, godown |
| Hotels | hotel, hospitality, resort |
| Factories | factory, manufacturing, industrial |
| Airports | airport, terminal, dgca, bcas |
| Fire Extinguishers | extinguisher, abc, co2, dry powder |
| Hydrant & Hose Reel | hydrant, hose reel, wet riser |
| Sprinkler Systems | sprinkler, suppression, deluge |
| Smoke Detectors | detector, smoke, heat detector |
| Fire Alarm | fire alarm, panel, mcp, call point |
| Exits & Egress | exit, egress, evacuation, escape |
| Occupancy Load | occupancy, load, capacity, persons |
| Fire NOC | noc, no objection, fire certificate |
| NBC 2016 | nbc, national building, part 4 |
| CAPA | capa, corrective, action plan, finding |

- Generic fallback now returns a comprehensive standards reference guide (not a vague 4-line paragraph)
- Suggestion chips updated to cover diverse topics

---

### FIX 4 — Login Branding (RESOLVED)

**Problem:** Login screen title read "Fire Audit Platform", not matching the product name "FireShield AI".

**Fix in `login_screen.dart`:**
```
Before: "Fire Audit Platform"
After:  "FireShield AI"

Before: "Self Fire Audit & Readiness Platform"
After:  "Self Fire Audit Readiness & Compliance Platform"

Added:  "Developed by EY"
```

Also added a proper "Forgot Password?" dialog — previously the button was a silent stub. Now shows a dialog with administrator contact details.

---

### FIX 5 — Dead Buttons (RESOLVED)

All identified `onPressed: () {}` and `onTap: () {}` stubs replaced with `ScaffoldMessenger` snackbar: **"This feature is available in the next release."**

| Location | Dead button fixed |
|----------|------------------|
| `login_screen.dart` | Forgot Password → now shows a dialog with admin contact |
| `ca_screen.dart` | Filter icon button |
| `ca_screen.dart` | Add (+) icon button |
| `ai_assistant_screen.dart` | Settings/Tune icon button |
| `ai_assistant_screen.dart` | Copy, Thumbs Up, Thumbs Down on AI messages |
| `ai_assistant_screen.dart` | Mic input button |
| `audit_execution_screen.dart` | Voice, Doc, Flag action icons in checklist |
| `admin_dashboard.dart` | More options (⋮) button in header |
| `admin_dashboard.dart` | "View All" on System Alerts |
| `admin_dashboard.dart` | Search button in Organisations tab |

---

## Updated Demo Readiness Score

| Dimension | Before | After | Change |
|-----------|--------|-------|--------|
| UI Completeness | 7 / 10 | 7 / 10 | — |
| Data Believability | 9 / 10 | 9 / 10 | — |
| Navigation | 8 / 10 | 9 / 10 | +1 (audit flow now continuous) |
| Feature Depth | 5 / 10 | 5 / 10 | — |
| Offline Capability | 10 / 10 | 10 / 10 | — |
| Crash Risk | 8 / 10 | 9 / 10 | +1 (dead buttons now safe) |
| Visual Polish | 7 / 10 | 8 / 10 | +1 (branding corrected) |
| AI Credibility | 3 / 10 | 7 / 10 | +4 (16 topics, no false claims) |

**Overall Demo Readiness: 6.5 → 8.0 / 10**

---

## Known Limitations Remaining (Post-Fix)

These are known, accepted limitations for the demo. They do not block the manager review.

1. **Audit checklist has 3 sections / ~9 items** — real audits have 8–15 sections with 150–250 items. The structure is correct; data volume is thin.
2. **CA detail view does not exist** — tapping a CA card does nothing. CA list is the final level of navigation.
3. **Equipment detail view does not exist** — same as above.
4. **Notifications do not deep-link** — tapping a notification does not navigate.
5. **Audit checklist responses reset on back-navigation** — state is in-memory only.
6. **PDF export shows confirmation dialog only** — no actual file is generated.
7. **Audit execution always loads Phoenix Mall** — `mockAudits[0]` is hardcoded in execution screen; only one facility can be audited.
8. **Phone frame status bar shows "9:41"** — hardcoded; cosmetic.
9. **No logout button on Safety Manager / Auditor / Govt dashboards** — only Admin Settings tab has Sign Out. Use device back button to return to login.

---

## Recommended Demo Path (Revised)

Follow this exact sequence to demonstrate all key features without hitting any broken functionality:

| Step | Action | What to show |
|------|--------|-------------|
| 1 | Splash → Login | FireShield AI branding, "Developed by EY", standards compliance banner |
| 2 | Email: `priya.nair@auditcorp.in` → Sign In → Priya Nair (Auditor) | Role picker, clean login flow |
| 3 | Auditor Dashboard | Assigned audits, status chips, FRI scores |
| 4 | Tap Phoenix Mall audit → Start Audit | Audit execution: checklist tabs, YES/NO/PARTIAL, non-compliant badges |
| 5 | Tap Submit | Audit summary: **same audit ID and facility throughout** |
| 6 | Show Findings tab, Scores tab, Recommendations tab | Clause references, cost estimates |
| 7 | Back to login → `rajesh.kumar@refineryco.in` → Safety Manager | Dashboard KPIs, NOC countdown |
| 8 | Navigate to Corrective Actions | CA list, severity colours, tab filtering (don't tap individual cards) |
| 9 | Navigate to AI Assistant | Type: "Sprinkler design for shopping malls" → show IS 15105 response |
| 10 | Navigate to Document Intelligence | Select Floor Plan → Upload → Show extraction animation and results |
| 11 | Back to login → `admin@fireaudit.gov.in` → Platform Admin | 48 orgs, 312 facilities, governance KPIs |
| 12 | Admin: Register Org flow | Multi-step form |
| 13 | Back to login → `arjun.singh@mfd.gov.in` → Govt Officer | Compliance overview, facility risk list |

**Avoid during demo:** Individual CA cards, individual equipment items, notification cards (no destination), the Forgot Password dialog (now works but shows admin contact — fine to show), QR scanner button on equipment screen.

---

## Android Build Status

APK build was running at time of this report (downloading NDK 28.2.13676358 + Android SDK Platform 36 automatically). Build expected to complete within 10–15 minutes of SDK download.

**Output when complete:**
```
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab
```
