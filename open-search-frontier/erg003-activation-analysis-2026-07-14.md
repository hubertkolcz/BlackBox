# ERG-003 activation — does the (3,1) cell fire? ω(C₉∨C₉∨C₉∨C₅) ∈ [17, 19], 17 evidenced-tight

2026-07-14. The (3,1) cell "activates" iff the emulator load `ω/(8√5) ≥ 1`, i.e. iff
**ω(C₉∨C₉∨C₉∨C₅) ≥ 18** (ω=17 → load 0.950, SAFE; ω=18 → load 1.006, activation). H3's
original claim ω=16 was already **REFUTED** — a genuine 17-clique exists (family
`(1,3,5,5,3)`, WCS-found and independently verified). The remaining question is whether an
**18-clique** exists. After three independent search regimes and a rigorous bound, the
honest answer is a sharp bracket with strong evidence for the low end.

## The bracket is [17, 19] and both ends are near-immovable by cheap means

`G = C₉∨C₉∨C₉∨C₅` is the OR/disjunctive (co-normal) product; `complement(G) =
C̄₉ ⊠ C̄₉ ⊠ C̄₉ ⊠ C̄₅` (strong product of cycle complements), so `ω(G) = α(complement(G))`.

- **Lower bound 17.** The trivial product bound is only `ω(C₉)³·ω(C₅) = 2³·2 = 16` (each
  cycle is triangle-free, ω=2). The verified 17-clique **strictly exceeds the product by 1** —
  ω is genuinely super-multiplicative here, which is exactly why the answer isn't simply 16.
- **Upper bound 19 (Lovász ϑ, exact).** ϑ is multiplicative over the strong product, so
  `ω(G) ≤ ϑ(C̄₉)³·ϑ(C̄₅)`. With `ϑ(C̄₉) = 1 + sec(π/9) = 2.06417777…` (SDP-confirmed) and
  `ϑ(C̄₅) = √5` (C̄₅ ≅ C₅, self-complementary): product `= 19.66646…` → **UB = 19**.
- **Schrijver ϑ′ provably cannot help.** Each factor's ϑ-optimal (α-side) SDP solution is
  already entrywise nonnegative (diag 1/n, cycle-edge entries positive, chords zero), so
  Schrijver's `X ≥ 0` constraint leaves each factor unchanged; their Kronecker product is
  nonnegative, PSD, feasible for the product's ϑ′ SDP and attains 19.666, forcing
  `ϑ′(product) = ϑ(product) = 19.666`. (Empirically confirmed on C̄₅⊠C̄₅: ϑ′=ϑ=5.000.)
  **To certify ω ≤ 17 one needs a strictly stronger relaxation — Lasserre / θ-body level ≥ 2
  (degree-4 SOS) on the full 3645-vertex product** — even with the automorphism group
  `(D₉≀S₃)×D₅` and its Terwilliger algebra for block-diagonalization, that is research-scale
  with no guarantee of dropping below 18.

## No 18-clique found by any of three independent search regimes

| Regime | Effort | Best | 18-clique? |
|---|---|---|---|
| Free local ILS (seeded) | (1,1)-swaps + 200 s ILS from the 17-clique | 17 | none |
| **WCS S=18 detection** (Memory16x128, 16 cores) | 10 C₅-layer families, 35 min each, **294.8 M** DFS nodes, 438 cr | 17 | none (all 10 PARTIAL) |
| **Free 7-strategy workflow** | 7 diverse methods, 150 s each, parallel | 17 | none (7/7) |

The 7-strategy sweep (all best = 17):
- **swap-BFS** — explored **681,006 distinct 17-cliques** (remove-1-add-2 test on each); none extends.
- **vertex-fixed B&B** — fix v₀, search its 2616-vertex neighborhood; k-core(16) removes 0 vertices ⇒ the neighborhood is *uniformly dense*, yet no 17-clique-in-A (→18) exists; 4.2 M B&B nodes.
- **simulated annealing (k=18)** — the sharpest signal: over **14.7 M swap-steps / ~11,000 restarts** the energy floored at **E = 1** (an 18-set with exactly one non-adjacent pair) and never reached 0; **405 distinct maximal 17-cliques** were probed at E=1 and **every one had zero common-neighbors** — non-extendable exactly like the seed.
- **DLS (1,2)-swap** (1.16 M iters), **multi-seed ILS**, **replicator/Motzkin-Straus** — all plateau at 17.
- **random-greedy baseline** — 669,440 blind restarts never even reach 17 (best 16), confirming the 17-clique is a *structured, rare* object, not a chance find.

**Qualitative conclusion:** the maximal 17-cliques form a genuine ceiling. Search after search
reaches 17, gets within a single edge of 18, and finds the underlying 17-cliques uniformly
non-extendable. This is strong convergent evidence that **ω = 17** and the cell does **not** activate.

## Cost to actually close the gap (why we hold)

- **Brute-force exhaustion** (prove no 18-clique ⇒ ω=17): the 16-core machine bills a flat
  ~12.5 cr/wall-min and all 10 families run in one concurrent wave, so cost = `438/f` credits
  where `f` = fraction of each DFS tree covered in the 35-min slice. Scenario band
  **f=25% → ~1,750 cr, f=10% → ~4,380 cr (central), f=3% → ~14,600 cr**, wall 2.3–19.4 h. The
  trees are heavy-tailed (node/wall varies ~10× across families), so the true cost may exceed
  the high end; a 1% tail gives ~44 k cr. This is a scenario band, not a measurement — no tree
  size is known (all 10 PARTIAL).
- **A cheap certificate does not exist:** ϑ and ϑ′ are both pinned at 19.666, and only
  Lasserre-2 could certify ω≤17 — research-scale, uncertain to succeed.

## Verdict

**ω(C₉∨C₉∨C₉∨C₅) ∈ [17, 19], with strong convergent evidence that ω = 17 — so the (3,1) cell
does NOT activate (load 17/(8√5) = 0.950 < 1).** The bracket's low end is evidenced-tight
(three independent regimes, incl. an SA that repeatedly stalled one edge short over 405 distinct
non-extendable 17-cliques); the high end 19 is the exact Lovász bound, immovable by ϑ/ϑ′.
Closure — proving 17 vs 18 rigorously — is **research-scale** (a symmetry-reduced Lasserre-2 SDP,
or a 1.7 k–15 k+ cr uncertain exhaustion), directly mirroring the Paley-13 `[39,46]` situation:
an evidenced-tight bracket whose formal closure is a single hard computation, not more brute force.

**Honest status: activation OPEN, ω ∈ [17,19], ω=17 evidenced-tight, no activation on all evidence.**
