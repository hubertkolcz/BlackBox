# -*- coding: utf-8 -*-
"""
signaling_taxonomy.py -- Extending the correlation taxonomy to signaling and
quantum-communication scenarios: the executable verifier.

Hubert Kolcz -- July 2026.  Companion to signaling_taxonomy.wl (the essay) and
NOTES-signaling.md (the strata table).  Everything quantitative in the essay is
computed HERE; the essay mirrors these numbers.

PRE-REGISTERED GATES (semantics fixed before computation, attack-catalog style)
-------------------------------------------------------------------------------
G1 (signaling stratum = the repurposed rejected tool).  By Abramsky-
   Brandenburger Theorem 5.9 (arXiv:1102.0264), an R-LINEAR global section
   exists iff the model is no-signalling.  The cellular-sheaf HarmonicResidual
   ||delta.e|| -- REJECTED as a contextuality measure because its kernel is
   exactly the no-disturbance space -- is therefore EXACTLY the detector for
   the signaling axis.  Gate: on (a) the three canonical C5 models, (b) 500
   random signaling perturbations + 200 random no-disturbance models, (c) the
   PR box, Tsirelson and a pure-signaling box, the three-way equivalence
     {residual = 0} <=> {R-linear global section exists (LP, free sign)}
                    <=> {marginals consistent}
   holds exactly (exact rank over Q[sqrt(5)] for the canonical models; LP
   tolerance 1e-9 for the random instances); AND the exact rank ledger reads
     rank(delta_5) = 9,  dim ker(delta_5) = 11,  rank(M_5) = 11,
     delta_5 . M_5 = 0   (hence im M = ker delta: AB 5.9 in matrix form),
     dim ker(delta_5) = dim(affine hull of ND polytope) + 1 = 10 + 1,
   with the C4/CHSH analogues (7, 9, 9, 0-matrix, 9 = 8 + 1).
   Else: UNDERMINED (exit nonzero).
G2 (Contextuality-by-Default layer for signaling data).  Criterion pinned from
   Kujala-Dzhafarov, Found. Phys. 46, 282-299 (2016), arXiv:1503.02181v4,
   Eq. (6)/(7)/(13) [proving the Dzhafarov-Kujala-Larsson conjecture,
   arXiv:1411.2244; equivalent to the PRL 115, 150401 criterion by their
   Theorem 13]: a cyclic-n binary system is CONTEXTUAL iff
     s_1(<V_i W_{i+1}>: i=1..n) - Delta > n - 2,
     Delta = sum_i |<V_i> - <W_i>|,
   s_1 = max signed sum over an ODD number of minus signs; the measure is
     CNTX = Delta_min - Delta_0 = max(s_1 - Delta - (n-2), 0)/2.
   Gate: ideal quantum C5 has Delta = 0 and must reduce to the standard KCBS
   verdict with the sqrt(5) value (s_1 = 4 sqrt(5) - 5, exactly); classical C5
   must come out noncontextual (margin exactly 0); the Lapkiewicz-realistic
   reconstruction (V = 0.977 simulation model, context-dependent-marginal
   perturbation of the measured size eps = 0.081) must come out CONTEXTUAL
   with the Delta-penalty visibly reducing the margin vs the Delta-ignoring
   analysis (reduction = eps exactly); the pure-signaling box must come out
   NONcontextual.  Else FAIL.
G3 (communication cost).  (a) The signaling-fraction LP -- minimal lambda with
   e = (1-lambda) . noncontextual + lambda . arbitrary -- must reproduce
   SF(C5, quantum) = 2 sqrt(5) - 4 exactly: float LP within 1e-8 AND an exact
   primal/dual certificate pair over Q[sqrt(5)] pinching the value.  (b) The
   one-bit communication LP over the 4^5 = 1024 deterministic context-aware
   strategies must yield a finite minimal bit-fraction in [0, 1] for the
   quantum table with the witness strategy exhibited (and mu(PR box) = 1 with
   its two-strategy witness).  Else FAIL.

Exit code 0 iff G1, G2, G3 all PASS.
"""

from fractions import Fraction
import itertools
import math
import sys

import numpy as np
from scipy.optimize import linprog

TOL = 1e-9
SQRT5 = math.sqrt(5.0)


# ============================================================ exact field ===
class Quad:
    """Element a + b*sqrt(D) of the real quadratic field Q(sqrt(D)), exact."""

    __slots__ = ("a", "b", "D")

    def __init__(self, a, b=0, D=5):
        self.a, self.b, self.D = Fraction(a), Fraction(b), D

    def _lift(self, x):
        if isinstance(x, Quad):
            assert x.D == self.D
            return x
        return Quad(x, 0, self.D)

    def __add__(self, x):
        x = self._lift(x)
        return Quad(self.a + x.a, self.b + x.b, self.D)

    __radd__ = __add__

    def __neg__(self):
        return Quad(-self.a, -self.b, self.D)

    def __sub__(self, x):
        return self + (-self._lift(x))

    def __rsub__(self, x):
        return self._lift(x) - self

    def __mul__(self, x):
        x = self._lift(x)
        return Quad(self.a * x.a + self.D * self.b * x.b,
                    self.a * x.b + self.b * x.a, self.D)

    __rmul__ = __mul__

    def inv(self):
        n = self.a * self.a - self.D * self.b * self.b
        if n == 0:
            raise ZeroDivisionError
        return Quad(self.a / n, -self.b / n, self.D)

    def __truediv__(self, x):
        return self * self._lift(x).inv()

    def is_zero(self):
        return self.a == 0 and self.b == 0

    def sign(self):
        a, b = self.a, self.b
        if b == 0:
            return (a > 0) - (a < 0)
        if a == 0:
            return (b > 0) - (b < 0)
        if a > 0 and b > 0:
            return 1
        if a < 0 and b < 0:
            return -1
        s = (a * a > self.D * b * b) - (a * a < self.D * b * b)
        return s if a > 0 else -s

    def __eq__(self, x):
        return (self - self._lift(x)).is_zero()

    def __lt__(self, x):
        return (self - self._lift(x)).sign() < 0

    def __le__(self, x):
        return (self - self._lift(x)).sign() <= 0

    def __gt__(self, x):
        return (self - self._lift(x)).sign() > 0

    def __ge__(self, x):
        return (self - self._lift(x)).sign() >= 0

    def __abs__(self):
        return self if self.sign() >= 0 else -self

    def __float__(self):
        return float(self.a) + float(self.b) * math.sqrt(self.D)

    def __repr__(self):
        return f"({self.a}+{self.b}*sqrt{self.D})"


def qmat(rows, D=5):
    return [[x if isinstance(x, Quad) else Quad(x, 0, D) for x in row]
            for row in rows]


def exact_rank(rows):
    """Rank by fraction-free-ish Gaussian elimination over the exact field."""
    m = [row[:] for row in rows]
    if not m:
        return 0
    nrow, ncol = len(m), len(m[0])
    rank, prow = 0, 0
    for col in range(ncol):
        piv = next((r for r in range(prow, nrow) if not m[r][col].is_zero()), None)
        if piv is None:
            continue
        m[prow], m[piv] = m[piv], m[prow]
        pval = m[prow][col]
        for r in range(prow + 1, nrow):
            if not m[r][col].is_zero():
                f = m[r][col] / pval
                m[r] = [m[r][c] - f * m[prow][c] for c in range(ncol)]
        rank += 1
        prow += 1
        if prow == nrow:
            break
    return rank


# ============================================================== scenarios ===
def cycle_contexts(n):
    return [(i, (i + 1) % n) for i in range(n)]


SECTIONS = [(0, 0), (0, 1), (1, 0), (1, 1)]  # (1st obs, 2nd obs) -- WL order


def cycle_incidence(n):
    """4n x 2^n integer incidence matrix, rows context-major (WL layout)."""
    glob = list(itertools.product((0, 1), repeat=n))
    M = []
    for (i, j) in cycle_contexts(n):
        for (a, b) in SECTIONS:
            M.append([1 if (g[i], g[j]) == (a, b) else 0 for g in glob])
    return M, glob


def cycle_coboundary(n):
    """2n x 4n integer coboundary, mirroring BlackBox.wl CycleCoboundary[n]:
    row pair 2i, 2i+1 = (marginal of measurement i as 2nd obs of context i-1)
                      - (marginal of measurement i as 1st obs of context i)."""
    m1st = [[1, 1, 0, 0], [0, 0, 1, 1]]
    m2nd = [[1, 0, 1, 0], [0, 1, 0, 1]]
    delta = [[0] * (4 * n) for _ in range(2 * n)]
    for i in range(n):
        for r in range(2):
            for c in range(4):
                delta[2 * i + r][4 * ((i - 1) % n) + c] += m2nd[r][c]
                delta[2 * i + r][4 * i + c] -= m1st[r][c]
    return delta


# ================================================================= models ===
def cycle_model(n, p00, p10):
    return [p00, p10, p10, Fraction(0)] * n


E_CLASSICAL = cycle_model(5, Fraction(1, 5), Fraction(2, 5))
E_QUANTUM = cycle_model(5, Quad(1, Fraction(-2, 5)), Quad(0, Fraction(1, 5)))
E_WRIGHT = cycle_model(5, Fraction(0), Fraction(1, 2))

# PR box on the 4-cycle (a1, b1, a2, b2), as in SupportCohomology.wl:
E_PR = ([Fraction(1, 2), 0, 0, Fraction(1, 2)] * 3
        + [0, Fraction(1, 2), Fraction(1, 2), 0])

# Tsirelson point on the 4-cycle: correlations (1/sqrt2,)*3 + (-1/sqrt2,).
def chsh_corr_model(cs):
    e = []
    for c in cs:
        e += [(1 + c) / 4, (1 - c) / 4, (1 - c) / 4, (1 + c) / 4]
    return e


E_TSIRELSON = chsh_corr_model([1 / math.sqrt(2)] * 3 + [-1 / math.sqrt(2)])

# Pure-signaling box on C5: contexts 0..3 deterministic section 00; context 4
# deterministic section 10 (measurement 4 answers 0 in context 3, 1 in
# context 4: a context-dependent marginal, nothing else).
E_PURESIG = [Fraction(1), 0, 0, 0] * 4 + [0, 0, Fraction(1), 0]


def lapkiewicz_realistic(V, eps, sign):
    """Simulation model of kcbs_simulation.py at visibility V, with the
    closing-context marginal shifted by eps/2 (the measured epsilon size):
    contexts 0..3: (1-2p, p, p, 0); context 4 = (A5, A1'): A1' click
    probability p' = p + sign*eps/2 (exclusivity keeps P(11) = 0)."""
    p = V / SQRT5 + (1 - V) / 3
    pp = p + sign * eps / 2
    e = [1 - 2 * p, p, p, 0.0] * 4
    e[16:] = [1 - p - pp, pp, p, 0.0]
    return e, p, pp


# =============================================================== axis 1 =====
def residual_vec(delta, e):
    return [sum(delta[r][c] * e[c] for c in range(len(e)))
            for r in range(len(delta))]


def residual_norm_float(delta, e):
    v = np.array(delta, dtype=float) @ np.array([float(x) for x in e])
    return float(np.linalg.norm(v))


def marginals_consistent_float(e, n):
    worst = 0.0
    for i in range(n):
        prev = 4 * ((i - 1) % n)
        cur = 4 * i
        # measurement i as 2nd obs of context i-1 vs 1st obs of context i
        p2 = float(e[prev + 0]) + float(e[prev + 2])   # m_i = 0
        p1 = float(e[cur + 0]) + float(e[cur + 1])
        worst = max(worst, abs(p2 - p1))
    return worst


def real_section_lp(Mf, ef):
    """Feasibility of M d = e with FREE-sign d (AB 5.9's R-linear section)."""
    res = linprog(np.zeros(Mf.shape[1]), A_eq=Mf, b_eq=ef,
                  bounds=[(None, None)] * Mf.shape[1], method="highs")
    return res.status == 0


def axis1():
    print("=" * 78)
    print("AXIS 1 -- the signaling stratum via the repurposed rejected tool")
    print("=" * 78)
    ok = True

    # ---- exact rank ledger, C5 and C4 --------------------------------------
    for n, want in ((5, (9, 11, 11, 10)), (4, (7, 9, 9, 8))):
        delta = cycle_coboundary(n)
        M, _ = cycle_incidence(n)
        rk_d = exact_rank(qmat(delta))
        ker_d = 4 * n - rk_d
        rk_M = exact_rank(qmat(M))
        # delta . M = 0 exactly (integer arithmetic)
        prod_zero = all(
            sum(delta[r][k] * M[k][g] for k in range(4 * n)) == 0
            for r in range(2 * n) for g in range(2 ** n))
        norm_rows = [[1 if 4 * c <= k < 4 * c + 4 else 0 for k in range(4 * n)]
                     for c in range(n)]
        rk_stack = exact_rank(qmat(delta + norm_rows))
        aff = 4 * n - rk_stack   # affine hull dim of the ND polytope
        got = (rk_d, ker_d, rk_M, aff)
        ok &= (got == want) and prod_zero and (ker_d == aff + 1) \
            and (rk_M == ker_d)
        print(f"  C{n}: rank(delta) = {rk_d}, dim ker(delta) = {ker_d}, "
              f"rank(M) = {rk_M}, delta.M = 0: {prod_zero},")
        print(f"      affine hull of ND polytope = {aff}  "
              f"=> dim ker = affine hull + 1 ({ker_d} = {aff} + 1); "
              f"rank M = dim ker delta => im M = ker delta (AB 5.9).")

    # ---- canonical C5 models, exact ----------------------------------------
    M5, _ = cycle_incidence(5)
    d5 = cycle_coboundary(5)
    M5q = qmat(M5)
    rkM5 = exact_rank(M5q)
    print("  canonical models (exact arithmetic over Q[sqrt5]):")
    for name, e in (("classical", E_CLASSICAL), ("quantum", E_QUANTUM),
                    ("Wright", E_WRIGHT)):
        eq = [x if isinstance(x, Quad) else Quad(x) for x in e]
        res = residual_vec(qmat(d5), eq)
        res_zero = all(x.is_zero() for x in res)
        aug = [row + [eq[r]] for r, row in enumerate(M5q)]
        sec = exact_rank([list(col) for col in zip(*aug)])  # rank of [M|e]^T
        section_exists = (sec == rkM5)
        ok &= res_zero and section_exists
        print(f"    {name:10s}: residual == 0: {res_zero}, "
              f"R-linear section exists: {section_exists}")

    # pure-signaling box, exact: residual != 0 and NO real section
    epq = [x if isinstance(x, Quad) else Quad(x) for x in E_PURESIG]
    res = residual_vec(qmat(d5), epq)
    res_sq = sum(x * x for x in res)
    aug = [row + [epq[r]] for r, row in enumerate(M5q)]
    sec = exact_rank([list(col) for col in zip(*aug)])
    ok &= (not all(x.is_zero() for x in res)) and (sec == rkM5 + 1) \
        and res_sq == Quad(2)
    print(f"    pure-sig  : ||residual||^2 = {res_sq} (exact 2), "
          f"R-linear section exists: {sec == rkM5}  (rank jumps to {sec})")

    # ---- 500 signaling perturbations + 200 ND models, float LP -------------
    rng = np.random.default_rng(20260710)
    Mf = np.array(M5, dtype=float)
    eqf = np.array([float(x) for x in E_QUANTUM])
    euf = np.full(20, 0.25)

    def random_nd():
        t = rng.integers(0, 3)
        if t == 0:
            return Mf @ rng.dirichlet(np.ones(32))
        if t == 1:
            V = rng.uniform()
            return V * eqf + (1 - V) * euf
        lam = rng.uniform()
        base = Mf @ rng.dirichlet(np.ones(32))
        return lam * base + (1 - lam) * np.array(
            [float(x) for x in E_WRIGHT])

    agree = True
    n_sig = n_nd = 0
    for k in range(700):
        e = random_nd()
        if k < 500:  # signaling perturbation inside one context block
            c = rng.integers(0, 5)
            s1c = int(np.argmax(e[4 * c: 4 * c + 4]))  # heaviest: >= 1/4
            s2c = rng.choice([s for s in range(4) if s != s1c])
            eta = rng.uniform(0.01, min(0.1, e[4 * c + s1c]))
            e = e.copy()
            e[4 * c + s1c] -= eta
            e[4 * c + s2c] += eta
            n_sig += 1
        else:
            n_nd += 1
        r0 = residual_norm_float(d5, e) < TOL
        f0 = real_section_lp(Mf, e)
        m0 = marginals_consistent_float(e, 5) < TOL
        if not (r0 == f0 == m0):
            agree = False
            print(f"    DISAGREEMENT at instance {k}: residual0={r0}, "
                  f"LP={f0}, marginals={m0}")
    ok &= agree
    print(f"  random instances: {n_sig} signaling perturbations, "
          f"{n_nd} no-disturbance models; three-way equivalence "
          f"{{residual=0}} <=> {{LP feasible}} <=> {{marginals consistent}}: "
          f"{agree}")

    verdict = "PASS" if ok else "UNDERMINED"
    print(f"  GATE G1: {verdict}")
    return ok


# =============================================================== axis 2 =====
def s1_bruteforce(xs):
    """s_1 = max over sign vectors with an odd number of -1 of sum m_i x_i."""
    best = None
    for signs in itertools.product((1, -1), repeat=len(xs)):
        if (sum(1 for m in signs if m == -1)) % 2 == 1:
            v = xs[0] * 0
            for m, x in zip(signs, xs):
                v = v + (x if m == 1 else -x)
            if best is None or v > best:
                best = v
    return best


def s1_closed(xs):
    """Closed form: sum|x| if #negatives odd, else sum|x| - 2 min|x|."""
    absx = [abs(x) for x in xs]
    tot = absx[0] * 0
    for x in absx:
        tot = tot + x
    neg = sum(1 for x in xs if (x.sign() if isinstance(x, Quad) else
                                (x > 0) - (x < 0)) < 0)
    if neg % 2 == 1:
        return tot
    return tot - 2 * min(absx)


def cbd_cyclic(e, n):
    """Kujala-Dzhafarov cyclic-n criterion on a context-major table.
    Returns (s1, Delta, margin, CNTX, contextualQ) -- exact if e is exact."""
    prods, dV, dW = [], {}, {}
    for c in range(n):
        p = e[4 * c: 4 * c + 4]
        # 0 -> +1, 1 -> -1
        prods.append(p[0] - p[1] - p[2] + p[3])
        dV[c] = p[0] + p[1] - p[2] - p[3]            # 1st obs = measurement c
        dW[(c + 1) % n] = p[0] - p[1] + p[2] - p[3]  # 2nd obs = c+1
    delta = None
    for i in range(n):
        d = abs(dV[i] - dW[i])
        delta = d if delta is None else delta + d
    s1 = s1_closed(prods)
    assert (s1 - s1_bruteforce(prods)) == (s1 * 0)  # internal cross-check
    margin = s1 - delta - (n - 2)
    sgn = margin.sign() if isinstance(margin, Quad) else (
        (margin > 0) - (margin < 0))
    cntx = margin / 2 if sgn > 0 else margin * 0
    # criterion (8) of arXiv:1412.4724 (PRL 115, 150401), equivalent by Thm 13:
    crit8 = s1_closed(prods + [1 - abs(dV[i] - dW[i]) for i in range(n)])
    c8 = (crit8 - (2 * n - 2))
    s8 = c8.sign() if isinstance(c8, Quad) else ((c8 > 0) - (c8 < 0))
    assert (s8 > 0) == (sgn > 0), "criterion (7) vs (8) mismatch"
    return s1, delta, margin, cntx, sgn > 0


def axis2():
    print("=" * 78)
    print("AXIS 2 -- Contextuality-by-Default on C5, exact and realistic")
    print("=" * 78)
    ok = True

    def as_field(e):
        return [x if isinstance(x, Quad) else Quad(x) for x in e]

    # exact rows ---------------------------------------------------------------
    s1q, dq, mq, cq, bq = cbd_cyclic(as_field(E_QUANTUM), 5)
    s1c, dc, mc, cc, bc = cbd_cyclic(as_field(E_CLASSICAL), 5)
    s1w, dw, mw, cw, bw = cbd_cyclic(as_field(E_WRIGHT), 5)
    s1p, dp, mp, cp, bp = cbd_cyclic(as_field(E_PURESIG), 5)
    s1pr, dpr, mpr, cpr, bpr = cbd_cyclic(
        [Fraction(x) if not isinstance(x, Fraction) else x for x in E_PR], 4)

    ideal_locks = (
        s1q == Quad(-5, 4)            # s_1 = 4 sqrt5 - 5
        and dq == Quad(0)             # consistently connected
        and mq == Quad(-8, 4)         # margin = 4 sqrt5 - 8 > 0
        and cq == Quad(-4, 2)         # CNTX = 2 sqrt5 - 4 = CF !
        and bq)
    # "reduces to the standard KCBS verdict with the sqrt5 value":
    # s_1 = 4*sum<P_i> - 5, so s_1 = 4 sqrt5 - 5 <=> sum<P_i> = sqrt5.
    sumP = (s1q + 5) / 4
    ideal_locks &= (sumP == Quad(0, 1))
    ok &= ideal_locks
    print(f"  quantum C5 : s1 = 4sqrt5-5 = {float(s1q):.6f}, Delta = 0, "
          f"margin = 4sqrt5-8 = {float(mq):.6f} > 0 -> CONTEXTUAL")
    print(f"               CNTX = 2sqrt5-4 = {float(cq):.6f}; "
          f"sum<P_i> = (s1+5)/4 = sqrt5: {sumP == Quad(0, 1)}   "
          f"[locks: {ideal_locks}]")

    ok &= (mc == Quad(0)) and not bc
    print(f"  classical  : s1 = {float(s1c):.4f}, margin = 0 exactly -> "
          f"NONCONTEXTUAL (sits on the boundary): {not bc}")
    ok &= (mw == Quad(2)) and bw and (cw == Quad(1))
    print(f"  Wright box : margin = 2, CNTX = 1 -> CONTEXTUAL: {bw}")
    ok &= (mp == Quad(0)) and not bp and (dp == Quad(2))
    print(f"  pure-signal: s1 = 5, Delta = 2, margin = 0 exactly -> "
          f"NONCONTEXTUAL: {not bp}  (all context-dependence booked as "
          f"signaling)")
    ok &= (mpr == Fraction(2)) and bpr and (cpr == Fraction(1))
    print(f"  PR box (C4): margin = 2, CNTX = 1 -> CONTEXTUAL: {bpr}")

    # Lapkiewicz-realistic reconstruction --------------------------------------
    # Published aggregates: Sigma = -3.893(6), eps = 1 - <A1A1'> = 0.081(2)
    # (Nature 474, 490).  The five per-edge correlations are NOT individually
    # recoverable from (Sigma, eps) alone -- five unknowns, two equations -- so
    # per the pre-registration we analyze the kcbs_simulation.py noise model at
    # V = 0.977 with the closing marginal shifted by eps/2 in each direction
    # (Delta = eps is the maximal context-dependent-marginal reading of eps,
    # since Delta = |<A1>-<A1'>| <= 2 P(A1 != A1') = eps), plus a V calibrated
    # to reproduce Sigma = -3.893 exactly.
    eps = 0.081
    rows = []
    for tag, V, sign in (("V=0.977, p'=p-eps/2", 0.977, -1),
                         ("V=0.977, p'=p+eps/2", 0.977, +1)):
        e, p, pp = lapkiewicz_realistic(V, eps, sign)
        rows.append((tag, e, p, pp))
    # calibrated: Sigma = 5 - 20 p - eps = -3.893  (p' = p + eps/2 direction)
    p_cal = (5 + 3.893 - eps) / 20
    V_cal = (p_cal - 1 / 3) / (1 / SQRT5 - 1 / 3)
    e_cal, _, _ = lapkiewicz_realistic(V_cal, eps, +1)
    rows.append((f"V={V_cal:.4f} (Sigma calibrated)", e_cal, p_cal,
                 p_cal + eps / 2))

    real_ok = True
    for tag, e, p, pp in rows:
        ef = [Fraction(x).limit_denominator(10 ** 12) for x in e]
        s1r, dr, mr, cr, br = cbd_cyclic(ef, 5)
        s1f, df, mf = float(s1r), float(dr), float(mr)
        sigma = sum(float(prod) for prod in
                    [ef[4 * c] - ef[4 * c + 1] - ef[4 * c + 2] + ef[4 * c + 3]
                     for c in range(5)])
        margin_nd_style = s1f - 3          # Delta ignored
        reduction = margin_nd_style - mf   # must equal Delta = eps
        real_ok &= br and abs(df - eps) < 1e-9 \
            and abs(reduction - eps) < 1e-9 and mf > 0.5
        print(f"  Lapkiewicz-realistic [{tag}]:")
        print(f"      Sigma = {sigma:+.4f}, Delta = {df:.4f} (= eps), "
              f"s1 = {s1f:.4f}")
        print(f"      margin(CbD) = {mf:.4f} vs margin(Delta ignored) = "
              f"{margin_nd_style:.4f}: penalty = {reduction:.4f} -> "
              f"CONTEXTUAL: {br}, CNTX = {float(cr):.4f}")
    ok &= real_ok
    print("  [literature anchor: the Kujala-Dzhafarov-Larsson PRL 115, 150401"
          " CbD reanalysis of the Lapkiewicz data likewise confirms"
          " contextuality despite significant inconsistent connectedness.]")

    verdict = "PASS" if ok else "FAIL"
    print(f"  GATE G2: {verdict}")
    return ok


# =============================================================== axis 3 =====
def ncf_lp_float(M, e):
    Mf = np.array(M, dtype=float)
    ef = np.array([float(x) for x in e])
    res = linprog(-np.ones(Mf.shape[1]), A_ub=Mf, b_ub=ef,
                  bounds=[(0, None)] * Mf.shape[1], method="highs")
    assert res.status == 0
    return -res.fun


def one_bit_strategies(n):
    """All deterministic context-aware strategies (x, y):  measurement i
    answers x_i when it is the FIRST observable of its context (context i)
    and y_i when it is the SECOND (context i-1).  Table: context i carries
    the deterministic section (x_i, y_{i+1})."""
    T = []
    for x in itertools.product((0, 1), repeat=n):
        for y in itertools.product((0, 1), repeat=n):
            col = [0] * (4 * n)
            for c in range(n):
                col[4 * c + SECTIONS.index((x[c], y[(c + 1) % n]))] = 1
            T.append(col)
    return T


def min_bit_fraction_lp(M, T, e):
    """min sum(w) s.t. M d + T w = e, sum d + sum w = 1, d, w >= 0."""
    Mf, Tf = np.array(M, dtype=float), np.array(T, dtype=float).T
    ef = np.array([float(x) for x in e])
    nd, nw = Mf.shape[1], Tf.shape[1]
    A_eq = np.vstack([np.hstack([Mf, Tf]), np.ones((1, nd + nw))])
    b_eq = np.concatenate([ef, [1.0]])
    c = np.concatenate([np.zeros(nd), np.ones(nw)])
    res = linprog(c, A_eq=A_eq, b_eq=b_eq,
                  bounds=[(0, None)] * (nd + nw), method="highs")
    return (res.fun if res.status == 0 else None), res.status


def axis3():
    print("=" * 78)
    print("AXIS 3 -- communication cost: two LPs")
    print("=" * 78)
    ok = True
    M5, glob5 = cycle_incidence(5)
    M4, glob4 = cycle_incidence(4)

    # ---- LP (a): signaling fraction ----------------------------------------
    # SF = 1 - NCF: the free part of the mixture is an ARBITRARY normalized
    # table (the signaling polytope), so the constraint set is exactly the
    # NCF LP's -- for C5 SF must equal CF.
    sf_q = 1 - ncf_lp_float(M5, E_QUANTUM)
    exact_cf = 2 * SQRT5 - 4
    ok &= abs(sf_q - exact_cf) < 1e-8
    print(f"  LP(a) float: SF(C5 quantum) = {sf_q:.10f} vs 2sqrt5-4 = "
          f"{exact_cf:.10f}  (|diff| = {abs(sf_q - exact_cf):.2e})")

    # exact certificate pair over Q[sqrt5], pinching NCF = 5 - 2 sqrt5:
    # primal: weight 1 - 2/sqrt5 on each of the 5 non-adjacent-pair
    # assignments; dual: y = (1, 0, 0, 1) per context.
    w = Quad(1, Fraction(-2, 5))                    # 1 - 2/sqrt5
    pairs = [g for g in glob5
             if sum(g) == 2 and all(not (g[i] and g[(i + 1) % 5])
                                    for i in range(5))]
    assert len(pairs) == 5
    d_star = {g: w for g in pairs}
    Md = [Quad(0)] * 20
    for r in range(20):
        for gi, g in enumerate(glob5):
            if g in d_star and M5[r][gi]:
                Md[r] = Md[r] + d_star[g]
    eQ = [x if isinstance(x, Quad) else Quad(x) for x in E_QUANTUM]
    primal_feas = all((eQ[r] - Md[r]).sign() >= 0 for r in range(20))
    primal_val = w * 5                              # 5 - 2 sqrt5
    y = ([1, 0, 0, 1] * 5)
    dual_feas = all(sum(y[r] * M5[r][gi] for r in range(20)) >= 1
                    for gi in range(32))            # integer arithmetic
    dual_val = Quad(0)
    for r in range(20):
        dual_val = dual_val + y[r] * eQ[r]
    pinch = (primal_val == Quad(5, -2)) and (dual_val == Quad(5, -2))
    ok &= primal_feas and dual_feas and pinch
    print(f"  LP(a) exact: primal witness (5 pair-assignments at 1-2/sqrt5) "
          f"feasible: {primal_feas}, value 5-2sqrt5: "
          f"{primal_val == Quad(5, -2)}")
    print(f"               dual witness y = (1,0,0,1) per context feasible "
          f"(every assignment hits >= 1 section with y = 1): {dual_feas}, "
          f"value 5-2sqrt5: {dual_val == Quad(5, -2)}")
    print(f"               => NCF = 5-2sqrt5, SF = CF = 2sqrt5-4 EXACTLY "
          f"(primal = dual pinch: {pinch})")

    # exact SF of the other exemplars via zero-section dual certificates:
    def sf_exact_zero_dual(M, e, glob):
        zero_rows = [r for r in range(len(e))
                     if (e[r].is_zero() if isinstance(e[r], Quad)
                         else e[r] == 0)]
        covers = all(any(M[r][gi] for r in zero_rows)
                     for gi in range(len(glob)))
        return covers  # y = 1 on zero rows: dual value 0 => NCF = 0, SF = 1

    ok &= sf_exact_zero_dual(M5, [Quad(x) if not isinstance(x, Quad) else x
                                  for x in E_WRIGHT], glob5)
    ok &= sf_exact_zero_dual(M4, [Fraction(x) for x in E_PR], glob4)
    ok &= sf_exact_zero_dual(M5, [Quad(x) if not isinstance(x, Quad) else x
                                  for x in E_PURESIG], glob5)
    print("  LP(a) exact: SF(Wright) = SF(PR) = SF(pure-signaling) = 1 "
          "(zero-section dual certificates; every assignment is blocked)")
    # classical: exact global distribution => SF = 0
    dcl = {g: Fraction(1, 5) for g in pairs}
    Mdc = [sum(Fraction(1, 5) for gi, g in enumerate(glob5)
               if g in dcl and M5[r][gi]) for r in range(20)]
    cl_ok = all(Fraction(Mdc[r]) == E_CLASSICAL[r] for r in range(20))
    ok &= cl_ok
    print(f"  LP(a) exact: classical = M . (uniform on the 5 pairs) exactly "
          f"=> SF = 0: {cl_ok}")
    sf_ts = 1 - ncf_lp_float(M4, E_TSIRELSON)
    ok &= abs(sf_ts - (math.sqrt(2) - 1)) < 1e-8
    print(f"  LP(a) float: SF(Tsirelson C4) = {sf_ts:.10f} "
          f"(= sqrt2-1 = {math.sqrt(2) - 1:.10f})")
    e_real, _, _ = lapkiewicz_realistic(0.977, 0.081, +1)
    sf_real = 1 - ncf_lp_float(M5, e_real)
    print(f"  LP(a) float: SF(Lapkiewicz-realistic, +eps/2) = {sf_real:.6f}")

    # ---- LP (b): one-bit communication model -------------------------------
    T5 = one_bit_strategies(5)
    # the strategy set is EXACTLY the set of all 4^5 deterministic tables:
    sig = sorted(tuple(col.index(1, 4 * c, 4 * c + 4) - 4 * c
                       for c in range(5)) for col in T5)
    full = sorted(itertools.product(range(4), repeat=5))
    bijection = (sig == full) and len(T5) == 1024
    ok &= bijection
    print(f"  LP(b): 1024 deterministic 1-bit strategies = ALL 4^5 "
          f"deterministic tables (bijection: {bijection}) => their convex "
          f"hull is the full table polytope; the quantum table is "
          f"reproducible (mu = 1 trivially feasible).")
    mu_q, status = min_bit_fraction_lp(M5, T5, E_QUANTUM)
    ok &= status == 0 and abs(mu_q - exact_cf) < 1e-8 and 0 <= mu_q <= 1
    print(f"  LP(b) float: minimal bit-fraction mu(C5 quantum) = "
          f"{mu_q:.10f} = SF = 2sqrt5-4 (|diff| = "
          f"{abs(mu_q - exact_cf):.2e})")

    # exact witness: e_quantum = (5-2sqrt5) e_classical + (2sqrt5-4) e_Wright,
    # with e_classical = 0-bit (uniform on the 5 pair-assignments) and
    # e_Wright = the uniform mixture of the 32 one-bit strategies
    # x in {0,1}^5, y_j = 1 - x_{j-1}.
    lamq = Quad(-4, 2)
    idq = all(
        (Quad(5, -2) * Quad(E_CLASSICAL[r]) + lamq * Quad(E_WRIGHT[r])) ==
        eQ[r] for r in range(20))
    wright_cols = []
    for x in itertools.product((0, 1), repeat=5):
        y = tuple(1 - x[(j - 1) % 5] for j in range(5))
        col = [0] * 20
        for c in range(5):
            col[4 * c + SECTIONS.index((x[c], y[(c + 1) % 5]))] = 1
        wright_cols.append(col)
    wr_mix = [Fraction(sum(col[r] for col in wright_cols), 32)
              for r in range(20)]
    wright_id = all(wr_mix[r] == E_WRIGHT[r] for r in range(20))
    ok &= idq and wright_id
    print(f"  LP(b) exact witness: e_quantum = (5-2sqrt5) e_classical + "
          f"(2sqrt5-4) e_Wright: {idq}")
    print(f"      e_Wright = uniform mixture of the 32 one-bit strategies "
          f"(x, y = NOT x shifted): {wright_id}")
    print(f"      => communication cost of the quantum C5 table = 2sqrt5-4 "
          f"= {exact_cf:.6f} bits/round EXACTLY, witness explicit.")

    # PR box cross-check on C4: mu = 1 with a two-strategy witness
    T4 = one_bit_strategies(4)
    mu_pr, status = min_bit_fraction_lp(M4, T4, E_PR)
    x0, y0 = (0, 0, 0, 0), (1, 0, 0, 0)
    x1, y1 = (1, 1, 1, 1), (0, 1, 1, 1)
    mix = [Fraction(0)] * 16
    for x, y in ((x0, y0), (x1, y1)):
        for c in range(4):
            mix[4 * c + SECTIONS.index((x[c], y[(c + 1) % 4]))] += Fraction(1, 2)
    pr_witness = all(mix[r] == E_PR[r] for r in range(16))
    ok &= status == 0 and abs(mu_pr - 1) < 1e-8 and pr_witness
    print(f"  LP(b) cross-check: mu(PR box) = {mu_pr:.10f} = 1; exact "
          f"two-strategy witness (x=0000/y=1000 and its global flip): "
          f"{pr_witness}")
    mu_real, status = min_bit_fraction_lp(M5, T5, e_real)
    ok &= status == 0 and abs(mu_real - sf_real) < 1e-7
    print(f"  LP(b) float: mu(Lapkiewicz-realistic) = {mu_real:.6f} "
          f"= SF (as it must: conv(strategies) = full polytope)")

    verdict = "PASS" if ok else "FAIL"
    print(f"  GATE G3: {verdict}")
    return ok, sf_real, mu_real, sf_ts


# ============================================================== synthesis ===
def synthesis(sf_real, mu_real, sf_ts):
    print("=" * 78)
    print("SYNTHESIS -- the extended taxonomy (3 axes), computed exemplars")
    print("=" * 78)
    d5 = cycle_coboundary(5)
    d4 = cycle_coboundary(4)
    e_real, _, _ = lapkiewicz_realistic(0.977, 0.081, +1)
    exact_cf = 2 * SQRT5 - 4

    def row(name, e, n, sf, mu):
        delta = d5 if n == 5 else d4
        r = residual_norm_float(delta, e)
        ef = [Fraction(x).limit_denominator(10 ** 12)
              if not isinstance(x, (Fraction, Quad)) else x for x in e]
        if any(isinstance(x, Quad) for x in ef):
            ef = [x if isinstance(x, Quad) else Quad(x) for x in ef]
        s1v, dv, mv, cv, bv = cbd_cyclic(ef, n)
        return (name, r, float(dv), float(mv), float(cv), bv, sf, mu)

    rows = [
        row("C5 classical", E_CLASSICAL, 5, 0.0, 0.0),
        row("C5 quantum", E_QUANTUM, 5, exact_cf, exact_cf),
        row("C5 Wright box", E_WRIGHT, 5, 1.0, 1.0),
        row("CHSH Tsirelson", E_TSIRELSON, 4, sf_ts, sf_ts),
        row("CHSH PR box", E_PR, 4, 1.0, 1.0),
        row("C5 pure-signaling", E_PURESIG, 5, 1.0, 1.0),
        row("C5 Lapkiewicz-real.", e_real, 5, sf_real, mu_real),
    ]
    hdr = (f"  {'model':<21}{'||delta e||':>11}{'Delta':>8}{'margin':>8}"
           f"{'CNTX':>8}{'CbD?':>6}{'SF':>8}{'mu(bits)':>9}   stratum")
    print(hdr)
    for name, r, dv, mv, cv, bv, sf, mu in rows:
        sig = r > TOL
        if not sig and not bv:
            stratum = "S0 classical" if sf < TOL else "S? (unreachable)"
        elif not sig and bv:
            stratum = "S1 contextual" if sf < 1 - 1e-6 else "S2 strongly ctx"
        elif sig and not bv:
            stratum = "S3 pure-signaling"
        else:
            stratum = "S4 ctx despite sig"
        print(f"  {name:<21}{r:>11.4f}{dv:>8.4f}{mv:>8.4f}{cv:>8.4f}"
              f"{str(bv):>6}{sf:>8.4f}{mu:>9.4f}   {stratum}")
    print()
    print("  Axis 1 (theorem, AB 5.9 / im M = ker delta): signaling <=> ")
    print("    nonzero harmonic residual <=> no R-linear global section.")
    print("  Axis 2 (computation on the pinned KD formula): CbD margin")
    print("    s1 - Delta - (n-2); on Delta = 0 rows CNTX = CF exactly.")
    print("  Axis 3 (LP): SF = CF-with-signaling-free-part; mu = SF because")
    print("    one context bit per measurement spans the full table polytope.")


def observation_sf_equals_dmin():
    """NON-GATE OBSERVATION: on every exemplar row SF coincides with the
    Kujala-Dzhafarov Delta_min = max(s_1 - (n-2), Delta)/2.  Probe whether
    the identity  SF = Delta_min  (hence CNTX = SF - Delta_0) holds across
    random C5 tables -- if it does, Axis 3's LP computes Axis 2's
    fundamental coupling quantity and the two axes are one geometry."""
    M5, _ = cycle_incidence(5)
    rng = np.random.default_rng(7)
    worst, worst_tbl = 0.0, None
    for _ in range(200):
        e = np.concatenate([rng.dirichlet(np.ones(4)) for _ in range(5)])
        sf = 1 - ncf_lp_float(M5, e)
        ef = [Fraction(x).limit_denominator(10 ** 12) for x in e]
        s1v, dv, mv, cv, bv = cbd_cyclic(ef, 5)
        dmin = max(float(s1v) - 3, float(dv)) / 2
        if abs(sf - dmin) > worst:
            worst, worst_tbl = abs(sf - dmin), (sf, dmin)
    print("=" * 78)
    print("OBSERVATION (non-gate): is SF = Delta_min on random C5 tables?")
    print(f"  200 random tables: max |SF - Delta_min| = {worst:.3e}"
          + ("  -> identity holds to LP tolerance"
             if worst < 1e-7 else
             f"  -> FAILS, e.g. SF = {worst_tbl[0]:.6f} vs "
             f"Delta_min = {worst_tbl[1]:.6f}: the coincidence on the"
             " exemplar rows is special, not generic"))
    return worst


# =================================================================== main ===
def main():
    print("signaling_taxonomy.py -- pre-registered gates G1-G3")
    print("exact field: Q[sqrt5]; float LPs: scipy HiGHS, tol 1e-9\n")
    g1 = axis1()
    g2 = axis2()
    g3, sf_real, mu_real, sf_ts = axis3()
    synthesis(sf_real, mu_real, sf_ts)
    observation_sf_equals_dmin()
    print("=" * 78)
    print(f"GATES: G1 {'PASS' if g1 else 'UNDERMINED'} | "
          f"G2 {'PASS' if g2 else 'FAIL'} | G3 {'PASS' if g3 else 'FAIL'}")
    all_ok = g1 and g2 and g3
    print(f"OK -> {all_ok}")
    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
