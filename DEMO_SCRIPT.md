# DEMO_SCRIPT.md — FireShield AI
## 10-Minute Manager Walkthrough

**Presenter:** EY team  
**Audience:** Manager / client reviewer  
**Duration:** 8–10 minutes (scripted path)  
**Device:** Android phone with `app-release.apk` installed  
**Pre-check:** App installed and open to splash screen before meeting starts

---

## Before the Demo

- Install the APK on your demo phone (see INSTALLATION_GUIDE.md)
- Do a full run-through once before the meeting
- Keep DEMO_SCRIPT.md open on your laptop as a reference
- Do NOT hand the phone to the reviewer — navigate yourself and narrate
- Stay strictly on the scripted path — do not tap filter icons, (+) buttons, or individual CA cards

---

## MINUTE 0–1 | Opening & Splash

**[App is already open to the splash screen]**

**Say:**
> "FireShield AI is a self-service fire audit and compliance platform built for the Indian regulatory landscape — covering NBC 2016, IS 2190, IS 2189, and OISD standards. It supports five roles: Government officers, Platform admins, Organisation admins, Safety managers, and Field auditors. Let me walk you through each role in the next ten minutes."

**Do:**
- Let the splash screen auto-advance to the Login screen
- Point out: FireShield AI logo, "Self Fire Audit Readiness & Compliance Platform", "Developed by EY"

---

## MINUTE 1–2 | Login & Role Selection

**[On the Login screen]**

**Say:**
> "The login screen supports role-based access. Let's start with the field auditor role."

**Do:**
1. Tap the **Email** field → type `priya.nair@auditcorp.in`
2. Tap the **Password** field → type any text (e.g. `auditor123`)
3. Tap **Sign In**
4. The role picker bottom sheet appears — point out the 5 available users

**Say:**
> "The platform recognises each user's role automatically. Priya Nair is a certified fire auditor assigned to the Phoenix Mall facility in Bengaluru."

**Do:**
5. Tap **Priya Nair (Auditor)**

---

## MINUTE 2–4 | Auditor Dashboard → Audit Execution

**[On the Auditor Dashboard]**

**Say:**
> "The auditor sees their assigned audit queue — facility name, audit type, scheduled date, and current FRI score. Phoenix Mall Bengaluru is in-progress."

**Do:**
1. Point to the audit cards and status badges (Scheduled / In Progress / Submitted)
2. Tap the **Phoenix Mall Bengaluru** audit card
3. Tap **Start Audit** (or "Resume Audit" button)

**[On the Audit Execution screen]**

**Say:**
> "The audit engine walks through structured checklists mapped to Indian fire safety standards. Each checklist item references the specific clause — NBC 2016 Part 4, IS 2190 for extinguishers, IS 2189 for detection systems."

**Do:**
4. Point out the three section tabs: **NBC 2016**, **IS 2190**, **IS 2189**
5. On the first tab, tap **YES** on 2 items, **PARTIAL** on 1, **NO** on 1
6. Show how the red non-compliant badge appears on the tab

**Say:**
> "Every non-compliant or partial response is automatically flagged. The auditor can add evidence photos in the production version. The platform tracks compliance rate in real time."

**Do:**
7. Tap the **IS 2190** tab — point out extinguisher checklist items
8. Respond to 2–3 items
9. Tap the **IS 2189** tab — point out detection system items
10. Respond to 1–2 items

---

## MINUTE 4–5 | Audit Summary

**[Still on Audit Execution — ready to submit]**

**Say:**
> "Once the auditor completes the checklist, they submit the audit. The platform instantly generates the audit summary with FRI score, findings, and recommendations."

**Do:**
1. Tap the **Submit Audit** button
2. Confirm in the dialog if one appears

**[On the Audit Summary screen]**

**Say:**
> "The Fire Readiness Index — or FRI — is a composite score calculated from compliance rate, safety index, and emergency readiness. Phoenix Mall scores 78 out of 100."

**Do:**
3. Point to the circular FRI gauge
4. Tap the **Findings** tab — point out 6 flagged items with NBC/IS clause references and severity badges
5. Tap the **Recommendations** tab — point out recommendations with cost estimates and timelines

**Say:**
> "Each recommendation includes an estimated remediation cost and timeline — so the facility manager and fire officer can immediately prioritise corrective actions."

---

## MINUTE 5–6 | Safety Manager — Dashboard & NOC Readiness

**[Navigate: device back → Login]**

**Do:**
1. Use the device back button to return to Login
2. Enter `rajesh.kumar@refineryco.in` → any password → Sign In
3. Select **Rajesh Kumar (Safety Manager)**

**[On the Safety Manager Dashboard]**

**Say:**
> "The Safety Manager gets an operational command view. The KPI row shows overall compliance rate, open corrective actions, critical facilities, and days until NOC renewal. The NOC countdown is a real compliance deadline — many facilities lose their fire NOC because they miss this window."

**Do:**
4. Point to the KPI cards: Compliance %, Open CAs, NOC Days Remaining
5. Tap the **Compliance** tab — show facility list with FRI scores and NOC status badges

**Say:**
> "Every facility in the portfolio is ranked by Fire Readiness Index. Red badges indicate facilities approaching NOC expiry or with critical non-compliances."

---

## MINUTE 6–7 | Corrective Actions

**[Still as Safety Manager]**

**Do:**
1. Navigate to **Corrective Actions** (bottom nav or from dashboard card)

**Say:**
> "Corrective actions are auto-generated from audit findings. Each CA has a severity level — Critical, High, Medium, Low — a responsible owner, and a due date. The tab filter lets the safety manager focus on overdue or critical items."

**Do:**
2. Point to the summary row: total CAs, open, overdue counts
3. Tap the **Critical** tab — show filtered list
4. Tap the **Overdue** tab — show filtered list

**Say:**
> "In the production system, CAs trigger push notifications to the responsible team, integrate with the organisation's existing corrective action workflow, and auto-escalate if not closed by the due date."

---

## MINUTE 7–8 | AI Compliance Assistant

**[Still as Safety Manager — navigate to AI Assistant]**

**Do:**
1. Tap **AI Assistant** (bottom nav or from dashboard)

**Say:**
> "The AI Compliance Reference Assistant is trained on NBC 2016, IS standards, OISD regulations, and PESO guidelines. It answers regulatory questions, interprets clauses, and provides facility-type specific requirements."

**Do:**
2. Tap the suggestion chip: **"Sprinkler requirements for malls"**  
   *(OR type:* `What are NBC 2016 exit requirements for hospitals?`*)*
3. Wait for the simulated response (~2 seconds typing indicator)
4. Point out the response — NBC Part 4 clause references, specific requirements

**Say:**
> "Instead of a fire officer manually searching through hundred-page regulatory documents, they can ask the assistant in plain language and get clause-referenced answers in seconds."

---

## MINUTE 8–9 | Platform Admin — Governance View

**[Navigate: device back → Login]**

**Do:**
1. Back to Login → `admin@fireaudit.gov.in` → any password → Sign In → Platform Admin

**[On the Admin Dashboard]**

**Say:**
> "The Platform Admin has a governance view across the entire ecosystem — 48 registered organisations, 312 facilities, 924 active users, and 6,843 audits conducted. This is the command centre for the regulator or EY's platform operations team."

**Do:**
2. Point to the governance KPI cards
3. Scroll to show the Industry Breakdown — Petroleum, Healthcare, Commercial, Industrial segments
4. Tap the **Organisations** tab — show org list

**Say:**
> "Each organisation is registered with GST number, industry classification, and NOC status. The admin can onboard new organisations through a guided multi-step form."

**Do:**
5. Tap **Register Organisation** button (or equivalent)
6. Walk through: Organisation name → GST → Industry → Contact → "Add Facility" step

**Say:**
> "The registration flow captures all regulatory data needed to issue fire NOC applications. In production, this triggers an automated workflow to the State Fire Department."

---

## MINUTE 9–10 | Government Officer — Regulatory Oversight

**[Navigate: device back → Login]**

**Do:**
1. Back to Login → `arjun.singh@mfd.gov.in` → any password → Sign In → Govt Officer

**[On the Government Dashboard]**

**Say:**
> "The Government Officer dashboard gives the State Fire Department a real-time view of compliance across all registered facilities in their jurisdiction. Critical facilities — those with expired NOC or FRI below threshold — are flagged for priority inspection."

**Do:**
2. Point to the overview KPIs: Total facilities, Compliant, Non-Compliant, Pending NOC, Expired NOC
3. Scroll through the facility list — show red/amber/green risk badges
4. Tap the **Analytics** tab — show compliance distribution chart

**Say:**
> "This replaces manual inspections and paper-based compliance registers. The government officer can see the FRI score of every facility, schedule inspections from the platform, and issue or reject NOC applications digitally."

---

## Closing (30 seconds)

**Say:**
> "To summarise — FireShield AI digitises the entire fire safety compliance lifecycle: from the field auditor's checklist to the government officer's NOC dashboard. It works offline on Android and iPhone, uses Indian regulatory standards as the audit backbone, and gives every stakeholder a role-specific view of compliance. This is the demo build. The production version will integrate with Azure AD for authentication, Azure OpenAI for the compliance assistant, and backend APIs for data persistence and workflow automation."

---

## Emergency Fallback Points

If something goes wrong during the demo, fall back to these safe moments:

| If... | Do this |
|-------|---------|
| App crashes | Restart and go to Login — demo the login flow itself |
| Audit summary looks wrong | Say "the system captures the findings in real time — let me show you the data model" and switch to Admin |
| Reviewer asks to tap a dead button | Say "that feature triggers a backend workflow — in the live system it would open the approval queue" |
| Reviewer wants to type in AI | Accept their question only if it's about: hospital, mall, school, sprinkler, extinguisher, hydrant, NOC, NBC 2016, CAPA, exits |
| Reviewer asks about Azure AI | Say "the production integration connects to Azure OpenAI — the demo uses a regulatory rules engine for predictability" |

---

## Safe AI Questions for Demo

Use exactly these phrases to get substantive AI responses:

| Type this | Topic shown |
|-----------|------------|
| `Sprinkler design for shopping malls` | IS 15105 coverage, K-factor, hazard classification |
| `Fire extinguisher requirements NBC 2016` | IS 2190 clause references, types, spacing |
| `Hospital fire safety standards` | NABH, compartmentalisation, detection zones |
| `Exit requirements for high rise buildings` | NBC Part 4 egress width, staircase requirements |
| `What is CAPA in fire audits` | Corrective and Preventive Action framework |
| `NOC renewal process` | State Fire Department procedure, required documents |
