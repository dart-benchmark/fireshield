"""Tesseract is the default OCR backend (see ocr.py) — no PyTorch, no loaded
model weights, so the memory constraint that disabled EasyOCR at runtime
doesn't apply. pytesseract is imported lazily inside _tesseract_reads(), so
it's mocked via sys.modules here rather than requiring the real package (and
the real tesseract-ocr binary, only present in the Docker image) locally.
"""

import sys
import types

import numpy as np


def _install_fake_pytesseract(monkeypatch, data):
    fake = types.ModuleType("pytesseract")
    fake.Output = types.SimpleNamespace(DICT="dict")
    fake.image_to_data = lambda rgb, config=None, output_type=None: data
    monkeypatch.setitem(sys.modules, "pytesseract", fake)


def test_reads_are_converted_to_box_text_conf_tuples(monkeypatch):
    from floorplan2dxf.ocr import _tesseract_reads

    data = {
        "text": ["2.00", "", "KITCHEN"],
        "conf": ["91", "-1", "78"],
        "left": [100, 0, 300],
        "top": [40, 0, 200],
        "width": [30, 0, 60],
        "height": [15, 0, 20],
    }
    _install_fake_pytesseract(monkeypatch, data)
    reads = _tesseract_reads(np.zeros((10, 10, 3), dtype=np.uint8))

    # The empty-text and conf=-1 (Tesseract's "not text") rows are dropped.
    assert len(reads) == 2
    box, text, conf = reads[0]
    assert text == "2.00"
    assert conf == 0.91  # confidence normalised to 0..1, matching EasyOCR's scale
    assert box == [(100, 40), (130, 40), (130, 55), (100, 55)]
    assert reads[1][1] == "KITCHEN"


def test_negative_confidence_rows_are_dropped():
    # Tesseract marks block/paragraph/line-level aggregate rows (not actual
    # detected words) with conf=-1; these must never surface as detections.
    from floorplan2dxf.ocr import _tesseract_reads

    data = {"text": ["block"], "conf": ["-1"], "left": [0], "top": [0], "width": [1], "height": [1]}
    import sys as _sys
    import types as _types
    fake = _types.ModuleType("pytesseract")
    fake.Output = _types.SimpleNamespace(DICT="dict")
    fake.image_to_data = lambda rgb, config=None, output_type=None: data
    _sys.modules["pytesseract"] = fake
    try:
        reads = _tesseract_reads(np.zeros((10, 10, 3), dtype=np.uint8))
    finally:
        del _sys.modules["pytesseract"]
    assert reads == []


def test_run_ocr_feeds_text_through_the_normal_classification_pipeline(monkeypatch):
    # End-to-end through run_ocr(): text Tesseract reads must classify the
    # same way EasyOCR's output would — classify_text() doesn't know or care
    # which backend produced the string, only the string itself. classify_text
    # needs an explicit unit or a WxH pair to call something a dimension (see
    # test_calibrate.py); "2.00m" qualifies, a bare "2.00" would not.
    from floorplan2dxf.ocr import run_ocr

    data = {
        "text": ["2.00m"], "conf": ["91"],
        "left": [100], "top": [40], "width": [30], "height": [15],
    }
    _install_fake_pytesseract(monkeypatch, data)
    items = run_ocr(np.zeros((10, 10, 3), dtype=np.uint8), enabled=True)
    assert len(items) == 1
    assert items[0].content == "2.00m"
    assert items[0].kind == "dimension"


def test_disabled_returns_nothing_without_importing_pytesseract():
    from floorplan2dxf.ocr import run_ocr

    assert run_ocr(np.zeros((10, 10, 3), dtype=np.uint8), enabled=False) == []
