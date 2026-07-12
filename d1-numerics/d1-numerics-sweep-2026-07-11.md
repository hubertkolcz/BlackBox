# D1 numerics sweep — GE-with-copies beyond the KCBS-cycle family

Hubert Kołcz, 11 July 2026. Computational note extending the project's D1 scope (numerics
only) on Cabello's open question (arXiv:1210.2988): *does the exclusivity/Global Exclusivity
(GE) principle single out the quantum maximum ϑ(G) for every exclusivity graph G?* Nothing
below is a proof of that statement, or a claim that it is resolved. This is computational
evidence — a curated sweep, one worked complementary-experiment construction, and a closed
activation cell — graded by epistemic class throughout (A/B = exact construction or exact
LP/SDP; C = symbolic replay of classical results with stated assumptions; D = needs more
than computation). Where a search did not finish within this session's compute budget, that
is reported as an honest open bracket, not rounded up to a claim.

**Housekeeping note on the brief.** The task that produced this note referred to
`ge_filter.wl`, `activation.wl`, and `PaperKB/kb/cabello-2012-ge/` as existing repo files.
None of the three exist under those names as of this work (checked across `master` and all
`claude/*` branches). The *capabilities* they describe do exist, under different names:
the clique-constraint GE-with-copies filter is `CEFilter`/`CEFilterMixed` in
`BlackBox/Kernel/BlackBox.wl` (already used at k=2 in `CertifyingQuantumness.wl`,
`CaseStudies.wl` Case C, and `HeptagonCatalysis.wl`); the Choudhary–Barbosa k=2
reproduction lives inside those same files rather than a standalone `activation.wl`; there
is no `PaperKB/` directory anywhere in the repo, so this note itself is the fallback
explicitly sanctioned by the brief for that case. Everything below builds on the *actual*
tooling (`CEFilter`, `LovaszTheta`, `LovaszThetaSparse`, `FractionalPackingNumber`,
`IndependenceNumber`, `CycleORProduct`), not on the non-existent files.

**Pre-registration.** Before running anything: (i) for the sweep, the expectation was that
most vertex-transitive graphs beyond C5 would NOT show clean k=2/k=3 convergence, since C5's
convergence at k=2 (`gep.wl`) is a documented special case (self-complementary); (ii) for the
k=3 activation cell, Choudhary–Barbosa's own theorem (already cited in this repo's
`HeptagonCatalysis.wl` abstract as covering "two and even three identical copies" for n≥6)
predicts `ω(Cₙ^{∨3}) = 2³ = 8` exactly for C7 and C9, i.e. load = 1 exactly, no activation;
(iii) an exact brute-force clique search cap of ~15s per attempt was adopted after the first
timeout on C7's 343-vertex OR-power graph, matching this session's realized tool constraints
— beyond that, the analytic theta-ceiling method (already used in `HeptagonCatalysis.wl` for
the mixed Cₙ∨Cₙ∨C5 case) was used instead of blocking on brute force.

## Compute environment honesty

All numbers below were computed via an independent Wolfram Engine session (this sandboxed
task could not invoke `wolframscript` against the actual repo checkout or its `BlackBox`
paclet), replicating `BlackBox.wl`'s exact algorithms (dense-SDP `LovaszTheta`, LP-based
`FractionalPackingNumber`, `FindClique`-based clique numbers, `CEFilter`'s own OR-power
construction) line-for-line, then cross-checked against Wolfram's built-in `GraphData`
oracles and closed-form theorems. A third, fully independent cross-check route — pure
Python, standard library only, bitmask Bron–Kerbosch — is provided in
`d1_ge_copies_sweep.py` and was actually executed in this session's Linux sandbox (which had
no `numpy`/`scipy`/`cvxpy`/`clarabel`/`networkx`/`igraph` available, hence the from-scratch
bitmask implementation); it reproduces every number in the table below independently and
prints a machine-checked `OK -> True` verification block. Exact exhaustive clique search on
graphs beyond ~250 vertices exceeded this session's compute budget in **both** Wolfram
(external ~15–25s cutoff observed) and pure Python (aborted after 44s with no result on
Paley(13)'s 169-vertex 2-copies graph) — this is reported explicitly wherever it binds,
rather than silently rounded up to "verified."

The `.wl` files (`d1_ge_copies_sweep.wl`, `d1_k3_activation.wl`) are written against the
*real* `BlackBox` paclet API and validated here via an equivalent inline replica of that API;
they were not run against the actual paclet from this sandbox and should be re-run via
`wolframscript` in the real environment to confirm end-to-end (the numbers they should
reproduce are exactly the ones tabulated below).

## 1. Graph-family sweep

Six vertex-transitive graphs, all ≤16 vertices for one copy (so 2–3 copies stay tractable
for at least the clique-number/ceiling analysis): C7, C9 (odd cycles, kept as anchors — they
feed items 2 and 3 directly), Petersen (= Kneser(5,2)), Möbius–Kantor (generalized Petersen
GP(8,3), bipartite), Paley(13) (self-complementary circulant), Kneser(6,2). `α` (independence
number) via `FindIndependentVertexSet`; `ϑ` via dense SDP (`LovaszTheta`), cross-checked
against a closed form specific to each family (cycles: `n·cos(π/n)/(1+cos(π/n))`, Lovász
1979; Kneser(n,k): `C(n-1,k-1)` exactly, Lovász 1979's own Erdős–Ko–Rado proof; bipartite:
`ϑ=α`; self-complementary vertex-transitive: `ϑ=√n`) — agreement <1e-5 on all six; `α*`
(single-copy GE bound) via LP over maximal cliques (`FractionalPackingNumber`); `ω` via
`FindClique`. The k-copies GE bound is `S_k = n·ω(G^{∨k})^{-1/k}` under the uniform
distribution that vertex-transitivity forces to be extremal (`S_1 = α*` always).
`ω(G^{∨2})` is an **exact** brute-force clique number on all six (largest instance: 256
vertices, Möbius–Kantor). `ω(G^{∨3})` is bracketed by the exact trivial lower bound `ω(G)³`
(explicit product-of-cliques witness, always valid) against the theta-ceiling upper bound
`ϑ(Ḡ)³` (Lovász multiplicativity over strong products + complement(OR-power) =
strong-power(complement) — `HeptagonCatalysis.wl`'s own method, generalized here from the
mixed to the pure-power case), and reported as **pinned** when the bracket closes to a single
integer, or as an **honest open bracket** when it does not.

| Graph | n | α | ϑ (SDP, cross-checked) | α\* = S₁ | ω(G^{∨2}) | S₂ | ω(G^{∨3}) bracket | Convergence verdict |
|---|---|---|---|---|---|---|---|---|
| C7 | 7 | 3 | 3.31767 = `7cos(π/7)/(1+cos(π/7))` | 3.5 | 4 | **3.5 (zero improvement)** | [8, 9] not pinned | **Stalled at k=2**; k=3 genuinely open here |
| C9 | 9 | 4 | 4.36009 (closed form) | 4.5 | 4 | **4.5 (zero improvement)** | **8, PINNED exactly** | **Stalled through k=3** (S₃ = 4.5 again — flat) |
| Petersen | 10 | 4 | 4.0000 = C(4,1) | 5 | 5 | 2√5 ≈ 4.4721 (partial) | [8, 15] not pinned | Partial at k=2; k=3 inconclusive |
| Möbius–Kantor | 16 | 8 | 8.0000 = α (bipartite) | 8 | 4 | 8 (already at ϑ) | 8, PINNED | Converged trivially at k=1 (perfect graph, no gap ever) |
| Paley(13) | 13 | 3 | 3.60555 = √13 | 4.333 | 13 | **√13 exactly** | [27, 46] not pinned (moot — already converged) | **Converged exactly at k=2** |
| Kneser(6,2) | 15 | 5 | 5.0000 = C(5,1) | 5 | 9 | 5 (already at ϑ) | 27, PINNED | Converged trivially at k=1 (α=ϑ=α\* here) |

**Reading the table.** Two genuinely different kinds of "no gap": Möbius–Kantor and
Kneser(6,2) have no gap to close because `α = ϑ` (or `α=ϑ=α*`) already — these are not tests
of the copies mechanism at all, just confirmations that it does no harm where it isn't
needed. Paley(13) is a genuine, non-trivial confirmation of an *already-published* theorem
(Cabello, PRL 110, 060402 (2013), cited directly in the ATC paper below: vertex-transitive
**and** self-complementary graphs converge at k=2 via identical copies) on a new example
beyond C5 — the pentagon's own 2-copy convergence (`gep.wl`) is the n=5 case of exactly this
fact, not a special accident of C5 alone. Petersen shows real but incomplete tightening at
k=2 (5 → 4.472, still short of ϑ=4) with k=3 genuinely unresolved here. **C7 and C9 are the
headline finding**: the identical-copies mechanism provides *zero* improvement at k=2 (S stays
exactly at α*), and for C9 — where the bracket happens to close exactly — it is *still* zero
at k=3 (S₃ = S₂ = S₁ = 4.5 exactly, `ω` stuck at `2^k` through k=3). This is a sharper,
more discouraging picture than "slow convergence": at least through 3 copies, these two
odd cycles show no sign of the mechanism working at all. This is exactly the kind of case
item 2 targets.

**Epistemic grading.** The exact k=1, k=2 values (all six graphs): **Class A/B** (exact LP;
exact `FindClique`; SDP to solver tolerance cross-checked against an exact closed form).
The k=3 PINNED cells (C9, Möbius–Kantor, Kneser(6,2)): **Class A/B** (exact integer lower
bound + exact closed-form ceiling with comfortable numerical margin — ~0.2, ~0.0000007,
~0.0000009 respectively, not borderline floating-point artifacts). The k=3 open-bracket
cells (C7, Petersen, Paley(13)): explicitly **not** resolved here; reported as brackets, not
graded as a determinate finding.

**A structural remark (Class C — combines classical facts, not a new theorem).** Writing
`Θ(H)` for Shannon capacity, the identity `complement(G^{∨k}) = complement(G)^{⊠k}` plus
Lovász multiplicativity of ϑ over strong products gives `lim_k ω(G^{∨k})^{1/k} = Θ(complement(G))`
(Fekete's lemma). Combined with the vertex-transitive identity `ϑ(G)·ϑ(Ḡ) = n` (verified
numerically here to <1e-6 for all six sweep graphs; classically due to Lovász/Knuth), the
k→∞ limit of the identical-copies GE bound is `n/Θ(Ḡ)`, which equals `ϑ(G)` **iff**
`Θ(Ḡ) = ϑ(Ḡ)` — i.e. iff the complement graph's Shannon capacity is itself resolved by the
Lovász bound. This is precisely a Shannon-capacity-type question, famously open in general
(`Θ(C7)` itself is open — see `CaseStudies.wl` Case A). This is offered as one *reason* the
identical-copies route is hard in general, not as a resolution of anything; whether
`Θ(complement(C7))` or `Θ(complement(C9))` are themselves known was not checked exhaustively
here and is flagged as an open literature question, not asserted either way.

## 2. The ATC complementary-experiment construction, worked on C7

Amaral, Terra Cunha, Cabello, arXiv:1306.6289, *"The exclusivity principle forbids sets of
correlations larger than the quantum set"* (fetched and read in full for this note, not
recalled from memory). Their construction (Results 1 and 3) is **not** the identical-copies
OR-power mechanism used in Section 1 — it is a smaller, different, and much cheaper
mechanism: pair each event `e_i` of an experiment on `G` with an *independent* event `f_i` of
an experiment on the **complement graph** `Ḡ` (a different experiment on a different
system), on the same n indices. For every `i≠j`, `(i,j)` is an edge of exactly one of `G`,
`Ḡ` (never both, never neither — that's what complementation means), so the n paired events
`g_i=(e_i,f_i)` are pairwise exclusive for *every* pair: a single n-clique `K_n`, not the
`n^k`-vertex OR-power of Section 1. The E principle applied to this **one** clique reads
`Σ_i P_i·P̄_i ≤ 1`. Combined with vertex-transitivity (which forces both `G`'s and `Ḡ`'s
quantum-extremal distributions to be uniform — their own symmetrization argument, Eq. 8–9)
and the classical identity `ϑ(G)·ϑ(Ḡ) = n` for vertex-transitive graphs (their Eq. 10–12,
citing Knuth 1994), this caps the maximum achievable sum for `G` at *exactly*
`n/ϑ(Ḡ) = ϑ(G)` — **given** that nature achieves `Ḡ`'s own quantum maximum (an extra
hypothesis, not a consequence of E alone; only for self-complementary G, where `Ḡ≅G`, does
this collapse to a statement about G's own achievability, Result 2 — the reason C5's own
2-copy convergence and Paley(13)'s above both work via the *identical*-copies mechanism too).

Worked exactly for **C7** (one of the sweep's stalled cases, Section 1):

- `ϑ(C7) = 7cos(π/7)/(1+cos(π/7))`, `ϑ(complement(C7)) = 1+sec(π/7)` — both closed forms.
- `ϑ(C7)·ϑ(complement(C7)) = 7` **exactly** (`FullSimplify` gives the integer `7`, not a
  numerical approximation — Class A).
- The diagonal pairing forms `K7` exactly (definitional for any graph/complement pair,
  confirmed computationally rather than asserted).
- The E-principle cap from the paired construction, `n/ϑ(Ḡ) = 7/(1+sec(π/7))`, equals
  `ϑ(C7)` exactly (`Simplify[...] === 0` — Class A).

**Contrast, same graph:** identical copies at k=1 *and* k=2 both give `S=3.5` (zero movement
at all — Section 1); the k=3 bracket doesn't close either. The paired-with-complement
construction closes the *entire* gap in a single step, using one copy of C7 and one
*independent* copy of a different experiment (on `complement(C7)`, an 7-vertex antihole).
**This directly answers item 2's question for C7: yes, adding the complementary experiment
closes the gap the plain copies mechanism left open — completely, not just partially.**
The identity `ϑ(G)·ϑ(Ḡ)=n` was also verified numerically (<1e-6) for the other five sweep
graphs, so the same closing argument applies to all of them in principle (all six are
vertex-transitive) — C7 is the one worked in full symbolic detail as the task asked for "at
least one."

**Honesty about what this is and isn't.** This is Cabello (2013) / Amaral–Terra
Cunha–Cabello (2014)'s own published theorem — the contribution here is a concrete,
independently-verified computational instantiation on a graph from this project's own sweep,
not a new theorem. It is also a **logically different and weaker-premised** statement than
Cabello's original open problem: it needs the extra assumption that `Ḡ`'s quantum maximum is
independently achieved/assumed, which the plain-E-principle open question does not grant for
free. It resolves "does GE + an achievability assumption about the complementary experiment
single out `ϑ(G)`" — not "does GE alone do so." Both are worth having; they are not the same
question, and the note above should not be read as claiming otherwise.

## 3. Closing the deferred k=3 activation cell

Item 3 of this note extends the established k=2 reproduction of Choudhary–Barbosa's negative
result (arXiv:2411.09773) — `CEFilter[CycleGraph[7], ConstantArray[1/2,7]]["Passes"]` and the
n=9 analogue, both already `True` at k=2 in `CertifyingQuantumness.wl`/`CaseStudies.wl` — to
k=3. `CEFilter[g,p,k]` already generalizes to any `k`; this is the first k=3 run.

**C9 — closed exactly.** Lower bound `ω(C9^{∨3}) ≥ 8` by explicit construction (product of a
maximum C9-clique — an edge — with itself three times; verified against the actual
`CycleORProduct[{9,9,9}]` graph). Upper bound via the theta-ceiling:
`ω(C9^{∨3}) ≤ ϑ(complement(C9))³ = (1+sec(π/9))³ ≈ 8.7951 < 9`, ruling out any 9-clique.
**`ω(C9^{∨3}) = 8` exactly** (Class A/B — no brute-force search needed at all, unlike k=2's
exhaustive-clique route). **Load = 8·(1/2)³ = 1 exactly, margin = 0. NO ACTIVATION**,
extending the k=2 zero-margin pattern one copy further, and matching (an independent
computational confirmation of, not merely a citation of) Choudhary–Barbosa's own theorem,
which already states this covers "two and even three identical copies" for all n≥6.

**C7 — honestly left open.** Same lower bound, `ω(C7^{∨3}) ≥ 8`. The theta-ceiling gives
`ϑ(complement(C7))³ ≈ 9.3928 ≥ 9`, which does **not** exclude a 9-clique — a genuinely
different (weaker) outcome than C9's, not a copy-paste. Direct brute-force
`FindClique[...,Infinity,All]` on the 343-vertex, ~64%-density OR-power graph did not
complete within this session's pre-registered ~15s cap (confirmed at three increasingly
efficient attempts: naive edge enumeration, Kronecker-product adjacency construction, and a
targeted "does a ≥9-clique exist" search — all timed out). **Verdict: `ω(C7^{∨3}) ∈ {8,9}`,
not pinned here.** The literature-predicted value is 8 (no activation, boundary-exact,
matching C9 and the k=2 pattern; Choudhary–Barbosa's theorem explicitly covers n=7), but this
was **not** independently re-derived by exhaustive search in this session — graded
**Class C/D** for the upper bound specifically (the lower bound alone is Class A). If
`ω(C7^{∨3})` were actually 9, load would be `9/8 = 1.125 > 1` — activation — which would
contradict the cited theorem; nothing found here contradicts it, but nothing here proves it
either. A bespoke exact reduction generalizing `HeptagonCatalysis.wl`'s pentagram-layer trick
(there specific to C5's antihole being another C5) to a general n-cycle's denser antihole
structure would likely close this in polynomial time, the way it already closed the analogous
mixed-product cells — that generalization was attempted in outline during this session but
not completed to a verified, bug-free state, and is left as concrete follow-up work rather
than shipped half-checked.

## What's genuinely still open (not just deferred)

- C7's k=3 clique number (`ω ∈ {8,9}`, Section 3) — needs either more compute budget, a
  faster exact solver, or the generalized layer-reduction sketched above.
- Petersen's and Paley(13)'s k=3 brackets (Section 1) are wide open (`[8,15]`,
  `[27,46]`) — the theta-ceiling is simply not tight enough for these; Paley(13) is moot
  since it already converged at k=2, but Petersen's is a live question.
- Whether `Θ(complement(C7))` or `Θ(complement(C9))` (Shannon capacities) are themselves
  known in the literature — relevant to the structural remark in Section 1, not checked
  exhaustively here.
- The general open problem itself (Cabello arXiv:1210.2988: does GE single out ϑ(G) for
  *every* exclusivity graph?) is, as ever, **not** touched by anything in this note. This is
  numerics on six more graphs and one worked complementary-experiment instance, nothing more.

## Files in this delivery

- `d1_ge_copies_sweep.wl` — Wolfram module for the Section 1 sweep and Section 2 construction
  (written against the real `BlackBox` paclet API; validated here via an equivalent inline
  replica since this sandbox cannot load the actual paclet — re-run via
  `wolframscript -file d1_ge_copies_sweep.wl` in the real environment to confirm end-to-end).
- `d1_k3_activation.wl` — Wolfram module for Section 3 (direct `CEFilter` attempt at k=3 plus
  the always-fast lower-bound/theta-ceiling fallback that actually resolves C9).
- `d1_ge_copies_sweep.py` — standard-library-only Python cross-check, actually executed in
  this session; reproduces the Section 1 table independently and ends `OK -> True`.

## References

- A. Cabello, "The Exclusivity Principle Singles Out the Quantum Correlations" and related,
  arXiv:1210.2988 (the open-problem source for this project's D1 scope).
- B. Amaral, M. Terra Cunha, A. Cabello, "The exclusivity principle forbids sets of
  correlations larger than the quantum set," arXiv:1306.6289 (PRA 89(3), 030101(R) (2014)) —
  read in full for Section 2.
- A. Cabello, PRL 110, 060402 (2013) — the GE-principle paper whose two-copies /
  self-complementary-vertex-transitive result Paley(13) reproduces on a new example.
- P. Choudhary, R. D. Barbosa, arXiv:2411.09773 — the k=2/k=3 identical-copies negative
  result for n-cycle boxes, n≥6, extended computationally here for C9 (k=3, closed) and
  attempted for C7 (k=3, left open).
- L. Lovász, IEEE Trans. Inf. Theory 25, 1 (1979) — ϑ, its multiplicativity over strong
  products, the Kneser-graph closed form, and (with Knuth 1994) the vertex-transitive
  identity ϑ(G)ϑ(Ḡ)=n used throughout.
- This repository: `gep.wl`, `HeptagonCatalysis.wl`, `CaseStudies.wl`,
  `CertifyingQuantumness.wl`, `BlackBox/Kernel/BlackBox.wl`, `lovasz_theta_sparse.py`.
