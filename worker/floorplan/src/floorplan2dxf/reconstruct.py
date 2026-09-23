from __future__ import annotations

import math
from typing import Iterable, Optional

import numpy as np

from .ocr import label_to_room_type
from .schema import (
    ICON_CLASS_NAMES,
    ROOM_CLASS_NAMES,
    Door,
    FloorplanModel,
    Furniture,
    Room,
    TextItem,
    Wall,
    Window,
)


def reconstruct(
    polygons,
    types,
    room_polygons,
    room_types,
    texts: list[TextItem],
    image_size: tuple[int, int],
    cv_geom=None,
) -> FloorplanModel:
    model = FloorplanModel(image_size=image_size, units="px")
    walls: list[Wall] = []
    openings_raw: list[tuple[str, np.ndarray, dict]] = []
    furn_i = 0

    for poly, typ in zip(polygons if polygons is not None else [], types or []):
        quad = _as_quad(poly)
        if quad is None:
            continue
        kind = typ.get("type")
        cls = int(typ.get("class", 0))
        if kind == "wall":
            start, end, thickness = _centerline(quad)
            walls.append(
                Wall(
                    id=f"wall_{len(walls)}",
                    start=start,
                    end=end,
                    thickness_mm=float(thickness),
                    kind="railing" if cls == 8 else "wall",
                    quad=quad,
                )
            )
        elif kind == "icon" and cls in (1, 2):
            openings_raw.append(("window" if cls == 1 else "door", np.asarray(poly, dtype=float), typ))
        elif kind == "icon" and cls not in (0,):
            model.furniture.append(
                Furniture(id=f"furn_{furn_i}", kind=ICON_CLASS_NAMES.get(cls, f"ICON_{cls}"), quad=quad)
            )
            furn_i += 1

    cv_walls = list(getattr(cv_geom, "walls", None) or [])
    if cv_walls:
        model.walls = _renumber_walls(cv_walls)
    else:
        model.walls = _snap_walls(walls)
    model.traces = list(getattr(cv_geom, "traces", None) or [])

    door_i = 0
    win_i = 0
    for name, poly, typ in openings_raw:
        quad = _as_quad(poly)
        if quad is None:
            continue
        start, end, _ = _centerline(quad)
        width = math.hypot(end[0] - start[0], end[1] - start[1])
        cx = (start[0] + end[0]) / 2.0
        cy = (start[1] + end[1]) / 2.0
        host = _nearest_wall((cx, cy), model.walls)
        if name == "door":
            model.doors.append(
                Door(
                    id=f"door_{door_i}",
                    wall_id=host.id if host else None,
                    width_mm=float(width),
                    center=(cx, cy),
                    swing="unknown",
                    quad=quad,
                )
            )
            door_i += 1
        else:
            model.windows.append(
                Window(
                    id=f"window_{win_i}",
                    wall_id=host.id if host else None,
                    width_mm=float(width),
                    center=(cx, cy),
                    quad=quad,
                )
            )
            win_i += 1

    cubi_rooms: list[Room] = []
    for geom, typ in zip(room_polygons or [], room_types or []):
        cls = int(typ.get("class", 11))
        if cls in (0, 2, 8):
            continue
        ring = _geom_ring(geom)
        if len(ring) < 3:
            continue
        cubi_rooms.append(Room(id="", type=ROOM_CLASS_NAMES.get(cls, "UNDEFINED"), boundary=ring))

    cv_rooms = list(getattr(cv_geom, "rooms", None) or [])
    if cv_rooms:
        model.rooms = _label_rooms_from_overlap(cv_rooms, cubi_rooms)
    else:
        for i, room in enumerate(cubi_rooms):
            room.id = f"room_{i}"
            model.rooms.append(room)

    _associate_text(model, texts)
    return model


def _renumber_walls(walls: list[Wall]) -> list[Wall]:
    for i, wall in enumerate(walls):
        wall.id = f"wall_{i}"
    return walls


def _poly_area(ring: list[tuple[float, float]]) -> float:
    if len(ring) < 3:
        return 0.0
    try:
        from shapely.geometry import Polygon

        return float(Polygon(ring).area)
    except Exception:
        xs = [p[0] for p in ring]
        ys = [p[1] for p in ring]
        return max(0.0, (max(xs) - min(xs)) * (max(ys) - min(ys)))


def _overlap_area(a: list[tuple[float, float]], b: list[tuple[float, float]]) -> float:
    try:
        from shapely.geometry import Polygon

        pa, pb = Polygon(a), Polygon(b)
        if not pa.is_valid:
            pa = pa.buffer(0)
        if not pb.is_valid:
            pb = pb.buffer(0)
        return float(pa.intersection(pb).area)
    except Exception:
        return 0.0


def _label_rooms_from_overlap(cv_rooms: list[Room], cubi_rooms: list[Room]) -> list[Room]:
    out: list[Room] = []
    for i, room in enumerate(cv_rooms):
        room.id = f"room_{i}"
        best_type = room.type
        best = 0.0
        for other in cubi_rooms:
            if other.type in ("UNDEFINED", "BACKGROUND", "WALL"):
                continue
            ov = _overlap_area(room.boundary, other.boundary)
            if ov > best:
                best = ov
                best_type = other.type
        if best > 20:
            room.type = best_type
        out.append(room)
    return out


def apply_scale(model: FloorplanModel, mm_per_px: Optional[float]) -> FloorplanModel:
    model.mm_per_px = mm_per_px
    if not mm_per_px:
        model.units = "px"
        return model
    _, h = model.image_size if model.image_size[1] else (0, 0)

    def pt(p):
        return (p[0] * mm_per_px, (h - p[1]) * mm_per_px)

    for wall in model.walls:
        wall.start = pt(wall.start)
        wall.end = pt(wall.end)
        wall.thickness_mm = wall.thickness_mm * mm_per_px
        wall.quad = [pt(p) for p in wall.quad]
    for door in model.doors:
        door.center = pt(door.center)
        door.width_mm = door.width_mm * mm_per_px
        door.quad = [pt(p) for p in door.quad]
    for window in model.windows:
        window.center = pt(window.center)
        window.width_mm = window.width_mm * mm_per_px
        window.quad = [pt(p) for p in window.quad]
    for room in model.rooms:
        room.boundary = [pt(p) for p in room.boundary]
        room.area_m2 = _poly_area(room.boundary) / 1_000_000.0
    for text in model.texts:
        text.position = pt(text.position)
        text.bbox = [pt(p) for p in text.bbox]
    for furn in model.furniture:
        furn.quad = [pt(p) for p in furn.quad]
    for obj in model.objects:
        obj.boundary = [pt(p) for p in obj.boundary]
    for trace in model.traces:
        trace.points = [pt(point) for point in trace.points]
    model.exterior_boundary = [pt(p) for p in model.exterior_boundary]
    model.units = "mm"
    return model


def _as_quad(poly) -> Optional[list[tuple[float, float]]]:
    arr = np.asarray(poly, dtype=float)
    if arr.ndim != 2 or arr.shape[0] < 3 or arr.shape[1] < 2:
        return None
    return [(float(x), float(y)) for x, y in arr[:, :2]]


def _centerline(quad: list[tuple[float, float]]):
    xs = [p[0] for p in quad]
    ys = [p[1] for p in quad]
    x0, x1 = min(xs), max(xs)
    y0, y1 = min(ys), max(ys)
    w, h = x1 - x0, y1 - y0
    if w >= h:
        return (x0, (y0 + y1) / 2.0), (x1, (y0 + y1) / 2.0), h
    return ((x0 + x1) / 2.0, y0), ((x0 + x1) / 2.0, y1), w


def _snap_walls(walls: list[Wall], deg: float = 2.0) -> list[Wall]:
    rad = math.radians(deg)
    for wall in walls:
        dx = wall.end[0] - wall.start[0]
        dy = wall.end[1] - wall.start[1]
        if abs(dx) < 1e-6 and abs(dy) < 1e-6:
            continue
        angle = math.atan2(dy, dx)
        if abs(angle) < rad or abs(abs(angle) - math.pi) < rad:
            y = (wall.start[1] + wall.end[1]) / 2.0
            wall.start = (wall.start[0], y)
            wall.end = (wall.end[0], y)
        elif abs(abs(angle) - math.pi / 2) < rad:
            x = (wall.start[0] + wall.end[0]) / 2.0
            wall.start = (x, wall.start[1])
            wall.end = (x, wall.end[1])
    return walls


def _point_seg_dist(p, a, b) -> float:
    px, py = p
    ax, ay = a
    bx, by = b
    dx, dy = bx - ax, by - ay
    if dx == 0 and dy == 0:
        return math.hypot(px - ax, py - ay)
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))


def _nearest_wall(point, walls: Iterable[Wall]) -> Optional[Wall]:
    best = None
    best_d = 1e18
    for wall in walls:
        d = _point_seg_dist(point, wall.start, wall.end)
        if d < best_d:
            best_d = d
            best = wall
    if best is None:
        return None
    if best_d > max(best.thickness_mm * 2.5, 20.0):
        return None
    return best


def _geom_ring(geom) -> list[tuple[float, float]]:
    if geom is None:
        return []
    if hasattr(geom, "exterior"):
        return [(float(x), float(y)) for x, y in geom.exterior.coords]
    if hasattr(geom, "geoms"):
        largest = max(geom.geoms, key=lambda g: getattr(g, "area", 0.0), default=None)
        return _geom_ring(largest)
    try:
        return [(float(x), float(y)) for x, y in np.asarray(geom).reshape(-1, 2)]
    except Exception:
        return []


def _point_in_ring(point, ring) -> bool:
    if len(ring) < 3:
        return False
    try:
        from shapely.geometry import Point, Polygon

        return Polygon(ring).contains(Point(point))
    except Exception:
        xs = [p[0] for p in ring]
        ys = [p[1] for p in ring]
        return min(xs) <= point[0] <= max(xs) and min(ys) <= point[1] <= max(ys)


def _associate_text(model: FloorplanModel, texts: list[TextItem]) -> None:
    model.texts = list(texts)
    for text in texts:
        if text.kind != "label":
            continue
        mapped = label_to_room_type(text.content)
        for room in model.rooms:
            if _point_in_ring(text.position, room.boundary):
                room.label = text.content
                if mapped:
                    room.type = mapped
                break
    for text in texts:
        if text.kind != "dimension" or text.parsed_mm is None:
            continue
        best = None
        best_d = 1e18
        for room in model.rooms:
            if not room.boundary:
                continue
            cx = sum(p[0] for p in room.boundary) / len(room.boundary)
            cy = sum(p[1] for p in room.boundary) / len(room.boundary)
            d = math.hypot(text.position[0] - cx, text.position[1] - cy)
            if d < best_d:
                best_d = d
                best = room
        if best and best.dimension_text is None:
            best.dimension_text = text.content
