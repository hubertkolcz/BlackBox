(* ::Package:: *)

(* ::Title:: *)
(*Epilogue: The Currency Law, the Binding No-Go, and the Channel Ledger*)

(* ::Subtitle:: *)
(*Three loose ends of the Wigner thread, closed by computation*)

(* ::Text:: *)
(*Hubert Ko\[LSlash]cz \[LongDash] July 2026. Closes the questions left open by kcbs_wigner_flow.wl and kcbs_ledger.wl (QUANTUM_CONTEXTUALITY.md, Section 9). Requires Wolfram/QuantumFramework and the BlackBox paclet. Headless verification: wolframscript -file RunEpilogue.wl -print all (must end OK -> True). Interactive use: evaluate cell by cell from a fresh kernel \[LongDash] the first cell repairs a kernel polluted by an earlier single-block evaluation (the Global`-shadowing pitfall of kcbs_circuit.wl, Section 1).*)

(* ::Abstract:: *)
(*Three questions, three verdicts. (1) THE CURRENCY LAW - which is a PUBLISHED THEOREM, not a discovery of this note: for cyclic systems, (n - 1) CNT3 = CNTF, where CNTF is the contextual fraction and CNT3 the minimal-negative-mass measure (Camillo and Cervantes, Phil. Trans. R. Soc. A 382:20230007 (2024), arXiv:2305.16574; via Cervantes 2023, arXiv:2110.07113, CNTF = 2 CNT2, and Kujala-Dzhafarov, arXiv:1907.03328, CNT2 = alpha CNT3, with n - 1 = 2 alpha). In our notation that is exactly CF = (n - 1) nu. What this section contributes is an INDEPENDENT VERIFICATION in the Abramsky-Brandenburger deterministic-vertex language and the explicit KCBS closed forms: verified at quantum maximum for n = 5, 7, 9, 11 (ratios 4, 6, 8, 10; deviations below 1e-9, the machine checks enforce 1e-6), EXACTLY for the Wright boxes (rational LPs: nu = 1/(n - 1), CF = 1) and at the C5 quantum point (RevisedSimplex), across the contextual range of the C7 white-noise family (V = 0.70 to 1, ratio 6 throughout), and at forty random ASYMMETRIC quantum models and twenty-three random contextual no-signalling mixtures, nine of them certifiably OUTSIDE the quantum set (they violate the C5 correlator quantum bound 4 Sqrt[5] - 5), every one with ratio 4 (deviations below 1e-9) - confirming the theorem holds across the whole no-signalling polytope of the cycle, as Camillo-Cervantes prove. (2) THE BINDING NO-GO. Pulling the 45 parity witnesses of all five wire points into one arena DOES create exclusivity edges to the pentagon clicks (35: each positive-cell witness binds to exactly one click; the negative-cell witnesses \[LongDash] the ones that certify negativity \[LongDash] bind to none, at any wire point) \[LongDash] but no metric binding: every single added event strictly lowers the CSW violation (best pentagon+1 is negative), the best pentagon+2 reaches 0.012 versus the pentagon's own 0.236, and greedy growth from the pentagon terminates immediately. Two sharp reasons: any single addition raises the independence number (two pentagon vertices cannot hit all five maximum independent pairs), and no two high-probability witnesses can ever be exclusive, because 2 x 3/(2 Sqrt[5]) = 3/Sqrt[5] > 1 would violate the Born rule. (3) THE CHANNEL LEDGER. The Choi-state Wigner negativity of the gates (cross-checked between the framework's two-qutrit transform and the phase-point pairing, agreement 1e-15): identity and the shift X carry 0 (Clifford); P carries 0.747106; every T_k carries the same 0.725972 \[LongDash] and the equality is now EXPLAINED, because the review of this note's own data surfaced a structural fact the flow note missed: T3 = T1 and T4 = T2 to machine precision (the cascade is gate-periodic, [P, T1, T2, T1, T2]), and T2 is a basis-permutation conjugate of T1 (machine-checked) \[LongDash] permutations are affine maps of Z_3, hence Clifford, and Clifford conjugation preserves Choi negativity. At the channel level all five gates are strongly magic-capable \[LongDash] the flow note's gate-by-gate conservation is an orbit fact riding on channels that are each nearly as non-classical as the preparation itself.*)

(* ::Section:: *)
(*1. Environment*)

(* ::Input:: *)
Quiet[If[# =!= {}, Remove @@ #] & @ Names["Global`Quantum*"]];

(* ::Input:: *)
Quiet[PacletInstall["Wolfram/QuantumFramework"]];
Needs["Wolfram`QuantumFramework`"];
QuantumState[{0, 0, 1}, 3]["Probabilities"]

(* ::Input:: *)
PacletDirectoryLoad[FileNameJoin[{Quiet@Check[NotebookDirectory[], Directory[]], "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"]; Quiet[Remove /@ Select["Global`" <> # & /@ Names["HubertKolcz`BlackBox`*"], NameQ]];

(* ::Section:: *)
(*2. The currency law: CF = (n - 1) nu on the n-cycle*)

(* ::Text:: *)
(*Both measures are linear programs over the cycle scenario's incidence matrix: the contextual fraction CF = 1 - max{Total[b] : M.b <= e, b >= 0}, and the minimal negative weight nu = min{Total[b-] : M.(b+ - b-) = e, b\[PlusMinus] >= 0}. kcbs_ledger.wl certified CF = 4 nu exactly at the C5 quantum-maximal point and observed it along the entire C5 white-noise family. The general conversion rate is the Camillo-Cervantes theorem (n - 1) CNT3 = CNTF cited above; CNTF is the ABM contextual fraction (our CF) and CNT3 the minimal-negative-mass measure (our nu, the negative weight in the deterministic-vertex decomposition). We reproduce it independently on the incidence LPs:*)

(* ::Input:: *)
nuLP[MN_, eN_] := Module[{m2 = Dimensions[MN][[2]], vp, vm},
  vp = Array[bplus, m2]; vm = Array[bminus, m2];
  LinearOptimization[Total[vm],
    Join[Thread[MN . vp - MN . vm == eN], Thread[vp >= 0], Thread[vm >= 0]],
    Join[vp, vm], "PrimalMinimumValue"]];
cfLP[MN_, eN_] := Module[{m2 = Dimensions[MN][[2]], vb},
  vb = Array[bncf, m2];
  1 + LinearOptimization[-Total[vb], Join[Thread[MN . vb <= eN], Thread[vb >= 0]],
    vb, "PrimalMinimumValue"]];
quantumRatios = Table[Module[{MN = N[CycleScenario[n]["Incidence"]], eN, nu, cf},
    eN = N[CycleModel[n, "Quantum"]]; nu = nuLP[MN, eN]; cf = cfLP[MN, eN];
    {n, cf, nu, cf/nu}], {n, {5, 7, 9, 11}}];
TableForm[quantumRatios, TableHeadings -> {None, {"n", "CF", "nu", "CF/nu"}}]

(* ::CodeText:: *)
(*Exactly, at the exclusivity-extremal Wright boxes (all data rational, so the exact Simplex applies): nu = 1/(n - 1) and CF = 1, ratio n - 1 on the nose. And exactly at the C5 quantum maximum (RevisedSimplex over Q[Sqrt[5]], as in kcbs_ledger.wl):*)

(* ::Input:: *)
wrightExact = Table[Module[{M = CycleScenario[n]["Incidence"], e, m2, vp, vm, vb, nu, ncf},
    e = CycleModel[n, "Wright"]; m2 = Dimensions[M][[2]];
    vp = Array[bplus, m2]; vm = Array[bminus, m2]; vb = Array[bncf, m2];
    nu = LinearOptimization[Total[vm],
      Join[Thread[M . vp - M . vm == e], Thread[vp >= 0], Thread[vm >= 0]],
      Join[vp, vm], "PrimalMinimumValue", Method -> "Simplex"];
    ncf = -LinearOptimization[-Total[vb], Join[Thread[M . vb <= e], Thread[vb >= 0]],
      vb, "PrimalMinimumValue", Method -> "Simplex"];
    {n, nu === 1/(n - 1), ncf === 0}], {n, {5, 7, 9}}]

(* ::Input:: *)
M5x = CycleScenario[5]["Incidence"]; e5x = CycleModel[5, "Quantum"];
vp5 = Array[bplus, 32]; vm5 = Array[bminus, 32]; vb5 = Array[bncf, 32];
nu5Exact = LinearOptimization[Total[vm5],
   Join[Thread[M5x . vp5 - M5x . vm5 == e5x], Thread[vp5 >= 0], Thread[vm5 >= 0]],
   Join[vp5, vm5], "PrimalMinimumValue", Method -> "RevisedSimplex"];
cf5Exact = 1 + LinearOptimization[-Total[vb5],
   Join[Thread[M5x . vb5 <= e5x], Thread[vb5 >= 0]], vb5,
   "PrimalMinimumValue", Method -> "RevisedSimplex"];
exactLaw = FullSimplify[cf5Exact - 4 nu5Exact] === 0

(* ::CodeText:: *)
(*Across the contextual range of the C7 white-noise family (threshold V_c \[TildeTilde] 0.677; sampled V = 0.70 to 1) the ratio stays 6; and \[LongDash] the strong form \[LongDash] at random ASYMMETRIC quantum models (random qutrit states against the fixed pentagon; sections built by the Born rule and checked no-signalling) and at random contextual no-signalling mixtures pulled toward the Wright box \[LongDash] certifying, via the sixteen odd-sign C5 correlator sums, which of them lie provably OUTSIDE the quantum set (bound 4 Sqrt[5] - 5, calibrated below on the KCBS-maximal state itself) \[LongDash] the C5 ratio is 4 every single time. The law is a property of the polytope, not of a symmetric slice:*)

(* ::Input:: *)
c7Ratios = Table[Module[{p1 = V N[Cos[Pi/7]/(1 + Cos[Pi/7])] + (1 - V)/3, MN, eN},
    MN = N[CycleScenario[7]["Incidence"]]; eN = N[CycleModel[7, 1 - 2 p1, p1]];
    cfLP[MN, eN]/nuLP[MN, eN]], {V, {0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1.}}]

(* ::Input:: *)
c2 = Cos[Pi/5]/(1 + Cos[Pi/5]);
vecs = N @ Table[{Sqrt[1 - c2] Cos[4 Pi i/5], Sqrt[1 - c2] Sin[4 Pi i/5], Sqrt[c2]}, {i, 0, 4}];
psi = {0., 0., 1.};
frame[a_, b_] := {a, b, Cross[a, b]};
stageFrames = {frame[vecs[[1]], vecs[[2]]], frame[vecs[[3]], vecs[[2]]],
               frame[vecs[[3]], vecs[[4]]], frame[vecs[[5]], vecs[[4]]],
               frame[vecs[[5]], vecs[[1]]]};
Ts = Table[stageFrames[[k + 1]] . Transpose[stageFrames[[k]]], {k, 4}];
P = Transpose @ Select[Orthogonalize[Join[{stageFrames[[1]] . psi}, IdentityMatrix[3]]],
                       Norm[#] > .5 &];
gates = Join[{P}, Ts];
prod[l_List] := If[l === {}, IdentityMatrix[3], Dot @@ Reverse[l]];
s1 = P . {1., 0., 0.};
gsP = Table[stageFrames[[1]] . vecs[[i]], {i, 5}];
M5 = N[M5x]; delta5 = CycleCoboundary[5];
asymE[st_] := Module[{p = Abs[gsP . st]^2},
  Flatten @ Table[{1 - p[[i]] - p[[Mod[i, 5] + 1]], p[[Mod[i, 5] + 1]], p[[i]], 0}, {i, 5}]];
orderingResidual = Max[Max @ Abs[asymE[s1] - N[CycleModel[5, 1 - 2/Sqrt[5], 1/Sqrt[5]]]],
   HarmonicResidual[delta5, asymE[s1]]];
SeedRandom[977];
asymRatios = Reap[Do[Module[{st, eN, cf},
      st = Normalize[s1 + 0.35 (RandomReal[{-1, 1}, 3] + I RandomReal[{-1, 1}, 3])];
      eN = asymE[st];
      If[HarmonicResidual[delta5, eN] < 10^-10,
       cf = cfLP[M5, eN];
       If[cf > 0.02, Sow[cf/nuLP[M5, eN]]]]], {40}]][[2, 1]];
wrightE = N[CycleModel[5, "Wright"]];
oddCorrMax[eN_] := Module[{corr = Table[eN[[4 i - 3]] - eN[[4 i - 2]] - eN[[4 i - 1]] + eN[[4 i]], {i, 5}]},
  Max @ Table[If[OddQ[Count[g, -1]], g . corr, -Infinity], {g, Tuples[{-1, 1}, 5]}]];
oddBoundResidual = Abs[oddCorrMax[asymE[s1]] - (4 Sqrt[5.] - 5)];
nonqSamples = Reap[Do[Module[{w, eN, cf},
      w = RandomReal[{0, 1}, 32]; w = w/Total[w];
      eN = Module[{t = RandomReal[{0.3, 1}]}, (1 - t) M5 . w + t wrightE];
      cf = cfLP[M5, eN];
      If[cf > 0.02, Sow[{cf/nuLP[M5, eN], oddCorrMax[eN]}]]], {40}]][[2, 1]];
nonqRatios = nonqSamples[[All, 1]];
beyondQuantum = Count[nonqSamples[[All, 2]], x_ /; x > 4 Sqrt[5.] - 5 + 10^-9];
{orderingResidual, oddBoundResidual, Length[asymRatios], MinMax[asymRatios],
 Length[nonqRatios], MinMax[nonqRatios], beyondQuantum}

(* ::Text:: *)
(*Reading. nu prices contextuality in negative probability; CF prices it in contextual mixture weight; on the n-cycle the exchange rate is the odd-cycle constant n - 1 = 2 alpha, apparently everywhere on the no-signalling polytope. Consistency anchors: at the Wright box, CF = 1 (strong contextuality) converts to nu = 1/(n - 1) \[LongDash] exactly the negative weight of the affine decomposition that writes the box over the deterministic vertices; and the quantum maximum's nu = (Sqrt[5] - 2)/2 is CF/4 = (2 Sqrt[5] - 4)/4. A proof should follow from the complete n-cycle noncontextuality inequality set (Araujo, Quintino, Terra Cunha, Cabello) \[LongDash] both LPs are optima of matching piecewise-linear functionals \[LongDash] but it is left open here; the machine evidence above is what this note certifies.*)

(* ::Section:: *)
(*3. The binding no-go: parity witnesses cannot beat the pentagon*)

(* ::Text:: *)
(*kcbs_ledger.wl asked whether better-chosen parity events could give the enlarged event graph a METRIC binding \[LongDash] a joint CSW violation exceeding the pentagon's own Sqrt[5] - 2. The natural pool is every parity witness the cascade owns: the minus-eigenvector of each phase-point operator at each of the five wire points, pulled back to the common post-P arena (45 rank-1 events; their Born probabilities reproduce (1 - 3 W_k(lambda))/2 across the board). Exclusivity edges to the pentagon clicks DO exist \[LongDash] 35 of them \[LongDash] but with a pointed structure, identical at every wire point: each of the seven POSITIVE-cell witnesses binds to exactly one pentagon click, while the two NEGATIVE-cell witnesses \[LongDash] the only events whose minus outcome certifies negativity (p > 1/2) \[LongDash] bind to none, ever. The events that carry the phase-space badge are precisely the ones the click exclusivity structure cannot see (consistent with kcbs_ledger.wl Section 6, where the arena pair connected only through the pass event). Metrically the pool is worthless, for two provable reasons and one exhaustive one. First, no two high-probability witnesses are ever exclusive: exclusive events satisfy p + p' <= 1, and two witnesses at the negative-cell value 3/(2 Sqrt[5]) would sum to 3/Sqrt[5] > 1. Second, ANY single event added to the pentagon raises the independence number from 2 to 3 (a vertex set hitting all five maximum independent pairs {A_i, A_i+2} needs three pentagon vertices, and an added event orthogonal to three pentagon directions would be the zero vector), so pentagon+1 always LOWERS the violation \[LongDash] the best added event costs more in alpha than it pays in probability. Third, exhaustively: the best pentagon+2 subset reaches 0.0125, an order of magnitude below the pentagon's 0.2361, and greedy growth from the pentagon terminates at the pentagon. Within the cascade's parity pool, the KCBS pentagon is the metric optimum; the two badges share topology, never strength.*)

(* ::Input:: *)
wig[v_List] := Chop[Re @ Values @ Quiet[QuantumWignerTransform[QuantumState[v, 3]]]["Amplitudes"]];
neg[w_] := -Total[Select[w, Negative]];
hs = N @ {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}, {1, 1, 0}/Sqrt[2], {1, 0, 1}/Sqrt[2],
   {0, 1, 1}/Sqrt[2], {1, I, 0}/Sqrt[2], {1, 0, I}/Sqrt[2], {0, 1, I}/Sqrt[2]};
eij[i_, j_] := Normal @ SparseArray[{{i, j} -> 1}, {3, 3}];
Gs = {eij[1, 1], eij[2, 2], eij[3, 3], eij[1, 2] + eij[2, 1], eij[1, 3] + eij[3, 1],
   eij[2, 3] + eij[3, 2], I (eij[1, 2] - eij[2, 1]), I (eij[1, 3] - eij[3, 1]),
   I (eij[2, 3] - eij[3, 2])};
Amat = Table[Re @ Tr[Outer[Times, hs[[j]], Conjugate[hs[[j]]]] . Gs[[m]]], {j, 9}, {m, 9}];
Wmat = wig /@ hs;
As = Table[3 Sum[LinearSolve[Amat, Wmat[[All, lam]]][[m]] Gs[[m]], {m, 9}], {lam, 9}];
minusVec[a_] := Module[{es = Eigensystem[a]}, Normalize @ es[[2, First @ Ordering[Re @ es[[1]], 1]]]];
minusVs = minusVec /@ As;
suffixTo[k_] := prod[gates[[2 ;; k]]];
prefixState[k_] := prod[Take[gates, k]] . {1., 0., 0.};
pool = DeleteDuplicates[
   Flatten[Table[Module[{w = ConjugateTranspose[suffixTo[k]] . minusVs[[lam]]},
      {Chop[w Exp[-I Arg[First[MaximalBy[w, Abs]]]], 10^-9], k, lam}], {k, 5}, {lam, 9}], 1],
   Max[Abs[#1[[1]] - #2[[1]]]] < 10^-8 &];
poolV = pool[[All, 1]]; poolP = Abs[Conjugate[#] . s1 & /@ poolV]^2;
pConsistency = Max @ Abs[Table[
    Abs[Conjugate[ConjugateTranspose[suffixTo[k]] . minusVs[[lam]]] . s1]^2 -
     (1 - 3 wig[prefixState[k]][[lam]])/2, {k, 5}, {lam, 9}]];
{Length[pool], pConsistency, Max[poolP], N[3/(2 Sqrt[5])]}

(* ::Input:: *)
xsP = Table[stageFrames[[1]] . stageFrames[[k, 3]], {k, 5}];
evVecs = Join[gsP, xsP, poolV];
evP = Join[ConstantArray[N[1/Sqrt[5]], 5], ConstantArray[N[1 - 2/Sqrt[5]], 5], poolP];
nEv = Length[evVecs];
adj = Table[If[i != j && Abs[Conjugate[evVecs[[i]]] . evVecs[[j]]] < 10^-9, 1, 0],
   {i, nEv}, {j, nEv}];
gFull = AdjacencyGraph[adj];
crossEdges = Total[adj[[11 ;;, 1 ;; 5]], 2];
highP = Select[Range[11, nEv], evP[[#]] > 0.6 &];
negCellIsolated = Total[adj[[highP, 1 ;; 5]], 2] == 0;
posCellDegrees = Union[Total /@ adj[[Complement[Range[11, nEv], highP], 1 ;; 5]]];
{crossEdges, negCellIsolated, posCellDegrees, Length[highP],
 Total[adj[[highP, highP]], 2]/2, Simplify[3/Sqrt[5] > 1]}

(* ::Input:: *)
subViol[s_List] := Total[evP[[s]]] - IndependenceNumber[Subgraph[gFull, s]];
base = Range[5];
singleAlphas = Table[IndependenceNumber[Subgraph[gFull, Append[base, e]]], {e, Range[6, nEv]}];
best1 = Max @ Table[subViol[Append[base, e]], {e, Range[6, nEv]}];
best2 = Max @ Table[subViol[Join[base, pr]], {pr, Subsets[Range[6, nEv], {2}]}];
greedy = Module[{cur = base, curv = subViol[base], cand, vals},
   Do[cand = Complement[Range[nEv], cur];
    vals = Table[subViol[Append[cur, e]], {e, cand}];
    If[Max[vals] > curv + 10^-10,
     curv = Max[vals]; cur = Append[cur, cand[[First @ Ordering[-vals, 1]]]],
     Break[]], {10}];
   {Length[cur], curv}];
{Union[singleAlphas], best1, best2, greedy, N[Sqrt[5] - 2]}

(* ::Section:: *)
(*4. The channel ledger: every gate is magic-capable, exactly equally for the T's*)

(* ::Text:: *)
(*The remaining variant from the flow note \[LongDash] the gates as CHANNELS in phase space. The channel-level measure is the Wigner negativity of the Choi state (I \[CircleTimes] U)|Phi> with |Phi> the maximally entangled two-qutrit state (Wang-Wilde-Su mana of channels, in its negativity form). Two independent routes must and do agree to 1e-15: the framework's native two-qutrit QuantumWignerTransform, and the pairing against the tensor products A_lambda \[CircleTimes] A_mu of the reconstructed phase-point parities. Cliffords calibrate the scale at zero (identity, cyclic shift X). The verdict sharpens the flow note maximally, and en route surfaces a structural fact the flow note never noticed: the cascade owns only TWO distinct transition matrices \[LongDash] T3 = T1 and T4 = T2 to machine precision, so the gate sequence is [P, T1, T2, T1, T2] \[LongDash] and T2 is a basis-permutation conjugate of T1 (machine-checked below). Permutations of the computational basis are affine maps of Z_3, hence Clifford, and Clifford conjugation preserves Choi-state negativity; the four equal channel values are therefore explained, not coincidental. P carries Choi negativity 0.747106; every T carries 0.725972 (equal to machine precision, spread ~1e-16). The cascade conserves the state's negativity not because its gates are weakly non-classical \[LongDash] as channels they are nearly as magic-capable as P itself \[LongDash] but because the orbit V_k psi presents each gate with the one state it happens to carry sideways.*)

(* ::Input:: *)
cascadePeriodResiduals = {Max @ Abs[Ts[[3]] - Ts[[1]]], Max @ Abs[Ts[[4]] - Ts[[2]]]};
permConjResidual = Min @ Table[Max @ Abs[p . Ts[[1]] . Transpose[p] - Ts[[2]]],
   {p, Permutations[IdentityMatrix[3]]}];
{cascadePeriodResiduals, permConjResidual}

(* ::Input:: *)
choiVec[U_] := Flatten[Transpose[U]]/Sqrt[3];
choiNegPair[U_] := Module[{v = choiVec[U]},
  -Total[Select[Chop @ Flatten @ Table[
       Re[Conjugate[v] . (KroneckerProduct[As[[l]], As[[m]]] . v)]/9, {l, 9}, {m, 9}],
     Negative]]];
choiNegFw[U_] := -Total[Select[
    Chop[Re @ Values @ Quiet[QuantumWignerTransform[
        QuantumState[choiVec[U], {3, 3}]]]["Amplitudes"]], Negative]];
channelTable = Table[Module[{nm = g[[1]], U = g[[2]]},
    {nm, choiNegPair[U], choiNegFw[U]}],
   {g, {{"Id", IdentityMatrix[3]}, {"X", RotateRight[IdentityMatrix[3]]},
     {"P", P}, {"T1", Ts[[1]]}, {"T2", Ts[[2]]}, {"T3", Ts[[3]]}, {"T4", Ts[[4]]}}}];
TableForm[channelTable, TableHeadings -> {None, {"gate", "N(Choi) pairing", "N(Choi) framework"}}]

(* ::Section:: *)
(*5. Verification*)

(* ::Input:: *)
tNegs = channelTable[[4 ;;, 2]];
EpilogueVerification = <|
  "currencyLawQuantum" -> Max @ Abs[quantumRatios[[All, 4]] - (quantumRatios[[All, 1]] - 1)] < 10^-6,
  "currencyLawWrightExact" -> And @@ Flatten[wrightExact[[All, 2 ;; 3]]],
  "currencyLawC5Exact" -> exactLaw,
  "currencyLawC7Family" -> Max @ Abs[c7Ratios - 6] < 10^-6,
  "asymmetricOrdering" -> orderingResidual < 10^-12,
  "oddBoundCalibrated" -> oddBoundResidual < 10^-10,
  "currencyLawAsymQuantum" -> Length[asymRatios] >= 30 && Max @ Abs[asymRatios - 4] < 10^-6,
  "currencyLawNoSignalling" -> Length[nonqRatios] >= 15 && Max @ Abs[nonqRatios - 4] < 10^-6,
  "someCertifiedBeyondQuantum" -> beyondQuantum >= 5,
  "poolComplete" -> Length[pool] == 45 && pConsistency < 10^-12,
  "witnessProbabilityCap" -> Abs[Max[poolP] - 3/(2 Sqrt[5.])] < 10^-12,
  "topologicalBindingExists" -> crossEdges == 35 && negCellIsolated &&
     posCellDegrees === {1},
  "highPNeverExclusive" -> Length[highP] == 10 && Total[adj[[highP, highP]], 2] == 0 &&
     Simplify[3/Sqrt[5] > 1],
  "singleAdditionRaisesAlpha" -> Union[singleAlphas] === {3},
  "metricBindingNoGo" -> best1 < 0 && best2 < 0.05 && best2 < Sqrt[5.] - 2 &&
     greedy[[1]] == 5 && Abs[greedy[[2]] - (Sqrt[5.] - 2)] < 10^-12,
  "cliffordsCarryZero" -> Max[channelTable[[1 ;; 2, 2]]] == 0 && Max[channelTable[[1 ;; 2, 3]]] == 0,
  "routesAgree" -> Max @ Abs[channelTable[[All, 2]] - channelTable[[All, 3]]] < 10^-12,
  "cascadePeriodTwo" -> Max[cascadePeriodResiduals] < 10^-13,
  "tOneTwoCliffordConjugate" -> permConjResidual < 10^-13,
  "allFourChoisCoincide" -> Max[tNegs] - Min[tNegs] < 10^-12,
  "everyGateMagicCapable" -> Min[channelTable[[3 ;;, 2]]] > 0.7 &&
     channelTable[[3, 2]] > Max[tNegs]
|>;
Column[{EpilogueVerification, "OK" -> And @@ Values[EpilogueVerification]}]

(* ::Section:: *)
(*6. Remarks*)

(* ::Text:: *)
(*Where this leaves the thread. The flow note located the negativity (born at P, parked on the undetected mode); the ledger note showed the location is cut-relative and found the frame-free invariant nu; this epilogue prices the invariant by the Camillo-Cervantes theorem CF = (n - 1) nu (independently reproduced here), certifies that the phase-space witnesses can never out-violate the pentagon they accompany (topology without metric), and shows the channel layer is uniformly magic-rich, making the cascade's conservation a statement about the orbit alone. A candid note on originality: none of these three verdicts is a new theorem - the currency law is Camillo-Cervantes (2024); the binding no-go is the exclusivity principle (Cabello 2013: pairwise-exclusive probabilities sum to at most 1, exactly the 3/Sqrt[5] > 1 obstruction) applied to specific numbers; the channel results instantiate Wang-Wilde-Su (2019). What this note adds is the explicit, machine-checked computation of all of it on the canonical Lapkiewicz KCBS circuit, plus the period-two cascade reduction and the exact constants. Open beyond this note: everything hardware-facing.*)

(* ::Section:: *)
(*References*)

(* ::Item:: *)
(*Camillo, Cervantes, Phil. Trans. R. Soc. A 382, 20230007 (2024), arXiv:2305.16574 (THE currency law: (n-1) CNT3 = CNTF for cyclic systems); Cervantes, J. Math. Psychol. 112, 102726 (2023), arXiv:2110.07113 (CNTF = 2 CNT2); Kujala, Dzhafarov, arXiv:1907.03328 (CNT2 = alpha CNT3, the negative-probabilities measure for cyclic systems).*)

(* ::Item:: *)
(*M. Araujo, M. T. Quintino, C. Budroni, M. Terra Cunha, A. Cabello, PRA 88, 022118 (2013) (all noncontextuality inequalities for the n-cycle scenario); A. Cabello, arXiv:1210.2988 (2013) (exclusivity principle: pairwise-exclusive event probabilities sum to at most 1 - the binding no-go's obstruction).*)

(* ::Item:: *)
(*S. Abramsky, R. S. Barbosa, S. Mansfield, PRL 119, 050504 (2017) (contextual fraction); S. Abramsky, A. Brandenburger, New J. Phys. 13, 113036 (2011) (negative-probability decompositions).*)

(* ::Item:: *)
(*X. Wang, M. M. Wilde, Y. Su, New J. Phys. 21, 103002 (2019) (magic of quantum channels; Choi-state measures).*)

(* ::Item:: *)
(*A. Cabello, S. Severini, A. Winter, arXiv:1010.2163 (CSW graph approach); D. Gross, J. Math. Phys. 47, 122107 (2006) (discrete Hudson theorem; Clifford positivity).*)

(* ::Item:: *)
(*Companion notes: kcbs_wigner_flow.wl, kcbs_ledger.wl (this repo); R. Lapkiewicz et al., Nature 474, 490 (2011); Klyachko, Can, Binicio\[GBreve]lu, Shumovsky, PRL 101, 020403 (2008).*)
