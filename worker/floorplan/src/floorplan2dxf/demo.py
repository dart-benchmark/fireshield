"""Write a semantic bedroom DXF without the neural net — proves the CAD contract."""

from __future__ import annotations

import json
from pathlib import Path

from .export_dxf import write_dxf
from .schema import Door, FloorplanModel, Room, TextItem, Wall


def bedroom_example() -> FloorplanModel:
    # 10'10" x 10'0" bedroom in millimetres: 3302 x 3048
    w, h, t = 3302.0, 3048.0, 230.0
    return FloorplanModel(
        walls=[
            Wall(id="wall_0", start=(0, 0), end=(w, 0), thickness_mm=t, quad=[(0, -t / 2), (w, -t / 2), (w, t / 2), (0, t / 2)]),
            Wall(id="wall_1", start=(w, 0), end=(w, h), thickness_mm=t, quad=[(w - t / 2, 0), (w + t / 2, 0), (w + t / 2, h), (w - t / 2, h)]),
            Wall(id="wall_2", start=(w, h), end=(0, h), thickness_mm=t, quad=[(w, h - t / 2), (w, h + t / 2), (0, h + t / 2), (0, h - t / 2)]),
            Wall(id="wall_3", start=(0, h), end=(0, 0), thickness_mm=t, quad=[(-t / 2, h), (t / 2, h), (t / 2, 0), (-t / 2, 0)]),
        ],
        doors=[
            Door(
                id="door_0",
                wall_id="wall_1",
                width_mm=900,
                center=(w, h / 2),
                swing="clockwise",
                quad=[(w - t / 2, h / 2 - 450), (w + t / 2, h / 2 - 450), (w + t / 2, h / 2 + 450), (w - t / 2, h / 2 + 450)],
            )
        ],
        rooms=[
            Room(
                id="room_0",
                type="BEDROOM",
                boundary=[(0, 0), (w, 0), (w, h), (0, h)],
                label="bedroom",
                dimension_text="10'10\"x10'0\"",
            )
        ],
        texts=[
            TextItem(content="bedroom", position=(w / 2, h / 2 + 200), kind="label"),
            TextItem(content="10'10\"x10'0\"", position=(w / 2, h / 2 - 200), kind="dimension", parsed_mm=(w, h)),
        ],
        units="mm",
        mm_per_px=1.0,
        image_size=(int(w), int(h)),
    )


def write_demo(out_dir: str | Path = "out") -> tuple[Path, Path]:
    out_dir = Path(out_dir)
    model = bedroom_example()
    dxf = write_dxf(model, out_dir / "demo_bedroom.dxf")
    payload = out_dir / "demo_bedroom.json"
    payload.write_text(json.dumps(model.to_dict(), indent=2), encoding="utf-8")
    return dxf, payload
