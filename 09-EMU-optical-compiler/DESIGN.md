# 09-EMU-optical-compiler — Architecture (DESIGN.md)

**The constructive mirror of `00-BBT` certification.** `00-BBT-blackbox-protocol`
runs the two-lens theorem in the *analysis* direction: given a table (and a claimed
compilation), it *certifies* whether a device is quantum or classically-optically
emulable. This module runs the *same mathematics in the synthesis direction*: given a
target (a unitary, a no-disturbance table, or a mesh word), it *emits an optical
blueprint* — a Givens/beamsplitter mesh (Layer 1), an intensity-redistribution
schedule (Layer 2), or a stage/routing list (mesh) — together with the per-component
certification verdict that says which of the two it had to use and why.

Status: architecture spec, 2026-07-13. This file is the contract for three parallel
builders (Section 8). Author of spec: Architect pass; no shipped `.wl` yet.

## Honest scope (must survive into `OpticalCompiler.wl`'s header, verbatim in spirit)

The compiler emits **emulators of BLOCK-LOCAL statistics** — per-block tables and
block-local AvN witnesses — which is exactly what Prop. 1 / the certification map says
classical optics CAN do. It does **NOT** construct globally-entangled cluster states:
single-photon linear optics cannot, absent exponential mode count or KLM nonlinearity.
The emulated/genuine boundary carried in every blueprint is the framework's two-lens
theorem applied constructively. Cite: Prop. 1 / `BBT-002`, `BBT-003`, `MESH-004`,
`MESH-008`, and Frustaglia et al., PRL **116**, 250404 (2016).

Layer-2 blueprints in particular are the *constructive* form of the adversarial case
(iii-d) of `mbqc_blackbox_test.py`: a divided classical beam reproducing a quantum
table exactly. Their honesty flag is the DLA audit (Layer 3): a Layer-2 blueprint is
leaf-confined by its own audit (`DLADimension < 3`), and the blueprint says so.

---

## 1. Layer model (what is being integrated, and from where)

| Layer | Source file (READ ONLY — copy helpers verbatim + attribute) | Direction here |
|------|------|------|
| **L1 Interferometer** | `01-D2-core-computation/kcbs_circuit.wl` (Sec. 3–4, cascade `[P,T1..T4]`), `kcbs_circuit_ncycle.wl` (`buildNCycleCircuit`), `01-D2-core-computation/BiphotonSimulator.wl` (u⊗u lift) | synthesize the Givens/beamsplitter mesh of a target unitary |
| **L2 Intensity** | `00-BBT-blackbox-protocol/mbqc_blackbox_test.py` (`table_intensity`, `sample_table`, construction iii-d) | synthesize per-context intensity fractions + source/splitter/detector schedule |
| **L3 Dispatcher** | `BlackBox` paclet (`CascadeGenerators`, `So3Axis`, `DLADimension`); `00-BBT/final_o3_cv_dla.py` (Sp(2n,R) CV closure) | decide, per component, L1 vs L2, and stamp the verdict |
| **Mesh routing** | `04-cluster-state-mbqc/cct_mesh_sparse_construction.wl` (`wordRingEdgesFast`) | translate a `(word, reps)` mesh into a stage/routing list |

**Two-lens dispatch rule (from L3):** a component whose claimed dynamics is
leaf-confined / poly-DLA / table-only ⇒ **Layer 2 suffices** (emulable, cheap); a
genuine multi-axis `so(3)+` block ⇒ **Layer 1** (a real interferometer is required).
Every emitted blueprint carries a per-component certification verdict.

**Verified anchor facts (recomputed this pass, exact):**
- Cascade Givens angle: `cos θ_k = 1/GoldenRatio = (√5−1)/2` **exactly**, all four `k`
  (`RootReduce[cos θ_k − 1/GoldenRatio] == 0`); `sin θ_k = Root[#^4+#^2−1&,…] = √(1/φ)`.
- Period-2 structure: `T3 == T1` and `T4 == T2` exactly ⇒ cascade `= [P,T1,T2,T1,T2]`.
  `T1` fixes mode 2, acts on plane {1,3}; `T2` fixes mode 1, acts on {2,3}.
- `DLADimension[CascadeGenerators[]] == 3`, axis span `== 2` (the "2→3" anchor).

---

## 2. API — exact names and signatures

All symbols live in context `HubertKolcz\`OpticalCompiler\``. Every function is a
pure definition (Get-loadable); no demo runs at load. Numeric/exact convention: every
parameter-bearing field carries BOTH `"Exact"` (algebraic, `RootReduce`d) and
`"Numeric"` (`N[...,$MachinePrecision]`).

### 2.1 Layer 1 — interferometer synthesis (Builder A)

```
CompileInterferometer[u_?MatrixQ, opts:OptionsPattern[]] -> StageMesh assoc
CompileInterferometer[spec_Association]                  -> StageMesh assoc
```
- Matrix form: Reck (default) or Clements (`Method->"Clements"`) Givens elimination of
  a unitary/special-orthogonal `u` into a mesh of two-level rotations + phases. Exact
  path taken automatically when `u` has algebraic entries (Section 5). Returns
  `<|"ModeCount"->n, "Stages"->{stage...}, "Unitary"-><|"Exact"->…,"Numeric"->…|>,
    "Method"->"Reck"|"Clements", "ResidualDiagonal"-><phases>|>`.
- Spec form (the A1/A2 anchor path): `spec = <|"Scenario"->"KCBS"|>` or
  `<|"Scenario"->"Cn","n"->n_?OddQ|>` reproduces the Lapkiewicz cascade `[P,T1..T_{n-1}]`
  directly from the geometry (reuse `kcbs_circuit.wl` / `buildNCycleCircuit` verbatim
  with attribution). This is NOT re-derived through Reck; it is the literal cascade so
  A1/A2 can compare byte-for-byte.
- Options: `"Exact"->Automatic|True|False`, `"Encoding"->"Qutrit"|"BiphotonQubit"`
  (the second returns the u⊗u collective-rotation stages via the `BiphotonSimulator.wl`
  ZYZ lift, with the singlet leakage flag as a stage of type `"Flag"`).

Helper (public, needed by VerifyBlueprint):
```
GivensDecompose[u_?MatrixQ, "Reck"|"Clements"] -> {stage...}   (* pure list *)
StagesToUnitary[stages_List, n_Integer]        -> {Exact,Numeric} matrix  (* re-multiply *)
```

### 2.2 Mesh routing (Builder A)

```
CompileMeshRouting[word_String, reps_Integer] -> Mesh assoc
```
Uses a **verbatim copy** of `wordRingEdgesFast` (Section 5, no Join-in-loop). Returns
`<|"Word"->word, "Reps"->reps, "ModeCount"->3 L, "L"->L,
   "Blocks"->{blockStage...}, "Routing"->{routing...}, "EdgeList"->{{i,j}…}|>`
where `L = StringLength[StringRepeat[word,reps]]`, one 3-mode Lapkiewicz block-stage
per pentagon; `EdgeList` is exactly `wordRingEdgesFast[word,reps]` (the A4 anchor).
`Routing[[k]] = <|"From"->k-1,"To"->k, "SharedModes"->{3(k-1)+1,3(k-1)+2},
"Orientation"->"cis"|"trans"|>`, orientation `= "trans"` iff the k-th letter is `t`
(the wordRing swap), `"cis"` for letter `c`.

### 2.3 Layer 2 — intensity emulator synthesis (Builder B)

```
CompileIntensityEmulator[table_List, scenario_Association, opts:OptionsPattern[]] -> Schedule assoc
```
`scenario` is a `BlackBox\`CycleScenario[n]` (or any `CoverScenario`) association;
`table` is the empirical model vector `e` in that scenario's section order. Performs
the **exact rational feasibility LP over the no-disturbance polytope**: verify
`CycleCoboundary[n].e == 0` (no signaling) and per-context fractions ≥ 0 summing ≤ 1,
via `LinearOptimization` with flat variable list and `Method->"RevisedSimplex"` on
exact rationals/`Q(√5)` (Section 5). Returns
`<|"Feasible"->True|False, "Scenario"->…, "IntensitySchedule"->{ctxSchedule...},
   "Stages"->{source,splitter,detector…}, "TableReproduced"-><|Exact,Numeric|>,
   "NodeSum"-><|Exact,Numeric|>, "SignalingResidual"->0|…|>`.
Each `ctxSchedule = <|"Context"->{i,j}, "Fractions"-><|"f00"->…,"f01"->…,"f10"->…|>
(Exact+Numeric), "SourceIntensity"->1|>`. Convenience constructor mirroring iii-d:
```
IntensityTableKCBS[t_, delta_] -> table  (* (f00,f01,f10)=(1-2t, t-delta, t+delta) *)
```
so `IntensityTableKCBS[1/Sqrt[5], 0]` is the A3 anchor.

### 2.4 Layer 3 — dispatcher / DLA (Builder C)

```
DispatchLayers[targetSpec_Association] -> Dispatch assoc
```
`targetSpec` describes the target as a list of components, each with either a claimed
generator set (`"Generators"->{so(3) matrices}`), a declared unitary, or a table.
For each component compute `span = MatrixRank[So3Axis/@gens]` and
`dla = DLADimension[gens]` (reuse paclet). Verdict per component:
`"emulable"` (leaf-confined `dla<3`, or table-only) ⇒ `"Layer"->"L2"`; `"genuine"`
(multi-axis, `dla>=3`) ⇒ `"Layer"->"L1"`. Returns
`<|"Components"->{<|"Name"->…, "Span"->…, "DLADimension"->…, "LeafConfined"->bool,
   "Verdict"->"emulable"|"genuine", "Layer"->"L1"|"L2"|"Mesh"|>...},
   "OverallLayer"->…|>`.
CV extension (optional, port `final_o3_cv_dla.py` to WL with attribution; skip if time
short — L1/L2 gates do not depend on it):
```
CVLeafConfinedQ[gens_List, n_Integer] -> <|"Dim"->,"Compact"->,"Confined"->bool|>
```
using `K = Ω.G`, `LieClosure` to fixed point, confined ⇔ closure ⊆ u(n) (all
antisymmetric, `dim ≤ n^2`).

### 2.5 Emission and self-certification (Builder C)

```
EmitBlueprint[targetSpec_Association, opts:OptionsPattern[]] -> Blueprint assoc   (Section 3)
VerifyBlueprint[bp_Association]                              -> Verify assoc
```
`EmitBlueprint` orchestrates: `DispatchLayers` picks the layer per component, then
routes to `CompileInterferometer` / `CompileIntensityEmulator` / `CompileMeshRouting`,
assembles the Blueprint Association, and attaches `"Schematic"->Graphics[…]` (native
`GraphicsRow`/`Graph` of the mesh; no hand-rolled geometry beyond box glyphs).
Option `Method->Automatic|"L1"|"L2"|"Mesh"` forces a layer (Automatic = dispatch).

`VerifyBlueprint` is the **self-certification loop (A5)**: it re-simulates the
blueprint from its own data — L1: `StagesToUnitary` then Born statistics of the target
observables; L2: fold the intensity schedule to a table; Mesh: rebuild the edge list —
compares to the target statistics exactly, AND re-runs the DLA audit to confirm the
recorded verdict matches the layer actually used (a Layer-2 blueprint must be
leaf-confined by its own audit). Returns
`<|"StatisticsMatch"->bool, "MaxDeviation"->…, "TargetReproduced"->bool,
   "DLAVerdictConsistent"->bool, "OK"->bool|>`.

### 2.6 Module verdict (Builder C, top of `OpticalCompiler.wl`)

```
OpticalCompilerVerification :: association with "OK" -> True   (the repo signature)
```
Runs anchors A1–A5 (Section 6) and ANDs their pass flags into `"OK"`. Behind an
explicit runner only — the package defines it as a delayed value or the runner
evaluates it; nothing heavy runs on bare `Get`.

---

## 3. Blueprint format (one Association schema)

`EmitBlueprint` returns exactly this shape. `VerifyBlueprint` reads it and fills
`"SelfCertification"`. Keys are fixed; this is the cross-builder contract.

```
<|
 "TargetSpec"    -> <original targetSpec assoc>,
 "ModeCount"     -> n_Integer,
 "Layer"         -> "L1" | "L2" | "Mesh" | "Mixed",
 "Stages"        -> { stage, ... },              (* ordered; see stage schema below *)
 "Routing"       -> { routing, ... } | Missing,  (* mesh case only *)
 "IntensitySchedule" -> { ctxSchedule, ... } | Missing,  (* L2 parts only *)
 "Unitary"       -> <|"Exact"->matrix, "Numeric"->matrix|> | Missing,  (* L1 parts *)
 "CertificationVerdict" -> <| per-component, from DispatchLayers:
        <|"Name"->…, "Span"->Integer, "DLADimension"->Integer,
          "LeafConfined"->bool, "Verdict"->"emulable"|"genuine",
          "Layer"->"L1"|"L2"|"Mesh"|> ... |>,
 "Schematic"     -> Graphics[...],
 "Provenance"    -> <|"Targets"->…, "Anchors"->{"A1"…}, "Date"->"2026-07-13",
                      "Citations"->{ "BBT-002","BBT-003","MESH-004","MESH-008",
                        "Frustaglia PRL116 250404", "Lapkiewicz Nature474 490" }|>,
 "SelfCertification" -> <from VerifyBlueprint> | Missing
|>
```

**Stage schema** (atom of `"Stages"`), uniform across layers:
```
<|"Type"     -> "BS" | "Phase" | "Source" | "Detector" | "Prep" | "Flag",
  "Modes"    -> {i} | {i,j},                (* 1-indexed optical modes touched *)
  "Parameter"-> <|"Exact"->expr, "Numeric"->real|> | None,
  "Label"    -> "T1" | "P" | ...|>
```
- `"BS"` (beamsplitter = Givens two-level rotation): `"Modes"->{i,j}`,
  `"Parameter"` = the rotation angle θ (KCBS: `Exact -> ArcCos[1/GoldenRatio]`).
- `"Phase"`: `"Modes"->{i}`, `"Parameter"` = phase φ.
- `"Source"`/`"Detector"` (L2 and endpoints): `"Parameter"` = intensity fraction or None.
- `"Prep"`: the `P` gate (L1 qutrit) or `X·H·CNOT` triple (biphoton encoding).
- `"Flag"`: singlet-leakage monitor (biphoton encoding), `"Parameter"->None`.

**ctxSchedule schema** (atom of `"IntensitySchedule"`): see 2.3.

**routing schema** (atom of `"Routing"`): see 2.2.

**Certification verdict semantics.** `"Verdict"->"genuine"` ⇒ this component needed a
real interferometer (`"Layer"->"L1"`, `DLADimension>=3`). `"Verdict"->"emulable"` ⇒ an
intensity redistribution suffices (`"Layer"->"L2"`, leaf-confined `DLADimension<3`, or
table-only). The tag is the framework's emulated/genuine boundary, per blueprint.

---

## 4. File layout and loadability

```
09-EMU-optical-compiler/
  DESIGN.md                     (this file)
  README.md                     (stub; has the standard "Relationship" section)
  OpticalCompiler.wl            (Builder C: BeginPackage, Gets the three layer files,
                                 defines EmitBlueprint/VerifyBlueprint/Dispatch +
                                 OpticalCompilerVerification; ends with "OK"->True)
  layer1_interferometer.wl      (Builder A: CompileInterferometer, GivensDecompose,
                                 StagesToUnitary, CompileMeshRouting)
  layer2_intensity.wl           (Builder B: CompileIntensityEmulator, IntensityTableKCBS)
  layer3_dispatch.wl            (Builder C: DispatchLayers, CVLeafConfinedQ)
  tests_optical_compiler.wl     (any builder: A1–A5, behind a runner)
```
Loadability discipline: each `.wl` is `Get`-loadable (definitions only). All demos and
the A1–A5 battery live behind `runners/RunOpticalCompiler.wl` (parametrized; the ONLY
files this module may add outside its folder are that runner and one registration line
in `runners/RunAll.ps1`). `OpticalCompiler.wl` context: `HubertKolcz\`OpticalCompiler\``;
it loads the `BlackBox` paclet via `PacletDirectoryLoad[".../BlackBox"]` +
`Needs["HubertKolcz\`BlackBox\`"]` (pattern copied from `BiphotonSimulator.wl` lines
13–14). The runner ends by printing `OpticalCompilerVerification` whose `"OK"` is True
(matches `RunBiphotonSimulator.wl` / RunAll's `"OK -> True"` grep).

---

## 5. WL optimization plan

1. **Native-first.** Givens elimination reuses `Dot`, `ArcTan`, `ArcCos`, `RootReduce`,
   `Orthogonalize` (the `P`-gate completion in `kcbs_circuit.wl` line 101–102 is copied
   verbatim). Mesh edge dedup uses `DeleteDuplicates[Sort/@…]` (hashing, near-linear).
   Do NOT hand-roll any invariant the `BlackBox` paclet already exposes
   (`DLADimension`, `CascadeGenerators`, `So3Axis`, `CycleCoboundary`, `CycleScenario`,
   `NoncontextualFraction`).
2. **Exact vs numeric boundary.** Algebraic inputs (KCBS geometry lives in `Q(√5)`)
   stay exact end-to-end: Givens angles are kept as `ArcCos[1/GoldenRatio]` and matrix
   entries `RootReduce`d, never `N`-collapsed on the exact path. `N[...]` is applied
   ONLY to populate the `"Numeric"` sibling field and for `Graphics`. A1/A2 comparisons
   run on the `"Exact"` field. Rule of thumb: any value that feeds a `==` anchor is
   exact; anything that feeds a plot or a tolerance-`<` check may be numeric.
3. **No Join-in-loop (the documented O(L²) pitfall).** `CompileMeshRouting` copies
   `wordRingEdgesFast` verbatim: all `5L` edges via a single `Table` of ragged blocks +
   one `Flatten[…,1]`. Block-stage and routing lists likewise built by `Table`, never
   grown with `AppendTo`/`Join` inside `Do`. Same for the Reck stage list (build via
   `Reap`/`Sow` or a `Table` over the elimination order, then one `Flatten`).
4. **Exact rational/algebraic LP.** `CompileIntensityEmulator`'s feasibility LP uses
   `LinearOptimization` with a FLAT variable list (the documented pitfall — never a
   matrix of variables), `Method->"RevisedSimplex"`, on exact rationals; `Q(√5)`
   entries handled per the project's RevisedSimplex precedent
   (`NoncontextualFraction` in the paclet is the template). No floats on the exact
   feasibility path.
5. **Reck exactness on `Q(√5)`.** Each Givens angle is
   `θ = ArcTan[a, b]` on the two eliminated entries; keep `Cos θ, Sin θ` as the
   `RootReduce`d radical (for KCBS they collapse to `1/φ` and `√(1/φ)`), and apply the
   rotation by exact `Dot`. Verify column-by-column that eliminated entries are
   `RootReduce`-zero, not `Chop`-zero. Memoize `KCBSDirections[]` and
   `CascadeGenerators[]` results (`once`-style, they are constant) so repeated
   blueprint emission does not recompute the geometry.
6. **SparseArray threshold.** Below ~50 modes keep dense matrices. For mesh
   mode-coupling matrices at scale (`CompileMeshRouting` at large `reps`), represent the
   adjacency/coupling as `SparseArray` and NEVER build a dense `n×n`; the routing list
   is the primary object and is already O(L). Threshold: switch to `SparseArray` when
   `ModeCount > 1000` (matches the mesh module's practice). `EmitBlueprint` on a mesh
   target returns the routing+edge list only — it does NOT synthesize a dense unitary
   for the whole mesh (that would be the exponential wall this module refuses to hit).
7. **Caching.** `DispatchLayers` memoizes DLA verdicts keyed by the exact generator
   set; `VerifyBlueprint` reuses the blueprint's stored `"Unitary"` when present rather
   than re-multiplying.

---

## 6. Validation plan — anchors A1–A5 (literal expected values)

Implemented in `tests_optical_compiler.wl`, invoked by the runner, ANDed into
`OpticalCompilerVerification["OK"]`.

**A1 — KCBS pentagon reproduces the Lapkiewicz cascade EXACTLY.**
`bp = EmitBlueprint[<|"Scenario"->"KCBS"|>]` (or `CompileInterferometer[<|"Scenario"->"KCBS"|>]`).
Expected, on the `"Exact"` fields:
- Every `"BS"` stage angle: `RootReduce[Cos[θ] - 1/GoldenRatio] == 0`, i.e.
  `Cos θ = (√5−1)/2`; `Sin θ = Root[#^4+#^2−1&,2,0] = √(1/φ)` — a RootReduced identity,
  not a numeric approx.
- Stage list `= [P, T1, T2, T1, T2]` (period-2): the compiled stages satisfy
  `T3==T1` and `T4==T2` exactly. `T1` touches modes `{1,3}` (fixes 2), `T2` touches
  `{2,3}` (fixes 1). Shared-detector alternation `{2,1,2,1}`.
- Compiled unitary reproduces `kcbs_circuit.wl`'s qutrit statistics: each context
  probability vector `= (1/√5, 1/√5, 1−2/√5)`; five Heisenberg expectations sum to
  `√5` (Lovász); `S = Σ corr = 5 − 4√5 ≈ −3.9443` exactly.
- `VerifyBlueprint[bp]["OK"] == True`, `MaxDeviation < 10^-12`.

**A2 — C7 target → n=7 cascade.**
`bp7 = CompileInterferometer[<|"Scenario"->"Cn","n"->7|>]`. Expected:
`S_qutrit = 7 − 4·θ(C7)` with `θ(C7) = 7 Cos[π/7]/(1+Cos[π/7])`;
`Abs[S_qutrit − (7 − 4 θ(C7))] < 10^-8` (matches `buildNCycleCircuit[7]["match"]`).
Two-level deviation and cyclic orthogonality `< 10^-8`. (Also run n=9 as a second
point, same identity.)

**A3 — intensity layer reproduces construction iii-d for KCBS.**
`sch = CompileIntensityEmulator[IntensityTableKCBS[1/Sqrt[5], 0], CycleScenario[5]]`.
Expected (cross-checked against the Python original's numbers):
- `"Feasible"->True`, `"SignalingResidual"->0` (δ=0 ⇒ no signaling).
- Per-context fractions `(f00,f01,f10) = (1−2/√5, 1/√5, 1/√5)`;
  `f00 = 0.1055728…`, `f01=f10 = 1/√5 = 0.4472135955…`.
- `NodeSum = √5 = 2.2360679…`; `ContextualFraction[CycleScenario[5], table] = 2√5−4 =
  0.4721359549995794` (the `CF_EXACT` anchor of `mbqc_blackbox_test.py`).
- Table-level indistinguishable from the quantum box (this IS Prop. 1 / iii-d),
  yet its Layer-3 verdict is `"emulable"` / leaf-confined (that is the point).

**A4 — mesh routing matches `wordRingEdgesFast` exactly.**
For `word="cct"`, `reps∈{1,2,3}`: `CompileMeshRouting["cct",reps]["EdgeList"]` equals
`wordRingEdgesFast["cct",reps]` as sorted sets (and equals `wordRingOriginal`'s edge
set — the regression already proven in `cct_mesh_sparse_construction.wl`).
`ModeCount = 3L`: reps 1→9, 2→18, 3→27 modes. Routing shared-mode map
`{3(k-1)+1,3(k-1)+2}`; orientation `"trans"` exactly at `t` letters (word `cct` ⇒
per period letters `c,c,t` ⇒ swap on every third block). Expected: `EXACT MATCH -> True`
for all three reps.

**A5 — self-certification of every emitted blueprint.**
For each of {A1 KCBS L1 blueprint, A3 KCBS L2 blueprint, A4 mesh blueprint}:
`VerifyBlueprint[bp]` re-simulates from the blueprint's own Givens list / intensity
schedule / edge list and must reproduce the target statistics with
`MaxDeviation < 10^-12` (`< 0.025` for any shot-sampled cross-check), AND
`DLAVerdictConsistent -> True`: the L1 KCBS blueprint audits to
`DLADimension==3, span==2` (genuine); the L2 KCBS blueprint audits leaf-confined
(`DLADimension<3`, `Verdict=="emulable"`). A blueprint whose stored layer contradicts
its own DLA audit fails A5.

`OpticalCompilerVerification["OK"] = And[A1all, A2all, A3all, A4all, A5all]` — must be
`True`.

---

## 7. Cross-cutting conventions (so builders agree)

- Modes are 1-indexed everywhere (matches `kcbs_circuit.wl` and `wordRingEdgesFast`).
- Section order per context is `(00,01,10,11)` with `(1,1)` structurally absent
  (matches `CycleScenario`, `mbqc_blackbox_test.py`). Click convention: detector click
  = value `−1`, so `corr = p11? no` → `corr = p_third − p_first − p_second`
  (the `(#[[3]]-#[[1]]-#[[2]])&` of `kcbs_circuit.wl`).
- `"Exact"`/`"Numeric"` twin fields are MANDATORY on every parameter; anchors read
  `"Exact"`.
- Attribution: any helper lifted from `00`–`08` is copied with a comment
  `(* extracted verbatim from <path> — <symbol>, per repo convention *)`.

## 8. Parallel build plan (three builders, no cross-talk)

Contracts that make this parallelizable: the **stage schema** and **Blueprint schema**
(Section 3), the **function signatures** (Section 2), and the **A1–A5 expected values**
(Section 6). Given those, the three files can be built independently:

- **Builder A — `layer1_interferometer.wl`**: `CompileInterferometer` (both forms),
  `GivensDecompose`, `StagesToUnitary`, `CompileMeshRouting`. Consumes: `KCBSDirections`,
  `kcbs_circuit.wl` cascade construction, `buildNCycleCircuit`, `wordRingEdgesFast`
  (copy). Produces: StageMesh + Mesh assocs. Owns anchors **A1, A2, A4**. Does not need
  L2 or L3.
- **Builder B — `layer2_intensity.wl`**: `CompileIntensityEmulator`,
  `IntensityTableKCBS`. Consumes: `CycleScenario`, `CycleCoboundary`,
  `ContextualFraction`, `NoncontextualFraction` (paclet); `table_intensity`/iii-d logic
  (port). Produces: Schedule assoc. Owns anchor **A3**. Does not need L1 or L3.
- **Builder C — `layer3_dispatch.wl` + `OpticalCompiler.wl`**: `DispatchLayers`,
  `CVLeafConfinedQ`, `EmitBlueprint`, `VerifyBlueprint`, `OpticalCompilerVerification`,
  the `BeginPackage` wrapper, and `runners/RunOpticalCompiler.wl` +
  the one `RunAll.ps1` line. Consumes: `CascadeGenerators`, `DLADimension`, `So3Axis`
  (paclet), `final_o3_cv_dla.py` (port, optional), and A/B's public signatures (against
  the schema, not their internals). Owns anchor **A5** and the integration.

Merge point: `OpticalCompiler.wl` `Get`s the three layer files. Because A and B never
import C and C imports A/B only through the fixed signatures, the three can be written,
tested (each against its own anchors), and reviewed independently, then integrated by C.
