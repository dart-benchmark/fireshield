# NBC/BIS Audit Module

Adds a real regulation-backed audit flow to the demo app:

```
/building-classification  →  /nbc-checklist  →  /risk-dashboard  →  /capa-tracker
```

## What's in it

| Layer | File | Contents |
|---|---|---|
| Model | `lib/data/checkpoint_model.dart` | `Checkpoint`, `Severity`, `Response`, `CheckpointAnswer` |
| Masterdata | `lib/data/nbc_bis_masterdata.dart` | 152 NBC + 74 BIS checkpoints (generated) |
| Taxonomy | `lib/data/occupancy_taxonomy.dart` | 9 groups, 35 subdivisions, 85 building types |
| Risk | `lib/core/engine/risk_engine.dart` | Weighted scoring, NOC gate |
| CAPA | `lib/core/engine/capa_engine.dart` | Action lifecycle, due dates, escalation |
| State | `lib/core/engine/audit_session.dart` | In-memory audit session |
| Screens | `lib/screens/classification`, `audit_engine/nbc_checklist_screen.dart`, `risk`, `capa` | Four screens |

## Masterdata is generated

`lib/data/nbc_bis_masterdata.dart` is generated — do not hand-edit it.

Source: `Fire Audit/NBC_BIS Fire safety masterdata .xlsx`, sheets `NBC` and `BIS`.

```bash
python tool/gen_masterdata.py
```

NBC categories (152 checkpoints): Building Characteristics 10, Means of Escape 26,
Fire Detection & Alarm 18, Fire Fighting Systems 25, Fire Pumps & Water Storage 13,
Fire Command Centre 7, Fire Lifts 9, Smoke Management 9, Electrical & Standby Power 9,
Building Construction 9, Emergency Preparedness 8, AC/HVAC 4, Additional Systems 5.

BIS standards (74 checkpoints): IS 2190, IS 2189, IS 3844, IS 15105, IS 12458,
IS 13039, IS/ISO 7240, IS 884, IS 15301, IS 2309, IS 14665 Pt.2.

## Scoring

Compliance is severity-weighted, not a flat pass percentage:

```
compliance = Σ(weight of passed) / Σ(weight of answered) × 100
```

Weights: critical 5, major 3, minor 1.

`N/A` and unanswered are excluded from the denominator. A section where nothing
was answered returns `null`, not `0` — the UI shows "Not scored".

Residual risk applies the occupancy hazard factor:

```
risk = (100 − compliance) × hazardFactor,  clamped to 100
```

Hazard factors run 0.8 (private dwelling) to 3.0 (explosives magazine).

Grade bands on residual risk: <15 Low, <35 Moderate, <60 High, else Critical.
One critical failure floors the grade at High; three or more force Critical.

NOC needs all three: every checkpoint answered, zero critical failures,
compliance ≥ 80%.

## CAPA

One action per failed checkpoint. Due window follows severity — critical 7 days,
major 30, minor 90. Escalation rises with overdue days (critical escalates
faster): none → supervisor → management → authority. Closing, verifying or
submitting stops the clock.

Owner is routed by category — escape and emergency go to Safety Manager,
electrical/HVAC/lifts to Facility Engineer, pumps and detection and all BIS
items to Fire Systems Technician, construction to Projects Team.

## Assumptions that need sign-off

These were not in the source data and were set to sensible defaults:

1. **Severity per checkpoint** — assigned by category in the generator, since
   the Excel has no severity column. Edit `NBC_SEVERITY` / `BIS_SEVERITY` in
   `tool/gen_masterdata.py` and regenerate.
2. **Severity weights** (5/3/1) — in `SeverityInfo.weight`.
3. **Hazard factors per subdivision** — in `occupancy_taxonomy.dart`.
4. **NOC threshold** (80%) — `RiskEngine.nocThreshold`.
5. **CAPA due windows** (7/30/90) — `SeverityInfo.capaDueDays`.
6. **Checkpoint applicability** — currently all checkpoints apply to every
   building type except lifts for `A-2`. If the KB defines per-occupancy
   applicability, wire it into `OccupancyTaxonomy.checkpointsFor`.

## Tests

```bash
flutter test test/risk_capa_test.dart
```

18 tests covering masterdata integrity, taxonomy referential integrity,
scoring behaviour (N/A exclusion, critical flooring, severity weighting,
hazard amplification) and the CAPA lifecycle.

## Not done

- Nothing persists. `AuditSession` is in-memory; a restart clears the audit.
  Swap the backing store in that one class when an API exists.
- Evidence capture is modelled (`evidenceRefs`) but not wired to the camera.
- The 53-point NOC checklist (`53 point checklist.xlsx`) is not loaded yet.
