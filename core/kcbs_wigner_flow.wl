(* ::Package:: *)

(* ::Title:: *)
(*Negativity Enters Once: Wigner Flow Through the KCBS Cascade*)

(* ::Subtitle:: *)
(*A computational note tracking the discrete Wigner function gate by gate through the Lapkiewicz circuit*)

(* ::Text:: *)
(*Hubert Ko\[LSlash]cz \[LongDash] July 2026. Companion note to kcbs_circuit.wl: Section 11 there computed the endpoints (input and prepared state); Section 13 posed the flow question this note answers. Headless verification: wolframscript -file RunWignerFlow.wl -print all (must end OK -> True). Interactive use: evaluate cell by cell from a fresh kernel \[LongDash] the first cell repairs a kernel polluted by an earlier single-block evaluation (the Global`-shadowing pitfall documented in kcbs_circuit.wl, Section 1).*)

(* ::Abstract:: *)
(*The Lapkiewicz realization of the KCBS test is one circuit on one qutrit wire \[LongDash] the cascade [P, T1, T2, T3, T4] \[LongDash] and kcbs_circuit.wl showed that its input |0> has a non-negative discrete Wigner function while the state one gate later has negativity 0.2278. Here we compute the Wigner function of every prefix of the cascade, and the result is sharper than "P is the non-stabilizer step". Negativity is born entirely at P \[LongDash] exactly 2/Sqrt[5] - 2/3 \[TildeTilde] 0.227761, as two phase-space cells of depth 1/3 - 1/Sqrt[5] each \[LongDash] and is then conserved by every T_k to machine precision: the same amount, at the same two cells, in the column of the one optical mode the detectors never monitor. What the transformations move is positive quasi-probability only, alternating between exactly two patterns in step with the experiment's detector alternation. The conservation is not a gate property: each T_k is non-Clifford and manufactures negativity 0.324 from two of the three computational basis states. It is a property of the orbit: the cascade re-expresses one fixed non-classical state in five detector frames, and the Wigner function knows it.*)

(* ::Section:: *)
(*1. Environment*)

(* ::CodeText:: *)
(*Kernel hygiene first (see kcbs_circuit.wl, Section 1), then the paclet, then a sanity check:*)

(* ::Input:: *)
Quiet[If[# =!= {}, Remove @@ #] & @ Names["Global`Quantum*"]];

(* ::Input:: *)
Quiet[PacletInstall["Wolfram/QuantumFramework"]];
Needs["Wolfram`QuantumFramework`"];

(* ::Input:: *)
QuantumState[{0, 0, 1}, 3]["Probabilities"]

(* ::Section:: *)
(*2. The cascade, restated*)

(* ::Text:: *)
(*A self-contained restatement of kcbs_circuit.wl, Sections 2-4: five pentagram directions on a cone around the z axis, stage frames encoding which detector carries which observable, transitions T_k = V_{k+1} . Transpose[V_k], and a preparation P completing V_1 . psi to a unitary. One exact identity does quiet work throughout this note: the cone parameter cos(Pi/5)/(1 + cos(Pi/5)) IS 1/Sqrt[5], so the state after prefix k \[LongDash] which is V_k . psi, the same physical psi re-expressed in the stage-k detector frame \[LongDash] has components (5^(-1/4), 5^(-1/4), \[PlusMinus]Sqrt[1 - 2/Sqrt[5]]): identical moduli in every context, and a third-component sign that alternates because Lapkiewicz et al. alternate the shared detector (the frame's handedness relative to the cone axis flips with it).*)

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

(* ::CodeText:: *)
(*The six prefix states (prefix 0 = the input |0>), and the identity they satisfy \[LongDash] prefix k equals V_k . psi:*)

(* ::Input:: *)
prefixStates = FoldList[#2 . #1 &, {1., 0., 0.}, gates];
frameResidual = Max @ Table[Norm[prefixStates[[k + 1]] - stageFrames[[k]] . psi], {k, 5}]

(* ::Section:: *)
(*3. Six states, six Wigner functions: the flow*)

(* ::CodeText:: *)
(*Discrete Wigner function of each prefix state, on the 3x3 qutrit phase space; negativity is minus the sum of the negative cells, the convention of kcbs_circuit.wl, Section 11. These five numbers (plus the zero in front) are the deliverable of this note:*)

(* ::Input:: *)
wigner[v_] := Chop[Re @ Values @ Quiet[QuantumWignerTransform[QuantumState[v, 3]]]["Amplitudes"]];
negativity[w_] := -Total[Select[w, Negative]];
wigners = wigner /@ prefixStates;
prefixNames = {"|0>", "P", "P T1", "P T1 T2", "P T1 T2 T3", "P T1 T2 T3 T4"};
WignerFlow = AssociationThread[prefixNames, negativity /@ wigners]

(* ::Input:: *)
{Min /@ wigners, N[1/3 - 1/Sqrt[5]], N[2/Sqrt[5] - 2/3]}

(* ::Text:: *)
(*Input zero; then 0.227761 five times. Negativity jumps into existence at P and every T_k transmits it unchanged \[LongDash] the flow is a step function. The plot makes the finer structure visible: after P the picture only ever alternates between two frames.*)

(* ::Input:: *)
Grid[{MapThread[MatrixPlot[Partition[#1, 3], PlotLabel -> #2, FrameTicks -> None,
    PlotRange -> {-1/3, 1/3}] &, {wigners, prefixNames}]}]

(* ::Section:: *)
(*4. Where it sits, what actually moves*)

(* ::Text:: *)
(*Index the 3x3 grid by (a, m), where m is the column: summing each column reproduces the three mode probabilities (checked below against the Born rule), so m is the mode/detector coordinate and a its conjugate. Both negative cells sit at m = 2 \[LongDash] flattened positions 6 and 9, cells (a, m) = (1, 2) and (2, 2) \[LongDash] in EVERY prefix from P onward: the negativity never moves. And m = 2 is a distinguished mode: at every stage the two detectors monitor modes 0 and 1, so the entire negativity of the state is carried by the one mode the detectors never look at. Its column is frozen at (1/3, 1/3 - 1/Sqrt[5], 1/3 - 1/Sqrt[5]), summing to the no-click probability 1 - 2/Sqrt[5] \[TildeTilde] 0.1056, while the monitored columns stay pointwise non-negative in every context.*)

(* ::Input:: *)
negCells = Flatten[Position[#, _?Negative]] & /@ wigners

(* ::Input:: *)
modeMarginals = Total[Partition[#, 3]] & /@ wigners;
bornProbs = Chop[Abs[#]^2 & /@ prefixStates];
marginalResidual = Max @ Abs[modeMarginals - bornProbs]

(* ::Input:: *)
monitoredColumnsMin = Min @ Table[Partition[w, 3][[All, {1, 2}]], {w, wigners}]

(* ::Text:: *)
(*What DOES move is positive quasi-probability in the monitored columns, and it moves between exactly two patterns: W+ (prefixes P, P..T2, P..T4) and W- (P..T1, P..T3), tracking the sign of the third stage-frame amplitude \[LongDash] i.e. the detector alternation of Section 2. With s = Sqrt[Sqrt[5] - 2], the monitored cells hold (1 + 2s)/(3 Sqrt[5]) at a = 0 and (1 - s)/(3 Sqrt[5]) at a = 1, 2 in W+, and the sign-flipped counterparts in W-. We verify the closed forms exactly, from the exact prefix state (5^(-1/4), 5^(-1/4), \[PlusMinus]Sqrt[1 - 2/Sqrt[5]]):*)

(* ::Input:: *)
u = 5^(-1/4); amp3 = Sqrt[1 - 2/Sqrt[5]];
wPlusExact  = FullSimplify[Values @ Quiet[QuantumWignerTransform[QuantumState[{u, u, amp3}, 3]]]["Amplitudes"]];
wMinusExact = FullSimplify[Values @ Quiet[QuantumWignerTransform[QuantumState[{u, u, -amp3}, 3]]]["Amplitudes"]];
exactChecks = {
  FullSimplify[Cos[Pi/5]/(1 + Cos[Pi/5]) - 1/Sqrt[5]] === 0,
  FullSimplify[wPlusExact[[{3, 6, 9}]]  - {1/3, 1/3 - 1/Sqrt[5], 1/3 - 1/Sqrt[5]}] === {0, 0, 0},
  FullSimplify[wMinusExact[[{3, 6, 9}]] - {1/3, 1/3 - 1/Sqrt[5], 1/3 - 1/Sqrt[5]}] === {0, 0, 0},
  FullSimplify[-Total[Select[wPlusExact,  # < 0 &]] - (2/Sqrt[5] - 2/3)] === 0,
  FullSimplify[-Total[Select[wMinusExact, # < 0 &]] - (2/Sqrt[5] - 2/3)] === 0,
  Max[Abs[wigners[[2]] - N[wPlusExact]]]  < 10^-12,
  Max[Abs[wigners[[3]] - N[wMinusExact]]] < 10^-12}

(* ::Text:: *)
(*So the negativity per prefix is EXACTLY 2/Sqrt[5] - 2/3: the ingredients are the flat-distribution value 1/d = 1/3 and the KCBS per-event probability 1/Sqrt[5] = theta(C5)/5, the same number that runs the whole contextuality analysis. Two cells of depth 1/Sqrt[5] - 1/3 each, parked on the undetected mode.*)

(* ::Section:: *)
(*5. Conservation is a property of the orbit, not of the gates*)

(* ::Text:: *)
(*For a single qudit of odd prime dimension the unitaries that preserve Wigner non-negativity are exactly the Clifford group (Gross). If the T_k were Clifford, the constancy above would be automatic \[LongDash] they are not, and it is not. Feeding each gate the three computational basis states (all stabilizer states, all Wigner-non-negative): P makes every one of them negative, and each T_k makes exactly two of them negative (0.324 apiece), sparing only its shared-detector mode \[LongDash] the mode it acts on as the identity, by the two-level structure of the cascade (sharedDetector = {2, 1, 2, 1}, kcbs_circuit.wl Section 3). So the T_k are negativity-CREATING gates in general; along the cascade orbit they conserve it exactly, because each one carries V_k . psi to V_{k+1} . psi \[LongDash] the same state in the next frame, up to the handedness sign that the Wigner function's negative cells turn out not to see.*)

(* ::Input:: *)
basisNegativity = Table[negativity @ wigner[g . UnitVector[3, j]], {g, gates}, {j, 3}];
TableForm[basisNegativity, TableHeadings -> {{"P", "T1", "T2", "T3", "T4"}, {"|0>", "|1>", "|2>"}}]

(* ::CodeText:: *)
(*One more identity of the cascade, free of charge: every T_k is a Givens rotation by the SAME angle, and its cosine (Tr[T_k] - 1)/2 equals the overlap of next-nearest pentagram directions \[LongDash] which is (Sqrt[5] - 1)/2, the inverse golden ratio:*)

(* ::Input:: *)
givensCos = (Tr[#] - 1)/2 & /@ Ts;
{givensCos, N[1/GoldenRatio], Chop[vecs[[1]] . vecs[[3]] - 1/GoldenRatio]}

(* ::Section:: *)
(*6. Verification*)

(* ::Input:: *)
sharedDetector = {2, 1, 2, 1};
tNegs = basisNegativity[[2 ;;]];
WignerFlowVerification = <|
  "inputStabilizer" -> Min[wigners[[1]]] >= 0,
  "normalization" -> Max[Abs[1 - Total /@ wigners]] < 10^-12,
  "prefixFrameIdentity" -> frameResidual < 10^-12,
  "negativityBornAtP" -> Abs[WignerFlow["P"] - (2/Sqrt[5.] - 2/3)] < 10^-12,
  "negativityConserved" -> Max[Abs[Values[WignerFlow][[2 ;;]] - (2/Sqrt[5.] - 2/3)]] < 10^-12,
  "cellDepthExact" -> Max[Abs[Min /@ wigners[[2 ;;]] - (1/3 - 1/Sqrt[5.])]] < 10^-12,
  "negativeCellsPinned" -> Union[negCells[[2 ;;]]] === {{6, 9}},
  "undetectedModeCarriesIt" -> monitoredColumnsMin >= 0,
  "modeMarginalsAreBorn" -> marginalResidual < 10^-12 &&
     Max[Abs[modeMarginals[[2 ;;]] -
       ConstantArray[N @ {1/Sqrt[5], 1/Sqrt[5], 1 - 2/Sqrt[5]}, 5]]] < 10^-12,
  "twoPatternAlternation" -> Max[Abs[wigners[[2]] - wigners[[4]]], Abs[wigners[[4]] - wigners[[6]]],
     Abs[wigners[[3]] - wigners[[5]]]] < 10^-12,
  "handednessAlternation" -> Sign[prefixStates[[2 ;;, 3]]] == {1, -1, 1, -1, 1},
  "exactClosedForms" -> And @@ exactChecks,
  "prepFullyNonClifford" -> Min[basisNegativity[[1]]] > 0.2,
  "transitionsNotClifford" -> And @@ Table[tNegs[[k, sharedDetector[[k]]]] == 0 &&
     Min[Delete[tNegs[[k]], sharedDetector[[k]]]] > 0.3, {k, 4}],
  "goldenGivens" -> Max[Abs[givensCos - 2/(1 + Sqrt[5.])]] < 10^-12,
  "anchorsOfSection11" -> Abs[Min[wigners[[2]]] - (-0.1139)] < 10^-4 &&
     Abs[WignerFlow["P"] - 0.2278] < 10^-4
|>;
Column[{WignerFlow, WignerFlowVerification, "OK" -> And @@ Values[WignerFlowVerification]}]

(* ::Section:: *)
(*7. Remarks*)

(* ::Text:: *)
(*In resource language (Veitch et al.): the cascade neither consumes nor replenishes the magic that P injects \[LongDash] it spends the whole budget at the first gate and then transports it losslessly, on the mode nobody measures. This sharpens the closing point of kcbs_circuit.wl, Section 11: Wigner negativity and KCBS contextuality are certificates relative to DIFFERENT measurement sets, and here the phase-space certificate literally resides in the part of the apparatus (the undetected mode) that the contextuality certificate (detector clicks) never touches. The two badges of non-classicality are not just logically independent for a single qutrit \[LongDash] in this circuit they are spatially segregated. The companion note kcbs_ledger.wl resolves that segregation: it is a property of the cheapest ledger, not of non-classicality \[LongDash] writing both sides of the Born rule in phase space moves the negativity into the effects (Heisenberg cut) without touching a single probability, the frame-free LP invariant nu = (Sqrt[5] - 2)/2 locks the currencies together (CF = 4 nu, N = 1/3 - nu/(1 + nu)), and parity witnesses read the negative cells directly.*)

(* ::Section:: *)
(*References*)

(* ::Item:: *)
(*N. Murzin, "On quantum amplitudes, correlations and negativity", Wolfram Community (https://community.wolfram.com/groups/-/m/t/3026423) \[LongDash] the QuantumWignerTransform / QuantumWeylTransform / QuantumPhaseSpaceTransform toolchain.*)

(* ::Item:: *)
(*W. K. Wootters, Ann. Phys. 176, 1 (1987) (the discrete Wigner function).*)

(* ::Item:: *)
(*D. Gross, J. Math. Phys. 47, 122107 (2006) (discrete Hudson theorem: non-negative pure states = stabilizer states; positivity-preserving unitaries = Clifford, odd d).*)

(* ::Item:: *)
(*V. Veitch, C. Ferrie, D. Gross, J. Emerson, New J. Phys. 14, 113011 (2012) (negativity as the resource for magic-state quantum computation).*)

(* ::Item:: *)
(*N. Delfosse, C. Okay, J. Bermejo-Vega, D. E. Browne, R. Raussendorf, New J. Phys. 19, 123024 (2017) (negativity <-> contextuality equivalence for n >= 2 qudits; the single-qutrit divergence).*)

(* ::Item:: *)
(*R. Lapkiewicz et al., Nature 474, 490 (2011); Klyachko, Can, Binicio\[GBreve]lu, Shumovsky, PRL 101, 020403 (2008).*)
