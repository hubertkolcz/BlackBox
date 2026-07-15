# 09-EMU-optical-compiler

An optical compiler that runs the `00-BBT` certification mathematics *in the synthesis
direction*: given a target (a unitary, a no-disturbance table, or a pentagon-mesh word),
it emits an optical **blueprint** — a Givens/beamsplitter mesh (Layer 1), an
intensity-redistribution schedule (Layer 2), or a stage/routing list (mesh) — each
stamped with the per-component certification verdict (emulable vs genuine) that says
which layer it required and why.

## What it is

The **constructive mirror of `00-BBT-blackbox-protocol`**. `00-BBT` runs the two-lens
theorem in the *analysis* direction — from a table (plus a claimed compilation) it
*certifies* quantum vs classically-optically-emulable. `09-EMU` runs the *same
mathematics in the synthesis direction* — from a target it *builds* the optical blueprint
and attaches the certification verdict.

## The three layers

| Layer | File | Role |
|-------|------|------|
| **L1 Interferometer** | `InterferometerLayer.wl` | The Givens/beamsplitter cascade of an indivisible qutrit (Lapkiewicz) and the pentagon-mesh routing. Exact Reck/Clements decomposition, `KCBSCascadeStages`, biphoton (spin-1) encoding. |
| **L2 Intensity** | `IntensityLayer.wl` | The divided classical beam that reproduces any no-disturbance table (construction iii-d), certified over the no-disturbance polytope by an exact `RevisedSimplex` LP. |
| **L3 Dispatcher** | `DispatcherEmitter.wl` | The two-lens dispatcher (so(3) DLA via the paclet; CV Sp(2n,R) port), the blueprint emitter, the schematic renderer and the A5 self-certification loop, with self-contained L1/L2/mesh compilers it orchestrates. |

## Master module

`OpticalCompiler.wl` (context `HubertKolcz`OpticalCompiler``) is the single Get-loadable
entry point. It Get-loads the three layers and exposes one unified public API, ending in
the `OpticalCompilerVerification` association whose `"OK"` key gates on **all five anchors
A1–A5** (must evaluate `True`).

```
CompileInterferometer  GivensDecompose  StagesToUnitary  CompileMeshRouting
CompileIntensityEmulator  IntensityTableKCBS  DispatchLayers  CVLeafConfinedQ
EmitBlueprint  VerifyBlueprint  OpticalCompilerSchematic
OpticalCompilerExportSchematics  OpticalCompilerVerification  KCBSCascadeStages
```

**Authority / reconciliation.** `DispatcherEmitter.wl` is self-contained: it carries its
own *simplified* copies of the shared pipeline symbols. The standalone L1/L2 files carry
the richer, independently verified implementations of the same symbols (exact
Reck/Clements with round-trip `< 10^-12`, biphoton, n-cycle table, LP-with-slack); the
dispatcher's simplified `GivensDecompose` does **not** round-trip. To keep the integrated
pipeline deterministic **and correct**, the master hands **sole authority for the six
shared symbols to the layer builders** (load `DispatcherEmitter` first for dispatch /
emission / verification, clear the six shared symbols, then load L1+L2 last as the single
authorities; the dispatcher's orchestration resolves them at call time). The per-layer
**extended** batteries additionally run **standalone** via their own runners:
`tests_interferometer_layer.wl` (Builder A: A1/A2/A4 + Reck/Clements round-trip) and
`runners/RunIntensityLayer.wl` (Builder B: 27-check A3 + generalized-construction
battery). The integrated gate here is `OpticalCompilerVerification` (A1–A5).

Reused verbatim with attribution: the `BlackBox` paclet (`CascadeGenerators`, `So3Axis`,
`DLADimension`, `CycleScenario`, `CycleCoboundary`, `ContextualFraction`,
`KCBSDirections`); the KCBS/n-cycle cascade geometry of
`01-D2-core-computation/kcbs_circuit.wl` and `kcbs_circuit_ncycle.wl`; the biphoton lift
of `BiphotonSimulator.wl`; `wordRingEdgesFast` from
`04-cluster-state-mbqc/cct_mesh_sparse_construction.wl`; and the Sp(2n,R)
leaf-confinement audit ported from `00-BBT-blackbox-protocol/final_o3_cv_dla.py`.

## Honest scope

The compiler emits emulators of **block-local** statistics (per-block tables,
block-local AvN witnesses) — exactly what Prop. 1 / the certification map says classical
optics CAN do. It does **not** construct globally-entangled cluster states: single-photon
linear optics cannot, absent exponential mode count or KLM nonlinearity. A Layer-2
blueprint is the constructive form of `00-BBT`'s adversarial case (iii-d) — a divided
classical beam reproducing a quantum table exactly — flagged leaf-confined
(`DLADimension < 3`) by its own DLA audit. The emulated/genuine boundary carried in every
blueprint is the framework's two-lens theorem applied constructively.

## Demo gallery

Four self-certified demo blueprints (`blueprints/*.wl` data + `schematics/*.png`), each
re-simulated from its own data by `VerifyBlueprint` (`OK -> True`) before it is written:

| Demo | Target | Layer | What it shows |
|------|--------|-------|---------------|
| `demo1_kcbs_pentagon_L1` | `<\|"Scenario"->"KCBS"\|>` | L1 | Lapkiewicz reconstruction: cascade `[P,T1,T2,T1,T2]`, exact `cos θ = 1/GoldenRatio`, genuine (so(3) DLA = 3). |
| `demo2_c7_heptagon_L1` | `<\|"Scenario"->"Cn","n"->7\|>` | L1 | C7 heptagon cascade: six Givens stages, numeric identity `S = 7 − 4·θ(C7)`. |
| `demo3_cct_mesh_reps2` | `<\|"Word"->"cct","Reps"->2\|>` | Mesh | cct pentagon-mesh chain reps=2: block-local, shared-mode routing (cis/trans), per-block verdicts (emulable). |
| `demo4_table_V0977_L2` | table at `V = 977/1000` | L2 | Pure no-disturbance table, **Layer-2 only** (leaf-confined): the divided-beam intensity schedule reproducing it exactly. |

## Relationship to the primary module

`00-BBT` *certifies*; `09-EMU` *builds*. Layer-2 blueprints are the constructive form of
`00-BBT`'s adversarial case (iii-d): a divided classical beam reproducing a quantum table
exactly, flagged leaf-confined by its own DLA audit. The Givens-cascade and mesh layers
reuse `01-D2-core-computation` (`kcbs_circuit.wl`, `kcbs_circuit_ncycle.wl`,
`BiphotonSimulator.wl`) and `04-cluster-state-mbqc` (`wordRingEdgesFast`); the dispatcher
reuses the `BlackBox` paclet (`CascadeGenerators` / `So3Axis` / `DLADimension`) and the
CV `Sp(2n,R)` port of `00-BBT/final_o3_cv_dla.py`.

## Regeneration commands

```
# integrated gate (A1–A5) + four demo blueprints + schematics
wolframscript -file runners/RunOpticalCompiler.wl -print all      # OK -> True

# standalone per-layer extended gates
wolframscript -file 09-EMU-optical-compiler/tests_interferometer_layer.wl   # Layer 1 (A/A1,A2,A4)
wolframscript -file runners/RunIntensityLayer.wl -print all                 # Layer 2 (B/A3, 27 checks)

# whole-repo battery (registers RunOpticalCompiler.wl)
powershell -File runners/RunAll.ps1
```

See `DESIGN.md` for the full architecture: API signatures, the blueprint Association
schema, the WL-optimization plan, and the A1–A5 validation anchors with literal expected
values.

## Ledger cross-reference

`BBT-002`, `BBT-003`, `MESH-004`, `MESH-008`. External anchor: Frustaglia et al.,
PRL **116**, 250404 (2016); Lapkiewicz et al., Nature **474**, 490 (2011); Reck et al.,
PRL **73**, 58 (1994); Clements et al., Optica **3**, 1460 (2016).
