import numpy as np

from floorplan2dxf.correction import apply_corrections, constrain_geometry_to_spec
from floorplan2dxf.geometry import CvGeometry
from floorplan2dxf.guidance import review_against_spec
from floorplan2dxf.schema import FloorplanModel, Room, Wall


def test_pixel_gate_removes_unsupported_wall_and_adds_supported_wall():
    rgb = np.full((100, 100, 3), 255, dtype=np.uint8)
    rgb[5:96, 48:53] = 0
    model = FloorplanModel(
        image_size=(100, 100),
        walls=[Wall("fake", (10, 20), (90, 20), 5)],
    )
    accepted, rejected = [], []
    apply_corrections(rgb, model, {
        "remove_walls": [{"wall_id": "fake", "confidence": 0.98}],
        "add_walls": [{"start": [50, 5], "end": [50, 95], "thickness": 5, "confidence": 0.99}],
    }, accepted, rejected)

    assert all(wall.id != "fake" for wall in model.walls)
    assert len(model.walls) == 1
    assert model.walls[0].start[0] == model.walls[0].end[0] == 50
    assert {item["kind"] for item in accepted} == {"remove_wall", "add_wall"}


def test_vision_spec_labels_walls_without_discarding_traced_geometry():
    outline = Wall("outline", (0, 0), (99, 0), 8, quad=[(0, 0), (99, 0), (99, 99), (0, 99)])
    divider = Wall("divider", (50, 0), (50, 99), 5)
    furniture_line = Wall("noise", (10, 25), (40, 25), 3)
    left = Room("left", "UNDEFINED", [(2, 2), (48, 2), (48, 98), (2, 98)])
    right = Room("right", "UNDEFINED", [(52, 2), (98, 2), (98, 98), (52, 98)])
    geometry = CvGeometry(walls=[outline, divider, furniture_line], rooms=[left, right])

    audit = constrain_geometry_to_spec(geometry, {
        "status": "usable", "confidence": 0.95,
        "major_walls": [{
            "orientation": "vertical", "start": [50, 0], "end": [50, 99],
            "kind": "internal", "confidence": 0.96,
        }],
        "spaces": [
            {"label": "Bedroom", "type": "BEDROOM", "center": [25, 50], "confidence": 0.9},
            {"label": "Kitchen", "type": "KITCHEN", "center": [75, 50], "confidence": 0.9},
        ],
    }, (100, 100))

    assert audit["applied"] is True
    # Non-destructive: every traced wall is preserved, never suppressed by an
    # unmatched vision spec (that collapse was the deployed floor-plan bug).
    assert {wall.id for wall in geometry.walls} == {"outline", "divider", "noise"}
    assert audit["matchedWalls"] == 1
    # The matched wall is only labeled, not moved or replaced.
    assert next(w for w in geometry.walls if w.id == "divider").wall_type == "internal"
    # Deterministic rooms are relabeled in place, not dropped.
    assert [(room.label, room.type) for room in geometry.rooms] == [
        ("Bedroom", "BEDROOM"), ("Kitchen", "KITCHEN"),
    ]


def test_single_vision_spec_approves_matching_python_topology_and_flags_mismatch():
    model = FloorplanModel(
        image_size=(100, 100),
        walls=[Wall("divider", (50, 0), (50, 99), 5)],
        rooms=[Room("office", "OFFICE", [(0, 0), (49, 0), (49, 99), (0, 99)])],
    )
    spec = {
        "status": "usable", "confidence": 0.9,
        "major_walls": [{"start": [50, 0], "end": [50, 99], "confidence": 0.95}],
        "spaces": [{"label": "Office", "center": [25, 50], "confidence": 0.9}],
    }
    approved = review_against_spec(spec, model)["review"]
    assert approved["status"] == "approved"
    assert approved["summary"].startswith("Matched 2/2")
    spec["major_walls"].append({"start": [10, 0], "end": [10, 99], "confidence": 0.95})
    spec["spaces"].append({"label": "Lobby", "center": [90, 50], "confidence": 0.9})
    mismatch = review_against_spec(spec, model)["review"]
    assert mismatch["status"] == "needs_correction"
    assert len(mismatch["discrepancies"]) == 2


def test_external_walls_must_form_one_closed_perimeter():
    model = FloorplanModel(
        image_size=(100, 100),
        walls=[
            Wall("top", (10, 10), (90, 10), 5),
            Wall("right", (90, 10), (90, 90), 5),
            Wall("bottom", (90, 90), (10, 90), 5),
        ],
    )
    spec = {
        "status": "usable", "confidence": 0.95,
        "major_walls": [
            {"start": [10, 10], "end": [90, 10], "kind": "external", "confidence": 0.95},
            {"start": [90, 10], "end": [90, 90], "kind": "external", "confidence": 0.95},
            {"start": [90, 90], "end": [10, 90], "kind": "external", "confidence": 0.95},
            {"start": [10, 90], "end": [10, 10], "kind": "external", "confidence": 0.95},
        ],
    }
    open_review = review_against_spec(spec, model)["review"]
    assert open_review["status"] == "needs_correction"
    assert any(item["kind"] == "open_external_perimeter"
               for item in open_review["discrepancies"])

    model.walls.append(Wall("left", (10, 90), (10, 10), 5))
    assert review_against_spec(spec, model)["review"]["status"] == "approved"
