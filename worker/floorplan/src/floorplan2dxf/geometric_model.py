"""Builds the explicit, grid-grounded geometric model of a floor plan: wall
IDs + intersection graph, dimension-to-wall resolution, and cleaned/merged
text labels — meant as an LLM-ready set of facts/constraints for the
compliance reasoning step, not a loose blob.

Ported from symbol_lab (a standalone research activity that iterated this
design against a real plan, including two real bugs caught and fixed live:
mixing mm+Y-flipped wall coordinates with raw-pixel OCR positions silently
corrupts every distance calculation, and a "same row" text-clustering check
based on image-size-derived grid cells instead of the OCR tokens' own text
height let two different lines merge incorrectly). See symbol_lab/README.md
for the full history. Geometric symbol matching (candidate regions vs a PDF
symbol library) was tried there and DROPPED — too many confident-but-wrong
matches, and it missed the plan's actual staircase entirely. Subcomponent
identification here comes from Mistral vision instead (see guidance.py's
identify_subcomponents_via_mistral).

Runs entirely in the SAME raw pixel space (Y-down) that extract_geometry()
and run_ocr() already produce — this must run BEFORE pipeline.convert()
calls apply_scale() (which converts to mm AND flips Y for DXF export), or
the coordinate-space bug above reproduces here too.
"""
from __future__ import annotations

from . import dimension_resolver, text_clustering, wall_graph
from .geometry import CvGeometry
from .grid import annotate_position, grid_spec_for_image
from .schema import TextItem


def build_geometric_model(
    cv_geom: CvGeometry, texts: list[TextItem], image_size: tuple[int, int],
    mm_per_px: float | None, *, floor_id: str = "ground",
) -> dict:
    """image_size is (w, h) as stored on FloorplanModel; grid_spec_for_image
    wants (h, w), so it's flipped here at the one call site rather than
    changing that convention elsewhere."""
    w, h = image_size
    grid_spec = grid_spec_for_image((h, w), mm_per_px=mm_per_px)

    wall_nodes = wall_graph.build_wall_nodes(cv_geom.walls, floor_id)
    intersections = wall_graph.build_intersections(wall_nodes)

    clean_texts = text_clustering_input(texts)
    clusters = text_clustering.cluster_text_items(clean_texts, grid_spec)
    resolved_dims = dimension_resolver.resolve_dimensions(clean_texts, wall_nodes, grid_spec)

    return {
        "floorId": floor_id,
        "gridCellSizePx": round(grid_spec.cell_size_px, 2),
        "gridCellSizeMm": round(grid_spec.cell_size_mm(), 1) if grid_spec.mm_per_px else None,
        "walls": [wall_graph.wall_node_to_dict(n, grid_spec) for n in wall_nodes],
        "wallIntersections": [wall_graph.intersection_to_dict(x, grid_spec) for x in intersections],
        "textLabels": [text_clustering.cluster_to_dict(c, grid_spec) for c in clusters if c.kind == "label"],
        "dimensions": [dimension_resolver.resolved_to_dict(r, grid_spec) for r in resolved_dims],
    }


def text_clustering_input(texts: list[TextItem]) -> list[TextItem]:
    from .text_cleaning import clean_ocr_texts
    return clean_ocr_texts(texts)


def attach_subcomponents(model: dict, subcomponents: list[dict],
                          image_size_px: tuple[int, int], mm_per_px: float | None) -> None:
    """Resolves each Mistral-identified subcomponent's approximate position
    (a 0.0-1.0 fraction of the image, since asking a vision model for exact
    pixel coordinates is unreliable — fractional/quadrant positioning is
    what it can actually estimate) to pixel space, then to the nearest
    wall(s) using the SAME proximity approach dimension resolution already
    uses — no separate ad-hoc logic. Adds a "subcomponents" key to an
    already-built model dict, in place.

    Works directly off `model["walls"]` (the already-serialized dict form —
    {id, start: {px: [x,y]}, end: {px: [x,y]}, thicknessMm}) rather than
    requiring internal WallNode objects, so this can be called from api.py
    (a separate advisory step, after pipeline.convert() has already returned
    and serialized everything) without re-exposing pipeline internals across
    that boundary. image_size_px is (w, h)."""
    from .grid import dist_point_to_segment, grid_spec_for_image

    img_w, img_h = image_size_px
    grid_spec = grid_spec_for_image((img_h, img_w), mm_per_px=mm_per_px)
    walls = model.get("walls", [])
    thicknesses = [w.get("thicknessMm", 4.0) for w in walls] or [4.0]
    median_thickness_mm = sorted(thicknesses)[len(thicknesses) // 2]
    snap_px = max((median_thickness_mm / mm_per_px if mm_per_px else median_thickness_mm) * 4, 20.0)

    resolved = []
    for item in subcomponents:
        frac = item.get("positionFraction")
        entry = {
            "type": item.get("type"),
            "label": item.get("label"),
            "sourceHint": item.get("sourceHint"),
            "confidence": item.get("confidence"),
        }
        if frac and len(frac) == 2:
            pos_px = (float(frac[0]) * img_w, float(frac[1]) * img_h)
            entry["position"] = annotate_position(grid_spec, pos_px)
            entry["adjacentWallIds"] = [
                w["id"] for w in walls
                if dist_point_to_segment(pos_px, tuple(w["start"]["px"]), tuple(w["end"]["px"])) <= snap_px
            ]
        resolved.append(entry)
    model["subcomponents"] = resolved


def attach_openings(
    model: dict, mistral_openings: list[dict], image_size_px: tuple[int, int],
    mm_per_px: float | None, deterministic_doors: list[dict], deterministic_windows: list[dict],
) -> None:
    """Cross-checks Mistral's vision read of door/window symbols against the
    deterministic CV opening detector's own output (openings.py), and adds
    an "openings" key to an already-built model dict — never edits
    `deterministic_doors`/`deterministic_windows` themselves, since those
    still carry the only real, pixel-measured widths this system has.

    Each vision-identified opening is flagged `confirmedByGeometry: bool` —
    within a generous match radius (4% of the image's own longer side, since
    a vision model's positionFraction is a rough estimate, not a precise
    pixel read) of a deterministically-traced opening of the SAME kind. A
    `false` here is the signal worth acting on: it means the drawing visibly
    has a door/window symbol the deterministic pass missed (a fragmented
    wall network confused its perimeter search, or the drawing's line
    weights didn't give it a thickness signal to work with — both real,
    confirmed failure modes on real plans this session, not hypothetical).
    The compliance reasoning step is instructed to treat those as evidence
    of at least one more opening than the traced count, not to invent a
    width for it (see PLAN_REASON_SYSTEM in worker.js).

    `deterministic_doors`/`deterministic_windows` are `Door.to_dict()`/
    `Window.to_dict()` from `result.model` AFTER `pipeline.convert()` has
    already run `apply_scale()` — which converts every coordinate to mm AND
    flips Y for CAD/DXF export (image Y-down -> CAD Y-up). Vision positions
    here are still raw pixel space (image Y-down), the same convention
    `build_geometric_model()` itself requires running BEFORE apply_scale for
    (see that module's docstring) — mixing the two silently makes every
    distance wrong, live-confirmed here: with centers left in mm, EVERY
    comparison came out "far" regardless of drawing, since px and mm are
    different units entirely. Undoing apply_scale's transform (only when
    mm_per_px was actually applied — `model.units == "px"` otherwise, a
    no-op) restores a fair comparison without touching the real, exported
    geometry.
    """
    from .grid import dist_point_to_segment, grid_spec_for_image
    import math

    img_w, img_h = image_size_px
    grid_spec = grid_spec_for_image((img_h, img_w), mm_per_px=mm_per_px)
    walls = model.get("walls", [])
    match_px = max(img_w, img_h) * 0.04

    def undo_scale(center: list) -> tuple[float, float]:
        x, y = float(center[0]), float(center[1])
        if not mm_per_px:
            return x, y
        return x / mm_per_px, img_h - y / mm_per_px

    det_centers: dict[str, list[tuple[float, float]]] = {"door": [], "window": []}
    for door in deterministic_doors:
        center = door.get("center")
        if center:
            det_centers["door"].append(undo_scale(center))
    for window in deterministic_windows:
        center = window.get("center")
        if center:
            det_centers["window"].append(undo_scale(center))

    resolved = []
    for item in mistral_openings:
        kind = item.get("kind")
        frac = item.get("positionFraction")
        entry = {"kind": kind, "confidence": item.get("confidence")}
        if frac and len(frac) == 2 and kind in det_centers:
            pos_px = (float(frac[0]) * img_w, float(frac[1]) * img_h)
            entry["position"] = annotate_position(grid_spec, pos_px)
            nearest_wall, nearest_dist = None, None
            for wall in walls:
                dist = dist_point_to_segment(pos_px, tuple(wall["start"]["px"]), tuple(wall["end"]["px"]))
                if nearest_dist is None or dist < nearest_dist:
                    nearest_wall, nearest_dist = wall["id"], dist
            entry["nearestWallId"] = nearest_wall
            entry["confirmedByGeometry"] = any(
                math.hypot(pos_px[0] - cx, pos_px[1] - cy) <= match_px
                for cx, cy in det_centers[kind]
            )
        resolved.append(entry)
    model["openings"] = resolved
