// Live NBCS 2026 Part F graph query — the server side of the `query_nbc` tool
// that the reasoning model calls during compliance analysis.
//
// This is the same idea as `graphify query`: seed on label/token match, then
// BFS a hop or two along the typed edges and return page-anchored, citable
// requirements. It runs at the edge over `nbc_query_index.json` (built by
// tool/gen_nbc_query_index.py and stored in R2), so the hosted app needs no
// local Python CLI.

const STOPWORDS = new Set([
  'the', 'a', 'an', 'of', 'for', 'and', 'or', 'to', 'in', 'on', 'is', 'are',
  'be', 'by', 'with', 'as', 'at', 'from', 'this', 'that', 'requirement',
  'requirements', 'building', 'buildings', 'nbc', 'part', 'clause', 'what',
  'which', 'how', 'per', 'shall', 'should', 'must',
]);

function tokenize(s) {
  return (s || '')
    .toLowerCase()
    .split(/[^a-z0-9]+/)
    .filter((t) => t.length > 1 && !STOPWORDS.has(t));
}

// Module-scope caches keyed by nothing — a Worker isolate serves one index.
let _index = null;
let _byId = null;
let _postings = null; // token -> [{i, tf}]
let _idf = null; // token -> idf weight

async function loadIndex(env) {
  if (_index) return _index;
  const raw = await readIndexBlob(env);
  if (!raw) throw new Error('NBC index not available (bind R2 NBC_BUCKET or KV NBC_KV)');
  const idx = typeof raw === 'string' ? JSON.parse(raw) : raw;
  buildSearchStructures(idx);
  _index = idx;
  return idx;
}

async function readIndexBlob(env) {
  // Prefer R2 (large blob), fall back to KV.
  if (env.NBC_BUCKET && typeof env.NBC_BUCKET.get === 'function') {
    const obj = await env.NBC_BUCKET.get(env.NBC_INDEX_KEY || 'nbc_query_index.json');
    if (obj) return await obj.text();
  }
  if (env.NBC_KV && typeof env.NBC_KV.get === 'function') {
    const val = await env.NBC_KV.get(env.NBC_INDEX_KEY || 'nbc_query_index', 'text');
    if (val) return val;
  }
  return null;
}

function buildSearchStructures(idx) {
  _byId = new Map();
  _postings = new Map();
  const docFreq = new Map();
  idx.nodes.forEach((n, i) => {
    _byId.set(n.id, i);
    const toks = new Set(tokenize(n.norm || n.label));
    toks.forEach((t) => {
      if (!_postings.has(t)) _postings.set(t, []);
      _postings.get(t).push(i);
      docFreq.set(t, (docFreq.get(t) || 0) + 1);
    });
  });
  const N = idx.nodes.length || 1;
  _idf = new Map();
  for (const [t, df] of docFreq) _idf.set(t, Math.log(1 + N / df));
}

// Score seed nodes by summed IDF of overlapping query tokens.
function seedNodes(idx, queryTokens, limit) {
  const scores = new Map();
  for (const t of new Set(queryTokens)) {
    const posting = _postings.get(t);
    if (!posting) continue;
    const w = _idf.get(t) || 0;
    for (const i of posting) scores.set(i, (scores.get(i) || 0) + w);
  }
  return [...scores.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, limit)
    .map(([i, score]) => ({ i, score }));
}

function snippetFor(idx, node) {
  if (!node.page) return null;
  const text = idx.pages[String(node.page)];
  if (!text) return null;
  // Prefer the sentence around the node label; else the page head.
  const label = (node.label || '').slice(0, 40).toLowerCase();
  let start = 0;
  if (label) {
    const at = text.toLowerCase().indexOf(label);
    if (at > 0) start = Math.max(0, at - 40);
  }
  return text.slice(start, start + 260).replace(/\s+/g, ' ').trim();
}

/**
 * queryNbc — answer a natural-language regulation question from the graph.
 * @returns {{query:string, count:number, results:Array}}
 */
export async function queryNbc(env, question, opts = {}) {
  const idx = await loadIndex(env);
  const { seedTerms = '', k = 8, hops = 1 } = opts;
  const qTokens = [...tokenize(question), ...tokenize(seedTerms)];
  if (qTokens.length === 0) return { query: question, count: 0, results: [] };

  const seeds = seedNodes(idx, qTokens, Math.min(k, 8));
  const chosen = new Map(); // i -> depth
  for (const s of seeds) chosen.set(s.i, 0);

  // BFS along typed edges, preferring higher-weight edges.
  let frontier = [...chosen.keys()];
  const maxHops = Math.min(hops, 2);
  for (let d = 0; d < maxHops && chosen.size < k + 8; d++) {
    const next = [];
    for (const i of frontier) {
      const node = idx.nodes[i];
      const edges = (idx.adj[node.id] || [])
        .slice()
        .sort((a, b) => (b[2] || 0) - (a[2] || 0))
        .slice(0, 5);
      for (const [tgtId] of edges) {
        const ti = _byId.get(tgtId);
        if (ti === undefined || chosen.has(ti)) continue;
        chosen.set(ti, d + 1);
        next.push(ti);
        if (chosen.size >= k + 8) break;
      }
      if (chosen.size >= k + 8) break;
    }
    frontier = next;
  }

  // Rank: seeds first (by score), then BFS nodes by shallow depth.
  const seedScore = new Map(seeds.map((s) => [s.i, s.score]));
  const ranked = [...chosen.keys()].sort((a, b) => {
    const da = chosen.get(a);
    const db = chosen.get(b);
    if (da !== db) return da - db;
    return (seedScore.get(b) || 0) - (seedScore.get(a) || 0);
  });

  const results = ranked.slice(0, k).map((i) => {
    const n = idx.nodes[i];
    const relations = (idx.adj[n.id] || []).slice(0, 3).map(([tgtId, rel]) => {
      const ti = _byId.get(tgtId);
      return { relation: rel, node: ti !== undefined ? idx.nodes[ti].label.slice(0, 80) : tgtId };
    });
    return {
      id: n.id,
      label: n.label,
      page: n.page,
      community: n.community != null ? idx.communities[String(n.community)] : null,
      rationale: n.rationale ? n.rationale.slice(0, 240) : undefined,
      snippet: snippetFor(idx, n),
      relations,
    };
  });

  return { query: question, count: results.length, results };
}

export { loadIndex };
