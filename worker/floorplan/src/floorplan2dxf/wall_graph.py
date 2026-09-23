"""Wall-to-wall intersection graph: which wall touches which, and where.

Walls already carry stable IDs from floorplan2dxf's tracer (`wall_N`). This
module adds the relationship data that doesn't exist yet: for every pair of
walls, do their segments touch/cross, and at what point — the actual
structural graph a reasoning LLM needs ("wall_7 meets wall_3 at a corner",
not just two independent line segments).

Everything here works in the SAME raw pixel space geometry_source.load()
returns (see that module's docstring for why px, not mm, is canonical).
mm is applied only at output time via grid.GridSpec.annotate_position, using
the plan's own recovered mm_per_px if available.

Touch threshold is derived from the plan's OWN wall thickness distribution
(median thickness), not a fixed px/mm constant — a hairline-drawn plan and a
heavy-lineweight plan both get a sensible snap tolerance this way.
"""
from __future__ import annotations

from dataclasses import dataclass

from .grid import GridSpec, Point, annotate_position, dist_point_to_segment


@dataclass
class WallNode:
    id: str
    start: Point  # px
    end: Point  # px
    thickness_px: float
    wall_type: str
    length_px: float
    floor_id: str


@dataclass
class WallIntersection:
    wall_a: str
    wall_b: str
    point: Point  # px
    kind: str  # "corner" (endpoint-to-endpoint) | "t_junction" | "cross"


def _length(a: Point, b: Point) -> float:
    return ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2) ** 0.5


def _seg_intersect(a1: Point, a2: Point, b1: Point, b2: Point) -> Point | None:
    """Standard 2D segment intersection; returns the point or None if the
    segments (as finite segments, not infinite lines) don't cross."""
    x1, y1 = a1
    x2, y2 = a2
    x3, y3 = b1
    x4, y4 = b2
    denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
    if abs(denom) < 1e-9:
        return None
    t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom
    u = ((x1 - x3) * (y1 - y2) - (y1 - y3) * (x1 - x2)) / denom
    if -0.02 <= t <= 1.02 and -0.02 <= u <= 1.02:  # small tolerance for drawn-not-exact endpoints
        return (x1 + t * (x2 - x1), y1 + t * (y2 - y1))
    return None


def build_wall_nodes(walls, floor_id: str) -> list[WallNode]:
    return [
        WallNode(
            id=w.id, start=w.start, end=w.end, thickness_px=w.thickness_mm,  # raw-space model: mm field holds px
            wall_type=w.wall_type, length_px=_length(w.start, w.end), floor_id=floor_id,
        )
        for w in walls
    ]


def build_intersections(nodes: list[WallNode]) -> list[WallIntersection]:
    """O(n^2) pairwise check — fine at the scale of a single-floor plan's
    wall count (tens, not thousands)."""
    if not nodes:
        return []
    thicknesses = [n.thickness_px for n in nodes]
    median_thickness = sorted(thicknesses)[len(thicknesses) // 2]
    snap_px = max(median_thickness * 1.5, 6.0)  # derived from THIS plan's own wall weight

    results: list[WallIntersection] = []
    seen: set[tuple[str, str]] = set()
    for i, a in enumerate(nodes):
        for b in nodes[i + 1:]:
            key = tuple(sorted((a.id, b.id)))
            if key in seen:
                continue

            # Endpoint-to-endpoint proximity first (the common "corner" case).
            endpoint_pairs = [
                (a.start, b.start), (a.start, b.end),
                (a.end, b.start), (a.end, b.end),
            ]
            best = min(endpoint_pairs, key=lambda p: _length(p[0], p[1]))
            if _length(*best) <= snap_px:
                midpoint = ((best[0][0] + best[1][0]) / 2, (best[0][1] + best[1][1]) / 2)
                results.append(WallIntersection(a.id, b.id, midpoint, "corner"))
                seen.add(key)
                continue

            # Otherwise, does one wall's run cross or T into the other's span?
            point = _seg_intersect(a.start, a.end, b.start, b.end)
            if point is not None:
                on_a_interior = snap_px < _length(a.start, point) < a.length_px - snap_px
                on_b_interior = snap_px < _length(b.start, point) < b.length_px - snap_px
                kind = "cross" if (on_a_interior and on_b_interior) else "t_junction"
                results.append(WallIntersection(a.id, b.id, point, kind))
                seen.add(key)

    return results


def wall_node_to_dict(node: WallNode, grid_spec: GridSpec) -> dict:
    out = {
        "id": node.id,
        "floorId": node.floor_id,
        "wallType": node.wall_type,
        "lengthPx": round(node.length_px, 1),
        "start": annotate_position(grid_spec, node.start),
        "end": annotate_position(grid_spec, node.end),
    }
    if grid_spec.mm_per_px:
        out["thicknessMm"] = round(node.thickness_px * grid_spec.mm_per_px, 1)
        out["lengthMm"] = round(node.length_px * grid_spec.mm_per_px, 1)
    return out


def intersection_to_dict(x: WallIntersection, grid_spec: GridSpec) -> dict:
    return {
        "wallA": x.wall_a,
        "wallB": x.wall_b,
        "kind": x.kind,
        "point": annotate_position(grid_spec, x.point),
    }
