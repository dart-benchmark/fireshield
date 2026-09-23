"""Tests for geometric_model.py — the wall-intersection graph, dimension-to-
wall resolution, and text-label output ported from symbol_lab (a standalone
research activity; see worker/floorplan/symbol_lab/README.md for the design
history and the two real coordinate-space bugs it caught before this ported
into the real package).
"""
from floorplan2dxf.geometric_model import attach_openings, attach_subcomponents, build_geometric_model
from floorplan2dxf.geometry import CvGeometry
from floorplan2dxf.schema import TextItem, Wall


def _wall(id_, start, end, thickness=8.0):
    return Wall(id=id_, start=start, end=end, thickness_mm=thickness)


def _text(content, position, kind="other", bbox=None):
    bbox = bbox or [(position[0] - 10, position[1] - 6), (position[0] + 10, position[1] - 6),
                     (position[0] + 10, position[1] + 6), (position[0] - 10, position[1] + 6)]
    return TextItem(content=content, position=position, kind=kind, bbox=bbox, confidence=1.0)


def test_build_geometric_model_assigns_walls_intersections_and_dimensions():
    walls = [
        _wall("wall_0", (0.0, 0.0), (100.0, 0.0)),
        _wall("wall_1", (100.0, 0.0), (100.0, 100.0)),
    ]
    cv_geom = CvGeometry(walls=walls, rooms=[], envelope=(0, 0, 100, 100), bars=[], traces=[])
    texts = [
        _text("2.00", (50.0, 12.0)),  # near the middle of wall_0, offset in y
        _text("KITCHEN", (30, 40), kind="label"),
    ]

    model = build_geometric_model(cv_geom, texts, image_size=(200, 200), mm_per_px=10.0)

    wall_ids = {w["id"] for w in model["walls"]}
    assert wall_ids == {"wall_0", "wall_1"}
    # The two walls share an endpoint at (100, 0) -> one corner intersection.
    assert len(model["wallIntersections"]) == 1
    assert model["wallIntersections"][0]["kind"] == "corner"
    # "2.00" sits much closer to wall_0 (12px away) than wall_1 (~60px away).
    dims = model["dimensions"]
    assert len(dims) == 1
    assert dims[0]["resolved"] is True
    assert dims[0]["wallId"] == "wall_0"
    assert dims[0]["value"] == 2.0
    # mm annotation present since mm_per_px was supplied.
    assert dims[0]["position"]["mm"] is not None


def test_build_geometric_model_works_without_scale():
    """Per user direction: relative positioning (wall graph, dimension
    resolution) must not depend on scale calibration succeeding — pixel
    space is the foundation, mm is an optional layer on top."""
    walls = [_wall("wall_0", (0.0, 0.0), (50.0, 0.0))]
    cv_geom = CvGeometry(walls=walls, rooms=[], envelope=(0, 0, 50, 50), bars=[], traces=[])
    texts = [_text("3.00", (25.0, 8.0))]

    model = build_geometric_model(cv_geom, texts, image_size=(100, 100), mm_per_px=None)

    assert model["gridCellSizeMm"] is None
    assert len(model["walls"]) == 1
    assert "lengthMm" not in model["walls"][0]  # no mm annotation without scale
    assert model["dimensions"][0]["wallId"] == "wall_0"
    assert "mm" not in model["dimensions"][0]["position"]


def test_bedroom_number_is_not_read_as_a_dimension():
    """"BEDROOM" + "1" must merge into one label, not have the bare "1" read
    as a 1-metre measurement against whatever wall happens to be nearby.
    Image size and token positions here are the actual measured values from
    test3.jpg (736x1076, "BEDROOM" at (150.5, 541.0), "1" at (198.0, 541.5)
    -> ~47.5px apart) where this exact case was live-verified — a smaller
    synthetic image makes the derived grid cell too small for a fair test of
    the adjacency radius."""
    walls = [_wall("wall_0", (0.0, 0.0), (700.0, 0.0))]
    cv_geom = CvGeometry(walls=walls, rooms=[], envelope=(0, 0, 700, 1000), bars=[], traces=[])
    texts = [
        _text("BEDROOM", (150.5, 541.0), kind="label"),
        _text("1", (198.0, 541.5)),  # right next to "BEDROOM" — part of the label, not a dimension
    ]

    model = build_geometric_model(cv_geom, texts, image_size=(736, 1076), mm_per_px=None)

    assert model["dimensions"] == []
    assert any(t["text"] == "BEDROOM 1" for t in model["textLabels"])


def test_attach_subcomponents_resolves_position_fraction_and_adjacent_walls():
    model = {
        "walls": [
            {"id": "wall_11", "start": {"px": [0.0, 0.0]}, "end": {"px": [0.0, 100.0]}, "thicknessMm": 8.0},
            {"id": "wall_28", "start": {"px": [0.0, 0.0]}, "end": {"px": [100.0, 0.0]}, "thicknessMm": 8.0},
        ],
    }
    subcomponents = [
        {"type": "staircase", "label": "Staircase", "confidence": 0.95,
         "sourceHint": "uP", "positionFraction": [0.02, 0.02]},  # near the (0,0) corner -> both walls
        {"type": "dining_table", "label": "Dining table", "confidence": 0.9,
         "sourceHint": "DINING AREA", "positionFraction": [0.5, 0.5]},  # far from both walls
    ]

    attach_subcomponents(model, subcomponents, image_size_px=(200, 200), mm_per_px=None)

    resolved = {s["type"]: s for s in model["subcomponents"]}
    assert "wall_11" in resolved["staircase"]["adjacentWallIds"]
    assert "wall_28" in resolved["staircase"]["adjacentWallIds"]
    assert resolved["dining_table"]["adjacentWallIds"] == []
    assert resolved["staircase"]["position"]["px"] == [4.0, 4.0]


def test_attach_openings_confirms_a_match_and_flags_a_geometry_miss():
    """A vision-identified opening near an already-traced one of the same
    kind is confirmed; one with nothing nearby is flagged as likely missed
    by the deterministic CV pass — the signal the compliance reasoning step
    uses to treat opening count as a floor, not a ceiling, without this
    module ever inventing a width for the unconfirmed one."""
    model = {
        "walls": [{"id": "wall_0", "start": {"px": [0.0, 0.0]}, "end": {"px": [200.0, 0.0]}, "thicknessMm": 8.0}],
    }
    deterministic_doors = [{"center": [50.0, 2.0]}]
    deterministic_windows = []
    mistral_openings = [
        {"kind": "door", "positionFraction": [0.25, 0.01], "confidence": 0.9},  # near the traced door
        {"kind": "window", "positionFraction": [0.75, 0.01], "confidence": 0.8},  # no traced window at all
    ]

    attach_openings(
        model, mistral_openings, image_size_px=(200, 100), mm_per_px=None,
        deterministic_doors=deterministic_doors, deterministic_windows=deterministic_windows,
    )

    by_kind = {o["kind"]: o for o in model["openings"]}
    assert by_kind["door"]["confirmedByGeometry"] is True
    assert by_kind["window"]["confirmedByGeometry"] is False
    assert by_kind["door"]["nearestWallId"] == "wall_0"


def test_attach_openings_undoes_apply_scale_before_comparing():
    """`deterministic_doors`/`deterministic_windows` are read off
    `result.model` AFTER pipeline.convert() has already run apply_scale() —
    which converts every coordinate to mm and flips Y for CAD export (see
    reconstruct.apply_scale). Mistral's positionFraction is still raw pixel
    space. Live-confirmed regression: without undoing that transform here,
    EVERY comparison came out "far" (comparing mm distances against a
    pixel-space match radius), so a real, correctly-traced door a few px
    from a vision hit was reported as missed. mm_per_px=10, image 200x100px
    -> a door genuinely at pixel (50, 2) is stored post-scale as
    ((50*10), (100-2)*10) = (500.0, 980.0)."""
    model = {
        "walls": [{"id": "wall_0", "start": {"px": [0.0, 0.0]}, "end": {"px": [200.0, 0.0]}, "thicknessMm": 8.0}],
    }
    deterministic_doors = [{"center": [500.0, 980.0]}]  # (50, 2)px scaled to mm and Y-flipped
    mistral_openings = [
        {"kind": "door", "positionFraction": [0.25, 0.01], "confidence": 0.9},  # same real spot, in px fraction
    ]

    attach_openings(
        model, mistral_openings, image_size_px=(200, 100), mm_per_px=10.0,
        deterministic_doors=deterministic_doors, deterministic_windows=[],
    )

    assert model["openings"][0]["confirmedByGeometry"] is True
