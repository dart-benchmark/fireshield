from floorplan2dxf.commercial_model import SCHEMA_VERSION, build_commercial_model
from floorplan2dxf.schema import FloorplanModel, Room, Wall


def test_commercial_model_keeps_semantics_geometry_and_unknowns_separate():
    model = FloorplanModel(
        image_size=(200, 100), units="px",
        walls=[Wall("wall_0", (0, 0), (200, 0), 8, wall_type="unknown")],
        rooms=[Room("space_0", "CORRIDOR", [(0, 0), (100, 0), (100, 50), (0, 50)], label="C-01")],
        exterior_boundary=[(0, 0), (200, 0), (200, 100), (0, 100)],
    )
    payload = build_commercial_model(
        model,
        building_profile={"building": "Office Tower", "occupancy": "Business", "floors": 12},
        plan_spec={
            "grid": {"x": [0, 100, 200], "y": [0, 100]},
            "elements": [{"id": "ST-1", "kind": "fire_stair", "category": "circulation",
                          "label": "FIRE STAIR", "center": [150, 50],
                          "bbox": [130, 20, 180, 80], "confidence": 0.9}],
        },
        guidance_audit={"review_status": "approved"},
    )
    assert payload["schemaVersion"] == SCHEMA_VERSION
    assert payload["building"]["occupancy"] == "Business"
    assert payload["floor"]["spaces"][0]["type"] == "CORRIDOR"
    assert payload["floor"]["circulation"]["stairs"][0]["evidence"]["status"] == "candidate"
    assert payload["floor"]["structure"]["walls"][0]["fireRatingMinutes"] is None
    assert payload["evidence"]["finalReviewStatus"] == "approved"
