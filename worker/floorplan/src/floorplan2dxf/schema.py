"""Semantic floor-plan objects. This is the contract the later app consumes."""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import Any, Literal, Optional


Point = tuple[float, float]

ROOM_CLASS_NAMES = {
    0: "BACKGROUND",
    1: "OUTDOOR",
    2: "WALL",
    3: "KITCHEN",
    4: "LIVING_ROOM",
    5: "BEDROOM",
    6: "BATH",
    7: "ENTRY",
    8: "RAILING",
    9: "STORAGE",
    10: "GARAGE",
    11: "UNDEFINED",
}

ICON_CLASS_NAMES = {
    0: "NO_ICON",
    1: "WINDOW",
    2: "DOOR",
    3: "CLOSET",
    4: "ELECTRICAL",
    5: "TOILET",
    6: "SINK",
    7: "SAUNA_BENCH",
    8: "FIRE_PLACE",
    9: "BATHTUB",
    10: "CHIMNEY",
}

LABEL_TO_ROOM_TYPE = {
    "bedroom": "BEDROOM",
    "bed room": "BEDROOM",
    "bed": "BEDROOM",
    "kitchen": "KITCHEN",
    "living": "LIVING_ROOM",
    "living room": "LIVING_ROOM",
    "family": "LIVING_ROOM",
    "family room": "LIVING_ROOM",
    "dining": "DINING",
    "dinning": "DINING",
    "dining area": "DINING",
    "master": "BEDROOM",
    "master bedroom": "BEDROOM",
    "closet": "STORAGE",
    "washroom": "BATH",
    "laundry": "STORAGE",
    "drawing": "LIVING_ROOM",
    "lounge": "LIVING_ROOM",
    "bath": "BATH",
    "bathroom": "BATH",
    "toilet": "BATH",
    "wc": "BATH",
    "entry": "ENTRY",
    "foyer": "ENTRY",
    "lobby": "ENTRY",
    "storage": "STORAGE",
    "store": "STORAGE",
    "garage": "GARAGE",
    "balcony": "OUTDOOR",
    "terrace": "OUTDOOR",
    "lift": "LIFT",
    "elevator": "LIFT",
    "shaft": "SHAFT",
    "staircase": "STAIR",
    "stair": "STAIR",
    "stairs": "STAIR",
}


@dataclass
class Wall:
    id: str
    start: Point
    end: Point
    thickness_mm: float
    kind: Literal["wall", "railing"] = "wall"
    wall_type: Literal["external", "internal", "unknown", "thin_candidate", "thick_candidate"] = "unknown"
    quad: list[Point] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class Door:
    id: str
    wall_id: Optional[str]
    width_mm: float
    center: Point
    swing: Literal["clockwise", "counterclockwise", "unknown"] = "unknown"
    quad: list[Point] = field(default_factory=list)
    connects: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class Window:
    id: str
    wall_id: Optional[str]
    width_mm: float
    center: Point
    quad: list[Point] = field(default_factory=list)
    room_id: Optional[str] = None

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class Furniture:
    id: str
    kind: str
    quad: list[Point] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class Room:
    id: str
    type: str
    boundary: list[Point]
    label: Optional[str] = None
    dimension_text: Optional[str] = None
    door_ids: list[str] = field(default_factory=list)
    window_ids: list[str] = field(default_factory=list)
    adjacent_room_ids: list[str] = field(default_factory=list)
    area_m2: Optional[float] = None

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class ArchitecturalObject:
    id: str
    kind: str
    category: Literal["structural", "circulation", "safety", "other"] = "other"
    boundary: list[Point] = field(default_factory=list)
    room_id: Optional[str] = None
    level_id: str = "level_0"

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class VectorTrace:
    id: str
    points: list[Point]
    closed: bool = False
    line_class: Literal["thin", "thick"] = "thin"

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class RoomConnection:
    id: str
    from_room_id: str
    to_room_id: str
    via_type: Literal["door", "opening"] = "door"
    via_id: Optional[str] = None

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class TextItem:
    content: str
    position: Point
    kind: Literal["label", "dimension", "other"]
    bbox: list[Point] = field(default_factory=list)
    confidence: float = 0.0
    parsed_mm: Optional[tuple[float, float]] = None

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class FloorplanModel:
    walls: list[Wall] = field(default_factory=list)
    doors: list[Door] = field(default_factory=list)
    windows: list[Window] = field(default_factory=list)
    rooms: list[Room] = field(default_factory=list)
    texts: list[TextItem] = field(default_factory=list)
    furniture: list[Furniture] = field(default_factory=list)
    objects: list[ArchitecturalObject] = field(default_factory=list)
    traces: list[VectorTrace] = field(default_factory=list)
    connections: list[RoomConnection] = field(default_factory=list)
    exterior_boundary: list[Point] = field(default_factory=list)
    level_id: str = "level_0"
    units: Literal["mm", "px"] = "px"
    mm_per_px: Optional[float] = None
    image_size: tuple[int, int] = (0, 0)

    def to_dict(self) -> dict[str, Any]:
        return {
            "units": self.units,
            "mm_per_px": self.mm_per_px,
            "image_size": list(self.image_size),
            "walls": [w.to_dict() for w in self.walls],
            "doors": [d.to_dict() for d in self.doors],
            "windows": [w.to_dict() for w in self.windows],
            "rooms": [r.to_dict() for r in self.rooms],
            "texts": [t.to_dict() for t in self.texts],
            "furniture": [f.to_dict() for f in self.furniture],
            "objects": [o.to_dict() for o in self.objects],
            "traces": [trace.to_dict() for trace in self.traces],
            "exterior_boundary": self.exterior_boundary,
            "room_graph": {
                "outside_node": "outside",
                "nodes": [{"id": r.id, "type": r.type, "label": r.label} for r in self.rooms],
                "edges": [c.to_dict() for c in self.connections],
            },
        }
