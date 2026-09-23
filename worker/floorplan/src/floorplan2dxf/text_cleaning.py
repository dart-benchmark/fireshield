"""Regex-based OCR garbage filtering, applied before clustering/dimension
resolution so noise tokens ('|', '==', stray single letters from furniture
hatching/icons) never pollute a merged label.

Confidence alone isn't a safe filter here — real short labels on this
drawing ("UP", "CR.") score as low as pure junk does (checked directly
against test3.jpg's actual Tesseract output: genuine content spans the full
range, garbage clusters at the low end but overlaps it). So this filters by
what the STRING actually looks like, not by score:

  - reject tokens that are ONLY non-alphanumeric characters (punctuation/
    junk glyphs Tesseract hallucinated from line art) — unambiguous noise.
  - reject lone single alphabetic characters — never a real token on an
    architectural drawing (shortest real content here is 2+ letters).

Deliberately conservative: when in doubt, keep the token. A few residual
noise fragments reaching clustering/dimension resolution is a much smaller
problem than dropping real content.
"""
from __future__ import annotations

import re

_ONLY_SYMBOLS = re.compile(r"^[^A-Za-z0-9]+$")
_LONE_LETTER = re.compile(r"^[A-Za-z]$")


def is_garbage(content: str) -> bool:
    text = content.strip()
    if not text:
        return True
    if _ONLY_SYMBOLS.match(text):
        return True
    if _LONE_LETTER.match(text):
        return True
    return False


def clean_ocr_texts(ocr_texts) -> list:
    return [t for t in ocr_texts if not is_garbage(t.content)]
