(* Generalization of kcbs_circuit.wl's Encoding A (native qutrit circuit,
   Sections 2-5) from the pentagon (n=5) to general odd n, specifically
   n=7 and n=9 -- the "n-cycle generalizations (C7, C9...) and their
   circuits" open item from QUANTUM_CONTEXTUALITY.md:430-431.

   Derivation of the general azimuth step (verbatim reasoning, checked
   against the n=5 code): vectors sit on a cone, z-component Sqrt[c2],
   xy-radius Sqrt[1-c2], so the dot product of two vectors at azimuthal
   separation phi is (1-c2)*Cos[phi] + c2. Requiring this to vanish for
   CYCLICALLY ADJACENT vectors gives Cos[phi] = -c2/(1-c2) = -Cos[Pi/n]
   (using c2 = Cos[Pi/n]/(1+Cos[Pi/n])) = Cos[(n-1)Pi/n], so the required
   azimuth step is phi = (n-1)Pi/n. For n=5 this gives 4Pi/5, EXACTLY
   matching kcbs_circuit.wl's hardcoded "4 Pi i/5" -- confirming the
   general formula before trusting it at n=7,9. Odd n is required for the
   n steps to close into a single n-cycle (n*phi = (n-1)*Pi, an integer
   multiple of 2*Pi exactly when n-1 is even, i.e. n is odd) -- this
   reproduces, from the circuit side, why odd cycles are structurally
   required (matches the graph-side Specker/NCHV-saturation argument
   already established for C3/C5 elsewhere in this project).

   ONLY extends Encoding A (native qutrit circuit) -- Encoding B (two-qubit
   biphoton) is qutrit(spin-1)-specific and would need a genuinely
   different multi-qubit/qudit encoding for n=7,9, not attempted here. *)

Quiet[If[# =!= {}, Remove @@ #] & @ Names["Global`Quantum*"]];
Quiet[PacletInstall["Wolfram/QuantumFramework"]];
Needs["Wolfram`QuantumFramework`"];

buildNCycleCircuit[n_Integer /; OddQ[n] && n >= 3] := Module[
  {c2, vecs, psi, frame, stageFrames, Ts, sharedDetector, twoLevelDeviation,
   prepCol, P, qutritGates, circuit, prefixes, contextProbs, corr, SQuditN,
   thetaClosedForm, observablesN, MM, eigCheck},

  c2 = Cos[Pi/n]/(1 + Cos[Pi/n]);
  vecs = N@Table[{Sqrt[1 - c2] Cos[(n - 1) Pi i/n], Sqrt[1 - c2] Sin[(n - 1) Pi i/n],
      Sqrt[c2]}, {i, 0, n - 1}];
  psi = {0., 0., 1.};

  frame[a_, b_] := {a, b, Cross[a, b]};
  (* Re-derived (not guessed) from the literal n=5 code: context k's frame
     is frame[v_k, v_{k+1}] when k is odd, frame[v_{k+1}, v_k] when k is
     even (1-indexed, wraparound via Mod[k,n]+1) -- i.e. the "shared"
     vertex alternates between the first and second slot of consecutive
     frames, exactly the detector-alternation trick. Verified by hand
     against all 5 of kcbs_circuit.wl's explicit stageFrames lines before
     trusting it here: k=1..5 gives frame[1,2], frame[3,2], frame[3,4],
     frame[5,4], frame[5,1] -- an exact match. *)
  stageFrames = Table[
     If[OddQ[k], frame[vecs[[k]], vecs[[Mod[k, n] + 1]]],
       frame[vecs[[Mod[k, n] + 1]], vecs[[k]]]],
     {k, 1, n}];

  Ts = Table[stageFrames[[k + 1]].Transpose[stageFrames[[k]]], {k, n - 1}];
  sharedDetector = Table[If[OddQ[k], 2, 1], {k, n - 1}];
  twoLevelDeviation = Max@Table[Max[
      Abs[Ts[[k, sharedDetector[[k]]]] - UnitVector[3, sharedDetector[[k]]]],
      Abs[Ts[[k, All, sharedDetector[[k]]]] - UnitVector[3, sharedDetector[[k]]]]],
     {k, n - 1}];

  prepCol = stageFrames[[1]].psi;
  P = Transpose@Select[Orthogonalize[Join[{prepCol}, IdentityMatrix[3]]], Norm[#] > .5 &];
  qutritGates = MapThread[QuantumOperator[N@#1, "Label" -> #2] &,
     {Join[{P}, Ts], Join[{"P"}, Table["T" <> ToString[k], {k, n - 1}]]}];
  circuit = QuantumCircuitOperator[qutritGates];
  prefixes = Table[QuantumCircuitOperator[Take[qutritGates, k]], {k, n}];
  contextProbs = Table[Values@prefixes[[k]][QuantumState[{1, 0, 0}, 3]]["Probabilities"], {k, n}];
  corr = (#[[3]] - #[[1]] - #[[2]]) & /@ contextProbs;
  SQuditN = Total[corr];
  thetaClosedForm = N[n Cos[Pi/n]/(1 + Cos[Pi/n])];

  <|"n" -> n, "cyclicOrthogonality" -> Chop@Table[vecs[[k]].vecs[[Mod[k, n] + 1]], {k, n}],
    "psiOverlap" -> (vecs.psi)^2, "expectedOverlap" -> N[1/Sqrt[n]],
    "twoLevelDeviation" -> twoLevelDeviation,
    "S_qutrit" -> SQuditN, "n_minus_4theta" -> N[n - 4 thetaClosedForm, 10],
    "match" -> Abs[SQuditN - (n - 4 thetaClosedForm)] < 10^-8,
    "thetaClosedForm" -> thetaClosedForm|>];

Print["=== Baseline sanity: n=5 must reproduce the ORIGINAL kcbs_circuit.wl result ==="];
r5 = buildNCycleCircuit[5];
Print["n=5: S_qutrit = ", r5["S_qutrit"], " (expect 5-4Sqrt[5] = ", N[5 - 4 Sqrt[5], 10], ")"];
Print["  matches original: ", Abs[r5["S_qutrit"] - (5 - 4 Sqrt[5.])] < 10^-8];
Print["  twoLevelDeviation: ", r5["twoLevelDeviation"], ", cyclicOrthogonality: ", r5["cyclicOrthogonality"]];

Print["=== n=7 (heptagon) ==="];
r7 = buildNCycleCircuit[7];
Print[r7];

Print["=== n=9 (nonagon) ==="];
r9 = buildNCycleCircuit[9];
Print[r9];

Print["=== VERDICT ==="];
Print["n=5 baseline OK: ", Abs[r5["S_qutrit"] - (5 - 4 Sqrt[5.])] < 10^-8];
Print["n=7 internally consistent (S_qutrit == n-4theta): ", r7["match"]];
Print["n=9 internally consistent (S_qutrit == n-4theta): ", r9["match"]];
Print["n=7 two-level & orthogonality clean: ", r7["twoLevelDeviation"] < 10^-8, " ",
  Max[Abs[r7["cyclicOrthogonality"]]] < 10^-8];
Print["n=9 two-level & orthogonality clean: ", r9["twoLevelDeviation"] < 10^-8, " ",
  Max[Abs[r9["cyclicOrthogonality"]]] < 10^-8];
