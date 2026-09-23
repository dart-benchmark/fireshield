"""The compact line format read_dimensions() asks Qwen for, parsed without JSON."""

import floorplan2dxf.guidance as guidance


def _parse(text: str) -> dict:
    dimensions = []
    overall_w = overall_h = 0.0
    for line in text.splitlines():
        match = guidance._DIMENSION_LINE.match(line)
        if match:
            dimensions.append({
                "value_m": float(match.group("value")),
                "orientation": "horizontal" if match.group("axis").upper() == "H" else "vertical",
                "position": [float(match.group("x")), float(match.group("y"))],
            })
            continue
        overall = guidance._OVERALL_LINE.match(line)
        if overall:
            overall_w, overall_h = float(overall.group("w")), float(overall.group("h"))
    return {"dimensions": dimensions, "overall_width_m": overall_w, "overall_height_m": overall_h}


def test_parses_well_formed_lines():
    result = _parse("2.00 H 219 162\n4.00 H 420 162\n8.00 V 68 550\nOVERALL 9.00 11.00\n")
    assert len(result["dimensions"]) == 3
    assert result["dimensions"][0] == {"value_m": 2.0, "orientation": "horizontal", "position": [219.0, 162.0]}
    assert result["dimensions"][2] == {"value_m": 8.0, "orientation": "vertical", "position": [68.0, 550.0]}
    assert result["overall_width_m"] == 9.0
    assert result["overall_height_m"] == 11.0


def test_lowercase_axis_letters_are_accepted():
    result = _parse("3.00 h 610 162\n1.50 v 68 400\n")
    assert result["dimensions"][0]["orientation"] == "horizontal"
    assert result["dimensions"][1]["orientation"] == "vertical"


def test_unparseable_lines_are_skipped_not_fatal():
    # A model reply is never guaranteed clean — stray prose, a malformed
    # line, or explanatory text must not lose the lines that DID parse.
    text = "2.00 H 219 162\nsome prose the model added by mistake\ngarbled line !! 2.00\n8.00 V 68 550\n"
    result = _parse(text)
    assert len(result["dimensions"]) == 2


def test_no_overall_line_defaults_to_zero_not_a_guess():
    result = _parse("2.00 H 219 162\n")
    assert result["overall_width_m"] == 0.0
    assert result["overall_height_m"] == 0.0


def test_empty_reply_yields_empty_result_not_an_error():
    result = _parse("")
    assert result == {"dimensions": [], "overall_width_m": 0.0, "overall_height_m": 0.0}
