(* ::Package:: *)

(* ::Title:: *)
(*Biphoton Encoding of the KCBS Cascade on the Wolfram Quantum Simulator*)

(* ::Text:: *)
(*Hubert Ko\[LSlash]cz \[LongDash] July 2026. The hardware-run thread, executed on the Wolfram Quantum Framework simulator instead of gate hardware. What a simulator CAN validate: the two-qubit triplet encoding, the collective-rotation compilation u\[CircleTimes]u of the cascade, singlet-leakage flags, the full shot-statistics pipeline, and the noise thresholds. What it CANNOT supply: evidential force \[LongDash] the sampler knows the context, which is exactly what hidden-variable models are forbidden (QUANTUM_CONTEXTUALITY.md \[Section]6). A hardware run remains the genuine platform test. Verify: wolframscript -file RunBiphotonSimulator.wl -print all \[RightArrow] OK -> True.*)

(* ::CodeText:: *)
(*Load the BlackBox paclet (geometry + cascade) and the Wolfram Quantum Framework (simulator layer):*)

(* ::Input:: *)
PacletDirectoryLoad[FileNameJoin[{Quiet@Check[NotebookDirectory[], Directory[]], "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"]; Quiet[Remove /@ Select["Global`" <> # & /@ Names["HubertKolcz`BlackBox`*"], NameQ]];
Needs["Wolfram`QuantumFramework`"];

(* ::Section:: *)
(*1. The Triplet Encoding: Qutrit in Two Photonic Qubits*)

(* ::Text:: *)
(*The biphoton qutrit lives in the symmetric (triplet) subspace of two polarization qubits. Real qutrit vectors map through the Cartesian spin-1 basis; collective rotations u\[CircleTimes]u implement SO(3) exactly; the singlet is the leakage flag.*)

(* ::Input:: *)
chi = {{-1, 0, 0, 1}/Sqrt[2], {I, 0, 0, I}/Sqrt[2], {0, 1, 1, 0}/Sqrt[2]};   (* |x>,|y>,|z> in basis |00>,|01>,|10>,|11> *)
embed[v_] := v . chi; proj[v_] := Outer[Times, embed[v], Conjugate[embed[v]]];
singlet = {0, 1, -1, 0}/Sqrt[2]; dirs = KCBSDirections[]; psi = embed[{0, 0, 1}];

(* ::CodeText:: *)
(*Encoding sanity: Cartesian states orthonormal, and the state is a valid pure QuantumState of two qubits:*)

(* ::Input:: *)
{Chop[Outer[Conjugate[#1] . #2 &, chi, chi, 1]] === IdentityMatrix[3],
 Wolfram`QuantumFramework`QuantumState[psi, {2, 2}]["Type"],
 Chop[Abs[Conjugate[singlet] . psi]^2]}

(* ::Section:: *)
(*2. Collective-Rotation Compilation of the Cascade*)

(* ::CodeText:: *)
(*Each cascade transition T = MatrixExp[so(3) generator] compiles to u\[CircleTimes]u with u from the axis-angle SU(2) lift; the phase-free transition probabilities match SO(3) exactly:*)

(* ::Input:: *)
su2[g_] := Module[{ax = So3Axis[g], th}, th = Norm[ax];
   MatrixExp[-I (th/2) (Normalize[ax] . {{{0, 1}, {1, 0}}, {{0, -I}, {I, 0}}, {{1, 0}, {0, -1}}})]];
compileDev = Max@Table[Module[{R = MatrixExp[CascadeGenerators[][[k]]], uu},
    uu = KroneckerProduct[su2[CascadeGenerators[][[k]]], su2[CascadeGenerators[][[k]]]];
    Max@Table[Abs[Abs[Conjugate[embed[IdentityMatrix[3][[a]]]] . (uu . embed[IdentityMatrix[3][[b]]])]^2 -
        (IdentityMatrix[3][[a]] . R . IdentityMatrix[3][[b]])^2], {a, 3}, {b, 3}]], {k, 4}]

(* ::Section:: *)
(*3. Shot-Sampled KCBS Statistics, Ideal and Noisy*)

(* ::Text:: *)
(*Each context measures the commuting pair (P_i, P_i+1) jointly; outcome (1,1) is forbidden by orthogonality. We sample 10^5 shots per context from the Born probabilities of the two-qubit state and estimate S = \[CapitalSigma]<A_i A_i+1> with A = 1 - 2P. White noise mixes within the triplet: \[Rho]_V = V|\[Psi]><\[Psi]| + (1-V)\[CapitalPi]_triplet/3.*)

(* ::Input:: *)
rhoV[V_] := V Outer[Times, psi, Conjugate[psi]] + (1 - V)/3 Total[proj /@ IdentityMatrix[3]];
sampleS[V_, n_] := Module[{S = 0}, Do[Module[{pi, pj, probs, cnt},
     pi = Re[Tr[rhoV[V] . proj[dirs[[i]]]]]; pj = Re[Tr[rhoV[V] . proj[dirs[[Mod[i, 5] + 1]]]]];
     probs = Normalize[Max[#, 0] & /@ {pi, pj, 1 - pi - pj}, Total];
     cnt = RandomVariate[MultinomialDistribution[n, probs]];
     S += (cnt[[3]] - cnt[[1]] - cnt[[2]])/n], {i, 5}]; S];
SeedRandom[20260710];
{sIdeal = sampleS[1, 10^5] // N, N[5 - 4 Sqrt[5]], s977 = sampleS[0.977, 10^5]}

(* ::CodeText:: *)
(*The noisy prediction in closed form, the 2011 experimental regime, and the exact death of the violation at V_crit = (5+3Sqrt[5])/20:*)

(* ::Input:: *)
sTheory[V_] := 5 - 20 (V/Sqrt[5] + (1 - V)/3);
{N[sTheory[0.977]], Simplify[sTheory[(5 + 3 Sqrt[5])/20]] == -3}

(* ::Section:: *)
(*4. Verification*)

(* ::Input:: *)
BiphotonSimulatorVerification = <|
  "encodingOrthonormal" -> Chop[Outer[Conjugate[#1] . #2 &, chi, chi, 1]] === IdentityMatrix[3],
  "frameworkState" -> Wolfram`QuantumFramework`QuantumState[psi, {2, 2}]["Type"] === "Pure",
  "singletLeakageZero" -> Chop[Abs[Conjugate[singlet] . psi]^2] === 0,
  "cascadeCompiles" -> compileDev < 10^-12,
  "idealShots" -> Abs[sIdeal - (5 - 4 Sqrt[5.])] < 0.025,
  "noisyShots977" -> Abs[s977 - sTheory[0.977]] < 0.025,
  "matches2011Regime" -> Abs[sTheory[0.977] - (-3.893)] < 0.01,
  "vCritExact" -> Simplify[sTheory[(5 + 3 Sqrt[5])/20]] == -3
|>;
Column[{BiphotonSimulatorVerification, "OK" -> And @@ Values[BiphotonSimulatorVerification]}]
