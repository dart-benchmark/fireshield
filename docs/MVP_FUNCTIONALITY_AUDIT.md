# FireShield MVP functionality audit

Audit date: 15 August 2026

## Executive baseline

The Flutter screens contain **83 direct `onPressed` / `onTap` action declarations**. This is a static code count, not a count of unique rendered controls: reusable builders and list rows can render an action more than once.

- **Current live deployment:** 2 showcase actions call a real backend: site-photo vision detection and compliance reasoning. That is roughly **2% of raw action declarations** (2/83).
- **Current local branch:** 3 showcase actions call a real backend after the new GPT-OSS chat wiring: detection, compliance reasoning, and chat. That is roughly **4% of raw action declarations** (3/83).
- An additional NBCS graph lookup runs automatically inside the AI audit wizard; it is real backend functionality but is not counted as a button.

This strict percentage intentionally excludes navigation, tabs, filters, reveal-password toggles, local wizard controls, and demo-state changes. Those controls may work correctly as UI, but they are not backend functionality.

For an MVP, the more useful denominator is the set of prominent actions a presenter might reasonably imply are operational. Across authentication, CRUD, audits, evidence, reporting, government action, AI and plans, there are about **16 backend-worthy action families**. Two are live today (**~13%**); the local chat change raises this to three (**~19%**) before plan conversion is completed.

## Feature truth table

| Area | UI behavior | Persistent/backend behavior | MVP status |
|---|---|---|---|
| Demo role login | Works and routes by role | Local demo users only; email password is not validated | Demo-only |
| Dashboards and analytics | Tabs, filters and drill-downs work | Metrics come from static mock data | Demo-only |
| Organisation registration | Wizard and success state work | No organisation is created | Fake success |
| Facility creation | Wizard and success state work | No facility is created | Fake success |
| User creation/invite | Form and success state work | No user or invitation is created | Fake success |
| Audit assignment | Wizard and success state work | No audit is saved or assigned | Fake success |
| Checklist execution | Local selections and summary work | Answers/evidence are not persisted | Local-only |
| Documents | Rows can be toggled attached/unattached | No file picker, storage or validation | Mock |
| Equipment / drills / NOC | Tabs and local interactions work | Static data; no save workflow | Mock |
| Reports | Report cards are visible | Export explicitly says it is not wired | Dead CTA |
| Government action | Review UI is visible | Escalate handler is empty; no case workflow | Dead CTA |
| Site photo detection | Camera/gallery → CLIPSeg where supported + Qwen | Real model path through Worker | Core MVP |
| NBCS regulation lookup | Loads clauses in AI audit wizard | Real KV graph query | Core MVP |
| Compliance reasoning | GPT-OSS + NBCS tool calls produce findings | Real model path through Worker | Core MVP |
| AI assistant | Local branch now calls grounded GPT-OSS chat | Not present in current Pages bundle yet | Ready to deploy |
| Floor-plan assessment / DXF | AI Workspace link exists locally | Route is still a placeholder; converter is separate | In progress |

## Live deployment evidence

- GitHub Pages responds successfully.
- Its deployed JavaScript contains `/groq/vision`, `/groq/reason`, `/nbc/query`, and the AI Audit Engine.
- Its deployed JavaScript does **not** contain `/groq/chat`; the grounded assistant change is local only until the next Pages build.
- The live Worker health endpoint reports both Groq and the NBCS index configured. The live Worker does not yet report the new rate-limiter bindings, so the local Worker changes are also not deployed.

## MVP target

The showcase should optimize for three complete journeys rather than broad enterprise CRUD:

1. **Site assessment:** upload real photos → CLIPSeg/Qwen observations → edit/confirm evidence → GPT-OSS NBCS findings → downloadable result.
2. **Building-plan assessment:** upload image/PDF → deterministic topology → bounded Qwen correction → NBCS plan findings → preview + DXF/JSON/report download.
3. **Grounded assistant:** ask a fire-safety question → GPT-OSS answer with NBCS page citations and clear uncertainty.

Supporting MVP behavior:

- All roles can reach the same AI Workspace.
- Demo dashboards remain available but carry a visible `Demo data` label.
- Fake success screens are either connected to lightweight persistence or relabelled `Preview only`.
- Empty handlers and “not wired” primary CTAs are removed from the presentation path.
- Each AI output shows source/model, citations where applicable, limitations, and retry/error states.

## Coverage milestones

| Milestone | Showcase-critical result | Expected backend-worthy coverage |
|---|---|---:|
| A — deploy current AI work | Site assessment + grounded chat live | ~19% |
| B — plan workflow | All three headline AI journeys live | ~25% |
| C — evidence and exports | Persist an assessment and download report/artifacts | ~38% |
| D — thin operational backend | Real auth, facilities, audits and findings | ~63% |
| E — enterprise workflows | Users/invites, NOC, government actions, drills, notifications | 85%+ |

The percentages are planning estimates against the 16 backend-worthy action families, not test-coverage metrics.

## Recommended showcase scope

Implement milestones A–C first. For the MVP presentation, keep organisation/user administration and government workflows as explicitly labelled demo views. They add breadth, but do not strengthen the core claim that FireShield can inspect a site, assess a plan, and explain the applicable fire guidance.
