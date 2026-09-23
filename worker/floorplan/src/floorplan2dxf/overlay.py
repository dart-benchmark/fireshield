from __future__ import annotations

from pathlib import Path

import cv2
import numpy as np

from .schema import FloorplanModel


def write_overlay(rgb: np.ndarray, model: FloorplanModel, path: str | Path) -> Path:
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    canvas = rgb.copy()
    if canvas.ndim == 2:
        canvas = cv2.cvtColor(canvas, cv2.COLOR_GRAY2BGR)
    else:
        canvas = cv2.cvtColor(canvas, cv2.COLOR_RGB2BGR)

    for room in model.rooms:
        pts = _cv_pts(room.boundary)
        if pts is not None:
            overlay = canvas.copy()
            cv2.fillPoly(overlay, [pts], (180, 220, 160))
            canvas = cv2.addWeighted(overlay, 0.25, canvas, 0.75, 0)
            cv2.polylines(canvas, [pts], True, (80, 160, 60), 2)

    for wall in model.walls:
        pts = _cv_pts(wall.quad) if wall.quad else None
        if pts is not None:
            cv2.polylines(canvas, [pts], True, (0, 0, 220), 2)
        else:
            cv2.line(canvas, _ipt(wall.start), _ipt(wall.end), (0, 0, 220), 2)

    for door in model.doors:
        pts = _cv_pts(door.quad)
        if pts is not None:
            cv2.polylines(canvas, [pts], True, (0, 128, 255), 2)

    for trace in model.traces:
        pts = _cv_pts(trace.points)
        if pts is not None:
            cv2.polylines(canvas, [pts], trace.closed, (190, 150, 40), 1)

    for window in model.windows:
        pts = _cv_pts(window.quad)
        if pts is not None:
            cv2.polylines(canvas, [pts], True, (255, 200, 0), 2)

    for text in model.texts:
        color = (200, 80, 80) if text.kind == "dimension" else (160, 60, 160)
        cv2.circle(canvas, _ipt(text.position), 4, color, -1)
        cv2.putText(
            canvas, text.content[:32], _ipt(text.position),
            cv2.FONT_HERSHEY_SIMPLEX, 0.4, color, 1, cv2.LINE_AA,
        )

    cv2.imwrite(str(path), canvas)
    return path


def _ipt(p) -> tuple[int, int]:
    return int(round(p[0])), int(round(p[1]))


def _cv_pts(ring):
    if not ring or len(ring) < 2:
        return None
    arr = np.array([[int(round(x)), int(round(y))] for x, y in ring], dtype=np.int32)
    return arr
