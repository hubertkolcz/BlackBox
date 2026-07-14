"""
Lasserre level-2 (las_2 = BGSV s=2,t=0) SDP bound on the independence number of
X125 = Cbar5 (X) Cbar5 (X) Cbar5  =  Cay(Z5^3, S),  adjacency:
   adjX(u,v) = (u!=v) and all((u[k]-v[k])%5 in (0,2,3) for k in 0..2).
Known facts (validation gates): alpha=10, theta=5*sqrt5=11.18034, three-point(s=1,t=1)=11.00890.

Method (group-algebra block-diagonalization, cf. erg003_threepoint_sibling.py):
 * Moment matrix M2 indexed by I = { independent sets of size <=2 } (|I|=6251:
   1 empty + 125 singletons + 6125 stable pairs).  M2[S,T]=y_{S u T}; y_emptyset=1;
   y_W=0 if W not independent; free variables = one per orbit of the FULL automorphism
   group Gamma = Z5^3 rtimes G0 (|Gamma|=6000) on independent <=4-sets (K=475 orbits).
 * Objective: maximize sum_v y_{{v}} = 125 * y_(singleton orbit).  Constraint M2>>0.
 * Gamma acts on I by permutations; A0 = sum_g c_g P_g (generic self-adjoint group-algebra
   element) has eigenspaces = the SDP blocks (M2 commutes with every P_g, hence with A0).
   A second generic A1 identifies eigenspaces of the same irrep (V_a^T A1 V_b != 0 iff
   same irrep) so we keep ONE representative block per irrep (35 blocks, max size 30).
 * Each block's coefficient matrices B_{E,r}=Q_E^T E_r Q_E (E_r = indicator of index-pairs
   (S,T) with orbit(S u T)=r) are affine in the y_r; solve max 125*y_pt s.t. all blocks>>0.

Solvers: CLARABEL (fallback SCS). MOSEK not required. Correctness > speed.
Caches core.npz/eig.npz/reps.npz/LAB.npy/coeffs.npz; delete them to force a full recompute.
"""
import numpy as np, itertools, time, os, cvxpy as cp
np.random.seed(0)
n=5; N=125
T0=time.time()
def log(*a): print(*a,flush=True)

# ============================================================ core structures
def build_core():
    elems=np.array(list(itertools.product(range(n),repeat=3)))
    Dm=(elems[:,None,:]-elems[None,:,:])%5
    inset=np.isin(Dm,[0,2,3]).all(axis=2); notzero=(Dm!=0).any(axis=2)
    ADJ=inset&notzero; STAB=(~np.eye(N,dtype=bool))&(~ADJ)
    idx={tuple(e):i for i,e in enumerate(elems.tolist())}
    def negc(a,c): return tuple(v if k!=c else (-v)%n for k,v in enumerate(a))
    def prm(a,p): return (a[p[0]],a[p[1]],a[p[2]])
    def transl(a,k): return tuple((a[i]+(1 if i==k else 0))%n for i in range(3))
    def as_perm(f): return tuple(idx[f(tuple(e))] for e in elems.tolist())
    gens=[lambda a:negc(a,0),lambda a:negc(a,1),lambda a:negc(a,2),
          lambda a:prm(a,(1,0,2)),lambda a:prm(a,(1,2,0)),
          lambda a:transl(a,0),lambda a:transl(a,1),lambda a:transl(a,2)]
    gp=[as_perm(g) for g in gens]; grp={tuple(range(N))}; fr=[tuple(range(N))]
    while fr:
        nf=[]
        for q in fr:
            for g in gp:
                r=tuple(g[q[i]] for i in range(N))
                if r not in grp: grp.add(r); nf.append(r)
        fr=nf
    Gamma=np.array(sorted(grp),dtype=np.int32); assert Gamma.shape[0]==6000
    for gi in [1,10,100,3000,5999]:
        g=Gamma[gi]; assert np.array_equal(ADJ[np.ix_(g,g)],ADJ)
    ii,jj=np.nonzero(np.triu(STAB,1)); pairs=np.stack([ii,jj],1).astype(np.int32)
    nP=pairs.shape[0]; nI=1+N+nP
    pid=-np.ones((N,N),np.int32); pidx=126+np.arange(nP)
    pid[pairs[:,0],pairs[:,1]]=pidx; pid[pairs[:,1],pairs[:,0]]=pidx
    Iv0=np.full(nI,125,np.int32); Iv1=np.full(nI,125,np.int32)
    Iv0[1:1+N]=np.arange(N); Iv0[126:]=pairs[:,0]; Iv1[126:]=pairs[:,1]
    # enumerate stable <=4 sets
    def ext(sa):
        out=[]
        for s in sa:
            common=STAB[s[0]].copy()
            for v in s[1:]: common&=STAB[v]
            for c in np.nonzero(common)[0]:
                if c>s[-1]: out.append(list(s)+[int(c)])
        return np.array(out,np.int32) if out else np.zeros((0,sa.shape[1]+1),np.int32)
    S1=np.arange(N,dtype=np.int32)[:,None]; S2=pairs.copy(); S3=ext(S2); S4=ext(S3)
    POW=np.array([1,126,126**2,126**3],np.int64)
    def keyof(sa):
        M,k=sa.shape; pad=np.full((M,4),125,np.int64); pad[:,:k]=np.sort(sa,axis=1); return pad@POW
    def orbit_ids(sa,id0):
        if sa.shape[0]==0: return np.zeros(0,np.int64),np.zeros(0,np.int32),0
        keys=keyof(sa); o=np.argsort(keys); keys=keys[o]; verts=sa[o]
        oid=-np.ones(len(keys),np.int32); cur=id0; k=sa.shape[1]
        for i in range(len(keys)):
            if oid[i]>=0: continue
            img=Gamma[:,verts[i]]; img.sort(axis=1)
            pad=np.full((img.shape[0],4),125,np.int64); pad[:,:k]=img
            ik=np.unique(pad@POW); oid[np.searchsorted(keys,ik)]=cur; cur+=1
        return keys,oid,cur-id0
    k1,o1,p1=orbit_ids(S1,1); k2,o2,p2=orbit_ids(S2,1+p1)
    k3,o3,p3=orbit_ids(S3,1+p1+p2); k4,o4,p4=orbit_ids(S4,1+p1+p2+p3)
    assert p1==1
    empty_key=np.int64(POW@np.array([125,125,125,125]))
    SK=np.concatenate([[empty_key],k1,k2,k3,k4]); SOID=np.concatenate([[0],o1,o2,o3,o4]).astype(np.int32)
    o=np.argsort(SK); SK=SK[o]; SOID=SOID[o]; assert (np.diff(SK)>0).all()
    K=1+p1+p2+p3+p4
    log("  |Gamma|=6000  |I|=%d  stable pairs=%d  orbit counts: size2=%d size3=%d size4=%d  K=%d"
        %(nI,nP,p2,p3,p4,K))
    np.savez("core.npz",Gamma=Gamma,pairs=pairs,pid=pid,Iv0=Iv0,Iv1=Iv1,SK=SK,SOID=SOID,
             K=K,nI=nI,singleton_oid=1,POW=POW,STAB=STAB,ADJ=ADJ)

if not os.path.exists("core.npz"): log("[core] building..."); build_core()
C=np.load("core.npz")
Gamma=C["Gamma"]; pairs=C["pairs"]; pid=C["pid"]; Iv0=C["Iv0"]; Iv1=C["Iv1"]
SK=C["SK"]; SOID=C["SOID"]; K=int(C["K"]); nI=int(C["nI"]); POW=C["POW"].astype(np.int64)
ADJ=C["ADJ"]; STAB=C["STAB"]; singleton_oid=int(C["singleton_oid"]); DUMP=K
a_end=pairs[:,0]; b_end=pairs[:,1]; ar=np.arange(nI); nG=Gamma.shape[0]

# ============================================================ GATE 1: alpha=10
def gate1():
    import networkx as nx
    Comp=nx.from_numpy_array(STAB.astype(int))
    alpha=max(len(c) for c in nx.find_cliques(Comp))
    log("GATE1: alpha(X125) = max clique in complement = %d   (expect 10)  -> %s"
        %(alpha,"PASS" if alpha==10 else "FAIL"))
    return alpha

# ============================================================ GATE 2: theta
def gate2():
    Y=cp.Variable((N+1,N+1),symmetric=True); cons=[Y>>0,Y[0,0]==1]
    for i in range(N): cons.append(Y[i+1,i+1]==Y[0,i+1])
    ii,jj=np.nonzero(np.triu(ADJ,1))
    for i,j in zip(ii,jj): cons.append(Y[i+1,j+1]==0)
    p=cp.Problem(cp.Maximize(cp.sum(Y[0,1:])),cons); p.solve(solver=cp.CLARABEL)
    log("GATE2: las_1 = Lovasz theta(X125) = %.5f  (expect %.5f=5*sqrt5)  -> %s"
        %(p.value,5*np.sqrt(5),"PASS" if abs(p.value-5*np.sqrt(5))<1e-3 else "FAIL"))
    return p.value

# ============================================================ block-diagonalization
def perm_I(g):
    p=np.empty(nI,np.int64); p[0]=0; p[1:126]=1+g; p[126:]=pid[g[a_end],g[b_end]]; return p
def rand_group_algebra(seed):
    rng=np.random.default_rng(seed); c=rng.standard_normal(nG); A=np.zeros((nI,nI))
    for gi in range(nG): A[perm_I(Gamma[gi]),ar]+=c[gi]
    return (A+A.T)*0.5

def build_blocks():
    if os.path.exists("eig.npz") and os.path.exists("reps.npz"):
        return
    log("[blocks] building A0 & eigendecomposition (~25s)...")
    A0=rand_group_algebra(12345); w,V=np.linalg.eigh(A0)
    lens=[]; i=0
    grp=[[0]]
    for i in range(1,nI):
        if abs(w[i]-w[grp[-1][-1]])<=1e-6*max(1,abs(w[i]))+1e-8: grp[-1].append(i)
        else: grp.append([i])
    lens=np.array([len(g) for g in grp]); starts=np.concatenate([[0],np.cumsum(lens)])[:-1]
    np.savez("eig.npz",w=w,V=V.astype(np.float64),group_ptr=lens)
    # identify irreps via A1
    log("[blocks] identifying irrep representatives via A1...")
    A1=rand_group_algebra(99); M1=V.T@(A1@V); Sm=M1*M1
    bn=np.sqrt(np.add.reduceat(np.add.reduceat(Sm,starts,0),starts,1)); thr=1e-6*bn.max()
    adj=bn>thr; par=list(range(len(lens)))
    def find(x):
        while par[x]!=x: par[x]=par[par[x]]; x=par[x]
        return x
    for i in range(len(lens)):
        for j in range(i+1,len(lens)):
            if adj[i,j]:
                ri,rj=find(i),find(j)
                if ri!=rj: par[ri]=rj
    comp={}
    for i in range(len(lens)): comp.setdefault(find(i),[]).append(i)
    reps=[g[0] for g in comp.values()]
    for g in comp.values(): assert len(set(int(lens[x]) for x in g))==1
    rstarts=np.array([starts[r] for r in reps]); rlens=np.array([lens[r] for r in reps])
    log("[blocks] %d representative irrep blocks, sizes=%s"%(len(reps),sorted(int(x) for x in rlens)))
    np.savez("reps.npz",rep_starts=rstarts,rep_lens=rlens)

def build_LAB():
    if os.path.exists("LAB.npy"): return
    log("[LAB] building %dx%d moment-matrix orbit-label array (~25s)..."%(nI,nI))
    Iv0_64=Iv0.astype(np.int64); Iv1_64=Iv1.astype(np.int64); lenSK=len(SK)
    LAB=np.empty((nI,nI),np.int32)
    for S in range(nI):
        cands=np.empty((nI,4),np.int64)
        cands[:,0]=int(Iv0_64[S]); cands[:,1]=int(Iv1_64[S]); cands[:,2]=Iv0_64; cands[:,3]=Iv1_64
        cands.sort(axis=1)
        dup=cands[:,1:]==cands[:,:-1]; sub=cands[:,1:]; sub[dup]=125; cands.sort(axis=1)
        key=cands@POW; pos=np.minimum(np.searchsorted(SK,key),lenSK-1)
        hit=SK[pos]==key; LAB[S]=np.where(hit,SOID[pos],DUMP).astype(np.int32)
    assert np.array_equal(LAB,LAB.T)
    np.save("LAB.npy",LAB)

def build_coeffs():
    if os.path.exists("coeffs.npz"): return
    e=np.load("eig.npz"); V=e["V"]; r=np.load("reps.npz")
    rstarts=r["rep_starts"]; rlens=r["rep_lens"]; LAB=np.load("LAB.npy"); nblk=len(rstarts)
    flat=LAB.ravel(); nz=np.nonzero(flat!=DUMP)[0]
    labels=flat[nz].astype(np.int32); Snz=(nz//nI).astype(np.int32); Tnz=(nz%nI).astype(np.int32)
    del flat,nz
    log("[coeffs] projecting %d nonzero entries onto %d blocks (~10min)..."%(len(labels),nblk))
    coeffs=[]; ts=time.time()
    for bi in range(nblk):
        s=int(rstarts[bi]); L=int(rlens[bi]); Q=np.ascontiguousarray(V[:,s:s+L])
        Qc=[np.ascontiguousarray(Q[:,i]) for i in range(L)]; B=np.zeros((K,L,L))
        for i in range(L):
            qi=Qc[i][Snz]
            for j in range(i,L):
                col=np.bincount(labels,weights=qi*Qc[j][Tnz],minlength=K)[:K]
                B[:,i,j]=col; B[:,j,i]=col
        coeffs.append(B)
        log("   block %2d/%d L=%2d  [%.0fs]"%(bi+1,nblk,L,time.time()-ts))
    # validation: random y, direct projection vs coefficient-sum
    rng=np.random.default_rng(3); yv=rng.standard_normal(K); M2=np.append(yv,0.0)[LAB]; mx=0.0
    for bi in range(nblk):
        s=int(rstarts[bi]); L=int(rlens[bi]); Q=V[:,s:s+L]
        mx=max(mx,np.abs(Q.T@M2@Q-np.tensordot(yv,coeffs[bi],axes=(0,0))).max())
    log("[coeffs] end-to-end validation max|direct-coeffsum| = %.2e  -> %s"%(mx,"PASS" if mx<1e-8 else "FAIL"))
    assert mx<1e-8
    np.savez("coeffs.npz",**{"c%d"%i:coeffs[i] for i in range(nblk)},rlens=rlens,K=K)

# ============================================================ solve las_2
def solve_las2():
    z=np.load("coeffs.npz"); rlens=z["rlens"]; nblk=len(rlens); coeffs=[z["c%d"%i] for i in range(nblk)]
    y=cp.Variable(K); cons=[y[0]==1]
    for bi in range(nblk):
        B=coeffs[bi]; nzr=[r for r in range(K) if np.abs(B[r]).max()>1e-12]
        cons.append(sum(y[r]*B[r] for r in nzr)>>0)     # cvxpy scalar FIRST
    prob=cp.Problem(cp.Maximize(125*y[singleton_oid]),cons)
    vals={}
    # primary: CLARABEL; fall back to SCS eps=1e-7 only if CLARABEL errors
    t=time.time()
    try:
        prob.solve(solver=cp.CLARABEL); vals["CLARABEL"]=(prob.value,prob.status)
        log("  [CLARABEL]       las_2=%.6f  floor=%d  status=%s  [%.1fs]"
            %(prob.value,int(np.floor(prob.value+1e-7)),prob.status,time.time()-t))
    except Exception as ex:
        log("  [CLARABEL] error -> SCS fallback: %r"%ex); t=time.time()
        prob.solve(solver=cp.SCS,eps=1e-7,max_iters=200000); vals["SCS"]=(prob.value,prob.status)
        log("  [SCS]            las_2=%.6f  floor=%d  status=%s  [%.1fs]"
            %(prob.value,int(np.floor(prob.value+1e-7)),prob.status,time.time()-t))
    # cheap independent cross-check with a tighter CLARABEL tolerance
    try:
        t=time.time(); prob.solve(solver=cp.CLARABEL,tol_gap_abs=1e-9,tol_gap_rel=1e-9,tol_feas=1e-9,max_iter=500)
        vals["CLARABEL-tight"]=(prob.value,prob.status)
        log("  [CLARABEL-tight] las_2=%.6f  floor=%d  status=%s  [%.1fs]"
            %(prob.value,int(np.floor(prob.value+1e-7)),prob.status,time.time()-t))
    except Exception as ex:
        log("  [CLARABEL-tight] error: %r"%ex)
    return vals,nblk,int(max(int(x) for x in rlens))

# ============================================================ run
log("="*70); log("las_2 (Lasserre level-2, s=2 t=0) on X125");  log("="*70)
alpha=gate1()
theta=gate2()
log("GATE3: three-point (s=1,t=1) reference = 11.00890 (see erg003_threepoint_sibling.py)")
build_blocks(); build_LAB(); build_coeffs()
log("-"*70); log("Solving las_2 SDP:")
vals,nblk,maxblk=solve_las2()
best=vals.get("CLARABEL",vals.get("SCS",vals.get("CLARABEL-tight")))
v=best[0]
log("-"*70)
log("RESULT: las_2(X125) = %.5f   floor = %d   (#blocks=%d, max block=%d)"%(v,int(np.floor(v+1e-6)),nblk,maxblk))
log("GATE4: 10 <= las_2 <= 11.00890 <= 11.18034 :  %s"
    %("PASS" if (10-1e-6)<=v<=11.00890+1e-4 else "FAIL"))
if v<11-1e-4: log("VERDICT: floor(las_2)=10  => s=2 CLOSES the gap (las_2<11).")
else:         log("VERDICT: floor(las_2)=%d => s=2 does NOT close the gap (las_2 not <11)."%int(np.floor(v+1e-6)))
log("total wall time %.1fs"%(time.time()-T0))
