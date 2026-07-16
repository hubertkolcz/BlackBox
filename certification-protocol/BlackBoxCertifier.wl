(* ::Package:: *)

(* :Title: BlackBoxCertifier *)
(* :Context: HubertKolcz`BlackBoxCertifier` *)
(* :Author: Hubert Kolcz *)
(* :Date: 2026-07-14 *)

(* :Summary:
   Native-Wolfram-Language port of the black-box certification protocol
   (mbqc_blackbox_test.py) plus its whole "second-generation" gate family
   (G7-G9, eta*, OQ1/OQ2), wired directly onto the optical-synthesis
   blueprint schema. certification-protocol certifies; optical-synthesis builds; this module is the
   missing pure-WL bridge that lets a SINGLE Wolfram notebook run the full
   loop -- construct a device (optical-synthesis) -> certify it (this module) -> get a
   quantitative grade -- with every claim kernel-verified in place, instead
   of shelling out to Python.

   NO NEW MATHEMATICS. Every gate here reproduces logic that already exists
   and is already validated in this repository or the literature it cites;
   this module's own contribution is the native-WL implementation and its
   direct wiring onto EmitBlueprint's output. Sources, gate by gate:
     Category 1 (device-facing metrics)      -- mbqc_blackbox_test.py C1-C5
     Category 2 (engine self-validation)      -- mbqc_blackbox_test.py's
                                                  "sanity-first" anchors
     Category 3 (engine trust/scope-boundary) -- G7: BlackBox.wl's
                                                  CascadeGenerators/DLADimension
                                                  (LP-001); eta*:
                                                  efficiency_threshold_kcbs.py
     Category 4 (engine redesign / access-    -- G9: g9_antibunching_gate.py
       expansion -- future-metric directions)    (Glauber 1963); G8:
                                                  oq2_attenuation_gate.py /
                                                  arXiv:2601.13869 (KBS);
                                                  OQ1: oq1_interventional_dla.py
   The four-category taxonomy itself (which gates are literal device
   thresholds vs. checks on the assessment ENGINE's own correctness, trust
   assumptions, or reach) is stated explicitly here because it is the
   organizing structure of this module and of ConstructCertifyLoop.nb.

   HONEST SCOPE. Categories 1-3 are implemented in full, exact, native WL
   and reproduce every literature/pre-registered anchor to machine precision
   (see the SelfTest[] battery below). Category 4's three gates are heavy,
   pre-registered, seeded Monte-Carlo/optimization protocols in their
   original Python form (927+374+306 lines); this module implements their
   CORE MECHANISM natively and exactly (the Glauber bound is exact; the
   attenuation/orbit-rank demonstrations are honest, working, smaller-scale
   instances of the real mechanism) while CITING, not re-deriving, the
   original pre-registered worst-case numbers (e.g. the minimax-optimal G8
   adversary's Delta_min = 0.041309). Do not read AttenuationGateDemo or
   InterventionalOrbitProbe as reproducing the full pre-registered protocol
   at its pre-registered power -- they are illustrative, honestly-scoped
   companions to it, citable as "mechanism confirmed in native WL" and no
   more. This mirrors DispatcherEmitter.wl's own "Honest scope" convention. *)

PacletDirectoryLoad[
  FileNameJoin[{Quiet@Check[NotebookDirectory[], DirectoryName[$InputFileName]],
    "..", "BlackBox"}]];

BeginPackage["HubertKolcz`BlackBoxCertifier`", {"HubertKolcz`BlackBox`"}];

(* ---- Category 1: device-facing metrics (C1-C5) ------------------------ *)
EventProbabilities::usage = "EventProbabilities[e] gives the 5 per-measurement click probabilities of a 20-vector table e (CycleScenario[5] section order (00,01,10,11) per context, contexts (0,1)..(4,0)), pooled over the two contexts containing each measurement -- mbqc_blackbox_test.py's event_probs.";
CertifyTable::usage = "CertifyTable[e] runs the exact-table (N->Infinity) form of certificates C1-C5 on the KCBS-pentagon table e: C1 no-disturbance (HarmonicResidual), C2 contextual fraction (ContextualFraction, numeric LP -- LinearOptimization's exact solver only accepts rational data, so algebraic tables are N[]'d, matching mbqc_blackbox_test.py's own all-floating-point scipy LP), C3 two-copy Consistent-Exclusivity (CEFilter on CycleGraph[5]), C4 possibilistic support (PossibilisticSupport), C5 node sum vs. {2,Sqrt[5],5/2}. CertifyTable[e,scen] uses an explicit CycleScenario-compatible scen instead of CycleScenario[5].";
TableVerdict::usage = "TableVerdict[cert] applies mbqc_blackbox_test.py's pre-registered V1-V5 verdict order to a CertifyTable[] result, giving <|\"Verdict\"->\"QUANTUM-CERTIFIED\"|\"CLASSICAL\"|\"EMULATION-SUSPECT\"|\"INCONCLUSIVE\", \"Reasons\"->{...}|>. This is the CORRELATION-LENS-ONLY verdict; see TwoLensVerdict for the full engine.";

(* ---- Category 2: engine self-validation -------------------------------- *)
SanityAnchors::usage = "SanityAnchors[] recomputes, on exact tables, every anchor mbqc_blackbox_test.py checks before trusting a single simulated device: CF(quantum)=2Sqrt5-4, CF(classical)=0, CF(Wright)=1, node sums {Sqrt5,2,5/2}, and the G7 cascade DLA anchor (span 2, dim 3). Gives <|\"Checks\"->{name->bool...}, \"AllPass\"->bool|>. This validates the ENGINE, not any device -- see the module header's four-category taxonomy.";
QuantumTable::usage = "QuantumTable[V] gives the exact KCBS pentagon table of the depolarized qutrit state rho = V|psi><psi| + (1-V) I/3 (V=1 is the noiseless pentagram). QuantumTable[] = QuantumTable[1].";
ClassicalTable::usage = "ClassicalTable is the best-classical (NCHV, node sum alpha=2) exact table.";
WrightTable::usage = "WrightTable is the exclusivity-extremal (alpha*=5/2, CF=1, strongly contextual) exact table.";
AdversaryTable::usage = "AdversaryTable is construction (iii-d): the intensity emulator tuned EXACTLY to QuantumTable[1] -- the documented BBT-002 blind spot. Identical to QuantumTable[1] by construction.";

(* ---- Category 3: engine trust / scope-boundary audits ------------------ *)
LeafConfinementAudit::usage = "LeafConfinementAudit[gens] is the G7 gate: given a DECLARED so(3) generator set gens (a white-box compilation claim, NOT a black-box observable -- see Corollary 2 of PROPOSITION-O3.md), returns <|\"Span\"->,\"DLADimension\"->,\"LeafConfined\"->dla<3,\"Verdict\"->\"emulable\"|\"genuine\"|>. LeafConfinementAudit[] with no argument audits the genuine KCBS cascade (BlackBox`CascadeGenerators[]); expect DLADimension 3.";
DetectionEfficiencyThreshold::usage = "DetectionEfficiencyThreshold[] derives eta* = 2/Sqrt[5], the KCBS detection-efficiency threshold, TWO independent ways: (1) solving eta*Sqrt[5]==2 (efficiency-degraded quantum value meets the NCHV bound); (2) an exact LP over the 11 independent sets of C5 giving the fair-sampled detection-loophole ceiling max S_fair(eta)=2/eta. Gives <|\"EtaStar\"->,\"Derivation1\"->,\"Derivation2\"->{...},\"OddCycleTable\"->{...}|>. This is a THEOREM about the engine's fundamental reach (below eta* no amount of statistics-only testing closes the detection loophole), not a per-device pass/fail number.";

(* ---- Category 4: engine redesign / access-expansion (future-metric directions) *)
G2FromNumberDistribution::usage = "G2FromNumberDistribution[pn] gives g2(0) = <n(n-1)>/<n>^2 of a photon-number distribution pn (index k = photon number k-1).";
G2FromIntensitySamples::usage = "G2FromIntensitySamples[I] gives g2(0) = 1 + Var(I)/Mean(I)^2 from samples of a classical intensity I>=0 -- always >= 1 by construction (Glauber's classical bound made computationally manifest).";
AntibunchingGate::usage = "AntibunchingGate[pn, eps] (G9) applies Glauber's classical bound g2(0)>=1: g2+eps<1 -> \"CERTIFIED-NONCLASSICAL\" (outside every classical-optical-emulator family, under ANY detection scheme); g2-eps>=1 -> \"CLASSICAL-COMPATIBLE\"; else \"INCONCLUSIVE\". eps defaults to 0 (exact input).";
AttenuationGateDemo::usage = "AttenuationGateDemo[] (G8, illustrative mechanism) compares the binomial-consistency deviation D(eta)=|R(eta)-eta R(1)| across an attenuation grid for (a) a single-photon-semantics box (R linear in eta, D=0 exactly) vs. (b) a naive coherent forger tuned to match at eta=1 (R concave, D>0). Demonstrates the KBS (arXiv:2601.13869) discriminating mechanism G8 keys on; NOT the pre-registered minimax-optimal adversary search (cf. oq2_attenuation_gate.py, Delta_min=0.041309 at the pre-registered J=8/z_max=0.20 configuration -- cited, not reproduced here).";
InterventionalOrbitProbe::usage = "InterventionalOrbitProbe[] (OQ1, illustrative mechanism) computes the exact table-orbit Jacobian of the KCBS cascade under an SO(3) preparation intervention theta, at theta=0 (closed form dT/dtheta_k=2V(l.z)(l.(e_k x z)), the same anchor oq1_interventional_dla.py pre-registers) and at a generic theta (finite differences): rank 2 both times, vs. a theta-blind rig's rank 0. Also confirms, numerically, that T(theta) already lies in the no-disturbance polytope for every theta (Parseval/orthonormal-basis identity), the structural reason the theta-aware rig's fit is a tautology (T_A === T).";

(* ---- integration: the two lenses, the blueprint bridge, the grade ------ *)
TwoLensVerdict::usage = "TwoLensVerdict[tableVerdict_String, reasons_List, dlaAudit] combines the correlation-lens verdict with an (optional) G7 audit per Proposition O3-C: QUANTUM-CERTIFIED + leaf-confined audit -> overridden to EMULATION-SUSPECT (closes the Prop.1/BBT-002 blind spot); QUANTUM-CERTIFIED + no audit supplied -> left standing, flagged 'DLA not audited' (Prop.2/BBT-003: no table functional can decide it either way); otherwise unchanged.";
BlueprintTable::usage = "BlueprintTable[bp] extracts the exact 20-vector KCBS table from a optical-synthesis EmitBlueprint[] Association: L1 (reconstructs Born-rule context probabilities from bp[\"Stages\"], matching DispatcherEmitter.wl's l1ContextProbs / VerifyBlueprint convention exactly), L2 (reads bp[\"Schedule\"][\"TableReproduced\"][\"Exact\"] directly), Mesh (returns the single-pentagon KCBS anchor table, block-local by construction -- see the module header; a genuine per-block joint simulator is out of scope).";
CertifyBlueprint::usage = "CertifyBlueprint[bp] is the full construct-to-certify bridge: extracts BlueprintTable[bp], runs CertifyTable+TableVerdict (Category 1), reads bp's own DLA claim from \"CertificationVerdict\" (Category 3/G7) and combines via TwoLensVerdict. Gives a full report Association including \"Table\",\"Cert\",\"CorrelationVerdict\",\"DLA\",\"TwoLensVerdict\".";
GradeReport::usage = "GradeReport[e] or GradeReport[bp] (blueprint or bare table) prints and returns a human-readable quantitative grade: the categorical verdict, the contextual fraction CF_hat against its three named anchors {0 classical, 2Sqrt5-4 quantum-max, 1 Wright/exclusivity-extremal}, the node sum against {2,Sqrt5,5/2}, the G7 DLA reading, and a presentational (non-canonical, explicitly labeled) 0-100 QuantumnessIndex = Clip[100 CF_hat/(2Sqrt5-4),0,100+].";
EngineMap::usage = "EngineMap[] gives the kernel-generated dependency Graph of the whole assessment engine: the four categories (device metrics / engine self-validation / engine trust-boundary / engine redesign-expansion), color-coded, with edges showing which gates gate/feed/bound which.";
SelfTest::usage = "SelfTest[] runs every anchor and cross-check this module depends on and gives <|\"AllPass\"->bool, per-check booleans...|>.";

Begin["`Private`"];

(* ======================================================================
   0. shared helpers
   ====================================================================== *)
tableFromEdge[p00_, p01_, p10_] := Flatten[Table[{p00, p01, p10, 0}, {5}]];

EventProbabilities[e_List] := Module[{ctx = Partition[e, 4]},
  Table[With[{left = ctx[[Mod[m - 1, 5] + 1, 2]] + ctx[[Mod[m - 1, 5] + 1, 4]],
              right = ctx[[m + 1, 3]] + ctx[[m + 1, 4]]}, (left + right)/2], {m, 0, 4}]];

cfNumeric[scen_Association, e_List] := ContextualFraction[scen, N[e]];

(* ======================================================================
   1. Category 1 -- device-facing metrics C1-C5
   ====================================================================== *)
CertifyTable[e_List, scen_Association : Automatic] := Module[
  {sc = If[scen === Automatic, CycleScenario[5], scen], delta, resid, zeroQ, cf, p, sigma, supp},
  delta = CycleCoboundary[sc["n"]];
  resid = delta . e;
  zeroQ = TrueQ[Chop[N[resid]] == ConstantArray[0., Length[resid]]];
  cf = cfNumeric[sc, e];
  p = EventProbabilities[e]; sigma = Total[p];
  supp = PossibilisticSupport[sc, e];
  <|"Table" -> e, "ND" -> <|"Residual" -> resid, "Signaling" -> !zeroQ|>,
    "CF" -> <|"Hat" -> cf, "Lo" -> cf, "Hi" -> cf|>,
    "CE2" -> CEFilter[CycleGraph[sc["n"]], p, 2],
    "Support" -> supp,
    "NodeSum" -> <|"Sigma" -> sigma, "SupraQuantum" -> TrueQ[N[sigma] > N[Sqrt[5]] + 10^-9]|>|>];

TableVerdict[cert_Association] := Module[{reasons = {}, v},
  If[cert["ND"]["Signaling"], AppendTo[reasons, "C1 signaling: no-disturbance residual nonzero"]];
  If[cert["NodeSum"]["SupraQuantum"], AppendTo[reasons, "C5 supra-quantum: node sum exceeds Sqrt[5]"]];
  If[!cert["CE2"]["Passes"], AppendTo[reasons, "C3 CE2 violated: 2-copy clique load exceeds 1"]];
  If[cert["Support"]["Empty"], AppendTo[reasons, "C4 empty possibilistic support: strong contextuality beyond quantum reach"]];
  v = Which[reasons =!= {}, "EMULATION-SUSPECT",
     TrueQ[N[cert["CF"]["Lo"]] > 10^-9], "QUANTUM-CERTIFIED",
     TrueQ[N[cert["CF"]["Hat"]] <= 0.05], "CLASSICAL",
     True, "INCONCLUSIVE"];
  <|"Verdict" -> v, "Reasons" -> reasons|>];

(* ======================================================================
   2. Category 2 -- engine self-validation
   ====================================================================== *)
QuantumTable[V_ : 1] := With[{q = V/Sqrt[5] + (1 - V)/3, p00 = V (1 - 2/Sqrt[5]) + (1 - V)/3},
   tableFromEdge[p00, q, q]];
ClassicalTable = tableFromEdge[1/5, 2/5, 2/5];
WrightTable = tableFromEdge[0, 1/2, 1/2];
AdversaryTable = tableFromEdge[1 - 2/Sqrt[5], 1/Sqrt[5], 1/Sqrt[5]];

SanityAnchors[] := Module[{cfq, cfc, cfw, ns, dlaSpan, dlaDim, res},
  cfq = cfNumeric[CycleScenario[5], QuantumTable[1]];
  cfc = cfNumeric[CycleScenario[5], ClassicalTable];
  cfw = cfNumeric[CycleScenario[5], WrightTable];
  ns = {Total[EventProbabilities[QuantumTable[1]]], Total[EventProbabilities[ClassicalTable]], Total[EventProbabilities[WrightTable]]};
  dlaSpan = MatrixRank[So3Axis /@ CascadeGenerators[], Tolerance -> 10^-8];
  dlaDim = DLADimension[CascadeGenerators[]];
  res = {
   "CF(quantum)=2Sqrt5-4" -> (Abs[cfq - N[2 Sqrt[5] - 4]] < 10^-6),
   "CF(classical)=0" -> (Abs[cfc] < 10^-6),
   "CF(Wright)=1" -> (Abs[cfw - 1] < 10^-6),
   "nodeSums={Sqrt5,2,5/2}" -> (Max[Abs[N[ns] - N[{Sqrt[5], 2, 5/2}]]] < 10^-9),
   "AdversaryTable===QuantumTable[1]" -> (Simplify[AdversaryTable - QuantumTable[1]] === ConstantArray[0, 20]),
   "DLA(cascade)=3,span=2" -> ({dlaSpan, dlaDim} === {2, 3})};
  <|"Checks" -> res, "AllPass" -> AllTrue[res[[All, 2]], TrueQ]|>];

(* ======================================================================
   3. Category 3 -- engine trust / scope-boundary audits
   ====================================================================== *)
LeafConfinementAudit[] := LeafConfinementAudit[CascadeGenerators[]];
LeafConfinementAudit[gens_List] := Module[
  {span = MatrixRank[So3Axis /@ gens, Tolerance -> 10^-8], dla = DLADimension[gens]},
  <|"Span" -> span, "DLADimension" -> dla, "LeafConfined" -> dla < 3,
    "Verdict" -> If[dla < 3, "emulable", "genuine"]|>];

c5IndepSets[] := Select[Subsets[Range[0, 4]],
   AllTrue[Subsets[#, {2}], (Mod[#[[1]] - #[[2]], 5] != 1 && Mod[#[[2]] - #[[1]], 5] != 1) &] &];

fairSampledSMax[etaVal_] := Module[{sets = c5IndepSets[], dets, types, nv, cvec, vars, Aeq, beq, minVal},
  dets = Tuples[{0, 1}, 5];
  types = Flatten[Table[{S, d}, {S, sets}, {d, dets}], 1];
  nv = Length[types]; vars = Array[Symbol["HubertKolcz`BlackBoxCertifier`Private`x"], nv];
  cvec = Table[Total[Table[If[MemberQ[types[[k, 1]], i] && types[[k, 2, i + 1]] == 1, 1, 0], {i, 0, 4}]], {k, nv}];
  Aeq = Join[{Table[1., {nv}]}, Table[Table[N[Boole[types[[k, 2, i + 1]] == 1]], {k, nv}], {i, 0, 4}]];
  beq = N[Join[{1}, Table[etaVal, {5}]]];
  minVal = First@Quiet@LinearOptimization[-cvec . vars,
     Join[Thread[Aeq . vars == beq], Thread[vars >= 0]], vars, {"PrimalMinimumValue"}];
  (-minVal)/etaVal];

oddCycleEtaStar[n_] := With[{Qn = n Cos[Pi/n]/(1 + Cos[Pi/n])}, {(n - 1)/2/Qn, Qn}];

DetectionEfficiencyThreshold[] := Module[{etaSym, etaNum, d2},
  etaSym = eta /. Solve[eta*Sqrt[5] == 2, eta][[1]];
  etaNum = N[etaSym];
  d2 = Table[<|"Eta" -> e, "MaxSFair" -> fairSampledSMax[e], "TwoOverEta" -> 2/e|>, {e, {0.40, 0.50, etaNum, 0.90, 1.00}}];
  <|"EtaStar" -> etaSym, "EtaStarNumeric" -> etaNum,
    "Derivation1" -> "S_Q(eta)=eta*Sqrt[5]=2 => eta*=2/Sqrt[5] (efficiency-degraded quantum value meets NCHV bound)",
    "Derivation2" -> d2,
    "Derivation2AllMatch" -> AllTrue[d2, Abs[#["MaxSFair"] - #["TwoOverEta"]] < 10^-6 &],
    "OddCycleTable" -> Table[<|"n" -> n, "Qn" -> N[oddCycleEtaStar[n][[2]]], "EtaStarN" -> N[oddCycleEtaStar[n][[1]]]|>, {n, {5, 7, 9, 11}}]|>];

(* ======================================================================
   4. Category 4 -- engine redesign / access-expansion (future directions)
   ====================================================================== *)
G2FromNumberDistribution[pn_List] := Module[{p = pn/Total[pn], nn = Range[0, Length[pn] - 1], m1, m2},
  m1 = nn . p; m2 = (nn (nn - 1)) . p; If[m1 <= 0, Infinity, m2/m1^2]];
G2FromIntensitySamples[I_List] := Module[{m = Mean[I]}, If[m <= 0, Infinity, 1 + Variance[I]/m^2]];

AntibunchingGate[pn_List, eps_ : 0] := Module[{g2 = G2FromNumberDistribution[pn]},
  <|"G2" -> g2, "Eps" -> eps,
    "Verdict" -> Which[g2 + eps < 1, "CERTIFIED-NONCLASSICAL", g2 - eps >= 1, "CLASSICAL-COMPATIBLE", True, "INCONCLUSIVE"]|>];

pnFock[k_, nmax_ : 30] := ReplacePart[ConstantArray[0., nmax + 1], k + 1 -> 1.];
pnCoherentNum[muv_, nmax_ : 60] := Module[{p = Table[PDF[PoissonDistribution[muv], k], {k, 0, nmax}]}, p/Total[p]];
pnThermalNum[nbv_, nmax_ : 60] := Module[{p = Table[nbv^k/(1 + nbv)^(k + 1), {k, 0, nmax}]}, p/Total[p]];

AttenuationGateDemo[] := Module[{pQ1, etaGrid, muC, Rsp, Rc, dev},
  pQ1 = N[1 - 2/Sqrt[5]];
  etaGrid = {1.0, 0.85, 0.70, 0.55, 0.40, 0.25, 0.12, 0.05};
  muC = mu /. FindRoot[1 - Exp[-mu] == pQ1, {mu, pQ1}];
  Rsp[eta_] := eta*pQ1; Rc[eta_] := 1 - Exp[-eta*muC];
  dev = Table[<|"Eta" -> e, "D_SinglePhoton" -> Abs[Rsp[e] - e Rsp[1]], "D_CoherentForger" -> Abs[Rc[e] - e Rc[1]]|>, {e, etaGrid}];
  <|"Grid" -> dev, "MaxD_SinglePhoton" -> Max[dev[[All, "D_SinglePhoton"]]], "MaxD_CoherentForger" -> Max[dev[[All, "D_CoherentForger"]]],
    "Note" -> "illustrative single-aggregate mechanism demo; pre-registered minimax adversary Delta_min=0.041309 at J=8/z_max=0.20 (oq2_attenuation_gate.py) is cited, not re-derived"|>];

kcbsLVEC[] := N[KCBSDirections[]];
ctxPairsList = Table[{i, Mod[i + 1, 5]}, {i, 0, 4}];

InterventionalOrbitProbe[] := Module[
  {z0 = {0, 0, 1}, lvec, jacRow0, jac0full, rank0, sv0, tableThetaNum, fdJacobian, thetaGen, jacGen, ndResid},
  lvec = kcbsLVEC[];
  jacRow0[l_, V_] := 2 V (l . z0) Table[l . Cross[UnitVector[3, k], z0], {k, 3}];
  jac0full = Flatten[Table[Module[{i = ctx[[1]], j = ctx[[2]], av, bv, nv},
      av = lvec[[i + 1]]; bv = lvec[[j + 1]]; nv = Normalize[Cross[av, bv]];
      {jacRow0[nv, 1], jacRow0[bv, 1], jacRow0[av, 1], {0, 0, 0}}], {ctx, ctxPairsList}], 1];
  rank0 = MatrixRank[jac0full, Tolerance -> 10^-10]; sv0 = SingularValueList[jac0full];
  tableThetaNum[{a_?NumericQ, b_?NumericQ, c_?NumericQ}, V_] := Module[{Rm, psi, e},
    Rm = If[Norm[{a, b, c}] < 10^-13, IdentityMatrix[3], RotationMatrix[Norm[{a, b, c}], Normalize[{a, b, c}]]];
    psi = Rm . {0, 0, 1};
    e = Table[Module[{i = ctx[[1]], j = ctx[[2]], av, bv, nv, p10, p01, p00},
       av = lvec[[i + 1]]; bv = lvec[[j + 1]]; nv = Normalize[Cross[av, bv]];
       p10 = V (av . psi)^2 + (1 - V)/3; p01 = V (bv . psi)^2 + (1 - V)/3; p00 = V (nv . psi)^2 + (1 - V)/3;
       {p00, p01, p10, 0}], {ctx, ctxPairsList}]; Flatten[e]];
  fdJacobian[f_, pt_List, h_ : 10^-5] := Transpose[Table[
     (f[pt + h UnitVector[Length[pt], k]] - f[pt - h UnitVector[Length[pt], k]])/(2 h), {k, Length[pt]}]];
  thetaGen = {0.3, -0.2, 0.15};
  jacGen = fdJacobian[tableThetaNum[#, 1] &, thetaGen];
  SeedRandom[42];
  ndResid = Max[Table[Norm[CycleCoboundary[5] . tableThetaNum[RandomReal[{-1, 1}, 3], 1]], {10}]];
  <|"RankAtZero" -> rank0, "SingularValuesAtZero" -> sv0,
    "RankGeneric" -> MatrixRank[jacGen, Tolerance -> 10^-7], "ThetaGeneric" -> thetaGen,
    "RankThetaBlindRig" -> 0,
    "MaxNDResidualOverRandomTheta" -> ndResid,
    "Note" -> "theta=0 anchor is the EXACT closed form dT/dtheta_k=2V(l.z)(l.(e_k x z)); generic point uses central finite differences, h=1e-5, matching oq1_interventional_dla.py's own primary method"|>];

(* ======================================================================
   5. integration: two lenses, the blueprint bridge, the grade
   ====================================================================== *)
TwoLensVerdict[corrVerdict_String, reasons_List, dla_ : Missing] := Which[
   corrVerdict === "QUANTUM-CERTIFIED" && AssociationQ[dla] && TrueQ[dla["LeafConfined"]],
     <|"Verdict" -> "EMULATION-SUSPECT", "Lens" -> "geometric (G7)",
       "Reasons" -> Append[reasons, "correlation lens alone reads QUANTUM-CERTIFIED, but the audited compilation is leaf-confined (DLA=" <>
         ToString[dla["DLADimension"]] <> "<3) -- Prop.1/BBT-002 blind spot, closed by G7"]|>,
   corrVerdict === "QUANTUM-CERTIFIED" && !AssociationQ[dla],
     <|"Verdict" -> corrVerdict, "Lens" -> "correlation-only (DLA not audited)",
       "Reasons" -> Append[reasons, "Prop.2/BBT-003: no table functional can certify the DLA either way -- an explicit generator claim is required"]|>,
   True, <|"Verdict" -> corrVerdict, "Lens" -> If[AssociationQ[dla], "two-lens (agree)", "correlation-only"], "Reasons" -> reasons|>];

(* per DispatcherEmitter.wl's l1ContextProbs + the frame[a,b]={a,b,Cross[a,b]} convention:
   detector 1 = l_i click = event "10"; detector 2 = l_{i+1} click = event "01";
   detector 3 = orthogonal-complement click = event "00" *)
l1ContextProbsLocal[bp_Association] := Module[{stages, prep, bsStages, prepCol, n, stageMatrixLocal, prefixState},
  stages = bp["Stages"];
  prep = SelectFirst[stages, #["Type"] === "Prep" &];
  bsStages = Select[stages, #["Type"] === "BS" &];
  prepCol = prep["Matrix"]["Exact"][[All, 1]];
  n = Length[bsStages] + 1;
  stageMatrixLocal[st_] := st["Matrix"]["Exact"];
  prefixState[k_] := If[k == 1, prepCol, (Dot @@ Reverse[stageMatrixLocal /@ Take[bsStages, k - 1]]) . prepCol];
  Table[prefixState[k]^2, {k, n}]];

BlueprintTable[bp_Association] := Which[
  bp["Layer"] === "L1", Flatten[{#[[3]], #[[2]], #[[1]], 0} & /@ l1ContextProbsLocal[bp]],
  bp["Layer"] === "L2", bp["Schedule"]["TableReproduced"]["Exact"],
  bp["Layer"] === "Mesh", QuantumTable[1],
  True, $Failed];

(* HONESTY FIX (2026-07-14 repo audit): the old Mesh special-case called
   LeafConfinementAudit[CascadeGenerators[]] -- CONTENT-BLIND, ignoring the
   blueprint's actual word/reps entirely, always returning the fixed KCBS
   cascade's own DLA=3/"genuine" regardless of what mesh was passed in. This
   directly DISAGREED with DispatcherEmitter.wl's own (separately hardcoded)
   LeafConfined->True/"emulable" for the exact same blueprints -- the repo
   contained two different fabricated mesh verdicts that didn't even agree
   with each other. Removed: the general case below already does the right
   thing once EmitBlueprint's Mesh branch honestly stores Missing["NotComputed"]
   instead of a fabricated literal (fixed alongside this) -- DLADimension
   fails IntegerQ, so this correctly falls through to Missing["NotAudited"]
   for Mesh blueprints today, and will pick up a real per-block audit
   automatically if/when one is ever wired in upstream, with no further edit
   needed here.
   State update (2026-07-16): DispatcherEmitter's meshDLAAudit now computes a
   real per-block structural audit -- each verified 5-cycle block carries
   integer DLADimension -> 3, verdict "genuine" -- so Mesh blueprints no longer
   fall through to Missing["NotAudited"]; the general case below picks the
   audit up exactly as anticipated, with no edit needed here. The JOINT
   whole-mesh leaf-confinement verdict remains open: meshDLAAudit's ScopeNote
   is explicit that it makes no claim about the composed su(2^n) dynamics. *)
blueprintDLA[bp_Association] := Module[{comp},
  Which[
   KeyExistsQ[bp, "CertificationVerdict"] && AssociationQ[bp["CertificationVerdict"]] && Length[bp["CertificationVerdict"]] > 0,
     comp = First[Values[bp["CertificationVerdict"]]];
     If[KeyExistsQ[comp, "DLADimension"] && IntegerQ[comp["DLADimension"]],
       <|"Span" -> comp["Span"], "DLADimension" -> comp["DLADimension"],
         "LeafConfined" -> TrueQ[comp["LeafConfined"]], "Verdict" -> comp["Verdict"]|>,
       Missing["NotAudited"]],
   True, Missing["NotAudited"]]];

CertifyBlueprint[bp_Association] := Module[{tbl, cert, cv, dla, tl},
  tbl = BlueprintTable[bp];
  cert = CertifyTable[tbl];
  cv = TableVerdict[cert];
  dla = blueprintDLA[bp];
  tl = TwoLensVerdict[cv["Verdict"], cv["Reasons"], If[AssociationQ[dla], dla, Missing]];
  <|"Table" -> tbl, "Cert" -> cert, "CorrelationVerdict" -> cv, "DLA" -> dla, "TwoLensVerdict" -> tl|>];

GradeReport[x_] := Module[{tbl, cert, cv, dla, tl, cfHat, sigma, qIndex},
  If[AssociationQ[x] && KeyExistsQ[x, "TargetSpec"],
    Module[{r = CertifyBlueprint[x]}, tbl = r["Table"]; cert = r["Cert"]; cv = r["CorrelationVerdict"]; dla = r["DLA"]; tl = r["TwoLensVerdict"]],
    tbl = x; cert = CertifyTable[tbl]; cv = TableVerdict[cert]; dla = Missing["NotAudited"];
    tl = TwoLensVerdict[cv["Verdict"], cv["Reasons"], Missing]];
  cfHat = N[cert["CF"]["Hat"]]; sigma = N[cert["NodeSum"]["Sigma"]];
  qIndex = Clip[100 cfHat/N[2 Sqrt[5] - 4], {0, 200}];
  <|"Verdict" -> tl["Verdict"], "Lens" -> tl["Lens"], "Reasons" -> tl["Reasons"],
    "ContextualFraction" -> <|"Value" -> cfHat, "Anchors" -> <|"classical" -> 0, "quantumMax" -> N[2 Sqrt[5] - 4], "WrightExclusivityExtremal" -> 1|>|>,
    "NodeSum" -> <|"Value" -> sigma, "Anchors" -> <|"NCHV" -> 2, "quantumMax" -> N[Sqrt[5]], "exclusivityOnly" -> 2.5|>|>,
    "DLA" -> dla, "QuantumnessIndex" -> qIndex|>];

(* ======================================================================
   6. the engine map (kernel-generated dependency diagram)
   ====================================================================== *)
EngineMap[] := Module[{nodes, labels, coordList, colBlue, colGray, colAmber, colGreen, colRed, colorList, labelOf, edges},
  nodes = {"C1", "C2", "C3", "C4", "C5", "Sanity", "AEmu", "G7", "EtaStar", "G8", "G9", "OQ1", "VERDICT"};
  labels = {"C1\nno-disturbance", "C2\ncontextual\nfraction", "C3\nCE^2", "C4\npossibilistic\nsupport", "C5\nnode sum",
    "sanity-first\nanchors", "A1\[Dash]A5\n(optical\nsynthesis)", "G7\nDLA hook", "\[Eta]*=2/\[Sqrt]5",
    "G8\nattenuation", "G9\nantibunching", "OQ1\ninterventional", "VERDICT"};
  coordList = {{-4, 3}, {-2, 3}, {0, 3}, {2, 3}, {4, 3},
    {-4.5, 1.6}, {-2.2, 1.6}, {1.5, 1.6}, {3.8, 1.6},
    {-2, 0.2}, {0, 0.2}, {2, 0.2}, {0, -1.2}};
  colBlue = RGBColor[0.20, 0.45, 0.75]; colGray = GrayLevel[0.55];
  colAmber = RGBColor[0.80, 0.55, 0.10]; colGreen = RGBColor[0.30, 0.58, 0.30]; colRed = RGBColor[0.55, 0.15, 0.15];
  colorList = {colBlue, colBlue, colBlue, colBlue, colBlue, colGray, colGray, colAmber, colAmber, colGreen, colGreen, colGreen, colRed};
  labelOf = AssociationThread[nodes, labels];
  edges = {"Sanity" -> "C1", "Sanity" -> "C2", "AEmu" -> "C1",
    "C1" -> "VERDICT", "C2" -> "VERDICT", "C3" -> "VERDICT", "C4" -> "VERDICT", "C5" -> "VERDICT",
    "G7" -> "VERDICT", "EtaStar" -> "C1",
    "C1" -> "G8", "C2" -> "G8", "G8" -> "VERDICT", "G9" -> "VERDICT", "OQ1" -> "G7"};
  Graph[nodes, DirectedEdge @@@ edges,
    VertexCoordinates -> Thread[nodes -> coordList],
    VertexStyle -> Thread[nodes -> colorList],
    VertexSize -> Thread[nodes -> 0.55],
    VertexShapeFunction -> "Rectangle",
    VertexLabels -> Table[nodes[[k]] -> Placed[Style[labelOf[nodes[[k]]], White, Bold, 9], Center], {k, Length[nodes]}],
    EdgeStyle -> Directive[GrayLevel[0.45], Thickness[0.0028]],
    ImageSize -> 720, PlotRangePadding -> 0.3]];

(* ======================================================================
   7. self-test
   ====================================================================== *)
SelfTest[] := Module[{anchors, eta, g9, ce2q, res},
  anchors = SanityAnchors[];
  eta = DetectionEfficiencyThreshold[];
  g9 = AntibunchingGate[pnFock[1]];
  ce2q = CertifyTable[QuantumTable[1]]["CE2"]["Passes"];
  res = {
   "sanity anchors all pass" -> anchors["AllPass"],
   "eta* = 2/Sqrt5" -> (Simplify[eta["EtaStar"] - 2/Sqrt[5]] === 0),
   "eta* LP derivations match" -> eta["Derivation2AllMatch"],
   "G9 Fock|1> certified nonclassical" -> (g9["Verdict"] === "CERTIFIED-NONCLASSICAL"),
   "quantum table passes CE2" -> ce2q,
   "quantum table verdict QUANTUM-CERTIFIED" -> (TableVerdict[CertifyTable[QuantumTable[1]]]["Verdict"] === "QUANTUM-CERTIFIED"),
   "classical table verdict CLASSICAL" -> (TableVerdict[CertifyTable[ClassicalTable]]["Verdict"] === "CLASSICAL"),
   "adversary table (correlation-only) reads QUANTUM-CERTIFIED (the blind spot)" ->
     (TableVerdict[CertifyTable[AdversaryTable]]["Verdict"] === "QUANTUM-CERTIFIED"),
   "adversary table, two-lens with leaf-confined DLA, reads EMULATION-SUSPECT" ->
     (TwoLensVerdict["QUANTUM-CERTIFIED", {}, <|"DLADimension" -> 0, "LeafConfined" -> True|>]["Verdict"] === "EMULATION-SUSPECT")};
  <|"Checks" -> res, "AllPass" -> AllTrue[res[[All, 2]], TrueQ]|>];

End[];
EndPackage[];
