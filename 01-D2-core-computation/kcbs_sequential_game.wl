(* End-to-end sequential-game quantum strategy demo, wiring together
   kcbs_circuit.wl Section 7 (the three-party KCBS game: referee draws an
   edge, Alice outputs two bits, Bob outputs one bit for one endpoint
   without knowing the edge) and Section 10 (the actual binary-POVM
   sequential-measurement machinery, binMeas) -- per the open item in
   QUANTUM_CONTEXTUALITY.md:492, "Sequential-game quantum strategy demo
   end-to-end (Alice prefix + Bob binary POVM)".

   Design (re-derived, not guessed, from Section 7's game rules + Section
   10's pullback trick):
   - Alice's move for edge/context k: run prefix_k = [P,T1,...,T_{k-1}] on
     |0>, then a 3-outcome PROJECTIVE measurement in the CURRENT
     computational basis (matching the existing "Probabilities" readout
     convention exactly: outcome 1 = detector-k clicked -> bits (1,0);
     outcome 2 = detector-(k+1) clicked -> bits (0,1); outcome 3 = neither
     -> bits (0,0)).
   - Bob's move: he is handed ONE endpoint j in {k, k+1} of the SAME edge,
     but must answer using his FIXED, real, context-independent detector
     for vertex j -- NOT a gate Alice's context happens to expose. Since
     the circuit's computational basis after prefix_k is context-k's own
     basis (by construction: P maps |0> into context-1's basis, each T_i
     advances one frame), Bob's fixed lab-frame projector |v_j><v_j| must
     be pulled back into context-k's basis before it can be applied there:
     proj_in_context_k = stageFrames[[k]] . Outer[Times,vecs[[j]],vecs[[j]]]
       . Transpose[stageFrames[[k]]]
     (stageFrames[[k]] IS the lab-frame -> context-k-basis rotation, by
     construction; conjugating a lab-frame operator by it gives that
     operator's expression in context-k's basis -- the exact same pullback
     principle as Section 10's ABA check, generalized to an arbitrary
     target vertex rather than the one specific case already built there).
   - Both measurements are applied SEQUENTIALLY to the SAME carrier (Alice
     first, Bob second, on the post-collapse state) via one
     QuantumCircuitOperator, exactly mirroring Section 10's
     measurement-gate-measurement pattern (here: measurement, [implicit
     identity], measurement, since Bob's operator is already re-expressed
     in the current frame -- no further gate is needed).
   - Win condition: Alice's bits differ (outcome in {1,2}) AND Bob's
     bit for vertex j agrees with Alice's bit for vertex j.
   - Verification target: averaging uniformly over the 5 edges and both
     of Bob's vertex choices per edge must reproduce the EXACT known
     quantum win rate 2/Sqrt[5] ~ 0.894 (Section 7's dictionary,
     independently derived there from contextProbs marginals -- here
     derived from a literal simulated sequential Alice+Bob circuit
     instead) and must NOT reproduce classical 4/5, and Bob's conditional
     agreement (given Alice's bits differ) must be exactly 1 (certainty),
     per line 337's claim. *)

Quiet[If[# =!= {}, Remove @@ #] & @ Names["Global`Quantum*"]];
Quiet[PacletInstall["Wolfram/QuantumFramework"]];
Needs["Wolfram`QuantumFramework`"];

n = 5;
c2 = Cos[Pi/n]/(1 + Cos[Pi/n]);
vecs = N@Table[{Sqrt[1 - c2] Cos[(n - 1) Pi i/n], Sqrt[1 - c2] Sin[(n - 1) Pi i/n], Sqrt[c2]},
    {i, 0, n - 1}];
psi = {0., 0., 1.};
frame[a_, b_] := {a, b, Cross[a, b]};
stageFrames = Table[
   If[OddQ[k], frame[vecs[[k]], vecs[[Mod[k, n] + 1]]], frame[vecs[[Mod[k, n] + 1]], vecs[[k]]]],
   {k, 1, n}];
Ts = Table[stageFrames[[k + 1]].Transpose[stageFrames[[k]]], {k, n - 1}];
prepCol = stageFrames[[1]].psi;
P = Transpose@Select[Orthogonalize[Join[{prepCol}, IdentityMatrix[3]]], Norm[#] > .5 &];
qutritGates = MapThread[QuantumOperator[N@#1, "Label" -> #2] &,
   {Join[{P}, Ts], Join[{"P"}, Table["T" <> ToString[k], {k, n - 1}]]}];

(* Bob's fixed lab-frame detector for vertex j, pulled back into context-k's
   basis. Verified below (BaselineCheck) against the trivial j in {k,k+1}
   cases, where the pullback must reduce EXACTLY to the plain computational
   basis projectors {1,0,0}/{0,1,0} already used for Alice's own readout --
   confirming the general pullback formula before trusting it. *)
bobProjInContextK[k_, j_] := Module[{projLab = Outer[Times, vecs[[j]], vecs[[j]]]},
   stageFrames[[k]].projLab.Transpose[stageFrames[[k]]]];

(* BUG FOUND AND FIXED (this run): the baseline check originally assumed
   vertex k is always the "up"/outcome-1 detector -- but stageFrames[[k]]'s
   row order alternates with parity (odd k: {v_k,v_{k+1},cross}, so v_k IS
   outcome-1; even k: {v_{k+1},v_k,cross}, so v_k is actually outcome-2).
   Fixed by making the expected target parity-aware. *)
outcomeIndexOfVertex[k_, j_] := Which[
   j == k, If[OddQ[k], 1, 2],
   j == Mod[k, n] + 1, If[OddQ[k], 2, 1]];

Print["=== Baseline sanity: pullback of vertex j into context-k's own basis must \
reduce to the plain computational projector at the parity-correct outcome index ==="];
baselineCheck = Table[
   Module[{jj = Mod[k, n] + 1},
     {k, Max[Abs[bobProjInContextK[k, k] - DiagonalMatrix[UnitVector[3, outcomeIndexOfVertex[k, k]]]]],
      Max[Abs[bobProjInContextK[k, jj] - DiagonalMatrix[UnitVector[3, outcomeIndexOfVertex[k, jj]]]]]}],
   {k, n}];
Print[baselineCheck];
Print["All near machine precision: ", AllTrue[baselineCheck[[All, {2, 3}]], # < 10^-10 &, 2]];

(* BUG FOUND AND FIXED (this run): key extraction assumed Keys[...][[All,1]]
   /. Subscript[_,idx_]:>idx would give a list of {aliceOutcome,bobOutcome}
   pairs -- but the ACTUAL key structure (checked directly) is
   QuditName[{Subscript[E,a],Subscript[E,b]}, Dual->False], so the old
   pattern silently extracted garbage and every win probability came back
   0/Indeterminate. Fixed to match the real structure. Hand-verified the
   underlying circuit values against the known context-1 probabilities
   (1/Sqrt[5],1/Sqrt[5],1-2/Sqrt[5]) before trusting this fix. *)
aliceProj = {DiagonalMatrix[{1., 0., 0.}], DiagonalMatrix[{0., 1., 0.}], DiagonalMatrix[{0., 0., 1.}]};
jointResults = Table[
  Module[{bobProj, jointProbs, outcomePairs, aliceOutcome, bobOutcome, wins, aliceDiffers,
     bobAgrees, winProb, condAgreeGivenDiffer, expectedIdx},
    bobProj = bobProjInContextK[k, j];
    jointProbs = QuantumCircuitOperator[Join[
        Take[qutritGates, k],
        {QuantumMeasurementOperator[aliceProj, {1}]},
        {QuantumMeasurementOperator[{bobProj, IdentityMatrix[3] - bobProj}, {1}]}]][
       QuantumState[{1, 0, 0}, 3]]["Probabilities"];
    outcomePairs = Keys[jointProbs] /. QuditName[{Subscript[_, a_], Subscript[_, b_]}, ___] :> {a, b};
    aliceOutcome = outcomePairs[[All, 1]]; bobOutcome = outcomePairs[[All, 2]];
    aliceDiffers = # != 3 & /@ aliceOutcome;
    expectedIdx = outcomeIndexOfVertex[k, j];
    bobAgrees = MapThread[Function[{ao, bo}, (bo == 1) == (ao == expectedIdx)],
       {aliceOutcome, bobOutcome}];
    winProb = Total[Pick[Values[jointProbs], MapThread[#1 && #2 &, {aliceDiffers, bobAgrees}]]];
    condAgreeGivenDiffer = winProb/Total[Pick[Values[jointProbs], aliceDiffers]];
    {k, j, N[winProb, 10], N[condAgreeGivenDiffer, 10]}],
  {k, n}, {j, {k, Mod[k, n] + 1}}];
jointResults = Flatten[jointResults, 1];
Print["=== Per-(edge, Bob-vertex) results: {k, j, winProb, P(Bob agrees | Alice differs)} ==="];
Print[jointResults];

overallWinRate = Mean[jointResults[[All, 3]]];
Print["=== VERDICT ==="];
Print["Overall win rate (uniform referee + uniform Bob choice): ", overallWinRate];
Print["Expected quantum value 2/Sqrt[5]: ", N[2/Sqrt[5], 10]];
Print["Matches quantum (not classical 4/5): ",
  Abs[overallWinRate - 2/Sqrt[5.]] < 10^-8, " / classical would be ", 4/5.];
Print["Bob agrees with certainty whenever Alice's bits differ: ",
  AllTrue[jointResults[[All, 4]], Abs[# - 1] < 10^-8 &]];
