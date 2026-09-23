"""The vision advisory is billed per day, so repeat reads must be free."""

from pathlib import Path

import floorplan2dxf.api as api


def _usable():
    return {
        "status": "usable", "confidence": 0.9, "summary": "s",
        "spaces": [], "openings": [], "elements": [],
        "_dimensions": [{"value_m": 9.0}], "_overallMm": (9000.0, 11000.0),
    }


def _install(monkeypatch, result):
    calls = {"n": 0}

    def fake(source, page, api_key, profile):
        calls["n"] += 1
        return result() if callable(result) else dict(result)

    monkeypatch.setattr(api, "_qwen_advisory", fake)
    api._ADVISORY_CACHE.clear()
    return calls


def test_same_drawing_is_read_once(monkeypatch):
    calls = _install(monkeypatch, _usable)
    payload = b"PLAN-BYTES"
    api._cached_qwen_advisory(payload, Path("x"), 0, "k", {})
    api._cached_qwen_advisory(payload, Path("x"), 0, "k", {})
    assert calls["n"] == 1


def test_a_changed_drawing_is_read_again(monkeypatch):
    calls = _install(monkeypatch, _usable)
    api._cached_qwen_advisory(b"PLAN-A", Path("x"), 0, "k", {})
    api._cached_qwen_advisory(b"PLAN-B", Path("x"), 0, "k", {})
    assert calls["n"] == 2


def test_caller_mutating_its_result_cannot_corrupt_the_cache(monkeypatch):
    # convert_plan pops the private scale keys off whatever it receives, so a
    # shared reference would strip them from every later cache hit.
    _install(monkeypatch, _usable)
    payload = b"PLAN-BYTES"
    first = api._cached_qwen_advisory(payload, Path("x"), 0, "k", {})
    first.pop("_dimensions")
    first.pop("_overallMm")
    second = api._cached_qwen_advisory(payload, Path("x"), 0, "k", {})
    assert "_dimensions" in second and "_overallMm" in second


def test_failures_are_never_cached(monkeypatch):
    # Caching a rate-limit failure would keep the advisory dead long after the
    # daily quota recovered.
    calls = _install(monkeypatch, {"status": "unavailable", "detail": "429"})
    api._cached_qwen_advisory(b"FAILS", Path("x"), 0, "k", {})
    api._cached_qwen_advisory(b"FAILS", Path("x"), 0, "k", {})
    assert calls["n"] == 2


def test_cache_is_bounded(monkeypatch):
    # The service runs under a 512MB limit; the cache must not grow unbounded.
    _install(monkeypatch, _usable)
    for index in range(api._ADVISORY_CACHE_MAX + 8):
        api._cached_qwen_advisory(f"PLAN-{index}".encode(), Path("x"), 0, "k", {})
    assert len(api._ADVISORY_CACHE) <= api._ADVISORY_CACHE_MAX
