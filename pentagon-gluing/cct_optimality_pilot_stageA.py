"""cct-optimality PILOT, STAGE A (proxy functional test).

Decides whether the EXACT max-plus alpha tilt changes the certificate family's
LIMIT (not just its speed), using exact theta-bar (word_density_transfer_sdp) as
a stand-in for the k->infinity theta-window bound.

For every binary gluing necklace of period <= PMAX compute
   theta  = word_density_transfer_sdp(w)          (exact per-word theta density)
   alpha  = alpha_density_word(w)                  (exact max-plus alpha density)
   f_c    = (#c)/len(w)
and the two competing certificate functionals
   (a) FLOOR : theta - max(4/3, 1 + f_c/2)         (any affine-in-f_c alpha credit)
   (b) EXACT : theta - alpha                        (window-matched max-plus tilt)

PASS iff  (a) sup > 0.073 with argmax OFF cct   AND
          (b) sup = gap(cct) = 0.0699 +- 1e-3 attained AT cct, every other word below.
"""
import sys
from fractions import Fraction

from lovasz_theta_sparse import word_density_transfer_sdp, alpha_density_word

PMAX = int(sys.argv[1]) if len(sys.argv) > 1 else 8
GAP_CCT = 0.0698975  # certified irrational gap(cct)


def primitive_necklaces(pmax):
    """One canonical (lexicographically minimal rotation) representative per
    primitive binary necklace of period 1..pmax, alphabet ordered c<t."""
    seen, out = set(), []
    for p in range(1, pmax + 1):
        for bits in range(2 ** p):
            w = "".join("ct"[(bits >> i) & 1] for i in range(p))
            # drop imprimitive (has a strictly smaller period)
            if any(p % d == 0 and w == w[:d] * (p // d) for d in range(1, p)):
                continue
            canon = min(w[r:] + w[:r] for r in range(p))
            if canon in seen:
                continue
            seen.add(canon)
            out.append(canon)
    return out


def fc(w):
    return Fraction(w.count("c"), len(w))


def main():
    words = primitive_necklaces(PMAX)
    print(f"STAGE A: {len(words)} primitive necklaces, period <= {PMAX}")
    print(f"{'word':>10} {'fc':>6} {'theta':>11} {'alpha':>9} "
          f"{'(a)FLOOR':>10} {'(b)EXACT':>10}")
    rows = []
    for w in words:
        th = float(word_density_transfer_sdp(w))
        al = float(alpha_density_word(w))
        f = fc(w)
        floor_credit = max(Fraction(4, 3), 1 + f / 2)
        a_val = th - float(floor_credit)
        b_val = th - al
        rows.append((w, f, th, al, a_val, b_val))

    # sort by FLOOR functional descending for display of the top competitors
    for w, f, th, al, a_val, b_val in sorted(rows, key=lambda r: -r[4])[:12]:
        print(f"{w:>10} {str(f):>6} {th:11.7f} {al:9.6f} {a_val:10.7f} {b_val:10.7f}")

    a_arg = max(rows, key=lambda r: r[4])
    b_arg = max(rows, key=lambda r: r[5])
    print()
    print(f"(a) FLOOR sup = {a_arg[4]:.7f}  at  '{a_arg[0]}'  (fc={a_arg[1]})")
    print(f"(b) EXACT sup = {b_arg[5]:.7f}  at  '{b_arg[0]}'  (fc={b_arg[1]})")

    # every non-cct EXACT value strictly below cct's
    cct_b = next(r[5] for r in rows if r[0] == "cct")
    runner = sorted((r for r in rows if r[0] != "cct"), key=lambda r: -r[5])[0]
    print(f"    cct EXACT = {cct_b:.7f}; next-highest EXACT = "
          f"{runner[5]:.7f} at '{runner[0]}' (margin {cct_b - runner[5]:.7f})")

    pass_a = a_arg[4] > 0.073 and a_arg[0] != "cct"
    pass_b = (abs(b_arg[5] - GAP_CCT) < 1e-3 and b_arg[0] == "cct"
              and all(r[5] < cct_b - 1e-9 for r in rows if r[0] != "cct"))
    print()
    print(f"PASS (a) FLOOR off-cct plateau > 0.073 : {pass_a}")
    print(f"PASS (b) EXACT peaks at cct = 0.0699   : {pass_b}")
    print(f"STAGE A VERDICT: {'PASS' if (pass_a and pass_b) else 'FAIL'}")
    return 0 if (pass_a and pass_b) else 1


if __name__ == "__main__":
    sys.exit(main())
