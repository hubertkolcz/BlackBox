# Enhancement Blueprint — `EvaluatingBlackBoxPhysics-Illustrated.nb`

**Date:** 2026-07-15 · **Target:** `C:\Users\cp\Desktop\black-box\EvaluatingBlackBoxPhysics-Illustrated.nb` (944 KB, 5 970 lines)
**Rule of the pass:** *no new content.* Every figure, number, and paragraph added below already exists — rendered, computed, and kernel-verified — somewhere in the repo. This plan only **relocates and connects** it into the essay and **modifies** existing cells. Nothing is recomputed.

---

## 0. Diagnosis — what the notebook is, and what it leaves on the table

The notebook is already a strong illustrated essay: **Title → "The Instrument" framing → Stages 0–11 → Interlude (multiway) → "The Through-Line" → "The Cherry on Top" (Hawking) → backmatter**, carrying **54 inline vector figures, 10 interactive `Manipulate`/`Graphics3D` cells, 61 Input / 52 Output cells.**

But it has **zero `Import` cells** — so *every figure a module rendered to PNG/PDF sits outside the essay* — and a keyword sweep shows whole delivered tracks are near-absent:

| Probe in the essay | Hits | Reality in the repo |
|---|---|---|
| `Čech` / `cohomolog` | **0 / 0** | bound-derivation-question is the project's **stated #1 priority** (ESSAY-005), fully worked (P1–P4 + refuted H¹) |
| `Page curve` / `Bogoliubov` / `Gaussian` / `Wigner` | **0 / 0 / 0 / 0** | HK-006 (Page curve) and HK-007 (A1–A8 Gaussian) are both **built and verified** |
| `certification_map` | **0** | the 494 KB O3 staircase poster is the single best summary figure in the repo |
| `signaling` / `communication` | 3 / **0** | signaling-extension (O5) is a complete 3-gate taxonomy, no stage |
| `hypergraph`, `orbit_spectrum`, optical schematics | 0 | 11 rendered figures across figure-gallery / composition-optimality / open-search-frontier / optical-synthesis, none embedded |

The `figure-gallery/README.md` even says it out loud: *"the main essay … should import figures from this module's `figures/` directory directly rather than duplicating the derivations."* The enhancement is therefore mostly **connection work**, plus three sections lifted from already-written module scripts.

**Design principles for the pass**
1. Reuse only — Import rendered figures; paste verified numbers with their ledger IDs; lift narrative from existing essay-ready scripts.
2. Keep the systematic staged spine; new material becomes numbered stages, so "step-by-step" stays intact.
3. Negative/refuted results stay first-class (they are this project's credibility signature).
4. Mechanism for figures: an `"Input"` cell `Import[FileNameJoin[{NotebookDirectory[], …}]]` followed by a `"Text"` caption cell — matching the essay's existing *figure → caption-text* pattern.

---

## Part A — Embed the already-rendered figures (7 insertions, additive, zero computation)

| # | Figure file (repo-relative) | Insert at | What it shows / why there | Caption + number source |
|---|---|---|---|---|
| A1 | `figure-gallery/figures/leaf_sphere_paper.png` | **Stage 5**, right after the existing `Manipulate` (~line 1786) | Static Paper-theme **twin of the interactive already there** (red leaf DLA=1 vs sphere-filling cascade DLA=3, span=2). The `Manipulate` will not render in a static PDF export — this fixes that. | `VisualGallery.nb` §"so(3) Leaf Confinement"; numbers `{4,2,3,1}` |
| A2 | `figure-gallery/figures/hypergraph_paper.png` | **Stage 2** (Three-Number Ruler) | The two-copy GE object that *produces* √5: **25 vertices (C5×C5), 200 exclusivity edges, 10 pentads**, degree 16. Makes the √5 mechanism visible, not tabulated. | `VisualGallery.nb` §"GE Two-Copy Hypergraph"; `structureOK → {True,25,200,10}` |
| A3 | `certification-protocol/certification_map.png` | **Stage 3** (Certification Protocol); **reference again** in The Through-Line | The **3×3 staircase** — ACCESS (A1 table / A2 interventional / A3 attenuation) × ADVERSARY (NCHV / θ-blind tuned / θ-aware). Only **two cells are INDISTINGUISHABLE** (A1×tuned = Prop 1·BBT-002; A2×θ-aware = OQ1-B, fit <1e-9). This *is* the essay's central claim in one image. | `certification_map.nb` (4-section provenance) |
| A4 | `composition-optimality/orbit_spectrum.png` (`.pdf` twin) | **Stage 8** (Ergodic Optimization) | 2-panel: (A) orbit-density spectrum from **trans τ\*=1.3767** to **cis 3/2**, crowding zone 16/11, 19/13, 25/17; (B) seeds vs density — **cct alone drops to density−4/3, gap 0.0698975**. | `composition-optimality/orbit_spectrum_figure.wl` header |
| A5 | `open-search-frontier/witness_adjacency_certificate.png` | **Stage 11** (ω=17 catalyst) | The 17-clique witness for ω(C9∨C9∨C9∨C5) ≥ 17: **all 136 pairs adjacent, 0 non-adjacent** (family `[1,3,5,5,3]`). | `erg003_omega17_witness.json` (verify caption vs this file) |
| A6 | `open-search-frontier/orbit_size_distribution.png` | **Stage 11** (beside A5) | Automorphism-orbit-size distribution of the search graph, **\|Aut\|=349 920** — why symmetry-breaking matters. | `erg003_verdict.json` / `erg003_sat_calibration.json` |
| A7 | `optical-synthesis/schematics/` — **strip of 4**: `demo1_kcbs_pentagon_L1.png`, `demo2_c7_heptagon_L1.png`, `demo3_cct_mesh_reps2.png`, `demo4_table_V0977_L2.png` | **Stage 6** (Optical Constructor) | The compiler's actual output blueprints: KCBS L1 cascade (cosθ=1/φ, genuine so(3) DLA=3); C7 L1 (identity S=7−4θ(C7)); cct-mesh reps=2 (18 modes); pure table V=977/1000 **Layer-2 only, leaf-confined**. | `optical-synthesis/DESIGN.md`; `blueprints/*.wl` (`kcbs_L1/L2`, `mesh_cct2` are alt renders) |

*Portability note:* `Import[FileNameJoin[{NotebookDirectory[],…}]]` keeps the essay light and reproducible **provided the notebook stays at repo root** (it does). If you want a fully self-contained single file for submission, an optional final "bake" step replaces each `Import` output with the embedded raster — flagged in Part D.

---

## Part B — Three sections lifted from already-written tracks (no new results)

### B1 · New **Stage 12 — "The Priority Question: Can the Sheaf *Derive* the Bound?"**
*Insert after Stage 11, before The Through-Line.* This is the project instruction's explicit #1 priority and is currently missing. All four probes already exist in `bound-derivation-question/`:

- **Frame** (quote `RESEARCH.md` priority line): *can the AB sheaf derive local–global relations of GE graphs built as products of KCBS 5-cycles?*
- **P1/P4 — possibilistic route CLOSED** (`p1p4_census.csv`, `p1p4_torsion.csv`): supports are identical across classical↔quantum↔α\*, so every possibilistic invariant is flat; only the strongly-contextual row flips (`H1torsion {{∞,10}}`, CF→1).
- **P2 — bounded-size impossibility certified** (`p2_certificate.json`): exhaustive over ≤10-measurement partition-type covers, **2 classes reach 5/2**, NPA bounds **2.1784** and **2.2071**, *both < √5* — "the transfer fails exactly at the quantum tier."
- **P3 — gluing-LP reformulation PASSES** (`p3_certificates.json`, 16 gates): **L₁(C5)=5/2, L₂(C5)=5, L₂(C7)=49/4, L₃(C5)=25/2, L₃(C7)=343/8**; reduces the question to "which invariant of the weighted presheaf computes the optimal partition of unity."
- **H¹ detector REFUTED** (`final_h1_cocycle_results.json`): the Q/Z fractional-part cocycle is not gauge-invariant and is forced to 0 (C7: 20 776 bad overlaps) — a *rigorous* obstruction, kept as a first-class negative.
- **Verdict:** OPEN, sharply narrowed (obstacle `SH-006`: Bell covers ≠ CSW/GE covers). Optional live cells `Import` the CSV/JSON and print the two `hit_5_2` rows — reuse, not recompute.

### B2 · New **Stage 13 — "Extending the Ruler: Signaling & Communication Cost"**
*Insert after Stage 12.* Source: `signaling-extension/signaling_taxonomy.wl` (its `SignalingTaxonomyVerification` cell can be lifted verbatim).

- 3-gate taxonomy on **7 exemplar models** (SIG-001).
- **SF(C5, quantum) = 2√5 − 4 ≈ 0.4721**; one-bit LP over all **4⁵ = 1024** strategies gives minimal **μ = 2√5 − 4 bits/round** (SIG-002).
- Exact decomposition **e_quantum = (5 − 2√5)·e_classical + (2√5 − 4)·e_Wright**; PR box μ=1, SF=1.
- Candidate identity **SF = Δ_min REFUTED** (200 random tables, max gap ≈ 2.015) — kept as open question SIG-003.

### B3 · Expand **"The Cherry on Top" (Hawking)** from structural-negative-only → three parts
*Modify the existing section in place.* Keep the current exhaustive CF≡0 result as Part 1; add two subsections already built and verified:

- **Part 1 (keep):** structural negative — the experiments' Cauchy–Schwarz witness is single-context ⇒ **CF ≡ 0** at every discretization (HK-003).
- **Part 2 — Qubit sector, the Page curve certified** (HK-006, `cluster-state-realization/cct_mbqc_hawking_*`): Page curve Rényi-2 **peaks 2.08 / 2.77 / 3.47 bits at N/2** (N=8/10/12); Hayden–Preskill fidelity ~0.77, **OTOC exact 0.25**; CF anchors **CF(2√2)=√2−1, CF(2)=0, CF(2.25)=0.125** — confronted head-to-head vs 4 published papers (Chowdhury 2412.15180, Landsman 1806.02807, BEC 2404.16497).
- **Part 3 — Gaussian/Bogoliubov sector, the A1–A8 scoreboard** (HK-007, `hawking-application/hawking_gaussian_sector.wl`): A1 Planck `Sinh²r=1/(e^{w/T}−1)`; A2 S_vN=thermality; **A3 E_N=2r/ln2**; A4 `θ(n̄)=1+1/(2n̄)>1`; A5 Busch–Parentani Δ<0; **A6 CHSH(r)=2√(1+tanh²2r)→2√2** (lit B=2.25 → r_eff=0.285); A7 Hudson + single-context **CF=0**; **A8 CV-DLA dim 10 = sp(4,ℝ), ACTIVE** — "not passive-linear-optics-emulable, but Gaussian-classically-simulable."
- **Why it belongs:** Part 3 lands Hawking squarely back on the essay's two-lens spine — correlation lens says CF=0, resource lens says the CV-DLA is active — the exact synthesis the essay is built around.

---

## Part C — Systematic scaffolding, so the essay visibly captures *all* the work

- **C1 · "Objective → Stage → Claim" map** (new table right after "The Instrument"): O1–O5 + Priority + D1/MESH/MBQC → the stage that now covers each → ledger IDs. Pure reuse of the `RESEARCH.md` table; it makes the step-by-step coverage explicit and shows the essay now spans every objective.
- **C2 · "Results at a glance" ledger table** (verified headline numbers + claim IDs): 2<√5<5/2 (GE-001); CF=2√5−4; τ\*=1.3767177459, cis=3/2 (MESH); gap(cct)=0.0698975 with ladder **Γ₇..Γ₁₀ = 0.0770206 / 0.0752664 / 0.0720260 / 0.0714575** (CERT); ω≥17 vs ω(C9^v3)=8 (ERG-003); DLA 3 vs leaf 1 (LP-002); CV-DLA 10=sp(4,ℝ) (HK-007); SF=2√5−4 (SIG-002). All already in the ledger.
- **C3 · "Three devices, run live"** — harvest the ready-made demo from `ConstructCertifyLoop.nb` (§7): **7a** genuine KCBS cascade, **7b** blind-spot intensity emulator (declared leaf-confined), **7c** mesh-composed device (both lenses agree). Drop into Stage 4 or The Through-Line as an end-to-end engine run — it is already essay-grade (narrative + code + inline figure).
- **C4 · Backmatter tidy** — extend References with the papers the new sections already cite (Chowdhury 2412.15180, Landsman 1806.02807, BEC 2404.16497); fill the Acknowledgments `[TODO]` with the facts on record (mentor feedback on the KCBS + Global-Exclusivity direction per the 6 July 2026 progress report; staff/Stephen Wolfram suggested the direction) — author confirms names.

---

## Part D — Execution order (low-risk first) and the one step that needs care

1. **Back up** `EvaluatingBlackBoxPhysics-Illustrated.nb` → `docs/` (`.bak`) before any edit.
2. **Part A** figure Imports (A1–A7) — additive, lowest risk; confirm each path resolves and renders.
3. **Part C1 + C2** scaffolding tables — additive.
4. **Part B3** Hawking expansion — modify existing section into 3 subsections.
5. **Part B1** (Stage 12 sheaf) + **B2** (Stage 13 signaling) — additive new stages.
6. **Part C3** three-devices demo + **C4** backmatter.
7. **Rebuild the trailing cache** (`NotebookFileOutline` / `CellTagsIndex` at file end): the safe path is *open + save once in Mathematica*, which regenerates the outline and validates every new cell. (Hand-editing the cache is possible but unnecessary; a stale cache is harmless but untidy.)
8. **Verification pass** (final task): section count went 31 → ~34; all `Import` cells resolve; no stray `[TODO]` in added parts; optionally re-run the cited `.wl` gates (`RunSupportCohomology.wl`, `RunSignalingTaxonomy.wl`, `RunGaussianHawking.wl`) to reconfirm the pasted numbers end `OK → True`.

### Risks / caveats
- **Import portability** — keep the notebook at repo root, or run the optional "bake rasters" step for a self-contained submission file.
- **Interactives don't export to PDF** — exactly why the Paper-theme PNG twins (A1, and the static schematics A7) matter for the WSRI PDF deliverable.
- **"No new content" honored** — every added number carries an existing ledger ID and a kernel-verified source module; nothing here is recomputed or invented.

---

## Net effect

The essay goes from **12 stages, 54 inline figures, 0 imported** → **~14 stages + expanded Hawking, ~65 figures (11 rendered module figures embedded), a coverage map, and a results ledger** — and, most importantly, it now visibly *answers its own stated priority question* and carries all five objectives plus the negative results end-to-end. Same spine, same voice, nothing recomputed — the effort that already exists in the repo becomes visible inside the single deliverable.
