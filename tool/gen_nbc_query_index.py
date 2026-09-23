#!/usr/bin/env python3
"""Repackage the graphify NBCS 2026 Part F graph into a compact query index.

This is a *deterministic repackaging* of the existing graphify output — no LLM,
no invented occupancy->clause mappings. The reasoning happens live at query time
in the Cloudflare Worker (`worker/src/nbc_graph.js`), which BFS-traverses this
index. Faithful to `graphify query`'s NetworkX-traversal fallback.

Inputs (graphify root, default: the repo's "Fire safety standards India" folder):
    graphify-out/graph.json          nodes + typed edges
    graphify-out/.graphify_labels.json  community id -> human label
    corpus/groups/nbc_p*.md          page text (for citation snippets)

Output:
    worker/data/nbc_query_index.json
    {
      "meta":    {document, pages, generated_at, counts},
      "nodes":   [{id, label, norm, rationale, page, community}],
      "adj":     {id: [[targetId, relation, weight], ...]},   # undirected
      "pages":   {"111": "full page text ..."},
      "communities": {"21": "Fire Doors and Hardware"},
      "occupancySeeds": {"A": "assembly theatre ...", ...}
    }

Usage:
    python tool/gen_nbc_query_index.py
    python tool/gen_nbc_query_index.py --root "/path/to/Fire safety standards India"
"""
from __future__ import annotations

import argparse
import io
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

# The graphify root sits outside the Flutter project, two levels up from it by
# default:  <repo>/Fire safety standards India   and
#           <repo>/CodeBase/FireShield_Flutter_Source/fireshield_flutter
DEFAULT_ROOT = (
    Path(__file__).resolve().parents[4] / "Fire safety standards India"
)

# NBC occupancy groups A-J (no I) -> seed terms that steer the model's first
# query_nbc() call. Terms are drawn from the standard's own vocabulary; they are
# search hints only, not a compliance ruleset.
OCCUPANCY_SEEDS = {
    "A": "residential dwelling apartment lodging hotel refuge staircase",
    "B": "educational school classroom exit panic bar assembly",
    "C": "institutional hospital patient ward refuge progressive evacuation",
    "D": "assembly theatre auditorium seating aisle exit occupant load",
    "E": "business office high rise travel distance exit",
    "F": "mercantile shop store basement sprinkler exit",
    "G": "industrial factory hazard process venting sprinkler",
    "H": "storage warehouse fire load compartmentation hydrant",
    "J": "hazardous flammable liquid explosive high hazard",
}

PAGE_HEADER = re.compile(r"^#\s*NBCS 2026 Part F\s*[—-]\s*Page\s+(\d+)\s*$", re.M)
PAGE_KEY = re.compile(r"p(\d+)")


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def page_num(source_location) -> int | None:
    """'p142' -> 142.  Node source_location may be str or list."""
    if not source_location:
        return None
    if isinstance(source_location, list):
        source_location = source_location[0] if source_location else None
    if not source_location:
        return None
    m = PAGE_KEY.search(str(source_location))
    return int(m.group(1)) if m else None


def parse_pages(groups_dir: Path) -> dict[str, str]:
    """Split each corpus group markdown into {page_number: text}."""
    pages: dict[str, str] = {}
    for md in sorted(groups_dir.glob("nbc_p*.md")):
        text = md.read_text(encoding="utf-8")
        matches = list(PAGE_HEADER.finditer(text))
        for i, m in enumerate(matches):
            pno = m.group(1)
            start = m.end()
            end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
            body = text[start:end].strip()
            # Collapse runaway whitespace; keep it readable for citation.
            body = re.sub(r"\n{3,}", "\n\n", body)
            if body:
                pages[pno] = body
    return pages


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=str(DEFAULT_ROOT),
                    help="graphify root (contains graphify-out/ and corpus/)")
    ap.add_argument("--out", default=None,
                    help="output path (default worker/data/nbc_query_index.json)")
    args = ap.parse_args()

    root = Path(args.root).resolve()
    gout = root / "graphify-out"
    graph_path = gout / "graph.json"
    labels_path = gout / ".graphify_labels.json"
    groups_dir = root / "corpus" / "groups"

    if not graph_path.exists():
        print(f"ERROR: {graph_path} not found", file=sys.stderr)
        return 1

    project_root = Path(__file__).resolve().parents[1]
    out_path = Path(args.out) if args.out else (
        project_root / "worker" / "data" / "nbc_query_index.json"
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)

    graph = load_json(graph_path)
    labels = load_json(labels_path) if labels_path.exists() else {}
    pages = parse_pages(groups_dir) if groups_dir.exists() else {}

    # --- nodes -------------------------------------------------------------
    nodes_out = []
    for n in graph.get("nodes", []):
        nid = n.get("id")
        if not nid:
            continue
        entry = {
            "id": nid,
            "label": n.get("label", ""),
            "norm": n.get("norm_label") or n.get("label", "").lower(),
            "page": page_num(n.get("source_location")),
            "community": n.get("community"),
        }
        rat = n.get("rationale")
        if rat:
            entry["rationale"] = rat
        nodes_out.append(entry)

    node_ids = {e["id"] for e in nodes_out}

    # --- adjacency (undirected, typed) ------------------------------------
    adj: dict[str, list] = {}

    def add_edge(a, b, rel, w):
        if a not in node_ids or b not in node_ids:
            return
        adj.setdefault(a, []).append([b, rel, w])

    for l in graph.get("links", []):
        s, t = l.get("source"), l.get("target")
        rel = l.get("relation", "related")
        try:
            w = round(float(l.get("weight", 1.0)), 3)
        except (TypeError, ValueError):
            w = 1.0
        add_edge(s, t, rel, w)
        add_edge(t, s, rel, w)  # undirected traversal

    # Hyperedges: connect every member to the hyperedge's other members so
    # "system" groupings (e.g. means-of-egress path) traverse together.
    for h in graph.get("hyperedges", []):
        members = h.get("nodes")
        if isinstance(members, str):
            # stored as a stringified list in some exports
            try:
                members = json.loads(members.replace("'", '"'))
            except json.JSONDecodeError:
                members = []
        members = [m for m in (members or []) if m in node_ids]
        rel = h.get("relation", "participate_in")
        for i, a in enumerate(members):
            for b in members[i + 1:]:
                add_edge(a, b, rel, 1.0)
                add_edge(b, a, rel, 1.0)

    communities = {str(k): v for k, v in labels.items()}

    index = {
        "meta": {
            "document": graph.get("graph", {}).get("document")
            or "NBCS 2026 Part F Fire and Life Safety",
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "counts": {
                "nodes": len(nodes_out),
                "edges_undirected": sum(len(v) for v in adj.values()),
                "pages": len(pages),
                "communities": len(communities),
            },
        },
        "nodes": nodes_out,
        "adj": adj,
        "pages": pages,
        "communities": communities,
        "occupancySeeds": OCCUPANCY_SEEDS,
    }

    with io.open(out_path, "w", encoding="utf-8") as f:
        json.dump(index, f, ensure_ascii=False, separators=(",", ":"))

    size_kb = out_path.stat().st_size / 1024
    print(f"Wrote {out_path}")
    print(f"  nodes={len(nodes_out)}  edges(undirected)="
          f"{index['meta']['counts']['edges_undirected']}  "
          f"pages={len(pages)}  communities={len(communities)}")
    print(f"  size={size_kb:.0f} KB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
