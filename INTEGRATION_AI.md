# FireShield AI integration — what was built & how to run it

Adds real vision + NBCS 2026 compliance to the AI Audit Engine vertical slice.
Front-end stays web-PWA + mobile-friendly; the Groq key never reaches the browser.

## Pieces

| Area | Files |
|---|---|
| NBC 2026 query index (built from graphify) | `tool/gen_nbc_query_index.py` → `worker/data/nbc_query_index.json` |
| Secure Groq gateway + live `query_nbc` tool | `worker/src/worker.js`, `worker/src/nbc_graph.js`, `worker/wrangler.jsonc`, `worker/README.md` |
| Dart services | `lib/fireshield/services/fs_config.dart`, `fs_groq_service.dart`, `fs_clipseg_service.dart` (+ `fs_clipseg_interop_web.dart` / `_stub.dart`) |
| Models | `lib/fireshield/data/fs_models.dart` (`DetectedEquipment`, `NbcClause`, `ComplianceFinding`, `FsAuditRun`) |
| In-browser CLIPSeg | `web/clipseg/fireseg.js` (+ `<script>` in `web/index.html`) |
| Wired screen + state | `lib/fireshield/screens/fs_ai_audit_engine_screen.dart`, `fs_building_classification_screen.dart`, `lib/fireshield/fs_app_state.dart` |
| Dep | `pubspec.yaml` → `http` |

## Data flow (AI Audit Engine)
classify occupancy (+height/area) → **P2** live NBC 2026 clauses (`/nbc/query`) →
**P4** photos → CLIPSeg (if supported) + Qwen vision (`/groq/vision`) → observed equipment →
**P6** gpt-oss (`/groq/reason`) decides mandatory systems, queries the graph live per system,
compares vs observed → findings with clause+page citations → **P7/P8** score + NOC readiness.

## Run locally (needs Flutter SDK — not installed on this machine)

```bash
cd CodeBase/FireShield_Flutter_Source/fireshield_flutter
flutter pub get
flutter analyze
flutter run -t lib/fireshield_main.dart -d chrome \
  --dart-define=FIRESHIELD_WORKER_URL=https://fireshield-groq-gateway.<sub>.workers.dev
```

Without `--dart-define`, the app runs but the AI phases show an explicit
"not configured" state (no fake results).

## Deploy the Worker (needs your Cloudflare account)
See `worker/README.md`. Summary: `wrangler whoami` → set `<STORE_ID>` (reuse existing
`GROQ_API_KEY`) + `<OWNER>` in `wrangler.jsonc` → `r2 bucket create fireshield-nbc-index`
→ `npm run index:build && npm run index:upload` → `wrangler deploy`.

## Deploy the app to GitHub Pages
```bash
flutter build web -t lib/fireshield_main.dart --release \
  --base-href /<REPO>/ \
  --dart-define=FIRESHIELD_WORKER_URL=https://fireshield-groq-gateway.<sub>.workers.dev
# publish build/web to the gh-pages branch (or via an Actions workflow)
```
Then set the Worker `ALLOWED_ORIGINS` to `https://<OWNER>.github.io`.

## Verify NBC query fidelity vs the CLI
```bash
# after upload/deploy, compare Worker output to the real graphify CLI:
graphify query "sprinkler requirement for hospital above 45 m"
# vs POST /nbc/query {"question":"sprinkler requirement for hospital above 45 m"}
```

## Notes / limits
- CLIPSeg is a progressive enhancement (WebGPU/memory gated). Qwen is the baseline that
  works on every phone, so mobile is never the weak path.
- App checklist is still NBC 2016 (152 checkpoints); NBCS 2026 is used for the Regulations
  phase + reasoning grounding. Regenerating the checkpoint master to 2026 is future work.
- Image→DXF (CubiCasa5K/ezdxf) is out of scope for this slice.
