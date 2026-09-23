# Demo Guide — Fire Audit Platform

## Prerequisites

- Flutter SDK installed and `flutter doctor` passes
- Run `flutter pub get` inside `demo_app/` before first launch
- For web demo: `flutter run -d chrome` or open `build/web/index.html` after `flutter build web --release`
- The app requires no backend, no login credentials, and no network connection

---

## Demo Users (Quick Login)

On the Login screen, tap **"Quick Demo Login"** and select a role from the bottom sheet.

| Name | Role | Email | Facility |
|------|------|-------|----------|
| Rajesh Kumar | Safety Manager | rajesh.kumar@refineryco.in | Jamnagar Refinery Complex |
| Dr. Meena Patel | Safety Manager | meena.patel@cityhospital.in | City Hospital Ahmedabad |
| Arjun Singh | Government Officer | arjun.singh@mfd.gov.in | Maharashtra Fire Department |
| Priya Nair | Auditor | priya.nair@auditcorp.in | Phoenix Mall Bengaluru |
| Admin User | Platform Admin | admin@fireaudit.gov.in | All Facilities |
| Vikram Mehta | Organisation Admin | vikram.mehta@phoenixmalls.com | All Phoenix Facilities |

---

## Scenario 1 — Platform Admin Overview (Admin User)

**Goal:** Show the governance dashboard and organization management.

1. Open the app → Splash screen auto-navigates to Login
2. Tap **"Quick Demo Login"** → select **"Platform Admin"** (Admin User)
3. You land on the **Admin Dashboard** — Overview tab
   - 4 KPI cards: 312 orgs, 1,847 facilities, 3,924 audits, 94.2% NOC coverage
   - System Health: 6 service tiles (all green/operational)
   - Recent alerts list
4. Tap **"Orgs"** tab — see organization list with NOC status badges
5. Tap **"Users"** tab — see system user list across all organizations
6. Tap **"+ Register Organisation"** → opens multi-step **Register Org** form (demo: fill fields and tap Next; no data is saved)
7. Tap the bell icon → **Notifications** screen
8. Tap **Settings** tab → see system configuration tiles
9. Tap profile menu → **Sign Out** → returns to Login

---

## Scenario 2 — Safety Manager Daily Workflow (Rajesh Kumar)

**Goal:** Show audit oversight, compliance tracking, and AI assistant.

1. Login as **Safety Manager** (Rajesh Kumar — Jamnagar Refinery)
2. **Dashboard tab** shows:
   - 4 stat cards: Active Facilities (4), Pending Audits (3), Open CAs (12), Avg Compliance (82%)
   - Facility compliance progress bars (Jamnagar: 78%, City Hospital: 85%, Phoenix Mall: 91%, Delhi School: 52%)
   - Active audits list
3. Tap **"Start Audit"** on any audit card → opens **Audit Execution** screen
   - Shows Jamnagar Refinery checklist (148 questions, 5 sections)
   - Section 1: Fire Exits & Evacuation Routes — scroll through items
   - Tap any item → expand to see YES/NO/PARTIAL/N/A response buttons
   - Note pre-filled answers and flagged items (red flag icon)
   - Tap the **camera icon** → snackbar: "Evidence capture coming soon"
   - Tap **"Complete Audit"** → navigates to **Audit Summary** screen
4. On **Audit Summary**: Executive score 78.4%, findings breakdown, section scores, recommendations
5. Go back → **Dashboard** → tap **"Compliance"** tab
   - Fire Systems / Structural / Evacuation / Administrative compliance bars
   - Active standards list (NBC 2016, IS 1641, OISD-STD-116, NFPA 72)
6. Tap **"Reports"** tab → report archive with Generate Report button
7. Tap **"Corrective Actions"** from Dashboard quick actions → see 8 mock CAs with priorities
   - Filter by status — tap any CA → detail bottom sheet → "Mark Complete" button
8. Tap **"AI Assistant"** quick action → type "What are NBC 2016 exit requirements?" → get instant regulation response
9. Tap **"Documents"** → **Document Intelligence** screen
   - Tap **"Upload Document"** → pick any option → watch AI processing animation
   - Result shows Phoenix Marketcity extraction: NOC No., validity dates, compliance gaps

---

## Scenario 3 — Auditor Field Workflow (Priya Nair)

**Goal:** Show the mobile-first audit execution experience.

1. Login as **Auditor** (Priya Nair — Phoenix Mall Bengaluru)
2. **Dashboard** shows: 4 assigned, 28 completed, 2 pending, 14 findings
3. **Today's Schedule** shows 2 audits: Phoenix Mall (IN_PROGRESS) and City Hospital (SCHEDULED)
4. Tap **"Start Audit"** quick action or tap a schedule card → **Audit Execution** screen
   - Swipe through checklist sections using the tab bar: Fire Exits, Detection Systems, Suppression, Emergency Lighting, Staff Training
   - Tap an unanswered item → select a response → item updates inline
   - Flagged items show a red indicator
5. Tap **"My Audits"** tab → full audit list — tap **"Resume"** on the IN_PROGRESS audit
6. Tap **"Equipment"** tab → 7 equipment items with status badges (OPERATIONAL / MAINTENANCE_DUE / OUT_OF_SERVICE)
7. Tap **"AI Assistant"** → ask "Is a hospital above 6 floors required to have sprinklers?" → see pre-canned response
8. Tap bell → Notifications (4 mock notifications with type icons)
9. Profile → Sign Out

---

## Scenario 4 — Government Officer Inspection View (Arjun Singh)

**Goal:** Show regulatory oversight and multi-facility analytics.

1. Login as **Government Officer** (Arjun Singh — Maharashtra Fire Department)
2. **Overview tab**:
   - 4 KPI cards: 847 facilities, 12 pending inspections, 34 violations this month, 89.2% compliance rate
   - Alert bar: 3 critical violations
   - Facility cards with FRI scores and NOC status
3. Tap **"Facilities"** tab → list of all 6 facilities with compliance %, risk level, and NOC status
   - Delhi Public School: CRITICAL risk, NOC Expired, 52% compliance — highlighted in red
4. Tap **"Inspections"** tab → inspection schedule with status badges
5. Tap **"Analytics"** tab → compliance trend chart, risk distribution, top violations list
6. Tap bell → Notifications

---

## Scenario 5 — Organisation Admin (Vikram Mehta)

**Goal:** Show org-level facility management and user provisioning.

1. Login as **Organisation Admin** (Vikram Mehta — Phoenix Malls)
2. **Overview tab**:
   - Facilities managed: 3, Active users: 28, Ongoing audits: 2, Compliance: 87%
   - Facility cards for Phoenix Bengaluru, Phoenix Pune, Phoenix Chennai
3. Tap **"Facilities"** tab → facility detail cards with compliance bars
4. Tap **"Users"** tab → user list with role badges; tap **"+ Add User"** → Create User form
   - Fill name, email, role dropdown, department → "Create User" button (snackbar confirmation)
5. Tap **"Audits"** tab → audit list for all owned facilities
6. Tap **"Equipment"** tab → equipment registry for all facilities
7. Tap **"Corrective Actions"** → CAs filtered to org facilities

---

## Scenario 6 — End-to-End Audit Cycle (Combined)

Use this for a full stakeholder walkthrough (5–7 minutes).

| Step | Actor | Action | Screen |
|------|-------|--------|--------|
| 1 | Admin User | Register new org | `/register-org` |
| 2 | Admin User | Create auditor account | (UI demo only) |
| 3 | Vikram Mehta (Org Admin) | Add user, view facilities | `/org-admin` |
| 4 | Rajesh Kumar (Safety Mgr) | View scheduled audit, check compliance | `/safety-manager` |
| 5 | Priya Nair (Auditor) | Execute checklist, flag findings | `/audit-execution` |
| 6 | Priya Nair (Auditor) | Submit audit → view summary | `/audit-summary` |
| 7 | Rajesh Kumar (Safety Mgr) | Review corrective actions | `/corrective-actions` |
| 8 | Arjun Singh (Govt Officer) | View compliance analytics | `/government` |

---

## Tips for Live Demo

- The app works best in **portrait orientation** on a phone or in Chrome DevTools mobile view (430×932 — iPhone 14 Pro Max)
- On a wide desktop screen, the app renders inside a **decorative phone frame** automatically
- All data resets when the app is restarted (no persistence)
- The **AI Assistant** has prepared responses for: hospital sprinkler requirements, smoke detector placement, fire extinguisher types. Other queries return a generic response
- **Document Intelligence** always extracts the same Phoenix Marketcity document — the file picker is decorative
- To go back to the Login screen from any dashboard: Profile tab → Sign Out
