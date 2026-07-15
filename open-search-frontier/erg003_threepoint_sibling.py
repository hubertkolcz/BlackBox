import numpy as np, itertools, cvxpy as cp, time
n=5; N=125; M=N+1   # 126: index 0 = emptyset, 1..125 = vertices
elems=list(itertools.product(range(n),repeat=3)); idx={e:i for i,e in enumerate(elems)}
def diff(a,b): return tuple((a[i]-b[i])%n for i in range(3))
def adjX(a,b):
    d=diff(a,b); return d!=(0,0,0) and all(x in (0,2,3) for x in d)
def stable(a,b): return a!=b and not adjX(a,b)
def negc(a,c): return tuple(v if k!=c else (-v)%n for k,v in enumerate(a))
def prm(a,p): return (a[p[0]],a[p[1]],a[p[2]])
def as_perm(f): return tuple(idx[f(e)] for e in elems)
gens=[lambda a:negc(a,0),lambda a:negc(a,1),lambda a:negc(a,2),lambda a:prm(a,(1,0,2)),lambda a:prm(a,(1,2,0))]
gp=[as_perm(g) for g in gens]; grp={tuple(range(N))}; fr=[tuple(range(N))]
while fr:
    nf=[]
    for q in fr:
        for g in gp:
            r=tuple(g[q[i]] for i in range(N))
            if r not in grp: grp.add(r); nf.append(r)
    fr=nf
G0p=list(grp)
# G0' on 126 points (point 0 = emptyset, fixed; points shifted by +1)
G0M=[np.array([0]+[p[i]+1 for i in range(N)]) for p in G0p]
nb0=[i for i in range(N) if stable(elems[0],elems[i])]
seen=set(); edge_reps=[]; edge_id={}
for i in nb0:
    if i in seen: continue
    for g in G0p: seen.add(g[i])
    for g in G0p: edge_id.setdefault(g[i], len(edge_reps))
    edge_reps.append(i)
nE=len(edge_reps)
import itertools as it
def canon_triple(v,w):
    best=None
    for tp in it.permutations([0,v,w]):
        o=tp[0]; sh=tuple((-elems[o][k])%n for k in range(3))
        a=idx[tuple((elems[tp[1]][k]+sh[k])%n for k in range(3))]
        b=idx[tuple((elems[tp[2]][k]+sh[k])%n for k in range(3))]
        for g in G0p:
            key=tuple(sorted((g[a],g[b])))
            if best is None or key<best: best=key
    return best
tri_id={}
for i in nb0:
    for j in nb0:
        if i!=j and stable(elems[i],elems[j]):
            k=canon_triple(i,j); tri_id.setdefault(k,len(tri_id))
nT=len(tri_id)
print("edge-orbits=%d  triangle-orbits=%d"%(nE,nT),flush=True)
# coefficient matrices (126x126)
Ct_e=np.zeros((M,M)); Ce_e=[np.zeros((M,M)) for _ in range(nE)]; Cc=np.zeros((M,M)); Cc[0,0]=1
for i in range(N):
    Ct_e[0,i+1]+=1; Ct_e[i+1,0]+=1; Ct_e[i+1,i+1]+=1
for i in range(N):
    for j in range(i+1,N):
        if stable(elems[i],elems[j]):
            r=edge_id[idx[diff(elems[i],elems[j])]]; Ce_e[r][i+1,j+1]+=1; Ce_e[r][j+1,i+1]+=1
Ct_z=np.zeros((M,M)); Ct_z[0,0]=1
Ce_z=[np.zeros((M,M)) for _ in range(nE)]; Cf_z=[np.zeros((M,M)) for _ in range(nT)]
for i in range(N):
    if i in edge_id:
        r=edge_id[i]; Ce_z[r][0,i+1]+=1; Ce_z[r][i+1,0]+=1; Ce_z[r][i+1,i+1]+=1
for i in nb0:
    for j in nb0:
        if i<j and stable(elems[i],elems[j]):
            r=tri_id[canon_triple(i,j)]; Cf_z[r][i+1,j+1]+=1; Cf_z[r][j+1,i+1]+=1
# block-diagonalize 126-space via group-algebra element of G0'
rng=np.random.default_rng(1); A0=np.zeros((M,M))
for p,c in zip(G0M, rng.standard_normal(len(G0M))): A0[p,np.arange(M)]+=c
A0=(A0+A0.T)/2
w,V=np.linalg.eigh(A0); o=np.argsort(w); w,V=w[o],V[:,o]
groups=[[0]]
for i in range(1,M):
    if abs(w[i]-w[groups[-1][-1]])<=1e-7*max(1,abs(w[i]))+1e-8: groups[-1].append(i)
    else: groups.append([i])
Qs=[V[:,g] for g in groups]
print("num blocks (126-space) =",len(Qs)," sizes=",sorted(q.shape[1] for q in Qs),flush=True)
def proj(C): return [Q.T@C@Q for Q in Qs]
Pt_e=proj(Ct_e); Pc=proj(Cc); Pe_e=[proj(x) for x in Ce_e]
Pt_z=proj(Ct_z); Pe_z=[proj(x) for x in Ce_z]; Pf_z=[proj(x) for x in Cf_z]
t=cp.Variable(); e=cp.Variable(nE); f=cp.Variable(nT); cons=[]
for b in range(len(Qs)):
    Be = t*Pt_e[b] + Pc[b] + sum(e[r]*Pe_e[r][b] for r in range(nE))
    Bz = t*Pt_z[b] + sum(e[r]*Pe_z[r][b] for r in range(nE)) + sum(f[r]*Pf_z[r][b] for r in range(nT))
    cons += [Be>>0, Bz>>0]
t0=time.time()
prob=cp.Problem(cp.Maximize(N*t),cons)
try: prob.solve(solver=cp.CLARABEL, max_iter=2000)
except Exception as ex:
    print("CLARABEL failed (%r); trying SCS"%ex,flush=True); prob.solve(solver=cp.SCS,eps=1e-7,max_iters=200000)
print("THREE-POINT bound(X125) = %.5f  status=%s  [%.1fs]"%(prob.value,prob.status,time.time()-t0))
print("  theta=11.18034  alpha=10  floor(3pt)=%d"%int(np.floor(prob.value+1e-3)))
if prob.value is not None:
    print("  VERDICT: three-point %s"%("BEATS theta (below 11.18)" if prob.value<11.15 else "does NOT beat theta"))
    if prob.value<10.999: print("  *** reaches <=10 => method closes the odd-power gap (validates approach) ***")
