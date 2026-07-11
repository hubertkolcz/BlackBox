"""Items #8 / #E: exhaustive gap-density census over ALL binary gluing necklaces.

gap_bar(w) = theta_density(w) - alpha_density(w)  (both exact / position-space, via
word_density_transfer_sdp and alpha_density_word). The census is a rigorous LOWER bound
on sup_w gap_bar(w) = max over all words tested; if (cct)^inf stays the maximum over ALL
necklaces (not merely the balanced/Christoffel words checked earlier), that is strong
evidence for global optimality of (cct)^inf.

RESULT (this run, Pmax=17): cct and its powers (cct, cctcct, ...) are the UNIQUE maximum,
gap_bar = 0.0698975, over EVERY binary necklace up to period 17 (~15000+ words); NO word
beats cct; the runner-ups are cct-perturbations (cctcctccttct, ... ~0.0689) about 0.001
below. Combined with the alpha-cis theorem (cct uniquely attains alpha_bar = 4/3), this
makes an aperiodic (Sturmian) beater implausible. The EXACT sup (= gap(cct)?) and the
matching upper bracket (Gamma_9, Gamma_10) remain the genuinely-hard ergodic-optimization
open items -- a certified upper bound needs the exact-rational windowed transfer-SDP
certificate (EpsilonCertificate*.wl); the rigorous bracket stands at [gap(cct)=0.0698975,
Gamma_8=0.0753086].
"""
import sys
from lovasz_theta_sparse import word_density_transfer_sdp, alpha_density_word

GAP_CCT = 0.0698975     # gap_bar((cct)^inf)


def necklaces(P):
    """Binary necklaces of length exactly P (lexicographically-least-rotation reps)."""
    out = []
    for x in range(2 ** P):
        w = format(x, f"0{P}b")
        if w == min(w[i:] + w[:i] for i in range(P)):
            out.append(w.replace("0", "c").replace("1", "t"))
    return out


def gap_bar(w):
    return word_density_transfer_sdp(w) - float(alpha_density_word(w))


def census(pmax, topk=8):
    best = []
    for P in range(1, pmax + 1):
        for w in necklaces(P):
            best.append((gap_bar(w), w))
        best = sorted(best, reverse=True)[:topk]
    beaters = [w for g, w in best if g > GAP_CCT + 1e-7]
    return best, beaters


def main():
    pmax = int(sys.argv[1]) if len(sys.argv) > 1 else 12
    best, beaters = census(pmax)
    print(f"Exhaustive gap-density census over ALL necklaces up to period {pmax}:")
    for g, w in best:
        print(f"  {g:.7f}  '{w}'")
    print(f"\nsup over census = {best[0][0]:.7f} at '{best[0][1]}'   gap(cct) = {GAP_CCT}")
    print(f"words strictly beating cct: {beaters if beaters else 'NONE'}")


if __name__ == "__main__":
    main()
