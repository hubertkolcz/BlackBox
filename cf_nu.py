"""Item #6: CF (contextual fraction) vs nu (signed negativity) rate for NON-cyclic scenarios
(Python-only; the repo's other implementation, SignedNegativity.wl, is Wolfram).

Background. For the n-CYCLE, CF = (n-1)*nu is a theorem (Camillo-Cervantes 2024, arXiv:
2305.16574); this repo's currency law CF = (n-1)*nu on the KCBS pentagon is its n=5 case.
QUANTUM_CONTEXTUALITY.md sec.9 left open "whether an analogous CF<->nu rate exists for a
specific NON-cyclic graph (CHSH gives 2 empirically; the general classification is uncharted)".

FINDING (charts that classification). The proportionality CF = c*nu, with a CONSTANT rate c
holding along the ENTIRE white-noise family (not just the extremal box), is NOT special to
cyclic scenarios:
    n-cycle       : c = n-1        (nu(box) = 1/(n-1))     [reproduces Camillo-Cervantes]
    CHSH / PR box : c = 2          (nu(box) = 1/2)
    Peres-Mermin  : c = 4          (nu(box) = 1/4)
In every case c = 1 / nu(extremal box) = the reciprocal MAXIMAL signed negativity -- a
scenario invariant, of which n-1 is merely the cyclic specialization. MECHANISM: CF and nu
are both piecewise-linear in the visibility v and vanish TOGETHER at the noncontextuality
threshold (CF=0 <=> nu=0), so along a white-noise ray from a strongly-contextual vertex their
ratio is constant = CF(vertex)/nu(vertex) = 1/nu(vertex) (CF=1 at a strongly-contextual box),
as long as the ray stays within one linear piece (no facet crossing). So a CF<->nu rate law
exists well beyond cyclic systems; the rate is 1/nu_max, not universally n-1.

LP setup for a measurement scenario: measurements 0..M-1, each outcome in {0,1}; contexts =
jointly-measurable tuples; empirical model e = per-context distribution.
  CF:  NCF = max sum_g q_g, q>=0, for every context C and local section s: sum_{g|C=s} q_g
        <= e_C(s).   CF = 1 - NCF.        (g ranges over the 2^M deterministic assignments)
  nu:  min sum_g (b_g)_-  s.t. sum_g b_g = 1 and for every C,s: sum_{g|C=s} b_g = e_C(s).
"""
import itertools
import cvxpy as cp


def _dets(M):
    return list(itertools.product((0, 1), repeat=M))


def _restrict(g, C):
    return tuple(g[i] for i in C)


def cf(M, contexts, e):
    G = _dets(M)
    q = cp.Variable(len(G), nonneg=True)
    cons = []
    for C in contexts:
        for s in itertools.product((0, 1), repeat=len(C)):
            idx = [k for k, g in enumerate(G) if _restrict(g, C) == s]
            cons.append(cp.sum(q[idx]) <= e[C].get(s, 0.0))
    cp.Problem(cp.Maximize(cp.sum(q)), cons).solve(solver=cp.CLARABEL, verbose=False)
    return 1 - float(cp.sum(q).value)


def nu(M, contexts, e):
    G = _dets(M)
    b = cp.Variable(len(G))
    neg = cp.Variable(len(G), nonneg=True)
    cons = [cp.sum(b) == 1, neg >= -b]
    for C in contexts:
        for s in itertools.product((0, 1), repeat=len(C)):
            idx = [k for k, g in enumerate(G) if _restrict(g, C) == s]
            cons.append(cp.sum(b[idx]) == e[C].get(s, 0.0))
    p = cp.Problem(cp.Minimize(cp.sum(neg)), cons)
    p.solve(solver=cp.CLARABEL, verbose=False)
    return float(p.value)


def ncycle_box(n):
    contexts = [tuple(sorted((i, (i + 1) % n))) for i in range(n)]
    e = {C: {(0, 1): 0.5, (1, 0): 0.5} for C in contexts}   # frustrated odd cycle: anticorrelated edges
    return n, contexts, e


def chsh_box():
    contexts = [(0, 2), (0, 3), (1, 2), (1, 3)]
    e = {}
    for C in contexts:
        e[C] = {(0, 1): 0.5, (1, 0): 0.5} if C == (1, 3) else {(0, 0): 0.5, (1, 1): 0.5}
    return 4, contexts, e


def pm_box():
    rows = [(0, 1, 2), (3, 4, 5), (6, 7, 8)]
    cols = [(0, 3, 6), (1, 4, 7), (2, 5, 8)]
    contexts = rows + cols
    parity = {**{r: 0 for r in rows}, **{cols[0]: 0, cols[1]: 0, cols[2]: 1}}
    e = {}
    for C in contexts:
        outs = [s for s in itertools.product((0, 1), repeat=3) if s[0] ^ s[1] ^ s[2] == parity[C]]
        e[C] = {s: 1.0 / len(outs) for s in outs}
    return 9, contexts, e


def mix_uniform(M, contexts, e, v):
    out = {}
    for C in contexts:
        U = 1.0 / (2 ** len(C))
        out[C] = {s: v * e[C].get(s, 0.0) + (1 - v) * U
                  for s in itertools.product((0, 1), repeat=len(C))}
    return out


def rate_along_noise_line(M, contexts, e, vs=(1.0, 0.9, 0.8, 0.7)):
    out = []
    for v in vs:
        em = mix_uniform(M, contexts, e, v)
        c, n = cf(M, contexts, em), nu(M, contexts, em)
        out.append(None if n < 1e-9 else c / n)
    return out


def main():
    print("n-cycle validation (expect CF/nu = n-1 = 1/nu(box)):")
    for n in (3, 5, 7):
        M, ctx, e = ncycle_box(n)
        c, v = cf(M, ctx, e), nu(M, ctx, e)
        print(f"  n={n}: CF={c:.4f} nu={v:.4f} CF/nu={c/v:.3f} (n-1={n-1})")
    print("non-cyclic (rate constant along the white-noise line, = 1/nu(box)):")
    for name, mk in [("CHSH/PR", chsh_box), ("Peres-Mermin", pm_box)]:
        M, ctx, e = mk()
        rr = rate_along_noise_line(M, ctx, e)
        print(f"  {name:>13}: 1/nu(box)={1/nu(M,ctx,e):.3f}  CF/nu along v=1,.9,.8,.7 = "
              f"{['%.3f' % r for r in rr]}")


if __name__ == "__main__":
    main()
