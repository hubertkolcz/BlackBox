#!/usr/bin/env python3
# -*- coding: utf-8 -*-
r"""
final_o3_cv_dla.py -- the continuous-variable (Gaussian) analogue of gate G7.

Objective O3, CV column.  The existing G7 leaf-confinement audit
(BlackBox.wl: CascadeGenerators / So3Axis / DLADimension) lives on so(3): it
tells a genuine 3-axis KCBS qutrit cascade (DLA = 3) apart from a
leaf-confined intensity rig (DLA < 3).  That audit does NOT transplant to
Gaussian / continuous-variable devices (Hawking-type two-mode squeezers,
analogue-gravity Bogoliubov states): those live on the real symplectic group
Sp(2n,R) acting on covariance matrices, not on SO(3) acting on a Bloch/Stokes
sphere.  This was flagged as UNBUILT in NOTES-hawking.md (Sec.4 disanalogy;
Sec.6 open item 4) and as the open "CONTINUOUS-VARIABLE column" cell of
certification_map.wl.

This module DERIVES and IMPLEMENTS the Sp(2n,R) leaf-confinement criterion.

DERIVATION (the criterion).
  Quadrature vector r = (x_1,p_1,...,x_n,p_n).  Symplectic form
      Omega = blockdiag([[0,1],[-1,0]]) (one 2x2 block per mode).
  A Gaussian unitary exp(-i H) with H = (1/2) r^T G r, G = G^T real, acts on
  quadratures by the symplectic generator
      K = Omega . G  in  sp(2n,R) = { K : K^T Omega + Omega K = 0 },
      dim sp(2n,R) = n(2n+1).
  The maximal COMPACT subalgebra is the passive (photon-number-conserving)
  linear optics algebra
      u(n) = sp(2n,R) cap so(2n) = { K in sp(2n,R) : K^T = -K },
      dim u(n) = n^2,
  generated exactly by phase shifters (a_j^dag a_j) and beamsplitters
  (a_j^dag a_k + h.c.).  Squeezing generators (single-mode x^2-p^2, two-mode
  x_j x_k - p_j p_k) are SYMMETRIC (K^T = +K): non-compact, active, outside u(n).

  LEAF-CONFINEMENT CRITERION (CV analogue of "DLA < 3 => intensity-emulable"):
  given a device's CLAIMED generator set {K_i}, form the matrix dynamical Lie
  algebra g = LieClosure({K_i}) (iterated commutators to a fixed point).  Then
      * g subset u(n)  <=>  every basis element of g is antisymmetric
                        <=>  dim g <= n^2 and closure is compact
        => PASSIVE-CONFINED: the device is a passive linear-interferometer and
           is classically emulable by linear optics (no genuine squeezing; the
           Gaussian state stays a rotated/relabelled input -- the CV counterpart
           of "leaf-confined, no genuine so(3) rotation").
      * g contains a symmetric element (dim g > n^2 toward n(2n+1))
        => ACTIVE: genuine squeezing present, NOT confined -- the resource an
           intensity/linear-optics forger cannot reproduce.

  This is the exact CV mirror of G7's so(3) "2 -> 3" anchor: there the audit
  asks whether the claimed axes close to the full so(3) (dim 3) or collapse to
  a leaf (dim < 3); here it asks whether the claimed symplectic generators
  close to something beyond u(n) (active) or stay inside it (passive-confined).

TRUST ASSUMPTION (stated plainly, identical in kind to G7's).
  The input is a CLAIMED mode compilation -- a white-box declaration of the
  device's generator set -- NOT a black-box observable.  This audit certifies
  "the claimed Gaussian dynamics is / isn't passive-linear-optics-emulable",
  not "the device's ACTUAL dynamics is."  Same standing as G7 (PROPOSITION-O3
  Corollary 2): a compilation audit, trusted to the extent the compilation is.

VALIDATION (run this file; all asserts must pass).
  (i)   beamsplitter + phase shifters on 2 modes  -> dim 4  = u(2)      CONFINED
  (ii)  (i) + a two-mode squeezer                 -> dim 10 = sp(4,R)   ACTIVE
  (iii) single-mode squeezer + phase on 1 mode    -> dim 3  = sp(2,R)   ACTIVE

Exact arithmetic (sympy Rational) throughout: Lie-algebra dimensions are
integers, so the closure rank is computed exactly -- no tolerance, no
floating-point verdict ambiguity.

Refs: Weedbrook et al., Rev. Mod. Phys. 84, 621 (2012), arXiv:1110.3234
(Gaussian formalism, Sp(2n,R) / U(n) subgroup, dims n(2n+1) and n^2);
Arvind, Dutta, Mukunda, Simon, Pramana 45, 471 (1995) (the real symplectic
group in quantum optics).  NOTES-hawking.md Sec.4/Sec.6(4) (the open item this
closes).  BlackBox.wl DLADimension (the so(3) audit this is the CV analogue of).
"""

import sympy as sp


# ----------------------------------------------------------------------
# symplectic-algebra scaffolding (exact)
# ----------------------------------------------------------------------
def omega(n):
    """Symplectic form on n modes, ordering (x1,p1,...,xn,pn)."""
    O = sp.zeros(2 * n, 2 * n)
    for j in range(n):
        O[2 * j, 2 * j + 1] = 1
        O[2 * j + 1, 2 * j] = -1
    return O


def _sym_from_terms(n, terms):
    """Symmetric 2n x 2n matrix G with r^T G r = sum of the given quadratic
    monomials.  terms: list of (a, b, coeff), meaning coeff * r_a r_b."""
    G = sp.zeros(2 * n, 2 * n)
    for a, b, c in terms:
        if a == b:
            G[a, a] += c
        else:
            G[a, b] += sp.Rational(c, 2)
            G[b, a] += sp.Rational(c, 2)
    return G


def gen_from_G(n, G):
    """Symplectic generator K = Omega . G of a quadratic Hamiltonian (1/2)r^T G r."""
    return omega(n) * G


# --- physical generators (indices are 0-based mode numbers) ---
def x(j):
    return 2 * j


def p(j):
    return 2 * j + 1


def phase(n, j):
    """Phase shifter on mode j: H ~ x_j^2 + p_j^2 (number operator). Passive."""
    return gen_from_G(n, _sym_from_terms(n, [(x(j), x(j), 1), (p(j), p(j), 1)]))


def beamsplitter_re(n, j, k):
    """Beamsplitter, real part of a_j^dag a_k: H ~ x_j x_k + p_j p_k. Passive."""
    return gen_from_G(n, _sym_from_terms(n, [(x(j), x(k), 1), (p(j), p(k), 1)]))


def beamsplitter_im(n, j, k):
    """Beamsplitter, imag part of a_j^dag a_k: H ~ x_j p_k - p_j x_k. Passive."""
    return gen_from_G(n, _sym_from_terms(n, [(x(j), p(k), 1), (p(j), x(k), -1)]))


def squeeze_single_1(n, j):
    """Single-mode squeezer on mode j: H ~ x_j^2 - p_j^2. Active."""
    return gen_from_G(n, _sym_from_terms(n, [(x(j), x(j), 1), (p(j), p(j), -1)]))


def squeeze_single_2(n, j):
    """Single-mode squeezer (rotated): H ~ x_j p_j + p_j x_j. Active."""
    return gen_from_G(n, _sym_from_terms(n, [(x(j), p(j), 2)]))


def squeeze_two_1(n, j, k):
    """Two-mode squeezer: H ~ x_j x_k - p_j p_k. Active."""
    return gen_from_G(n, _sym_from_terms(n, [(x(j), x(k), 1), (p(j), p(k), -1)]))


def squeeze_two_2(n, j, k):
    """Two-mode squeezer (rotated): H ~ x_j p_k + p_j x_k. Active."""
    return gen_from_G(n, _sym_from_terms(n, [(x(j), p(k), 1), (p(j), x(k), 1)]))


# ----------------------------------------------------------------------
# the audit
# ----------------------------------------------------------------------
def _comm(A, B):
    return A * B - B * A


def _flatten(M):
    return sp.Matrix([M[i, j] for i in range(M.rows) for j in range(M.cols)])


def _rank_of(mats):
    if not mats:
        return 0
    cols = [_flatten(M) for M in mats]
    return sp.Matrix.hstack(*cols).rank()


def lie_closure(gens, max_iter=64):
    """Matrix dynamical Lie algebra generated by `gens` (exact, to a fixed point).
    Returns a list of matrices spanning the closure (a linear basis)."""
    # Start from an independent spanning set of the generators.
    basis = []
    for g in gens:
        trial = basis + [g]
        if _rank_of(trial) > _rank_of(basis):
            basis.append(g)
    dim = len(basis)
    for _ in range(max_iter):
        new = list(basis)
        added = False
        for i in range(len(basis)):
            for j in range(i + 1, len(basis)):
                c = _comm(basis[i], basis[j])
                if c.is_zero_matrix:
                    continue
                if _rank_of(new + [c]) > len(new):
                    new.append(c)
                    added = True
        basis = new
        if not added or len(basis) == dim and not added:
            if len(basis) == dim:
                break
        dim = len(basis)
    return basis


def is_compact(basis):
    """True iff every basis element is antisymmetric (closure subset u(n))."""
    return all((M + M.T).is_zero_matrix for M in basis)


def audit(name, n, gens):
    """Run the CV leaf-confinement audit on a claimed generator set."""
    basis = lie_closure(gens)
    d = _rank_of(basis)
    un, spn = n * n, n * (2 * n + 1)
    compact = is_compact(basis)
    confined = compact and d <= un
    verdict = ("PASSIVE-CONFINED (subset u(n): classically emulable by linear optics)"
               if confined else
               "ACTIVE (genuine squeezing; NOT confined -- beyond linear optics)")
    print(f"[{name}]  n={n} modes")
    print(f"    claimed generators : {len(gens)}")
    print(f"    DLA dimension       : {d}")
    print(f"    dim u(n)  (passive) : {un}")
    print(f"    dim sp(2n,R) (full) : {spn}")
    print(f"    closure compact?    : {compact}")
    print(f"    VERDICT             : {verdict}")
    print()
    return {"name": name, "n": n, "dim": d, "u(n)": un, "sp(2n,R)": spn,
            "compact": compact, "confined": confined}


# ----------------------------------------------------------------------
# validation harness (pre-registered anchors -- mirror mbqc_blackbox_test.py)
# ----------------------------------------------------------------------
def main():
    print("=" * 68)
    print("final_o3_cv_dla.py -- Sp(2n,R) leaf-confinement audit (CV analogue of G7)")
    print("=" * 68)
    print()

    # (i) passive interferometer on 2 modes: phases + one beamsplitter -> u(2), dim 4
    n = 2
    g_i = [phase(n, 0), phase(n, 1),
           beamsplitter_re(n, 0, 1), beamsplitter_im(n, 0, 1)]
    r_i = audit("(i) beamsplitter + phase shifters, 2 modes", n, g_i)

    # (ii) add a two-mode squeezer -> fills toward sp(4,R), dim 10
    g_ii = g_i + [squeeze_two_1(n, 0, 1), squeeze_two_2(n, 0, 1)]
    r_ii = audit("(ii) (i) + two-mode squeezer, 2 modes", n, g_ii)

    # (iii) single-mode squeezer + phase, 1 mode -> sp(2,R), dim 3
    n1 = 1
    g_iii = [phase(n1, 0), squeeze_single_1(n1, 0)]
    r_iii = audit("(iii) single-mode squeezer + phase, 1 mode", n1, g_iii)

    # --- pre-registered acceptance checks ---
    print("-" * 68)
    print("ANCHOR CHECKS (abort if any is off -- mbqc_blackbox_test.py rule):")
    checks = [
        ("(i)  dim = u(2) = 4",            r_i["dim"] == 4),
        ("(i)  passive-confined",          r_i["confined"] is True),
        ("(ii) dim = sp(4,R) = 10",        r_ii["dim"] == 10),
        ("(ii) NOT confined (active)",     r_ii["confined"] is False),
        ("(iii) dim = sp(2,R) = 3",        r_iii["dim"] == 3),
        ("(iii) NOT confined (active)",    r_iii["confined"] is False),
    ]
    ok = True
    for label, cond in checks:
        print(f"    [{'PASS' if cond else 'FAIL'}]  {label}")
        ok = ok and cond
    print("-" * 68)
    print(f"ALL ANCHORS PASS: {ok}")
    if not ok:
        raise SystemExit("ANCHOR FAILURE -- audit not trustworthy, aborting.")
    print()
    print("CV column of the certification map is now instantiated:")
    print("  passive linear optics  -> dim <= n^2  -> PASSIVE-CONFINED (emulable)")
    print("  + genuine squeezing     -> dim  > n^2  -> ACTIVE (not confined)")
    print("Trust assumption: audits a CLAIMED compilation (white-box), as G7 does.")


if __name__ == "__main__":
    main()
