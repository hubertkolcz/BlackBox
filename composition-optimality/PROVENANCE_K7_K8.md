# Provenance note: regeneration test of the k=7 / k=8 exact epsilon-certificates

**Date:** 2026-07-13
**Ledger items addressed:** CERT-001 / ISSUE-001 (high severity): no generator script
survives for the committed exact certificates `EpsilonCertificate.wl` (k=7,
Gamma_7 = 1541247/20000000) and `EpsilonCertificate8.wl` (k=8, Gamma_8 = 941357/12500000).
Both were committed as complete, already-solved data files with no construction code
anywhere in the repo or its git history.

**Method:** the repaired, K-parameterized reconstruction
`GenerateEpsilonCertificate9.wl` (the same pipeline that produced the accepted,
fully-cross-checked k=9 certificate, CERT-002) was copied verbatim with only K and the
output filename changed:

- `GenerateEpsilonCertificate_testK7.wl`  (K = 7 -> `EpsilonCertificate_testK7_output.wl`)
- `GenerateEpsilonCertificate_testK8.wl`  (K = 8 -> `EpsilonCertificate_testK8_output.wl`)

Command lines (run from `05-CERT-epsilon-certificates/`):

```
wolframscript -file GenerateEpsilonCertificate_testK7.wl        # full run, ~14.5 min wall
timeout -k 30 600 wolframscript -file GenerateEpsilonCertificate_testK8.wl   # 10-min capped run (see K=8 below)
```

Comparison of "Gamma" fields was done as exact rationals (Python `fractions`).

---

## k = 7 -- COMPLETE regeneration; Gamma does NOT match exactly (regenerated is tighter)

Full pipeline ran to completion and **exported** `EpsilonCertificate_testK7_output.wl`,
i.e. every built-in exact gate passed:

```
nodeEqOK = True, edgeEqOK = True, psdOK = True          (exact rational PSD + equalities)
pointwise sigma(e) <= Gamma for all 256 edges: True
GammaExact vs Stage-1 SDP-Gamma drift = 1.15e-8: True
finalConverged = True
```

Cross-seed agreement: both trusted deterministic seeds (A and B) independently converged
to the SAME numeric SDP optimum 0.07702055862175518 (A in 2 rounds, B in 3); the two
random restarts converged to the known spurious fixed points (~0.50, ~0.394) and were
excluded by the script's converged-best selection, exactly as at k=9.

| quantity | value |
|---|---|
| committed `EpsilonCertificate.wl` Gamma_7 | 1541247/20000000 = 0.07706235 exactly |
| regenerated Gamma_7 (exact) | 763801638996471561227260969/9916852456914441403888390140 = 0.0770205710244... |
| exact rational equality | **NO** |
| difference (committed - regenerated) | 414315936629042293677512905229/9916852456914441403888390140000000 = +4.1779e-5 |
| tighter bound | **regenerated** (smaller Gamma) |

**Interpretation (the flagged "Gamma differs" finding, characterized):**

- Neither file is *wrong as a certificate*. Both are valid upper bounds: the committed
  file was already verified exactly (CERT-001 "verified"), and the regenerated file
  passes the identical exact verification (pointwise sigma <= Gamma on all edges + exact
  PSD blocks) built into the generator, which refuses to export otherwise.
- The committed Gamma_7 = 0.07706235 is, however, **not the transfer-SDP optimum**: the
  SDP optimum at k=7 is ~0.0770205586 (two independent seeds agree to 15 digits), so the
  committed certificate is ~4.18e-5 (0.054% relative) **looser** than what the
  construction can achieve. The committed file's entries all have denominators dividing
  10^8 (decimal-grid rounding), consistent with a lost generator that rounded more
  coarsely and/or stopped at a slightly suboptimal solution; the reconstruction
  rationalizes at tol 1e-9 and lands essentially on the SDP optimum.
- Consequence for the ledger: CERT-001's *claim* (gap-density <= Gamma_7 = 0.07706235)
  remains true and exactly verified; the regeneration additionally shows the same
  construction supports the strictly tighter Gamma_7' ~ 0.07702057
  (`EpsilonCertificate_testK7_output.wl`, fully exact and self-verified). Block-level
  Q/R data differs, as expected and permitted for provenance purposes.
- Provenance status: the reconstructed pipeline demonstrably reproduces the k=7
  certificate *construction* (same shape, same verification, Gamma agreeing to ~3.5
  significant decimals and differing only in the tightness direction), but it is NOT
  bit-for-bit the lost generator -- the committed file's exact Gamma value was not
  reproduced, and cannot be reproduced by this pipeline since the pipeline converges to
  the tighter SDP optimum.

## k = 8 -- PARTIAL (10-minute compute cap): numeric Stage-1 checkpoint only, same pattern as k=7

Local compute policy for this session capped the k=8 run at 10 minutes
(`timeout -k 30 600 ...`, exit 124 = killed at cap). Checkpoint obtained before the cap:

```
seed A (sig=s):
  round 1: Gamma = 0.5000039983673249
  round 2: Gamma = 0.07526641357042801
  converged at round 2
seed B: started, killed by the cap before round 1 completed
```

| quantity | value |
|---|---|
| committed `EpsilonCertificate8.wl` Gamma_8 | 941357/12500000 = 0.07530856 exactly |
| regenerated Gamma_8 (numeric SDP optimum, seed A, converged) | 0.07526641357042801 |
| difference (committed - regenerated numeric) | +4.2146e-5 |
| tighter bound | **regenerated** (numerically; no exact-rational stage was reached) |

The k=8 checkpoint reproduces the k=7 finding quantitatively: the committed Gamma_8 is
~4.21e-5 looser than the SDP optimum found by the reconstruction (compare +4.18e-5 at
k=7) -- a consistent signature of the lost generator's coarser rounding/earlier stop.

**Measured extrapolation for a full k=8 run** (from this checkpoint + the k=7 run +
`opt/profile_K{4,5,6}.log` scaling of ~3.8x per +1 in K):

- per strategy-iteration round at K=8: ~4.5 min (seed A: 2 rounds in <10 min, measured);
- expected round count if seeds behave as at k=7/k=9 (A:2, B:3, random:4-17): ~26 rounds
  -> Stage 1 ~ 1.5-2 h;
- Stage 2 exact projection (6400 vars, 3328 equalities; ~60 s at k=7, x4-10) + Stage 3
  exact checks + export: ~10-20 min;
- **total: roughly 2-2.5 h single local run.** No cloud submission was made (forbidden
  this session); rerunning `GenerateEpsilonCertificate_testK8.wl` locally without the
  600 s cap is all that is needed to complete the exact k=8 leg.

## Verification note

The regenerated k=7 certificate's own verification is the generator's built-in Stage 3
(exact rational: node/edge equalities, PSD of all 128 Q (5x5) + 128 R (4x4) blocks,
pointwise sigma(e) <= Gamma on all 256 edges against Stage 1's independently reported
SDP Gamma) -- the same k-agnostic logic `CaseStudies.wl` uses to verify the committed
k=7/k=8 files. Export is hard-gated on all checks passing, so the existence of
`EpsilonCertificate_testK7_output.wl` certifies they all passed (see
`testK7` run log lines quoted above).

## Files

- `GenerateEpsilonCertificate_testK7.wl`, `GenerateEpsilonCertificate_testK8.wl` -- the
  two test drivers (3-line diff each from `GenerateEpsilonCertificate9.wl`: K, export
  filename, final Print).
- `EpsilonCertificate_testK7_output.wl` -- regenerated, fully verified exact k=7
  certificate (Gamma_7' = 763801638996471561227260969/9916852456914441403888390140).
- k=8: no output file (run capped before Stage 2); Stage-1 checkpoint recorded above.
