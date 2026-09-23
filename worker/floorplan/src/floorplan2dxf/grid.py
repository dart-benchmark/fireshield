"""Shared coordinate system for every entity in the reconstructed plan.

Two layers, deliberately decoupled:

  1. PIXEL grid — always available. Built straight off the raster, needs no
     OCR/scale recovery to exist. This is what answers "what is where
     relative to what" (adjacency, containment, clustering) even when scale
     calibration fails or an image has no printed dimensions at all.
  2. MM scaling — layered on top ONLY when mm_per_px is known (from OCR-read
     dimension labels). Never required for the pixel grid/topology to work;
     it just re-expresses the same relative structure in real-world units.

Every entity gets both where possible: a stable grid-cell address (works
regardless of scale) plus, when available, a real-world mm position. Grid
cell size defaults to a fraction of the image's own shorter side (~2.5%) —
derived from the image, not a fixed pixel constant, so a 500px sketch and a
4000px scan both get a sane cell size.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable, Optional

Point = tuple[float, float]


@dataclass(frozen=True)
class GridSpec:
    """origin/cell_size are always in PIXELS — the one coordinate space
    guaranteed to exist for any input image. `mm_per_px` is optional and
    purely a scaling annotation applied on top."""
    origin_px: Point
    cell_size_px: float
    mm_per_px: Optional[float] = None

    def to_grid(self, point_px: Point) -> tuple[int, int]:
        x, y = point_px
        ox, oy = self.origin_px
        return (
            int(round((x - ox) / self.cell_size_px)),
            int(round((y - oy) / self.cell_size_px)),
        )

    def to_mm(self, point_px: Point) -> Optional[Point]:
        if self.mm_per_px is None:
            return None
        return (point_px[0] * self.mm_per_px, point_px[1] * self.mm_per_px)

    def mm_to_px(self, point_mm: Point) -> Point:
        """For callers whose geometry already arrived in mm (e.g. walls, after
        the existing pipeline's own apply_scale) and need it back in the
        shared pixel grid. Only valid once mm_per_px is known."""
        if self.mm_per_px is None:
            raise ValueError("mm_per_px not set on this GridSpec")
        return (point_mm[0] / self.mm_per_px, point_mm[1] / self.mm_per_px)

    def cell_size_mm(self) -> Optional[float]:
        return None if self.mm_per_px is None else self.cell_size_px * self.mm_per_px

    def grid_distance(self, cell_a: tuple[int, int], cell_b: tuple[int, int]) -> int:
        """Chebyshev distance in grid cells — the natural "how many cells
        apart" metric for adjacency/clustering decisions."""
        return max(abs(cell_a[0] - cell_b[0]), abs(cell_a[1] - cell_b[1]))


def grid_spec_for_image(image_shape: tuple[int, int], mm_per_px: Optional[float] = None,
                         cell_fraction: float = 0.025) -> GridSpec:
    """image_shape = (height, width) in px, as returned by any raster load.
    Origin is (0, 0) — the image's own top-left — so grid addresses are
    stable across every module without needing to re-derive an origin from
    entity positions."""
    h, w = image_shape[:2]
    cell_size_px = max(4.0, min(h, w) * cell_fraction)
    return GridSpec(origin_px=(0.0, 0.0), cell_size_px=cell_size_px, mm_per_px=mm_per_px)


def annotate_position(spec: GridSpec, point_px: Point) -> dict:
    """The canonical per-entity position payload: pixel grid always present,
    mm fields present only once/if scale is known. Every module should route
    positional output through this so the shape is identical everywhere."""
    gx, gy = spec.to_grid(point_px)
    out = {
        "px": [round(point_px[0], 1), round(point_px[1], 1)],
        "grid": [gx, gy],
    }
    mm = spec.to_mm(point_px)
    if mm is not None:
        out["mm"] = [round(mm[0], 1), round(mm[1], 1)]
        out["gridSizeMm"] = round(spec.cell_size_mm(), 1)
    return out


def grid_spec_for_bounds(points_px: Iterable[Point], cell_size_px: float,
                          mm_per_px: Optional[float] = None) -> GridSpec:
    """Alternative constructor when there's no raster shape handy (e.g. pure
    unit tests) — origin snaps to the given points' own bounding-box corner."""
    pts = list(points_px)
    if not pts:
        return GridSpec(origin_px=(0.0, 0.0), cell_size_px=cell_size_px, mm_per_px=mm_per_px)
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    return GridSpec(origin_px=(min(xs), min(ys)), cell_size_px=cell_size_px, mm_per_px=mm_per_px)


def dist_point_to_segment(p: Point, a: Point, b: Point) -> float:
    """Perpendicular (clamped) distance from point p to segment a-b. Unit-
    agnostic — works for px or mm as long as all three points share a unit."""
    px, py = p
    ax, ay = a
    bx, by = b
    dx, dy = bx - ax, by - ay
    seg_len_sq = dx * dx + dy * dy
    if seg_len_sq < 1e-9:
        return ((px - ax) ** 2 + (py - ay) ** 2) ** 0.5
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / seg_len_sq))
    cx, cy = ax + t * dx, ay + t * dy
    return ((px - cx) ** 2 + (py - cy) ** 2) ** 0.5


# Backwards-compat alias used by earlier drafts of wall_graph/dimension_resolver.
dist_point_to_segment_mm = dist_point_to_segment
