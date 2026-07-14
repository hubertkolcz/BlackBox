"""Decisive test of the Legendre-frontier method: compute the UPPER CONCAVE HULL
of exact theta-bar over cis-frequency fc from enumerated primitive necklaces.
The Legendre transform min_lam[Gamma(lam)+lam*fc] certifies ONLY this concave hull.
If the hull at fc=2/3 equals the global theta max 3/2 (because theta=3/2 is hit at
fc straddling 2/3), then frontier(2/3)>=3/2 for ANY window k and any theta bound,
so gap-bound >= 3/2 - 4/3 = 1/6 = 0.1667 >> gap(cct)=0.0699. Method cannot work."""
from fractions import Fraction
from lovasz_theta_sparse import word_density_transfer_sdp as TH

def primitive_necklaces(pmax):
    seen, out = set(), []
    for p in range(1, pmax + 1):
        for bits in range(2 ** p):
            w = "".join("ct"[(bits >> i) & 1] for i in range(p))
            if any(p % d == 0 and w == w[:d] * (p // d) for d in range(1, p)):
                continue
            canon = min(w[r:] + w[:r] for r in range(p))
            if canon in seen:
                continue
            seen.add(canon)
            out.append(canon)
    return out

def upper_concave_hull(points):
    """points: list of (x,y). Return hull vertices (upper hull) sorted by x."""
    pts = sorted(set(points))
    # keep max y per x
    from collections import defaultdict
    mx = {}
    for x, y in pts:
        mx[x] = max(mx.get(x, -1e9), y)
    pts = sorted(mx.items())
    hull = []
    for x, y in pts:
        while len(hull) >= 2:
            (x1, y1), (x2, y2) = hull[-2], hull[-1]
            # cross product; pop if middle point below the line (not on upper hull)
            if (x2 - x1) * (y - y1) - (y2 - y1) * (x - x1) >= 0:
                hull.pop()
            else:
                break
        hull.append((x, y))
    return hull

def hull_value(hull, x):
    for i in range(len(hull) - 1):
        x1, y1 = hull[i]; x2, y2 = hull[i + 1]
        if x1 <= x <= x2:
            if x2 == x1:
                return max(y1, y2)
            return y1 + (y2 - y1) * (x - x1) / (x2 - x1)
    return None

def main():
    PMAX = 14
    words = primitive_necklaces(PMAX)
    print(f"{len(words)} primitive necklaces, period <= {PMAX}")
    pts = []
    max_theta = -1
    for w in words:
        fc = w.count("c") / len(w)
        th = float(TH(w))
        pts.append((fc, th))
        if th > max_theta:
            max_theta = th; argmax = w
    print(f"global max theta-bar = {max_theta:.9f} at '{argmax}' (fc={argmax.count('c')/len(argmax):.4f})")
    # words achieving theta = 3/2
    at15 = sorted({(round(w.count('c')/len(w), 6), w) for w in words if abs(float(TH(w)) - 1.5) < 1e-6})
    print("words with theta-bar = 3/2 (fc, word), sample:")
    seenfc = {}
    for fc, w in at15:
        if fc not in seenfc:
            seenfc[fc] = w
    for fc in sorted(seenfc):
        print(f"   fc={fc:.4f}  '{seenfc[fc]}'")
    hull = upper_concave_hull(pts)
    print("\nupper concave hull vertices (fc, theta):")
    for x, y in hull:
        print(f"   {x:.4f}  {y:.7f}")
    h23 = hull_value(hull, 2.0 / 3.0)
    print(f"\nCONCAVE HULL at fc=2/3 = {h23:.7f}")
    print(f"cct actual theta       = 1.4032309  (interior gap {h23-1.4032309:.7f} below hull)")
    print(f"floor at fc=2/3        = 1.3333333")
    print(f"=> Legendre gap-bound at 2/3 >= hull - floor = {h23 - 4.0/3.0:.7f}")
    print(f"   (flat Gamma_9 = 0.0720265 ; gap(cct)=0.0698975)")
    # the certified frontier gap bound (best case, exact theta) at any fc
    fcs = [i / 300 for i in range(301)]
    import math
    def floor(fc): return max(4.0/3.0, 1.0 + fc/2.0)
    gb = max(hull_value(hull, fc) - floor(fc) for fc in fcs)
    print(f"\nmax over fc of [concavehull(fc) - floor(fc)] = {gb:.7f}  (EXACT-theta Legendre bound)")
    print("Verdict: Legendre/concave-hull frontier CANNOT beat flat Gamma_k (>> 0.072).")

if __name__ == "__main__":
    main()
