"""Bounded Qwen-vision corrections for deterministic floor-plan topology.

The vision model may propose additions, but this module validates every proposal
against the source image coordinate system. It never lets an LLM emit DXF
entities directly.
"""

from __future__ import annotations

import base64
import json
import os
import re
import time
import urllib.error
import urllib.request
from dataclasses import dataclass, field

import cv2
import numpy as np

from .schema import Door, FloorplanModel, Wall, Window
from .correction import TopologyCorrectionPlanner, apply_corrections


@dataclass
class GuidanceAudit:
    specification_status: str = "not_run"
    specification_confidence: float = 0.0
    specification_summary: str = ""
    initial_review_status: str = "not_run"
    review_status: str = "not_run"
    review_confidence: float = 0.0
    review_summary: str = ""
    discrepancies: list[dict] = field(default_factory=list)
    accepted: list[dict] = field(default_factory=list)
    rejected: list[dict] = field(default_factory=list)
    correction_status: str = "not_run"
    correction_model: str = ""


class QwenTopologyGuide:
    """Use two vision passes around deterministic, pixel-validated reconstruction."""

    def __init__(self, api_key: str | None = None, model: str = "qwen/qwen3.6-27b",
                 enable_correction: bool = True, building_profile: dict | None = None):
        self.api_key = api_key or os.environ.get("GROQ_API_KEY", "")
        self.model = model
        self.enable_correction = enable_correction
        self.building_profile = building_profile or {}
        self.audit = GuidanceAudit()
        self.plan_spec: dict = {}
        if not self.api_key:
            raise RuntimeError("GROQ_API_KEY is not configured")

    def __call__(self, rgb: np.ndarray, model: FloorplanModel) -> FloorplanModel:
        payload = review_against_spec(self.plan_spec, model)
        self._capture_review(payload, initial=True)
        if not self.enable_correction:
            self.audit.correction_status = "disabled"
            return model
        try:
            planner = TopologyCorrectionPlanner(self.api_key)
            discrepancies = list(self.audit.discrepancies)
            if not discrepancies:
                discrepancies.append({
                    "kind": "independent_visual_verification",
                    "description": (
                        "Independently verify the full topology and its closed exterior perimeter; "
                        "return no operations when it already matches the image."
                    ),
                })
            proposals = planner.propose(rgb, model, discrepancies)
            model = apply_corrections(rgb, model, proposals, self.audit.accepted, self.audit.rejected)
            self.audit.correction_model = planner.model_used
            changed = any(
                item.get("kind") in {"remove_wall", "replace_wall", "add_wall"}
                for item in self.audit.accepted
            )
            self.audit.correction_status = "applied" if changed else "verified_no_change"
            revised = review_against_spec(self.plan_spec, model)
            self._capture_review(revised, initial=False)
        except Exception as exc:
            self.audit.correction_status = "failed"
            self.audit.rejected.append({"kind": "correction_stage", "reason": str(exc)[:500]})
        return model

    def specify(self, rgb: np.ndarray) -> dict:
        """Create the vision-first semantic target that constrains reconstruction."""
        prompt = specify_prompt(rgb, self.building_profile)
        self.plan_spec = _qwen_json(self.api_key, self.model, rgb, prompt, max_tokens=1800)
        self._record_specification(self.plan_spec)
        return self.plan_spec

    def _record_specification(self, spec: dict) -> None:
        status = str(spec.get("status", "insufficient"))
        self.audit.specification_status = status if status in {"usable", "insufficient"} else "insufficient"
        self.audit.specification_confidence = _bounded_confidence(spec.get("confidence", 0))
        self.audit.specification_summary = str(spec.get("summary", ""))[:500]

    def read_dimensions(self, rgb: np.ndarray) -> dict:
        """A second, small, focused call: read printed dimension labels only.

        Split out from specify() deliberately. That call already has to
        enumerate spaces, walls, openings (with connectivity) and elements —
        asking it to ALSO transcribe every printed dimension number competed
        for the same completion budget and lost: dimensions/overall_width_m/
        height_m sat last in a long prompt and a long response, and were
        observed live to never actually arrive (scale stayed unrecovered call
        after call) while even openings quality regressed once this was added
        to the same request. A dedicated call has nothing else to do, so it
        can give this its full, small budget instead of the tail end of a
        crowded one. EasyOCR is disabled at runtime (Render memory limit), so
        this is the only source for printed dimensions.
        """
        prompt = dimension_read_prompt(rgb)
        try:
            return _qwen_dimension_lines(self.api_key, self.model, rgb, prompt, max_tokens=900)
        except Exception:  # noqa: BLE001 - scale recovery is best-effort, never fatal
            return {}

    def _capture_review(self, payload: dict, initial: bool) -> None:
        review = payload.get("review") if isinstance(payload.get("review"), dict) else {}
        status = str(review.get("status", "insufficient"))
        status = status if status in {"approved", "needs_correction", "insufficient"} else "insufficient"
        if initial:
            self.audit.initial_review_status = status
        self.audit.review_status = status
        self.audit.review_confidence = _bounded_confidence(review.get("confidence", 0))
        self.audit.review_summary = str(review.get("summary", ""))[:500]
        self.audit.discrepancies = list(review.get("discrepancies") or [])[:50]

    def _request(self, rgb: np.ndarray, model: FloorplanModel) -> dict:
        compact = {
            "image_size": list(model.image_size),
            "walls": [{"id": w.id, "start": w.start, "end": w.end} for w in model.walls],
            "doors": [{"center": d.center, "width": d.width_mm} for d in model.doors],
            "windows": [{"center": w.center, "width": w.width_mm} for w in model.windows],
            "rooms": [{"id": r.id, "type": r.type, "boundary": r.boundary} for r in model.rooms],
        }
        prompt = (
            "Compare this floor-plan image with the extracted topology JSON. Propose only clearly visible "
            "objects that the extraction missed. Coordinates must be pixels in the supplied image_size. "
            "Walls must be horizontal or vertical centerlines. Do not delete or move existing geometry. "
            "First review whether the extracted structure matches the visible drawing. "
            "Return JSON only: {\"review\":{\"status\":\"approved|needs_correction|insufficient\","
            "\"confidence\":0..1,\"summary\":str,\"discrepancies\":[{\"kind\":str,\"description\":str}]},"
            "\"add_walls\":[{\"start\":[x,y],\"end\":[x,y],\"thickness\":px,"
            "\"confidence\":0..1}],\"add_doors\":[{\"center\":[x,y],\"width\":px,\"confidence\":0..1}],"
            "\"add_windows\":[same],\"room_labels\":[{\"room_id\":str,\"label\":str,\"type\":str,"
            "\"confidence\":0..1}]}. Omit uncertain proposals. Extracted topology: " + json.dumps(compact)
        )
        return _qwen_json(self.api_key, self.model, rgb, prompt, max_tokens=1800)


def review_against_spec(spec: dict, model: FloorplanModel) -> dict:
    """Measure Python topology against Qwen's pixel-coordinate target without another vision call."""
    if not isinstance(spec, dict) or spec.get("status") != "usable":
        return {"review": {"status": "insufficient",
                           "confidence": _bounded_confidence(spec.get("confidence", 0) if isinstance(spec, dict) else 0),
                           "summary": "Vision specification was insufficient for geometry approval.",
                           "discrepancies": []}}
    width, height = model.image_size
    tolerance = max(8.0, max(width, height) * 0.025)
    walls = [item for item in list(spec.get("major_walls") or [])
             if _bounded_confidence(item.get("confidence", 0)) >= 0.65]
    spaces = [item for item in list(spec.get("spaces") or [])
              if _bounded_confidence(item.get("confidence", 0)) >= 0.65]
    discrepancies = []
    matched = 0
    exterior_matches = []
    for item in walls:
        matching_wall = next(
            (wall for wall in model.walls if _wall_matches(item, wall, tolerance)),
            None,
        )
        if matching_wall is not None:
            matched += 1
            if item.get("kind") == "external":
                exterior_matches.append(matching_wall)
        else:
            discrepancies.append({"kind": "missing_specified_wall",
                                  "description": f"No pixel-supported reconstructed wall matches {item.get('start')} to {item.get('end')}.",
                                  "target": item})
    for item in spaces:
        center = item.get("center")
        if any(_room_contains(room, center, tolerance) for room in model.rooms):
            matched += 1
        else:
            discrepancies.append({"kind": "missing_specified_space",
                                  "description": f"No reconstructed space contains vision target {item.get('label')!r} at {center}.",
                                  "target": item})
    total = len(walls) + len(spaces)
    ratio = matched / total if total else 0.0
    exterior_targets = [item for item in walls if item.get("kind") == "external"]
    perimeter_closed = not exterior_targets or _closed_perimeter(
        exterior_matches, tolerance
    )
    if exterior_targets and not perimeter_closed:
        discrepancies.append({
            "kind": "open_external_perimeter",
            "description": "Exterior wall segments do not form one unbroken closed perimeter.",
        })
    status = (
        "approved"
        if total and ratio >= 0.70 and perimeter_closed
        else ("needs_correction" if total else "insufficient")
    )
    confidence = _bounded_confidence(spec.get("confidence", 0)) * (0.5 + 0.5 * ratio)
    return {"review": {"status": status, "confidence": confidence,
                       "summary": f"Matched {matched}/{total} high-confidence vision targets to pixel-derived topology.",
                       "discrepancies": discrepancies[:50]}}


def _closed_perimeter(walls: list[Wall], tolerance: float) -> bool:
    if len(walls) < 4:
        return False
    nodes: list[tuple[float, float]] = []
    edges = []

    def node_for(point):
        for index, node in enumerate(nodes):
            if np.hypot(point[0] - node[0], point[1] - node[1]) <= tolerance:
                return index
        nodes.append((float(point[0]), float(point[1])))
        return len(nodes) - 1

    for wall in walls:
        a, b = node_for(wall.start), node_for(wall.end)
        if a != b:
            edges.append((a, b))
    if len(edges) < 4:
        return False
    degrees = [0] * len(nodes)
    adjacency = [set() for _ in nodes]
    for a, b in edges:
        degrees[a] += 1
        degrees[b] += 1
        adjacency[a].add(b)
        adjacency[b].add(a)
    if any(degree != 2 for degree in degrees):
        return False
    visited = set()
    stack = [0]
    while stack:
        current = stack.pop()
        if current in visited:
            continue
        visited.add(current)
        stack.extend(adjacency[current] - visited)
    return len(visited) == len(nodes)


def _wall_matches(item: dict, wall: Wall, tolerance: float) -> bool:
    try:
        start, end = item["start"], item["end"]
        sx, sy, ex, ey = map(float, (start[0], start[1], end[0], end[1]))
        wx1, wy1 = map(float, wall.start)
        wx2, wy2 = map(float, wall.end)
    except (KeyError, TypeError, ValueError, IndexError):
        return False
    horizontal = abs(ex - sx) >= abs(ey - sy)
    wall_horizontal = abs(wx2 - wx1) >= abs(wy2 - wy1)
    if horizontal != wall_horizontal:
        return False
    if horizontal:
        return abs((sy + ey - wy1 - wy2) / 2) <= tolerance and _overlap(sx, ex, wx1, wx2) >= 0.45
    return abs((sx + ex - wx1 - wx2) / 2) <= tolerance and _overlap(sy, ey, wy1, wy2) >= 0.45


def _overlap(a1: float, a2: float, b1: float, b2: float) -> float:
    alo, ahi = sorted((a1, a2))
    blo, bhi = sorted((b1, b2))
    return max(0.0, min(ahi, bhi) - max(alo, blo)) / max(ahi - alo, 1.0)


def _room_contains(room, center, tolerance: float) -> bool:
    if not isinstance(center, (list, tuple)) or len(center) != 2 or not room.boundary:
        return False
    try:
        x, y = map(float, center)
        xs = [float(point[0]) for point in room.boundary]
        ys = [float(point[1]) for point in room.boundary]
    except (TypeError, ValueError, IndexError):
        return False
    return min(xs) - tolerance <= x <= max(xs) + tolerance and min(ys) - tolerance <= y <= max(ys) + tolerance

#: Longest edge sent to the vision model. Image tokens dominate the cost of a
#: vision call, and the daily budget is what actually runs out (observed:
#: 197,885 of 200,000 tokens per day consumed, which disables the advisory
#: stream entirely — no space labels, no openings and no printed-dimension
#: read, so scale cannot be recovered). Printed dimension text stays legible
#: well below the full preprocessed size, so capping here buys a large
#: multiple of extra calls per day for no practical loss of reading accuracy.
QWEN_MAX_SIDE = 768


def _downscale_for_vision(rgb: np.ndarray, max_side: int = QWEN_MAX_SIDE) -> np.ndarray:
    height, width = rgb.shape[:2]
    longest = max(height, width)
    if longest <= max_side:
        return rgb
    ratio = max_side / float(longest)
    return cv2.resize(
        rgb, (max(1, int(round(width * ratio))), max(1, int(round(height * ratio)))),
        interpolation=cv2.INTER_AREA,
    )


#: Firing two Qwen calls per plan (specify() then read_dimensions()) can
#: collide with the org's own TPM/TPD budget — observed live: the second call
#: 429'd immediately after the first succeeded. Unlike worker.js's callGroq,
#: this path had no retry at all, so any such collision silently killed scale
#: recovery for the whole request. One bounded wait-and-retry, honouring
#: Groq's own Retry-After, matches what the Worker already does.
_MAX_RATE_LIMIT_WAIT_SECONDS = 12.0


def _qwen_request(
    api_key: str, model: str, rgb: np.ndarray, prompt: str, max_tokens: int,
    response_format: dict | None,
) -> str:
    """Encode the image and prompt, return the raw text content."""
    rgb = _downscale_for_vision(rgb)
    ok, encoded = cv2.imencode(".jpg", cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR), [cv2.IMWRITE_JPEG_QUALITY, 82])
    if not ok:
        raise RuntimeError("could not encode plan image")
    image_url = "data:image/jpeg;base64," + base64.b64encode(encoded).decode("ascii")
    payload = {
        "model": model,
        "messages": [{"role": "user", "content": [
            {"type": "text", "text": prompt},
            {"type": "image_url", "image_url": {"url": image_url}},
        ]}],
        "temperature": 0.7,
        "top_p": 0.8,
        "presence_penalty": 1.5,
        "max_completion_tokens": max_tokens,
        "reasoning_effort": "none",
        "stream": False,
    }
    if response_format is not None:
        payload["response_format"] = response_format
    body = json.dumps(payload).encode("utf-8")
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": "FireShield-Floorplan/1.0",
    }
    for attempt in range(2):
        req = urllib.request.Request(
            "https://api.groq.com/openai/v1/chat/completions", data=body, headers=headers, method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=60) as response:
                result = json.load(response)
            return result.get("choices", [{}])[0].get("message", {}).get("content", "")
        except urllib.error.HTTPError as exc:
            # Only 429 is handled here, by waiting and retrying once. Every
            # other status (including 400/json_validate_failed) is re-raised
            # AS THE ORIGINAL HTTPError, unmodified — _qwen_json's own retry
            # depends on catching that exact exception type and reading its
            # Groq error code, so this must not wrap or swallow it.
            if exc.code == 429 and attempt == 0:
                wait = _retry_after_seconds(exc)
                if wait is not None and 0 < wait <= _MAX_RATE_LIMIT_WAIT_SECONDS:
                    time.sleep(wait)
                    continue
            raise
    raise RuntimeError("Qwen request failed after rate-limit retry")


def _retry_after_seconds(error: urllib.error.HTTPError) -> float | None:
    header = error.headers.get("Retry-After") if error.headers else None
    if not header:
        return None
    try:
        return float(header)
    except (TypeError, ValueError):
        return None


def _qwen_json(api_key: str, model: str, rgb: np.ndarray, prompt: str, max_tokens: int) -> dict:
        for attempt in range(2):
            attempt_prompt = prompt
            if attempt:
                attempt_prompt += (
                    " Previous generation failed JSON validation. Return exactly one complete JSON object "
                    "matching the requested keys, with no markdown, comments, or trailing text."
                )
            try:
                content = _qwen_request(
                    api_key, model, rgb, attempt_prompt, max_tokens, {"type": "json_object"})
                return json.loads(content or "{}")
            except urllib.error.HTTPError as exc:
                provider_code, provider_message = _provider_error_details(exc)
                if exc.code == 400 and provider_code == "json_validate_failed" and attempt == 0:
                    continue
                suffix = f": {provider_message}" if provider_message else ""
                raise RuntimeError(f"Qwen request failed ({exc.code}){suffix}") from exc
            except json.JSONDecodeError:
                if attempt == 0:
                    continue
                raise RuntimeError("Qwen request failed after JSON validation retry")
        raise RuntimeError("Qwen request failed after JSON validation retry")


def specify_prompt(rgb: np.ndarray, building_profile: dict) -> str:
    """The spaces/walls/openings/elements prompt, shared across providers."""
    height, width = rgb.shape[:2]
    return (
        "Inspect this floor-plan image before any geometry extraction. Define what a deterministic Python "
        "reconstructor should produce. Coordinates are pixels in image_size. Return JSON only: "
        '{"status":"usable|insufficient","confidence":0..1,"summary":string,'
        '"spaces":[{"label":string,"type":string,"category":"occupied|circulation|service|shaft|safety",'
        '"center":[x,y],"bbox":[x0,y0,x1,y1],'
        '"confidence":0..1}],"major_walls":[{"orientation":"horizontal|vertical",'
        '"start":[x,y],"end":[x,y],"kind":"external|internal","confidence":0..1}],'
        '"openings":[{"type":"door|window","center":[x,y],"connects":[string,string],'
        '"is_external":true|false,"confidence":0..1}]}. '
        'For EVERY opening also report what it attaches to: "connects" lists the labels of the one or two '
        'spaces it joins (use the exact space labels you returned above; for a door or window on an outside '
        'wall use the single interior space plus "OUTSIDE"), and "is_external" is true when it leads outdoors. '
        'A door to the outside is an egress point, so this matters more than the count. Always give "center" '
        'as pixel coordinates for windows too, not just doors — never return null for center. '
        'Also return "grid":{"x":[pixel positions],"y":[pixel positions]} and '
        '"elements":[{"id":string,"kind":string,"category":"structural|circulation|safety|mep|other",'
        '"label":string,"center":[x,y],"bbox":[x0,y0,x1,y1],"confidence":0..1}]. '
        "Include commercial spaces and features when visible: offices, tenant areas, corridors, lobbies, "
        "stairs, fire-escape stairs, lift banks, shafts, service/electrical rooms, fire command centres, "
        "refuge areas, compartments and exits. Preserve exact visible labels. Do not assume residential "
        "space types or invent features from the building profile. Include only structural walls, not "
        "furniture, dimension lines, text underlines, or room contents. "
        f"image_size=[{width},{height}]. Building profile context="
        + json.dumps(building_profile)
    )


def dimension_read_prompt(rgb: np.ndarray) -> str:
    """The compact-line dimension-reading prompt, shared by every provider
    (Qwen, Mistral) so a change to the format only has to be made once.
    """
    height, width = rgb.shape[:2]
    # A compact line per dimension, not JSON: no repeated field names to pay
    # for on every one of a plan's 10-20 labels. Format is exactly
    # "<value_m> <H|V> <x> <y>", one per line, e.g. "2.00 H 219 162" for a
    # horizontal 2.00m label centred at pixel (219,162). Blank/unreadable
    # lines are simply omitted.
    return (
        "Read every printed dimension label on this floor-plan drawing. Output ONLY plain text lines "
        "in this exact format, nothing else — no JSON, no markdown, no explanation:\n"
        "<value_m> <H|V> <x> <y>\n"
        "One line per printed number along a dimension line — each individual segment (e.g. \"2.00\", "
        "\"4.00\", \"3.00\" drawn along one wall run), not only the outermost total. value_m is the "
        "number converted to metres (convert feet/inches). H means it labels a horizontal (width/length) "
        "run, V a vertical (height/depth) run. x y is the pixel position of that label, near the wall "
        "segment it measures. Read as many as are legibly printed; omit any you cannot read confidently "
        "— never guess a value. "
        "After all dimension lines, add exactly one final line for the printed OUTER envelope total for "
        "the whole building (not a single room): \"OVERALL <width_m> <height_m>\". If no explicit overall "
        "total is printed, write \"OVERALL 0 0\".\n"
        "Example output:\n2.00 H 219 162\n4.00 H 420 162\n8.00 V 68 550\nOVERALL 9.00 11.00\n"
        f"image_size=[{width},{height}]."
    )


#: Matches one compact dimension line: "2.00 H 219 162" (value, orientation
#: letter, x, y). Whitespace-tolerant; unrecognised lines are simply skipped
#: rather than failing the whole read, so partial output is never wasted.
_DIMENSION_LINE = re.compile(
    r"^\s*(?P<value>\d+(?:\.\d+)?)\s+(?P<axis>[HhVv])\s+(?P<x>-?\d+(?:\.\d+)?)\s+(?P<y>-?\d+(?:\.\d+)?)\s*$"
)
_OVERALL_LINE = re.compile(
    r"^\s*OVERALL\s+(?P<w>\d+(?:\.\d+)?)\s+(?P<h>\d+(?:\.\d+)?)\s*$", re.IGNORECASE
)


def _parse_dimension_lines(text: str) -> dict:
    """Shared by every provider: turn the compact line format into the same
    {"dimensions": [...], "overall_width_m": ..., "overall_height_m": ...}
    shape regardless of which vision model produced the text. Repeating
    JSON's field names ("value_m", "orientation", "position") for every one
    of a plan's 10-20 printed dimensions is what competed the dimension read
    out of its token budget when this was folded into the combined call — a
    plain line per dimension carries the same information in roughly a fifth
    the characters. No JSON-repair retry is needed: unparseable lines are
    simply skipped, so a partially malformed reply still yields whatever it
    got right instead of being discarded entirely.
    """
    dimensions: list[dict] = []
    overall_w = overall_h = 0.0
    for line in text.splitlines():
        dim_match = _DIMENSION_LINE.match(line)
        if dim_match:
            dimensions.append({
                "value_m": float(dim_match.group("value")),
                "orientation": "horizontal" if dim_match.group("axis").upper() == "H" else "vertical",
                "position": [float(dim_match.group("x")), float(dim_match.group("y"))],
            })
            continue
        overall_match = _OVERALL_LINE.match(line)
        if overall_match:
            overall_w, overall_h = float(overall_match.group("w")), float(overall_match.group("h"))
    return {"dimensions": dimensions, "overall_width_m": overall_w, "overall_height_m": overall_h}


def _qwen_dimension_lines(api_key: str, model: str, rgb: np.ndarray, prompt: str, max_tokens: int) -> dict:
    text = _qwen_request(api_key, model, rgb, prompt, max_tokens, response_format=None)
    return _parse_dimension_lines(text)


#: Separate provider, separate quota pool from Groq/Qwen entirely — which is
#: the actual point: firing this from a fresh budget means it can never
#: collide with whatever the site/photo audit or plan compliance reasoning is
#: doing against Groq at the same time.
#: "mistral-medium-3-5-26-04" (the dated ID) does not appear in the account's
#: own rate-limit dashboard (admin.mistral.ai/plateforme/limits) at all, so it
#: is not confirmed as a real, callable model ID — using it risked a request
#: that fails outright. "mistral-medium-latest" IS listed there (25,000
#: TPM / 0.83 RPS) and is Mistral's alias for the current newest Medium
#: release, so it is used instead: same model family, a confirmed-valid ID.
MISTRAL_DIMENSION_MODEL = os.environ.get("MISTRAL_VISION_MODEL", "mistral-medium-latest")
_MISTRAL_MAX_RATE_LIMIT_WAIT_SECONDS = 12.0
#: A single real drawing used well under half of this (~1300 of 4000 tokens
#: for 8 spaces + 9 walls + 12 openings + 1 element). Left generous rather
#: than tuned to that one observation — a denser commercial plan with many
#: more rooms/openings needs real headroom, and Mistral's account TPM budget
#: (25,000-375,000/min depending on model) makes this cheap regardless.
#: specify_via_mistral() also retries with a shorten-the-reply instruction if
#: this still isn't enough for a particular drawing.
MISTRAL_SPECIFY_MAX_TOKENS = int(os.environ.get("MISTRAL_SPECIFY_MAX_TOKENS", "6000"))


def _mistral_request(
    api_key: str, model: str, rgb: np.ndarray, prompt: str, max_tokens: int,
    response_format: dict | None,
) -> str:
    """Shared HTTP call for every Mistral use (dimensions, specify, ...).

    Mistral's chat completions endpoint is OpenAI-shaped EXCEPT for how an
    image is attached: their own docs example (fetched and read directly, not
    assumed — see guidance.py history) uses "image_url" as a flat string
    ("image_url": "data:image/jpeg;base64,...."), not OpenAI/Groq's nested
    {"image_url": {"url": ...}}. response_format:{"type":"json_object"} is
    also confirmed from their docs, same shape as OpenAI/Groq's.
    """
    rgb = _downscale_for_vision(rgb)
    ok, encoded = cv2.imencode(".jpg", cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR), [cv2.IMWRITE_JPEG_QUALITY, 82])
    if not ok:
        raise RuntimeError("could not encode plan image")
    image_url = "data:image/jpeg;base64," + base64.b64encode(encoded).decode("ascii")
    payload = {
        "model": model,
        "messages": [{"role": "user", "content": [
            {"type": "text", "text": prompt},
            {"type": "image_url", "image_url": image_url},
        ]}],
        "max_tokens": max_tokens,
        "temperature": 0.2,
    }
    if response_format is not None:
        payload["response_format"] = response_format
    body = json.dumps(payload).encode("utf-8")
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    for attempt in range(2):
        req = urllib.request.Request(
            "https://api.mistral.ai/v1/chat/completions", data=body, headers=headers, method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=60) as response:
                result = json.load(response)
            return result.get("choices", [{}])[0].get("message", {}).get("content", "")
        except urllib.error.HTTPError as exc:
            # Only 429 is retried here; everything else (including a JSON-mode
            # validation error, if Mistral emits one) is re-raised unmodified
            # so callers that need to react to a specific status can.
            if exc.code == 429 and attempt == 0:
                wait = _retry_after_seconds(exc)
                if wait is not None and 0 < wait <= _MISTRAL_MAX_RATE_LIMIT_WAIT_SECONDS:
                    time.sleep(wait)
                    continue
            raise
    raise RuntimeError("Mistral request failed after rate-limit retry")


def read_dimensions_via_mistral(
    rgb: np.ndarray, api_key: str, prompt: str, max_tokens: int = 900,
    model: str = MISTRAL_DIMENSION_MODEL,
) -> dict:
    try:
        text = _mistral_request(api_key, model, rgb, prompt, max_tokens, response_format=None)
    except urllib.error.HTTPError as exc:
        _, message = _provider_error_details(exc)
        suffix = f": {message}" if message else ""
        raise RuntimeError(f"Mistral request failed ({exc.code}){suffix}") from exc
    return _parse_dimension_lines(text)


def specify_via_mistral(
    rgb: np.ndarray, api_key: str, building_profile: dict,
    model: str = MISTRAL_DIMENSION_MODEL, max_tokens: int = MISTRAL_SPECIFY_MAX_TOKENS,
) -> dict:
    """Mistral equivalent of QwenTopologyGuide.specify() — spaces, walls,
    openings (with connectivity/is_external) and elements, in one call.

    Verified live against a real floor plan: 8/8 spaces correctly labelled,
    5/5 doors with connectivity, 7/8 windows with connectivity and external
    flags, using well under half of a 4000-token budget — noticeably more
    complete than Qwen was returning for the same prompt, and on a separate
    quota pool from Groq entirely. A denser plan (many more rooms/openings)
    could still run past that budget and get cut off mid-JSON, so this
    retries once, explicitly asking for a shorter reply, on either a JSON
    decode failure or a 400 that names a JSON-mode validation problem —
    the same two-strikes pattern _qwen_json already uses.
    """
    prompt = specify_prompt(rgb, building_profile)
    for attempt in range(2):
        attempt_prompt = prompt
        if attempt:
            attempt_prompt = prompt + (
                " Your previous reply was cut off before completing the JSON object. Keep every field, "
                "but shorten summary text and omit low-confidence spaces/elements so the full object fits."
            )
        try:
            text = _mistral_request(
                api_key, model, rgb, attempt_prompt, max_tokens, {"type": "json_object"})
            return json.loads(text or "{}")
        except urllib.error.HTTPError as exc:
            if attempt == 0:
                continue
            _, message = _provider_error_details(exc)
            suffix = f": {message}" if message else ""
            raise RuntimeError(f"Mistral request failed ({exc.code}){suffix}") from exc
        except json.JSONDecodeError:
            if attempt == 0:
                continue
            raise RuntimeError("Mistral request failed: reply was not valid JSON after retry")
    raise RuntimeError("Mistral request failed after retry")


def subcomponent_prompt(ocr_labels: list[str]) -> str:
    """OCR label hints (room names, "UP", etc. — already cleaned/merged by
    text_clustering.py) are folded into the prompt so Mistral cross-checks
    its own vision read against what the drawing's own text says is there,
    rather than guessing purely from shape. Explicitly calls out stairs/
    egress: neither the deterministic CV pipeline nor a tried-and-dropped
    geometric symbol matcher (see symbol_lab/README.md) ever recognized a
    staircase, which is the one subcomponent category with direct fire-
    safety/egress relevance — this prompt is the fix for that blind spot."""
    labels_line = ", ".join(f'"{l}"' for l in ocr_labels) if ocr_labels else "(none read)"
    return (
        "This is an architectural floor plan drawing. Identify every furniture/fixture "
        "SUBCOMPONENT you can see drawn on it — tables, beds, sofas/chairs, cabinets, "
        "kitchen counters/sinks, bathroom fixtures (WC/sink/shower), and STAIRCASES "
        "(look for a set of parallel step lines, often with a direction arrow or an "
        "\"UP\"/\"DN\" label) — a staircase is a fire-safety/egress-relevant feature and "
        "must be reported if present, even if you are not fully certain. "
        f"Text already read off this drawing by OCR (room names, direction labels): "
        f"{labels_line}. Use these as hints for what a shape near that text label probably "
        "is, but still report only what you can actually see drawn. "
        "Return JSON only: {\"subcomponents\": [{\"type\": string (e.g. \"bed\", \"sofa\", "
        "\"dining_table\", \"kitchen_sink\", \"staircase\", \"wc\", \"cabinet\"), "
        "\"label\": string (short human description), "
        "\"positionFraction\": [x, y] (the item's approximate center, as a fraction 0.0-1.0 "
        "of the image width and height), \"sourceHint\": string or null (which OCR label, if "
        "any, is near this item), \"confidence\": number 0.0-1.0}]}. "
        "Do not invent items that aren't actually drawn; if you're unsure of an item's exact "
        "type, still report it with a lower confidence rather than omitting it."
    )


def identify_subcomponents_via_mistral(
    rgb: np.ndarray, api_key: str, ocr_labels: list[str],
    model: str = MISTRAL_DIMENSION_MODEL, max_tokens: int = 2000,
) -> list[dict]:
    """Mistral vision identification of furniture/fixture/staircase
    subcomponents, with OCR label hints. Returns a list of
    {type, label, positionFraction, sourceHint, confidence} dicts —
    positionFraction is converted to pixel coordinates and resolved to the
    nearest wall(s) by geometric_model.attach_subcomponents(), not here,
    keeping this function a pure vision call with no geometry dependency."""
    prompt = subcomponent_prompt(ocr_labels)
    for attempt in range(2):
        attempt_prompt = prompt
        if attempt:
            attempt_prompt = prompt + (
                " Your previous reply was cut off or invalid. Return a SHORTER, complete "
                "JSON object — fewer subcomponents if needed, but valid JSON."
            )
        try:
            text = _mistral_request(
                api_key, model, rgb, attempt_prompt, max_tokens, {"type": "json_object"})
            parsed = json.loads(text or "{}")
            items = parsed.get("subcomponents", [])
            return [item for item in items if isinstance(item, dict) and item.get("type")]
        except urllib.error.HTTPError as exc:
            if attempt == 0:
                continue
            _, message = _provider_error_details(exc)
            suffix = f": {message}" if message else ""
            raise RuntimeError(f"Mistral request failed ({exc.code}){suffix}") from exc
        except json.JSONDecodeError:
            if attempt == 0:
                continue
            raise RuntimeError("Mistral request failed: reply was not valid JSON after retry")
    raise RuntimeError("Mistral request failed after retry")


def opening_prompt(ocr_labels: list[str]) -> str:
    """Door/window identification, as a cross-check for the deterministic
    CV opening detector (openings.py) rather than a replacement for it.

    That detector reads real pixel geometry off the traced wall network
    (swing-arc fitting for doors, hollow-run analysis for windows), which
    this vision read can never match for precision — but it depends on the
    traced wall list being clean enough to search, and on the drawing's own
    line-weight convention actually making a wall thicker than a dimension
    hairline. Both assumptions can fail on a real plan (a densely-fragmented
    wall network, or a thin-outline drawing style where every line is the
    same weight) in ways no CV threshold reliably self-corrects for — this
    is exactly the kind of visual pattern read a vision model does natively
    ("python can't see"; a human glancing at the drawing does this
    instantly). Used only to check *coverage* (is a door/window symbol
    visibly present that the deterministic pass missed or double-counted),
    never to report a width — see attach_openings() and its reconciliation
    caller for how a vision-only find is kept distinct from a measured one.
    """
    labels_line = ", ".join(f'"{l}"' for l in ocr_labels) if ocr_labels else "(none read)"
    return (
        "This is an architectural floor plan drawing. Identify every DOOR and WINDOW "
        "symbol you can see drawn on it. A door is a quarter-circle swing arc plus a "
        "straight leaf line, set into a wall opening. A window is a short hollow/hatched "
        "box or a gap with tick marks, set into an exterior (sometimes interior) wall band "
        "— it never has a swing arc. Count each individually even if several are drawn "
        "close together (e.g. a row of windows on one wall) or if a door/window style "
        "repeats identically around the building. "
        f"Text already read off this drawing by OCR (room names, labels): {labels_line}. "
        "Use these only as context for where rooms are, not as opening evidence. "
        "Return JSON only: {\"openings\": [{\"kind\": \"door\" or \"window\", "
        "\"positionFraction\": [x, y] (this opening's approximate center, as a fraction "
        "0.0-1.0 of the image width and height), \"confidence\": number 0.0-1.0}]}. "
        "Do not invent openings that aren't actually drawn; do not count a plain wall "
        "corner, a furniture edge, or a dimension tick mark as an opening."
    )


def identify_openings_via_mistral(
    rgb: np.ndarray, api_key: str, ocr_labels: list[str],
    model: str = MISTRAL_DIMENSION_MODEL, max_tokens: int = 2000,
) -> list[dict]:
    """Mistral vision identification of door/window symbols, as a coverage
    cross-check for the deterministic CV opening detector. Returns a list of
    {kind, positionFraction, confidence} dicts — positionFraction is
    resolved to pixel coordinates and the nearest wall by
    geometric_model.attach_openings(), not here, keeping this a pure vision
    call with no geometry dependency (same split as
    identify_subcomponents_via_mistral)."""
    prompt = opening_prompt(ocr_labels)
    for attempt in range(2):
        attempt_prompt = prompt
        if attempt:
            attempt_prompt = prompt + (
                " Your previous reply was cut off or invalid. Return a SHORTER, complete "
                "JSON object — fewer openings listed if needed, but valid JSON."
            )
        try:
            text = _mistral_request(
                api_key, model, rgb, attempt_prompt, max_tokens, {"type": "json_object"})
            parsed = json.loads(text or "{}")
            items = parsed.get("openings", [])
            return [
                item for item in items
                if isinstance(item, dict) and item.get("kind") in ("door", "window")
            ]
        except urllib.error.HTTPError as exc:
            if attempt == 0:
                continue
            _, message = _provider_error_details(exc)
            suffix = f": {message}" if message else ""
            raise RuntimeError(f"Mistral request failed ({exc.code}){suffix}") from exc
        except json.JSONDecodeError:
            if attempt == 0:
                continue
            raise RuntimeError("Mistral request failed: reply was not valid JSON after retry")
    raise RuntimeError("Mistral request failed after retry")


def _bounded_confidence(value) -> float:
    try:
        return max(0.0, min(float(value), 1.0))
    except (TypeError, ValueError):
        return 0.0


def _provider_error_message(error: urllib.error.HTTPError) -> str:
    """Return only Groq's bounded error message/code, never headers or keys."""
    _, message = _provider_error_details(error)
    return message


def _provider_error_details(error: urllib.error.HTTPError) -> tuple[str, str]:
    """Return Groq's bounded error code and display message."""
    try:
        payload = json.loads(error.read(4096).decode("utf-8", errors="replace"))
        detail = payload.get("error", payload) if isinstance(payload, dict) else {}
        if not isinstance(detail, dict):
            return "", ""
        message = str(detail.get("message", ""))[:500]
        code = str(detail.get("code", ""))[:100]
        display = f"{code}: {message}" if code and code not in message else message
        return code, display
    except (OSError, UnicodeError, json.JSONDecodeError):
        return "", ""


def apply_guidance(
    model: FloorplanModel,
    proposals: dict,
    audit: GuidanceAudit | None = None,
    min_confidence: float = 0.75,
) -> FloorplanModel:
    audit = audit or GuidanceAudit()
    width, height = model.image_size

    def point(value):
        if not isinstance(value, (list, tuple)) or len(value) != 2:
            return None
        x, y = float(value[0]), float(value[1])
        return (x, y) if 0 <= x <= width and 0 <= y <= height else None

    for raw in list(proposals.get("add_walls") or [])[:64]:
        try:
            a, b = point(raw.get("start")), point(raw.get("end"))
            conf = float(raw.get("confidence", 0))
            thick = max(2.0, min(float(raw.get("thickness", 8)), 80.0))
            if not a or not b or conf < min_confidence:
                raise ValueError("low confidence or invalid coordinates")
            if abs(a[0] - b[0]) <= 3:
                x = (a[0] + b[0]) / 2
                a, b = (x, a[1]), (x, b[1])
            elif abs(a[1] - b[1]) <= 3:
                y = (a[1] + b[1]) / 2
                a, b = (a[0], y), (b[0], y)
            else:
                raise ValueError("wall is not axis-aligned")
            if np.hypot(b[0] - a[0], b[1] - a[1]) < 8:
                raise ValueError("wall is too short")
            if any(_same_segment(a, b, w.start, w.end, 6) for w in model.walls):
                raise ValueError("duplicate wall")
            item = Wall(id=f"wall_{len(model.walls)}", start=a, end=b, thickness_mm=thick)
            model.walls.append(item)
            audit.accepted.append({"kind": "wall", "id": item.id, "confidence": conf})
        except (TypeError, ValueError) as exc:
            audit.rejected.append({"kind": "wall", "proposal": raw, "reason": str(exc)})

    for key, cls, target in (("add_doors", Door, model.doors), ("add_windows", Window, model.windows)):
        for raw in list(proposals.get(key) or [])[:32]:
            try:
                center = point(raw.get("center"))
                conf = float(raw.get("confidence", 0))
                size = float(raw.get("width", 0))
                if not center or conf < min_confidence or not 4 <= size <= max(width, height) / 2:
                    raise ValueError("low confidence or invalid opening")
                common = {"id": f"{'door' if cls is Door else 'window'}_{len(target)}", "wall_id": None,
                          "width_mm": size, "center": center}
                item = cls(**common)
                target.append(item)
                audit.accepted.append({"kind": "door" if cls is Door else "window", "id": item.id,
                                       "confidence": conf})
            except (TypeError, ValueError) as exc:
                audit.rejected.append({"kind": key, "proposal": raw, "reason": str(exc)})

    rooms = {room.id: room for room in model.rooms}
    for raw in list(proposals.get("room_labels") or [])[:64]:
        room = rooms.get(str(raw.get("room_id", "")))
        conf = float(raw.get("confidence", 0))
        if room and conf >= min_confidence:
            room.label = str(raw.get("label", ""))[:80] or room.label
            room.type = str(raw.get("type", room.type))[:40].upper()
            audit.accepted.append({"kind": "room_label", "id": room.id, "confidence": conf})
        else:
            audit.rejected.append({"kind": "room_label", "proposal": raw, "reason": "unknown room or low confidence"})
    return model


def _same_segment(a, b, c, d, tolerance: float) -> bool:
    direct = np.hypot(a[0] - c[0], a[1] - c[1]) + np.hypot(b[0] - d[0], b[1] - d[1])
    reverse = np.hypot(a[0] - d[0], a[1] - d[1]) + np.hypot(b[0] - c[0], b[1] - c[1])
    return min(direct, reverse) <= tolerance * 2
