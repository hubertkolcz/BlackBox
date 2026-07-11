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

- **`BlackBox/`** — Wolfram paclet `HubertKolcz/BlackBox` (v1.1.0, 22 exported
  symbols): Lovász ϑ by SDP (dense and sparse/chordal), independence and
  fractional packing numbers, exclusivity (CE) filters under OR-product
  composition, n-cycle scenarios, contextual fraction, Abramsky–Brandenburger
  local–global analysis, the Čech obstruction of the support presheaf, and the
  so(3) interface of the KCBS cascade. Includes `Tests/BlackBoxTests.wl` and
  Documentation pages. Submission notes: `BlackBox/CONTRIBUTING.md`.
- **Essays and notes** (`*.wl` at the root) — package-format computational
  essays; evaluate cell by cell in a notebook, or run headlessly (below).
- **Python tools** — `lovasz_theta_sparse.py` (sparse ϑ at 10⁴–10⁶ vertices,
  Clarabel), `beyond7_clique_search.py` / `beyond7_theorem_sweep.py` (exact
  clique decisions for catalysed n-cycle boxes), `kcbs_simulation.py`
  (Monte Carlo of the 2011 experiment).

## Headless verification

Each major module has a `Run<Name>.wl` runner:

```
wolframscript -file RunEssay.wl -print all        # CertifyingQuantumness.wl
wolframscript -file RunCaseStudies.wl -print all
wolframscript -file RunHeptagonCatalysis.wl -print all
wolframscript -file RunBiphotonSimulator.wl -print all
wolframscript -file RunSupportCohomology.wl -print all
wolframscript -file RunWignerFlow.wl -print all   # kcbs_wigner_flow.wl
wolframscript -file RunLedger.wl -print all       # kcbs_ledger.wl
wolframscript -file BlackBox/Tests/BlackBoxTests.wl
```

Every run must end `OK -> True` (the test battery prints `ALL PASS`). The
runners exist because `wolframscript -file` on an essay parses the whole file
before evaluating, which shadows the quantum-framework symbols in `` Global` ``
(documented in `kcbs_circuit.wl`, Section 1); `Get[]` inside a runner evaluates
expression by expression and avoids this.

`kcbs_circuit.wl` (the 13-section KCBS circuit essay) and `kcbs_simulation.wl`
are notebook-first: evaluate cell by cell from a fresh kernel.

## Requirements

- Wolfram Language 13.0+ with `wolframscript`; the essays install the
  [Wolfram/QuantumFramework](https://resources.wolframcloud.com/PacletRepository/resources/Wolfram/QuantumFramework/)
  paclet on first run.
- Python 3.10+ with `numpy`, `python-igraph`, `clarabel`, `scipy` for the
  Python tools (optional; every Python result has a WL counterpart or anchor).

## License

MIT — see [LICENSE](LICENSE).
