#!/usr/bin/env python3
"""KCBS-FEM study driver -- executes the pre-registered study of
mbqc-fem-study-design-2026-07-10.md (hypotheses H1-H5, falsification gates
section 5) on pentagon exclusivity meshes.

Every quantitative claim of kcbs_fem_study.wl is produced by THIS script
(the sandbox has no Wolfram kernel; this is the executed verification).
Certified sparse Lovasz-theta machinery is reused from lovasz_theta_sparse.py
(same directory): chordal_theta (clique-tree SDP, eigenvalue-certified),
ring_theta_symmetric (Z_N symbol reduction, independent route), exact
max-plus alpha for gluing words.

  python3 fem_study.py [--stages sanity,h1,h2,h3,h4,h5,gates] [--quick]

Outputs: printed study report + fem_study_results.json.
"""
import argparse
import itertools
import json
import math
import time

import numpy as np
import scipy.sparse as sp
from scipy.optimize import linprog

import lovasz_theta_sparse as lts

SQRT5 = math.sqrt(5.0)
Q5 = 1.0 / SQRT5                       # per-event probability, KCBS maximum
CF_C5 = 2.0 * SQRT5 - 4.0              # exact CF of the quantum pentagon table
VCRIT_C5 = (5.0 + 3.0 * SQRT5) / 20.0  # single-block visibility threshold
TAU_STAR = 1.3767177459158590          # Root[49x^3-128x^2-75x+218, 2] (trans)
CCT_DENSITY = 1.40323086923899745      # certified continuum optimum (cct)
ALPHA_DENS_T = 4.0 / 3.0               # alpha density, trans & cct families

RESULTS = {}


def log(msg=""):
    print(msg, flush=True)


# ---------------------------------------------------------------------------
# small exact graph machinery (n <= ~23)
# ---------------------------------------------------------------------------

def independent_sets(n, edges):
    """All independent sets as bitmasks (iterative DFS; sparse graphs)."""
    adj = [0] * n
    for u, v in edges:
        adj[u] |= 1 << v
        adj[v] |= 1 << u
    out = []
    stack = [(0, 0, 0)]
    while stack:
        v, mask, forb = stack.pop()
        while v < n:
            if not (forb >> v) & 1:
                stack.append((v + 1, mask, forb))     # branch: v excluded
                mask |= 1 << v
                forb |= adj[v]
            v += 1
        out.append(mask)
    return out


def alpha_exact(n, edges):
    return max(bin(s).count("1") for s in independent_sets(n, edges))


def triangle_free(n, edges):
    es = set(edges)
    adj = [set() for _ in range(n)]
    for u, v in edges:
        adj[u].add(v)
        adj[v].add(u)
    return not any(w in adj[u] for u, v in es for w in adj[v])


def alpha_star_lp(n, edges):
    """Fractional packing over maximal cliques; pentagon meshes are
    triangle-free (asserted), so cliques = edges."""
    assert triangle_free(n, edges)
    rows = [i for i, _ in enumerate(edges) for _ in range(2)]
    cols = [x for e in edges for x in e]
    A = sp.csr_matrix(([1.0] * len(cols), (rows, cols)), shape=(len(edges), n))
    res = linprog(-np.ones(n), A_ub=A, b_ub=np.ones(len(edges)),
                  bounds=(0, None), method="highs")
    assert res.status == 0
    return -res.fun


# ---------------------------------------------------------------------------
# contextual fraction: AB incidence LP over independent-set columns
# ---------------------------------------------------------------------------
# Scenario of a mesh: measurements = vertices, contexts = edges, outcomes
# {0,1}, section order (00,01,10,11).  Deterministic global assignments with
# nonzero admissible weight are exactly the independent sets (any assignment
# hitting a (1,1) section is killed by the e_11 = 0 rows) -- the column
# reduction that keeps the LP at #independent-sets instead of 2^n variables.

SECTIONS = ((0, 0), (0, 1), (1, 0), (1, 1))


def _incidence(n, edges, isets):
    rows, cols = [], []
    r = 0
    for (u, v) in edges:
        for (au, av) in SECTIONS:
            for j, S in enumerate(isets):
                if ((S >> u) & 1) == au and ((S >> v) & 1) == av:
                    rows.append(r)
                    cols.append(j)
            r += 1
    return sp.csr_matrix(([1.0] * len(rows), (rows, cols)),
                         shape=(r, len(isets)))


def edge_dist(V):
    """Per-context table at visibility V: V * quantum + (1-V) * uniform.
    Quantum block table: (1-2q, q, q, 0), q = 1/sqrt(5) (kcbs.wl maximum);
    uniform noise = maximally mixed qutrit per block: (1/3, 1/3, 1/3, 0)
    (P(1,1) = 0 stays exact: orthogonal projectors)."""
    eq = np.array([1 - 2 * Q5, Q5, Q5, 0.0])
    eu = np.array([1 / 3, 1 / 3, 1 / 3, 0.0])
    return V * eq + (1 - V) * eu


def ncf_lp(n, edges, V=1.0):
    """Noncontextual fraction (ABM PRL 119, 050504) of the visibility-V
    block-local table on the mesh. Returns (ncf, #isets)."""
    isets = independent_sets(n, edges)
    M = _incidence(n, edges, isets)
    b = np.tile(edge_dist(V), len(edges))
    res = linprog(-np.ones(len(isets)), A_ub=M, b_ub=b,
                  bounds=(0, None), method="highs")
    assert res.status == 0, res.message
    return min(-res.fun, 1.0), len(isets)


def vcrit_lp(n, edges):
    """Exact mesh visibility threshold as ONE LP: max V such that the
    noisy table e(V) = e_u + V (e_q - e_u) admits a full-mass noncontextual
    decomposition (M d <= e(V), sum d = 1, d >= 0, 0 <= V <= 1).
    NCF is concave in V, so CF(V) = 0 iff V <= V_crit."""
    isets = independent_sets(n, edges)
    m = len(isets)
    M = _incidence(n, edges, isets)
    de = np.tile(edge_dist(1.0) - edge_dist(0.0), len(edges))
    eu = np.tile(edge_dist(0.0), len(edges))
    A_ub = sp.hstack([M, sp.csr_matrix(-de.reshape(-1, 1))]).tocsr()
    A_eq = sp.csr_matrix(([1.0] * m, ([0] * m, range(m))), shape=(1, m + 1))
    c = np.zeros(m + 1)
    c[-1] = -1.0
    res = linprog(c, A_ub=A_ub, b_ub=eu, A_eq=A_eq, b_eq=[1.0],
                  bounds=[(0, None)] * m + [(0, 1)], method="highs")
    assert res.status == 0, res.message
    return res.x[-1], m


# ---------------------------------------------------------------------------
# theta-body membership: is the glued block-local table still quantum?
# ---------------------------------------------------------------------------

def theta_body_margin(n, edges, p):
    """min t s.t. M + t*I >= 0 with M[0,0] = 1, M[0,i] = M[i,i] = p_i,
    M[i,j] = 0 on edges, off-edge entries free (handle index 0).
    t* <= 0  <=>  p is in the theta body TH(G) = the CSW quantum set."""
    import clarabel
    d = n + 1
    pos = [(pp, qq) for qq in range(d) for pp in range(qq + 1)]
    loc = {pq: r for r, pq in enumerate(pos)}
    nrow = len(pos)
    C0 = np.zeros((d, d))
    C0[0, 0] = 1.0
    for i in range(n):
        C0[0, i + 1] = C0[i + 1, 0] = p[i]
        C0[i + 1, i + 1] = p[i]
    es = set(edges)
    free = [(i + 1, j + 1) for i in range(n) for j in range(i + 1, n)
            if (i, j) not in es]
    S2 = math.sqrt(2.0)

    def svec(Mat):
        return np.array([Mat[pp, qq] * (1.0 if pp == qq else S2)
                         for pp, qq in pos])

    b = svec(C0)
    rows, cols, vals = [], [], []
    for r in range(d):                       # column 0: -svec(I) (variable t)
        rows.append(loc[(r, r)])
        cols.append(0)
        vals.append(-1.0)
    for k, (i, j) in enumerate(free):        # column k+1: -svec(Eij + Eji)
        rows.append(loc[(min(i, j), max(i, j))])
        cols.append(k + 1)
        vals.append(-S2)
    A = sp.csc_matrix((vals, (rows, cols)), shape=(nrow, 1 + len(free)))
    c = np.zeros(1 + len(free))
    c[0] = 1.0
    cones = [clarabel.PSDTriangleConeT(d)]
    settings = clarabel.DefaultSettings()
    settings.verbose = False
    P = sp.csc_matrix((len(c), len(c)))
    res = clarabel.DefaultSolver(P, c, A, b, cones, settings).solve()
    return float(np.array(res.x)[0])


# ---------------------------------------------------------------------------
# Quad-C5: re-derive the two-fold-cover witness by composition (quad_c5.wl)
# ---------------------------------------------------------------------------

def quad_c5_search():
    """Four pentagon 5-cycles on 8 vertices, every edge in exactly two
    pentagons (10 edges); the alpha = 3 class carries the published gap.
    Returns dict with counts, the winner graph, alpha, and class data."""
    pents = set()
    for sub in itertools.combinations(range(8), 5):
        s0 = sub[0]
        for perm in itertools.permutations(sub[1:]):
            cyc = (s0,) + perm
            if cyc[1] < cyc[-1]:
                pents.add(frozenset(
                    tuple(sorted((cyc[k], cyc[(k + 1) % 5]))) for k in range(5)))
    pents = sorted(pents, key=sorted)
    first = frozenset({(0, 1), (1, 2), (2, 3), (3, 4), (0, 4)})
    sols = set()

    def search(k, cnt, start):
        if k == 4:
            if all(v == 2 for v in cnt.values()) and len(cnt) == 10 \
                    and len({x for e in cnt for x in e}) == 8:
                sols.add(frozenset(cnt))
            return
        for i in range(start, len(pents)):
            c2 = dict(cnt)
            ok = True
            for e in pents[i]:
                c2[e] = c2.get(e, 0) + 1
                if c2[e] > 2:
                    ok = False
                    break
            if ok and len(c2) <= 10:
                search(k + 1, c2, i + 1)

    search(1, {e: 1 for e in first}, 0)
    classes = {}
    for s in sols:
        a = alpha_exact(8, sorted(s))
        classes.setdefault(a, []).append(s)
    winner = sorted(classes[min(classes)], key=sorted)[0]
    return {"pentagon_cycles": len(pents), "two_fold_composites": len(sols),
            "class_sizes": {a: len(v) for a, v in classes.items()},
            "edges": sorted(winner), "alpha": min(classes)}


# ---------------------------------------------------------------------------
# H5 geometry: pentagram frames, cascade generators, DLA, gluing holonomy
# ---------------------------------------------------------------------------

def kcbs_pentagram():
    """The five exact pentagram unit vectors (KCBSDirections[]): cycle order
    p_i . p_{i+1} = 0, cone axis (0,0,1)."""
    c2 = math.cos(math.pi / 5) / (1 + math.cos(math.pi / 5))
    s, c = math.sqrt(1 - c2), math.sqrt(c2)
    return [np.array([s * math.cos(4 * math.pi * i / 5),
                      s * math.sin(4 * math.pi * i / 5), c]) for i in range(5)]


P_STD = kcbs_pentagram()


def so3_axis_angle(R):
    """Axis*angle vector of R in SO(3) (vee of the matrix log)."""
    tr = np.clip((np.trace(R) - 1.0) / 2.0, -1.0, 1.0)
    th = math.acos(tr)
    if th < 1e-12:
        return np.zeros(3)
    if abs(math.pi - th) < 1e-8:          # angle-pi fallback via eigenvector
        w, v = np.linalg.eigh((R + R.T) / 2.0)
        ax = v[:, np.argmax(w)]
        return th * ax / np.linalg.norm(ax)
    ax = np.array([R[2, 1] - R[1, 2], R[0, 2] - R[2, 0], R[1, 0] - R[0, 1]])
    return th * ax / (2.0 * math.sin(th))


def cascade_axes(verts):
    """The four so(3) stage-generator axes of the Lapkiewicz cascade compiled
    on the pentagram verts (cycle order): stage frames on the vertex pairs
    (1,2),(3,2),(3,4),(5,4),(5,1) per lie_poisson_interface.wl."""
    idx = [(0, 1), (2, 1), (2, 3), (4, 3), (4, 0)]
    Fs = [np.array([verts[i], verts[j], np.cross(verts[i], verts[j])])
          for i, j in idx]
    return [so3_axis_angle(Fs[k + 1] @ Fs[k].T) for k in range(4)]


def glued_pentagram(u, v):
    """SO(3)-gauge pentagram with entry pair (q1, q5) = (u, v): the unique
    proper rotation G with G p1 = u, G p5 = v (pentagram rigidity: fixing one
    orthonormal consecutive pair fixes the block up to mirror; we keep the
    det = +1 sheet throughout -- the compilation gauge, stated in the essay)."""
    M = np.column_stack([P_STD[0], P_STD[4], np.cross(P_STD[0], P_STD[4])])
    G = np.column_stack([u, v, np.cross(u, v)]) @ M.T
    return [G @ p for p in P_STD], G


def mesh_geometry(word):
    """Common-frame (single-R^3, leaf-confined) compilation of the mesh with
    gluing word: block k+1 shares block k's exit edge (cycle positions q2,q3),
    entry order per letter ('c' straight / 't' swapped), mirroring
    pentagon_ring_word. Returns (blocks, holonomy rotation G_L that the ring
    closure would demand to equal the identity)."""
    blocks = [[p.copy() for p in P_STD]]
    G = np.eye(3)
    for letter in word:
        q = blocks[-1]
        u, v = (q[1], q[2]) if letter == "c" else (q[2], q[1])
        verts, G = glued_pentagram(u, v)
        blocks.append(verts)
    return blocks[:-1] if word else blocks, G


def dla_common(blocks):
    """(generator span, DLA dim after one commutator step) of the union of all
    block cascades in the common so(3): so(3) = (R^3, cross)."""
    axes = [a for b in blocks for a in cascade_axes(b)]
    span = np.linalg.matrix_rank(np.array(axes), tol=1e-8)
    comms = [np.cross(x, y) for x, y in itertools.combinations(axes, 2)]
    dla = np.linalg.matrix_rank(np.array(axes + comms), tol=1e-8)
    return int(span), int(dla)


def dla_blockdiag(nblocks):
    """DLA dim (one commutator step) of the block-diagonal compilation
    so(3)^N: each block its own mode triple, commutators componentwise."""
    axes0 = cascade_axes(P_STD)
    vecs = []
    for k in range(nblocks):
        for a in axes0:
            v = np.zeros(3 * nblocks)
            v[3 * k:3 * k + 3] = a
            vecs.append(v)
    comms = [np.concatenate([np.cross(x[3 * k:3 * k + 3], y[3 * k:3 * k + 3])
                             for k in range(nblocks)])
             for x, y in itertools.combinations(vecs, 2)]
    return int(np.linalg.matrix_rank(np.array(vecs + comms), tol=1e-8))


# ---------------------------------------------------------------------------
# stage 0: sanity anchors (abort the study if any fails)
# ---------------------------------------------------------------------------

def stage_sanity(quick=False):
    log("== stage 0: sanity anchors (gate: |diff| <= 1e-4) ==")
    out = {}
    checks = []

    def anchor(name, got, want, tol=1e-4):
        ok = abs(got - want) <= tol
        checks.append(ok)
        out[name] = {"got": got, "want": want, "ok": ok}
        log(f"  {name:34s} got={got:.7f}  want={want:.7f}  "
            f"{'OK' if ok else '** FAIL **'}")

    r = lts.chordal_theta(*lts.cycle_graph(5))
    anchor("theta(C5)", r["Theta"], SQRT5)
    r = lts.chordal_theta(*lts.cycle_graph(7))
    anchor("theta(C7)", r["Theta"], 7 * math.cos(math.pi / 7) /
           (1 + math.cos(math.pi / 7)))
    # chain N=1..5 against the kernel-verified dense-SDP values (DENSE_REFERENCE
    # of lovasz_theta_sparse.py; the study-design seed列 2.236/4.000/5.137/7.000/8.101)
    chain_kernel = {1: SQRT5, 2: 4.0, 3: 5.1366009255, 4: 7.0, 5: None}
    chain_theta = {}
    for nb in range(1, 6):
        r = lts.chordal_theta(*lts.pentagon_chain(nb))
        chain_theta[nb] = r["Theta"]
        if chain_kernel[nb] is not None:
            anchor(f"theta(chain {nb})", r["Theta"], chain_kernel[nb])
        else:
            log(f"  theta(chain 5)                     got={r['Theta']:.7f}  "
                f"(design-doc anchor 8.101x; certgap {r['CertGap']:.1e})")
            checks.append(abs(r["Theta"] - 8.101) < 5e-3)
    out["chain_theta_1_5"] = chain_theta
    # alpha laws
    a_trans = all(lts.alpha_ring_word("t", N) == 4 * N // 3
                  for N in (3, 6, 9, 12, 30))
    a_cis = all(lts.alpha_ring_word("c", N) == 3 * N // 2
                for N in (4, 6, 8, 10, 30))
    checks += [a_trans, a_cis]
    log(f"  alpha(trans ring)=floor(4N/3): {a_trans}   "
        f"alpha(cis ring)=floor(3N/2): {a_cis}")
    # trans density limit
    rs = lts.ring_theta_symmetric(1000, family="trans")
    anchor("theta(trans 1000)/1000", rs["Theta"] / 1000, TAU_STAR, 1e-4)
    # CF and V_crit of the single block (validates the LP machinery)
    n5, e5 = lts.cycle_graph(5)
    ncf, m = ncf_lp(n5, e5)
    anchor("CF(C5, sqrt5 table)", 1 - ncf, CF_C5, 1e-7)
    out["c5_isets"] = m
    vc, _ = vcrit_lp(n5, e5)
    anchor("V_crit(C5)", vc, VCRIT_C5, 1e-7)
    # Quad-C5 by composition
    quad = quad_c5_search()
    out["quad"] = {k: v for k, v in quad.items() if k != "edges"}
    out["quad"]["edges"] = [list(e) for e in quad["edges"]]
    rq = lts.chordal_theta(8, quad["edges"])
    quad_theta = rq["Theta"]
    out["quad"]["theta"] = quad_theta
    checks += [quad["pentagon_cycles"] == 672, quad["two_fold_composites"] == 90,
               quad["alpha"] == 3]
    anchor("Delta(Quad-C5)", quad_theta - quad["alpha"], 0.46784, 5e-4)
    log(f"  quad search: {quad['pentagon_cycles']} pentagon cycles, "
        f"{quad['two_fold_composites']} two-fold composites, "
        f"classes {quad['class_sizes']}")
    # Lapkiewicz cascade DLA anchor
    span, dla = dla_common([P_STD])
    checks += [span == 2, dla == 3]
    log(f"  cascade DLA: generator span={span} (want 2), "
        f"dim after one commutator={dla} (want 3)")
    out["cascade"] = {"span": span, "dla": dla}
    out["all_ok"] = all(checks) and all(v["ok"] for v in out.values()
                                        if isinstance(v, dict) and "ok" in v)
    RESULTS["sanity"] = out
    if not out["all_ok"]:
        raise SystemExit("SANITY GATE FAILED -- aborting study")
    log("  sanity: ALL OK")
    RESULTS["quad_edges"] = [list(e) for e in quad["edges"]]
    return quad["edges"]


# ---------------------------------------------------------------------------
# stage H1: extensivity -- theta/N and CF densities under composition
# ---------------------------------------------------------------------------

def stage_h1(quad_edges, quick=False):
    log("\n== H1: extensivity (theta/N convergence; CF density) ==")
    out = {"theta_density": {}, "cf": {}}
    # theta densities: trans & cis via the exact Z_N symmetry route,
    # cct via the certified chordal route
    sizes_sym = [100, 1000, 10000] if quick else [100, 1000, 10000, 100000]
    for fam in ("trans", "cis"):
        rows = []
        for N in sizes_sym:
            r = lts.ring_theta_symmetric(N, family=fam)
            rows.append({"N": N, "theta": r["Theta"], "density": r["Theta"] / N,
                         "certgap": r["CertGap"], "time": r["Time"]})
            log(f"  {fam:5s} N={N:6d}  theta/N={r['Theta']/N:.9f}  "
                f"certgap={r['CertGap']:.1e}  {r['Time']:.1f}s")
        out["theta_density"][fam] = rows
    cct_sizes = [99, 300] if quick else [99, 300, 999]
    rows = []
    for L in cct_sizes:
        n, edges = lts.pentagon_ring_word("cct", L // 3)
        t0 = time.perf_counter()
        r = lts.chordal_theta(n, edges)
        rows.append({"N": L, "theta": r["Theta"], "density": r["Theta"] / L,
                     "certgap": r["CertGap"],
                     "time": time.perf_counter() - t0})
        log(f"  cct   N={L:6d}  theta/N={r['Theta']/L:.9f}  "
            f"certgap={r['CertGap']:.1e}  {rows[-1]['time']:.1f}s")
    out["theta_density"]["cct"] = rows
    out["limits"] = {"trans": TAU_STAR, "cis": 1.5, "cct": CCT_DENSITY}
    dev_t = abs(out["theta_density"]["trans"][-1]["density"] - TAU_STAR)
    dev_c = abs(out["theta_density"]["cis"][-1]["density"] - 1.5)
    dev_w = abs(rows[-1]["density"] - CCT_DENSITY)
    log(f"  deviations from limits: trans {dev_t:.2e} (tau*), "
        f"cis {dev_c:.2e} (3/2), cct {dev_w:.2e} (1.40323087)")
    out["limit_deviations"] = {"trans": dev_t, "cis": dev_c, "cct": dev_w}

    # CF part: exact AB LP over independent-set columns at 1-6 blocks.
    # NOTE (definitional): CF is a fraction, CF <= 1 by definition, so the
    # pre-registered "CF = Theta(N)" is unsatisfiable as written; the
    # extensive certificate is -ln NCF, whose per-block density we report.
    log("  CF of the glued block-local quantum table (exact LP):")
    meshes = [("chain", nb, lts.pentagon_chain(nb)) for nb in range(1, 6)]
    meshes += [("trans-ring", N, lts.pentagon_ring(N)) for N in (3, 4, 5)]
    meshes += [("cis-ring", N, lts.pentagon_ring_cis(N)) for N in (3, 4, 5)]
    meshes += [("cct-ring", L, lts.pentagon_ring_word("cct", L // 3))
               for L in (3, 6)]
    meshes += [("quad", 4, (8, quad_edges))]
    cf_rows = []
    for name, nb, (n, edges) in meshes:
        t0 = time.perf_counter()
        ncf, m = ncf_lp(n, edges)
        cf_rows.append({"mesh": name, "blocks": nb, "vertices": n,
                        "isets": m, "ncf": ncf, "cf": 1 - ncf,
                        "lognc_density": -math.log(max(ncf, 1e-300)) / nb})
        log(f"    {name:10s} L={nb}  n={n:2d}  isets={m:6d}  "
            f"NCF={ncf:.7f}  CF={1-ncf:.7f}  -ln(NCF)/L={cf_rows[-1]['lognc_density']:.5f}"
            f"  ({time.perf_counter()-t0:.1f}s)")
    out["cf"] = cf_rows
    RESULTS["h1"] = out
    return out


# === PART3 ===
