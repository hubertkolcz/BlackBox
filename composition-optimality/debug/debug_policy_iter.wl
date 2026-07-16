(* Instrumented small-k (K=3) run of GenerateEpsilonCertificate9.wl's Stage-1
   policy iteration, to see exactly where/why it fails to converge to the
   known-correct Gamma_3 = 1/8 = 0.125 (QUANTUM_CONTEXTUALITY.md). *)

SetDirectory[DirectoryName[$InputFileName]];
K = 3;

nodes = StringJoin /@ Tuples[{"d", "t"}, K];
edges = Select[Tuples[nodes, 2], StringDrop[#[[1]], 1] === StringDrop[#[[2]], -1] &];
Print["de Bruijn-", K, ": ", Length[nodes], " nodes, ", Length[edges], " edges"];

iu = 1; iv = 2; ia = 3; ib = 4; ip = 5;
jv = 1; jb = 2; jx = 3; jp = 4;
edgeLetter[e_] := StringTake[e[[1]], -1];

dpStates = {{0, 0}, {1, 0}, {0, 1}};
dpTransfer[letter_] := Module[{T = ConstantArray[-Infinity, {3, 3}], out, j},
   Do[If[! (dpStates[[i, 1]] == 1 && s1 == 1) && ! (s1 == 1 && s2 == 1) &&
        ! (s2 == 1 && s3 == 1) && ! (s3 == 1 && dpStates[[i, 2]] == 1),
      out = If[letter === "d", {s1, s2}, {s2, s1}];
      j = Position[dpStates, out][[1, 1]];
      T[[i, j]] = Max[T[[i, j]], s1 + s2 + s3]],
     {i, 3}, {s1, 0, 1}, {s2, 0, 1}, {s3, 0, 1}];
   T];
Td = dpTransfer["d"]; Tt = dpTransfer["t"];
Print["Td = ", Td // MatrixForm // ToString];
Print["Tt = ", Tt // MatrixForm // ToString];

Qs = Association[Table[w -> Table[Subscript[q, w, Min[i, j], Max[i, j]], {i, 5}, {j, 5}], {w, nodes}]];
Rs = Association[Table[w -> Table[Subscript[rblk, w, Min[i, j], Max[i, j]], {i, 4}, {j, 4}], {w, nodes}]];
dvar[w_] := Qs[w][[ip, ip]] + Rs[w][[jp, jp]];
phiVar[ph_, w_] := Subscript[phi, ph, w];
psiVar[w_] := Subscript[psiv, w];
rVar[e_] := Subscript[rvar, e];

qrVars = Join[
   Flatten[Table[Subscript[q, w, i, j], {w, nodes}, {i, 5}, {j, i, 5}]],
   Flatten[Table[Subscript[rblk, w, i, j], {w, nodes}, {i, 4}, {j, i, 4}]]];
potVars = Join[
   Flatten[Table[phiVar[ph, w], {ph, 0, 2}, {w, nodes}]],
   Table[psiVar[w], {w, nodes}],
   Table[rVar[e], {e, edges}],
   {gammaVar}];
allVars = Join[qrVars, potVars];

nodeCons = Flatten[Table[
    {Rs[w][[jx, jx]] == 1, Rs[w][[jx, jp]] == 1,
     Qs[w][[iv, ia]] == 0, Qs[w][[iu, ib]] == 0,
     Qs[w][[iv, ib]] + Rs[w][[jv, jb]] == 0},
    {w, nodes}]];

edgeCons = Flatten[Table[
    Module[{w = e[[1]], x = e[[2]], b, rA, rB},
      b = StringTake[w, -1];
      {rA, rB} = If[b === "d", {iu, iv}, {iv, iu}];
      {
       Qs[w][[ia, ia]] + Qs[x][[rA, rA]] + If[b === "t", Rs[x][[jv, jv]], 0] == 1,
       Qs[w][[ib, ib]] + Rs[w][[jb, jb]] + Qs[x][[rB, rB]] + If[b === "d", Rs[x][[jv, jv]], 0] == 1,
       Qs[w][[ia, ip]] + Qs[x][[rA, ip]] + If[b === "t", Rs[x][[jv, jp]], 0] == 1,
       Qs[w][[ib, ip]] + Rs[w][[jb, jp]] + Qs[x][[rB, ip]] + If[b === "d", Rs[x][[jv, jp]], 0] == 1
      }],
    {e, edges}]];

psdCons = Join[
   Table[VectorGreaterEqual[{Qs[w], 0}, {"SemidefiniteCone", 5}], {w, nodes}],
   Table[VectorGreaterEqual[{Rs[w], 0}, {"SemidefiniteCone", 4}], {w, nodes}]];

(* GAUGE-ANCHOR HYPOTHESIS TEST: Phi/Psi only ever appear as DIFFERENCES in every
   constraint -- nothing pins their absolute scale, so the solver can return an
   arbitrary (numerically wild) member of a large affine-equivalent-optima family,
   which would corrupt Improve[]'s greedy one-step-lookahead comparison even
   though gammaVar itself is still correctly optimized. Pin one reference node's
   three phase-potentials and its Psi to 0 to remove this degeneracy. *)
refNode = First[nodes];
anchorCons = {phiVar[0, refNode] == 0, phiVar[1, refNode] == 0,
   phiVar[2, refNode] == 0, psiVar[refNode] == 0};

validSigs[T_, s_] := Select[Range[3], T[[s, #]] > -Infinity &];

SolveJoint[strategy_] := Module[{potCons},
   potCons = Join[
     Flatten[Table[
       Module[{w = e[[1]], x = e[[2]], sig, T},
         T = If[edgeLetter[e] === "d", Td, Tt];
         sig = strategy[{s, e}];
         rVar[e] <= T[[s, sig]] + phiVar[sig - 1, x] - phiVar[s - 1, w]],
       {e, edges}, {s, 1, 3}]],
     Table[
      Module[{w = e[[1]], x = e[[2]]},
        dvar[x] - rVar[e] + psiVar[x] - psiVar[w] <= gammaVar],
      {e, edges}]];
   SemidefiniteOptimization[gammaVar, Join[psdCons, nodeCons, edgeCons, potCons, anchorCons], allVars]];

Improve[strategy_, sol_] := Association[Flatten[Table[
    Module[{w = e[[1]], x = e[[2]], T, valid, vals},
      T = If[edgeLetter[e] === "d", Td, Tt];
      valid = validSigs[T, s];
      vals = (T[[s, #]] + (phiVar[# - 1, x] /. sol)) & /@ valid;
      {s, e} -> valid[[First@Ordering[-vals, 1]]]],
    {e, edges}, {s, 1, 3}]]];

strategy0 = Association[Table[
   Module[{T = If[edgeLetter[e] === "d", Td, Tt], valid},
     valid = validSigs[T, s];
     {s, e} -> If[MemberQ[valid, s], s, First[valid]]],
   {e, edges}, {s, 1, 3}]];

Print["=== Strategy 0 (seed) ==="];
Print[Normal[strategy0]];

strat = strategy0;
Do[
  Print["--- round ", round, " ---"];
  sol = SolveJoint[strat];
  If[Head[sol] =!= List,
    Print["  SDP FAILED: ", sol]; Print[$MessageList]; Break[]];
  gam = gammaVar /. sol;
  Print["  Gamma = ", N[gam, 10]];
  (* dump r(e) and check r(e) truly equals the min formula independently *)
  rVals = Association[Table[e -> (rVar[e] /. sol), {e, edges}]];
  Print["  r(e) values: ", N[Values[rVals], 6]];
  (* independent recompute of r(e) from Phi (should match if SDP is behaving) *)
  rCheck = Association[Table[
     Module[{w = e[[1]], x = e[[2]], T},
       T = If[edgeLetter[e] === "d", Td, Tt];
       e -> Min[Table[Module[{sig = strat[{s, e}]},
           T[[s, sig]] + (phiVar[sig - 1, x] /. sol) - (phiVar[s - 1, w] /. sol)], {s, 3}]]],
     {e, edges}]];
  Print["  r(e) via min-formula recompute: ", N[Values[rCheck], 6]];
  Print["  r(e) matches SDP's rVar within 10^-6: ",
    AllTrue[edges, Abs[(rVals[#] - rCheck[#])] < 10^-6 &]];
  newStrat = Improve[strat, sol];
  Print["  strategy changed: ", newStrat =!= strat];
  If[newStrat === strat,
    Print["  CONVERGED at round ", round, ", final Gamma = ", N[gam, 10]];
    Break[]];
  strat = newStrat,
  {round, 1, 8}];
