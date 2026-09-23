from __future__ import annotations

import math
import re
from typing import Iterable, Optional

from .schema import Room, TextItem


_SMART = str.maketrans({"’": "'", "‘": "'", "“": '"', "”": '"', "×": "x"})

_FT_IN = re.compile(
    r"(?P<ft>\d+)\s*'\s*(?P<inch>\d+(?:\.\d+)?)?\s*\"?",
)
_METRIC = re.compile(
    r"(?P<val>\d+(?:\.\d+)?)\s*(?P<unit>mm|cm|m)\b",
    re.I,
)
_BARE = re.compile(r"^(?P<val>\d+(?:\.\d+)?)$")
_PAIR_SPLIT = re.compile(r"\s*[xX×]\s*")


def normalize_dim_text(text: str) -> str:
    return " ".join(text.translate(_SMART).strip().split())


def parse_length_mm(token: str) -> Optional[float]:
    token = normalize_dim_text(token).replace(" ", "")
    if not token:
        return None
    m = _METRIC.fullmatch(token)
    if m:
        val = float(m.group("val"))
        unit = m.group("unit").lower()
        if unit == "mm":
            return val
        if unit == "cm":
            return val * 10.0
        return val * 1000.0
    m = re.fullmatch(r"(\d+(?:\.\d+)?)\s*(?:ft|feet)\b", token, re.I)
    if m:
        return float(m.group(1)) * 304.8
    m = _FT_IN.fullmatch(token) or _FT_IN.match(token)
    if m and "'" in token:
        feet = float(m.group("ft"))
        inches = float(m.group("inch") or 0.0)
        return (feet * 12.0 + inches) * 25.4
    m = _BARE.fullmatch(token)
    if m:
        val = float(m.group("val"))
        if val >= 100:
            return val
    return None


def parse_dimension_pair(text: str) -> Optional[tuple[float, float]]:
    cleaned = normalize_dim_text(text)
    cleaned = re.sub(r"(?<=\d)\s*-\s*(?=\d)", "", cleaned)
    cleaned = re.sub(r"'\s*-\s*", "'", cleaned)
    parts = [p.strip() for p in _PAIR_SPLIT.split(cleaned) if p.strip()]
    if len(parts) != 2:
        return None
    # "3.15x3.0m" — a common shorthand where the unit is written once, on the
    # second number, and implicitly applies to both. Without this, the first
    # bare number ("3.15") fails to parse on its own (a bare decimal under
    # 100 is genuinely ambiguous — could be feet, metres, or a typo) even
    # though it is unambiguous in context. Only borrow the second part's unit
    # onto the first if the first has none of its own already.
    if not re.search(r"[a-zA-Z\"']", parts[0]):
        unit_match = re.search(r"[a-zA-Z]+$", parts[1])
        if unit_match:
            parts[0] = parts[0] + unit_match.group(0)
    a = parse_length_mm(parts[0])
    b = parse_length_mm(parts[1])
    if a is None or b is None or a <= 0 or b <= 0:
        return None
    return (a, b)


def parse_overall(spec: str) -> Optional[tuple[float, float]]:
    """Parse '40ft,30ft' / \"40',30'\" / '12192x9144' into millimetres."""
    if not spec:
        return None
    cleaned = normalize_dim_text(spec).replace(",", "x")
    pair = parse_dimension_pair(cleaned)
    if pair:
        return pair
    parts = [p.strip() for p in re.split(r"[xX×,;/]+", cleaned) if p.strip()]
    if len(parts) != 2:
        return None
    a = parse_length_mm(parts[0] if "'" in parts[0] or "ft" in parts[0].lower() else parts[0] + "ft")
    b = parse_length_mm(parts[1] if "'" in parts[1] or "ft" in parts[1].lower() else parts[1] + "ft")
    if a and b:
        return (a, b)
    return None


def classify_text(content: str) -> str:
    if parse_dimension_pair(content):
        return "dimension"
    if parse_length_mm(content) and any(ch in content for ch in "'\"ftm"):
        return "dimension"
    from .schema import LABEL_TO_ROOM_TYPE

    key = normalize_dim_text(content).lower()
    if key in LABEL_TO_ROOM_TYPE:
        return "label"
    for token in re.split(r"[^a-zA-Z]+", key):
        if token in LABEL_TO_ROOM_TYPE:
            return "label"
    return "other"


def room_bbox(room: Room) -> tuple[float, float, float, float]:
    xs = [p[0] for p in room.boundary]
    ys = [p[1] for p in room.boundary]
    return min(xs), min(ys), max(xs), max(ys)


def _aspect(a: float, b: float) -> float:
    return max(a, b) / max(min(a, b), 1e-6)


def calibrate_mm_per_px(
    rooms: Iterable[Room],
    texts: Iterable[TextItem],
    override: Optional[float] = None,
    aspect_tol: float = 0.25,
) -> Optional[float]:
    if override is not None and override > 0:
        return float(override)

    candidates: list[float] = []
    room_list = list(rooms)
    dim_texts = [t for t in texts if t.kind == "dimension" and t.parsed_mm]
    for room in room_list:
        if len(room.boundary) < 3:
            continue
        x0, y0, x1, y1 = room_bbox(room)
        pw, ph = x1 - x0, y1 - y0
        if pw < 8 or ph < 8:
            continue
        rcx, rcy = (x0 + x1) / 2.0, (y0 + y1) / 2.0
        for text in dim_texts:
            w_mm, h_mm = text.parsed_mm  # type: ignore[misc]
            tx, ty = text.position
            dist = math.hypot(tx - rcx, ty - rcy)
            diag = math.hypot(pw, ph)
            if dist > diag * 0.9:
                continue
            for a_mm, b_mm, a_px, b_px in (
                (w_mm, h_mm, pw, ph),
                (w_mm, h_mm, ph, pw),
            ):
                if abs(_aspect(a_mm, b_mm) - _aspect(a_px, b_px)) / _aspect(a_mm, b_mm) > aspect_tol:
                    continue
                candidates.append(a_mm / a_px)
                candidates.append(b_mm / b_px)
                if room.dimension_text is None:
                    room.dimension_text = text.content
    if not candidates:
        return None
    candidates.sort()
    # Room-label matching depends on room segmentation being roughly
    # accurate, which it is not guaranteed to be — the flood-filled regions
    # rooms_from_mask() finds can split or merge a real room, so a label can
    # end up aspect-matched against a bounding box that doesn't actually
    # belong to it. Confirmed directly on a real plan: candidates from that
    # kind of mismatch ranged from ~6 to ~33 mm/px (a >5x spread) while the
    # true scale was a single consistent value; blindly taking the median of
    # a pool that disagreed that badly produced a number roughly 4x too
    # small. A wide spread (relative to the pool's own median, not a fixed
    # mm/px constant) is itself the signal that these matches aren't
    # trustworthy — better to report "could not infer scale" than a
    # confident-looking wrong one, matching how this function already
    # returns None rather than guess when there's no candidate at all.
    median = float(candidates[len(candidates) // 2])
    q1 = float(candidates[len(candidates) // 4])
    q3 = float(candidates[(3 * len(candidates)) // 4])
    if len(candidates) >= 4 and median > 0 and (q3 - q1) / median > 0.5:
        return None
    return median


def _median(values: list[float]) -> Optional[float]:
    good = [v for v in values if v and v > 0]
    if not good:
        return None
    good.sort()
    return float(good[len(good) // 2])


def calibrate_from_span(width_px: float, height_px: float, overall_mm: tuple[float, float]) -> Optional[float]:
    if width_px < 8 or height_px < 8:
        return None
    w_mm, h_mm = overall_mm
    scales = []
    for a_mm, a_px, b_mm, b_px in (
        (w_mm, width_px, h_mm, height_px),
        (w_mm, height_px, h_mm, width_px),
    ):
        if abs(_aspect(a_mm, b_mm) - _aspect(a_px, b_px)) / _aspect(a_mm, b_mm) > 0.3:
            continue
        scales.extend([a_mm / a_px, b_mm / b_px])
    return _median(scales)


def calibrate_from_wall_dimensions(
    dimensions: Iterable[dict],
    walls: Iterable,
    *,
    proximity_px: float,
) -> Optional[float]:
    """Snap each vision-read dimension label to its nearest matching traced wall
    segment and take the median implied scale. EasyOCR is unavailable at runtime
    (Render memory limit), so Qwen reads the printed labels; the geometry itself
    stays deterministic — this only derives the pixel-to-mm scale factor, never
    wall/room topology. Robust to a handful of misread or mismatched labels
    because the median tolerates outliers where a single overall reading can't.
    """
    walls = list(walls)
    ratios: list[float] = []
    for dim in dimensions:
        try:
            value_mm = float(dim.get("value_m") or 0) * 1000.0
            x, y = (float(v) for v in dim["position"])
        except (KeyError, TypeError, ValueError, IndexError):
            continue
        if value_mm < 100:
            continue
        horizontal = str(dim.get("orientation", "")).lower() == "horizontal"
        best_wall = None
        best_dist = None
        for wall in walls:
            try:
                wx1, wy1 = wall.start
                wx2, wy2 = wall.end
            except (TypeError, ValueError):
                continue
            wall_horizontal = abs(wx2 - wx1) >= abs(wy2 - wy1)
            if wall_horizontal != horizontal:
                continue
            length_px = math.hypot(wx2 - wx1, wy2 - wy1)
            if length_px < 4:
                continue
            if horizontal:
                if not (min(wx1, wx2) - proximity_px <= x <= max(wx1, wx2) + proximity_px):
                    continue
                dist = abs(y - (wy1 + wy2) / 2.0)
            else:
                if not (min(wy1, wy2) - proximity_px <= y <= max(wy1, wy2) + proximity_px):
                    continue
                dist = abs(x - (wx1 + wx2) / 2.0)
            if dist > proximity_px:
                continue
            if best_dist is None or dist < best_dist:
                best_dist = dist
                best_wall = (wall, length_px)
        if best_wall is not None:
            _, length_px = best_wall
            ratios.append(value_mm / length_px)
    if len(ratios) < 2:
        return None
    return _median(ratios)


def standalone_lengths_mm(texts: Iterable[TextItem]) -> list[float]:
    """Lengths from labels meant to stand alone as an overall dimension —
    NOT the two components of an "AxB" pair. A pair like "3.31x5.97m" is a
    single room's own call-out, not a building-wide measurement; pulling
    both halves in here (as this used to) mixes numbers from unrelated
    rooms once a drawing has several such labels, and calibrate_auto() takes
    the two largest of whatever this returns as if they were one true
    overall width/height pair. Confirmed directly on a real plan with five
    per-room "AxB m" labels: the two largest components happened to come
    from two different rooms (a dining room's length and an unrelated
    garage's width) and calibrate_auto() silently accepted them as the
    building's own overall footprint, producing a scale several times too
    small. Only a genuinely standalone number (nothing else on that text)
    is safe to treat as a candidate half of a real overall dimension.
    """
    texts = list(texts)
    metric_drawing = any(
        re.search(r"\b(?:mts?|metres?|meters?)\b|scale\s*1\s*:\s*\d+", text.content, re.I)
        for text in texts
    )
    lengths: list[float] = []
    for text in texts:
        one = parse_length_mm(text.content)
        if one and one >= 1500:
            lengths.append(one)
            continue
        if metric_drawing:
            bare = _BARE.fullmatch(normalize_dim_text(text.content))
            if bare and 1.0 <= float(bare.group("val")) <= 100.0:
                lengths.append(float(bare.group("val")) * 1000.0)
    return lengths


def calibrate_auto(
    rooms: Iterable[Room],
    texts: Iterable[TextItem],
    *,
    override: Optional[float] = None,
    overall_mm: Optional[tuple[float, float]] = None,
    envelope: Optional[tuple[float, float, float, float]] = None,
    bar_h_px: Optional[float] = None,
    bar_v_px: Optional[float] = None,
) -> Optional[float]:
    if override is not None and override > 0:
        return float(override)

    texts = list(texts)
    rooms = list(rooms)
    singles = standalone_lengths_mm(texts)
    if overall_mm is None and len(singles) >= 2:
        singles = sorted(singles, reverse=True)
        overall_mm = (singles[0], singles[1])

    if overall_mm and envelope:
        x0, y0, x1, y1 = envelope
        scaled = calibrate_from_span(x1 - x0, y1 - y0, overall_mm)
        if scaled:
            return scaled
    if overall_mm and bar_h_px and bar_v_px:
        scaled = calibrate_from_span(bar_h_px, bar_v_px, overall_mm)
        if scaled:
            return scaled
    return calibrate_mm_per_px(rooms, texts, override=None)
