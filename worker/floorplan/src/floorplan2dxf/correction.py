"""Model-proposed, pixel-validated corrections for floor-plan topology."""

from __future__ import annotations

import base64
import json
import re
import time
import urllib.error
import urllib.request

import cv2
import numpy as np

from .schema import FloorplanModel, Room, Wall


QWEN_VISION_MODEL = "qwen/qwen3.6-27b"
GROQ_REASONING_MODEL = "openai/gpt-oss-120b"


def constrain_geometry_to_spec(cv_geom, plan_spec: dict, image_size: tuple[int, int], rgb=None) -> dict:
    """Match deterministic candidates to a high-confidence vision specification."""
    if (str(plan_spec.get("status")) != "usable"
            or _confidence(plan_spec) < 0.7):
        return {"applied": False, "reason": "vision specification is insufficient"}

    width, height = image_size
    scale = max(width, height, 1)
    predicted = [item for item in list(plan_spec.get("major_walls") or [])[:32]
                 if _confidence(item) >= 0.65]
    candidates = list(cv_geom.walls)
    line_candidates = candidates
    matched: list[Wall] = []
    external_points = []

    for target in predicted:
        start, end = _axis_segment(target.get("start"), target.get("end"), image_size)
        if not start:
            continue
        target_horizontal = abs(end[0] - start[0]) >= abs(end[1] - start[1])
        best, best_score = None, float("inf")
        tx, ty = (start[0] + end[0]) / 2, (start[1] + end[1]) / 2
        for wall in line_candidates:
            wall_horizontal = abs(wall.end[0] - wall.start[0]) >= abs(wall.end[1] - wall.start[1])
            if wall_horizontal != target_horizontal:
                continue
            wx, wy = (wall.start[0] + wall.end[0]) / 2, (wall.start[1] + wall.end[1]) / 2
            perpendicular = abs(wy - ty) if target_horizontal else abs(wx - tx)
            along = abs(wx - tx) if target_horizontal else abs(wy - ty)
            target_span = (start[0], end[0]) if target_horizontal else (start[1], end[1])
            wall_span = (wall.start[0], wall.end[0]) if target_horizontal else (wall.start[1], wall.end[1])
            overlap = _span_overlap(target_span, wall_span)
            if overlap < 0.30:
                continue
            score = perpendicular / scale + 0.15 * along / scale + 0.05 * (1 - overlap)
            if score < best_score:
                best, best_score = wall, score
        support = (_wall_support(rgb, best.start, best.end, best.thickness_mm)
                   if rgb is not None and best is not None else 1.0)
        if best is not None and best_score <= 0.10 and support >= 0.18:
            wall_type = str(target.get("kind", "unknown")) if target.get("kind") in {
                "external", "internal"
            } else "unknown"
            if not any(_same_segment(best.start, best.end, item.start, item.end, 5)
                       for item in matched):
                # Label the matched deterministic wall in place. The vision spec
                # never replaces the traced geometry, so every thick structural
                # line survives even when Qwen's coordinates are misaligned.
                best.wall_type = wall_type
                matched.append(best)
                if wall_type == "external":
                    external_points.extend((start, end))

    # Non-destructive: the deterministic tracer remains the geometry authority.
    # The vision spec only annotates which traced walls are external/internal;
    # unmatched thick lines are kept (they were already filtered from furniture,
    # text and dimension strokes upstream), so no information is lost.
    _snap_external_junctions(matched, tolerance=max(4.0, scale * 0.025))
    if len(external_points) >= 4:
        xs = [point[0] for point in external_points]
        ys = [point[1] for point in external_points]
        cv_geom.envelope = (min(xs), min(ys), max(xs), max(ys))

    expected_rooms = [item for item in list(plan_spec.get("spaces") or plan_spec.get("rooms") or [])[:80]
                      if _confidence(item) >= 0.6]
    selected_rooms = []
    used = set()
    for target in expected_rooms:
        try:
            center = (float(target["center"][0]), float(target["center"][1]))
        except (KeyError, TypeError, ValueError, IndexError):
            continue
        best_i, best_distance = None, float("inf")
        for i, room in enumerate(cv_geom.rooms):
            if i in used or not room.boundary:
                continue
            xs, ys = [p[0] for p in room.boundary], [p[1] for p in room.boundary]
            cx, cy = sum(xs) / len(xs), sum(ys) / len(ys)
            contains = min(xs) <= center[0] <= max(xs) and min(ys) <= center[1] <= max(ys)
            distance = 0.0 if contains else np.hypot(cx - center[0], cy - center[1]) / scale
            if distance < best_distance:
                best_i, best_distance = i, distance
        if best_i is not None and best_distance <= 0.18:
            room = cv_geom.rooms[best_i]
            room.label = str(target.get("label", ""))[:80] or None
            room.type = str(target.get("type", "UNDEFINED"))[:40].upper()
            bbox = target.get("bbox")
            if isinstance(bbox, (list, tuple)) and len(bbox) == 4:
                try:
                    x0, y0, x1, y1 = map(float, bbox)
                    if 0 <= x0 < x1 <= width and 0 <= y0 < y1 <= height:
                        room.boundary = [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]
                except (TypeError, ValueError):
                    pass
            selected_rooms.append(room)
            used.add(best_i)
        elif isinstance(target.get("bbox"), (list, tuple)) and len(target["bbox"]) == 4:
            try:
                x0, y0, x1, y1 = map(float, target["bbox"])
                if 0 <= x0 < x1 <= width and 0 <= y0 < y1 <= height:
                    new_room = Room(
                        id=f"room_spec_{len(selected_rooms)}",
                        type=str(target.get("type", "UNDEFINED"))[:40].upper(),
                        label=str(target.get("label", ""))[:80] or None,
                        boundary=[(x0, y0), (x1, y0), (x1, y1), (x0, y1)],
                    )
                    # Additive: a vision-only room the tracer missed is appended,
                    # never used to replace the deterministic room set.
                    cv_geom.rooms.append(new_room)
                    selected_rooms.append(new_room)
            except (TypeError, ValueError):
                pass

    return {
        "applied": True,
        "specifiedWalls": len(predicted),
        "matchedWalls": len(matched),
        "specifiedRooms": len(expected_rooms),
        "matchedRooms": len(selected_rooms),
    }


def _snap_external_junctions(walls: list[Wall], tolerance: float) -> None:
    """Make verified exterior endpoints share exact coordinates at nearby junctions."""
    endpoints = []
    for wall in walls:
        if wall.wall_type == "external":
            endpoints.extend(((wall, "start", wall.start), (wall, "end", wall.end)))
    unused = set(range(len(endpoints)))
    while unused:
        seed = unused.pop()
        cluster = {seed}
        changed = True
        while changed:
            changed = False
            for index in list(unused):
                point = endpoints[index][2]
                if any(np.hypot(point[0] - endpoints[item][2][0], point[1] - endpoints[item][2][1]) <= tolerance
                       for item in cluster):
                    unused.remove(index)
                    cluster.add(index)
                    changed = True
        if len(cluster) < 2:
            continue
        x = float(np.mean([endpoints[index][2][0] for index in cluster]))
        y = float(np.mean([endpoints[index][2][1] for index in cluster]))
        for index in cluster:
            wall, attribute, _ = endpoints[index]
            setattr(wall, attribute, (x, y))


def _span_overlap(a, b) -> float:
    a0, a1 = sorted(map(float, a))
    b0, b1 = sorted(map(float, b))
    intersection = max(0.0, min(a1, b1) - max(a0, b0))
    return intersection / max(a1 - a0, 1.0)


class TopologyCorrectionPlanner:
    def __init__(self, groq_key: str):
        self.groq_key = groq_key
        self.model_used = ""

    def propose(self, rgb: np.ndarray, model: FloorplanModel, discrepancies: list[dict]) -> dict:
        prompt = _correction_prompt(model, discrepancies)
        if not self.groq_key:
            raise RuntimeError("no correction model is configured")
        visual_result = self._qwen_visual(rgb, prompt)
        visual_review = _message_json(visual_result)
        result = self._groq(prompt, visual_review)
        self.model_used = f"{QWEN_VISION_MODEL} + {GROQ_REASONING_MODEL}"
        return _message_json(result)

    def _qwen_visual(self, rgb: np.ndarray, prompt: str) -> dict:
        ok, encoded = cv2.imencode(".jpg", cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR),
                                   [cv2.IMWRITE_JPEG_QUALITY, 88])
        if not ok:
            raise RuntimeError("could not encode correction image")
        image_url = "data:image/jpeg;base64," + base64.b64encode(encoded).decode("ascii")
        return _post_json(
            "https://api.groq.com/openai/v1/chat/completions",
            self.groq_key,
            {
                "model": QWEN_VISION_MODEL,
                "messages": [{"role": "user", "content": [
                    {"type": "text", "text": prompt},
                    {"type": "image_url", "image_url": {"url": image_url}},
                ]}],
                "temperature": 0.2,
                "max_completion_tokens": 1200,
                "reasoning_effort": "none",
                "response_format": {"type": "json_object"},
                "stream": False,
            },
        )

    def _groq(self, prompt: str, visual_review: dict) -> dict:
        text_prompt = (
            "Use the second Qwen visual verifier result below to produce the final conservative correction "
            "operations. Preserve its coordinates, remove unsupported speculation, and ensure the proposed "
            "external walls can form one closed perimeter. Python will reject any operation unsupported by "
            "pixels. Return only the same JSON operation schema requested in the task.\nTASK:\n"
            + prompt + "\nSECOND_VISUAL_REVIEW:\n" + json.dumps(visual_review)
        )
        return _post_json(
            "https://api.groq.com/openai/v1/chat/completions",
            self.groq_key,
            {
                "model": GROQ_REASONING_MODEL,
                "messages": [{"role": "user", "content": text_prompt}],
                "temperature": 0.1,
                "max_completion_tokens": 1200,
                "reasoning_effort": "low",
                "include_reasoning": False,
                "response_format": {"type": "json_object"},
                "stream": False,
            },
        )


def apply_corrections(
    rgb: np.ndarray,
    model: FloorplanModel,
    proposals: dict,
    accepted: list[dict],
    rejected: list[dict],
    min_confidence: float = 0.8,
) -> FloorplanModel:
    walls = {wall.id: wall for wall in model.walls}
    remove_ids: set[str] = set()

    for raw in list(proposals.get("remove_walls") or [])[:64]:
        wall = walls.get(str(raw.get("wall_id", "")))
        confidence = _confidence(raw)
        support = _wall_support(rgb, wall.start, wall.end, wall.thickness_mm) if wall else 1.0
        if wall and wall.wall_type != "external" and confidence >= min_confidence and support < 0.42:
            remove_ids.add(wall.id)
            accepted.append({"kind": "remove_wall", "id": wall.id, "confidence": confidence,
                             "pixelSupport": round(support, 3)})
        else:
            rejected.append({"kind": "remove_wall", "proposal": raw,
                             "reason": "wall missing/external, low confidence, or source pixels support it",
                             "pixelSupport": round(support, 3)})

    replacements: list[Wall] = []
    for raw in list(proposals.get("replace_walls") or [])[:32]:
        wall = walls.get(str(raw.get("wall_id", "")))
        start, end = _axis_segment(raw.get("start"), raw.get("end"), model.image_size)
        confidence = _confidence(raw)
        old_support = _wall_support(rgb, wall.start, wall.end, wall.thickness_mm) if wall else 1.0
        new_support = _wall_support(rgb, start, end, raw.get("thickness", 8)) if start else 0.0
        if (wall and wall.wall_type != "external" and start and confidence >= min_confidence
                and old_support < 0.42 and new_support >= 0.50):
            remove_ids.add(wall.id)
            replacements.append(Wall(wall.id, start, end, max(2.0, min(float(raw.get("thickness", 8)), 80.0))))
            accepted.append({"kind": "replace_wall", "id": wall.id, "confidence": confidence,
                             "oldPixelSupport": round(old_support, 3),
                             "newPixelSupport": round(new_support, 3)})
        else:
            rejected.append({"kind": "replace_wall", "proposal": raw,
                             "reason": "replacement is not supported by source pixels",
                             "oldPixelSupport": round(old_support, 3),
                             "newPixelSupport": round(new_support, 3)})

    additions: list[Wall] = []
    for raw in list(proposals.get("add_walls") or [])[:32]:
        start, end = _axis_segment(raw.get("start"), raw.get("end"), model.image_size)
        confidence = _confidence(raw)
        support = _wall_support(rgb, start, end, raw.get("thickness", 8)) if start else 0.0
        duplicate = start and any(_same_segment(start, end, wall.start, wall.end, 6) for wall in model.walls)
        if start and confidence >= min_confidence and support >= 0.50 and not duplicate:
            wall = Wall(f"wall_{len(model.walls) + len(additions)}", start, end,
                        max(2.0, min(float(raw.get("thickness", 8)), 80.0)))
            additions.append(wall)
            accepted.append({"kind": "add_wall", "id": wall.id, "confidence": confidence,
                             "pixelSupport": round(support, 3)})
        else:
            rejected.append({"kind": "add_wall", "proposal": raw,
                             "reason": "addition is invalid, duplicate, or unsupported by source pixels",
                             "pixelSupport": round(support, 3)})

    model.walls = [wall for wall in model.walls if wall.id not in remove_ids] + replacements + additions
    return model


def _correction_prompt(model: FloorplanModel, discrepancies: list[dict]) -> str:
    topology = {
        "image_size": list(model.image_size),
        "walls": [{"id": wall.id, "start": wall.start, "end": wall.end,
                   "thickness": wall.thickness_mm, "wall_type": wall.wall_type}
                  for wall in model.walls[:160]],
        "spaces": [{"id": room.id, "type": room.type, "label": room.label,
                   "boundary": room.boundary[:24]} for room in model.rooms[:80]],
        "doors": [{"id": door.id, "center": door.center, "width": door.width_mm}
                  for door in model.doors[:100]],
    }
    return (
        "Act as the second, independent visual verifier for this floor-plan reconstruction. Inspect the source "
        "image itself, then compare it with both the extracted topology and Qwen's first-pass review. Verify "
        "that exterior walls form one unbroken closed perimeter and that structural walls are not confused "
        "with furniture, text, dimensions, hatching, or door-swing arcs. Correct any clear mismatch. Coordinates "
        "are pixels. Propose only high-confidence axis-aligned wall operations; return empty operation arrays "
        "when the reconstruction is already correct. Do not emit DXF. Return JSON only: "
        '{"summary":string,"remove_walls":[{"wall_id":string,"confidence":0..1,"reason":string}],'
        '"replace_walls":[{"wall_id":string,"start":[x,y],"end":[x,y],"thickness":number,'
        '"confidence":0..1,"reason":string}],"add_walls":[{"start":[x,y],"end":[x,y],'
        '"thickness":number,"confidence":0..1,"reason":string}]}. '
        "Omit uncertain operations. Qwen discrepancies: " + json.dumps(discrepancies[:30])
        + " Extracted topology: " + json.dumps(topology)
    )


def _post_json(
    url: str, api_key: str, payload: dict, extra_headers: dict | None = None,
    rate_limit_retries: int = 1,
) -> dict:
    headers = {
        "Authorization": f"Bearer {api_key}", "Content-Type": "application/json",
        "Accept": "application/json", "User-Agent": "FireShield-Floorplan/1.0",
        **(extra_headers or {}),
    }
    request = urllib.request.Request(url, data=json.dumps(payload).encode(), headers=headers, method="POST")
    try:
        with urllib.request.urlopen(request, timeout=90) as response:
            return json.load(response)
    except urllib.error.HTTPError as exc:
        try:
            detail = json.loads(exc.read(4096)).get("error", {})
            message = str(detail.get("message", ""))[:500]
        except (json.JSONDecodeError, OSError, AttributeError):
            message = ""
        if exc.code == 429 and rate_limit_retries > 0:
            match = re.search(r"try again in\s+([0-9.]+)s", message, re.I)
            delay = min(50.0, max(2.0, float(match.group(1)) + 1.0 if match else 20.0))
            time.sleep(delay)
            return _post_json(
                url, api_key, payload, extra_headers,
                rate_limit_retries=rate_limit_retries - 1,
            )
        raise RuntimeError(f"correction model failed ({exc.code}){': ' + message if message else ''}") from exc


def _message_json(result: dict) -> dict:
    content = result.get("choices", [{}])[0].get("message", {}).get("content", "{}")
    return json.loads(content)


def _confidence(raw: dict) -> float:
    try:
        return max(0.0, min(float(raw.get("confidence", 0)), 1.0))
    except (TypeError, ValueError):
        return 0.0


def _axis_segment(start_raw, end_raw, image_size):
    try:
        start = (float(start_raw[0]), float(start_raw[1]))
        end = (float(end_raw[0]), float(end_raw[1]))
    except (TypeError, ValueError, IndexError):
        return None, None
    width, height = image_size
    if not all((0 <= start[0] <= width, 0 <= end[0] <= width,
                0 <= start[1] <= height, 0 <= end[1] <= height)):
        return None, None
    if abs(start[0] - end[0]) <= 3:
        x = (start[0] + end[0]) / 2
        start, end = (x, start[1]), (x, end[1])
    elif abs(start[1] - end[1]) <= 3:
        y = (start[1] + end[1]) / 2
        start, end = (start[0], y), (end[0], y)
    else:
        return None, None
    return (start, end) if np.hypot(end[0] - start[0], end[1] - start[1]) >= 8 else (None, None)


def _wall_support(rgb: np.ndarray, start, end, thickness) -> float:
    gray = cv2.cvtColor(rgb, cv2.COLOR_RGB2GRAY)
    mask = np.zeros(gray.shape, dtype=np.uint8)
    line_width = max(3, min(int(round(float(thickness))) + 2, 30))
    cv2.line(mask, tuple(map(round, start)), tuple(map(round, end)), 255, line_width)
    pixels = gray[mask > 0]
    return float(np.mean(pixels < 170)) if pixels.size else 0.0


def _same_segment(a, b, c, d, tolerance: float) -> bool:
    direct = np.hypot(a[0] - c[0], a[1] - c[1]) + np.hypot(b[0] - d[0], b[1] - d[1])
    reverse = np.hypot(a[0] - d[0], a[1] - d[1]) + np.hypot(b[0] - c[0], b[1] - c[1])
    return min(direct, reverse) <= tolerance * 2
