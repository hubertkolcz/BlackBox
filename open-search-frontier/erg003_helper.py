# Shared, verified helper for ERG-003 18-clique search in G = C9 v C9 v C9 v C5.
# Vertex = (x1,x2,x3,c), xi in Z9, c in Z5.  u~v iff some xi differs by +-1 mod 9,
# OR c differs by +-1 mod 5.  omega(G) in [17,19]; a 17-clique is known.
import json, os
_HERE = os.path.dirname(os.path.abspath(__file__))
verts = [(a, b, c, d) for a in range(9) for b in range(9) for c in range(9) for d in range(5)]
idx = {v: i for i, v in enumerate(verts)}
N = len(verts)


def adjG(u, v):
    if u == v:
        return False
    for t in range(3):
        if (u[t] - v[t]) % 9 in (1, 8):
            return True
    return (u[3] - v[3]) % 5 in (1, 4)


# adjacency as bitsets (Python ints) -- built once at import (~7s)
adj = [0] * N
for i, u in enumerate(verts):
    m = 0
    for j, v in enumerate(verts):
        if adjG(u, v):
            m |= (1 << j)
    adj[i] = m
FULL = (1 << N) - 1


def common(clique):
    """bitset of vertices adjacent to EVERY vertex in clique (the extension set)."""
    m = FULL
    for v in clique:
        m &= adj[v]
    return m


def bitlist(m):
    r = []
    i = 0
    while m:
        if m & 1:
            r.append(i)
        m >>= 1
        i += 1
    return r


SEED17 = [idx[tuple(t)] for t in
          json.load(open(os.path.join(_HERE, 'erg003_omega17_witness.json')))['witness']]


def verify(clique):
    """(is_valid_clique, up_to_3_bad_pairs). Independent all-pairs adjacency check."""
    cl = list(dict.fromkeys(clique))
    if len(cl) != len(clique):
        return (False, [('DUPLICATE', None)])
    bad = [(a, b) for ia, a in enumerate(cl) for b in cl[ia + 1:]
           if not adjG(verts[a], verts[b])]
    return (len(bad) == 0, bad[:3])


def astuples(clique):
    return [list(verts[i]) for i in clique]
