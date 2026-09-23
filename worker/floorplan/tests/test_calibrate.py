from floorplan2dxf.calibrate import calibrate_from_wall_dimensions, standalone_lengths_mm
from floorplan2dxf.schema import TextItem, Wall


def _text(content: str) -> TextItem:
    return TextItem(content=content, position=(0, 0), kind="other")


def test_metric_plan_bare_overall_dimensions_are_inferred_as_metres():
    values = standalone_lengths_mm([
        _text("GROUND FLOOR PLAN"), _text("SCALE 1:100 MTS."),
        _text("9.00"), _text("11.00"),
    ])
    assert values == [9000.0, 11000.0]


def test_bare_values_without_metric_plan_context_are_not_assumed():
    assert standalone_lengths_mm([_text("9.00"), _text("11.00")]) == []


def test_dimensions_snap_to_matching_wall_segments_and_median_scale():
    # Top run split into three collinear segments, matching separate printed
    # dimension labels (as on a real drawing: 2.00 / 4.00 / 3.00 along one wall
    # run). Left wall is the vertical 8.00m run. True scale is 10 mm/px.
    walls = [
        Wall(id="w0", start=(0, 50), end=(200, 50), thickness_mm=100),
        Wall(id="w1", start=(200, 50), end=(600, 50), thickness_mm=100),
        Wall(id="w2", start=(600, 50), end=(900, 50), thickness_mm=100),
        Wall(id="w3", start=(0, 50), end=(0, 850), thickness_mm=100),
    ]
    dimensions = [
        {"value_m": 2.00, "orientation": "horizontal", "position": [100, 40]},
        {"value_m": 4.00, "orientation": "horizontal", "position": [400, 40]},
        {"value_m": 3.00, "orientation": "horizontal", "position": [750, 40]},
        {"value_m": 8.00, "orientation": "vertical", "position": [-10, 450]},
    ]
    scale = calibrate_from_wall_dimensions(dimensions, walls, proximity_px=30)
    assert scale == 10.0


def test_a_single_misread_label_does_not_wreck_the_median():
    walls = [
        Wall(id="w0", start=(0, 50), end=(200, 50), thickness_mm=100),
        Wall(id="w1", start=(200, 50), end=(600, 50), thickness_mm=100),
        Wall(id="w2", start=(600, 50), end=(900, 50), thickness_mm=100),
    ]
    dimensions = [
        {"value_m": 2.00, "orientation": "horizontal", "position": [100, 40]},
        {"value_m": 4.00, "orientation": "horizontal", "position": [400, 40]},
        # Badly misread label (should be 3.00m -> 300px @10mm/px, model said 30m).
        {"value_m": 30.0, "orientation": "horizontal", "position": [750, 40]},
    ]
    scale = calibrate_from_wall_dimensions(dimensions, walls, proximity_px=30)
    assert scale == 10.0


def test_returns_none_when_fewer_than_two_dimensions_match():
    walls = [Wall(id="w0", start=(0, 50), end=(200, 50), thickness_mm=100)]
    dimensions = [{"value_m": 2.00, "orientation": "horizontal", "position": [100, 40]}]
    assert calibrate_from_wall_dimensions(dimensions, walls, proximity_px=30) is None


def test_ignores_labels_with_no_geometrically_nearby_wall():
    walls = [Wall(id="w0", start=(0, 50), end=(200, 50), thickness_mm=100)]
    dimensions = [
        {"value_m": 2.00, "orientation": "horizontal", "position": [100, 40]},
        {"value_m": 5.00, "orientation": "horizontal", "position": [5000, 40]},
    ]
    assert calibrate_from_wall_dimensions(dimensions, walls, proximity_px=30) is None
