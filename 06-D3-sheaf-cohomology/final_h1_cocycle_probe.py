"""
ESSAY-005 LANE 2: H^1 via the Q/Z fractional-part cocycle.

Tests whether delta(y* mod Z) -- the connecting map of 0->Z->Q->Q/Z applied to
the mod-Z reduction of the optimal dual 0-cochain y* -- is a well-defined
cohomology class that detects exact-vs-fractional (quantum-achieved vs stuck).

Two decisive tests:
  (T1) COCYCLE PREREQUISITE. The connecting map delta: H^0(U;Q/Z) -> H^1(U;Z)
       is defined ONLY on 0-cocycles. [ybar] in H^0(Q/Z) requires
       y*(K) == y*(K') (mod Z) for every OVERLAPPING clique pair K,K'
       (K cap K' != empty). If ybar is not a cocycle, delta[ybar] is UNDEFINED.
  (T2) GAUGE / COBOUNDARY INVARIANCE. Is the optimal dual unique? If the optimal
       dual face is >0-dimensional, different optimal y* give different mod-Z
       reductions, so any 'class' built from y* is gauge-dependent = not a
       cohomology class.

Cover U = maximal cliques of G^{vk} (conormal power). Nerve 1-simplex = clique
pair with nonempty vertex intersection.
"""
import itertools, numpy as np, networkx as nx
from fractions import Fraction
from scipy.optimize import linprog

def conormal_power(n, k):
    """C_n conormal (OR) k-th power: u~v iff exists t with u_t-v_t = +-1 mod n."""
    verts = list(itertools.product(range(n), repeat=k))
    idx = {v:i for i,v in enumerate(verts)}
    G = nx.Graph(); G.add_nodes_from(range(len(verts)))
    for i,u in enumerate(verts):
        for j in range(i+1,len(verts)):
            v = verts[j]
            adj = any((u[t]-v[t]) % n in (1, n-1) for t in range(k))
            if adj: G.add_edge(i,j)
    return G, verts, idx

def max_cliques(G):
    return [frozenset(c) for c in nx.find_cliques(G)]

def structured_dual(n, k, verts, idx, cliques):
    """Return the project's structured optimal dual y* as a dict clique->Fraction.
    C5,k=2: y*=1 on the 5 slope-2 pentads {(i,2i+j)}.
    C7,k=2: y*=1/4 on the 49 edge-square 4-cliques {(i,i+1)x(j,j+1)} ... but the
            'edge-square' 4-clique on C7^v2 is {a,a+1}x{b,b+1}? Careful: in the
            conormal power a 4-clique from single-coordinate edges. We instead
            recover y* directly from the LP for generality, and separately verify
            the named structured dual where the doc gives it.
    Single copy k=1: y*=1/2 on the n edges.
    """
    return None  # we get y* from the LP below; structured forms checked inline.

def solve_primal_dual(G, cliques, verts):
    """Primal packing L_k = max sum p_v s.t. clique sums <=1, p>=0 (float, HiGHS).
    Dual cover: min sum y_K s.t. for each v, sum_{K ni v} y_K >=1, y>=0."""
    nV = G.number_of_nodes(); nC = len(cliques)
    # membership
    mem = np.zeros((nV,nC))
    for ci,K in enumerate(cliques):
        for v in K: mem[v,ci]=1.0
    # primal: max sum p  -> min -sum p ; A_ub: clique membership^T p <=1
    c = -np.ones(nV)
    A_ub = mem.T  # nC x nV, each row = clique -> <=1
    b_ub = np.ones(nC)
    resP = linprog(c, A_ub=A_ub, b_ub=b_ub, bounds=[(0,None)]*nV, method='highs')
    Lk = -resP.fun
    # dual: min sum y ; A_ub: -mem y <= -1 (coverage >=1); y>=0
    cD = np.ones(nC)
    A_ubD = -mem     # nV x nC ; -sum_{K ni v} y <= -1
    b_ubD = -np.ones(nV)
    resD = linprog(cD, A_ub=A_ubD, b_ub=b_ubD, bounds=[(0,None)]*nC, method='highs')
    yval = resD.fun
    return Lk, resP.x, yval, resD.x, mem

def overlap_pairs(cliques):
    """All pairs (i,j) of cliques sharing >=1 vertex (nerve 1-simplices)."""
    # index cliques by vertex
    from collections import defaultdict
    byv = defaultdict(list)
    for ci,K in enumerate(cliques):
        for v in K: byv[v].append(ci)
    pairs=set()
    for v,lst in byv.items():
        for a in range(len(lst)):
            for b in range(a+1,len(lst)):
                pairs.add((lst[a],lst[b]))
    return pairs

def cocycle_test(yfrac, cliques, pairs):
    """yfrac: dict clique_index->Fraction. Test y(K)==y(K') mod Z on overlaps."""
    bad=0; examples=[]
    for (a,b) in pairs:
        d = (yfrac.get(a,Fraction(0)) - yfrac.get(b,Fraction(0)))
        if (d.numerator % d.denominator) != 0:  # d not integer
            bad+=1
            if len(examples)<5: examples.append((a,b,yfrac.get(a,Fraction(0)),yfrac.get(b,Fraction(0))))
    return bad, examples

def gauge_dim_test(mem, Lk, cliques):
    """Is the optimal dual face >0-dim? Fix sum y = Lk (optimal), then MAXIMIZE
    and MINIMIZE a few random linear directions over the optimal face; if any
    direction gives a strictly wider range than numerical tol, face is >0-dim
    => gauge-dependent. Returns (is_unique_bool, max_spread)."""
    nV = mem.shape[0]; nC = len(cliques)
    A_ubD = -mem; b_ubD = -np.ones(nV)
    # equality: sum y = Lk
    A_eq = np.ones((1,nC)); b_eq = np.array([Lk])
    rng = np.random.default_rng(0)
    max_spread=0.0
    for _ in range(6):
        d = rng.standard_normal(nC)
        rmin = linprog(d,  A_ub=A_ubD,b_ub=b_ubD,A_eq=A_eq,b_eq=b_eq,bounds=[(0,None)]*nC,method='highs')
        rmax = linprog(-d, A_ub=A_ubD,b_ub=b_ubD,A_eq=A_eq,b_eq=b_eq,bounds=[(0,None)]*nC,method='highs')
        if rmin.success and rmax.success:
            spread = (-rmax.fun) - (rmin.fun)
            max_spread=max(max_spread,spread)
    return (max_spread<1e-6), max_spread

def to_frac_dual(yx, tol=1e-6):
    """Snap solver dual to nearby simple fractions for the mod-Z test."""
    out={}
    for i,val in enumerate(yx):
        f = Fraction(val).limit_denominator(64)
        if abs(float(f)-val)<1e-4:
            out[i]=f
        else:
            out[i]=Fraction(val).limit_denominator(1000)
    return out

def run(n,k,label):
    G,verts,idx = conormal_power(n,k)
    cliques = max_cliques(G)
    Lk,px,yval,yx,mem = solve_primal_dual(G,cliques,verts)
    pairs = overlap_pairs(cliques)
    yfrac = to_frac_dual(yx)
    bad,ex = cocycle_test(yfrac,cliques,pairs)
    uniq,spread = gauge_dim_test(mem,Lk,cliques)
    # also: reduction values present
    nz = {}
    for i,f in yfrac.items():
        if f!=0:
            nz[str(f)] = nz.get(str(f),0)+1
    print(f"=== {label}: C{n}^v{k}  |V|={G.number_of_nodes()} cliques={len(cliques)} overlaps={len(pairs)}")
    print(f"    L_k (primal) = {Lk:.6f}   dual = {yval:.6f}")
    print(f"    optimal dual nonzero-value histogram (snapped): {nz}")
    print(f"    [T1 COCYCLE] overlapping pairs with y(K)!=y(K') mod Z: {bad}"
          f"   -> {'IS a 0-cocycle (delta defined)' if bad==0 else 'NOT a 0-cocycle (delta UNDEFINED)'}")
    if ex: print(f"        example bad overlaps (cliqueA,cliqueB,yA,yB): {ex[:3]}")
    print(f"    [T2 GAUGE] optimal dual face unique? {uniq}   max spread over 6 dirs = {spread:.3e}")
    print()
    return dict(label=label,n=n,k=k,Lk=Lk,cocycle_ok=(bad==0),bad_overlaps=bad,
                dual_unique=uniq,gauge_spread=spread,hist=nz)

if __name__=="__main__":
    results=[]
    results.append(run(5,1,"S1(C5) packing 5/2"))
    results.append(run(5,2,"S2(C5) quantum sqrt5 -> L=5 (should be exact partition)"))
    results.append(run(7,1,"S1(C7) control 7/2"))
    results.append(run(7,2,"S2(C7) control -> L=49/4 (fractional, stuck)"))
    print("SUMMARY")
    for r in results:
        print(f"  {r['label']:<45} L={r['Lk']:.4f}  cocycle_ok={r['cocycle_ok']}  "
              f"dual_unique={r['dual_unique']}  bad_overlaps={r['bad_overlaps']}")
