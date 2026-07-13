# black-box — machine-verified quantum contextuality

Research code for the KCBS (Klyachko–Can–Binicioğlu–Shumovsky) pentagon and its
generalizations: circuit models of the Lapkiewicz et al. experiment (Nature 474,
490), graph- and sheaf-theoretic certificates, phase-space (Wigner-negativity)
analysis, and composition/activation results for n-cycle boxes. Everything is
written in Wolfram Language as *computational essays* whose claims are
machine-checked: each module ends in a `<Name>Verification` association whose
`"OK"` key must evaluate to `True`.

The project context document — verified facts, key numbers, artifact index, and
open threads — is [QUANTUM_CONTEXTUALITY.md](QUANTUM_CONTEXTUALITY.md).

## Layout

The repository is organized by **goal**, not just topic, so the module answering
the project's central question stays distinct from the modules that merely
contribute to it. Folders are numbered `00`-`08`; the number is a reading order,
not an importance ranking beyond `00` itself, which is the primary module.

- **`00-BBT-blackbox-protocol/`** — **the primary module.** The black-box
  certification protocol itself (`mbqc_blackbox_test.py`, `mbqc_c5.wl`) — this
  directly operationalizes the project's central question. Read this folder's
  own README first.
- **`01-D2-core-computation/`** — shared KCBS-pentagon computational bedrock
  (graph invariants, circuits, GE, contextual fraction) that the primary module
  and several other tracks import from.
- **`BlackBox/`** — Wolfram paclet `HubertKolcz/BlackBox` (v1.1.0, 29 exported
  symbols as of this reorg): Lovász ϑ by SDP (dense and sparse/chordal),
  independence and fractional packing numbers, exclusivity (CE) filters under
  OR-product composition, n-cycle scenarios, contextual fraction,
  Abramsky–Brandenburger local–global analysis, the Čech obstruction of the
  support presheaf, and the so(3)/DLA interface of the KCBS cascade. Includes
  `Tests/BlackBoxTests.wl` and Documentation pages. Submission notes:
  `BlackBox/CONTRIBUTING.md`.
- **`02-D1-theory-frontier/`**, **`03-MESH-pentagon-composition/`**,
  **`05-CERT-epsilon-certificates/`**, **`06-D3-sheaf-cohomology/`**,
  **`07-SIG-signaling/`**, **`08-HK-hawking/`** — independent contributing
  tracks (theory-frontier numerics, pentagon-gluing composition, epsilon
  certificates, sheaf cohomology, signaling extension, and the Hawking-radiation
  application respectively). Each has its own README stating what it contains
  and its relationship to the primary module. None of these is imported by
  `00-BBT-blackbox-protocol/` directly — they inform the project's broader
  arguments without entering the certification protocol's own dependency chain.
- **`04-cluster-state-mbqc/`** — emerging module building a literal MBQC
  cluster-state realization of the pentagon-mesh gluing result; feeds the
  primary module's long-term goal but is not yet wired into it. See its README
  for the honest scaling boundary between its stabilizer, AvN-witness, and DLA
  checks.
- **`runners/`** — headless `Run<Name>.wl` entry points (below) plus
  `RunAll.ps1`, the one-command verification sweep.

Fu