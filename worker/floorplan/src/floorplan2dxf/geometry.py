"""OpenCV topology: complete wall faces, interior rooms, envelope, dimension bars."""

from __future__ import annotations

from dataclasses import dataclass, field

import cv2
import numpy as np

from .schema import Point, Room, VectorTrace, Wall


@dataclass
class DimensionBar:
    start: Point
    end: Point
    length_px: float
    horizontal: bool


@dataclass
class CvGeometry:
    walls: list[Wall] = field(default_factory=list)
    rooms: list[Room] = field(default_factory=list)
    envelope: tuple[float, float, float, float] | None = None  # x0,y0,x1,y1
    bars: list[DimensionBar] = field(default_factory=list)
    traces: list[VectorTrace] = field(default_factory=list)
    wall_mask: np.ndarray | None = None
    # Opening detection (openings.py) was built and validated against a
    # coarse, dominant-mass-only wall trace — a handful of long runs per
    # side. `walls` above is deliberately more complete (keeps every real
    # fragment so a wall broken by a window gap or a corner isn't dropped,
    # see largest_structure()/clip_to_outer()), but feeding that fuller list
    # to openings.py measurably hurt its accuracy: more candidate wall
    # fragments means more competing "lines" for perimeter selection and
    # more nearby-wall matches for arc detection, even though every extra
    # fragment is real architecture. Keeping a separate, deliberately
    # conservative wall list for openings.py specifically restores the
    # input shape it was tuned against without discarding the completeness
    # fix for everything else (DXF export, envelope, room sealing).
    walls_for_openings: list[Wall] = field(default_factory=list)


def extract_geometry(rgb: np.ndarray, wall_mask: np.ndarray) -> CvGeometry:
    raw = wall_mask if wall_mask is not None else np.zeros(rgb.shape[:2], np.uint8)
    h, w = raw.shape[:2]
    dash = max(9, int(round(min(h, w) * 0.022)))
    door = max(17, int(round(min(h, w) * 0.045)))
    linked = cv2.morphologyEx(raw, cv2.MORPH_CLOSE, _kernel(dash), iterations=1)
    ink = keep_building_ink(linked)
    main = largest_structure(ink)
    # This drawing's own typical gap between real architecture fragments
    # (see _max_gap_to_connect) — the one distance measurement used both to
    # decide how close a fragment must be to `main` to count as part of the
    # building (clip_to_outer's `reach`) and how wide a window opening's
    # closure ring needs to be for room sealing, below. Reusing a single
    # image-measured value keeps both jobs consistent instead of guessing
    # two different fixed constants.
    reach = max(dash, _max_gap_to_connect(main) + 4)
    # `structure` (walls/envelope) is real ink only, clipped to the building
    # region — no fabricated pixels. `seal_outer_loop`'s closure ring is
    # deliberately kept OUT of it and used only to build a separate mask for
    # room flood-fill sealing, below. It used to be folded into `structure`
    # itself (bitwise_or'd in before clip_to_outer), which meant widening the
    # ring to bridge a real window gap also injected spurious "wall" ink into
    # walls_from_mask/envelope/openings detection — confirmed directly:
    # widening the ring enough to close a 34px window gap on a real 12-room
    # plan spiked its door count from a correct ~5 to 25, because the ring
    # itself was being traced as wall/door evidence. Sealing for room
    # detection and tracing for real geometry are different jobs and must
    # not share one mask. `structure` itself also used to clip with a fixed
    # 15px reach regardless of `reach` above, which on a thin-outline-walled
    # drawing let an isolated dimension/extension line (never part of the
    # wall network) survive as its own kept contour once largest_structure()
    # stopped filtering by relative size — confirmed directly: it threw off
    # which traced line openings.py picked as the true exterior wall,
    # spiking door count and losing every window on a real plan. Clipping
    # `structure` with the same measured `reach` excludes it consistently.
    structure = clip_to_outer(ink, main, reach=reach)
    room_seal = clip_to_outer(cv2.bitwise_or(ink, seal_outer_loop(main, thickness=reach)), main, reach=reach)
    sealed = cv2.morphologyEx(room_seal, cv2.MORPH_CLOSE, _kernel(door), iterations=1)
    walls = walls_from_mask(cv2.bitwise_or(ink, structure))
    rooms = rooms_from_mask(sealed)
    envelope = envelope_from_mask(structure)
    bars = find_dimension_bars(rgb)
    traces = trace_all_lines(rgb)
    walls_for_openings = walls_from_mask(_dominant_mass(ink)) or walls
    return CvGeometry(
        walls=walls, rooms=rooms, envelope=envelope, bars=bars,
        walls_for_openings=walls_for_openings,
        traces=traces, wall_mask=structure,
    )


def _kernel(n: int) -> np.ndarray:
    n = max(3, int(n) | 1)
    return cv2.getStructuringElement(cv2.MORPH_RECT, (n, n))


def _max_gap_to_connect(mask: np.ndarray, cap: int = 200) -> int:
    """The widest TYPICAL edge-to-edge gap between this drawing's own ink
    components — i.e. the largest opening (window/door) actually present in
    the wall network, measured from the image instead of guessed.

    Built from the minimum spanning tree over components (nearest-pixel
    Euclidean distance as edge weight): the MST's edges are exactly the set
    of gaps that have to be bridged to connect every component to its
    nearest neighbour once, so most of them are real openings. But the
    single largest MST edge is NOT a safe answer on its own — a lone stray
    mark far from the building (a decorative plant/furniture icon that
    slipped past keep_building_ink's shape/size floor) still has to connect
    to *something* to complete the spanning tree, and its distance to the
    nearest real component can dwarf every genuine window/door gap.
    Confirmed directly on a real 12-room plan: 25 of 26 MST edges fell in
    the 6-49px range (real openings), and exactly one — to an isolated tree
    icon in a corner — was 150px; naively bridging that stretched the
    closure kernel over 3x too wide and merged rooms that should have
    stayed separate. IQR-based outlier rejection on the MST edge weights
    themselves (computed from this drawing's own gap distribution, no fixed
    cutoff) drops that kind of one-off outlier and keeps the largest gap
    that's actually representative of this drawing's real openings.
    """
    n, labels, stats, _ = cv2.connectedComponentsWithStats((mask > 0).astype(np.uint8) * 255, connectivity=8)
    ids = [i for i in range(1, n) if stats[i, cv2.CC_STAT_AREA] >= 1]
    if len(ids) <= 1:
        return 0
    if len(ids) > 60:  # too many fragments for O(n^2) distance transforms to be worth it
        return cap
    dist_maps = {}
    for i in ids:
        comp = np.where(labels == i, 0, 255).astype(np.uint8)
        dist_maps[i] = cv2.distanceTransform(comp, cv2.DIST_L2, 5)
    pts = {i: np.where(labels == i) for i in ids}
    edges = []
    for a_idx, a in enumerate(ids):
        for b in ids[a_idx + 1:]:
            gap = float(dist_maps[a][pts[b]].min())
            edges.append((gap, a, b))
    edges.sort(key=lambda e: e[0])
    parent = {i: i for i in ids}

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    mst_gaps = []
    connected = 1
    for gap, a, b in edges:
        ra, rb = find(a), find(b)
        if ra == rb:
            continue
        parent[ra] = rb
        mst_gaps.append(gap)
        connected += 1
        if connected == len(ids):
            break
    if not mst_gaps:
        return 0
    if len(mst_gaps) < 4:  # too few samples for a meaningful quartile split
        return min(cap, int(round(max(mst_gaps))))
    arr = np.array(mst_gaps)
    q1, q3 = np.percentile(arr, [25, 75])
    upper_fence = q3 + 1.5 * (q3 - q1)
    typical = arr[arr <= upper_fence]
    widest = float(typical.max()) if typical.size else float(arr.min())
    return min(cap, int(round(widest)))


def clip_to_outer(mask: np.ndarray, seed: np.ndarray, reach: int = 15) -> np.ndarray:
    """Clip `mask` to the region(s) near `seed`, rejecting ink far from any
    of it (stray title-block/legend/dimension-line content). Fills ALL of
    the dilated seed's external contours, not just the largest — same fix as
    largest_structure() and for the same reason: `seed` (now
    largest_structure's output) can legitimately be several geometrically
    separate regions of one building, and a fixed-radius dilation isn't
    guaranteed to merge distant ones into a single contour. Picking only the
    biggest contour reproduced the exact same "silently drop half the
    building" bug one level downstream even after largest_structure() itself
    was fixed — confirmed directly: room count for a 12-room test plan
    didn't improve until this was also fixed, despite the seed mask itself
    already being correct by that point.

    Keeping every contour cuts the other way if `reach` is too generous: a
    dimension/extension line drawn just outside the building, or a stray
    icon, is now its own separate contour too (once largest_structure()
    stopped filtering by relative size) and gets kept wholesale rather than
    excluded as "far". `reach` should be the drawing's own measured typical
    gap between real architecture fragments (see `_max_gap_to_connect`), not
    a fixed pixel constant — close enough to bridge a real window/door
    opening, not so wide it also swallows content that was never part of the
    wall network.
    """
    fill = np.zeros_like(mask)
    dilated = cv2.dilate(seed, _kernel(max(3, reach)), iterations=1)
    cnts, _ = cv2.findContours(dilated, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not cnts:
        return mask
    cv2.drawContours(fill, cnts, -1, 255, thickness=-1)
    return cv2.bitwise_and(mask, fill)


def _dominant_mass(ink: np.ndarray) -> np.ndarray:
    """Only the wall ink that clusters into the drawing's dominant mass(es)
    — components at least 8% of the single largest one's area, clipped to
    the single largest resulting contour.

    This is deliberately the stricter, earlier version of
    largest_structure()/clip_to_outer() (see their docstrings for why it was
    loosened for the *general* wall trace: on a densely-fragmented plan it
    drops real architecture). It exists only to build
    CvGeometry.walls_for_openings — opening detection wants the same small,
    dominant-only candidate set it was originally tuned against, not the
    fuller trace, so this keeps that option available without re-loosening
    (or re-tightening) the shared functions everything else depends on.
    """
    n, labels, stats, _ = cv2.connectedComponentsWithStats((ink > 0).astype(np.uint8) * 255, connectivity=8)
    candidates = [(i, int(stats[i, cv2.CC_STAT_AREA])) for i in range(1, n)]
    if not candidates:
        return np.zeros_like(ink)
    max_area = max(area for _, area in candidates)
    keep_ids = [i for i, area in candidates if area >= max_area * 0.08]
    main = np.isin(labels, keep_ids).astype(np.uint8) * 255
    dilated = cv2.dilate(main, _kernel(15), iterations=1)
    cnts, _ = cv2.findContours(dilated, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not cnts:
        return main
    fill = np.zeros_like(main)
    cv2.drawContours(fill, [max(cnts, key=cv2.contourArea)], -1, 255, thickness=-1)
    return cv2.bitwise_and(main, fill)


def largest_structure(mask: np.ndarray) -> np.ndarray:
    """Keep every ink component large enough to plausibly be part of the
    building, not just the single biggest one.

    Root-caused via a real 12-room floor plan: its wall ink wasn't one
    connected blob (a corner gap, a door swing arc, or a T-junction can
    easily split a large building's outline into several separate
    components), so picking only the single largest discarded the rest of
    the building outright — confirmed directly: of 29 ink components on that
    plan, only 1 (covering roughly a third of the total ink) survived the
    old "pick one" logic, and everything downstream (room sealing, the
    envelope) was clipped to just that fragment. A simpler test plan
    happened to trace as one connected piece, so this went unnoticed there.

    A first fix kept components >= 8% of the largest component's own area
    (relative, not absolute). That itself turned out to make the same
    mistake one level up: on a densely-partitioned plan the "largest"
    component is just whichever room cluster happens to be tightly linked
    (e.g. a block of bedrooms whose walls all touch at shared corners), not
    a stand-in for "typical wall size" — real exterior-wall segments between
    doors/windows are legitimately much smaller than that cluster and were
    still being discarded wholesale (confirmed directly: on the same 12-room
    plan, 26 of 37 real wall-ink components fell under an 8%-of-14241 cutoff,
    including most of the exterior perimeter, which fragments into one piece
    per opening rather than staying one blob). There is no component-count
    threshold, relative or absolute, that is a valid proxy for "is this
    architecture" across arbitrarily different room layouts.

    keep_building_ink() already did the real filtering this function needs
    (an absolute noise floor, and a shape check for the one specific
    false-positive shape confirmed in practice: a wide, short, low-on-the-
    page bar matching a title-block underline). Checked directly against
    both test plans: every component that survives keep_building_ink is
    wall-shaped (elongated bands and their L/T-junction unions), so no
    additional size-based filtering step is safe to add without cutting into
    real architecture again. This function now only re-applies that same
    absolute/shape filter (redundant with keep_building_ink, kept here so it
    holds even if called on a mask that skipped that step) instead of
    picking components by their size relative to each other.
    """
    work = (mask > 0).astype(np.uint8) * 255
    n, labels, stats, _ = cv2.connectedComponentsWithStats(work, connectivity=8)
    h = work.shape[0]
    keep_ids = []
    for i in range(1, n):
        area = int(stats[i, cv2.CC_STAT_AREA])
        ww = int(stats[i, cv2.CC_STAT_WIDTH])
        hh = int(stats[i, cv2.CC_STAT_HEIGHT])
        cy = int(stats[i, cv2.CC_STAT_TOP]) + hh / 2.0
        if hh < 25 and ww > 80 and cy > 0.78 * h:
            continue  # title-block underline shape, not architecture
        if area < 80:
            continue
        keep_ids.append(i)
    if not keep_ids:
        return work
    return np.isin(labels, keep_ids).astype(np.uint8) * 255


def keep_building_ink(mask: np.ndarray) -> np.ndarray:
    """Drop title underlines and speckle; keep every other wall fragment."""
    work = (mask > 0).astype(np.uint8) * 255
    n, labels, stats, _ = cv2.connectedComponentsWithStats(work, connectivity=8)
    h = work.shape[0]
    keep = np.zeros_like(work)
    for i in range(1, n):
        area = int(stats[i, cv2.CC_STAT_AREA])
        ww = int(stats[i, cv2.CC_STAT_WIDTH])
        hh = int(stats[i, cv2.CC_STAT_HEIGHT])
        cy = int(stats[i, cv2.CC_STAT_TOP]) + hh / 2.0
        if area < 40:
            continue
        if hh < 25 and ww > 80 and cy > 0.78 * h:
            continue
        keep[labels == i] = 255
    return keep if cv2.countNonZero(keep) else work


def seal_outer_loop(mask: np.ndarray, thickness: int = 10) -> np.ndarray:
    """Add a closed outer belt so window dashes cannot leak the interior."""
    work = (mask > 0).astype(np.uint8) * 255
    if cv2.countNonZero(work) < 20:
        return work
    pad = max(9, thickness)
    dilated = cv2.dilate(work, _kernel(pad), iterations=1)
    contours, _ = cv2.findContours(dilated, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        return work
    outer = max(contours, key=cv2.contourArea)
    fill = np.zeros_like(work)
    cv2.drawContours(fill, [outer], -1, 255, thickness=-1)
    belt = max(7, thickness)
    inner = cv2.erode(fill, _kernel(belt), iterations=1)
    ring = cv2.subtract(fill, inner)
    return cv2.bitwise_or(work, ring)


def walls_from_mask(mask: np.ndarray, min_area: int = 40) -> list[Wall]:
    if mask is None or mask.size == 0:
        return []
    work = (mask > 0).astype(np.uint8) * 255
    h, w = work.shape[:2]
    walls: list[Wall] = []
    min_len = max(22, int(round(min(h, w) * 0.04)))
    dist = cv2.distanceTransform(work, cv2.DIST_L2, 3)
    # Keep both filled bands and thin line evidence. Classification happens
    # after extraction so doors, partitions and dimension evidence are not lost.
    band_segments = _trace_wall_bands(work, min_len)
    hough = cv2.HoughLinesP(
        work, 1, np.pi / 180.0, threshold=28,
        minLineLength=max(14, min_len // 2), maxLineGap=max(8, min_len // 3),
    )
    line_segments = (
        [tuple(int(value) for value in segment) for segment in np.asarray(hough).reshape(-1, 4)]
        if hough is not None else []
    )
    merged = _complete_junctions(
        _merge_segments(band_segments + line_segments, min_len=max(14, min_len // 2)),
        tolerance=max(6, min_len // 4),
    )
    for i, (x1, y1, x2, y2) in enumerate(merged, start=len(walls)):
        thick = _sample_thickness(dist, x1, y1, x2, y2)
        walls.append(
            Wall(
                id=f"wall_{i}",
                start=(float(x1), float(y1)),
                end=(float(x2), float(y2)),
                thickness_mm=float(max(thick * 2.0, 2.0)),
                wall_type="thick_candidate" if thick * 2.0 >= 5.0 else "thin_candidate",
                quad=[(float(x1), float(y1)), (float(x2), float(y2))],
            )
        )
    if not walls:
        walls.extend(_contour_walls(work, start_id=len(walls)))
    return walls


def _trace_wall_bands(mask: np.ndarray, min_len: int) -> list[tuple[int, int, int, int]]:
    segments: list[tuple[int, int, int, int]] = []
    for horizontal in (True, False):
        kernel = cv2.getStructuringElement(
            cv2.MORPH_RECT, (min_len, 3) if horizontal else (3, min_len)
        )
        bands = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)
        contours, _ = cv2.findContours(bands, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        for contour in contours:
            x, y, width, height = cv2.boundingRect(contour)
            span = width if horizontal else height
            thickness = height if horizontal else width
            if span < min_len or thickness > max(30, min_len):
                continue
            if horizontal:
                cy = y + height // 2
                segments.append((x, cy, x + width - 1, cy))
            else:
                cx = x + width // 2
                segments.append((cx, y, cx, y + height - 1))
    return _merge_segments(segments, min_len=min_len)


def _complete_junctions(
    segments: list[tuple[int, int, int, int]], tolerance: int
) -> list[tuple[int, int, int, int]]:
    """Close small wall gaps by snapping endpoints to traced perpendicular bands."""
    mutable = [list(segment) for segment in segments]
    horizontals = [item for item in mutable if item[1] == item[3]]
    verticals = [item for item in mutable if item[0] == item[2]]
    for horizontal in horizontals:
        x0, y, x1, _ = horizontal
        for vertical in verticals:
            x, y0, _, y1 = vertical
            if y0 - tolerance <= y <= y1 + tolerance and x0 - tolerance <= x <= x1 + tolerance:
                if abs(x0 - x) <= tolerance:
                    horizontal[0] = x
                if abs(x1 - x) <= tolerance:
                    horizontal[2] = x
                if abs(y0 - y) <= tolerance:
                    vertical[1] = y
                if abs(y1 - y) <= tolerance:
                    vertical[3] = y
    return [tuple(item) for item in mutable]


def _silhouette(mask: np.ndarray) -> np.ndarray:
    if cv2.countNonZero(mask) < 20:
        return mask
    dilated = cv2.dilate(mask, _kernel(15), iterations=1)
    cnts, _ = cv2.findContours(dilated, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    fill = np.zeros_like(mask)
    if cnts:
        cv2.drawContours(fill, [max(cnts, key=cv2.contourArea)], -1, 255, thickness=-1)
    return fill


def _outer_ring(silhouette: np.ndarray) -> list[tuple[float, float]]:
    cnts, _ = cv2.findContours(silhouette, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not cnts:
        return []
    cnt = max(cnts, key=cv2.contourArea)
    approx = cv2.approxPolyDP(cnt, max(2.0, 0.004 * cv2.arcLength(cnt, True)), True)
    if len(approx) < 3:
        return []
    return [(float(p[0][0]), float(p[0][1])) for p in approx]


def _merge_segments(segs: list[tuple[int, int, int, int]], min_len: int) -> list[tuple[int, int, int, int]]:
    horiz: dict[int, list[tuple[int, int]]] = {}
    vert: dict[int, list[tuple[int, int]]] = {}
    for x1, y1, x2, y2 in segs:
        if abs(x2 - x1) >= abs(y2 - y1):
            y = int(round((y1 + y2) / 2.0))
            a, b = sorted((x1, x2))
            horiz.setdefault(y, []).append((a, b))
        else:
            x = int(round((x1 + x2) / 2.0))
            a, b = sorted((y1, y2))
            vert.setdefault(x, []).append((a, b))
    out: list[tuple[int, int, int, int]] = []
    gap = max(12, min_len // 2)
    bin_px = 12
    out.extend(_merge_axis(horiz, True, gap, bin_px, min_len))
    out.extend(_merge_axis(vert, False, gap, bin_px, min_len))
    return out


def _merge_axis(buckets, horizontal: bool, gap: int, bin_px: int, min_len: int):
    if not buckets:
        return []
    items = []
    for key, spans in buckets.items():
        items.append((key, list(spans)))
    items.sort()
    clusters: list[tuple[float, list[tuple[int, int]]]] = []
    for key, spans in items:
        if clusters and abs(key - clusters[-1][0]) <= bin_px:
            prev_key, prev_spans = clusters[-1]
            clusters[-1] = ((prev_key + key) / 2.0, prev_spans + spans)
        else:
            clusters.append((float(key), spans))
    merged = []
    for key, spans in clusters:
        spans = sorted(spans)
        cur_a, cur_b = spans[0]
        acc = [(cur_a, cur_b)]
        for a, b in spans[1:]:
            if a <= cur_b + gap:
                cur_b = max(cur_b, b)
                acc[-1] = (acc[-1][0], cur_b)
            else:
                cur_a, cur_b = a, b
                acc.append((cur_a, cur_b))
        pos = int(round(key))
        for a, b in acc:
            if b - a < min_len:
                continue
            if horizontal:
                merged.append((a, pos, b, pos))
            else:
                merged.append((pos, a, pos, b))
    return merged


def _sample_thickness(dist: np.ndarray, x1: int, y1: int, x2: int, y2: int) -> float:
    h, w = dist.shape[:2]
    vals = []
    for t in (0.25, 0.5, 0.75):
        x = int(round(x1 + t * (x2 - x1)))
        y = int(round(y1 + t * (y2 - y1)))
        if 0 <= x < w and 0 <= y < h:
            vals.append(float(dist[y, x]))
    return max(vals) if vals else 2.0


def _contour_walls(mask: np.ndarray, start_id: int = 0) -> list[Wall]:
    cnts, _ = cv2.findContours(mask, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
    extra: list[Wall] = []
    for i, cnt in enumerate(cnts):
        if abs(cv2.contourArea(cnt)) < 80:
            continue
        approx = cv2.approxPolyDP(cnt, max(1.5, 0.006 * cv2.arcLength(cnt, True)), True)
        if len(approx) < 3:
            continue
        ring = [(float(p[0][0]), float(p[0][1])) for p in approx]
        extra.append(
            Wall(
                id=f"wall_{start_id + i}",
                start=ring[0],
                end=ring[len(ring) // 2],
                thickness_mm=6.0,
                quad=ring,
            )
        )
    return extra


def rooms_from_mask(mask: np.ndarray, min_frac: float = 0.004) -> list[Room]:
    if mask is None or mask.size == 0:
        return []
    work = (mask > 0).astype(np.uint8) * 255
    h, w = work.shape[:2]
    interior = cv2.bitwise_not(work)
    flood = interior.copy()
    ff_mask = np.zeros((h + 2, w + 2), np.uint8)
    for seed in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        if flood[seed[1], seed[0]] != 0:
            cv2.floodFill(flood, ff_mask, seed, 0)
    n, labels, stats, _ = cv2.connectedComponentsWithStats(flood, connectivity=8)
    min_area = max(80.0, min_frac * h * w)
    max_area = 0.85 * h * w
    rooms: list[Room] = []
    for i in range(1, n):
        area = float(stats[i, cv2.CC_STAT_AREA])
        if area < min_area or area > max_area:
            continue
        comp = np.where(labels == i, 255, 0).astype(np.uint8)
        contours, _ = cv2.findContours(comp, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        if not contours:
            continue
        cnt = max(contours, key=cv2.contourArea)
        peri = cv2.arcLength(cnt, True)
        approx = cv2.approxPolyDP(cnt, max(1.5, 0.006 * peri), True)
        if len(approx) < 3:
            continue
        ring = [(float(p[0][0]), float(p[0][1])) for p in approx]
        rooms.append(Room(id=f"room_{len(rooms)}", type="UNDEFINED", boundary=ring))
    return rooms


def envelope_from_mask(mask: np.ndarray) -> tuple[float, float, float, float] | None:
    if mask is None or cv2.countNonZero(mask) < 20:
        return None
    ys, xs = np.where(mask > 0)
    return float(xs.min()), float(ys.min()), float(xs.max()), float(ys.max())


def find_dimension_bars(rgb: np.ndarray) -> list[DimensionBar]:
    """Long colored dimension ticks (any hue). Black wall ink is ignored."""
    hsv = cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV)
    color = cv2.inRange(hsv, (0, 45, 70), (180, 255, 255))
    color = cv2.morphologyEx(color, cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8), iterations=2)
    lines = cv2.HoughLinesP(color, 1, np.pi / 180.0, threshold=40, minLineLength=60, maxLineGap=12)
    if lines is None or len(lines) == 0:
        return []
    horiz: list[DimensionBar] = []
    vert: list[DimensionBar] = []
    for seg in np.asarray(lines).reshape(-1, 4):
        x1, y1, x2, y2 = (int(v) for v in seg)
        length = float(np.hypot(x2 - x1, y2 - y1))
        if length < 60:
            continue
        horizontal = abs(x2 - x1) >= abs(y2 - y1)
        bar = DimensionBar(
            start=(float(x1), float(y1)),
            end=(float(x2), float(y2)),
            length_px=length,
            horizontal=horizontal,
        )
        (horiz if horizontal else vert).append(bar)
    bars: list[DimensionBar] = []
    if horiz:
        bars.append(max(horiz, key=lambda b: b.length_px))
    if vert:
        bars.append(max(vert, key=lambda b: b.length_px))
    return bars


def trace_all_lines(rgb: np.ndarray) -> list[VectorTrace]:
    """Vectorize every meaningful visible ink contour without semantic filtering."""
    gray = cv2.cvtColor(rgb, cv2.COLOR_RGB2GRAY)
    normalized = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8)).apply(gray)
    otsu = cv2.threshold(normalized, 0, 255, cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU)[1]
    adaptive = cv2.adaptiveThreshold(
        normalized, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY_INV, 31, 11,
    )
    ink = cv2.bitwise_or(otsu, adaptive)
    contours, _ = cv2.findContours(ink, cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)
    traces: list[VectorTrace] = []
    for contour in contours:
        perimeter = cv2.arcLength(contour, True)
        if perimeter < 8:
            continue
        approx = cv2.approxPolyDP(contour, max(0.6, perimeter * 0.0015), True)
        points = [(float(item[0][0]), float(item[0][1])) for item in approx]
        if len(points) < 2:
            continue
        _, (box_width, box_height), _ = cv2.minAreaRect(contour)
        stroke_band = min(box_width, box_height)
        traces.append(VectorTrace(
            id=f"trace_{len(traces)}", points=points,
            closed=bool(len(points) >= 3), line_class="thick" if stroke_band >= 4 else "thin",
        ))
    return traces[:3000]
