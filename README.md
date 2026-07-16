# black-box — Evaluating black-box physics through optical emulation

Research code for the *Quantum Contextuality* project. **Research question:** given only black-box access to a device, under what conditions is it mathematically impossible to distinguish a genuinely quantum device from a classical optical emulation at the level of input–output behavior? The framework combines two independent certificates a classical emulation would have to defeat simultaneously — a **correlation certificate** (Cabello's Global Exclusivity / graph invariants / contextual fraction, built on the KCBS pentagon) and a **resource-scaling certificate** (the Lie-Poisson / dynamical-Lie-algebra reading of the same geometry) — and is illustrated on the classical emulatability of analogue-Hawking-radiation dynamics. Full objectives, verbatim description, and the objective→module→claim map: [`RESEARCH.md`](RESEARCH.md).

Everything is written as *computational essays* (Wolfram Language, plus Python counterparts) whose claims are machine-checked: each module ends in a `<Name>Verification` association whose `"OK"` key must evaluate to `True`.

Key documents:

- [`RESEARCH.md`](RESEARCH.md) — objectives (verbatim), deliverable map, status, reporting rules.
- [`docs/QUANTUM_CONTEXTUALITY.md`](docs/QUANTUM_CONTEXTUALITY.md) — the narrative log: verified facts, key numbers, artifact index, open threads.
- [`docs/REVIEW-2026-07-13.md`](docs/REVIEW-2026-07-13.md) — full research review vs. objectives, module assessments, prioritized actions.
- [`docs/RELATED-WORK.md`](docs/RELATED-WORK.md) — curated literature positioning (2026-07-13 pass).
- [`docs/ledger-snapshot/`](docs/ledger-snapshot/) — dated mirror of the claims ledger (canonical: the Quantum Contextuality project's `01-claims-ledger/ledger.json`, which indexes this repository file by file).
- [`docs/MAINTENANCE.md`](docs/MAINTENANCE.md) — git recovery, commit plan, release checklist.

## Layout

The repository is organized by **role in the research**, not by method or chronology — module names describe what a module is *for*, not the mathematical technique it happens to use internally (that detail lives in each module's own README). `certification-protocol/` is the primary module: the project's central question, operationalized. Dependency direction is inward-only toward it — peripheral modules feed the certification protocol, not the reverse.

| Module | Role | Ledger track |
|---|---|---|
| [`certification-protocol/`](certification-protocol/) | **Primary.** Pre-registered black-box certification protocol (statistics + the DLA hook); its one pre-declared blind spot is the project's central impossibility condition. | `BBT` |
| [`pentagon-foundations/`](pentagon-foundations/) | Shared KCBS-pentagon bedrock: graph invariants, circuits, GE at 2 copies, contextual fraction ↔ signed negativity. | `D2` |
| [`open-search-frontier/`](open-search-frontier/) | Numerics-only frontier: does GE-with-copies single out ϑ(G) for every graph? Heptagon catalysis; open nonagon cell. | `D1` |
| [`pentagon-gluing/`](pentagon-gluing/) | Pentagon gluing: direct/twisted laws, τ\* density, (ddt)^∞ optimal word, realizability. | `MESH` |
| [`cluster-state-realization/`](cluster-state-realization/) | Emerging: literal MBQC cluster-state realization of the winning gluing word at scale. | `MESH`/`LP` |
| [`composition-optimality/`](composition-optimality/) | ε-certificates (Γ_k) for the gluing-word gap density; ergodic-optimization family. | `CERT` |
| [`bound-derivation-question/`](bound-derivation-question/) | Abramsky–Brandenburger backbone: Laplacian rejection, Čech obstruction, torsion census; home of the priority open question (`ESSAY-005`). | `D3` |
| [`signaling-extension/`](signaling-extension/) | Signaling / communication-cost extension of the taxonomy. | `SIG` |
| [`hawking-application/`](hawking-application/) | Hawking application — structural negative result (single-context witness ⇒ CF ≡ 0); Gaussian/Bogoliubov thermal sector filled (analogue-Hawking dynamics as a CV state, A1–A8). | `HK` |
| [`optical-synthesis/`](optical-synthesis/) | Constructive mirror of `certification-protocol`: runs the two-lens certification mathematics in the *synthesis* direction — from a target it emits a three-layer optical blueprint (Givens/beamsplitter mesh, intensity schedule, stage/routing list), each stamped emulable-vs-genuine. | `EMU` |
| [`BlackBox/`](BlackBox/) | Wolfram paclet `HubertKolcz/BlackBox` (version and export count: see [`BlackBox/PacletInfo.wl`](BlackBox/PacletInfo.wl), the single authority): Lovász ϑ (dense + sparse/chordal), CE filters, contextual fraction, AB local–global analysis, Čech (co)homology with exact torsion orders, AvN over Z_d, signed negativity, the so(3)/DLA interface. Tests: `BlackBox/Tests/BlackBoxTests.wl`. | — |
| [`runners/`](runners/) | Headless `Run<Name>.wl` entry points + one-command sweeps (`RunAll.ps1`, `RunAll.sh`). | — |

Each module README states its contents, its relationship to the primary module, and its ledger claim IDs.

### Reading order

The modules follow the arc told in [`EvaluatingBlackBoxPhysics-Illustrated.nb`](EvaluatingBlackBoxPhysics-Illustrated.nb) — the sealed-box question, through certification, construction, composition, physical realization, and the two open extensions:

1. **[`pentagon-foundations/`](pentagon-foundations/)** — start here: the shared KCBS-pentagon bedrock (graph invariants, contextual fraction) every other module builds on.
2. **[`certification-protocol/`](certification-protocol/)** — the primary module: the black-box certification protocol and its one pre-declared blind spot, the project's central impossibility result.
3. **[`optical-synthesis/`](optical-synthesis/)** — the constructive mirror: builds the devices the protocol certifies.
4. **[`pentagon-gluing/`](pentagon-gluing/)** — how certified pentagons compose (direct/twisted laws, the winning gluing word).
5. **[`composition-optimality/`](composition-optimality/)** — the ergodic-optimization proof that the winning gluing word is optimal.
6. **[`cluster-state-realization/`](cluster-state-realization/)** — the physical (MBQC cluster-state) realization of that composition at scale.
7. **[`open-search-frontier/`](open-search-frontier/)** — the open numerical frontier the composition work still leaves (GE-with-copies, heptagon catalysis, the ω=17 clique search).
8. **[`bound-derivation-question/`](bound-derivation-question/)** — the project's stated #1 open priority: can the sheaf-theoretic machinery *derive* the bound rather than merely house it?
9. **[`signaling-extension/`](signaling-extension/)** and **[`hawking-application/`](hawking-application/)** — two independent extensions: a signaling/communication-cost taxonomy, and the analogue-Hawking-radiation illustration.
10. **[`figure-gallery/`](figure-gallery/)** — presentation layer: rendered figures referenced throughout the essay and module READMEs.

`BlackBox/` is the shared Wolfram paclet every module loads via `PacletDirectoryLoad`; it has no position in the reading order since every module depends on it directly.

## Headless verification

```
wolframscript -file RunBlackboxProtocol.wl -print all   # primary: mbqc_c5.wl (prints a validation report)
wolframscript -file RunEssay.wl -print all              # CertifyingQuantumness.wl
wolframscript -file RunCaseStudies.wl -print all
wolframscript -file RunHeptagonCatalysis.wl -print all
wolframscript -file RunBiphotonSimulator.wl -print all
wolframscript -file RunSupportCohomology.wl -print all
wolframscript -file RunWignerFlow.wl -print all
wolframscript -file RunLedger.wl -print all
wolframscript -file RunEpilogue.wl -print all
wolframscript -file RunSignedNegativity.wl -print all
wolframscript -file RunD1GECopiesSweep.wl -print all
wolframscript -file RunD1K3Activation.wl -print all
wolframscript -file RunSignalingTaxonomy.wl -print all
wolframscript -file ../BlackBox/Tests/BlackBoxTests.wl
```

One command for everything: `powershell -File runners/RunAll.ps1` (Windows) or `bash runners/RunAll.sh` (POSIX). Every run must end `OK -> True` (the test battery prints `ALL PASS`), except `RunBlackboxProtocol.wl`, which prints a validation report — read its Summary line.

Why runners exist: `wolframscript -file` on an essay parses the whole file before evaluating, which shadows the quantum-framework symbols in `` Global` `` (documented in `pentagon-foundations/kcbs_circuit.wl`, Section 1); `Get[]` inside a runner evaluates expression by expression and avoids this.

Notebook-first files (evaluate cell by cell from a fresh kernel): `kcbs_circuit.wl`, `kcbs_simulation.wl`. Python protocol: `python3 certification-protocol/mbqc_blackbox_test.py`.

## Requirements

- Wolfram Language 13.0+ with `wolframscript`; essays install [Wolfram/QuantumFramework](https://resources.wolframcloud.com/PacletRepository/resources/Wolfram/QuantumFramework/) on first run.
- Python 3.10+ with the packages in [`requirements.txt`](requirements.txt) (optional; every Python result has a WL counterpart or anchor).

## Citing

See [`CITATION.cff`](CITATION.cff). Foundations this project builds on are listed in `RESEARCH.md`; the full positioning bibliography is `docs/RELATED-WORK.md`.

## License

MIT — see [LICENSE](LICENSE).
