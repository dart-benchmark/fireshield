from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import cv2
import numpy as np


IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".tif", ".tiff", ".bmp", ".webp"}
PDF_SUFFIXES = {".pdf"}


@dataclass
class Raster:
    rgb: np.ndarray
    source: Path
    page: int = 0
    dpi: int = 200


def load_raster(path: str | Path, page: int = 0, dpi: int = 200) -> Raster:
    src = Path(path)
    if not src.exists():
        raise FileNotFoundError(f"Input not found: {src}")
    suffix = src.suffix.lower()
    if suffix in PDF_SUFFIXES:
        return _load_pdf(src, page=page, dpi=dpi)
    if suffix in IMAGE_SUFFIXES:
        return _load_image(src, dpi=dpi)
    raise ValueError(f"Unsupported input type: {suffix}")


def _load_image(path: Path, dpi: int) -> Raster:
    data = np.fromfile(str(path), dtype=np.uint8)
    bgr = cv2.imdecode(data, cv2.IMREAD_COLOR)
    if bgr is None:
        raise ValueError(f"Could not decode image: {path}")
    rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
    if rgb.size == 0:
        raise ValueError(f"Empty image: {path}")
    return Raster(rgb=rgb, source=path, page=0, dpi=dpi)


def _load_pdf(path: Path, page: int, dpi: int) -> Raster:
    import fitz

    doc = fitz.open(path)
    try:
        if page < 0 or page >= doc.page_count:
            raise IndexError(f"PDF has {doc.page_count} page(s); requested page {page}")
        zoom = dpi / 72.0
        pix = doc.load_page(page).get_pixmap(matrix=fitz.Matrix(zoom, zoom), alpha=False)
        rgb = np.frombuffer(pix.samples, dtype=np.uint8).reshape(pix.height, pix.width, 3).copy()
    finally:
        doc.close()
    return Raster(rgb=rgb, source=path, page=page, dpi=dpi)
