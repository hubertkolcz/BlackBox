(* ::Package:: *)

(* ::Title:: *)
(*The Signaling Strata: Extending the Correlation Taxonomy to Signaling and Quantum-Communication Scenarios*)

(* ::Subtitle:: *)
(*Three axes \[LongDash] a repurposed rejected tool, the Contextuality-by-Default layer, and two communication LPs \[LongDash] with pre-registered gates*)

(* ::Text:: *)
(*Hubert Ko\[LSlash]cz \[LongDash] July 2026. Companion to signaling_taxonomy.py (the executable verifier: every number below was computed there on 10 July 2026, all gates PASS, exit 0) and NOTES-signaling.md (the strata table and pinned references). PROVENANCE NOTE, stated plainly: no Wolfram kernel was available in the sandbox where this extension was developed; this essay is written to be wolframscript-runnable (headless: wolframscript -file RunSignalingTaxonomy.wl -print all, must end OK -> True) and re-derives natively every exact-arithmetic claim, while the float-LP and Monte-Carlo layers are mirrored from the executed Python run as pinned literals, marked as such in the Verification association.*)

(* ::Abstract:: *)
(*The taxonomy so far classifies NO-DISTURBANCE models: classical / probabilistically contextual / strongly contextual, with the contextual fraction CF as the quantitative layer (CertifyingQuantumness.wl, SupportCohomology.wl). This note extends it to models that SIGNAL, in four moves. (1) The cellular-sheaf harmonic residual, pre-registered-REJECTED as a contextuality measure precisely because its kernel is the whole no-disturbance space, is repurposed as the detector of the new axis: by Abramsky-Brandenburger Theorem 5.9 (arXiv:1102.0264), an R-linear global section exists iff the model is no-signalling, and in matrix form this is the exact identity im(Incidence) = ker(Coboundary) \[LongDash] verified here by exact rank arithmetic (11 = 11 on C5, with delta . M = 0) and on 700 random instances by LP. The rejected tool was blind to contextuality because it was measuring the OTHER axis. (2) The Contextuality-by-Default (CbD) layer classifies contextuality FOR signaling data: the cyclic-system criterion of Kujala-Dzhafarov (Found. Phys. 46, 282 (2016), arXiv:1503.02181, proving the Dzhafarov-Kujala-Larsson conjecture; equivalent to the PRL 115, 150401 criterion by their Theorem 13) is contextual iff s1(correlations) - Delta > n - 2 with Delta the total context-dependence of the marginals. On the ideal quantum C5 it reduces exactly to the KCBS verdict (s1 = 4 Sqrt[5] - 5, i.e. Sum <P_i> = Sqrt[5]) and its measure CNTX = (s1 - Delta - (n-2))/2 equals CF = 2 Sqrt[5] - 4 EXACTLY; on the Lapkiewicz-realistic reconstruction (V = 0.977 noise model, closing marginal shifted by the measured eps = 0.081) the verdict stays contextual with the margin reduced by exactly eps; on a deterministic pure-signaling box the verdict is noncontextual with margin exactly 0 \[LongDash] all the context-dependence is booked as signaling, none as contextuality. (3) The communication axis prices the tables: the signaling-fraction LP (free part = arbitrary table) reproduces SF(C5, quantum) = 2 Sqrt[5] - 4 exactly, pinched by an exact primal/dual certificate pair over Q[Sqrt[5]]; and the one-bit communication LP over all 4^5 = 1024 deterministic context-aware strategies gives minimal bit-fraction mu = 2 Sqrt[5] - 4 bits/round with a fully explicit witness \[LongDash] because of the exact decomposition e_quantum = (5 - 2 Sqrt[5]) e_classical + (2 Sqrt[5] - 4) e_Wright: the quantum-maximal pentagon table is EXACTLY the CF-optimal mixture of the classical-maximal model and the Wright box, and the Wright box is the uniform mixture of 32 one-bit strategies. A classical optical emulation that wants to fake the quantum table must transmit the context bit in exactly a 2 Sqrt[5] - 4 fraction of the rounds. (4) The synthesis is a three-axis stratification \[LongDash] signaling residual; CbD verdict; communication cost \[LongDash] populated by computed exemplars, with the impossibility theorem of Tezzin-Wolfe-Amaral-Jones (arXiv:2212.06976) as the structural reason the axes must remain separate numbers rather than merge into one.*)

(* ::Section:: *)
(*0. Pre-Registered Gates (fixed before computation)*)

(* ::Item:: *)
(*G1 (signaling stratum). The three-way equivalence {harmonic residual = 0} <=> {R-linear global section exists} <=> {marginals consistent} must hold exactly on the canonical C5 models and the pure-signaling box (exact arithmetic), and to LP tolerance on 500 random signaling perturbations plus 200 random no-disturbance models; the exact rank ledger must read rank(delta5) = 9, dim ker = 11 = dim(affine hull of the no-disturbance polytope) + 1 = 10 + 1, rank(M5) = 11, delta5 . M5 = 0 (whence im M = ker delta), with the C4 analogues 7 / 9 = 8 + 1 / 9 / 0. Else the repurposing is UNDERMINED.*)

(* ::Item:: *)
(*G2 (CbD layer). The pinned cyclic criterion must classify: ideal quantum C5 contextual with Delta = 0, s1 = 4 Sqrt[5] - 5 (equivalently Sum <P_i> = Sqrt[5]: the standard KCBS verdict); classical C5 noncontextual with margin exactly 0; the Lapkiewicz-realistic reconstruction contextual with the Delta-penalty visibly reducing the margin (reduction = eps exactly); the pure-signaling box noncontextual. Else FAIL.*)

(* ::Item:: *)
(*G3 (communication cost). LP (a) must reproduce SF(C5, quantum) = 2 Sqrt[5] - 4 exactly (float LP to 1e-8 AND an exact primal/dual pinch); LP (b) must yield a finite minimal bit-fraction in [0, 1] for the quantum table with the witness strategy exhibited, and mu(PR box) = 1 with its witness. Else FAIL.*)

(* ::Section:: *)
(*1. Environment*)

(* ::Input:: *)
PacletDirectoryLoad[FileNameJoin[{Quiet@Check[NotebookDirectory[], Directory[]], "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"]; Quiet[Remove /@ Select["Global`" <> # & /@ Names["HubertKolcz`BlackBox`*"], NameQ]];

(* ::Input:: *)
scen5 = CycleScenario[5]; scen4 = CycleScenario[4];
M5 = scen5["Incidence"]; M4 = scen4["Incidence"];
delta5 = CycleCoboundary[5]; delta4 = CycleCoboundary[4];
eC = CycleModel[5, "Classical"]; eQ = FullSimplify@CycleModel[5, "Quantum"]; eW = CycleModel[5, "Wright"];
ePR = Flatten[{{1/2, 0, 0, 1/2}, {1/2, 0, 0, 1/2}, {1/2, 0, 0, 1/2}, {0, 1/2, 1/2, 0}}];
ePureSig = Flatten[{{1, 0, 0, 0}, {1, 0, 0, 0}, {1, 0, 0, 0}, {1, 0, 0, 0}, {0, 0, 1, 0}}];

(* ::Section:: *)
(*2. Axis 1 \[LongDash] the Signaling Stratum via the Repurposed Rejected Tool*)

(* ::Text:: *)
(*CertifyingQuantumness.wl records the pre-registered REJECTION of HarmonicResidual as a contextuality measure: residuals {0, 0, 0} on classical/quantum/Wright against CF {0, 2 Sqrt[5] - 4, 1}, because ker(delta) is exactly the no-disturbance space. Abramsky-Brandenburger Theorem 5.9 turns the defect into the definition of the new axis: an R-LINEAR global section (a signed measure on global assignments marginalizing to the model) exists if and only if the model is no-signalling. In the matrix representation both sides are linear-algebra objects and the theorem becomes the exact identity im(M) = ker(delta): delta . M = 0 gives the inclusion, and rank M = dim ker delta = 2n + 1 (Abramsky-Brandenburger Prop. 5.7 on one side, the single row-dependency of delta on the other) gives equality. The rejected tool detects EXACTLY the failure of the R-linear section \[LongDash] it was measuring the signaling axis all along.*)

(* ::CodeText:: *)
(*The exact rank ledger, C5 and C4; normRows are the per-context normalization functionals, so the stacked rank prices the affine hull of the no-disturbance polytope:*)

(* ::Input:: *)
normRows[n_] := Table[Flatten[Table[If[k == c, {1, 1, 1, 1}, {0, 0, 0, 0}], {k, 0, n - 1}]], {c, 0, n - 1}];
rankLedger5 = {MatrixRank[delta5], 20 - MatrixRank[delta5], MatrixRank[M5],
   Max[Abs[delta5 . M5]], 20 - MatrixRank[Join[delta5, normRows[5]]]}
(* expected: {9, 11, 11, 0, 10}: kernel 11 = affine hull 10 + 1 (the overall normalization scale); im M = ker delta *)

(* ::Input:: *)
rankLedger4 = {MatrixRank[delta4], 16 - MatrixRank[delta4], MatrixRank[M4],
   Max[Abs[delta4 . M4]], 16 - MatrixRank[Join[delta4, normRows[4]]]}
(* expected: {7, 9, 9, 0, 8} *)

(* ::CodeText:: *)
(*The detector on the canonical models and the pure-signaling box (contexts 0-3 answer 00 deterministically; context 4 answers 10: measurement 4 says 0 in context 3 and 1 in context 4 \[LongDash] a context-dependent marginal and nothing else). Exact arithmetic throughout; sectionExists is the R-linear (free-sign) solvability of M . d = e:*)

(* ::Input:: *)
sectionExists[M_, e_] := ListQ[Quiet[LinearSolve[M, e]]];
axis1Table = {#1, HarmonicResidual[delta5, #2], sectionExists[M5, #2]} & @@@
  {{"classical", eC}, {"quantum", eQ}, {"Wright", eW}, {"pure-signaling", ePureSig}};
TableForm[axis1Table, TableHeadings -> {None, {"model", "residual", "R-linear section?"}}]

(* ::Input:: *)
pureSigResidualSq = Total[(delta5 . ePureSig)^2]   (* exactly 2 *)

(* ::Text:: *)
(*Python-executed randomized layer (mirrored): 500 random signaling perturbations (one context block perturbed by 0.01-0.1, never in ker delta because a two-entry perturbation cannot be proportional to the local kernel direction (1, -1, -1, 1)) and 200 random no-disturbance models (mixtures of deterministic global distributions, noisy quantum, Wright blends); on every instance the three tests agreed: residual < 1e-9 <=> free-sign LP feasible <=> marginals consistent. GATE G1: PASS.*)

(* ::Section:: *)
(*3. Axis 2 \[LongDash] Contextuality-by-Default for Signaling Data*)

(* ::Text:: *)
(*The formula is PINNED from the primary source, not from memory. Kujala-Dzhafarov, "Proof of a Conjecture on Contextuality in Cyclic Systems with Binary Variables", Found. Phys. 46, 282-299 (2016), arXiv:1503.02181v4 (DOI 10.1007/s10701-015-9964-8), proving the conjecture of Dzhafarov-Kujala-Larsson, Found. Phys. 45, 762 (2015), arXiv:1411.2244: a cyclic-n system of +-1 variables, with V_i, W_i the two measurements of property q_i in its two contexts and bunches (V_i, W_{i+1}), is CONTEXTUAL iff*)
(*    s1(<V_i W_{i+1}> : i = 1..n) - Delta > n - 2,   Delta = Sum_i |<V_i> - <W_i>|,*)
(*where s1 = the maximum of Sum m_i x_i over sign vectors with an ODD number of -1 (their Eqs. 6/7/13); the measure is CNTX = Delta_min - Delta_0 = Max[s1 - Delta - (n - 2), 0]/2 (their Theorem 14). Their Theorem 13 proves this equivalent to the criterion s1(<V_i W_{i+1}>, 1 - |<V_i> - <W_i>| : i) <= 2n - 2 of Kujala-Dzhafarov-Larsson, PRL 115, 150401 (2015), arXiv:1412.4724 \[LongDash] the paper whose CbD reanalysis of the Lapkiewicz data confirms contextuality despite statistically significant inconsistent connectedness. Both forms are implemented and asserted equal on every instance below (and in Python).*)

(* ::Input:: *)
s1odd[xs_List] := Module[{t = Total[Abs[xs]], negs = Count[Sign[xs], -1]},
  FullSimplify@If[OddQ[negs], t, t - 2 Min[Abs[xs]]]];
cbd[e_List, n_Integer] := Module[{prods, vs, ws, delta, s1, margin},
  prods = Table[e[[4 c + 1]] - e[[4 c + 2]] - e[[4 c + 3]] + e[[4 c + 4]], {c, 0, n - 1}];
  vs = Table[e[[4 c + 1]] + e[[4 c + 2]] - e[[4 c + 3]] - e[[4 c + 4]], {c, 0, n - 1}];
  ws = RotateRight@Table[e[[4 c + 1]] - e[[4 c + 2]] + e[[4 c + 3]] - e[[4 c + 4]], {c, 0, n - 1}];
  (* Table entry c+1 is the 2nd-observable marginal of context c = measurement c+1 mod n;
     RotateRight aligns position m+1 with measurement m, matching vs *)
  delta = FullSimplify@Total[Abs[vs - ws]];
  s1 = s1odd[prods]; margin = FullSimplify[s1 - delta - (n - 2)];
  <|"s1" -> s1, "Delta" -> delta, "Margin" -> margin,
    "CNTX" -> FullSimplify@Max[margin, 0]/2, "Contextual" -> Simplify[margin > 0],
    "Criterion8Agrees" -> Simplify[(s1odd[Join[prods, 1 - Abs[vs - ws]]] > 2 n - 2) == (margin > 0)]|>];

(* ::CodeText:: *)
(*Exact rows. Quantum: Delta = 0, s1 = 4 Sqrt[5] - 5 \[LongDash] equivalently Sum <P_i> = (s1 + 5)/4 = Sqrt[5], the standard KCBS verdict \[LongDash] and CNTX = 2 Sqrt[5] - 4 = CF exactly. Classical: margin exactly 0 (the boundary). Wright: margin 2, CNTX 1. Pure-signaling: s1 = 5 but Delta = 2, margin exactly 0 \[LongDash] CbD books ALL its context-dependence as signaling, none as contextuality. PR box (C4): margin 2, CNTX 1:*)

(* ::Input:: *)
{cbdQ, cbdC, cbdW, cbdP} = cbd[#, 5] & /@ {eQ, eC, eW, ePureSig}; cbdPR = cbd[ePR, 4];
cbdLocks = <|
  "quantumS1" -> FullSimplify[cbdQ["s1"] - (4 Sqrt[5] - 5)] === 0,
  "quantumDelta0" -> cbdQ["Delta"] === 0,
  "quantumMargin" -> FullSimplify[cbdQ["Margin"] - (4 Sqrt[5] - 8)] === 0,
  "quantumSumP" -> FullSimplify[(cbdQ["s1"] + 5)/4 - Sqrt[5]] === 0,
  "classicalBoundary" -> cbdC["Margin"] === 0 && cbdC["Contextual"] === False,
  "wright" -> cbdW["Margin"] === 2 && cbdW["CNTX"] === 1,
  "pureSignalingAcquitted" -> cbdP["Margin"] === 0 && cbdP["Delta"] === 2 && cbdP["Contextual"] === False,
  "prBox" -> cbdPR["Margin"] === 2 && cbdPR["CNTX"] === 1|>

(* ::Text:: *)
(*The Lapkiewicz-realistic reconstruction, honestly. Published aggregates (Nature 474, 490 (2011)): Sigma = -3.893(6) and eps = 1 - <A1 A1'> = 0.081(2). Five per-edge correlations are NOT recoverable from two aggregates \[LongDash] under-determined \[LongDash] so per the pre-registration the analysis runs on the kcbs_simulation.py noise model at V = 0.977 (per-event p = V/Sqrt[5] + (1 - V)/3, correlations 1 - 2(p_i + p_j)) with the closing-context marginal shifted by eps/2: Delta = 2 |p - p'| = eps is the MAXIMAL context-dependent-marginal reading of the published eps, since Delta = |<A1> - <A1'>| <= 2 P(A1 != A1') = eps. Both shift directions are computed (they bracket the measured Sigma: -3.811 and -3.973 around -3.893), plus a visibility calibrated to reproduce Sigma = -3.893 exactly (V = 0.9419). In all three the verdict is CONTEXTUAL and the CbD margin is the Delta-ignoring margin minus exactly eps:*)

(* ::Input:: *)
lapkModel[V_, eps_, sgn_] := Module[{p = V/Sqrt[5.] + (1 - V)/3, pp},
  pp = p + sgn eps/2;
  Flatten[{Table[{1 - 2 p, p, p, 0}, {4}], {{1 - p - pp, pp, p, 0}}}]];
lapkRows = With[{eps = 0.081},
  Table[Module[{e = lapkModel[r[[1]], eps, r[[2]]], c},
    c = cbd[e, 5];
    {r[[3]], Total@Table[e[[4 k + 1]] - e[[4 k + 2]] - e[[4 k + 3]] + e[[4 k + 4]], {k, 0, 4}],
     c["Delta"], c["Margin"], c["Margin"] + eps, c["Contextual"]}],
   {r, {{0.977, -1, "V=0.977, p'=p-eps/2"}, {0.977, +1, "V=0.977, p'=p+eps/2"},
        {0.941926, +1, "V calibrated to Sigma=-3.893"}}}]];
TableForm[lapkRows, TableHeadings -> {None, {"variant", "Sigma", "Delta", "margin(CbD)", "margin(Delta ignored)", "contextual?"}}]
(* Python-verified values: margins {0.7299, 0.8919, 0.8120}, Delta = eps = 0.081 in each, all contextual: GATE G2 PASS *)

(* ::Section:: *)
(*4. Axis 3 \[LongDash] Communication Cost: Two Linear Programs*)

(* ::Text:: *)
(*LP (a), the signaling fraction: the minimal lambda with e = (1 - lambda) e_NC + lambda e_free, where the free part is an ARBITRARY normalized table (the full signaling polytope). Because the free part absorbs anything, the constraint set is exactly the noncontextual-fraction LP's: SF = 1 - NCF = CF whenever e is no-disturbance, and SF remains well-defined (a COST, not a contextuality measure) when e signals. The exact value for the quantum pentagon, by the paclet's LP in exact arithmetic and by an exact primal/dual certificate pair:*)

(* ::Input:: *)
sfQuantumExact = FullSimplify[ContextualFraction[scen5, eQ, WorkingPrecision -> Infinity]];
{sfQuantumExact, FullSimplify[sfQuantumExact - (2 Sqrt[5] - 4)] === 0}

(* ::CodeText:: *)
(*The certificate pair, verified: primal = weight 1 - 2/Sqrt[5] on each of the five non-adjacent-pair assignments (value 5 - 2 Sqrt[5]); dual = the functional y = (1, 0, 0, 1) per context \[LongDash] every deterministic assignment hits at least one 00 or 11 section because the odd cycle has no proper 2-coloring \[LongDash] with y . eQ = 5 - 2 Sqrt[5]. Primal value = dual value pinches NCF = 5 - 2 Sqrt[5], SF = CF = 2 Sqrt[5] - 4, an algebraic identity:*)

(* ::Input:: *)
glob5 = scen5["Assignments"];
pairIdx = Flatten@Position[glob5, g_ /; Total[g] == 2 && And @@ Table[g[[i]] g[[Mod[i, 5] + 1]] == 0, {i, 5}], {1}, Heads -> False];
dStar = SparseArray[Thread[pairIdx -> (1 - 2/Sqrt[5])], 32] // Normal;
yDual = Flatten[ConstantArray[{1, 0, 0, 1}, 5]];
certificates = <|
  "primalFeasible" -> Min[Sign[FullSimplify[eQ - M5 . dStar]]] >= 0,
  "primalValue" -> FullSimplify[Total[dStar] - (5 - 2 Sqrt[5])] === 0,
  "dualFeasible" -> Min[yDual . M5] >= 1,
  "dualValue" -> FullSimplify[yDual . eQ - (5 - 2 Sqrt[5])] === 0|>

(* ::CodeText:: *)
(*The other exemplars, exact: Wright, PR and the pure-signaling box have SF = 1 by zero-section dual certificates (y = 1 on every zero-probability section; every assignment is blocked), and the classical model has SF = 0 (it IS a global distribution: uniform on the five pairs):*)

(* ::Input:: *)
zeroDualCovers[M_, e_] := Module[{z = Flatten@Position[e, 0]},
  AllTrue[Range[Dimensions[M][[2]]], Total[M[[z, #]]] >= 1 &]];
sfOne = {zeroDualCovers[M5, eW], zeroDualCovers[M4, ePR], zeroDualCovers[M5, ePureSig]};
classicalGlobal = M5 . Normal[SparseArray[Thread[pairIdx -> 1/5], 32]] === eC;
{sfOne, classicalGlobal}

(* ::Text:: *)
(*LP (b), the one-bit communication model. Formalization: in the C5 game a round presents a context {i, i+1}; measurement i appears in two contexts, and the one bit per round tells each measurement WHICH neighbour it is being paired with (the context label of the shared observable's other neighbour \[LongDash] operationally, whether the Lapkiewicz waveplate configuration is the one to its left or to its right). A deterministic 1-bit strategy is a pair (x, y) in {0,1}^5 x {0,1}^5: measurement i answers x_i as first observable (context i) and y_i as second (context i-1); context i then carries the deterministic section (x_i, y_{i+1}). PROPOSITION (proof by bijection, machine-checked): the 4^5 = 1024 strategies are in bijection with ALL deterministic tables (each context's section is freely and independently determined), so their convex hull is the FULL table polytope. COROLLARY: any table \[LongDash] quantum, supra-quantum or signaling \[LongDash] becomes reproducible with the bit on every round, and the minimal bit-fraction mu (mixing 0-bit noncontextual strategies with 1-bit strategies) equals SF: mu >= SF because dropping the strategy structure leaves the SF constraint set; mu <= SF because the SF-optimal residual is a normalized table, hence in the hull. No large LP is needed in the kernel; Python ran it anyway (float): mu(quantum) = 0.4721359550 = 2 Sqrt[5] - 4 to 2e-16.*)

(* ::CodeText:: *)
(*The witness, fully explicit and exact \[LongDash] the algebraic heart of the axis: the quantum-maximal table is EXACTLY the CF-optimal mixture of the classical-maximal model (0 bits: uniform over the five pair-assignments) and the Wright box (1 bit: uniform over the 32 strategies x arbitrary, y_j = 1 - x_{j-1}, whose sections alternate 01/10):*)

(* ::Input:: *)
decompositionIdentity = FullSimplify[eQ - ((5 - 2 Sqrt[5]) eC + (2 Sqrt[5] - 4) eW)] === ConstantArray[0, 20];
secIdx[{a_, b_}] := 2 a + b + 1;
wrightMix = Total@Table[Module[{y = Table[1 - x[[Mod[j - 2, 5] + 1]], {j, 5}], col = ConstantArray[0, 20]},
     Do[col[[4 c + secIdx[{x[[c + 1]], y[[Mod[c + 1, 5] + 1]]}]]] = 1, {c, 0, 4}]; col],
    {x, Tuples[{0, 1}, 5]}]/32;
{decompositionIdentity, wrightMix === eW}

(* ::CodeText:: *)
(*Cross-check on CHSH: the PR box needs the bit EVERY round (mu = 1 = SF), witnessed by two strategies \[LongDash] x = 0000 with y = 1000, and its global flip:*)

(* ::Input:: *)
prStrategy[x_, y_] := Module[{col = ConstantArray[0, 16]},
  Do[col[[4 c + secIdx[{x[[c + 1]], y[[Mod[c + 1, 4] + 1]]}]]] = 1, {c, 0, 3}]; col];
prWitness = (prStrategy[{0, 0, 0, 0}, {1, 0, 0, 0}] + prStrategy[{1, 1, 1, 1}, {0, 1, 1, 1}])/2 === ePR

(* ::Text:: *)
(*Python float-LP layer (mirrored literals from the executed run): SF(quantum) = 0.4721359550 (|diff to 2 Sqrt[5] - 4| = 2e-16); SF(Tsirelson C4 table) = 0.4142135624 = Sqrt[2] - 1; SF(Lapkiewicz-realistic, +eps/2) = mu = 0.486443; mu(PR) = 1.0000000000. Note the Tsirelson caution: Sqrt[2] - 1 average bits reproduces the four-context TABLE; it is not the Toner-Bacon protocol (PRL 91, 187904 (2003)), which spends 1 bit on EVERY round to simulate the singlet for ALL measurement directions \[LongDash] table simulation and state simulation are different tasks, and only the former is priced here. GATE G3: PASS.*)

(* ::Section:: *)
(*5. Synthesis \[LongDash] the Extended Taxonomy*)

(* ::Text:: *)
(*Three axes, each with its own jurisdiction: Axis 1 (theorem-backed detector): signaling <=> nonzero harmonic residual <=> no R-linear global section \[LongDash] the REJECTED tool is the canonical detector of the stratum it was rejected for missing. Axis 2 (classifier): the CbD verdict and measure CNTX, defined FOR signaling data, reducing exactly to the standard taxonomy at Delta = 0 (CNTX = CF on the quantum pentagon, exact). Axis 3 (price): SF and the bit-rate mu = SF, the communication a classical emulation needs. The computed strata table (Python, all rows verified):*)

(* ::Text:: *)
(*  model                 ||delta e||  Delta   margin   CNTX   CbD?   SF      mu      stratum*)
(*  C5 classical            0        0       0        0      no     0       0       S0 classical*)
(*  C5 quantum              0        0       0.9443   0.4721 yes    0.4721  0.4721  S1 contextual*)
(*  C5 Wright box           0        0       2        1      yes    1       1       S2 strongly contextual*)
(*  CHSH Tsirelson          0        0       0.8284   0.4142 yes    0.4142  0.4142  S1 contextual*)
(*  CHSH PR box             0        0       2        1      yes    1       1       S2 strongly contextual*)
(*  C5 pure-signaling       1.4142   2       0        0      no     1       1       S3 pure-signaling*)
(*  C5 Lapkiewicz-real.     0.0573   0.081   0.8919   0.4459 yes    0.4864  0.4864  S4 contextual despite signaling*)

(* ::Text:: *)
(*Readings. (i) SF alone cannot tell the PR box from the boring deterministic signaling box \[LongDash] both cost 1 \[LongDash] which is exactly why the axes must not be collapsed; the impossibility theorem of Tezzin-Wolfe-Amaral-Jones (arXiv:2212.06976) makes this structural: no single extension of contextuality to disturbing systems satisfies determinism-noncontextuality, marginal-monotonicity, post-processing-monotonicity and independent-composition at once. CbD keeps the first (our deterministic signaling box is CbD-noncontextual, margin exactly 0) at the documented price of the others. (ii) On the no-disturbance rows CNTX = SF exactly \[LongDash] two definitions, one number, an exact lock between Axis 2 and Axis 3. On the signaling rows they diverge (0 vs 1; 0.4459 vs 0.4864 = CNTX + Delta/2): SF pays for signaling in full, CNTX discounts it. A 200-random-table probe (Python) REFUTES the candidate identity SF = Delta_min in general (max gap 2.0; Delta_min is not even bounded by 1) \[LongDash] the agreement on all seven exemplar rows is a property of the low-signaling KCBS-like corner, recorded as an open question, not claimed as a theorem. (iii) Scope of the phrase "extending the taxonomy": the Ulrey census that the sheaf notes cross-validate against is EPRB-bound \[LongDash] its dividing lines live on the CHSH cover \[LongDash] whereas the strata above are scenario-unbound: every classifier used (residual, CbD-cyclic, SF, mu) is defined for any cyclic rank and, except the pinned CbD closed form, for arbitrary covers.*)

(* ::Text:: *)
(*Feasibility verdict for the project question ("can the correlation taxonomy be extended to signaling and quantum-communication scenarios?"): YES for cyclic scenarios, with the division of labor above; the load-bearing parts are one reused theorem (AB 5.9, which makes the rejected Laplacian the signaling detector at zero new cost), one pinned literature formula (the KD cyclic criterion), and three LPs, all executed exactly where the models are algebraic. What remains OPEN, stated precisely: (a) CbD closed forms beyond cyclic covers \[LongDash] the GHZ/AvN layer of SupportCohomology.wl has no Delta-corrected analogue here; (b) the general relation between SF and Delta_min (refuted as an identity, unexplored as an inequality/geometry); (c) the quantum-CHANNEL side of "quantum-communication scenarios": CaseStudies.wl Case A already computes the zero-error bridge Theta(C5) = Sqrt[5] = LovaszTheta (Shannon capacity of the pentagon channel, Lovasz 1979), and mu prices one-shot classical simulation of the C5 table \[LongDash] but a capacity-style asymptotic theory of the signaling strata (bits per round under many uses, composition of strategy polytopes under the OR product, a signaling analogue of Theta) is not formalized here; (d) extending the exact certificate layer to inconsistently-connected quantifiers in the literature (Amaral-Duarte, PRA 100, 062103 (2019), arXiv:1902.02413) \[LongDash] their graph-approach quantifiers should meet Axis 3's LPs on the C5 exemplars, a natural next verification.*)

(* ::Section:: *)
(*6. Verification*)

(* ::Text:: *)
(*House discipline: every claim above, machine-checked in one association; entries marked pythonMirror are literals pinned from the executed signaling_taxonomy.py run (10 July 2026, seeds 20260710/7, gates G1 G2 G3 all PASS, exit 0) and re-asserted here as facts of that run; everything else recomputes in this kernel. This cell must print OK -> True.*)

(* ::Input:: *)
lapkOK = And @@ Table[Abs[lapkRows[[k, 4]] - {0.7299, 0.8919, 0.8120}[[k]]] < 10^-3 && lapkRows[[k, 6]], {k, 3}];
SignalingTaxonomyVerification = <|
  "axis1RankLedgerC5" -> rankLedger5 === {9, 11, 11, 0, 10},
  "axis1RankLedgerC4" -> rankLedger4 === {7, 9, 9, 0, 8},
  "axis1KernelEqualsAffineHullPlusOne" -> rankLedger5[[2]] == rankLedger5[[5]] + 1 && rankLedger4[[2]] == rankLedger4[[5]] + 1,
  "axis1ImMEqualsKerDelta" -> rankLedger5[[3]] == rankLedger5[[2]] && rankLedger5[[4]] == 0,
  "axis1CanonicalNoDisturbance" -> And @@ (FullSimplify[HarmonicResidual[delta5, #]] === 0 & /@ {eC, eQ, eW}) &&
     And @@ (sectionExists[M5, #] & /@ {eC, eQ, eW}),
  "axis1PureSignalingConvicted" -> pureSigResidualSq === 2 && ! sectionExists[M5, ePureSig],
  "axis1RandomEquivalence700Instances" -> True (* pythonMirror: 500 signaling + 200 ND, three-way agreement on all *),
  "axis2QuantumReducesToKCBS" -> cbdLocks["quantumS1"] && cbdLocks["quantumDelta0"] &&
     cbdLocks["quantumMargin"] && cbdLocks["quantumSumP"],
  "axis2CNTXEqualsCFExactly" -> FullSimplify[cbdQ["CNTX"] - sfQuantumExact] === 0,
  "axis2ClassicalBoundary" -> cbdLocks["classicalBoundary"],
  "axis2WrightAndPR" -> cbdLocks["wright"] && cbdLocks["prBox"],
  "axis2PureSignalingAcquitted" -> cbdLocks["pureSignalingAcquitted"],
  "axis2Criterion8AgreesEverywhere" -> And @@ (TrueQ[#["Criterion8Agrees"]] & /@ {cbdQ, cbdC, cbdW, cbdP, cbdPR}),
  "axis2LapkiewiczContextualMarginReducedByEps" -> lapkOK,
  "axis3SFQuantumExact" -> FullSimplify[sfQuantumExact - (2 Sqrt[5] - 4)] === 0 && And @@ Values[certificates],
  "axis3SFOnesExact" -> And @@ sfOne,
  "axis3SFClassicalZero" -> classicalGlobal,
  "axis3SFQuantumFloatLP" -> True (* pythonMirror: 0.4721359550, |diff| = 2.2e-16 *),
  "axis3SFTsirelsonFloatLP" -> Abs[(1 - NoncontextualFraction[scen4, N@Flatten[Table[
        {(1 + c)/4, (1 - c)/4, (1 - c)/4, (1 + c)/4}, {c, {1, 1, 1, -1}/Sqrt[2.]}]]) - (Sqrt[2.] - 1)] < 10^-6,
  "axis3StrategiesSpanEverything" -> Sort[Flatten[Table[Module[{col = ConstantArray[0, 20]},
        Do[col[[4 c + secIdx[{x[[c + 1]], y[[Mod[c + 1, 5] + 1]]}]]] = 1, {c, 0, 4}]; col],
       {x, Tuples[{0, 1}, 5]}, {y, Tuples[{0, 1}, 5]}], 1]] ===
     Sort[Table[Flatten[Table[If[k == s[[c + 1]], 1, 0], {c, 0, 4}, {k, 0, 3}]],
       {s, Tuples[Range[0, 3], 5]}]],
  "axis3DecompositionIdentity" -> decompositionIdentity,
  "axis3WrightIsOneBitMixture" -> wrightMix === eW,
  "axis3PRWitness" -> prWitness,
  "axis3MuEqualsSF" -> True (* proposition (hull = full polytope) + pythonMirror: mu(quantum) = 0.4721359550, mu(PR) = 1, mu(realistic) = SF(realistic) = 0.486443 *),
  "obsSFvsDeltaMinRefutedGenerically" -> True (* pythonMirror: identity holds on all 7 exemplar rows, max gap 2.015 over 200 random tables -> not a theorem; open *),
  "gates" -> "G1 PASS | G2 PASS | G3 PASS (signaling_taxonomy.py, 2026-07-10, exit 0)"
|>;
SignalingTaxonomyVerification["OK"] = And @@ Cases[Values[SignalingTaxonomyVerification], _?BooleanQ];
SignalingTaxonomyVerification

(* ::Section:: *)
(*References*)

(* ::Item:: *)
(*S. Abramsky, A. Brandenburger, New J. Phys. 13, 113036 (2011); arXiv:1102.0264 (Theorem 5.9: R-linear global sections = no-signalling; Prop. 5.7: incidence rank 2n + 1).*)

(* ::Item:: *)
(*J. V. Kujala, E. N. Dzhafarov, Found. Phys. 46, 282-299 (2016); arXiv:1503.02181; DOI 10.1007/s10701-015-9964-8 (the pinned cyclic criterion and CNTX formula, Eqs. 6/7/13, Thms. 13-14).*)

(* ::Item:: *)
(*J. V. Kujala, E. N. Dzhafarov, J.-\[CapitalARing]. Larsson, Phys. Rev. Lett. 115, 150401 (2015); arXiv:1412.4724 (criterion (8); CbD reanalysis of the Lapkiewicz data).*)

(* ::Item:: *)
(*E. N. Dzhafarov, J. V. Kujala, J.-\[CapitalARing]. Larsson, Found. Phys. 45, 762-782 (2015); arXiv:1411.2244 (the conjecture; Contextuality-by-Default).*)

(* ::Item:: *)
(*R. Lapkiewicz et al., Nature 474, 490 (2011); DOI 10.1038/nature10119 (Sigma = -3.893(6), eps = 0.081(2)).*)

(* ::Item:: *)
(*S. Abramsky, R. S. Barbosa, S. Mansfield, Phys. Rev. Lett. 119, 050504 (2017); arXiv:1705.07918 (the contextual fraction LP).*)

(* ::Item:: *)
(*J. Hansen, R. Ghrist, J. Appl. Comput. Topol. 3 (2019); arXiv:1808.01513 (the cellular-sheaf coboundary behind HarmonicResidual).*)

(* ::Item:: *)
(*A. Tezzin, E. Wolfe, B. Amaral, M. Jones, arXiv:2212.06976 (impossibility of a single all-desiderata contextuality measure for disturbing systems).*)

(* ::Item:: *)
(*B. Amaral, C. Duarte, Phys. Rev. A 100, 062103 (2019); arXiv:1902.02413 (graph-approach quantifiers of extended contextuality; open item (d)).*)

(* ::Item:: *)
(*B. F. Toner, D. Bacon, Phys. Rev. Lett. 91, 187904 (2003) (one bit simulates the singlet: the state-simulation contrast to LP (b)).*)

(* ::Item:: *)
(*L. Lov\[AAcute]sz, IEEE Trans. Inf. Theory 25, 1 (1979); A. Cabello, S. Severini, A. Winter, arXiv:1010.2163 (Theta(C5) = Sqrt[5]: the zero-error quantum-communication bridge of CaseStudies.wl Case A).*)
