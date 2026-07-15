# PROPOSED ledger amendments — 2026-07-13

**Status: PROPOSED, not applied.** The claims ledger
(`C:/Users/cp/Documents/Claude/Projects/Quantum Contextuality/01-claims-ledger/` —
`ledger.json`, `LEDGER.md`, `KNOWN_ISSUES.md`) is read-only to automation; the user
applies these amendments by hand. Each entry below was produced by a dedicated
verification session on 2026-07-13 and then independently re-checked by a reviewer
session the same day (re-run of the primary artifact; see the "Reviewer re-verification"
line in each entry).

Covers five ledger items: **MESH-006** (Quad-C5 isomorphism), **ISSUE-011**
(fem_study results snapshot), **CERT-001 / ISSUE-001** (k=7/k=8 certificate
provenance), **GE-003 / ISSUE-010** (D1 k=3 brackets, Paley-13), and **BBT-005**
(H4' reduction: G9 antibunching gate + KCBS eta* = 2/sqrt5 boundary).

---

## 1. MESH-006 — Quad-C5 reconstruction vs the published graph

**Proposed amendment (status: OPEN → VERIFIED-CONFIRMED, 2026-07-13).**
Isomorphism to the actual published graph is now CONFIRMED: arXiv:2605.12828
(Tamer, Mustecaplioglu, Dizdar, Gedik, "The Quad-C5 Graph: Maximum Contextuality
Gap on Eight Vertices") Eq. (10) edge set
`E = {(0,3),(0,5),(1,4),(1,6),(2,5),(2,6),(2,7),(3,6),(3,7),(4,7)}` was fetched and
machine-checked against the project's reconstruction (`fem_study_results.json`
`quad_edges`) in `pentagon-gluing/quad_c5_verification.wl`:
`IsomorphicGraphQ` True with explicit map `{0->2, 1->6, 2->3, 3->0, 4->5, 5->7, 6->1, 7->4}`;
alpha = 3 for both; theta ≈ 3.4678438 (paclet primal SDP and an independent
dual-formulation SDP) inside the paper's Table-5 bracket [3.46784373, 3.46784378]
(at 1e-6 tolerance); gap Delta = 0.46784 matches the paper's printed value to all 5
printed dp and exceeds the paper's Wagner benchmark 0.41421; the paper's Table-6
four-pentagon two-fold edge cover verified, and the four pentagons are the ONLY
5-cycles of the graph (census: 4 in both). Class: `B (search exact) / UNCLEAR` →
**B throughout** (isomorphism now machine-verified). The "reconstruction, marked as
such" caveat in `fem_study.py` and the MESH-004 contrast note (Quad-C5 needs d=4;
eta_3 = 1+sqrt(5) < theta confirmed numerically) can be retained as history, but the
unconfirmed-isomorphism flag is discharged.

**Evidence.** `wolframscript -file quad_c5_verification.wl` exits 0 with all 15 checks
PASS, including `PASS ISOMORPHIC: project reconstruction == published Quad-C5 (Eq. 10)
| <|0 -> 2, 1 -> 6, 2 -> 3, 3 -> 0, 4 -> 5, 5 -> 7, 6 -> 1, 7 -> 4|>`; paclet theta
{3.467843790292604, 3.4678437915252482}, independent dual SDP 3.4678437293546245,
gap 0.46784379152524824; four Table-6 vertex sets each induce a C5 and cover each of
the 10 edges exactly twice; both graphs contain exactly four 5-cycles;
1+sqrt(5) = 3.23606797749979 < theta. Companion Python cross-check
(`quad_c5_crosscheck.py`: networkx VF2 + brute-force alpha + cvxpy CLARABEL/SCS)
agrees. Paper data extracted via two independent WebFetch prompts of the ar5iv HTML
(agreed verbatim); PDF not downloaded.

**Reviewer re-verification (2026-07-13).** `quad_c5_verification.wl` re-run by the
reviewer: exit 0, ALL 15 PASS, identical isomorphism map and theta/gap digits.
(First attempt failed with a Wolfram license/kernel-contention error while a
concurrent workflow held a kernel; immediate retry ran clean — noted in case the
script is re-run while other kernels are active.) Known residual: the three SDP
values spread ~6e-8, wider than the paper's own 5e-8 Table-5 bracket, so the script
certifies bracket membership at 1e-6 slack, not 1e-8.

**Files.**
- `pentagon-gluing/quad_c5_verification.wl` (new, runnable, exit-code gated)
- `pentagon-gluing/quad_c5_crosscheck.py` (independent Python toolchain)
- `pentagon-gluing/fem_study.py`, `fem_study_results.json` (reconstruction source)

---

## 2. ISSUE-011 — fem_study_results.json missing H1–H5

**Proposed amendment (status: RESOLVED, 2026-07-13).**
Root cause identified: `fem_study.py` writes `fem_study_results.json` only at the end
of `main()` with stages filtered by `--stages`; the stale snapshot (exactly
`{sanity, quad_edges}`, `sanity.all_ok = true`, dated 2026-07-12 17:33) is the unique
signature of a `--stages sanity` partial invocation after the audit's full run —
resolving the issue's "unclear whether" in favor of the partial-flag alternative
(a crashed full run would have persisted nothing). Fixed by re-running
`python fem_study.py` end to end (exit 0, ~2.5 min); `fem_study_results.json` now
contains all of h1–h5 alongside sanity/quad_edges. Refreshed values re-confirm the
related claims verbatim: **LP-002** (Pearson r(sat_frac, CF) = -0.4294 vs
r(AUC, CF) = +0.2662, 9 points, sign flip reproduced) and **MESH-002** (cis pinch at
N=3 and even N ≥ 4; odd-N residual gaps 0.2361 / 0.3177 / 0.3601 at N = 5/7/9).
No source change was needed; `fem_study.py` is unmodified.

**Evidence.** Before/after top-level keys: `[quad_edges, sanity]` (1917 bytes) →
`[h1, h2, h3, h4, h5, quad_edges, sanity]` (20011 bytes); sanity/quad_edges unchanged.
Spot checks against the ledger: h1 trans theta/N limit 1.376717745915859 vs
tau* = 1.3767177459 (dev 5.4e-9); cct per-block gap 1.4032309 - 4/3 = 0.0698975;
h4 V_crit = (5+3*sqrt(5))/20 = 0.5854101966 for all chain/trans-ring rows, cis-ring
N=3 pinched to ~0; h3 empirical exponent 1.242, h3_rejected = False; all `all_ok`
gates True. Full run log: session scratchpad `fem_study_full_run.log`.

**Reviewer re-verification (2026-07-13).** Reviewer independently parsed the
regenerated JSON: top-level keys exactly `{h1,h2,h3,h4,h5,quad_edges,sanity}`;
h5.correlation `pearson_satfrac = -0.4294334`, `pearson_auc = +0.2662100`,
`n_points = 9`; h2.cis_pinch gaps at N=5/7/9 = 0.23606799 / 0.31766721 / 0.36009
with pinches at N=3,4,6,8 (|gap| < 2e-8); h1.limits trans = 1.376717745915859,
cct = 1.4032308692; h4 anchor 0.5854101966249685; h3 exponent 1.2416, not rejected.
All match the LP-002 / MESH-002 ledger values.

**Known residuals (flagged, not fixed).** `fem_study.py`'s docstring advertises a
`gates` stage that `main()` silently ignores; results are still written only once at
end of `main()` (a mid-study crash persists nothing); h4 cis-ring N=3 serializes as a
tiny negative LP epsilon (prints -0.000000) rather than exact 0.

**Files.**
- `pentagon-gluing/fem_study.py` (unmodified)
- `pentagon-gluing/fem_study_results.json` (regenerated deliverable, uncommitted)

---

## 3. CERT-001 / ISSUE-001 — k=7/k=8 certificate provenance

**Proposed amendment to CERT-001 (keep status: verified; amend note).**
"verified; ISSUE-001 downgraded/reframed by the 2026-07-13 regeneration test (see
`composition-optimality/PROVENANCE_K7_K8.md`): the K-parameterized
reconstruction (`GenerateEpsilonCertificate9.wl`, the CERT-002 pipeline) regenerates
the same construction and passes the identical exact verification, but converges to
strictly TIGHTER bounds — Gamma_7' = 763801638996471561227260969 /
9916852456914441403888390140 = 0.0770205710 (complete, exact, exported as
`EpsilonCertificate_testK7_output.wl`) and numeric Gamma_8' = 0.0752664136 (Stage-1
checkpoint, 10-min compute cap; full exact run ~2–2.5 h local). The committed
Gamma_7/Gamma_8 therefore remain TRUE, exactly-verified upper bounds but are
~4.2e-5 (0.054%) suboptimal relative to the transfer-SDP optimum; the lost original
generator was NOT this pipeline (coarser 1e-8-grid rounding, slightly early stop).
Bit-level provenance of the committed files remains unrecoverable; functional
provenance (construction + verification) is reproduced."

**Proposed amendment to ISSUE-001 (severity: high → medium; add resolution note).**
"Generator reconstruction validated at k=7 end-to-end (exact, self-verifying, tighter
Gamma); k=8 numeric checkpoint matches the same pattern; remaining open items are
only the uncapped k=8 exact rerun (`wolframscript -file
GenerateEpsilonCertificate_testK8.wl`, ~2–2.5 h local, no cloud needed) and a
decision whether to supersede the committed k=7/k=8 certificates with the tighter
regenerated ones."

**Evidence.** k=7 full run (~14.5 min): trusted seeds A and B both converged to
0.07702055862175518 (two random restarts diverged to spurious fixed points and were
excluded, same structure as the accepted k=9 run); Stage-2 exact projection residual
{0}; Stage-3 `nodeEqOK=edgeEqOK=psdOK=True`, pointwise sigma(e) ≤ Gamma on all 256
edges, Gamma-vs-SDP drift 1.15e-8; export hard-gated on these checks. Exact
comparison: committed 1541247/20000000 = 0.07706235 vs regenerated
0.077020571024420 — NOT equal; committed looser by 4.1779e-5. k=8 capped run:
seed A converged round 2 to 0.07526641357042801 vs committed
941357/12500000 = 0.07530856 (looser by 4.2146e-5, same signature). Committed
k=7/k=8 entries all have denominators dividing 1e8 (decimal-grid rounding);
the reconstruction rationalizes at 1e-9.

**Reviewer re-verification (2026-07-13).** Reviewer independently extracted the
`"Gamma"` fields and compared as exact rationals (Python `fractions`):
regenerated k=7 = 763801638996471561227260969/9916852456914441403888390140
= 0.07702057102441988; committed k=7 = 1541247/20000000 = 0.07706235; exact
equality False; committed − regenerated = +4.1778975580116e-5 (relative 5.42e-4).
Committed k=8 = 941357/12500000 = 0.07530856; minus the reported regenerated
numeric = +4.2146429572e-5. Both committed denominators divide 1e8: True.
All figures match the session's report. (Reviewer did not repeat the 14.5-min k=7
generation; the exported certificate and its in-file Gamma were checked directly,
per review scope.)

**Files.**
- `composition-optimality/PROVENANCE_K7_K8.md` (full narrative)
- `composition-optimality/GenerateEpsilonCertificate_testK7.wl`, `GenerateEpsilonCertificate_testK8.wl`
- `composition-optimality/EpsilonCertificate_testK7_output.wl` (regenerated, exact, self-verified)
- `composition-optimality/EpsilonCertificate.wl`, `EpsilonCertificate8.wl` (committed, unchanged)

---

## 4. GE-003 / ISSUE-010 — D1 k=3 brackets: fold-back done; Paley(13) sharpened to [39, 46]

**Proposed amendment to ISSUE-010 (status: RESOLVED, 2026-07-13).**
The audit's two resolutions are now folded back into the project's own tracking
documents AND independently reproduced: `d1_k3_maxclique.c` was recompiled from
scratch (gcc/MSYS2), all graphs regenerated by `d1_k3_graphs.py`, all nine prior
k ≤ 2 / C9-k=3 validation values reproduced first, then omega(C7^OR3) = 8 (116,109
nodes) and omega(Petersen^OR3) = 12 (10,754,445 nodes, 11 s) re-derived with natural
color-bound termination (`timed_out=0`, `toplevel_reached_break=1`) and witnesses
re-verified against raw adjacency; node counts match the audit runs bit-for-bit
(deterministic solver). `d1_k3_activation.wl` and `d1-k3-brackets-2026-07-11.md`
updated in place with "Resolved by independent recomputation 2026-07-13, confirming
the reorg audit (ISSUE-010)" markers.

**Proposed amendment to GE-003 (value + status).**
Value: replace "Paley(13) in [33,46], not closed" with "Paley(13) in **[39,46]**, not
closed — lower bound raised 33 → 39 (Class A) by the product construction the
original session missed: cliques multiply across the OR/co-normal power, so an exact
13-clique of Paley13^OR2 (GE-003's own k=2 value) times a base triangle {0,1,4}
gives an exactly-verified 39-clique of Paley13^OR3; upper bound remains the
theta-ceiling floor(13^(3/2)) = 46 (Class B). C7 = 8 and Petersen = 12 now
'pinned, independently recomputed 2026-07-13' rather than audit-only." Status:
"partially open (Paley-13 k=3 exact value unresolved; bracket [39,46]); ISSUE-010
fold-back complete." Evidence gathered (~30 min solver budget) is consistent with
omega = 39 exactly (171M-node seeded exact search found no 40-clique; 5,496
heuristic restarts found many 39-cliques, never 40; SAT inconclusive) but this is
NOT certified. The k=3-cannot-beat-k=2 convergence conclusion for Paley(13) is
unchanged (analytic: 13^(3/2) irrational). Closing the bracket exactly is estimated
at ~20–40 single-thread CPU-hours, embarrassingly parallel over the 1000 hard
top-level chunks (`--toplevel-lo/hi --initial-best 39`) — a costed plan, NOT
submitted to any cloud service.

**Evidence.** Reproduction lines: C7_k3 `RESULT graph_N=343 reduce=1 M=218
search_best=7 final_omega=8 timed_out=0 nodes=116109 toplevel_reached_break=1 /
WITNESS_VERIFIED=1 size=8`; Petersen_k3 `RESULT graph_N=1000 reduce=1 M=657
search_best=11 final_omega=12 timed_out=0 nodes=10754445 elapsed=11s
toplevel_reached_break=1 / WITNESS_VERIFIED=1 size=12`. 39-clique witness verified
twice independently: (i) all C(39,2) = 741 pairs OR-adjacent against a freshly
re-derived Paley(13) edge set, (ii) directly against the packed binary
`bin/Paley13_k3.bin`. Seeded exact runs (`--reduce --initial-best 39`): 290 s /
54.2M nodes and 590 s / 117.0M nodes, both timed out with no improvement.

**Reviewer re-verification (2026-07-13).** Reviewer wrote a from-scratch
confirmation (scratchpad `paley39_confirm.py`, no reuse of the session's binaries or
solver): rederived Paley(13) via quadratic residues (6-regular, 39 edges; {0,1,4} a
triangle); igraph's independent exact solver gives omega(Paley13^OR2) = 13 and a
*different* 13-clique (starting (0,1), not the session's (0,0) clique); its product
with {0,1,4} yields 39 distinct tuples with all 741 pairs OR-adjacent — PASS,
confirming the construction generically, not just for one witness; floor(13^(3/2))
= 46 confirmed. The committed `d1_k3_verify_witnesses.py` also re-run: C7 size-8,
Petersen size-12, and Paley 33-witness all pass (exit 0). Note: the module has no
`bin/` directory in the working tree — `d1_k3_graphs.py` must be run first to
recreate the packed binaries before re-running the C solver.

**Files.**
- `open-search-frontier/d1-k3-brackets-2026-07-11.md` (2026-07-13 addendum: fold-back + [39,46])
- `open-search-frontier/d1_k3_activation.wl` (updated in place, C7 resolution)
- `open-search-frontier/d1_k3_maxclique.c`, `d1_k3_graphs.py`, `d1_k3_verify_witnesses.py`

## 5. BBT-005 (new claim) — H4' reduction: G9 antibunching gate + KCBS eta* boundary

**Proposed amendment (status: new BBT-track claim; H4' OPEN-ENDED → REDUCED).** Add
**BBT-005** recording that the A_IE-maximality question left open by Prop O3-C (BBT-004)
is now reduced into a closable part and a quantifiable boundary. (A) A **G9 antibunching
gate** grounded in Glauber's classical bound g2(0) >= 1: for any classical light
P(alpha) >= 0 the normally-ordered variance is a genuine P-averaged variance, so
g2(0) = 1 + Var_P(I)/<I>^2 >= 1 under ANY detection; a device with g2(0) < 1 is therefore
outside the entire classical-optical-emulator family, extending O3-C completeness from
"single unmodified on-off detector, fair-sampled" to "any classical-light source, any
detector (PNR/heralded included)" [T, theorem-extension]. (B) A computed **critical KCBS
detection efficiency** eta* = 2/sqrt(5) = 2 sqrt(5)/5 = 0.8944271910 (exact), above which
completeness extends to non-fair-sampling adversaries and below which a detection-loophole
NCHV model matches the KCBS value S = sqrt(5) [C, exact]. H4' status: **REDUCED**, not fully
closed — detection efficiency remains a physical assumption, as in every Bell/contextuality
test; A_IE-maximality beyond {G9, eta*} is the residual open problem. Depends on BBT-003,
BBT-004. Class **A** (both parts exact).

**Evidence.** `certification-protocol/g9_antibunching_gate.py` prints the anchors coherent
g2(0)=1 (Poissonian boundary, symbolic), thermal 2, Fock|1> 0, and a 10^5-field numeric
certificate that every classical P>=0 mixture has g2 >= 1. `efficiency_threshold_kcbs.py`
derives eta* = 2/sqrt(5) two independent ways — (i) the efficiency-degraded quantum value
eta* sqrt(5) meets the NCHV bound 2; (ii) an exact LP over the 11 independent sets of C_5
gives max fair-sampled loophole value 2/eta reaching sqrt(5) at the same eta* — and tabulates
the odd-n-cycle generalization eta*_n = ((n-1)/2)/Q_n, Q_n = n cos(pi/n)/(1+cos(pi/n)).
Integrated into `docs/FRAMEWORK-2026-07-13.md` ("H4' EXECUTED" delta) and
`certification-protocol/PROPOSITION-O3.md` (provenance note); repo commits c24ccb3, ac0f33d.

**Reviewer re-verification (2026-07-13).** Two-reviewer adversarial pass (the H4'/G9 build
workflow): 0 blocker/major findings; minor honesty-tightenings applied and recorded —
Part-B phrased "matches the quantum KCBS VALUE S = sqrt(5)" (the LP bounds the KCBS sum, not
the full context-by-context statistics), and the G9 epsilon band flagged as a heuristic
INCONCLUSIVE collar (not a rigorous confidence bound for a moment-ratio statistic). Underlying
physics is textbook (Glauber Phys. Rev. 131 2766 (1963); Larsson PRA 57 R3145 (1998);
Garg-Mermin PRD 35 3831 (1987)) — the contribution is the protocol gate/boundary, not the
physics.

**Files.**
- `certification-protocol/g9_antibunching_gate.py`, `efficiency_threshold_kcbs.py`
- `docs/FRAMEWORK-2026-07-13.md` ("H4' EXECUTED" delta), `certification-protocol/PROPOSITION-O3.md`
- `docs/ledger-snapshot/LEDGER.md` (BBT-005 row added in the repo snapshot)

---

*Assembled 2026-07-13 by the reviewer session from five verification-session reports,
each re-checked as described above. Apply to
`01-claims-ledger/{ledger.json, LEDGER.md, KNOWN_ISSUES.md}` manually.*
