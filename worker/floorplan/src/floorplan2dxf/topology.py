"""Deterministic semantic relationships for a reconstructed floor plan."""

from __future__ import annotations

import math

from .schema import ArchitecturalObject, FloorplanModel, RoomConnection

OUTSIDE = "outside"


def derive_topology(model: FloorplanModel) -> FloorplanModel:
    """Populate room/opening relationships after extraction and vision review."""
    for room in model.rooms:
        room.door_ids = []
        room.window_ids = []
        room.adjacent_room_ids = []
    model.connections = []

    if not model.exterior_boundary and model.rooms:
        points = [p for room in model.rooms for p in room.boundary]
        if points:
            x0, x1 = min(p[0] for p in points), max(p[0] for p in points)
            y0, y1 = min(p[1] for p in points), max(p[1] for p in points)
            model.exterior_boundary = [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

    walls = {wall.id: wall for wall in model.walls}
    rooms = {room.id: room for room in model.rooms}
    for door in model.doors:
        host = walls.get(door.wall_id or "") or _nearest_wall(door.center, model)
        if host is not None:
            door.wall_id = host.id
        door.connects = _rooms_on_sides(door.center, host, model, door.width_mm)[:2]
        if len(door.connects) == 1:
            door.connects.append(OUTSIDE)
        for room_id in door.connects:
            if room_id in rooms:
                _append_unique(rooms[room_id].door_ids, door.id)
        if len(door.connects) == 2 and door.connects[0] != door.connects[1]:
            edge = RoomConnection(
                id=f"connection_{len(model.connections)}",
                from_room_id=door.connects[0],
                to_room_id=door.connects[1],
                via_id=door.id,
            )
            model.connections.append(edge)
            if edge.from_room_id in rooms and edge.to_room_id in rooms:
                _append_unique(rooms[edge.from_room_id].adjacent_room_ids, edge.to_room_id)
                _append_unique(rooms[edge.to_room_id].adjacent_room_ids, edge.from_room_id)

    for window in model.windows:
        host = walls.get(window.wall_id or "") or _nearest_wall(window.center, model)
        if host is not None:
            window.wall_id = host.id
        candidates = _rooms_on_sides(window.center, host, model, window.width_mm)
        window.room_id = next(iter(candidates), None)
        if window.room_id in rooms:
            _append_unique(rooms[window.room_id].window_ids, window.id)

    for wall in model.walls:
        nearby = _rooms_on_sides(_midpoint(wall.start, wall.end), wall, model, wall.thickness_mm)
        wall.wall_type = "internal" if len(set(nearby)) >= 2 else "external" if len(nearby) == 1 else "unknown"

    _derive_objects(model)
    return model


def _derive_objects(model: FloorplanModel) -> None:
    retained = [obj for obj in model.objects if not obj.id.startswith("room_object_")]
    for room in model.rooms:
        if room.type in {"STAIR", "LIFT", "SHAFT", "CORRIDOR"}:
            retained.append(ArchitecturalObject(
                id=f"room_object_{room.id}",
                kind=room.type,
                category="circulation" if room.type in {"STAIR", "LIFT", "CORRIDOR"} else "structural",
                boundary=list(room.boundary),
                room_id=room.id,
                level_id=model.level_id,
            ))
    model.objects = retained


def _rooms_on_sides(point, wall, model: FloorplanModel, opening_width: float) -> list[str]:
    if wall is None:
        room = _containing_room(point, model)
        return [room] if room else []
    dx, dy = wall.end[0] - wall.start[0], wall.end[1] - wall.start[1]
    length = math.hypot(dx, dy)
    if length < 1e-6:
        return []
    nx, ny = -dy / length, dx / length
    offset = max(float(wall.thickness_mm) * 1.25, float(opening_width) * 0.12, 4.0)
    found: list[str] = []
    for sign in (-1.0, 1.0):
        sample = (point[0] + sign * nx * offset, point[1] + sign * ny * offset)
        room_id = _containing_room(sample, model)
        if room_id and room_id not in found:
            found.append(room_id)
    return found


def _containing_room(point, model: FloorplanModel) -> str | None:
    for room in model.rooms:
        if _point_in_ring(point, room.boundary):
            return room.id
    return None


def _point_in_ring(point, ring) -> bool:
    if len(ring) < 3:
        return False
    x, y = point
    inside = False
    j = len(ring) - 1
    for i in range(len(ring)):
        xi, yi = ring[i]
        xj, yj = ring[j]
        if (yi > y) != (yj > y):
            cross_x = (xj - xi) * (y - yi) / ((yj - yi) or 1e-12) + xi
            if x < cross_x:
                inside = not inside
        j = i
    return inside


def _nearest_wall(point, model: FloorplanModel):
    return min(model.walls, key=lambda wall: _segment_distance(point, wall.start, wall.end), default=None)


def _segment_distance(p, a, b) -> float:
    dx, dy = b[0] - a[0], b[1] - a[1]
    if dx == 0 and dy == 0:
        return math.hypot(p[0] - a[0], p[1] - a[1])
    t = max(0.0, min(1.0, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / (dx * dx + dy * dy)))
    return math.hypot(p[0] - (a[0] + t * dx), p[1] - (a[1] + t * dy))


def _midpoint(a, b):
    return ((a[0] + b[0]) / 2.0, (a[1] + b[1]) / 2.0)


def _append_unique(items: list[str], value: str) -> None:
    if value not in items:
        items.append(value)
