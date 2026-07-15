# ERG-003 Ramsey Long-Shot: Does the Choudhary-Barbosa technique exclude a large clique in C9 v C9 v C9 v C5?

Date: 2026-07-13
Analyst role: Ramsey Analyst (zero-compute)
Source: Choudhary & Barbosa, arXiv:2411.09773 ("The exclusivity principle... Ramsey theory... n-cycle PR boxes")
Target graph: G = C9 v C9 v C9 v C5 (OR / co-normal / disjunctive product), 3645 vertices.

## OUTCOME: (b) PRECISE OBSTRUCTION.

The technique maps onto our problem cleanly, but it CANNOT reach omega <= 17. The
best it yields analytically is **omega(G) <= 20**, which is strictly weaker than the
already-known upper bound omega <= 19. The single lemma that breaks is Theorem 6 /
Corollary 7 applied to the n=5 catalyst factor: C5 has odd-girth 5, so the
Ramsey-forced short odd cycle is *legally realized* in the catalyst colour and the
proof's contradiction step never fires. Quantitatively the gap is exactly the
half-integral overhang nu*(C5) = 5/2 vs floor = 2. The method council's suspicion
(alpha* = 5/2 pentagon overhang) is CONFIRMED, and pinned to the exact lemma.

---

## 1. What the paper actually proves (load-bearing lemmas, quoted / paraphrased)

Definitions.
- Single n-cycle PR-box exclusivity graph G_n: vertices = context events; edge = exclusivity.
  Facts used: (Cor 5) no triangle K3; (Thm 6) smallest odd cycle has length n if n odd,
  n+1 if n even; (Cor 7) contains a C5 only if n in {4,5}.
- k copies: joint exclusivity is refined to an EDGE-COLOURED multigraph Gamma^k
  (the "multicolour product"): V = V1 x...x Vk; between u,v there is a colour-i edge
  iff u_i ~ v_i in G_i. The uncolored shadow of this is exactly the OR/co-normal product.
- E-principle (uniform weights 1/2^k): a clique of size 2^k + 1 in Gamma^k forces a
  violation (l / 2^k > 1). So "activation with k copies" = "K_{2^k+1} exists in Gamma^k".

Prop 2 (projection). For each monochromatic odd cycle in colour i of Gamma^k there is
an odd cycle in G_i of at most the same length. (Collapse repeated i-coordinates; each
collapse strictly shortens and preserves oddness.)

Thm 9 (two copies, n>=6). Gamma^2 has no K5, hence no activation. Proof engine: a K5
would need two edge-disjoint C5 (one per colour); by Cor 7 no C5 exists for n>=6.

Thm 11 (three copies, n>=6). Uses the Ramsey number R(C5,C5,C5) = 9 = 2^3 + 1: every
3-colouring of K9 has a monochromatic odd cycle of length 3 or 5. By Thm 6 an n>=6 box
has odd-girth >= 7, so no colour can host that cycle (Prop 2) -> no K9 -> no activation.

Thm 12 (general k). If n >= 2^k + 2 then k copies do not activate. Mechanism: the
required clique K_{2^k+1}, k-coloured, is forced by a Ramsey odd-cycle number to contain
a monochromatic odd cycle of length <= 2^k + 1; the box odd-girth n must exceed it,
n >= 2^k + 2.

THE WHOLE TECHNIQUE IS ONE MOVE: "large coloured clique => forced monochromatic SHORT
odd cycle => contradiction because NO factor has a short enough odd cycle." The
contradiction is total only when *every* colour's factor lacks short odd cycles.

---

## 2. Mapping to the mixed cell, and the exact break

Our G = C9 v C9 v C9 v C5 is the OR/co-normal product of the *plain cycle graphs*
(9,9,9,5 vertices), i.e. the uncoloured shadow J^4 with a 4-colour refinement:
three "C9 colours" and one "C5 colour". Each factor is triangle-free (omega = 2), so the
product lower bound is omega >= 2^4 = 16, and the paper's uniform activation threshold is
a clique of size 2^4 + 1 = 17. (ERG-003's actual weighting shifts the true activation
line to omega >= 18 because the C5 catalyst is fractionally weighted, load 9*sqrt5/20 ~
1.006; so "no activation" = "no 18-clique", i.e. omega <= 17.)

Odd-girth per colour under Prop 2:
- C9 colours (i=1,2,3): projected odd cycle lives in C9 -> length >= 9.
- C5 colour (i=4): projected odd cycle lives in C5 -> length >= 5, AND length 5 IS achievable.

Run the paper's move on a would-be K_17 with 4 colours. Any Ramsey-forced monochromatic
short odd cycle can be ROUTED INTO THE C5 COLOUR and realized as a genuine 5-cycle of C5.
Colours 1-3 still forbid odd cycles < 9, but the argument only needs ONE colour to absorb
the forced cycle, and C5 does. The contradiction step (Thm 6 / Cor 7: "no factor has odd
girth <= forced length") is FALSE here because the n=5 factor has odd-girth exactly 5.
This is precisely the box the paper itself flags as still activating (they prove the 5/4
KCBS n=5 two-copy violation). CONFIRMED: the break is the pentagon catalyst.

Consistency check against Thm 12: treat the cell (generously) as k=4 identical C9's.
Thm 12 needs n >= 2^4 + 2 = 18; n = 9 < 18, so the paper does not cover k=4 at n=9 even
for identical boxes. Replacing one C9 by C5 (odd-girth 5) only makes it worse. Hence the
mixed cell is provably outside the theorem's reach - not a numbering accident.

---

## 3. The strongest bound the technique can give: omega <= 20 (and why not lower)

Convert to the project's pentagram-layer structure. A clique W of G = H v C5,
H = C9 v C9 v C9, splits by C5-coordinate into 5 layers Q_0..Q_4:
- each Q_j is a clique of H (same C5-coord gives no edge);
- C5-adjacent layers need no H-constraint (C5 edge covers all cross pairs);
- each pentagram pair (distance-2) union Q_j U Q_{j+2} must be a clique of H.

The 5 pentagram-pair constraints are |Q_j| + |Q_{j+2}| <= omega(H) = 8. Each layer sits
in exactly 2 of the 5 unions (verified), so summing: 2 * sum|Q_j| <= 5 * 8 = 40, giving

    omega(G) = sum|Q_j| <= 20.

This is the sharpest bound obtainable from the odd-cycle-counting / LP core of the
technique. It is exactly a fractional-matching optimum: the pentagram unions form a C5 on
the layer indices (0-2-4-1-3-0), and max sum x_j s.t. x_j + x_{j+2} <= 8 over C5 edges
equals 8 * nu*(C5) = 8 * (5/2) = 20, attained at the uniform fractional point x_j = 4.

THE 5/2 IS THE OVERHANG. nu*(C5) = alpha*(C5) = 5/2 while the integral value is 2. The LP
only ever sees 5/2. The true answer (16-17) lives below the LP optimum by exactly this
half-integral slack. No reweighting or sharper Ramsey count *inside this technique* can
remove a genuine fractional optimum of the constraint polytope - that is what "fractional"
means. Closing 20 -> 17 requires the INTEGRALITY + RIGIDITY of H's maximum cliques
(every 8-clique of H is a rigid product of one edge per C9), which is information the
odd-cycle/LP machinery does not carry. The council's route-(iii) census (25 of 26 size-17
families forced to a rigid maximum 8-clique of H; 1 residual family needing max-clique
enumeration) is exactly the rigidity injection that lies OUTSIDE this technique.

---

## 4. Can the technique be strengthened within itself? No.

- Adding the C9 colours' odd-girth-9 constraint does not help: 17 (or 20) is far below
  any Ramsey threshold that would force a mono odd cycle < 9 in a C9 colour once the C5
  colour is available as a sink. The C5 sink defeats the pigeonhole before the C9
  constraints bind.
- The general Thm-12 threshold n >= 2^k + 2 = 18 (k=4) is a hard wall: our n's (9 and 5)
  are both below it. The technique is engineered for LARGE n relative to k; the ERG-003
  regime is the opposite corner (small n, catalyst present).
- Any LP/fractional relaxation of the pentagram-layer constraints has optimum 8*5/2 = 20;
  the technique is fractional by nature, so 20 is its floor.

Conclusion: the Choudhary-Barbosa technique is a valid but STRICTLY WEAKER instrument
here (bound 20 > known 19 > target 17). It cannot, even in principle, certify omega <= 17.

---

## 5. Honest ledger

- Best analytic bound from the technique: omega(G) <= 20. (Known independent bound: <= 19,
  so the technique adds nothing numerically.)
- Exact breaking lemma: Thm 6 / Cor 7 on the n=5 factor (odd-girth 5, not >= 7); the
  Ramsey-forced short odd cycle is legally realized in the C5 colour, killing the
  contradiction step.
- Confirmed suspicion: pentagon alpha* = nu* = 5/2 overhang; it is the 20-vs-16/17 gap.
- What WOULD close it (out of scope for this technique): integrality/rigidity of the 8
  maximum cliques of H = C9 v C9 v C9 (product-of-edges), i.e. the max-clique-enumeration
  + constraint-propagation route, not Ramsey counting.

No proof of omega <= 17 is claimed. Outcome (b), obstruction precise and confirmed.
