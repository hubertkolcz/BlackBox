# OQ1 / OQ2 probe implementation specs (2026-07-13)

Normative implementation specifications for the two open items of
`PROPOSITION-O3.md` (ledger `BBT-002`; candidate follow-on claims). Phase-2
executors implement exactly what is written here; every free choice (seeds,
grids, tolerances, thresholds, print formats) is pre-registered below. The
companion script `oq_probe_pilot_2026-07-13.py` (same folder) reproduces every
load-bearing number quoted in this spec; run it first — it must print the
quoted values before any Phase-2 implementation work starts.

Design-validation findings that shaped this spec (pilot, run 2026-07-13):

1. **OQ1**: the quantum table-orbit Jacobian has singular values
   sigma_1, sigma_2 in [1.27, 2.43] and sigma_3 <= 4e-11 at every sampled
   theta (V = 1.0 and 0.977) — rank exactly 2, gap ~10 decades. The
   theta-blind rig is rank 0; the theta-aware polytope-fitting rig matches
   the quantum orbit exactly (residual 0). So OQ1's game value is
   (quantum, blind, aware) = (2, 0, 2), and BOTH publishable outcomes of
   PROPOSITION-O3 OQ1 obtain simultaneously.
2. **OQ2**: an *unanchored* eta-scaling test is worthless — an eta-blind
   stochastic report map forges it exactly (pilot: Delta = 0, e.g. the
   all-null map). G8 is only sound as a JOINT gate: the eta = 1 arm must be
   QUANTUM-CERTIFIED by C1–C5 (anchoring the table) and the raw-rate family
   must be binomial-consistent. Anchored, the best eta-blind forger deviates
   by Delta_min = 0.0413 (J = 8 grid, z_max = 0.20, exact anchor), 0.0264 at
   anchor slack 0.005, 0.0149 at slack 0.01.
3. **OQ2 grid**: J = 3 attenuation points are inadequate — *exactly*
   forgeable at z_max = 0.5 (Delta_min = 0 even anchored) and still
   sub-threshold at z_max = 0.20 (Delta_min = 0.0040 < 3 t_max = 0.0130).
   At z_max = 0.20: J = 6 -> 0.0388, J = 8 -> 0.0413. J = 8 pre-registered.
4. **OQ2 loss freedom**: the forger's dominant freedom is declared eta = 1
   inefficiency z. Pinning z = 0 gives Delta_min = 0.71; z_max = 0.5 gives
   0.0024. The operating condition z <= 0.20 (G8a below) is the power dial.

---

## Part I — OQ1: interventional DLA bounding

**Deliverable**: `certification-protocol/oq1_interventional_dla.py`, standalone,
Python only (numpy, scipy, cvxpy), no sampling anywhere (exact Born tables),
runtime < 2 min local. Exit code 0 iff the pre-registered readout holds.

### I.1 Intervention family U_theta

Wave-plate pair between preparation and cascade, modeled as the full SO(3)
acting on the (real) qutrit preparation:

- Parameter: theta in R^3 (axis–angle), |theta| <= pi/2.
- U_theta = Rodrigues rotation `rot(theta)`:
  R = I + sin|theta| K + (1-cos|theta|) K^2, K = hat(theta/|theta|) cross-matrix;
  R = I when |theta| < 1e-300.
- Intervened preparation: psi(theta) = R(theta) @ PSI, PSI = (0,0,1).
- The cascade (measurement side) is untouched: same `kcbs_vectors()` LVEC as
  `mbqc_blackbox_test.py` (import or copy verbatim — do NOT re-derive).

### I.2 Table map theta -> T(U_theta . prep)

Exact Born, 20-vector in the protocol's section order (00, 01, 10, 11) per
context c = (i, i+1 mod 5):

```
def table_theta(theta, V=1.0):
    psi = rot(theta) @ PSI
    e = np.zeros(20)
    for c, (i, j) in enumerate(CTX):
        a, b = LVEC[i], LVEC[j]
        n = np.cross(a, b); n /= np.linalg.norm(n)
        p10 = V * (a @ psi) ** 2 + (1 - V) / 3
        p01 = V * (b @ psi) ** 2 + (1 - V) / 3
        p00 = V * (n @ psi) ** 2 + (1 - V) / 3
        e[4 * c : 4 * c + 4] = [p00, p01, p10, 0.0]
    return e
```

No finite-sample layer: the rank question is about the exact response
manifold; sampling would only add noise the tolerance analysis then has to
carry. (A finite-N remark belongs in the discussion section of the writeup,
not in the probe.)

### I.3 Numerical rank procedure (primary: FD Jacobian + SVD)

- Central finite differences, step **h = 1e-5**, on each of the 3 axes:
  J[:,k] = (T(theta + h e_k) - T(theta - h e_k)) / (2h), J is 20 x 3.
- Error budget justifying h and the tolerance: entries of T are degree-2
  trigonometric polynomials of theta with third derivatives O(1) (bounded by
  8); truncation error <= (h^2/6) * 8 ~ 1.3e-10; float64 rounding
  ~ eps_mach/(2h) ~ 6e-12; per-entry FD error <= 2e-10; spectral norm of the
  Jacobian error ||E||_2 <= sqrt(20*3) * 2e-10 ~ 1.6e-9.
- **Rank tolerance sigma_tol = 1e-7** (pre-registered): >= 60x the 1.6e-9
  noise ceiling, <= 1e-4 x the smallest true singular value ever observed in
  the pilot (1.27). Decision: rank = #{sigma_k > sigma_tol}.
- **Spectral-gap guard**: if 1 <= rank <= 2, additionally require
  sigma_rank / sigma_rank+1 >= 1e3; else mark the point DEGENERATE, exclude
  it from the tally, and report the count (pilot expectation: 0 degenerate
  points). If sigma_max < sigma_tol, rank = 0 and the gap test is skipped
  (this is the theta-blind rig's code path — same pipeline, no special case).

### I.4 Cross-check: local PCA of the table cloud

At each base point theta_m and each radius rho in {0.02, 0.01}:

- Draw K = 400 offsets: direction = rng.normal(3)/norm, radius
  rho * u^(1/3), u = rng.uniform() (volumetric sampling). Same single rng
  as Section I.6, consumed in declared order.
- Cloud = {table_theta(theta_m + d)}; center; eigenvalues lambda_k of the
  covariance via SVD of the centered matrix.
- **Decision rule (pre-registered)**: dim_PCA = #{k : lambda_k(rho=0.02) > 1e-7
  AND lambda_k(0.02)/lambda_k(0.01) in [3, 5]}. Tangent directions scale as
  rho^2 (ratio 4); curvature directions as rho^4 (ratio ~16) — pilot values:
  ratios (4.20, 3.68) for the two tangent eigenvalues, 14.9 for the third,
  lambda_3(0.02) ~ 1.8e-8 < 1e-7. Both filters agree on dim 2.
- Consistency requirement: dim_PCA == rank(J) at every non-degenerate point.

Additional exact anchor (cheap, do it): at theta = 0 the Jacobian is
analytic — dT/dtheta_k = 2V (l . z)(l . (e_k x z)) per projector l — whose
third column (k = 3, rotation about the preparation axis z) vanishes
identically; assert rank 2 with sigma_1 = sigma_2 (pilot: 2.4266 double) and
kernel = z-rotations. This is OQ1's sanity-first anchor in the sense of the
protocol's SANITY-FIRST RULE; abort if it fails.

### I.5 The two rig baselines

**(B) theta-blind rig** — fractions frozen at the adversarial point:
T_B(theta) = table_intensity(1/sqrt(5), 0) = T_iii-d, constant. Run it
through the IDENTICAL FD + SVD + PCA pipeline (expected: J = 0 exactly,
rank 0, dim_PCA 0).

**(A) theta-aware rig** — best case allowed by Prop. 1: the rig knows theta
and re-tunes its intensity fractions to any point of the no-disturbance
polytope. Pre-registered optimization (projection onto the ND polytope):

    T_A(theta) = argmin_x ||x - T(theta)||_2^2   subject to
      x >= 0 (20 vars);  x[4c+3] = 0 for all c (structural (1,1) zero);
      sum_s x[4c+s] = 1 for all c (per-context normalization);
      x[4((m-1)%5)+1] + x[4((m-1)%5)+3] = x[4m+2] + x[4m+3] for m = 0..4
      (no-disturbance marginal equalities, exactly `marginals()` of
      mbqc_blackbox_test.py).

  Implementation: cvxpy with OSQP, eps_abs = eps_rel = 1e-10.

- **Executor trap, closed here**: do NOT finite-difference through the QP.
  QP solver jitter (~1e-8) sits above the FD scale and fabricates spurious
  rank. Pre-registered rule: since every T(theta) is itself a valid ND table,
  the projection must return it — assert residual ||T_A - T||_2 < 1e-9 at
  every sampled theta, then set T_A ≡ T analytically and record
  rank_aware = rank_Q *by identity*. Only if some residual exceeds 1e-9
  (which falsifies the polytope-membership claim and must be reported as a
  finding) fall back to FD on the QP path with h = 1e-3 and the gap guard.

### I.6 Sampling plan and seeds

- Single rng: `rng = np.random.default_rng(20260711)`; consumed in this
  exact order: for each V in (1.0, 0.977): 30 base points (direction then
  radius), then per base point the two PCA clouds (rho = 0.02 first).
- Base points: M = 30 per V; direction = rng.normal(3)/norm; radius
  |theta| = rng.uniform(0.05, pi/2) (0.05 floor avoids the measure-zero
  identity; pi/2 cap avoids the axis–angle chart boundary).
- No other random draws anywhere.

### I.7 Pre-registered acceptance readout (exactly PROPOSITION-O3 OQ1)

- **OQ1-A (blind separation)**: rank_Q = 2 at >= 28/30 non-degenerate base
  points for each V, PCA agreeing, AND rank_blind = 0 at all 30. If it
  holds: *"Interventional table access strictly separates the DLA-3 cascade
  from every fraction-frozen intensity rig: orbit rank 2 vs 0. Under the
  assumption that the rig's fraction-setting is decoupled from theta, the
  interventional protocol closes BBT-002 without trusting any compilation
  declaration (Corollary-2 trust assumption discharged)."*
- **OQ1-B (aware matching)**: T_A residual < 1e-9 at all theta (hence
  rank_aware = rank_Q). If it holds: *"A theta-aware rig that re-tunes
  within the ND polytope reproduces the full quantum orbit exactly:
  interventions alone do not certify the DLA without a theta-decoupling,
  timing, or semantics assumption — Proposition 1 extends from static to
  interventional table access."* (Candidate ledger claim alongside BBT-003.)
- Pilot verdict: BOTH hold; the probe's headline is the game value (2,0,2).
- Interpretation guard (print it in the scoreboard footer, verbatim):
  "Orbit rank 2 = dim SO(3)/stabilizer, implied by DLA 3; it lower-bounds
  the DLA of any rig whose response factors through its own internal
  dynamics (leaf-confined so(3) subalgebras are 1-dimensional, orbit rank
  <= 1). The theta-aware fitter evades because its response does not factor
  through a dynamics at all."

### I.8 Scoreboard format (print exactly)

```
==============================================================================
OQ1  INTERVENTIONAL DLA PROBE  (M=30 theta/V, h=1e-5, sigma_tol=1e-7, seed 20260711)
==============================================================================
  V=1.000
   m  |theta|   sigma1     sigma2     sigma3      rankJ dimPCA blind awareR      verdict
   01  0.9273  2.1376e+00 1.3328e+00 2.1880e-11    2     2      0    <1e-9       OK
   ...
  summary V=1.000: rank2 30/30, degenerate 0, blind rank0 30/30, aware match 30/30
  [repeat block for V=0.977]
  OQ1-A (blind separation):  SUPPORTED / UNDERMINED
  OQ1-B (aware matching):    SUPPORTED / UNDERMINED
  <interpretation guard paragraph>
MACHINE-READABLE SUMMARY
{json: seed, h, sigma_tol, per-V tallies, OQ1_A, OQ1_B}
```

Exit 0 iff the theta=0 anchor passes and OQ1-A and OQ1-B are both SUPPORTED.

---

## Part II — OQ2: attenuation-series gate G8

**Deliverable**: `certification-protocol/oq2_attenuation_gate.py`, standalone
(numpy, scipy.optimize.linprog/differential_evolution), structured so that
`cert_g8` / `gate_g8` can later be merged into `mbqc_blackbox_test.py`
unchanged. Runtime: pilot phase ~5 min, sampling phase ~10 min, local.

### II.1 Physical model and scaling laws (per arXiv:2601.13869)

Kovtoniuk–Bohmann–Semenov, "Nonclassical photocounting statistics with a
single on-off detector" (arXiv:2601.13869): a bare on-off click record is
coherent-state-forgeable; *controlled attenuation as a tunable setting* makes
it nonclassicality-revealing. The scaling laws (standard photocounting model
the paper is built on; abstract fetched 2026-07-13, equations below are the
canonical forms the executor needs — no further paper access required):

- On-off detector, input photon-number distribution P(n), attenuation eta:
  no-click probability Q(eta) = sum_n P(n) (1-eta)^n.
- **Single photon (Fock |1>)**: Q(eta) = 1 - eta. Click probability exactly
  linear in eta (binomial thinning; attenuated Fock-n is Binomial(n, eta)).
- **Coherent state, mean mu**: Q(eta) = exp(-eta mu) (attenuated Poisson
  stays Poisson). Click probability 1 - e^(-eta mu), strictly concave.
- General classical light: Q(eta) = Laplace transform of a positive
  P-function — completely monotone, in particular log-convex in eta. The
  Fock-1 line 1 - eta violates log-convexity. (Report the discrete
  log-convexity witness Q(eta1)Q(eta3) - Q(eta2)^2 as a DESCRIPTIVE second
  opinion only, like the bootstrap in C2 — the pilot proved report-map
  post-processing can distort per-outcome CM, so it is never the gate.)

### II.2 Interface extension and adversary model (new assumption A2')

- The tester inserts a calibrated attenuator (transmission eta) in front of
  the box's detectors and draws eta i.i.d. per trial, uniformly over the
  pre-registered grid, recording eta per trial. This *replaces* trusting A2.
- **Attenuation grid (pre-registered): J = 8, etas = (1.0, 0.85, 0.70, 0.55,
  0.40, 0.25, 0.12, 0.05).** Rationale (all at the z_max = 0.20 design
  point): J = 3 is sub-threshold (Delta_min = 0.0040, and exactly forgeable
  at z_max = 0.5); J = 6 reaches 0.0388; J = 8 gives 0.0413 plus redundancy
  against the global-anchor pilot eroding the floor, at negligible cost.
- Forger class (exactly what randomized per-trial eta enforces): classical
  intensities mu_d >= 0 on the 3 detectors of each context, independent
  Poissonian clicks 1 - e^(-eta mu_d), and an **eta-blind stochastic report
  map** g: {0,1}^3 -> {00, 01, 10, null} fixed across trials (its electronics
  see only its own raw click pattern — data-processing bound on its per-trial
  knowledge of eta). Fabrication (reporting clicks on raw pattern 000) is
  ALLOWED; the pilot shows the no-fabrication restriction changes nothing
  (Delta_min identical to 6 decimals), so the gate does not need that extra
  assumption.

### II.3 Device family under test (the eta-family of tables)

Per context c, per trial: outcome in {00, 01, 10, null}; empirical raw-rate
vectors q_hat_c(eta_j) from N_G8 trials per (c, eta_j).

- **(a) single-photon qutrit box**: q_c(eta) = (eta p00, eta p01, eta p10,
  1 - eta) with (p00, p01, p10) the Born row of `table_quantum(V)`;
  `box_quantum_attenuated(V, eta, N, rng)` = one multinomial per (c, eta).
  Classical NCHV box: same construction on `TABLE_CLASSICAL` rows (it has
  legitimate single-photon semantics and MUST pass).
- **(b) coherent/intensity forger** `box_forger_attenuated(mu, g, eta, N, rng)`:
  sample raw patterns r in {0,1}^3 with P_eta(r) = prod_d [r_d (1-e^(-eta mu_d))
  + (1-r_d) e^(-eta mu_d)], then apply g. Two pre-registered instances:
  - **F0 (iii-d physicalized, untuned)**: report map = "null if no raw click,
    else the lowest-index clicked detector" (detector order: the 00-detector
    n, then 01 = l_{i+1}, then 10 = l_i — i.e. section order); mu solved
    (3-dim root find, scipy.optimize.fsolve, x0 = -ln(1-p)) so that the
    REPORTED conditional-on-click table at eta = 1 equals the quantum row
    exactly. Pilot (identity variant): max scaling deviation 0.071 — far
    above threshold.
  - **F\* (minimax)**: (mu*, g*) from the pilot LP (II.6). Its deviation IS
    Delta_min; it is the hardest allowed opponent.

### II.4 Test statistic and thresholds (Hoeffding/Bonferroni house style)

Binomial-consistency deviations, for c = 0..4, s in {00, 01, 10, null},
j = 2..J:

    D[c,s,j] = | q_hat[c,s](eta_j) - eta_j q_hat[c,s](1) - (1-eta_j)*[s==null] |

Identity making this loss-robust (state it in the docstring): a binomial
device with ANY intrinsic efficiency 1-z has q_s(eta) = eta (1-z) p_s and
q_null(eta) = 1 - eta(1-z), so D = 0 in expectation for every z — quantum
boxes at every visibility V pass without knowing z, and the V = 0.977 box
needs no external table anchor (the statistic is anchored to the box's OWN
eta = 1 arm).

- Confidence budget: **alpha_G8 = 0.01**, a NEW budget for the G8 data run
  (separate experiment; does not touch the alpha = 0.01 of C1–C5).
  Comparisons m = 5 contexts x 4 outcomes x (J-1) = 140; each uses two
  independent empirical means, so a' = alpha_G8 / (2 * 140) = 3.5714e-5.
- eps = sqrt(ln(2/a') / (2 N_G8)); threshold per comparison
  **t[c,s,j] = eps * (1 + eta_j)** (Hoeffding on q_hat(eta_j) plus eta_j
  times Hoeffding on q_hat(1)).
- **G8b flag (semantics violation)**: any D[c,s,j] > t[c,s,j].
- **G8a operating condition**: total reported click rate at eta = 1 must
  satisfy q_hat_click(1) >= 1 - z_max - eps with **z_max = 0.20**; otherwise
  the box is OUT-OF-RANGE (semantics untestable at this efficiency — a
  distinct outcome, not a pass). The simulated boxes have z = 0.
- **Joint-gate requirement (the pilot's central lesson)**: G8 is only sound
  together with the anchor — the eta = 1 arm of the SAME data must be run
  through the existing C1–C5 stack and come out QUANTUM-CERTIFIED for the
  boxes claiming quantumness. An unanchored scaling test is exactly
  forgeable (pilot: all-null map). Implement `cert_g8(counts_by_eta, N)`
  returning {"D_max", "argmax", "threshold_max", "g8a_click1", "flag_b",
  "in_range_a"}; the eta = 1 counts (click outcomes only, renormalized) are
  ALSO fed to `certificates()` unchanged.

### II.5 Sample sizes and power (pre-registered)

- **N_G8 = 10^6 trials per (context, eta_j)** => 4e7 per box per repetition;
  numpy multinomial cost is per-cell, not per-trial — seconds.
- eps = sqrt(10.933 / 2e6) = 2.338e-3; max threshold (j>=2, eta_j <= 0.85):
  t_max = 4.33e-3.
- Adversary floor vs threshold: Delta_min = 0.0149 even granting the forger
  anchor slack delta_a = 0.01 (loose C-gate pinning); 0.0149 > 3 t_max =
  0.0130. At the realistic slack (the eta=1 arm has N = 5e6 pooled per
  context, pinning the table to ~0.003) the floor is >= 0.0264 ~ 6 t_max.
  F0's deviation 0.071 ~ 16 t_max. Quantum/NCHV boxes: exact zeros.

### II.6 The minimax pilot (run BEFORE the gate; ships with the gate)

`Delta_min = min_mu min_g max_(j,s) |q_s(eta_j) - eta_j q_s(1) - (1-eta_j)[s=null]|`
subject to the anchor `q_s(1) = (1-z) p_s (+/- delta_a)`, `0 <= z <= z_max`,
g stochastic (8x4, rows sum to 1).

- Inner problem is an **LP in (g, z)** for fixed mu (34 vars: 32 g entries,
  z, t; equality rows: 8 row-sums + 3 anchors when delta_a = 0, else anchor
  inequalities; 2 x 4 x (J-1) deviation inequalities). scipy linprog HiGHS.
- Outer problem: scipy differential_evolution over log mu in [-3, 3.5]^3,
  **seed 20260712**, maxiter 80, popsize 14, tol 1e-10, polish True.
- Reference outputs the executor MUST reproduce before proceeding
  (J = 8 grid, quantum V = 1 anchor row p = (1 - 2/sqrt5, 1/sqrt5, 1/sqrt5)):

  | configuration                       | Delta_min | mu*                  |
  |-------------------------------------|-----------|----------------------|
  | z_max 0.20, delta_a 0               | 0.041309  | ~(2.647, 2.646, 2.592) |
  | z_max 0.20, delta_a 0.005           | 0.026413  | ~(2.58, 2.47, 2.58)  |
  | z_max 0.20, delta_a 0.01            | 0.014881  | ~(2.43, 2.40, 2.45)  |
  | z_max 0.05                          | 0.191565  |                      |
  | z_max 0.10                          | 0.111839  |                      |
  | z_max 0.50                          | 0.002425  |                      |
  | J = 3 grid (1.0, 0.5, 0.25), z_max 0.20 | 0.004000 | (sub-threshold)   |
  | J = 3 grid, z_max 0.50              | 0.000000  | (exactly forgeable)  |
  | J = 6 grid (1,0.8,0.6,0.4,0.2,0.1), z_max 0.20 | 0.038824 |            |
  | no-fabrication, J = 12, z_max 0.5   | = fabricating case to 6 decimals |

- **Remaining pilot item (the one genuinely open computation)**: outer-
  optimize the anchor over ALL certifiable tables (every T with CF_lo > 0
  at the eta = 1 arm's N, plus G8a), not just the exact quantum point:
  add the 15 table values as LP variables with the CF-region constraints
  linearized via the 32-assignment LP dual, or (simpler, pre-registered)
  grid the anchor over `table_quantum(V)` for V in [V_crit, 1] plus a
  delta_a = 0.005 ball. **Kill criterion: Delta_min_global < 0.015 =>
  do NOT ship G8 as specified; escalate** (in order: widen grid to J = 16
  adding (0.95, 0.775, 0.625, 0.475, 0.325, 0.185, 0.085, 0.02); tighten
  z_max to 0.10; only then consider a no-fabrication assumption). Validate
  criterion: Delta_min_global >= 0.015 => freeze this spec and sample.

### II.7 Pre-registered pass/fail matrix (R = 25 reps, house rules)

Gate G8 passes iff every row hits its expected outcome in >= 95% of reps;
UNDERMINED (G5-style) if any forger row reaches "no flag" even once at
N_G8 = 10^6.

| box                                   | G8a in-range | G8b expected      | eta=1 arm C1–C5 |
|---------------------------------------|--------------|-------------------|-----------------|
| quantum V = 1.000                     | yes          | PASS (no flag)    | QUANTUM-CERTIFIED |
| quantum V = 0.977                     | yes          | PASS              | QUANTUM-CERTIFIED |
| quantum V = 0.550                     | yes          | PASS              | CLASSICAL (G8 is orthogonal to CF) |
| quantum V = V_crit                    | yes          | PASS              | (edge, reported) |
| classical NCHV                        | yes          | PASS              | CLASSICAL |
| F0 forger (iii-d physicalized)        | yes          | **FAIL every rep**| QUANTUM-CERTIFIED (that is the point) |
| F\* minimax forger                    | yes          | **FAIL every rep**| QUANTUM-CERTIFIED |

Verdict integration (second step, after the standalone gate is green): the
G8b flag enters `verdict()` as V0, before V1, reason string
"SEMANTICS-VIOLATION: click statistics not binomial-consistent across the
attenuation series (non-single-photon source)". Phase 2 delivers the
standalone gate first; the merge into `mbqc_blackbox_test.py` is a separate
commit-sized change.

### II.8 Seeds and rng discipline

- `rng = np.random.default_rng(20260712)` for ALL G8 sampling, consumed in
  this exact order: boxes in the table order of II.7 (top to bottom), reps
  outer loop, contexts 0..4, eta descending (1.0 first), one multinomial
  per (c, eta) for table boxes / one 8-cell multinomial + map for forgers.
- Pilot optimizer seeds are fixed IN the calls: differential_evolution
  seed 20260712 (main), 20260713 (no-fabrication variant), 20260714
  (z-pinned variant) — matching the reference table above.
- F0's fsolve is deterministic (x0 = -ln(1 - p)); no seed.

### II.9 Scoreboard format (print exactly)

```
==============================================================================
OQ2  ATTENUATION-SERIES GATE G8  (J=8, N=1e6/(ctx,eta), alpha_G8=0.01, z_max=0.20,
                                  seed 20260712)
==============================================================================
  PILOT: Delta_min(exact anchor) = 0.041309   Delta_min(slack 0.005) = 0.026413
         Delta_min(global anchor) = <value>   [VALIDATED / KILLED]
  thresholds: eps = 0.002338, t_max = 0.004330
  box                              G8a   D_max     @(c,s,eta)     t      G8b     eta1-arm
  quantum V=1.000                  ok    0.0004    (2,01,0.40)  0.0043   pass    QUANTUM-CERTIFIED
  ...
  F* minimax forger                ok    0.0264    (0,null,0.05) 0.0043  FLAG    QUANTUM-CERTIFIED
  repetition tally (R=25): <per box: expected outcome rate, PASS/FAIL>
  G8 GATE: [SUPPORTED / UNDERMINED]
MACHINE-READABLE SUMMARY
{json: seed, etas, N, eps, Delta_min table, per-box D_max/reps, gate bool}
```

Exit 0 iff pilot VALIDATED and G8 SUPPORTED.

---

## Part III — shared executor rules

1. Run `oq_probe_pilot_2026-07-13.py` first; every quoted number must
   reproduce (FD singular values to 3 significant digits, Delta_min to 1e-5)
   before writing new code.
2. Python only; no wolframscript needed for either probe (no seat issues).
   No RemoteBatchSubmit / CloudEvaluate — everything here is minutes local.
3. Do not modify `mbqc_blackbox_test.py` in Phase 2 except the final,
   separate G8-merge step (II.7); the standalone scripts must not import
   side effects from it (copy the small helpers they need: kcbs_vectors,
   CTX, table_quantum, TABLE_CLASSICAL, table_intensity, marginals).
4. Ledger (after both probes run green): OQ1 outcome updates BBT-002's open
   items and instantiates the OQ1-A/OQ1-B statements of PROPOSITION-O3
   Section "What remains genuinely open"; G8 closes the OQ2 item and the
   iii-d blind spot under assumption A2'. Candidate IDs: BBT-004 (OQ1 game
   value (2,0,2)), BBT-005 (G8 semantics gate, with the J>=6 forgeability
   boundary as its sharpest lemma).
