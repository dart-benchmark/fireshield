from __future__ import annotations

from pathlib import Path

import ezdxf
from ezdxf import units
from ezdxf.enums import TextEntityAlignment

from .schema import FloorplanModel

LAYERS = {
    "A-WALL": 7,
    "A-DOOR": 30,
    "A-GLAZ": 4,
    "A-ROOM": 3,
    "A-ANNO": 2,
    "A-FURN": 8,
    "A-CIRC": 6,
    "A-SAFE": 1,
    "A-BOUND": 5,
    "A-TRACE-THIN": 9,
    "A-TRACE-THICK": 8,
}


def write_dxf(model: FloorplanModel, path: str | Path) -> Path:
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    doc = ezdxf.new("R2010")
    doc.header["$INSUNITS"] = units.MM if model.units == "mm" else 0
    doc.header["$LUNITS"] = 2
    for name, color in LAYERS.items():
        if name not in doc.layers:
            doc.layers.add(name, color=color)
    msp = doc.modelspace()

    if len(model.exterior_boundary) >= 3:
        msp.add_lwpolyline(model.exterior_boundary, close=True, dxfattribs={"layer": "A-BOUND"})

    for wall in model.walls:
        pts = wall.quad or [wall.start, wall.end]
        if len(pts) >= 3:
            msp.add_lwpolyline(pts, close=True, dxfattribs={"layer": "A-WALL"})
        else:
            msp.add_line(wall.start, wall.end, dxfattribs={"layer": "A-WALL"})

    for door in model.doors:
        if door.quad:
            msp.add_lwpolyline(door.quad, close=True, dxfattribs={"layer": "A-DOOR"})
        _add_door_swing(msp, door)

    for trace in model.traces:
        if len(trace.points) >= 2:
            msp.add_lwpolyline(
                trace.points, close=trace.closed,
                dxfattribs={"layer": "A-TRACE-THICK" if trace.line_class == "thick" else "A-TRACE-THIN"},
            )

    for window in model.windows:
        if window.quad:
            msp.add_lwpolyline(window.quad, close=True, dxfattribs={"layer": "A-GLAZ"})

    for room in model.rooms:
        if len(room.boundary) >= 3:
            msp.add_lwpolyline(room.boundary, close=True, dxfattribs={"layer": "A-ROOM"})
        label = room.label or room.type
        if label and room.boundary:
            cx = sum(p[0] for p in room.boundary) / len(room.boundary)
            cy = sum(p[1] for p in room.boundary) / len(room.boundary)
            height = _text_height(model)
            msp.add_text(label, height=height, dxfattribs={"layer": "A-ANNO"}).set_placement(
                (cx, cy), align=TextEntityAlignment.MIDDLE_CENTER
            )
            if room.dimension_text:
                msp.add_text(
                    room.dimension_text, height=height * 0.8, dxfattribs={"layer": "A-ANNO"}
                ).set_placement((cx, cy - height * 1.4), align=TextEntityAlignment.MIDDLE_CENTER)

    for text in model.texts:
        if text.kind == "label" and any(
            (room.label or "").lower() == text.content.lower() for room in model.rooms
        ):
            continue
        height = _text_height(model)
        msp.add_text(text.content, height=height, dxfattribs={"layer": "A-ANNO"}).set_placement(
            text.position, align=TextEntityAlignment.LEFT
        )

    for furn in model.furniture:
        if furn.quad:
            msp.add_lwpolyline(furn.quad, close=True, dxfattribs={"layer": "A-FURN"})

    for obj in model.objects:
        if len(obj.boundary) >= 3:
            layer = "A-CIRC" if obj.category == "circulation" else "A-SAFE" if obj.category == "safety" else "A-FURN"
            msp.add_lwpolyline(obj.boundary, close=True, dxfattribs={"layer": layer})

    doc.saveas(path)
    return path


def _text_height(model: FloorplanModel) -> float:
    if model.units == "mm":
        return 150.0
    w, h = model.image_size
    return max(min(w, h) * 0.012, 8.0)


def _add_door_swing(msp, door) -> None:
    if not door.quad or len(door.quad) < 4:
        return
    xs = [p[0] for p in door.quad]
    ys = [p[1] for p in door.quad]
    w = max(xs) - min(xs)
    h = max(ys) - min(ys)
    radius = max(min(w, h) if min(w, h) > 1 else max(w, h), door.width_mm or 1.0)
    if w >= h:
        hinge = (min(xs), min(ys)) if door.swing != "counterclockwise" else (max(xs), min(ys))
        start_angle = 0 if door.swing == "counterclockwise" else 180
    else:
        hinge = (min(xs), min(ys)) if door.swing != "counterclockwise" else (min(xs), max(ys))
        start_angle = 90 if door.swing == "counterclockwise" else 270
    end_angle = start_angle + 90
    try:
        msp.add_arc(
            center=hinge,
            radius=radius,
            start_angle=start_angle,
            end_angle=end_angle,
            dxfattribs={"layer": "A-DOOR"},
        )
    except Exception:
        return
