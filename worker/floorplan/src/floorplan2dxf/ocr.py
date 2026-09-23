from __future__ import annotations

import os
from functools import lru_cache
from typing import Optional

import numpy as np

from .calibrate import classify_text, parse_dimension_pair
from .schema import LABEL_TO_ROOM_TYPE, TextItem

#: "tesseract" (default: no PyTorch, no loaded model weights — the runtime
#: memory constraint that disabled EasyOCR on the 512MB Render plan doesn't
#: apply) or "easyocr" (heavier, kept for comparison; needs the ocr-easyocr
#: extra installed).
OCR_BACKEND = os.environ.get("OCR_BACKEND", "tesseract")


def run_ocr(rgb: np.ndarray, enabled: bool = True) -> list[TextItem]:
    if not enabled:
        return []
    reads = _tesseract_reads(rgb) if OCR_BACKEND != "easyocr" else _easyocr_reads(rgb)
    items: list[TextItem] = []
    for box, text, conf in reads:
        content = (text or "").strip()
        if not content:
            continue
        pts = [(float(p[0]), float(p[1])) for p in box]
        cx = sum(p[0] for p in pts) / max(len(pts), 1)
        cy = sum(p[1] for p in pts) / max(len(pts), 1)
        kind = classify_text(content)
        parsed = parse_dimension_pair(content) if kind == "dimension" else None
        items.append(
            TextItem(
                content=content,
                position=(cx, cy),
                kind=kind,  # type: ignore[arg-type]
                bbox=pts,
                confidence=float(conf),
                parsed_mm=parsed,
            )
        )
    return items


def _tesseract_reads(rgb: np.ndarray) -> list[tuple[list[tuple[float, float]], str, float]]:
    """Read text via the Tesseract binary. Returns the same (box, text, conf)
    shape EasyOCR's readtext() does, so run_ocr()'s logic above needs no
    knowledge of which backend produced it.
    """
    import pytesseract

    # PSM 11: sparse text, no assumed layout/reading order — matches a
    # drawing where dimension labels, room labels and titles sit scattered
    # at arbitrary positions rather than in paragraphs.
    config = "--oem 3 --psm 11"
    data = pytesseract.image_to_data(
        rgb, config=config, output_type=pytesseract.Output.DICT,
    )
    reads: list[tuple[list[tuple[float, float]], str, float]] = []
    for i in range(len(data.get("text", []))):
        text = (data["text"][i] or "").strip()
        if not text:
            continue
        try:
            conf = float(data["conf"][i])
        except (TypeError, ValueError):
            conf = -1.0
        if conf < 0:  # Tesseract marks non-text detections with conf -1
            continue
        x, y = int(data["left"][i]), int(data["top"][i])
        w, h = int(data["width"][i]), int(data["height"][i])
        box = [(x, y), (x + w, y), (x + w, y + h), (x, y + h)]
        reads.append((box, text, conf / 100.0))
    return reads


def _easyocr_reads(rgb: np.ndarray) -> list[tuple[list[tuple[float, float]], str, float]]:
    return list(_easyocr_reader().readtext(rgb))


@lru_cache(maxsize=1)
def _easyocr_reader():
    import easyocr

    return easyocr.Reader(
        ["en"],
        gpu=False,
        verbose=False,
        model_storage_directory=os.environ.get("EASYOCR_MODEL_DIR"),
    )


def label_to_room_type(text: str) -> Optional[str]:
    key = " ".join(text.lower().split())
    if key in LABEL_TO_ROOM_TYPE:
        return LABEL_TO_ROOM_TYPE[key]
    for token in key.replace("/", " ").split():
        if token in LABEL_TO_ROOM_TYPE:
            return LABEL_TO_ROOM_TYPE[token]
    return None
