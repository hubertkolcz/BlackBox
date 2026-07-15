"""LANE 1 falsification probe: non-balanced / aperiodic substitution words.
Evaluate (fc, theta-bar est, alpha-bar exact) for periodic approximants of
Thue-Morse, Fibonacci, period-doubling, and random-balanced words projected to
{c,t}, and compare the gap theta-bar - alpha-bar against gap(cct)=0.0698975.
If ANY beats cct, cct is not globally optimal. Exact alpha via alpha_density_word,
exact theta via word_density_transfer_sdp on the periodic approximant."""
from fractions import Fraction
from lovasz_theta_sparse import word_density_transfer_sdp as TH, alpha_density_word as AL

GAP_CCT = 0.0698975

def gap(w):
    th = float(TH(w)); al = float(AL(w))
    return th, al, th - al, w.count("c") / len(w)

def thue_morse(nbits):
    s = "0"
    while len(s) < nbits:
        s = "".join("01"[c == "0"] for c in s)  # wrong; do proper
    return s

def tm(n):
    s = [0]
    while len(s) < n:
        s = s + [1 - x for x in s]
    return s[:n]

def fibonacci_word(n):
    a, b = "c", "ct"  # standard fib substitution c->ct? use c->ct, t->c
    s = "c"
    prev = "t"
    A, B = "c", "t"
    # substitution c->ct, t->c
    x = "c"
    while len(x) < n:
        x = "".join("ct" if ch == "c" else "c" for ch in x)
    return x[:n]

def period_double(n):
    # substitution a->ab, b->aa  (period-doubling)
    x = "a"
    while len(x) < n:
        x = "".join("ab" if ch == "a" else "aa" for ch in x)
    return x[:n].replace("a", "c").replace("b", "t")

def main():
    cands = []
    # Thue-Morse projected c/t at several lengths (periodic approximant)
    for L in (12, 24, 48):
        w = "".join("ct"[b] for b in tm(L))
        cands.append((f"TM{L}", w))
    # Thue-Morse with c<->t bias variants (majority letter differs)
    for L in (12, 24):
        w = "".join("ct"[1 - b] for b in tm(L))
        cands.append((f"TMbar{L}", w))
    # Fibonacci projected
    for L in (13, 21, 34):
        w = fibonacci_word(L)
        cands.append((f"Fib{L}", w))
    # period-doubling
    for L in (16, 32):
        cands.append((f"PD{L}", period_double(L)))
    # cct-perturbations: cct with occasional defect (non-balanced)
    cands.append(("cctcct", "cctcct"))
    cands.append(("cctccct", "cctccct"))   # a cis defect
    cands.append(("ccttct", "ccttct"))     # a trans defect
    cands.append(("cctcctt", "cctcctt"))
    cands.append(("cctct", "cctct"))
    # near-2/3 aperiodic mixes
    cands.append(("cctcctcctt", "cctcctcctt"))
    cands.append(("cctccttcct", "cctccttcct"))

    print("cct reference:", gap("cct"))
    print(f"{'name':>12} {'len':>4} {'fc':>7} {'theta':>11} {'alpha':>10} {'gap':>11} {'vs cct':>10}")
    best = ("cct",) + gap("cct")
    rows = []
    for name, w in cands:
        try:
            th, al, g, fc = gap(w)
        except Exception as e:
            print(f"{name:>12} ERR {e}")
            continue
        flag = "  BEATS" if g > GAP_CCT + 1e-9 else ""
        rows.append((g, name, len(w), fc, th, al))
        print(f"{name:>12} {len(w):>4} {fc:7.4f} {th:11.7f} {al:10.6f} {g:11.7f} {g-GAP_CCT:+10.7f}{flag}")
    rows.sort(reverse=True)
    print(f"\nTOP gap among candidates: {rows[0][1]} gap={rows[0][0]:.7f} (cct=0.0698975)")
    print("ANY beats cct:", any(r[0] > GAP_CCT + 1e-9 for r in rows))

if __name__ == "__main__":
    main()
