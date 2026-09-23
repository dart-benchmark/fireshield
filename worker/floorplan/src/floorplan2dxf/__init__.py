from .schema import Door, FloorplanModel, Room, TextItem, Wall, Window

__all__ = [
    "convert",
    "ConvertResult",
    "FloorplanModel",
    "Wall",
    "Door",
    "Window",
    "Room",
    "TextItem",
]


def convert(*args, **kwargs):
    from .pipeline import convert as _convert

    return _convert(*args, **kwargs)


def __getattr__(name: str):
    if name == "ConvertResult":
        from .pipeline import ConvertResult

        return ConvertResult
    raise AttributeError(name)
