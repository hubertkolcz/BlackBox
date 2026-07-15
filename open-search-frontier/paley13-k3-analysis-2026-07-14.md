# Paley(13) k=3 — sharpened characterization of the [39,46] bracket

2026-07-14. A genuine attempt to resolve H5 (`ω(Paley(13)^∨3) ∈ [39,46]`) with better
methods than brute force. The bracket is **not collapsed**, but the problem is
substantially sharpened: the structure is pinned down and the lower bound is shown to be
very likely tight, which relocates the entire difficulty into a single, well-identified
SDP computation.

## The exact structure (all verified)

`ω(Paley(13)^∨k)` (OR/conormal power) `= α(Paley(13)^⊠k)` (strong power of the complement;
Paley(13) is self-complementary). Key facts, machine-checked:

- **k=1:** α = 3 (Paley(13) has ω = α = 3).
- **k=2:** α(⊠2) = **13** exactly (`FindClique` on the 169-vertex OR square) **= ϑ(Paley13)² = 13**.
  So the Lovász bound is *tight at k=2*, hence **Θ(Paley13) = ϑ = √13 = 3.60555…** (Shannon capacity known exactly).
- **Even powers are then pinned:** α(⊠2m) ≥ α(⊠2)^m = 13^m and ≤ ϑ^{2m} = 13^m, so **α(⊠2m) = 13^m exactly** (α(⊠4)=169, α(⊠6)=2197, …).
- **Only odd powers are open,** with a *persistent* bracket: α(⊠(2m+1)) ∈ [3·13^m, ⌊√13·13^m⌋]
  (LB = product α(⊠2m)·α(⊠1); UB = ϑ^{2m+1}). The ratio 3.606/3 ≈ **1.20 is constant** across odd powers.
  **k=3 is the smallest instance: [3·13, ⌊√13·13⌋] = [39, 46].**

## The lower bound 39 is the product construction, and is very likely tight

The 39-clique is explicit: `{(a,b,c) : (a,b) ∈ [13-clique of ^∨2], c ∈ {0,1,4}}` (13×3 product),
verified a genuine 39-clique in the 2197-vertex graph. Three independent searches fail to beat it:

- **No vertex is adjacent to all 39** — the product clique is *maximal* (cannot extend to 40 by addition).
- **Seeded iterated local search:** 169,679 perturb-and-regrow iterations from the 39-clique → never reached 40.
- **Random greedy:** 211,083 restarts plateau at **33** (< 39) — the 39-clique is a *structured* object chance cannot find.
- **Exact `FindClique{40}`** times out (>150 s), and the purpose-built bitset-B&B C solver (symmetry-aware) also stopped at 39.

Convergent evidence that **α(Paley13^⊠3) = 39** — i.e., the Lovász bound is **not** tight at odd powers, and the odd sequence is product-optimal.

## Where the resolution lives (and why it's beyond a bounded run)

The gap [39,46] is *entirely* the weakness of ϑ at odd powers:
- **UB.** ϑ = ϑ′ = 46.87 exactly (Schrijver/Delsarte on the ℤ₁₃³ scheme; F9ix), and ϑ is multiplicative
  so **non-abelian symmetry reduction alone cannot beat 46** — it only makes a *higher* level tractable.
  To prove α ≤ 39 (or any UB < 46) requires **Lasserre level 2** (SOS degree 4) for the stable set,
  applied to the 2197-vertex power and **symmetry-reduced under Aut(Paley13)≀S₃** (order ≈ 78³·6).
  That is the Polak–Schrijver methodology: an isotypic block-diagonalization of a size-(≈2.4M) SDP —
  a research-scale computation, not a capped cloud job.
- **LB.** Beating 39 would need a genuinely non-product construction; all tractable searches (above) and the
  tuned solver fail, consistent with 39 being optimal.

## Verdict

**[39,46] stands, but H5 is sharpened:** Θ(Paley13)=√13 exactly; even powers pinned at 13^m; the open part is
exactly the odd-power gap; the LB 39 is the (very likely tight) product construction; and the residual difficulty
is a single symmetry-reduced Lasserre-2 SDP. Honest status: open, **[39,46], 39 evidenced-tight**, resolution = Lasserre-2.
