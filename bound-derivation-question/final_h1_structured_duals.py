"""
ESSAY-005 LANE 2 (decisive): test the NAMED structured optimal duals and the
GAUGE-INVARIANCE of any Q/Z class built from them.

We construct, exactly (Fraction), the project's canonical optimal duals and
alternative optimal duals on the SAME optimal face, then ask for each:
  (a) is it dual-optimal (feasible coverage>=1, value == L_k)?
  (b) is ybar = y* mod Z a Cech 0-COCYCLE  (y(K)==y(K') mod Z on all overlaps)?
      -> prerequisite for delta:H^0(Q/Z)->H^1(Z) to even be DEFINED.
  (c) if cocycle: what is delta[ybar] in H^1(nerve;Z)?  (0 iff ybar lifts to a
      Z-valued 0-cochain that is a cocycle... but the whole point is invariance.)

DECISIVE gauge test at C5,k=2: exhibit TWO optimal duals
    D_int  = 1 on a pentad-partition (slope family)     -> integer, ybar==0
    D_half = 1/2 on the union of two pentad-partitions   -> ybar=1/2 on 10 pentads
Both are optimal (value 5). If one is a cocycle and the other is not, the
'class' is NOT well-defined on the optimal face => not a cohomology class.
"""
import itertools, numpy as np, networkx as nx
from fractions import Fraction
from collections import defaultdict

def conormal_power(n,k):
    verts=list(itertools.product(range(n),repeat=k))
    G=nx.Graph(); G.add_nodes_from(range(len(verts)))
    for i in range(len(verts)):
        for j in range(i+1,len(verts)):
            if any((verts[i][t]-verts[j][t])%n in (1,n-1) for t in range(k)):
                G.add_edge(i,j)
    return G,verts,{v:i for i,v in enumerate(verts)}

def max_cliques(G): return [frozenset(c) for c in nx.find_cliques(G)]

def overlaps(cliques):
    byv=defaultdict(list)
    for ci,K in enumerate(cliques):
        for v in K: byv[v].append(ci)
    P=set()
    for lst in byv.values():
        for a in range(len(lst)):
            for b in range(a+1,len(lst)):
                P.add((lst[a],lst[b]))
    return P

def coverage(yfrac,cliques,nV):
    cov=[Fraction(0)]*nV
    for ci,f in yfrac.items():
        for v in cliques[ci]: cov[v]+=f
    return cov

def is_optimal_dual(yfrac,cliques,nV,Lk):
    cov=coverage(yfrac,cliques,nV)
    feas=all(c>=1 for c in cov)
    val=sum(yfrac.values())
    return feas, val, min(cov), max(cov)

def cocycle_bad(yfrac,cliques,pairs):
    bad=0; ex=[]
    for (a,b) in pairs:
        d=yfrac.get(a,Fraction(0))-yfrac.get(b,Fraction(0))
        if d.denominator!=1:
            bad+=1
            if len(ex)<4: ex.append((a,b,str(yfrac.get(a,Fraction(0))),str(yfrac.get(b,Fraction(0)))))
    return bad,ex

# ---------- C5, k=2 ----------
print("################  C5, k=2  (quantum sqrt5 ; L=5)  ################")
G,verts,idx=conormal_power(5,2); nV=len(verts)
cl=max_cliques(G); pairs=overlaps(cl)
pent=[i for i,K in enumerate(cl) if len(K)==5]
print(f"|V|={nV}  maxCliques={len(cl)}  5-cliques(pentads)={len(pent)}  overlaps={len(pairs)}")

# find all pentad-PARTITIONS (5 disjoint pentads covering 25)
pentsets=[cl[i] for i in pent]
partitions=[]
def search(chosen,covered):
    if len(chosen)==5:
        if len(covered)==25: partitions.append(list(chosen)); return
        return
    start=chosen[-1]+1 if chosen else 0
    for t in range(start,len(pent)):
        if pentsets[t].isdisjoint(covered):
            search(chosen+[t],covered|pentsets[t])
search([],frozenset())
print(f"pentad-partitions of the 25 events: {len(partitions)}  (each = 5 disjoint pentads)")

def dual_from_partition(part, w):
    return {pent[t]:Fraction(w) for t in part}

Lk=5
if len(partitions)>=2:
    D1=dual_from_partition(partitions[0],1)
    D2=dual_from_partition(partitions[1],1)
    # D_half: 1/2 on union of the two partitions' pentads
    union_idx=set(partitions[0])|set(partitions[1])
    Dhalf={pent[t]:Fraction(1,2) for t in union_idx}
    for name,D in [("D_int (partition #0, y=1)",D1),
                   ("D_int (partition #1, y=1)",D2),
                   ("D_half (1/2 on both partitions)",Dhalf)]:
        feas,val,cmin,cmax=is_optimal_dual(D,cl,nV,Lk)
        bad,ex=cocycle_bad(D,cl,pairs)
        print(f"\n  {name}")
        print(f"    optimal? feasible={feas} value={val} coverage[min,max]=[{cmin},{cmax}]  (need feas & value=5)")
        print(f"    cocycle? bad_overlaps={bad}  -> {'COCYCLE (delta defined), ybar values reduce to '+('0 (all integer)' if all(v.denominator==1 for v in D.values()) else 'nonzero') if bad==0 else 'NOT a cocycle (delta UNDEFINED)'}")
        if ex: print(f"       e.g. {ex[:2]}")

# ---------- C7, k=2 ----------
print("\n################  C7, k=2  (control ; L=49/4, fractional/stuck)  ################")
G7,verts7,idx7=conormal_power(7,2); nV7=len(verts7)
cl7=max_cliques(G7); pairs7=overlaps(cl7)
print(f"|V|={nV7}  maxCliques={len(cl7)}  overlaps={len(pairs7)}")
# structured 'edge-square' 4-cliques {a,a+1} x {b,b+1}
def sq(a,b):
    return frozenset(idx7[(x%7,y%7)] for x in (a,a+1) for y in (b,b+1))
squares={}
cl7_set={K:i for i,K in enumerate(cl7)}
n_sq=0; missing=0
Dsq={}
for a in range(7):
    for b in range(7):
        K=sq(a,b)
        if K in cl7_set:
            Dsq[cl7_set[K]]=Fraction(1,4); n_sq+=1
        else:
            missing+=1
print(f"edge-square 4-cliques present as maximal cliques: {n_sq} (expected 49); missing={missing}")
feas,val,cmin,cmax=is_optimal_dual(Dsq,cl7,nV7,Fraction(49,4))
bad,ex=cocycle_bad(Dsq,cl7,pairs7)
print(f"\n  D_sq (y=1/4 on 49 edge-squares)")
print(f"    optimal? feasible={feas} value={val} coverage[min,max]=[{cmin},{cmax}]  (need feas & value=49/4)")
print(f"    cocycle? bad_overlaps={bad}  -> {'COCYCLE (delta defined)' if bad==0 else 'NOT a cocycle (delta UNDEFINED for the canonical C7 dual)'}")
if ex: print(f"       e.g. {ex[:3]}")

print("\n================  VERDICT  ================")
print("If D_int is a cocycle but D_half is not (both optimal at C5,k=2), and")
print("D_sq is not a cocycle at C7,k=2, then delta(y* mod Z) is neither")
print("well-defined nor gauge-invariant on the optimal dual face.")
