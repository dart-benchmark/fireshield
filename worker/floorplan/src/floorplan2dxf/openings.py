"""Deterministic door/window detection from architectural drawing convention.

Standard plan symbols, which this encodes directly:

* A **door** is a quarter-circle swing arc plus a straight leaf. The arc bulges
  *perpendicular, away from* the wall into the room it opens onto.
* A **window** is a thin box drawn *inside* the wall band — parallel thin lines
  collinear with the wall, never bulging out of it. A wide window is drawn as
  several collinear blocks, so adjacent blocks on the same wall are merged into
  one opening.

That perpendicular-bulge-vs-collinear distinction is what separates the two, and
it is a property of the convention rather than of any particular drawing: every
threshold here is a ratio of the image's own dimensions or of the local wall
thickness, so nothing is tuned to a specific plan.

Unlike a vision model's read, the widths produced here are real pixel geometry,
so once a scale is recovered they become actual clear-width figures that can be
checked against a regulation.
"""

from __future__ import annotations

import math
from dataclasses import dataclass

import cv2
import numpy as np

from .schema import Point, Wall


@dataclass
class Opening:
    kind: str  # "door" | "window"
    center: Point
    width_px: float
    wall_id: str | None
    horizontal: bool
    confidence: float
    # How many drawn sub-blocks the opening spans. A wide window is drawn as
    # several units separated by mullions; they are one opening with one clear
    # width, but the unit count is kept because it is visible in the drawing.
    block_count: int = 1


def detect_openings(
    rgb: np.ndarray,
    wall_mask: np.ndarray,
    walls: list[Wall],
) -> list[Opening]:
    if rgb is None or rgb.size == 0 or not walls:
        return []
    height, width = rgb.shape[:2]
    scale = min(height, width)
    # Reference sizes derived from the drawing itself, not from any one plan.
    door_span = max(12.0, scale * 0.045)      # a single-leaf door is ~4.5% of the short side
    stroke = max(2, int(round(scale * 0.004)))  # nominal thin-line stroke

    gray = cv2.cvtColor(rgb, cv2.COLOR_RGB2GRAY) if rgb.ndim == 3 else rgb
    ink = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU)[1]
    thin = _thin_ink(rgb, stroke)
    if thin is None or not thin.any():
        return []

    # A wall shorter than a door span cannot host an opening of its own — it
    # is a partition stub, a closet return, or a short connector between two
    # real runs. Dropping those here (not from the traced wall list itself,
    # which real geometry/DXF export still needs in full) keeps
    # perimeter_lines()'s grouping and _nearest_wall()'s arc-to-wall matching
    # working with the same kind of "real wall runs only" candidate set this
    # detection was built and tuned against. On a plan with a lot of small
    # real partition fragments (a densely-divided building whose exterior
    # wall itself also fragments into many short runs around each window),
    # letting all of them compete as separate perimeter/opening candidates
    # measurably hurt door/window accuracy even though every fragment was
    # legitimate architecture — this is a red flag for opening detection
    # specifically, not for whether the ink is real.
    significant = [wall for wall in walls if _wall_length(wall) >= door_span] or walls

    # Windows: hollow runs in exterior wall bands. Doors: swing arcs, which are
    # mostly on interior walls, so the two searches do not compete.
    windows = _detect_windows(ink, significant, door_span)
    doors = _detect_doors(thin, significant, door_span, windows)
    return _dedupe(doors + windows, min_separation=door_span * 0.5)


def _thin_ink(rgb: np.ndarray, stroke: int) -> np.ndarray:
    """Ink with the solid wall bands removed, leaving door leaves/arcs and window boxes."""
    gray = cv2.cvtColor(rgb, cv2.COLOR_RGB2GRAY) if rgb.ndim == 3 else rgb
    ink = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU)[1]
    # A wall band survives an opening with a kernel wider than a thin stroke;
    # arcs, leaves and window boxes do not.
    band = max(3, stroke * 3)
    solid = cv2.morphologyEx(ink, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_RECT, (band, band)))
    return cv2.subtract(ink, solid)


def _wall_axis(wall: Wall) -> tuple[bool, float, float, float]:
    """Return (horizontal, fixed-axis coordinate, span start, span end)."""
    (x1, y1), (x2, y2) = wall.start, wall.end
    if abs(x2 - x1) >= abs(y2 - y1):
        return True, (y1 + y2) / 2.0, min(x1, x2), max(x1, x2)
    return False, (x1 + x2) / 2.0, min(y1, y2), max(y1, y2)


def _wall_thickness(wall: Wall) -> float:
    """Drawn wall thickness in pixels (walls_from_mask stores it in this unit)."""
    return max(2.0, float(getattr(wall, "thickness_mm", 0.0) or 0.0))


def _wall_length(wall: Wall) -> float:
    (x1, y1), (x2, y2) = wall.start, wall.end
    return math.hypot(x2 - x1, y2 - y1)


def _nearest_wall(
    cx: float, cy: float, walls: list[Wall], slack: float,
) -> tuple[Wall | None, bool, float]:
    """Nearest wall whose own band contains this point.

    The acceptance distance is derived per wall from its drawn thickness rather
    than one global constant: an opening is drawn inside the wall it belongs to,
    so a thick exterior wall legitimately admits a box further from its
    centreline than a thin partition does.
    """
    best: tuple[Wall | None, bool, float] = (None, True, float("inf"))
    for wall in walls:
        horizontal, fixed, lo, hi = _wall_axis(wall)
        along, across = (cx, cy) if horizontal else (cy, cx)
        tolerance = _wall_thickness(wall) * 0.75 + slack
        if along < lo - tolerance or along > hi + tolerance:
            continue
        distance = abs(across - fixed)
        if distance <= tolerance and distance < best[2]:
            best = (wall, horizontal, distance)
    return best


@dataclass
class PerimeterLine:
    """One complete side of the building, rebuilt from collinear wall fragments."""
    wall_id: str
    horizontal: bool
    fixed: float
    lo: float
    hi: float
    thickness: float


def perimeter_lines(walls: list[Wall], tolerance: float) -> list[PerimeterLine]:
    """The building's four outer sides, as continuous lines.

    Windows are only ever drawn on exterior walls, so restricting the search to
    the perimeter removes furniture, stairs and dimension text in one step
    rather than filtering each out by shape.

    The wall trace returns fragments, not whole sides (a single exterior run is
    broken into many short segments), so collinear fragments are first grouped
    into one line per side. The outermost group on each axis is the exterior
    wall; groups further in are interior partitions, and dimension lines sit
    outside the building but carry almost no total span, so ranking by span
    picks the real wall.
    """
    if not walls:
        return []
    groups: dict[tuple[bool, int], list[Wall]] = {}
    for wall in walls:
        horizontal, fixed, lo, hi = _wall_axis(wall)
        key = (horizontal, int(round(fixed / max(1.0, tolerance))))
        groups.setdefault(key, []).append(wall)

    lines: list[PerimeterLine] = []
    for (horizontal, _), members in groups.items():
        axes = [_wall_axis(wall) for wall in members]
        fixed = float(np.mean([axis[1] for axis in axes]))
        lo = min(axis[2] for axis in axes)
        hi = max(axis[3] for axis in axes)
        covered = sum(axis[3] - axis[2] for axis in axes)
        lines.append(PerimeterLine(
            wall_id=members[0].id, horizontal=horizontal, fixed=fixed, lo=lo, hi=hi,
            thickness=float(np.mean([_wall_thickness(wall) for wall in members])),
        ))
        lines[-1].__dict__["_covered"] = covered

    return lines


def _select_perimeter(
    lines: list[PerimeterLine], ink: np.ndarray, tolerance: float,
) -> list[PerimeterLine]:
    """Keep the outermost line per side that is actually a wall.

    Dimension lines sit further out than the building itself, so "outermost"
    alone picks them. A wall is distinguished by being densely inked across its
    band, which a dimension line — a single hairline — is not.
    """
    # Separate walls from dimension lines by measured thickness, then simply
    # take the outermost wall on each side. No ranking by length or position is
    # needed once dimension lines are excluded, which is what previously let a
    # long interior wall win and an exterior wall be missed.
    probe = max(4, int(round(tolerance)))
    measured: list[tuple[PerimeterLine, float]] = []
    for line in lines:
        if float(line.__dict__.get("_covered", 0.0)) < tolerance * 2:
            continue
        thickness = measured_thickness(line, ink, probe)
        if thickness > 0:
            measured.append((line, thickness))
    if not measured:
        return []
    # The thinnest line on the drawing IS the pen width, because dimension
    # lines are drawn at it. Walls are bands several times that. Comparing
    # against the pen width rather than the thickest wall keeps thin exterior
    # walls, which a max-relative threshold would discard alongside the
    # dimension lines.
    pen = min(thickness for _, thickness in measured)
    walls_only = [line for line, thickness in measured if thickness >= max(3.0, pen * 2.0)]
    chosen: list[PerimeterLine] = []
    for horizontal in (True, False):
        side = sorted(
            (line for line in walls_only if line.horizontal == horizontal),
            key=lambda line: line.fixed,
        )
        if not side:
            continue
        chosen.append(side[0])
        if side[-1] is not side[0]:
            chosen.append(side[-1])
    return chosen


def measured_thickness(line: PerimeterLine, ink: np.ndarray, probe: int) -> float:
    """Median drawn thickness of a line, measured perpendicular to it.

    This is what separates a wall from a dimension line. Walls are drawn as a
    band several pixels thick and hold that thickness along their length;
    dimension lines are hairlines, thickening only momentarily at their
    arrowheads, so their median stays near the pen width. Taking the median
    ignores those arrowheads and any tick marks.
    """
    height, width = ink.shape[:2]
    fixed = int(round(line.fixed))
    lo, hi = int(max(0, line.lo)), int(min((width if line.horizontal else height), line.hi))
    if hi - lo < 2:
        return 0.0
    samples: list[int] = []
    step = max(1, (hi - lo) // 40)
    for position in range(lo, hi, step):
        a = max(0, fixed - probe)
        b = min((height if line.horizontal else width), fixed + probe + 1)
        strip = ink[a:b, position] if line.horizontal else ink[position, a:b]
        if strip.size == 0:
            continue
        centre = min(len(strip) - 1, max(0, fixed - a))
        if strip[centre] == 0:
            continue  # a gap (an opening) — not evidence of thinness
        run = 1
        for direction in (-1, 1):
            index = centre + direction
            while 0 <= index < len(strip) and strip[index] > 0:
                run += 1
                index += direction
        samples.append(run)
    if not samples:
        return 0.0
    return float(np.median(samples))


def _line_density(line: PerimeterLine, ink: np.ndarray) -> float:
    height, width = ink.shape[:2]
    half = max(2, int(round(line.thickness * 0.5)))
    fixed = int(round(line.fixed))
    lo, hi = int(max(0, line.lo)), int(min(width if line.horizontal else height, line.hi))
    if hi - lo < 2:
        return 0.0
    a = max(0, fixed - half)
    b = min((height if line.horizontal else width), fixed + half + 1)
    if b - a < 1:
        return 0.0
    band = ink[a:b, lo:hi] if line.horizontal else ink[lo:hi, a:b]
    return float(band.mean()) if band.size else 0.0


def _detect_windows(ink: np.ndarray, walls: list[Wall], door_span: float) -> list[Opening]:
    """Windows are hollow runs inside an exterior wall band.

    A solid wall band is dense ink; a window interrupts it with an outlined box
    whose interior is empty, so ink density along the wall drops sharply. Each
    wall is compared against its OWN median density, so this adapts to line
    weight and drawing scale rather than assuming an absolute darkness.
    """
    height, width = ink.shape[:2]
    openings: list[Opening] = []
    tolerance = max(6.0, door_span * 0.5)
    for line in _select_perimeter(perimeter_lines(walls, tolerance), ink, tolerance):
        horizontal, fixed, lo, hi = line.horizontal, line.fixed, line.lo, line.hi
        span = int(hi - lo)
        if span < max(8, int(door_span * 0.5)):
            continue
        # Size the sampling band from the thickness actually measured off the
        # drawing, not the value carried on the wall record — the latter comes
        # from fragmented trace segments and understates a solid exterior wall,
        # which makes the band too narrow to see the hollow window interior.
        probe = max(4, int(round(max(6.0, door_span * 0.5))))
        drawn = measured_thickness(line, ink, probe)
        half = max(3, int(round(max(drawn, line.thickness) * 0.6)))
        fixed_i = int(round(fixed))
        a, b = max(0, fixed_i - half), min((height if horizontal else width), fixed_i + half + 1)
        if b - a < 2:
            continue
        profile = _density_profile(ink, horizontal, int(lo), span, a, b)
        if profile.size < 4:
            continue
        solid = float(np.median(profile))
        if solid <= 1e-6:
            continue
        hollow = profile < solid * 0.62
        runs = _runs(hollow, min_length=max(3, int(door_span * 0.25)))
        # A wide window is drawn as several units separated by mullions, which
        # show up as short dense spikes. Those are one opening with one clear
        # width, so adjacent runs are merged and the unit count recorded.
        for start, end, blocks in _merge_units(runs, mullion=max(3, int(door_span * 0.55))):
            centre_along = lo + (start + end) / 2.0
            centre = (centre_along, fixed) if horizontal else (fixed, centre_along)
            openings.append(Opening(
                kind="window",
                center=(float(centre[0]), float(centre[1])),
                width_px=float(end - start),
                wall_id=line.wall_id,
                horizontal=horizontal,
                confidence=0.75 if blocks > 1 else 0.65,
                block_count=blocks,
            ))
    return openings


def _merge_units(runs: list[tuple[int, int]], mullion: int) -> list[tuple[int, int, int]]:
    """Join runs separated by no more than a mullion into one opening."""
    if not runs:
        return []
    merged: list[tuple[int, int, int]] = []
    start, end, blocks = runs[0][0], runs[0][1], 1
    for run_start, run_end in runs[1:]:
        if run_start - end <= mullion:
            end, blocks = run_end, blocks + 1
        else:
            merged.append((start, end, blocks))
            start, end, blocks = run_start, run_end, 1
    merged.append((start, end, blocks))
    return merged


def _density_profile(
    ink: np.ndarray, horizontal: bool, origin: int, span: int, a: int, b: int,
) -> np.ndarray:
    """Mean ink across the wall band at each step along the wall."""
    values: list[float] = []
    limit = ink.shape[1] if horizontal else ink.shape[0]
    for step in range(span):
        position = origin + step
        if position < 0 or position >= limit:
            values.append(0.0)
            continue
        strip = ink[a:b, position] if horizontal else ink[position, a:b]
        values.append(float(strip.mean()))
    return np.array(values, dtype=float)


def _runs(flags: np.ndarray, min_length: int) -> list[tuple[int, int]]:
    runs: list[tuple[int, int]] = []
    start: int | None = None
    for index, flag in enumerate(flags):
        if flag and start is None:
            start = index
        elif not flag and start is not None:
            if index - start >= min_length:
                runs.append((start, index))
            start = None
    if start is not None and len(flags) - start >= min_length:
        runs.append((start, len(flags)))
    return runs


def _count_blocks(segment: np.ndarray, solid: float) -> int:
    """Sub-units within one window, separated by drawn mullions.

    A mullion is a short density spike inside an otherwise hollow run, so the
    deeply-hollow stretches either side of it are the individual units.
    """
    if segment.size == 0:
        return 1
    deep = segment < solid * 0.45
    return max(1, len(_runs(deep, min_length=2)))


def _merge_collinear(
    blocks: list[tuple[Wall, bool, float, float, float]], gap: float,
) -> list[Opening]:
    """Merge adjacent blocks on the same wall — a wide window is drawn as several."""
    grouped: dict[str, list[tuple[Wall, bool, float, float, float]]] = {}
    for block in blocks:
        grouped.setdefault(block[0].id, []).append(block)

    openings: list[Opening] = []
    for items in grouped.values():
        items.sort(key=lambda item: item[2])
        run = [items[0]]
        for block in items[1:]:
            previous = run[-1]
            previous_end = previous[2] + previous[4] / 2.0
            block_start = block[2] - block[4] / 2.0
            if block_start - previous_end <= gap:
                run.append(block)
            else:
                openings.append(_opening_from_run(run))
                run = [block]
        openings.append(_opening_from_run(run))
    return openings


def _opening_from_run(run: list[tuple[Wall, bool, float, float, float]]) -> Opening:
    wall, horizontal = run[0][0], run[0][1]
    start = min(block[2] - block[4] / 2.0 for block in run)
    end = max(block[2] + block[4] / 2.0 for block in run)
    across = float(np.mean([block[3] for block in run]))
    along = (start + end) / 2.0
    center = (along, across) if horizontal else (across, along)
    return Opening(
        kind="window",
        center=(float(center[0]), float(center[1])),
        width_px=float(end - start),
        wall_id=wall.id,
        horizontal=horizontal,
        # Several merged blocks is the drawn convention for a wide window, so a
        # merged run is stronger evidence than a lone block.
        confidence=0.75 if len(run) > 1 else 0.6,
    )


def _detect_doors(
    thin: np.ndarray, walls: list[Wall], door_span: float, windows: list[Opening],
) -> list[Opening]:
    """Swing arcs: circular, and bulging perpendicular away from their wall."""
    contours, _ = cv2.findContours(thin, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
    openings: list[Opening] = []
    for contour in contours:
        if len(contour) < 8:
            continue
        points = contour.reshape(-1, 2).astype(float)
        span = float(max(np.ptp(points[:, 0]), np.ptp(points[:, 1])))
        # A swing arc is about as big as the door it belongs to.
        if not (door_span * 0.45 <= span <= door_span * 2.6):
            continue
        fit = _fit_circle(points)
        if fit is None:
            continue
        cx, cy, radius, residual = fit
        if residual > 0.16 or not (door_span * 0.35 <= radius <= door_span * 2.0):
            continue
        # Furniture (round tables, chairs) fits a circle at least as well as a
        # swing arc does — what separates them is that furniture closes on
        # itself while a swing is a partial sweep.
        if _angular_coverage(points, cx, cy) > 300.0:
            continue
        # The hinge sits on its wall, within that wall's own drawn thickness —
        # not merely somewhere near it, which is what let interior furniture in.
        wall, horizontal, distance = _nearest_wall(cx, cy, walls, slack=door_span * 0.15)
        if wall is None:
            continue
        if not _bulges_off_wall(points, cx, cy, horizontal, radius):
            continue
        openings.append(Opening(
            kind="door",
            center=(float(cx), float(cy)),
            width_px=float(radius),  # swing radius == leaf length == clear width
            wall_id=wall.id,
            horizontal=horizontal,
            confidence=float(max(0.35, min(0.9, 1.0 - residual * 3.0))),
        ))
    # A window box can weakly imitate an arc; the window classification wins.
    return [
        door for door in openings
        if not any(_close(door.center, window.center, door_span * 0.6) for window in windows)
    ]


def _bulges_off_wall(
    points: np.ndarray, cx: float, cy: float, horizontal: bool, radius: float,
) -> bool:
    """A door arc extends perpendicular to its wall; a window box never does."""
    across = points[:, 1] - cy if horizontal else points[:, 0] - cx
    along = points[:, 0] - cx if horizontal else points[:, 1] - cy
    perpendicular = float(np.abs(across).max())
    parallel = float(np.abs(along).max())
    # Must reach well off the wall line, and not be a sliver lying along it.
    return perpendicular >= radius * 0.45 and perpendicular >= parallel * 0.35


def _angular_coverage(points: np.ndarray, cx: float, cy: float) -> float:
    """Degrees of the circle actually occupied, ignoring the largest empty gap.

    A door swing is a partial sweep (a quarter turn, drawn out-and-back so it
    reads as roughly half the circle); a round table or chair closes on itself
    and covers essentially all of it. This is what keeps furniture out.
    """
    angles = np.sort(np.arctan2(points[:, 1] - cy, points[:, 0] - cx))
    if len(angles) < 3:
        return 360.0
    gaps = np.diff(np.r_[angles, angles[0] + 2 * math.pi])
    return float(math.degrees(2 * math.pi - gaps.max()))


def _fit_circle(points: np.ndarray) -> tuple[float, float, float, float] | None:
    """Algebraic circle fit; returns (cx, cy, radius, normalised residual)."""
    x, y = points[:, 0], points[:, 1]
    try:
        solution, *_ = np.linalg.lstsq(
            np.c_[2 * x, 2 * y, np.ones(len(points))], x ** 2 + y ** 2, rcond=None,
        )
    except np.linalg.LinAlgError:
        return None
    cx, cy = float(solution[0]), float(solution[1])
    radii = np.hypot(x - cx, y - cy)
    mean = float(radii.mean())
    if mean < 1e-6:
        return None
    return cx, cy, mean, float(radii.std() / mean)


def _close(a: Point, b: Point, tolerance: float) -> bool:
    return math.hypot(a[0] - b[0], a[1] - b[1]) <= tolerance


def _dedupe(openings: list[Opening], min_separation: float) -> list[Opening]:
    kept: list[Opening] = []
    for opening in sorted(openings, key=lambda item: -item.confidence):
        if any(item.kind == opening.kind and _close(item.center, opening.center, min_separation)
               for item in kept):
            continue
        kept.append(opening)
    return kept[:120]
