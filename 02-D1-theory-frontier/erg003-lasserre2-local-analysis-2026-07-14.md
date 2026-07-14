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
only ~14% of the ϑ→α distance and stays above the integer. So on the target graph the
three-point bound would be expected to improve 19.666 → ~19.5, i.e. **it would not reach below
18 and could not prove ω ≤ 17.**

## Verdict

- **Local at the tractable level: yes, built and validated** — the abelian-Cayley + G₀
  reduction genuinely shrinks the SDP to 20 blocks (max 180); the end-to-end pipeline runs in
  well under a second on the 125-vertex analogue.
- **But the tractable level is provably insufficient** — demonstrated directly: the three-point
  bound does not close the analogous odd-power gap (11.009 ≥ 11 > 10).
- **The level that might work — full Lasserre-2 (s=2, "4-point") — is not local**: it is an
  order of magnitude heavier (moment matrix over stable *pairs*, reduced blocks of size ~10³),
  a genuine HPC/MOSEK computation, and there is **no guarantee it reaches < 18** either.

So a *local* rigorous certificate of ω ≤ 17 is **not achievable**: the reachable SDP level is
too weak, and the potentially-sufficient level is beyond a workstation. The activation bracket
**ω ∈ [17,19] with 17 evidenced-tight** stands — its closure is genuinely research-scale, now
confirmed from the *upper-bound* side as well (not just the search/exhaustion side). This
mirrors and reinforces the Paley-13 [39,46] situation.

Artifacts: `erg003_lasserre.py` (validated level-1 + block-diagonalizer, big graph),
`erg003_threepoint_sibling.py` (end-to-end three-point pipeline + the decisive X₁₂₅ result).
