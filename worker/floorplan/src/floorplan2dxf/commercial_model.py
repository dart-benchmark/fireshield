"""Commercial floor-plan JSON assembled from verified geometry and labelled candidates."""

from __future__ import annotations

from typing import Any

from .schema import FloorplanModel


SCHEMA_VERSION = "fireshield-commercial-floorplan-1.0"


def build_commercial_model(model: FloorplanModel, building_profile: dict | None = None,
                           plan_spec: dict | None = None,
                           guidance_audit: dict | None = None) -> dict[str, Any]:
    profile = building_profile or {}
    spec = plan_spec or {}
    audit = guidance_audit or {}
    elements = [_spec_element(item, model) for item in list(spec.get("elements") or [])[:200]]
    elements = [item for item in elements if item is not None]
    measured_area = sum(room.area_m2 or 0 for room in model.rooms)
    supplied_area = profile.get("floorAreaM2")
    floor_area = supplied_area if supplied_area else (
        round(measured_area, 2) if measured_area > 0 else None
    )

    def kinds(*names):
        return [item for item in elements if item["kind"] in names]

    return {
        "schemaVersion": SCHEMA_VERSION,
        "building": {
            "name": profile.get("building"), "occupancy": profile.get("occupancy"),
            "floors": profile.get("floors"), "buildingHeightM": profile.get("buildingHeightM"),
            "floorAreaM2": floor_area,
            "floorAreaSource": "user_provided" if supplied_area else (
                "scaled_geometry" if floor_area is not None else "unavailable"
            ),
            "units": model.units,
        },
        "floor": {
            "id": str(profile.get("level") or model.level_id),
            "boundary": model.exterior_boundary,
            "grid": _grid(spec.get("grid"), model),
            "spaces": [{
                "id": room.id, "name": room.label, "type": room.type,
                "polygon": room.boundary, "areaM2": room.area_m2, "occupancy": None,
                "evidence": {"source": "pixel_geometry", "status": "measured"},
            } for room in model.rooms],
            "structure": {
                "walls": [{
                    "id": wall.id, "start": wall.start, "end": wall.end,
                    "thickness": wall.thickness_mm, "type": wall.wall_type,
                    "fireRatingMinutes": None,
                } for wall in model.walls],
                "columns": kinds("column"), "shearWalls": kinds("shear_wall"),
                "cores": kinds("core"),
            },
            "openings": {
                "doors": [door.to_dict() for door in model.doors],
                "windows": [window.to_dict() for window in model.windows],
            },
            "circulation": {
                "corridors": [room.id for room in model.rooms if room.type.upper() == "CORRIDOR"],
                "stairs": kinds("stair", "fire_stair"), "lifts": kinds("lift", "elevator"),
                "shafts": kinds("shaft"), "exits": kinds("exit", "exit_door"),
                "refugeAreas": kinds("refuge_area"),
            },
            "fireLifeSafety": {
                "compartments": kinds("fire_compartment"),
                "equipment": kinds("extinguisher", "hydrant", "hose_reel", "sprinkler",
                                   "smoke_detector", "heat_detector", "manual_call_point",
                                   "exit_sign", "emergency_light", "fire_command_centre"),
            },
            "mep": {"devices": [item for item in elements if item["category"] == "mep"]},
            "connectivity": {
                "nodes": [{"id": room.id, "type": room.type, "label": room.label}
                          for room in model.rooms],
                "edges": [connection.to_dict() for connection in model.connections],
            },
        },
        "evidence": {
            "visionSpecificationStatus": audit.get("specification_status", "not_run"),
            "visionSpecificationConfidence": audit.get("specification_confidence", 0),
            "initialReviewStatus": audit.get("initial_review_status", "not_run"),
            "finalReviewStatus": audit.get("review_status", "not_run"),
            "correctionStatus": audit.get("correction_status", "not_run"),
            "limitations": [
                "Vision candidates are not proof of fire rating, material, certification or code compliance.",
                "Null properties were not established by the uploaded drawing.",
            ],
        },
    }


def _spec_element(raw: dict, model: FloorplanModel) -> dict | None:
    try:
        confidence = max(0.0, min(float(raw.get("confidence", 0)), 1.0))
        center = _point(raw.get("center"), model)
    except (TypeError, ValueError):
        return None
    if confidence < 0.65 or center is None:
        return None
    bbox = raw.get("bbox")
    polygon = []
    if isinstance(bbox, (list, tuple)) and len(bbox) == 4:
        p0 = _point((bbox[0], bbox[1]), model)
        p1 = _point((bbox[2], bbox[3]), model)
        if p0 and p1:
            polygon = [p0, (p1[0], p0[1]), p1, (p0[0], p1[1])]
    return {
        "id": str(raw.get("id") or "")[:80] or None,
        "kind": str(raw.get("kind") or "other")[:80].lower(),
        "category": str(raw.get("category") or "other")[:40].lower(),
        "label": str(raw.get("label") or "")[:120] or None,
        "center": center, "polygon": polygon, "properties": {},
        "evidence": {"source": "vision_specification", "status": "candidate",
                     "confidence": confidence},
    }


def _grid(raw, model: FloorplanModel) -> dict:
    if not isinstance(raw, dict):
        return {"x": [], "y": [], "status": "not_detected"}
    x_values = [_axis_value(value, model, True) for value in list(raw.get("x") or [])[:80]]
    y_values = [_axis_value(value, model, False) for value in list(raw.get("y") or [])[:80]]
    return {"x": [value for value in x_values if value is not None],
            "y": [value for value in y_values if value is not None],
            "status": "vision_candidate"}


def _axis_value(value, model: FloorplanModel, x_axis: bool):
    try:
        number = float(value)
    except (TypeError, ValueError):
        return None
    width, height = model.image_size
    if x_axis and not 0 <= number <= width:
        return None
    if not x_axis and not 0 <= number <= height:
        return None
    if model.units == "mm" and model.mm_per_px:
        return number * model.mm_per_px if x_axis else (height - number) * model.mm_per_px
    return number


def _point(value, model: FloorplanModel):
    if not isinstance(value, (list, tuple)) or len(value) != 2:
        return None
    x, y = float(value[0]), float(value[1])
    width, height = model.image_size
    if not (0 <= x <= width and 0 <= y <= height):
        return None
    if model.units == "mm" and model.mm_per_px:
        return (x * model.mm_per_px, (height - y) * model.mm_per_px)
    return (x, y)
