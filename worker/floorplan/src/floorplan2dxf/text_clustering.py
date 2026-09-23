"""Merge OCR tokens that sit close together on the grid into one semantic
label, before anything downstream (dimension resolution, the final model)
sees them.

Tesseract reads word-by-word: "GROUND FLOOR PLAN" arrives as three separate
TextItems, as does "SCALE 1:100 MTS." and "DINING AREA". Passed downstream
unmerged, a reasoning LLM has no way to know "AREA" belongs with "DINING"
two tokens away rather than being its own fragment. Clustering is grid-cell
adjacency — the SAME GridSpec every other module in this package uses for
proximity decisions (per user direction: the grid is the grounding for all
positional judgements, not a separate ad-hoc pixel threshold per module).
"""
from __future__ import annotations

from dataclasses import dataclass

from .dictionary import is_dictionary_word
from .grid import GridSpec, Point


@dataclass
class TextCluster:
    text: str  # merged, reading-order (left-to-right, then top-to-bottom)
    members: list  # original TextItem objects
    position: Point  # centroid, px
    kind: str  # majority kind among members ("label" wins over "other" if either is present)


def _derive_row_tolerance_px(ocr_texts) -> float:
    """How far apart in Y two tokens can be and still be "the same text
    line" — derived from the OCR tokens' OWN bounding-box heights, not the
    image-size-based grid cell (which happens to be a similar magnitude by
    coincidence on this image, but is the wrong basis conceptually: row
    alignment is a property of the text's font size, not the image's pixel
    dimensions). Using half the median token height caught two bad
    cross-line merges ("1.50 CR." with "DINING AREA" below it, "UP" with
    "BEDROOM 2" below it) that the grid-cell-based tolerance let through."""
    heights = []
    for t in ocr_texts:
        if len(t.bbox) >= 4:
            ys = [p[1] for p in t.bbox]
            heights.append(max(ys) - min(ys))
    if not heights:
        return 10.0
    heights.sort()
    median_height = heights[len(heights) // 2]
    return max(4.0, median_height * 0.6)


def _derive_dictionary_word_gap_px(ocr_texts, row_tolerance_px: float) -> float:
    """Typical spacing between adjacent real-word tokens on the same row,
    measured from THIS document's own title/label text (e.g. "GROUND" to
    "FLOOR" to "PLAN") — not an arbitrary multiplier. Geometric proximity
    stays the grounding signal; this only tells us what "close" means for
    title-sized text specifically, since architectural titles are drawn
    wider-spaced than a small measurement label."""
    words = [t for t in ocr_texts if is_dictionary_word(t.content)]
    gaps = []
    for i, a in enumerate(words):
        for b in words[i + 1:]:
            if abs(a.position[1] - b.position[1]) <= row_tolerance_px:
                gaps.append(abs(a.position[0] - b.position[0]))
    if len(gaps) < 2:
        return row_tolerance_px * 10  # not enough same-row word pairs to derive a real median; modest fallback
    gaps.sort()
    median_gap = gaps[len(gaps) // 2]
    return median_gap * 1.3


def cluster_text_items(ocr_texts, grid_spec: GridSpec, max_gap_cells: int = 3) -> list[TextCluster]:
    """Union-find: two tokens merge if they're on roughly the same text row
    AND close enough horizontally — where "close enough" is the tight
    `max_gap_cells` grid threshold for most tokens, but widened (see
    `_derive_dictionary_word_gap_px`) when BOTH tokens are real dictionary
    words, since title-sized label text ("GROUND   FLOOR   PLAN") is drawn
    with much wider word spacing than a small measurement figure.

    "Same row" is derived from the OCR tokens' own bounding-box heights (see
    `_derive_row_tolerance_px`), not image-size-based grid cells — row
    alignment is a font-size property, and using the wrong basis let two
    different text lines merge incorrectly. Geometric proximity stays the
    primary, grounding signal throughout; the dictionary check only adjusts
    how far "close" reaches for recognizable words on a genuinely shared
    row, it never overrides the row constraint itself.

    Transitive — A-B close and B-C close merges A,B,C into one cluster even
    if A and C aren't directly close, which is exactly how a multi-word
    label reads."""
    n = len(ocr_texts)
    parent = list(range(n))

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    def union(i, j):
        ri, rj = find(i), find(j)
        if ri != rj:
            parent[ri] = rj

    row_tolerance_px = _derive_row_tolerance_px(ocr_texts)
    cells = [grid_spec.to_grid(t.position) for t in ocr_texts]
    is_word = [is_dictionary_word(t.content) for t in ocr_texts]
    wide_gap_px = _derive_dictionary_word_gap_px(ocr_texts, row_tolerance_px)

    for i in range(n):
        for j in range(i + 1, n):
            same_row = abs(ocr_texts[i].position[1] - ocr_texts[j].position[1]) <= row_tolerance_px
            if not same_row:
                continue
            if grid_spec.grid_distance(cells[i], cells[j]) <= max_gap_cells:
                union(i, j)
            elif is_word[i] and is_word[j]:
                px_gap = abs(ocr_texts[i].position[0] - ocr_texts[j].position[0])
                if px_gap <= wide_gap_px:
                    union(i, j)

    groups: dict[int, list[int]] = {}
    for i in range(n):
        groups.setdefault(find(i), []).append(i)

    clusters = []
    for indices in groups.values():
        members = [ocr_texts[i] for i in indices]
        # Reading order: top-to-bottom rows (grid-cell y), then left-to-right within a row.
        members.sort(key=lambda t: (grid_spec.to_grid(t.position)[1], t.position[0]))
        text = " ".join(m.content for m in members)
        cx = sum(m.position[0] for m in members) / len(members)
        cy = sum(m.position[1] for m in members) / len(members)
        # A cluster counts as a "label" if it contains at least one real word
        # by OUR OWN general dictionary check (dictionary.py), not just the
        # underlying pipeline's narrow room-type keyword list. That list only
        # recognizes interior room names (bedroom/kitchen/living/...) for its
        # original DXF/area-export purpose — it has no "porch", no "up", no
        # egress-relevant vocabulary at all, so trusting it silently dropped
        # real content (the stairs "UP" marking, "PORCH") from textLabels
        # entirely. Falls back to the underlying kind only for edge cases
        # (e.g. a cluster of purely non-alphabetic content already tagged).
        has_real_word = any(is_dictionary_word(m.content) for m in members)
        kinds = {m.kind for m in members}
        if has_real_word:
            kind = "label"
        elif "dimension" in kinds:
            kind = "dimension"
        else:
            kind = "other"
        clusters.append(TextCluster(text=text, members=members, position=(cx, cy), kind=kind))
    return clusters


def cluster_to_dict(c: TextCluster, grid_spec: GridSpec) -> dict:
    from .grid import annotate_position
    return {
        "text": c.text,
        "kind": c.kind,
        "position": annotate_position(grid_spec, c.position),
        "tokenCount": len(c.members),
    }
