"""Resolve each OCR-read dimension number to the specific wall it measures.

The existing floorplan2dxf OCR classifier only tags text as "dimension" when
it's a W-x-H pair or carries an explicit unit suffix ('/"/ft/m) — this
drawing's labels are bare decimals ("2.00", "9.00") relying on a global
"SCALE 1:100 MTS." title, so every one of them gets misclassified as "other"
by the existing pipeline. This module does its own classification, tuned to
what's actually unambiguous in these drawings:

  - Any token containing a decimal point (\\d+\\.\\d+) is a dimension. That's
    an unambiguous convention on architectural drawings, not a guess.
  - A bare integer ("1", "2") is a dimension ONLY if it is NOT grid-adjacent
    to a room-label word — "BEDROOM" + "1" is one semantic label
    ("Bedroom 1"), not a 1-metre measurement, even though OCR reads them as
    two separate tokens. Adjacency is judged the same grid-cell way every
    other module in this package judges proximity (see text_clustering.py),
    not a separate ad-hoc pixel threshold.

Resolution to a wall is purely positional, entirely in the shared pixel
space (see geometry_source.py for why px, not mm, is canonical here): the
wall with the smallest perpendicular point-to-segment distance to the OCR
text's own position wins. Real-world value/units are attached only for
display, via the plan's own recovered mm_per_px — never used to decide WHICH
wall a number belongs to, only to state what it means once resolved.
"""
from __future__ import annotations

import re
from dataclasses import dataclass

from .grid import GridSpec, Point, annotate_position, dist_point_to_segment
from .wall_graph import WallNode

_DECIMAL = re.compile(r"^\d+\.\d+$")
_BARE_INT = re.compile(r"^\d+$")


@dataclass
class ResolvedDimension:
    text: str
    value: float  # as printed (e.g. 9.00) — unit is the drawing's own (this plan: metres)
    position_px: Point
    wall_id: str | None
    distance_px: float | None  # perpendicular distance to the matched wall; None if unresolved


def _is_label_adjacent(text_item, label_items, grid_spec: GridSpec, max_cells: int = 3) -> bool:
    cell = grid_spec.to_grid(text_item.position)
    for label in label_items:
        if grid_spec.grid_distance(cell, grid_spec.to_grid(label.position)) <= max_cells:
            return True
    return False


def classify_dimension_candidates(ocr_texts, grid_spec: GridSpec) -> list:
    label_items = [t for t in ocr_texts if t.kind == "label"]
    candidates = []
    for t in ocr_texts:
        content = t.content.strip()
        if _DECIMAL.match(content):
            candidates.append(t)
        elif _BARE_INT.match(content) and not _is_label_adjacent(t, label_items, grid_spec):
            candidates.append(t)
    return candidates


def resolve_dimensions(
    ocr_texts, wall_nodes: list[WallNode], grid_spec: GridSpec,
    *, max_distance_px: float | None = None,
) -> list[ResolvedDimension]:
    """`max_distance_px` defaults to a fraction of the plan's own extent
    (derived below from wall lengths), not a fixed constant — a tiny sketch
    and a large commercial plan both get a sensible search radius."""
    candidates = classify_dimension_candidates(ocr_texts, grid_spec)
    if not wall_nodes:
        return [
            ResolvedDimension(c.content, float(c.content), c.position, None, None)
            for c in candidates
        ]

    if max_distance_px is None:
        lengths = sorted(w.length_px for w in wall_nodes)
        median_len = lengths[len(lengths) // 2]
        # Dimension text sits offset from its wall by roughly one extension-line
        # gap — bounded here by half the plan's own median wall length so it
        # can't reach across the whole building on a small plan, nor be too
        # tight on a large one.
        max_distance_px = max(median_len * 0.5, grid_spec.cell_size_px * 5)

    resolved = []
    for c in candidates:
        pos = c.position
        best_wall, best_dist = None, float("inf")
        for wall in wall_nodes:
            d = dist_point_to_segment(pos, wall.start, wall.end)
            if d < best_dist:
                best_wall, best_dist = wall, d
        if best_wall is not None and best_dist <= max_distance_px:
            resolved.append(ResolvedDimension(
                c.content, float(c.content), pos, best_wall.id, round(best_dist, 1),
            ))
        else:
            resolved.append(ResolvedDimension(c.content, float(c.content), pos, None, None))
    return resolved


def resolved_to_dict(r: ResolvedDimension, grid_spec: GridSpec) -> dict:
    out = {
        "text": r.text,
        "value": r.value,
        "position": annotate_position(grid_spec, r.position_px),
        "wallId": r.wall_id,
        "resolved": r.wall_id is not None,
    }
    if r.distance_px is not None:
        out["distancePx"] = r.distance_px
        if grid_spec.mm_per_px:
            out["distanceMm"] = round(r.distance_px * grid_spec.mm_per_px, 1)
    return out
