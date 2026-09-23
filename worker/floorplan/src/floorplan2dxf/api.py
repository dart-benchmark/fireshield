"""HTTP boundary for FireShield plan conversion.

Designed to run behind the authenticated/rate-limited Cloudflare Worker. It has
no browser CORS policy and no embedded provider credentials.
"""

from __future__ import annotations

import base64
import copy
import hashlib
import hmac
import json
import os
import tempfile
import time
from collections import OrderedDict
from pathlib import Path

from fastapi import FastAPI, File, Form, Header, HTTPException, UploadFile

from .geometric_model import attach_openings, attach_subcomponents
from .guidance import (
    QwenTopologyGuide,
    dimension_read_prompt,
    identify_openings_via_mistral,
    identify_subcomponents_via_mistral,
    read_dimensions_via_mistral,
    specify_via_mistral,
)
from .ingest import load_raster
from .pipeline import convert
from .preprocess import preprocess


MAX_UPLOAD_BYTES = 25 * 1024 * 1024
ALLOWED_TYPES = {
    "application/pdf": ".pdf",
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
}

app = FastAPI(title="FireShield Floor Plan Processor", docs_url=None, redoc_url=None)


@app.get("/health")
def health():
    return {
        "ok": True,
        "service": "fireshield-floorplan",
        "qwenConfigured": bool(os.environ.get("GROQ_API_KEY")),
        "visionPasses": 2,
        "reasoningModel": "openai/gpt-oss-120b",
        "ocrBackend": os.environ.get("OCR_BACKEND", "tesseract"),
        "ocrRuntimeEnabled": os.environ.get("ENABLE_OCR_RUNTIME") == "1",
        "requestScopedQwenSupported": True,
        "serviceTokenConfigured": bool(os.environ.get("FLOORPLAN_SERVICE_TOKEN")),
        "cubicCasaEnabled": os.environ.get("ENABLE_NONCOMMERCIAL_CUBICASA") == "1",
    }


@app.post("/convert")
async def convert_plan(
    file: UploadFile = File(...),
    overall: str | None = Form(default=None),
    page: int = Form(default=0),
    require_qwen: bool = Form(default=True),
    building_profile: str = Form(default="{}"),
    service_token: str | None = Header(default=None, alias="X-FireShield-Service-Token"),
    groq_api_key: str | None = Header(default=None, alias="X-FireShield-Groq-Key"),
):
    _require_service_token(service_token)
    mime = (file.content_type or "").lower()
    suffix = ALLOWED_TYPES.get(mime)
    if suffix is None:
        raise HTTPException(415, "Upload a PDF, PNG, JPEG or WebP floor plan.")
    payload = await file.read(MAX_UPLOAD_BYTES + 1)
    if not payload:
        raise HTTPException(400, "The uploaded plan is empty.")
    if len(payload) > MAX_UPLOAD_BYTES:
        raise HTTPException(413, "The floor plan exceeds the 25 MB limit.")
    if page < 0 or page > 100:
        raise HTTPException(400, "PDF page must be between 0 and 100.")
    profile = _building_profile(building_profile)

    try:
        with tempfile.TemporaryDirectory(prefix="fireshield-plan-") as temp:
            work = Path(temp)
            source = work / f"source{suffix}"
            source.write_bytes(payload)
            dxf = work / "plan.dxf"
            # Qwen stream: a separate, parallel advisory read of the same image.
            # Run it first so its dimension-label reads are available as a scale
            # fallback below. It still never touches wall/room topology — only
            # the scalar pixel-to-mm factor, which is applied uniformly after
            # geometry is already fixed.
            vision_advisory = _cached_qwen_advisory(
                payload, source, page, groq_api_key, profile,
            ) if require_qwen else {"status": "disabled"}
            vision_dimensions = vision_advisory.pop("_dimensions", None)
            vision_overall_mm = vision_advisory.pop("_overallMm", None)
            # Geometry stream: always deterministic. OpenCV tracing is the sole
            # geometry authority; no vision model may replace or edit the DXF.
            result = convert(
                source,
                out=dxf,
                page=page,
                overall=overall or None,
                weights=Path("/app/weights/model_best_val_loss_var.pkl"),
                use_model=os.environ.get("ENABLE_NONCOMMERCIAL_CUBICASA") == "1",
                ocr=os.environ.get("ENABLE_OCR_RUNTIME") == "1",
                guide=None,
                guide_required=False,
                vision_dimensions=vision_dimensions,
                vision_overall_mm=vision_overall_mm,
            )
            json_path = result.json_path
            overlay_path = result.overlay_path
            geometric_model = result.geometric_model or {}
            # Subcomponent identification (furniture/fixtures/staircase) is a
            # separate advisory vision call, same reasoning as the Qwen/
            # Mistral space-and-opening advisory above: it must never gate or
            # replace the deterministic geometry, only add to it. Given OCR
            # label hints from the geometric model already built above (per
            # user direction: "taking hint from OCR labels too"), and
            # resolved to the nearest wall(s) afterward.
            if geometric_model:
                subcomponents = _subcomponent_advisory(
                    source, page, geometric_model.get("textLabels", []),
                )
                attach_subcomponents(
                    geometric_model, subcomponents,
                    image_size_px=result.model.image_size, mm_per_px=result.mm_per_px,
                )
                # Vision cross-check for door/window coverage (see
                # guidance.opening_prompt / geometric_model.attach_openings):
                # the deterministic CV detector still owns every real width,
                # this only flags symbols it may have missed or duplicated.
                openings = _opening_advisory(
                    source, page, geometric_model.get("textLabels", []),
                )
                attach_openings(
                    geometric_model, openings,
                    image_size_px=result.model.image_size, mm_per_px=result.mm_per_px,
                    deterministic_doors=[d.to_dict() for d in result.model.doors],
                    deterministic_windows=[w.to_dict() for w in result.model.windows],
                )
            return {
                "buildingProfile": profile,
                "topology": result.model.to_dict(),
                "commercialModel": result.commercial_model,
                "geometricModel": geometric_model,
                "warnings": result.warnings,
                "visionAdvisory": vision_advisory,
                "artifacts": {
                    "plan.dxf": _artifact(dxf, "application/dxf"),
                    "plan.json": _artifact(json_path, "application/json") if json_path else None,
                    "plan_overlay.png": _artifact(overlay_path, "image/png") if overlay_path else None,
                },
                "metrics": {
                    "walls": len(result.model.walls),
                    # "doors"/"windows" stay the deterministic, pixel-measured
                    # count — the only one with real widths. The vision cross-
                    # check (attach_openings) never edits these; the number of
                    # symbols it saw that AREN'T within match distance of one
                    # of these is surfaced separately below so a consumer can
                    # tell "we traced N" from "vision saw more/fewer than N"
                    # without walking geometricModel.openings itself.
                    "doors": len(result.model.doors),
                    "windows": len(result.model.windows),
                    "doorsMissedByGeometry": _unconfirmed_count(geometric_model, "door"),
                    "windowsMissedByGeometry": _unconfirmed_count(geometric_model, "window"),
                    "rooms": len(result.model.rooms),
                    "connections": len(result.model.connections),
                    "objects": len(result.model.objects),
                    "texts": len(result.model.texts),
                    "units": result.model.units,
                    "mmPerPx": result.mm_per_px,
                },
            }
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(422, f"Plan conversion failed: {exc}") from exc


#: Vision reads are billed against a tokens-per-DAY budget that a handful of
#: repeat conversions can exhaust, which disables the advisory stream entirely
#: (no space labels, no openings, no printed-dimension read, so no scale). The
#: same drawing always yields the same read, so re-analysing it should cost
#: nothing. Kept small and short-lived: the service runs under a 512MB limit,
#: and a stale read of an edited drawing would be worse than paying again.
_ADVISORY_TTL_SECONDS = 30 * 60
_ADVISORY_CACHE_MAX = 24
_ADVISORY_CACHE: "OrderedDict[str, tuple[float, dict]]" = OrderedDict()


def _cached_qwen_advisory(
    payload: bytes, source: Path, page: int, api_key: str | None, profile: dict,
) -> dict:
    """Reuse a previous vision read of the identical drawing.

    Keyed by the bytes of the upload, so any edit to the drawing misses the
    cache. Failures are never cached — caching a rate-limit error would keep
    the advisory dead long after the quota recovered.
    """
    key = hashlib.sha256(payload).hexdigest()
    key = f"{key}:{page}"
    now = time.monotonic()
    cached = _ADVISORY_CACHE.get(key)
    if cached is not None:
        stored_at, advisory = cached
        if now - stored_at <= _ADVISORY_TTL_SECONDS:
            _ADVISORY_CACHE.move_to_end(key)
            # Deep-copied because the caller pops private keys off the result.
            return copy.deepcopy(advisory)
        del _ADVISORY_CACHE[key]

    advisory = _qwen_advisory(source, page, api_key, profile)
    if advisory.get("status") in {"usable", "insufficient"}:
        _ADVISORY_CACHE[key] = (now, copy.deepcopy(advisory))
        _ADVISORY_CACHE.move_to_end(key)
        while len(_ADVISORY_CACHE) > _ADVISORY_CACHE_MAX:
            _ADVISORY_CACHE.popitem(last=False)
    return advisory


def _subcomponent_advisory(source: Path, page: int, text_labels: list[dict]) -> list[dict]:
    """Mistral-only (per explicit product direction — no Qwen/Groq fallback
    for this one; if Mistral isn't configured or fails, subcomponents are
    simply empty, never fabricated). Best-effort: any failure returns an
    empty list rather than failing plan conversion, matching how every other
    advisory stream in this file degrades.
    """
    mistral_key = os.environ.get("MISTRAL_API_KEY")
    if not mistral_key:
        return []
    try:
        raster = load_raster(source, page=page)
        prep = preprocess(raster.rgb)
        labels = [t["text"] for t in text_labels if t.get("text")]
        return identify_subcomponents_via_mistral(prep.display_rgb, mistral_key, labels)
    except Exception:  # noqa: BLE001 - advisory stream must not fail the request
        return []


def _unconfirmed_count(geometric_model: dict, kind: str) -> int:
    """How many vision-identified openings of this kind (see attach_openings)
    weren't within match distance of a deterministically-traced one — the
    signal that the CV pass likely missed a real door/window symbol."""
    return sum(
        1 for item in geometric_model.get("openings", [])
        if item.get("kind") == kind and item.get("confirmedByGeometry") is False
    )


def _opening_advisory(source: Path, page: int, text_labels: list[dict]) -> list[dict]:
    """Mistral-only door/window coverage cross-check, same degrade pattern
    as _subcomponent_advisory: any failure or missing key returns an empty
    list rather than failing the request or fabricating openings."""
    mistral_key = os.environ.get("MISTRAL_API_KEY")
    if not mistral_key:
        return []
    try:
        raster = load_raster(source, page=page)
        prep = preprocess(raster.rgb)
        labels = [t["text"] for t in text_labels if t.get("text")]
        return identify_openings_via_mistral(prep.display_rgb, mistral_key, labels)
    except Exception:  # noqa: BLE001 - advisory stream must not fail the request
        return []


def _qwen_advisory(source: Path, page: int, api_key: str | None, profile: dict) -> dict:
    """Vision advisory stream. Advisory only — it never constrains the DXF.

    Returns the model's semantic read of the plan (spaces, openings, visible
    safety features) so GPT-OSS can reason over it *alongside* the deterministic
    geometry. Any failure degrades to an explicit status, never to a fake result.

    Provider order for both the main read and dimensions: Mistral first — a
    completely separate quota pool from Groq/Qwen, so it can never collide
    with whatever the site/photo audit or plan compliance reasoning is doing
    against Groq at the same moment (which is exactly what broke this before:
    two Qwen calls per plan collided with the shared budget and the second
    429'd). Falls back to Qwen only if no MISTRAL_API_KEY is configured or the
    call fails — the Qwen guide is therefore built lazily, only if a fallback
    is actually needed, since building it requires GROQ_API_KEY to be
    configured and that must not gate the Mistral-only path.
    """
    try:
        raster = load_raster(source, page=page)
        prep = preprocess(raster.rgb)
    except Exception as exc:  # noqa: BLE001 - advisory stream must not fail the request
        return {"status": "unavailable", "detail": str(exc)[:300]}

    qwen_guide: QwenTopologyGuide | None = None
    qwen_error: str | None = None

    def qwen_fallback() -> QwenTopologyGuide | None:
        nonlocal qwen_guide, qwen_error
        if qwen_guide is None and qwen_error is None:
            try:
                qwen_guide = QwenTopologyGuide(api_key=api_key, building_profile=profile)
            except RuntimeError as exc:
                qwen_error = str(exc)[:300]
        return qwen_guide

    mistral_key = os.environ.get("MISTRAL_API_KEY")
    spec: dict = {}
    status, confidence, summary = "unavailable", 0.0, ""
    if mistral_key:
        try:
            spec = specify_via_mistral(prep.display_rgb, mistral_key, profile)
            status = str(spec.get("status", "insufficient"))
            status = status if status in {"usable", "insufficient"} else "insufficient"
            confidence = max(0.0, min(float(spec.get("confidence", 0) or 0), 1.0))
            summary = str(spec.get("summary", ""))[:500]
        except Exception:  # noqa: BLE001 - fall through to the Qwen path below
            spec = {}
    if not spec:
        guide = qwen_fallback()
        if guide is None:
            return {"status": "unavailable", "detail": qwen_error or "no vision provider configured"}
        try:
            spec = guide.specify(prep.display_rgb)
            status = guide.audit.specification_status
            confidence = guide.audit.specification_confidence
            summary = guide.audit.specification_summary
        except Exception as exc:  # noqa: BLE001 - advisory stream must not fail the request
            return {"status": "unavailable", "detail": str(exc)[:300]}

    # Second, small, dedicated call: printed dimensions only. Kept separate
    # from specify() because asking one call for spaces/openings/elements AND
    # every printed dimension number competed for one completion budget and
    # lost — dimensions never arrived, and openings quality regressed too.
    # Its own failure must not affect the spaces/openings read above. Tesseract
    # OCR (ocr.py, pipeline.py) remains the PRIMARY scale-recovery path
    # regardless — this is the fallback pipeline.py reaches when OCR found no
    # scale at all.
    dims: dict = {}
    if mistral_key:
        try:
            dims = read_dimensions_via_mistral(
                prep.display_rgb, mistral_key, dimension_read_prompt(prep.display_rgb))
        except Exception:  # noqa: BLE001 - scale recovery is best-effort, never fatal
            dims = {}
    if not dims.get("dimensions") and not (dims.get("overall_width_m") or dims.get("overall_height_m")):
        guide = qwen_fallback()
        if guide is not None:
            try:
                dims = guide.read_dimensions(prep.display_rgb)
            except Exception:  # noqa: BLE001 - scale recovery is best-effort, never fatal
                dims = {}
    spec["dimensions"] = dims.get("dimensions")
    spec["overall_width_m"] = dims.get("overall_width_m")
    spec["overall_height_m"] = dims.get("overall_height_m")
    return {
        "status": status,
        "confidence": confidence,
        "summary": summary,
        "spaces": [
            {
                "label": str(item.get("label", ""))[:80],
                "type": str(item.get("type", ""))[:40],
                "category": str(item.get("category", ""))[:20],
                "center": item.get("center"),
            }
            for item in list(spec.get("spaces") or [])[:80]
            if isinstance(item, dict)
        ],
        "openings": [
            {
                "type": str(item.get("type", ""))[:20],
                "center": item.get("center"),
                # What the opening attaches to — an egress door between a room
                # and OUTSIDE is materially different from an internal door, and
                # counts alone can't express that.
                "connects": [
                    str(name)[:80] for name in list(item.get("connects") or [])[:2]
                ],
                "isExternal": bool(item.get("is_external")),
            }
            for item in list(spec.get("openings") or [])[:80]
            if isinstance(item, dict)
        ],
        "elements": [
            {
                "kind": str(item.get("kind", ""))[:40],
                "category": str(item.get("category", ""))[:20],
                "label": str(item.get("label", ""))[:80],
            }
            for item in list(spec.get("elements") or [])[:80]
            if isinstance(item, dict)
        ],
        # Popped by the caller before this dict reaches the client response —
        # internal handoff for scale calibration only, not part of the advisory
        # contract the app/reasoning model sees.
        "_dimensions": [
            item for item in list(spec.get("dimensions") or [])[:200]
            if isinstance(item, dict)
        ],
        "_overallMm": _overall_mm_from_spec(spec),
    }


def _overall_mm_from_spec(spec: dict) -> tuple[float, float] | None:
    try:
        w = float(spec.get("overall_width_m") or 0) * 1000.0
        h = float(spec.get("overall_height_m") or 0) * 1000.0
    except (TypeError, ValueError):
        return None
    return (w, h) if w > 0 and h > 0 else None


def _artifact(path: Path, mime: str) -> dict:
    data = path.read_bytes()
    return {
        "mimeType": mime,
        "byteSize": len(data),
        "base64": base64.b64encode(data).decode("ascii"),
    }


def _building_profile(raw: str) -> dict:
    if len(raw) > 4000:
        raise HTTPException(400, "Building profile is too large.")
    try:
        value = json.loads(raw or "{}")
    except json.JSONDecodeError as exc:
        raise HTTPException(400, "Building profile must be valid JSON.") from exc
    if not isinstance(value, dict):
        raise HTTPException(400, "Building profile must be a JSON object.")
    allowed = {
        "building", "level", "occupancy", "buildingHeightM", "floorAreaM2",
        "expectedOccupants", "notes",
    }
    return {
        key: (str(item)[:500] if isinstance(item, str) else item)
        for key, item in value.items()
        if key in allowed and isinstance(item, (str, int, float, bool))
    }


def _require_service_token(received: str | None) -> None:
    expected = os.environ.get("FLOORPLAN_SERVICE_TOKEN", "")
    if not expected:
        raise HTTPException(503, "Floor-plan service authentication is not configured.")
    if not received or not hmac.compare_digest(received, expected):
        raise HTTPException(401, "Invalid floor-plan service credentials.")
