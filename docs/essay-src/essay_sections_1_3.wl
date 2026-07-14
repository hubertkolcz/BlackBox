(* ::Package:: *)

(* ::Title:: *)
(*Evaluating Black-Box Physics through Optical Emulation \[LongDash] Sections 1-3*)

(* ::Subtitle:: *)
(*Section builder A: the pentagon atom, the certification protocol and its located blind spot, and the two irreducible lenses \[LongDash] every number computed live*)

(* ::Text:: *)
(*Hubert Ko\[LSlash]cz \[LongDash] July 2026. This file supplies sections S1\[Dash]S3 of the master computational essay EvaluatingBlackBoxPhysics.wl (spine: docs/ESSAY-OUTLINE.md; framework labeling: docs/FRAMEWORK-2026-07-13.md). It follows the cell grammar and Get-safety of 01-D2-core-computation/CertifyingQuantumness.wl. THE PRIME DIRECTIVE (WSRI): every quantitative claim below is produced by the kernel at evaluation time \[LongDash] via the HubertKolcz`BlackBox` paclet or an inline recomputation of the pre-registered probe mathematics \[LongDash] never hand-restated. Each section closes with a sectionNCheck association; the file ends with a sectionsVerification block printing OK -> True.*)

(* ::Text:: *)
(*Labeling discipline (mirrors the framework): [T] theorem / machine-verified, [C] certified numeric, [R] refuted route, [H] named hypothesis. Layer-2 statements carry their hypothesis tag inline.*)

(* ::CodeText:: *)
(*Locate the repo root robustly by walking up to the BlackBox paclet marker -- works whether opened as a notebook (NotebookDirectory[]) or Get-loaded headless ($InputFileName) -- then load the library, repair any Global`-shadowing, and record the repo root for the figure/probe artifacts.*)

(* ::Input:: *)
repoRoot = Module[
   {ref, start, localRoot, base, cacheRoot, manifest, dest, res, tries, strm},
   ref = If[StringQ[$BlackBoxRef] && $BlackBoxRef =!= "", $BlackBoxRef, "master"];
   start = With[{f = $InputFileName},
     If[StringQ[f] && f =!= "" && FileExistsQ[f], DirectoryName[f],
       Quiet@Check[NotebookDirectory[], Directory[]]]];
   If[! StringQ[start] || start === "", start = Directory[]];
   localRoot = NestWhile[ParentDirectory, start,
     (# =!= ParentDirectory[#]) &&
       ! FileExistsQ[FileNameJoin[{#, "BlackBox", "PacletInfo.wl"}]] &];
   If[FileExistsQ[FileNameJoin[{localRoot, "BlackBox", "PacletInfo.wl"}]],
     localRoot,
     base = "https://raw.githubusercontent.com/hubertkolcz/BlackBox/" <> ref <> "/";
     cacheRoot = FileNameJoin[{$UserBaseDirectory, "ApplicationData", "BlackBoxEssay", ref}];
     Quiet@CreateDirectory[cacheRoot, CreateIntermediateDirectories -> True];
     If[! DirectoryQ[cacheRoot],
       cacheRoot = FileNameJoin[{$TemporaryDirectory, "BlackBoxEssay", ref}];
       Quiet@CreateDirectory[cacheRoot, CreateIntermediateDirectories -> True]];
     manifest = {"BlackBox/PacletInfo.wl", "BlackBox/Kernel/BlackBox.wl",
       "docs/essay-src/essay_sections_1_3.wl", "docs/essay-src/essay_sections_4_6.wl",
       "docs/essay-src/essay_sections_7_10.wl",
       "09-EMU-optical-compiler/OpticalCompiler.wl", "09-EMU-optical-compiler/DispatcherEmitter.wl",
       "09-EMU-optical-compiler/InterferometerLayer.wl", "09-EMU-optical-compiler/IntensityLayer.wl",
       "05-CERT-epsilon-certificates/EpsilonCertificate7_regenerated.wl",
       "05-CERT-epsilon-certificates/EpsilonCertificate8_regenerated.wl",
       "05-CERT-epsilon-certificates/EpsilonCertificate9.wl",
       "08-HK-hawking/hawking_gaussian_sector.wl", "08-HK-hawking/gaussian_engine.wl",
       "08-HK-hawking/gaussian_hawking_physics.wl", "08-HK-hawking/gaussian_witnesses_bridge.wl",
       "06-D3-sheaf-cohomology/final_h1_cocycle_results.json",
       "02-D1-theory-frontier/erg003_verdict.json", "docs/FRAMEWORK-2026-07-13.md",
       "09-EMU-optical-compiler/schematics/demo1_kcbs_pentagon_L1.png",
       "09-EMU-optical-compiler/schematics/demo3_cct_mesh_reps2.png",
       "00-BBT-blackbox-protocol/certification_map.png",
       "05-CERT-epsilon-certificates/orbit_spectrum.png"};
     Do[dest = FileNameJoin[Prepend[FileNameSplit[rel], cacheRoot]];
       If[! (FileExistsQ[dest] && FileByteCount[dest] > 0),
         Quiet@CreateDirectory[DirectoryName[dest], CreateIntermediateDirectories -> True];
         tries = 0;
         While[! (FileExistsQ[dest] && FileByteCount[dest] > 0) && tries < 3,
           tries++;
           res = Quiet@Check[URLRead[base <> rel, {"StatusCode", "BodyByteArray"}], $Failed];
           If[AssociationQ[res] && res["StatusCode"] === 200 &&
                ByteArrayQ[res["BodyByteArray"]] && Length[res["BodyByteArray"]] > 8 &&
                ! StringStartsQ[ToUpperCase@Quiet@Check[
                    FromCharacterCode@Normal@Take[res["BodyByteArray"], UpTo[14]], "?"],
                  "<!DOCTYPE" | "<HTML"],
             Quiet[strm = OpenWrite[dest, BinaryFormat -> True];
               BinaryWrite[strm, res["BodyByteArray"]]; Close[strm]]]]],
       {rel, manifest}];
     cacheRoot]];
PacletDirectoryLoad[FileNameJoin[{repoRoot, "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"]; Quiet[Remove /@ Select["Global`" <> # & /@ Names["HubertKolcz`BlackBox`*"], NameQ]];
Names["HubertKolcz`BlackBox`*"]

(* ::Section:: *)
(*S0  Summary of Results (sections 1-3)*)

(* ::Item:: *)
(*[T] The pentagon atom carries a strict hierarchy of three graph invariants \[LongDash] classical \[Alpha] = 2 < quantum \[CurlyTheta] = Sqrt[5] < exclusivity-only \[Alpha]* = 5/2 \[LongDash] reproduced live by {IndependenceNumber, LovaszTheta, FractionalPackingNumber}[CycleGraph[5]] and cross-checked against Wolfram's curated GraphData; the five exact pentagram axes sum to Sqrt[5] on the cone axis (KCBSDirections).*)

(* ::Item:: *)
(*[T] The located blind spot (Proposition 1, BBT-002, assumptions A1-A4): a tuned intensity emulator reproduces the quantum table exactly \[LongDash] the two 20-vectors are identical in exact arithmetic \[LongDash] so every table functional, including the contextual fraction 2 Sqrt[5] - 4, takes the same value on both. Distinguishing them from table access is mathematically impossible, not merely hard.*)

(* ::Item:: *)
(*[T] Two lenses, necessarily (Proposition 2, BBT-003): the KCBS cascade generators span a 2-plane of so(3) and close to the full algebra at commutator depth one (DLA dim 3), while a leaf-confined rig has DLA < 3 \[LongDash] identical tables, different DLA, so no table functional lower-bounds the DLA.*)

(* ::Item:: *)
(*[T]/[C] The access staircase: interventional table access separates the DLA-3 cascade from the \[Theta]-blind emulator (orbit-Jacobian rank 2 vs 0, recomputed live from the analytic \[Theta] = 0 anchor); attenuation/event-semantics (gate G8) flags the coherent forger with exact deviation D_max \[TildeTilde] 56 t_max (recomputed live), the deterministic core of the pre-registered 25/25 sampled result.*)

(* ::Item:: *)
(*[T]/[C] The CV column (G7-CV / F11): the symplectic leaf-confinement audit closes exactly \[LongDash] passive linear optics u(2) dim 4 (confined) vs active sp(4,R) dim 10 and sp(2,R) dim 3 \[LongDash] via an inline exact Lie closure, filling the Gaussian cell of the certification map.*)

(* ::Section:: *)
(*S1  The Question and the Pentagon Atom (F1)*)

(* ::Text:: *)
(*The central question (RESEARCH.md / Objective O3): given only black-box access, under what conditions is it mathematically impossible to distinguish a genuinely quantum device from a classical optical emulation at the level of input-output behavior? The essay answers by structuring certification as two provably irreducible lenses \[LongDash] a correlation lens (graph invariants of measurement statistics) and a geometric lens (the dynamical Lie algebra pricing resource scaling). Everything begins with one graph: the exclusivity graph of the KCBS pentagon (Klyachko-Can-Binicio\[GBreve]lu-Shumovsky, PRL 101, 020403 (2008)) \[LongDash] the 5-cycle.*)

(* ::Input:: *)
pentagon = CycleGraph[5];

(* ::CodeText:: *)
(*Three theories, three graph invariants (Cabello-Severini-Winter, arXiv:1010.2163): a deterministic hidden-variable model reaches the independence number \[Alpha]; quantum mechanics reaches the Lov\[AAcute]sz number \[CurlyTheta] by semidefinite programming; an exclusivity-only theory reaches the fractional packing number \[Alpha]*. The strict hierarchy 2 < Sqrt[5] < 5/2 is the contextuality resource. [T]*)

(* ::Input:: *)
atomHierarchy = {IndependenceNumber[pentagon], LovaszTheta[pentagon], FractionalPackingNumber[pentagon]}

(* ::CodeText:: *)
(*Wolfram's curated graph data supplies the same three values exactly \[LongDash] a free oracle cross-check for the library:*)

(* ::Input:: *)
atomOracle = GraphData[{"Cycle", 5}, #] & /@ {"IndependenceNumber", "LovaszNumber", "FractionalChromaticNumber"}

(* ::CodeText:: *)
(*The quantum value is physical, not a fitting parameter: the five exact pentagram directions are cyclically orthogonal and their squared projections on the cone axis {0,0,1} sum to Sqrt[5] (Simplify, exact):*)

(* ::Input:: *)
atomAxisSum = Simplify[Total[(#.{0, 0, 1})^2 & /@ KCBSDirections[]]]

(* ::CodeText:: *)
(*Section 1 check: the strict hierarchy, the exact oracle agreement, and the axis-sum identity.*)

(* ::Input:: *)
section1Check = <|
   "hierarchyStrict" -> IndependenceNumber[pentagon] == 2 && FractionalPackingNumber[pentagon] == 5/2 &&
      Abs[LovaszTheta[pentagon] - Sqrt[5.]] < 10^-6 && 2 < Sqrt[5.] < 5/2,
   "oracleExact" -> GraphData[{"Cycle", 5}, "LovaszNumber"] === Sqrt[5] &&
      GraphData[{"Cycle", 5}, "IndependenceNumber"] === 2,
   "axisSumSqrt5" -> Simplify[atomAxisSum - Sqrt[5]] === 0
   |>;
Column[{section1Check, "S1 OK" -> And @@ Values[section1Check]}]

(* ::Section:: *)
(*S2  The Certification Protocol and its Located Blind Spot (BBT-001/002, Proposition 1)*)

(* ::Text:: *)
(*The protocol (00-BBT-blackbox-protocol/mbqc_blackbox_test.py; PROPOSITION-O3.md) consumes a table T = {p_c(ab)}: per-context outcome distributions on the pentagon, sections (00, 01, 10, 11) with the (1,1) event structurally absent (one photon, one click). Gates C1-C5 test no-disturbance, the contextual fraction, consistent exclusivity, possibilistic support, and the node sum. Proposition 1 (BBT-002) locates an exact blind spot.*)

(* ::Text:: *)
(*Proposition 1 (table-level indistinguishability). Let T be any no-disturbance pentagon table with per-context fractions summing to \[LessEqual] 1 (in particular the quantum-optimal table, t = 1/Sqrt[5], \[Delta] = 0). Then an intensity emulator E(T) \[LongDash] classical light divided per context, reporting normalized intensity fractions (f00, f01, f10) = (1 - 2t, t - \[Delta], t + \[Delta]) as click probabilities \[LongDash] produces T exactly in every context. Hence for every sample size and every statistic of the empirical table, E(T) and any quantum device realizing T are identically distributed. [T] Assumptions (each an escape route when dropped): (A1) per-context table access only; (A2) event semantics unverified; (A3) no audit of the internal compilation; (A4) fresh preparation per trial.*)

(* ::CodeText:: *)
(*The quantum-optimal table (per-event probability cos(Pi/5)/(1 + cos(Pi/5)) = 1/Sqrt[5]) as the paclet's canonical model vector, and the intensity emulator built independently from its classical fractions at t = 1/Sqrt[5], \[Delta] = 0:*)

(* ::Input:: *)
quantumTable = CycleModel[5, "Quantum"];
intensityEmulatorTable[t_, delta_: 0] := Flatten[ConstantArray[{1 - 2 t, t - delta, t + delta, 0}, 5]];
emulatorTable = intensityEmulatorTable[1/Sqrt[5], 0];

(* ::CodeText:: *)
(*The blind spot, exactly: the emulator table and the quantum table are the same 20-vector (difference identically zero in exact arithmetic) \[LongDash] Proposition 1 is a construction, not an approximation:*)

(* ::Input:: *)
blindSpotDelta = Simplify[emulatorTable - quantumTable]

(* ::CodeText:: *)
(*Consequently every table functional agrees on the two devices. The contextual fraction (Abramsky-Barbosa-Mansfield, PRL 119, 050504 (2017)) of the shared table, in exact arithmetic, is 2 Sqrt[5] - 4 \[TildeTilde] 0.472 \[LongDash] the same value the protocol reads under verdict QUANTUM-CERTIFIED for the emulator (a false positive by design):*)

(* ::Input:: *)
sharedCF = FullSimplify[ContextualFraction[CycleScenario[5], quantumTable, WorkingPrecision -> Infinity]]

(* ::Text:: *)
(*External anchors (cited, not recomputed): classical fields reaching the quantum bounds is experimental fact (Frustaglia et al., PRL 116, 250404 (2016); Zhang et al., Sci. Rep. 7, 44467 (2017)); a single unmodified on-off detector's click record is coherent-state-forgeable (Kovtoniuk-Bohmann-Semenov, arXiv:2601.13869 (2026)).*)

(* ::CodeText:: *)
(*Section 2 check: the emulator/quantum table identity (the blind spot), the shared exact contextual fraction, and that the KCBS node sum \[Sigma] = Sum of the five per-event click probabilities (the p10 entry of each context block) reaches the quantum value Sqrt[5], strictly below the exclusivity cap 5/2 \[LongDash] the gap 5/2 - Sqrt[5] is exactly the room that lets the intensity forger sit at the quantum point.*)

(* ::Input:: *)
emulatorNodeSum = Simplify[Total[emulatorTable[[3 ;; ;; 4]]]];
section2Check = <|
   "blindSpotIdentity" -> blindSpotDelta === ConstantArray[0, 20] &&
      Simplify[emulatorTable - CycleModel[5, "Quantum"]] === ConstantArray[0, 20],
   "sharedCFexact" -> FullSimplify[sharedCF - (2 Sqrt[5] - 4)] === 0,
   "nodeSumQuantum" -> Simplify[emulatorNodeSum - Sqrt[5]] === 0 && Sqrt[5] < 5/2
   |>;
Column[{section2Check, "S2 OK" -> And @@ Values[section2Check]}]

(* ::Section:: *)
(*S3  Two Lenses, Necessarily (Proposition 2/BBT-003; G7, OQ1, OQ2, G7-CV)*)

(* ::Text:: *)
(*Proposition 2 (BBT-003). No function of the table can lower-bound the device's DLA dimension: by Proposition 1 there exist two devices with identical tables \[LongDash] the quantum cascade (DLA = 3) and the tuned intensity rig (DLA < 3) \[LongDash] so every table functional takes the same value on both. [T] Hence certification is irreducibly two-lens: correlation lens + geometric/dynamics lens, neither derivable from the other.*)

(* ::CodeText:: *)
(*The geometric lens G7 (Corollary 2). The Lapkiewicz cascade (Nature 474, 490 (2011)) walks one photon through four two-mode rotations; the four so(3) stage generators rotate about only two axes, yet one commutator closes the full three-dimensional algebra \[LongDash] DLA dimension 3, the "2 -> 3 anchor". A leaf-confined intensity rig compiles to co-axial generators with DLA < 3.*)

(* ::Input:: *)
cascadeGens = CascadeGenerators[];
g7AxisRank = MatrixRank[So3Axis /@ cascadeGens, Tolerance -> 10^-8];
g7CascadeDLA = DLADimension[cascadeGens];
g7LeafDLA = DLADimension[{cascadeGens[[1]]}];
{"axis rank" -> g7AxisRank, "cascade DLA" -> g7CascadeDLA, "leaf-confined DLA" -> g7LeafDLA}

(* ::CodeText:: *)
(*The access staircase, OQ1 (interventional DLA bounding; OQ-PROBE-SPEC / oq1_interventional_dla.py). Give the tester oracle access to tables of the device transformed by a known SO(3) family \[Theta] |-> T(R_\[Theta] . prep). The orbit of the DLA-3 cascade sweeps a manifold whose local dimension is the rank of the Jacobian dT/d\[Theta]. We recompute the pre-registered analytic \[Theta] = 0 anchor live (dT/d\[Theta]_k = 2 (l.z)(l.(e_k \[Times] z)) per pentagram projector l): rank 2, with the z-rotation column vanishing identically. The \[Theta]-blind rig freezes its fractions, so its table is constant in \[Theta] \[LongDash] Jacobian identically zero, rank 0. Rank 2 > 0 is the separation (OQ1-A).*)

(* ::Input:: *)
oq1c2 = Cos[Pi/5]/(1 + Cos[Pi/5]);
oq1L = Table[{Sqrt[1 - oq1c2] Cos[4 Pi i/5], Sqrt[1 - oq1c2] Sin[4 Pi i/5], Sqrt[oq1c2]}, {i, 0, 4}];
oq1psi = {0, 0, 1}; oq1ctx = Table[{i, Mod[i + 1, 5]}, {i, 0, 4}]; oq1e = IdentityMatrix[3];
oq1Row[l_] := Table[2 (l.oq1psi) (l.Cross[oq1e[[k]], oq1psi]), {k, 1, 3}];
oq1Jac = N@Join @@ Table[
     Module[{i = oq1ctx[[cc, 1]], j = oq1ctx[[cc, 2]], a, b, n},
      a = oq1L[[i + 1]]; b = oq1L[[j + 1]]; n = Cross[a, b]; n = n/Norm[n];
      {oq1Row[n], oq1Row[b], oq1Row[a], {0, 0, 0}}], {cc, 1, 5}];
oq1RankQuantum = MatrixRank[oq1Jac, Tolerance -> 10^-8];
oq1ZColumn = Max[Abs[oq1Jac[[All, 3]]]];
oq1RankBlind = MatrixRank[ConstantArray[0., {20, 3}], Tolerance -> 10^-8];
{"orbit rank (cascade)" -> oq1RankQuantum, "z-rotation column" -> oq1ZColumn, "orbit rank (\[Theta]-blind rig)" -> oq1RankBlind}

(* ::CodeText:: *)
(*The access staircase, OQ2 (attenuation-series gate G8; oq2_attenuation_gate.py). Insert a calibrated attenuator \[Eta] and test the loss-robust identity D[c,s,j] = |q(\[Eta]_j) - \[Eta]_j q(1) - (1-\[Eta]_j)[s=null]|, which vanishes for any single-photon (binomial) device at every intrinsic efficiency. A coherent/intensity forger's Poissonian click rates 1 - e^(-\[Eta] mu) are concave and cannot satisfy it. We recompute the deterministic core live: the physicalized iii-d forger (deterministic report map, mu fixed so the \[Eta] = 1 reported table is (1 - z0) times the quantum row, z0 = 0.10) has exact deviation D_max \[TildeTilde] 56 t_max \[LongDash] far above the pre-registered threshold, the reason gate G8 flags it in every one of the 25 sampled repetitions.*)

(* ::Input:: *)
oq2Etas = {1.0, 0.85, 0.70, 0.55, 0.40, 0.25, 0.12, 0.05};
oq2N = 10^6; oq2Alpha = 1/100; oq2M = 5*4*7; oq2aPrime = oq2Alpha/(2 oq2M);
oq2Eps = Sqrt[Log[2/oq2aPrime]/(2 oq2N)]; oq2tMax = oq2Eps (1 + 0.85);
oq2pQ = N@{1 - 2/Sqrt[5], 1/Sqrt[5], 1/Sqrt[5]}; oq2z0 = 0.10;
oq2Raws = Tuples[{0, 1}, 3];
oq2gCol[r_] := If[Total[r] == 0, 4, First[FirstPosition[r, 1]]];
oq2g = Table[UnitVector[4, oq2gCol[r]], {r, oq2Raws}];
oq2RawProbs[mu_, eta_] := Table[Product[If[r[[d]] == 1, 1 - Exp[-eta mu[[d]]], Exp[-eta mu[[d]]]], {d, 3}], {r, oq2Raws}];
oq2Report[mu_, eta_] := oq2RawProbs[mu, eta].oq2g;
oq2mu0 = -Log[1 - oq2pQ];
oq2sol = FindRoot[Thread[oq2Report[{m1, m2, m3}, 1.0][[1 ;; 3]] == (1 - oq2z0) oq2pQ],
    {{m1, oq2mu0[[1]]}, {m2, oq2mu0[[2]]}, {m3, oq2mu0[[3]]}}];
oq2muStar = {m1, m2, m3} /. oq2sol;
oq2q1 = oq2Report[oq2muStar, 1.0];
oq2Dmax = Max@Flatten@Table[
     Module[{qe = oq2Report[oq2muStar, eta]},
      Table[Abs[qe[[s]] - eta oq2q1[[s]] - (1 - eta) Boole[s == 4]], {s, 1, 4}]], {eta, oq2Etas[[2 ;;]]}];
{"t_max" -> oq2tMax, "forger D_max" -> oq2Dmax, "D_max / t_max" -> oq2Dmax/oq2tMax}

(* ::CodeText:: *)
(*The CV column, G7-CV (F11; Sp(2n,R) leaf-confinement, final_o3_cv_dla.py). The so(3) audit does not transplant to Gaussian devices, which live on the real symplectic group. A quadratic Hamiltonian (1/2) r^T G r generates K = \[CapitalOmega].G in sp(2n,R) (dim n(2n+1)); its maximal compact subalgebra is the passive linear-optics algebra u(n) (dim n^2, antisymmetric generators \[LongDash] phase shifters and beamsplitters). Squeezers are symmetric (active). The criterion: the claimed generators' matrix Lie closure sits inside u(n) (passive-confined, linear-optics-emulable) or breaks out (active). We recompute the closure inline in exact arithmetic.*)

(* ::Input:: *)
cvOmega[n_] := Module[{o = ConstantArray[0, {2 n, 2 n}]},
    Do[o[[2 j - 1, 2 j]] = 1; o[[2 j, 2 j - 1]] = -1, {j, 1, n}]; o];
cvSym[n_, terms_] := Module[{g = ConstantArray[0, {2 n, 2 n}]},
    Do[If[t[[1]] == t[[2]], g[[t[[1]], t[[1]]]] += t[[3]],
       g[[t[[1]], t[[2]]]] += t[[3]]/2; g[[t[[2]], t[[1]]]] += t[[3]]/2], {t, terms}]; g];
cvGen[n_, g_] := cvOmega[n].g;
cvX[j_] := 2 j - 1; cvP[j_] := 2 j;
cvPhase[n_, j_] := cvGen[n, cvSym[n, {{cvX[j], cvX[j], 1}, {cvP[j], cvP[j], 1}}]];
cvBsRe[n_, j_, k_] := cvGen[n, cvSym[n, {{cvX[j], cvX[k], 1}, {cvP[j], cvP[k], 1}}]];
cvBsIm[n_, j_, k_] := cvGen[n, cvSym[n, {{cvX[j], cvP[k], 1}, {cvP[j], cvX[k], -1}}]];
cvSq2a[n_, j_, k_] := cvGen[n, cvSym[n, {{cvX[j], cvX[k], 1}, {cvP[j], cvP[k], -1}}]];
cvSq2b[n_, j_, k_] := cvGen[n, cvSym[n, {{cvX[j], cvP[k], 1}, {cvP[j], cvX[k], 1}}]];
cvSq1[n_, j_] := cvGen[n, cvSym[n, {{cvX[j], cvX[j], 1}, {cvP[j], cvP[j], -1}}]];
cvLieAudit[gens_] := Module[{basis = {}, c, changed = True, i, j},
    Do[If[MatrixRank[Flatten /@ Append[basis, g]] > Length[basis], AppendTo[basis, g]], {g, gens}];
    While[changed, changed = False;
     Do[c = basis[[i]].basis[[j]] - basis[[j]].basis[[i]];
       If[Norm[N@Flatten[c]] > 0 && MatrixRank[Flatten /@ Append[basis, c]] > Length[basis],
        AppendTo[basis, c]; changed = True], {i, 1, Length[basis]}, {j, i + 1, Length[basis]}]];
    <|"dim" -> Length[basis], "compact" -> AllTrue[basis, (# + Transpose[#]) == ConstantArray[0, Dimensions[#]] &]|>];
cvPassive2 = cvLieAudit[{cvPhase[2, 1], cvPhase[2, 2], cvBsRe[2, 1, 2], cvBsIm[2, 1, 2]}];
cvActive2 = cvLieAudit[{cvPhase[2, 1], cvPhase[2, 2], cvBsRe[2, 1, 2], cvBsIm[2, 1, 2], cvSq2a[2, 1, 2], cvSq2b[2, 1, 2]}];
cvActive1 = cvLieAudit[{cvPhase[1, 1], cvSq1[1, 1]}];
{"passive u(2)" -> cvPassive2, "active sp(4,R)" -> cvActive2, "active sp(2,R)" -> cvActive1}

(* ::Text:: *)
(*Proposition O3-C (F10, [T] conditional). Within the intensity-emulator class A_IE (classical light + intensity redistribution up to \[Alpha]* = 5/2 + one unmodified on-off detector, fair-sampled, fresh-per-trial), the gate set {C1-C5, G7, G7-CV, G8} is complete: every device is distinguished or certified NCHV-bounded. Load-bearing premises stated openly: the KBS single-detector coherent-forgeability theorem and white-box trust on G7/G7-CV. The residual open problem is H4' (A_IE-maximality). [H]*)

(* ::CodeText:: *)
(*The certification map (00-BBT-blackbox-protocol/certification_map.png; regenerated by certification_map.wl with the CV column filled) embeds the whole staircase \[LongDash] access model x adversary strength, plus the orthogonal geometric lens:*)

(* ::Input:: *)
certMapFile = FileNameJoin[{repoRoot, "00-BBT-blackbox-protocol", "certification_map.png"}];
certificationMap = If[FileExistsQ[certMapFile], Import[certMapFile], Missing["regenerate via certification_map.wl"]];

(* ::CodeText:: *)
(*Section 3 check: the G7 anchor (axis rank 2, cascade DLA 3, leaf DLA < 3); OQ1 separation (orbit rank 2 vs 0, z-column zero); OQ2 forger flagged (D_max far above t_max); the CV column (u(2) = 4 confined, sp(4,R) = 10 and sp(2,R) = 3 active); and the embedded map.*)

(* ::Input:: *)
section3Check = <|
   "g7Anchor" -> g7AxisRank == 2 && g7CascadeDLA == 3 && g7LeafDLA < 3,
   "oq1Separation" -> oq1RankQuantum == 2 && oq1RankBlind == 0 && oq1ZColumn < 10^-10,
   "oq2ForgerFlagged" -> oq2Dmax > 10 oq2tMax && Abs[oq2Dmax/oq2tMax - 56] < 2,
   "cvColumn" -> cvPassive2["dim"] == 4 && cvPassive2["compact"] &&
      cvActive2["dim"] == 10 && ! cvActive2["compact"] &&
      cvActive1["dim"] == 3 && ! cvActive1["compact"],
   "certMapOK" -> (MissingQ[certificationMap] || ImageQ[certificationMap])
   |>;   (* figure is decorative: valid when present, gracefully absent in standalone mode -- never gates OK *)
Column[{section3Check, "S3 OK" -> And @@ Values[section3Check]}]

(* ::Section:: *)
(*Verification (sections 1-3)*)

(* ::Text:: *)
(*House discipline: the three section checks folded into one association. This cell must print OK -> True.*)

(* ::Input:: *)
sectionsVerification = <|
   "S1_atom" -> And @@ Values[section1Check],
   "S2_blindSpot" -> And @@ Values[section2Check],
   "S3_twoLenses" -> And @@ Values[section3Check]
   |>;
Column[{sectionsVerification, "OK" -> And @@ Values[sectionsVerification]}]
