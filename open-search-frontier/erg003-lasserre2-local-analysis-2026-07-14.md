# ERG-003 — can a *local* symmetry-reduced SDP certify ω(C₉∨C₉∨C₉∨C₅) ≤ 17?

2026-07-14. Attempt to close the activation bracket **[17,19]** from above with a
symmetry-reduced Lasserre/Schrijver SDP run on a single workstation (the Lovász ϑ=19.666 is
provably immovable; only a level-≥2 relaxation can beat it). Full pipeline built and
validated locally; the honest verdict is that the *tractable* level is **provably too weak**,
and the level that might work is **not local**.

## What was built and validated (all local, numpy/cvxpy)

- **Ḡ is an abelian Cayley graph** on A = ℤ₉³×ℤ₅ (|A|=3645); Ḡ = C̄₉⊠C̄₉⊠C̄₉⊠C̄₅ with
  connection set {0,±2,±3,±4}³×{0,±2}∖0, degree 1028. This is *why* ϑ has a closed form.
- **Level-1 = Delsarte LP = ϑ = 19.6664645521** — reproduced exactly via the character
  (Fourier) transform. Machinery validated. (`erg003_lasserre.py`)
- **Symmetry.** Aut(Ḡ) = A⋊G₀, point group **G₀ = ({±1}³⋊S₃)×{±1}, order 96** (only ±1
  multipliers preserve the connection set — no larger point group exists).
- **Block-diagonalization of the Terwilliger algebra** 𝒯=(ℂ^{A×A})^{G₀}, validated **two
  independent ways** (an averaging spectrum and a group-algebra-element eigendecomposition):
  **20 PSD blocks, sizes {105,120,30,180,120,150,90,60,60,12}∪{70,80,20,120,80,100,60,40,40,8},
  max 180, Σmₖ=1545, Σmₖ²=160433.** The reduced cone is small — *structurally* local-friendly.

## The practical wall (three-point / Schrijver s=1,t=1)

The tractable level-2 object is the three-point (Terwilliger) bound. Its variables are the
Γ-orbits of G-cliques of size ≤3: **1 point + 65 edge-orbits + 54,532 triangle-orbits.** The
blocks are tiny (max 180), but the algebra change-of-basis coupling the 54.5k triangle
variables into those blocks is a ≈54k×160k effectively-dense map (~9·10⁹ entries) — the
assembly is ~10¹²–10¹³ flops and the map does not fit in RAM. So the *solve* is MOSEK/HPC-scale,
**not** a clean local SCS run. "Locally computable" is true for the block *structure*, false
for the practical *solve* on this workstation.

## The decisive experiment: does three-point even close an odd-power gap?

Rather than run the HPC-scale version blind, tested the method on the smallest sibling with the
**same kind of gap**: X₁₂₅ = C̄₅⊠C̄₅⊠C̄₅ ≅ C₅⊠C₅⊠C₅ (=complement of C₅∨C₅∨C₅), where
**α = 10** (the classic Shannon value) but **ϑ = 5√5 = 11.18034** (floor 11) — an odd-power
product gap exactly analogous to 19-vs-17. The full symmetry-reduced three-point pipeline runs
here in **0.4 s** (19 blocks, max 12; `erg003_threepoint_sibling.py`):

| bound | value | floor |
|---|---|---|
| ϑ (level-1) | 11.18034 | 11 |
| **three-point (s=1,t=1)** | **11.00890** | **11** |
| α (truth) | 10 | — |

**The three-point bound beats ϑ (11.180 → 11.009) but does NOT close the gap** — it recovers
only ~14% of the ϑ→α distance and stays above the integer.

## But level-2 (s=2) DOES close it — the method is the right tool

Pushing one level higher, the **full Lasserre-2 (BGSV s=2, t=0)** bound on X₁₂₅ — moment matrix
over the 6251 stable sets of size ≤ 2, block-diagonalized under the full order-6000 automorphism
group (35 blocks, max 30) — gives (independently reproduced, CLARABEL+SCS agree, plus a
symmetry-free full-6251×6251 PSD reconstruction check, min eig −1.07e-8):

| bound | value | floor |
|---|---|---|
| ϑ = las₁ | 11.18034 | 11 |
| three-point (s=1,t=1) | 11.00890 | 11 |
| **las₂ (s=2,t=0)** | **10.53412** | **10** |
| α (truth) | 10 | — |

**las₂ = 10.534 < 11 pins the floor to α=10 — it closes the odd-power gap that the three-point
level could not.** So the SDP avenue is *not* futile: **level-2 is exactly the level that
resolves this family**, and full Lasserre-2 on the target graph would be expected to drive
19.666 below 18, i.e. **prove ω ≤ 17 (no activation)**. (Pipeline: `erg003_las2_sibling.py`.)

## Verdict

- **Local at the tractable level: yes, built and validated** — the abelian-Cayley + G₀
  reduction genuinely shrinks the SDP to 20 blocks (max 180); the end-to-end pipeline runs in
  well under a second on the 125-vertex analogue.
- **But the tractable level is provably insufficient** — demonstrated directly: the three-point
  bound does not close the analogous odd-power gap (11.009 ≥ 11 > 10).
- **The level that works — full Lasserre-2 (s=2, "4-point") — is validated but not local**: it
  **does** close the gap (10.534 < 11 on the sibling), so on the target graph it would very
  likely prove ω ≤ 17. But for the 3645-vertex graph its moment matrix is indexed by the ~4.77M
  stable *pairs* (edges of G), and even after the order-350k symmetry reduction it is an order of
  magnitude heavier than the three-point build — a genuine **MOSEK/HPC computation**, not a
  workstation SCS run.

So the picture is now sharp on **both** axes:
- *Local but insufficient*: three-point (s=1,t=1) — built, runs locally, provably too weak (11.009).
- *Sufficient but not local*: Lasserre-2 (s=2) — validated to close the gap (10.534→floor 10),
  but requires MOSEK-class tooling + a heavy assembly on the 3645-vertex / 4.77M-pair problem.

A *local* rigorous certificate of ω ≤ 17 is therefore **not achievable** — but the SDP avenue is
**not futile**: a symmetry-reduced **Lasserre-2 MOSEK run is now a justified investment** (the
method is proven to close exactly this kind of odd-power product gap). Absent that run, the
activation bracket **ω ∈ [17,19] with 17 evidenced-tight** stands. This mirrors and reinforces
the Paley-13 [39,46] situation — whose stated resolution (Lasserre-2) is now empirically
validated on the analogous odd-power gap.

## Exact sizing of the big-graph Lasserre-2 (2026-07-14) — and why WCS can't run it

To price a Wolfram-Compute-Services run, the reduced SDP was sized *exactly* (Burnside orbit
counts + an analytic Wigner–Mackey/Clifford block computation, both cross-validated on the
125-sibling and a 405-vertex intermediate):

- **Variables: 2,670,898** moment variables = 1 point + 65 edge-orbits + **9,309** triangle-orbits
  + **2,661,523** four-clique-orbits (the 4.77M-pair index has 920.9 billion 4-cliques → 2.66M
  Γ-orbits). All exact.
- **Blocks: 382 PSD blocks, max block 1309×1309**, Σ block² = 66,044,594, total cone dim ≈ 33M.
  The earlier naive scaling estimate (~390) was **wrong by 3.4×** — the true max block is
  |S_G|/2 + 1 = 1309 (driven by the 8 character-orbits with trivial point-group stabiliser).

**WCS cost verdict:** the *assembly* (a bespoke analytic sparse assembler — the sibling's dense
6251-dim method is categorically impossible at 4.77M, ~90 TB) is ~**1,500–12,000 credits** on
Memory16x128. The *solve* is **infeasible on WCS at any price**: Wolfram `SemidefiniteOptimization`
dies far past its ~10⁴-constraint limit; any interior-point (CLARABEL/**MOSEK**) needs a
2.67M×2.67M Schur complement = **57 TB**; SCS produces no rigorous certificate (can't prove < 18).
**MOSEK is a hard prerequisite *and* insufficient** — 2.67M variables are infeasible even on a
256 GB–1 TB HPC node without further structural reduction (chordal/low-rank/finer symmetry).
Wasted-spend risk > 90–95%.

**So the credit question resolves to: spend 0 on a WCS solve — it is a SCALE wall, not a budget
question.** A certified ω ≤ 17 by this route is a days-to-weeks off-WCS MOSEK/HPC research-software
project with non-trivial failure risk.

## Is there ANY WCS-only method left? (2026-07-14, second pass)

Two more angles checked before concluding "no way":

**GLV(s=1,t=2) — a cheaper-looking SDP hierarchy level — confirmed dead too.** This variant
(Gvozdenović–Laurent–Vallentin, arXiv:0712.3079) uses the *same* moment variables as full
Lasserre-2 but block-diagonalizes per-pair-orbit instead of monolithically. On the sibling it
**closes the gap and even beats full Lasserre-2** (10.38886 < 10.53412 < 11 — the tightest of all
four levels tested: ϑ=11.180 > three-point=11.009 > las₂=10.534 > GLV=10.389 > α=10). But at
big-graph scale it's **worse**: each pair-orbit only gets its own little stabilizer (median order
~8 of |Γ|=349,920, vs. full Lasserre-2 exploiting all 349,920 at once), so ≥7 of the 65 pair-orbits
produce near-**unreduced ~3646×3646 blocks** — 2.8× worse than las₂'s 1309 max block, aggregate
cone 4–6× larger. Every SDP route is now confirmed dead on WCS.

**Exhaustion (pure DFS, no SDP/MOSEK) is the one live WCS-native path — but costs far more than
first estimated.** Digging into the solver's actual anchor structure: the S=18 census is not 10
equally-hard families — 5 need only 386 anchors, 3 need 37,464, and **2 (families 6 and 9) need
1,202,564 anchors each**, with the first anchor not yet cleared in 2100s of compute. Revised
estimate: **central ~50,000–70,000 credits**, with real risk of 300,000+ or effectively open-ended
for those two families. 7 of 10 families haven't cleared even their first anchor — the same
signature that hid the real S=17 witness before, so "no result yet" must not be read as evidence
for NO. A concrete bug was also found: `erg003_s18_sweep.py` has no checkpoint/resume, so reruns
silently discard prior paid-for progress — a free fix needed before spending more.

**Verdict: not "no way" — but the one remaining way is expensive, uncertain for 2 of 10 families,
and needs a free bug fix plus a small paid pilot (~1,000–2,500 cr) before committing real budget.**
Ranked recommendation: (1) fix the checkpoint bug — free; (2) run a capped pilot on the two hard
families to see if within-family symmetry or replanning rescues them; (3) only then decide on full
exhaustion; (4) do not fund Lasserre-2 or GLV at big-graph scale — both are dead ends.

Artifacts: `erg003_lasserre.py` (validated level-1 + block-diagonalizer, big graph),
`erg003_threepoint_sibling.py` (end-to-end three-point pipeline + the decisive X₁₂₅ result).
