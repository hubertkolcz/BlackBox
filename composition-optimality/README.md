# 05-CERT-epsilon-certificates

Ledger track `CERT` — "epsilon-certificate / ergodic-optimization family": a separate, harder research thread from the primary module. For every possible pentagon-gluing word, is there one universal bound on the per-block quantum-classical gap density? Modeled as a mean-payoff/ergodic-optimization problem over a de Bruijn graph of window size $k$, with certificates $\Gamma_k$ that upper-bound the true supremum.

## Contents

`EpsilonCertificate.wl` (k=7), `EpsilonCertificate8.wl` (k=8), `EpsilonCertificate9.wl` + `GenerateEpsilonCertificate9.wl`/`_cloud.wl` (k=9, completed 2026-07-12, `CERT-002`) — exact rational certificates (`CERT-001`, `CERT-002`). `GenerateEpsilonCertificate10_cloud.wl` — **prepared, not completed.** Its naming bug (`ISSUE-020`: export targets still said `EpsilonCertificate9`, which would have silently overwritten the real k=9 file on a local run) was **fixed 2026-07-13** — all Stage-4 targets now say 10; mark `ISSUE-020` resolved in the ledger when this file is committed. `GenerateEpsilonCertificate_testK{3,4,5}.wl` + outputs — smaller validation runs. `glv_calibration_build.wl`/`glv_calibration_sdp.wl` + logs — calibration artifacts. `CertificateLoader.py` — shared certificate-loading utility. `extract_pdf.wl` — a one-off PDF-text extraction helper with a hardcoded absolute path to a since-expired session temp file; not portable, kept as a historical artifact only.

`debug/` — SDP-solver debugging scripts specific to this certificate family (policy iteration, PSD checks, decoupling, multi-seed sweeps, and the two `ZeroSlackDiagnostic*` cross-checks). Not a general-purpose debug folder; everything here is CERT-specific.

## Relationship to the primary module

No generator script for the k=7/k=8 files survives anywhere in git history (`ISSUE-001`) — a reconstructed pipeline exists and is validated at small k but is explicitly a skeleton. This track is independent of `00-BBT-blackbox-protocol/`; neither depends on the other.

## Ledger cross-reference

`CERT-001`, `CERT-002`, `ISSUE-001`, `ISSUE-020` (track `CERT`).
