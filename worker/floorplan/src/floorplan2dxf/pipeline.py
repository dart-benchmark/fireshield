from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Optional

from .calibrate import calibrate_auto, calibrate_from_span, calibrate_from_wall_dimensions, parse_overall
from .commercial_model import build_commercial_model
from .correction import constrain_geometry_to_spec
from .export_dxf import write_dxf
from .geometric_model import build_geometric_model
from .geometry import extract_geometry
from .ingest import load_raster
from .ocr import run_ocr
from .overlay import write_overlay
from .preprocess import preprocess
from .recognize import MissingWeights, Recognition, load_model, recognize, remap_recognition
from .reconstruct import apply_scale, reconstruct
from .openings import detect_openings
from .schema import Door, FloorplanModel, Window
from .topology import derive_topology


@dataclass
class ConvertResult:
    model: FloorplanModel
    dxf_path: Path
    json_path: Optional[Path]
    overlay_path: Optional[Path]
    mm_per_px: Optional[float]
    warnings: list[str]
    commercial_model: dict
    geometric_model: dict = None  # walls/intersections/dimensions/text labels — see geometric_model.py


def convert(
    path: str | Path,
    *,
    out: str | Path | None = None,
    page: int = 0,
    dpi: int = 200,
    weights: str | Path | None = None,
    device: Optional[str] = None,
    tta: bool = False,
    ocr: bool = True,
    mm_per_px: Optional[float] = None,
    overall: Optional[str] = None,
    max_side: int = 1024,
    threshold: float = 0.2,
    overlay: str | Path | bool = True,
    json_out: str | Path | bool = True,
    model=None,
    use_model: bool = True,
    guide: Optional[Callable] = None,
    guide_required: bool = False,
    vision_dimensions: Optional[list[dict]] = None,
    vision_overall_mm: Optional[tuple[float, float]] = None,
) -> ConvertResult:
    warnings: list[str] = []
    src = Path(path)
    raster = load_raster(src, page=page, dpi=dpi)
    prep = preprocess(raster.rgb, max_side=max_side)
    plan_spec = {}
    if guide is not None and hasattr(guide, "specify"):
        try:
            plan_spec = guide.specify(prep.display_rgb)
        except Exception as exc:
            if guide_required:
                raise
            warnings.append(f"Vision-first specification failed ({exc}); using unconstrained extraction.")
    cv_geom = extract_geometry(prep.display_rgb, prep.wall_mask)
    if plan_spec:
        constraint = constrain_geometry_to_spec(
            cv_geom, plan_spec, (prep.display_rgb.shape[1], prep.display_rgb.shape[0]),
            rgb=prep.display_rgb,
        )
        if constraint.get("applied"):
            warnings.append(
                "Vision-first constraints applied: "
                f"{constraint['matchedWalls']}/{constraint['specifiedWalls']} walls and "
                f"{constraint['matchedRooms']}/{constraint['specifiedRooms']} rooms matched to pixels."
            )

    recog = Recognition(
        polygons=None,
        types=[],
        room_polygons=[],
        room_types=[],
        heatmaps=None,
        rooms=None,
        icons=None,
    )
    if use_model:
        try:
            if model is None:
                net, device = load_model(Path(weights) if weights else None, device=device)
            else:
                net = model
                if device is None:
                    device = "cpu"
            recog = recognize(prep, net, device=device, tta=tta, threshold=threshold)
            recog = remap_recognition(recog, prep)
        except MissingWeights as exc:
            warnings.append(str(exc))
        except Exception as exc:
            warnings.append(f"CubiCasa recognition failed ({exc}); using OpenCV walls/rooms.")

    try:
        texts = run_ocr(prep.display_rgb, enabled=ocr)
    except RuntimeError as exc:
        warnings.append(str(exc))
        texts = []

    plan = reconstruct(
        recog.polygons,
        recog.types,
        recog.room_polygons,
        recog.room_types,
        texts,
        image_size=(prep.display_rgb.shape[1], prep.display_rgb.shape[0]),
        cv_geom=cv_geom,
    )

    if guide is not None:
        try:
            plan = guide(prep.display_rgb, plan)
        except Exception as exc:
            if guide_required:
                raise
            warnings.append(f"Vision guidance failed ({exc}); keeping deterministic topology.")

    # Doors/windows read straight off the drawing convention (swing arcs, and
    # hollow boxes inside exterior wall bands). This is the only source of
    # openings when the CubiCasa recogniser is disabled, and unlike a vision
    # read it yields measurable pixel widths. Purely additive: it never runs if
    # the recogniser already produced openings, and never touches walls/rooms.
    if not plan.doors and not plan.windows:
        try:
            for index, opening in enumerate(
                detect_openings(prep.display_rgb, prep.wall_mask, cv_geom.walls_for_openings)
            ):
                if opening.kind == "door":
                    plan.doors.append(Door(
                        id=f"door_{index}", wall_id=opening.wall_id,
                        width_mm=float(opening.width_px), center=opening.center,
                    ))
                else:
                    plan.windows.append(Window(
                        id=f"window_{index}", wall_id=opening.wall_id,
                        width_mm=float(opening.width_px), center=opening.center,
                    ))
        except Exception as exc:  # noqa: BLE001 - openings must never fail a conversion
            warnings.append(f"Opening detection failed ({exc}); walls and rooms are unaffected.")

    if cv_geom.envelope:
        x0, y0, x1, y1 = cv_geom.envelope
        plan.exterior_boundary = [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]
    plan = derive_topology(plan)

    overall_mm = parse_overall(overall) if overall else None
    bar_h = next((b.length_px for b in cv_geom.bars if b.horizontal), None)
    bar_v = next((b.length_px for b in cv_geom.bars if not b.horizontal), None)
    scale = calibrate_auto(
        plan.rooms,
        plan.texts,
        override=mm_per_px,
        overall_mm=overall_mm,
        envelope=cv_geom.envelope,
        bar_h_px=bar_h,
        bar_v_px=bar_v,
    )
    if scale is None and vision_dimensions:
        # EasyOCR is disabled at runtime (Render memory limit); Qwen reads the
        # printed dimension labels instead. Snapping each label to its nearest
        # matching wall segment (below) and never letting Qwen touch wall/room
        # topology keeps geometry deterministic while still recovering scale.
        proximity_px = max(10.0, max(*prep.display_rgb.shape[:2]) * 0.03)
        scale = calibrate_from_wall_dimensions(vision_dimensions, cv_geom.walls, proximity_px=proximity_px)
        if scale is not None:
            warnings.append(
                "Scale recovered from vision-read dimension labels matched to traced walls "
                "(advisory — EasyOCR unavailable at runtime)."
            )
    if scale is None and vision_overall_mm and cv_geom.envelope:
        x0, y0, x1, y1 = cv_geom.envelope
        scale = calibrate_from_span(x1 - x0, y1 - y0, vision_overall_mm)
        if scale is not None:
            warnings.append(
                "Scale recovered from a vision-read overall building dimension "
                "(advisory — EasyOCR unavailable at runtime)."
            )
    if scale is None:
        warnings.append(
            "Could not infer scale from printed dimensions. DXF stays in pixel units. "
            "Pass --overall W,H (any units the drawing uses) or --mm-per-px."
        )

    stem = src.stem if src.stem else "floorplan"
    out_path = Path(out) if out else Path("out") / f"{stem}.dxf"
    overlay_path = None
    if overlay:
        overlay_path = (
            Path(overlay) if isinstance(overlay, (str, Path)) else out_path.with_name(out_path.stem + "_overlay.png")
        )
        write_overlay(prep.display_rgb, plan, overlay_path)

    # Wall IDs + intersection graph + OCR-dimension-to-wall resolution + text
    # labels — an explicit, LLM-ready geometric model (see geometric_model.py
    # for the full history/design notes). MUST run before apply_scale() below:
    # that function converts to mm AND flips the Y axis for DXF/CAD export,
    # which would silently corrupt every distance calculation here if mixed
    # with the raw-pixel wall/OCR coordinates this model is built from.
    # Purely deterministic (no vision call) — safe to always compute.
    geometric_model = build_geometric_model(cv_geom, texts, plan.image_size, scale)

    plan = apply_scale(plan, scale)
    dxf_path = write_dxf(plan, out_path)

    json_path = None
    if json_out:
        json_path = Path(json_out) if isinstance(json_out, (str, Path)) else dxf_path.with_suffix(".json")
        commercial_model = build_commercial_model(
            plan,
            building_profile=getattr(guide, "building_profile", {}),
            plan_spec=plan_spec,
            guidance_audit=vars(guide.audit) if guide is not None and hasattr(guide, "audit") else {},
        )
        json_path.write_text(json.dumps({
            "topology": plan.to_dict(), "commercialModel": commercial_model,
        }, indent=2), encoding="utf-8")
    else:
        commercial_model = build_commercial_model(
            plan,
            building_profile=getattr(guide, "building_profile", {}),
            plan_spec=plan_spec,
            guidance_audit=vars(guide.audit) if guide is not None and hasattr(guide, "audit") else {},
        )

    return ConvertResult(
        model=plan,
        dxf_path=dxf_path,
        json_path=json_path,
        overlay_path=overlay_path,
        mm_per_px=scale,
        warnings=warnings,
        commercial_model=commercial_model,
        geometric_model=geometric_model,
    )
