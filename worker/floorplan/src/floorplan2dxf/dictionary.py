"""Offline English dictionary check (pyspellchecker — bundled word-frequency
data, no network/download needed at runtime). Used to validate that a text
token is plausibly a real label word before letting it merge across a wider
geometric gap than an unrecognized token would get (see text_clustering.py).
"""
from __future__ import annotations

from functools import lru_cache

# Architectural abbreviations that are legitimate label content but aren't
# in a general English dictionary (spellchecker correctly misses these).
KNOWN_ABBREVIATIONS = {"cr", "mts", "wc", "up", "dn", "ft", "sq", "elev"}


@lru_cache(maxsize=1)
def _checker():
    from spellchecker import SpellChecker
    return SpellChecker()


def is_dictionary_word(token: str) -> bool:
    cleaned = token.strip(".:").lower()
    if not cleaned or not cleaned.isalpha():
        return False
    if cleaned in KNOWN_ABBREVIATIONS:
        return True
    return cleaned in _checker()
