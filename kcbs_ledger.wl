(* ::Package:: *)

(* ::Title:: *)
(*One Currency for Two Badges: The Phase-Space Ledger of the KCBS Born Rule*)

(* ::Subtitle:: *)
(*A computational note reconciling Wigner negativity and contextuality in the Lapkiewicz cascade*)

(* ::Text:: *)
(*Hubert Ko\[LSlash]cz \[LongDash] July 2026. Companion note to kcbs_wigner_flow.wl (which tracked the state-side negativity gate by gate) and kcbs_circuit.wl, Section 11. Requires the Wolfram/QuantumFramework paclet and the BlackBox paclet (both loaded by the environment cells). Headless verification: wolframscript -file RunLedger.wl -print all (must end OK -> True). Interactive use: evaluate cell by cell from a fresh kernel \[LongDash] the first cell repairs a kernel polluted by an earlier single-block evaluation (the Global`-shadowing pitfall documented in kcbs_circuit.wl, Section 1).*)

(* ::Abstract:: *)
(*kcbs_wigner_flow.wl ended on a puzzle: in the Lapkiewicz cascade the two badges of non-classicality are spatially segregated \[LongDash] Wigner negativity rides the one optical mode the detectors never monitor, while KCBS contextuality lives in the clicks. This note resolves the segregation in three moves. (1) It is a property of one LEDGER, not of the physics: writing BOTH halves of the Born rule in phase space (p = 3 Sum W_E W_rho, verified exact at every cut of every context) and sliding the preparation/measurement cut through the circuit moves the negativity from the state (Schrodinger cut: 0.2278, effects clean) into the effects (Heisenberg cut: all ten pentagon effects Wigner-negative, state clean) \[LongDash] but no cut balances the books to zero; the minimum over cuts is exactly the state-side number 2/Sqrt[5] - 2/3, attained at the Schrodinger cut. (2) The frame-free invariant underneath is a linear program: the minimal negative weight nu over noncontextual decompositions of the empirical model. Exact LP (RevisedSimplex over Q[Sqrt[5]]) certifies nu = (Sqrt[5] - 2)/2, the contextual fraction CF = 2 Sqrt[5] - 4 = 4 nu, and the bridge N_Wigner = 1/3 - nu/(1 + nu). Under white noise the conversion CF = 4 nu holds along the ENTIRE visibility family and CF is exactly linear above threshold \[LongDash] but the badges decouple: Wigner negativity survives down to V* = (10 + 9 Sqrt[5])/61 ~ 0.4938 while contextuality dies at V_c = (5 + 3 Sqrt[5])/20 ~ 0.5854, leaving a window of Wigner-negative yet KCBS-noncontextual states. (3) Operationally, the negative cells are directly measurable: the phase-point operators are parity observables (eigenvalues {1, 1, -1}), and the two negative cells correspond to sharp binary measurements with outcome probability exactly 3/(2 Sqrt[5]) > 1/2. Their minus-eigenvectors interfere the two MONITORED modes, and the enlarged exclusivity graph (pentagon + pass events + parity witnesses) is connected across the badges \[LongDash] though its independence number 6 exceeds the joint quantum sum 5 - 2/Sqrt[5], so exclusivity binds the certificates topologically, not metrically.*)

(* ::Section:: *)
(*1. Environment*)

(* ::CodeText:: *)
(*Kernel hygiene, the quantum framework, and the BlackBox paclet (scenario/LP layer):*)

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
(*2. The cascade and the pairing*)

(* ::Text:: *)
(*The circuit of kcbs_circuit.wl, Sections 2-4, restated: pentagram geometry, stage frames, two-level transitions, preparation P. The one new ingredient is the PAIRING: for the discrete Wigner transform in odd dimension d, Tr[E rho] = d Sum_lambda W_E(lambda) W_rho(lambda). Writing an effect's symbol next to the state's symbol decomposes every Born probability over the 3x3 phase space \[LongDash] the two-sided ledger. We verify the pairing on the full-cascade output before using it.*)

(* ::Input:: *)
c2 = Cos[Pi/5]/(1 + Cos[Pi/5]);
vecs = N @ Table[{Sqrt[1 - c2] Cos[4 Pi i/5], Sqrt[1 - c2] Sin[4 Pi i/5], Sqrt[c2]},
                 {i, 0, 4}];
psi = {0., 0., 1.};
frame[a_, b_] := {a, b, Cross[a, b]};
stageFrames = {frame[vecs[[1]], vecs[[2]]], frame[vecs[[3]], vecs[[2]]],
               frame[vecs[[3]], vecs[[4]]], frame[vecs[[5]], vecs[[4]]],
               frame[vecs[[5]], vecs[[1]]]};
Ts = Table[stageFrames[[k + 1]] . Transpose[stageFrames[[k]]], {k, 4}];
P = Transpose @ Select[Orthogonalize[Join[{stageFrames[[1]] . psi}, IdentityMatrix[3]]],
                       Norm[#] > .5 &];
gates = Join[{P}, Ts];
x0 = {1., 0., 0.};
prod[l_List] := If[l === {}, IdentityMatrix[3], Dot @@ Reverse[l]];
s1 = P . x0;

(* ::Input:: *)
wig[v_List] := Chop[Re @ Values @ Quiet[QuantumWignerTransform[QuantumState[v, 3]]]["Amplitudes"]];
neg[w_] := -Total[Select[w, Negative]];
s5 = prod[gates] . x0;
pairingResidual5 = Max @ Abs[Abs[s5]^2 - Table[3 wig[UnitVector[3, i]] . wig[s5], {i, 3}]]

(* ::Section:: *)
(*3. The two-sided ledger and the cut scan*)

(* ::Text:: *)
(*For context k, place the cut after c gates (c = 0: Heisenberg side, the state is |0>; c = k: Schrodinger side, the effects are the bare detectors). The state at the cut is the length-c prefix acting on |0>; the three effects are the rows of the remaining suffix. At every cut the ledger reproduces the Born probabilities exactly. What moves is WHO holds the negativity: at c = k the effects are computational-basis (stabilizer) projectors with clean symbols and the state holds 2/Sqrt[5] - 2/3; at c = 0 the state is stabilizer and the effects hold it all \[LongDash] every one of the ten pentagon effects is Wigner-negative (0.20 to 0.33 each). No cut reaches zero: the minimum total over all cuts of all contexts is exactly the Schrodinger-side 0.2278 \[LongDash] the accounting used in kcbs_wigner_flow.wl was not just one choice among many, it was the CHEAPEST one, and the "segregation" was its geometry.*)

(* ::Input:: *)
cutScan = Table[Module[{sc, suf, Ns, Ne, born, led},
    sc = prod[Take[gates, c]] . x0;
    suf = prod[gates[[c + 1 ;; k]]];
    Ns = neg[wig[sc]];
    Ne = Total @ Table[neg[wig[suf[[i]]]], {i, 3}];
    born = Abs[suf . sc]^2;
    led = Table[3 wig[suf[[i]]] . wig[sc], {i, 3}];
    <|"cut" -> c, "Nstate" -> Ns, "Neffects" -> Ne, "total" -> Ns + Ne,
      "bornResidual" -> Max[Abs[born - led]]|>],
  {k, 5}, {c, 0, k}];
TableForm[{#["cut"], #["Nstate"], #["Neffects"], #["total"]} & /@ cutScan[[5]],
  TableHeadings -> {None, {"cut", "N(state)", "N(effects)", "total"}}]

(* ::Input:: *)
pairingResidual = Max[#["bornResidual"] & /@ Flatten[cutScan]];
minTotal = Min[#["total"] & /@ Flatten[cutScan]];
cheapestIsSchroedinger = And @@ Table[
   Abs[Min[#["total"] & /@ cutScan[[k]]] - cutScan[[k, -1]]["total"]] < 10^-12, {k, 5}];
tenEffectNegs = Flatten @ Table[neg[wig[prod[Take[gates, k]][[i]]]], {k, 5}, {i, 2}];
{pairingResidual, minTotal, cheapestIsSchroedinger, MinMax[tenEffectNegs]}

(* ::Section:: *)
(*4. The frame-free invariant: an exact LP triangle*)

(* ::Text:: *)
(*Underneath any particular ledger sits a frame-independent quantity. Every no-signalling empirical model is an AFFINE combination of noncontextual deterministic models (Abramsky-Brandenburger); the minimal negative weight nu in such a decomposition, e = (1 + nu) NC+ - nu NC-, is a linear program over the scenario's incidence matrix, and nu > 0 if and only if the model is contextual \[LongDash] this is the operational shadow of Spekkens' theorem that a non-negative quasi-probability representation exists exactly when a noncontextual model does. For the quantum-maximal pentagon model we solve the LP EXACTLY (RevisedSimplex handles algebraic input over Q[Sqrt[5]]), together with the noncontextual-fraction LP:*)

(* ::Input:: *)
scen = CycleScenario[5]; M = scen["Incidence"]; eQ = CycleModel[5, "Quantum"];
bp = Array[Global`bplus, 32]; bm = Array[Global`bminus, 32]; bb = Array[Global`bncf, 32];
nuExact = LinearOptimization[Total[bm],
   Join[Thread[M . bp - M . bm == eQ], Thread[bp >= 0], Thread[bm >= 0]],
   Join[bp, bm], "PrimalMinimumValue", Method -> "RevisedSimplex"];
ncfExact = -LinearOptimization[-Total[bb],
   Join[Thread[M . bb <= eQ], Thread[bb >= 0]],
   bb, "PrimalMinimumValue", Method -> "RevisedSimplex"];
cfExact = 1 - ncfExact;
{FullSimplify[nuExact], FullSimplify[cfExact]}

(* ::Text:: *)
(*The triangle of currencies, all exact: the operational negative weight nu = (Sqrt[5] - 2)/2; the contextual fraction CF = 2 Sqrt[5] - 4 = 4 nu; and the bridge to the phase-space ledger \[LongDash] the state-side Wigner negativity of kcbs_wigner_flow.wl is N = 1/3 - nu/(1 + nu), because nu/(1 + nu) is precisely the no-click probability 1 - 2/Sqrt[5] and the fixed cell W(0, 2) = 1/3 converts one into the other. Three measures, three definitions, one algebraic point.*)

(* ::Input:: *)
LedgerTriangle = <|
  "nu" -> FullSimplify[nuExact],
  "CF" -> FullSimplify[cfExact],
  "CFis4nu" -> FullSimplify[cfExact - 4 nuExact] === 0,
  "nuNormalizedIsNoClick" -> FullSimplify[nuExact/(1 + nuExact) - (1 - 2/Sqrt[5])] === 0,
  "bridgeToWigner" -> FullSimplify[1/3 - nuExact/(1 + nuExact) - (2/Sqrt[5] - 2/3)] === 0|>

(* ::Section:: *)
(*5. Noise decouples the badges*)

(* ::Text:: *)
(*Mix the KCBS state with white noise, rho_V = V |psi><psi| + (1 - V) 1/3. Exclusivity is state-independent (the projectors stay orthogonal), so the empirical model keeps p11 = 0 and per-event probability p(V) = V/Sqrt[5] + (1 - V)/3. The state-side Wigner negativity is piecewise linear with threshold V* = (10 + 9 Sqrt[5])/61 ~ 0.4938; contextuality (nu and CF alike) dies at the KCBS threshold V_c = (5 + 3 Sqrt[5])/20 ~ 0.5854. Since V* < V_c, the interval (V*, V_c) is a WINDOW of states that are Wigner-negative yet KCBS-noncontextual \[LongDash] under noise the two badges come apart cleanly, which is the honest completion of the story: the conversion rates of Section 4 are exact identities at the quantum-maximal point (and CF = 4 nu holds along the entire family), but the currencies measure genuinely different things. The maximally mixed state has the flat symbol 1/9, so W_V = V W + (1 - V)/9 by linearity:*)

(* ::Input:: *)
mixedFlatResidual = Max @ Abs[Total[wig /@ N @ IdentityMatrix[3]]/3 - 1/9];
nWigner[V_] := neg[V wig[s1] + (1 - V)/9];
nFormula[V_] := 2 Max[0, V (1/Sqrt[5.] - 1/3) - (1 - V)/9];
Vstar = (10 + 9 Sqrt[5])/61; Vc = (5 + 3 Sqrt[5])/20;
{mixedFlatResidual, N[Vstar], N[Vc], Simplify[Vstar < Vc]}

(* ::Input:: *)
MN = N[M];
nuOf[eN_] := LinearOptimization[Total[bm],
   Join[Thread[MN . bp - MN . bm == eN], Thread[bp >= 0], Thread[bm >= 0]],
   Join[bp, bm], "PrimalMinimumValue"];
cfOf[eN_] := 1 + LinearOptimization[-Total[bb],
   Join[Thread[MN . bb <= eN], Thread[bb >= 0]], bb, "PrimalMinimumValue"];
visGrid = {0.30, 0.45, N[Vstar], 0.52, 0.55, 0.58, N[Vc], 0.60, 0.65, 0.75, 0.90, 1.};
visScan = Table[Module[{p1 = V/Sqrt[5.] + (1 - V)/3, eV},
    eV = N @ CycleModel[5, 1 - 2 p1, p1];
    <|"V" -> V, "N" -> nWigner[V], "nu" -> nuOf[eV], "CF" -> cfOf[eV]|>], {V, visGrid}];
TableForm[Values /@ visScan, TableHeadings -> {None, {"V", "N_Wigner", "nu", "CF"}}]

(* ::Input:: *)
visChecks = <|
  "wignerMatchesFormula" -> Max @ Table[Abs[r["N"] - nFormula[r["V"]]], {r, visScan}] < 10^-12,
  "CFis4nuAlongFamily" -> Max @ Table[Abs[r["CF"] - 4 r["nu"]], {r, visScan}] < 10^-6,
  "sharedContextualityThreshold" -> And @@ Table[
     If[r["V"] <= N[Vc] + 10^-9, Max[r["nu"], r["CF"]] < 10^-6, Min[r["nu"], r["CF"]] > 10^-6],
     {r, visScan}],
  "CFlinearAboveThreshold" -> Max @ Table[
     Abs[r["CF"] - Max[0, (2 Sqrt[5.] - 4) (r["V"] - N[Vc])/(1 - N[Vc])]], {r, visScan}] < 10^-6,
  "windowDecoupled" -> With[{r = SelectFirst[visScan, #["V"] == 0.55 &]},
     r["N"] > 0.02 && r["nu"] < 10^-8 && r["CF"] < 10^-8]|>

(* ::Section:: *)
(*6. Reading the negative cells: parity witnesses and the enlarged event graph*)

(* ::Text:: *)
(*The phase-point operators A_lambda behind the Wigner transform are reconstructed here from the framework itself (by linearity, from nine pure states spanning the Hermitian space) and verified to be PARITY observables: Hermitian, A^2 = 1, Tr A = 1, eigenvalues {1, 1, -1}, mutually orthogonal (Tr[A A'] = 3 delta). Each Wigner cell is therefore directly measurable: W(lambda) = <A_lambda>/3, a sharp two-outcome measurement, and a NEGATIVE cell is exactly one whose minus outcome is more likely than not \[LongDash] at the two negative cells of the KCBS state the minus probability is exactly 3/(2 Sqrt[5]) ~ 0.6708. Physically the witnesses are interferometric: their minus-eigenvectors have NO component on the undetected mode (they live in the span of the two monitored modes), so although the negativity sits in the phase-space column of the unmonitored mode, reading it out interferes the modes the detectors do watch. The two badges are certified by one source, one wire, and a switchable final module \[LongDash] continue the cascade (contexts 1-5) or measure a parity (the witness contexts).*)

(* ::Input:: *)
hs = N @ {{1, 0, 0}, {0, 1, 0}, {0, 0, 1},
      {1, 1, 0}/Sqrt[2], {1, 0, 1}/Sqrt[2], {0, 1, 1}/Sqrt[2],
      {1, I, 0}/Sqrt[2], {1, 0, I}/Sqrt[2], {0, 1, I}/Sqrt[2]};
eij[i_, j_] := Normal @ SparseArray[{{i, j} -> 1}, {3, 3}];
Gs = {eij[1, 1], eij[2, 2], eij[3, 3],
      eij[1, 2] + eij[2, 1], eij[1, 3] + eij[3, 1], eij[2, 3] + eij[3, 2],
      I (eij[1, 2] - eij[2, 1]), I (eij[1, 3] - eij[3, 1]), I (eij[2, 3] - eij[3, 2])};
Amat = Table[Re @ Tr[Outer[Times, hs[[j]], Conjugate[hs[[j]]]] . Gs[[m]]], {j, 9}, {m, 9}];
Wmat = wig /@ hs;
As = Table[3 Sum[LinearSolve[Amat, Wmat[[All, lam]]][[m]] Gs[[m]], {m, 9}], {lam, 9}];
parityAlgebra = <|
  "hermitian" -> Max @ Abs[Flatten[# - ConjugateTranspose[#] & /@ As]] < 10^-12,
  "involution" -> Max @ Abs[Flatten[# . # - IdentityMatrix[3] & /@ As]] < 10^-12,
  "unitTrace" -> Max @ Abs[(Tr /@ As) - 1] < 10^-12,
  "orthogonal" -> Max @ Abs[Table[Tr[As[[l]] . As[[m]]], {l, 9}, {m, 9}] - 3 IdentityMatrix[9]] < 10^-12,
  "resolvesIdentity" -> Max @ Abs[Total[As]/3 - IdentityMatrix[3]] < 10^-12,
  "reproducesWigner" -> Max @ Abs[Table[Re @ Tr[Outer[Times, s1, Conjugate[s1]] . As[[l]]]/3, {l, 9}] - wig[s1]] < 10^-12,
  "crossChecksMixedScan" -> Abs[neg @ Chop @ Table[Re @ Tr[(0.75 Outer[Times, s1, Conjugate[s1]] + 0.25/3 IdentityMatrix[3]) . As[[l]]]/3, {l, 9}] - nWigner[0.75]] < 10^-12|>

(* ::Input:: *)
minusVec[a_] := Module[{es = Eigensystem[a]}, Normalize @ es[[2, First @ Ordering[Re @ es[[1]], 1]]]];
v6 = minusVec[As[[6]]]; v9 = minusVec[As[[9]]];
witnessProbs = {Abs[Conjugate[v6] . s1]^2, Abs[Conjugate[v9] . s1]^2};
{witnessProbs, N[3/(2 Sqrt[5])], Abs[v6[[3]]], Abs[v9[[3]]]}

(* ::CodeText:: *)
(*The enlarged event set at the post-P wire: 5 pentagon click events (prob 1/Sqrt[5]), 5 pass-mode events (prob 1 - 2/Sqrt[5]), 2 parity witnesses (prob 3/(2 Sqrt[5])). Exclusivity = orthogonality. The witnesses attach to the graph through the stage-1 pass event (their minus-eigenvectors are orthogonal to it), so the graph is CONNECTED across the badges \[LongDash] but alpha = 6 while the joint quantum sum is exactly 5 - 2/Sqrt[5] ~ 4.106: no joint CSW violation. Exclusivity binds the two certificates topologically, not metrically; the binding that certifies is the shared preparation.*)

(* ::Input:: *)
gs = Table[stageFrames[[1]] . vecs[[i]], {i, 5}];
xs = Table[stageFrames[[1]] . stageFrames[[k, 3]], {k, 5}];
eventLabels = Join[Table["A" <> ToString[i], {i, 5}], Table["pass" <> ToString[k], {k, 5}], {"W6", "W9"}];
eventVecs = Join[gs, xs, {v6, v9}];
eventProbs = Abs[Conjugate[#] . s1]^2 & /@ eventVecs;
edges = Select[Subsets[Range[12], {2}],
   Abs[Conjugate[eventVecs[[#[[1]]]]] . eventVecs[[#[[2]]]]] < 10^-9 &];
expectedEdges = Sort[Sort /@ Join[
   {{1, 2}, {2, 3}, {3, 4}, {4, 5}, {1, 5}},
   {{1, 6}, {2, 6}, {2, 7}, {3, 7}, {3, 8}, {4, 8}, {4, 9}, {5, 9}, {5, 10}, {1, 10}},
   {{6, 11}, {6, 12}}]];
eventGraphBig = Graph[Range[12], UndirectedEdge @@@ edges];
{Sort[Sort /@ edges] === expectedEdges,
 alphaBig = IndependenceNumber[eventGraphBig],
 thetaBig = LovaszTheta[eventGraphBig],
 quantumSumBig = Total[eventProbs], N[5 - 2/Sqrt[5]]}

(* ::Section:: *)
(*7. Verification*)

(* ::Input:: *)
LedgerVerification = <|
  "pairingExact" -> pairingResidual5 < 10^-12 && pairingResidual < 10^-12,
  "heisenbergCutAllInEffects" ->
     Max @ Table[cutScan[[k, 1]]["Nstate"], {k, 5}] == 0 && Min[tenEffectNegs] > 0.2,
  "schroedingerCutAllInState" ->
     Max @ Table[cutScan[[k, -1]]["Neffects"], {k, 5}] == 0 &&
     Max @ Table[Abs[cutScan[[k, -1]]["Nstate"] - (2/Sqrt[5.] - 2/3)], {k, 5}] < 10^-12,
  "ledgerNeverBalancesToZero" -> minTotal > 0.2,
  "schroedingerCutCheapest" -> cheapestIsSchroedinger &&
     Abs[minTotal - (2/Sqrt[5.] - 2/3)] < 10^-12,
  "nuExact" -> FullSimplify[nuExact - (Sqrt[5] - 2)/2] === 0,
  "cfExact" -> FullSimplify[cfExact - (2 Sqrt[5] - 4)] === 0,
  "triangleIdentities" -> LedgerTriangle["CFis4nu"] && LedgerTriangle["nuNormalizedIsNoClick"] &&
     LedgerTriangle["bridgeToWigner"],
  "mixedIsFlat" -> mixedFlatResidual < 10^-12,
  "wignerNoiseFormula" -> visChecks["wignerMatchesFormula"],
  "windowExists" -> Simplify[Vstar < Vc] && visChecks["windowDecoupled"],
  "sharedContextualityThreshold" -> visChecks["sharedContextualityThreshold"],
  "CFis4nuAlongFamily" -> visChecks["CFis4nuAlongFamily"],
  "CFlinearAboveThreshold" -> visChecks["CFlinearAboveThreshold"],
  "parityAlgebra" -> And @@ Values[parityAlgebra],
  "parityEigenvalues" -> Max @ Abs[Sort[Chop[Eigenvalues[#]]] & /@ As - ConstantArray[{-1, 1, 1}, 9]] < 10^-12,
  "witnessProbability" -> Max @ Abs[witnessProbs - 3/(2 Sqrt[5.])] < 10^-12,
  "witnessInterferesMonitoredModes" -> Max[Abs[v6[[3]]], Abs[v9[[3]]]] < 10^-12,
  "enlargedGraphConnectedAcrossBadges" -> Sort[Sort /@ edges] === expectedEdges &&
     ConnectedGraphQ[eventGraphBig],
  "eventProbsExact" -> Max @ Abs[eventProbs - N @ Join[ConstantArray[1/Sqrt[5], 5],
     ConstantArray[1 - 2/Sqrt[5], 5], ConstantArray[3/(2 Sqrt[5]), 2]]] < 10^-12,
  "noJointViolation" -> alphaBig == 6 && Abs[thetaBig - 6] < 10^-4 &&
     Abs[quantumSumBig - (5 - 2/Sqrt[5.])] < 10^-12 && quantumSumBig < alphaBig
|>;
Column[{LedgerTriangle, LedgerVerification, "OK" -> And @@ Values[LedgerVerification]}]

(* ::Section:: *)
(*8. Remarks*)

(* ::Text:: *)
(*What, in the end, resolves the segregation? Not a theorem that the two badges are secretly the same number \[LongDash] the noise window of Section 5 refutes that cleanly. The resolution is a change of question. "Where does the negativity live?" has no frame-independent answer: Section 3 moves it from the undetected mode's column (state side) into all ten click effects (Heisenberg side) without changing a single observable probability. The frame-independent facts are (i) the LEDGER NEVER BALANCES \[LongDash] every cut of every context keeps at least 2/Sqrt[5] - 2/3 of negativity somewhere, (ii) the LP invariant nu = (Sqrt[5] - 2)/2 > 0, which is the operational statement that no noncontextual accounting exists at all (Spekkens' equivalence, made computable), and (iii) at the quantum-maximal point the three currencies are locked by exact conversion rates \[LongDash] CF = 4 nu and N = 1/3 - nu/(1 + nu) \[LongDash] rates that survive along the whole noise family for CF and nu but not for N, because phase-space negativity answers to a finer measurement set (the parities of Section 6) than the pentagon statistics do. The spatial segregation of the opening question was real, but it was a fact about the cheapest ledger, not about non-classicality \[LongDash] and the parity witnesses show that even that geometry is operationally two-faced: negativity parked on the unmonitored mode is read out by interfering the monitored ones.*)

(* ::Section:: *)
(*References*)

(* ::Item:: *)
(*R. W. Spekkens, PRL 101, 020401 (2008) (negativity and contextuality as equivalent notions of nonclassicality).*)

(* ::Item:: *)
(*C. Ferrie, J. Emerson, J. Phys. A 41, 352001 (2008); New J. Phys. 11, 063040 (2009) (frame representations; no positive frame for quantum theory).*)

(* ::Item:: *)
(*S. Abramsky, A. Brandenburger, New J. Phys. 13, 113036 (2011) (affine/negative-probability decompositions of no-signalling models).*)

(* ::Item:: *)
(*S. Abramsky, R. S. Barbosa, S. Mansfield, PRL 119, 050504 (2017) (the contextual fraction).*)

(* ::Item:: *)
(*H. Pashayan, J. J. Wallman, S. D. Bartlett, PRL 115, 070501 (2015) (negativity as sampling cost).*)

(* ::Item:: *)
(*M. Howard, J. Wallman, V. Veitch, J. Emerson, Nature 510, 351 (2014) (contextuality supplies the magic).*)

(* ::Item:: *)
(*W. K. Wootters, Ann. Phys. 176, 1 (1987); D. Gross, J. Math. Phys. 47, 122107 (2006) (discrete Wigner function; discrete Hudson theorem).*)

(* ::Item:: *)
(*V. Veitch, C. Ferrie, D. Gross, J. Emerson, New J. Phys. 14, 113011 (2012); N. Delfosse et al., New J. Phys. 19, 123024 (2017) (negativity as magic resource; single-qutrit divergence).*)

(* ::Item:: *)
(*A. Cabello, S. Severini, A. Winter, arXiv:1010.2163 (the graph approach used for the enlarged event graph).*)

(* ::Item:: *)
(*R. Lapkiewicz et al., Nature 474, 490 (2011); Klyachko, Can, Binicio\[GBreve]lu, Shumovsky, PRL 101, 020403 (2008); N. Murzin, Wolfram Community (https://community.wolfram.com/groups/-/m/t/3026423).*)
