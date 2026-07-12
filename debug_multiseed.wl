(* Test whether the K=3 policy iteration escapes Gamma~0.5 with different/random
   seed strategies, since the gauge-anchor experiment showed 0.5 is a genuine
   fixed point for the specific "sig=s where valid" seed, not a numerical
   artifact. Known-correct target: Gamma_3 = 1/8 = 0.125. *)

SetDirectory[DirectoryName[$InputFileName]];
K = 3;

nodes = StringJoin /@ Tuples[{"c", "t"}, K];
edges = Select[Tuples[nodes, 2], StringDrop[#[[1]], 1] === StringDrop[#[[2]], -1] &];

iu = 1; iv = 2; ia = 3; ib = 4; ip = 5;
jv = 1; jb = 2; jx = 3; jp = 4;
edgeLetter[e_] := StringTake[e[[1]], -1];

dpStates = {{0, 0}, {1, 0}, {0, 1}};
dpTransfer[letter_] := Module[{T = ConstantArray[-Infinity, {3, 3}], out, j},
   Do[If[! (dpStates[[i, 1]] == 1 && s1 == 1) && ! (s1 == 1 && s2 == 1) &&
        ! (s2 == 1 && s3 == 1) && ! (s3 == 1 && dpStates[[i, 2]] == 1),
      out = If[letter === "c", {s1, s2}, {s2, s1}];
      j = Position[dpStates, out][[1, 1]];
      T[[i, j]] = Max[T[[i, j]], s1 + s2 + s3]],
     {i, 3}, {s1, 0, 1}, {s2, 0, 1}, {s3, 0, 1}];
   T];
Tc = dpTransfer["c"]; Tt = dpTransfer["t"];

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
      {rA, rB} = If[b === "c", {iu, iv}, {iv, iu}];
      {
       Qs[w][[ia, ia]] + Qs[x][[rA, rA]] + If[b === "t", Rs[x][[jv, jv]], 0] == 1,
       Qs[w][[ib, ib]] + Rs[w][[jb, jb]] + Qs[x][[rB, rB]] + If[b === "c", Rs[x][[jv, jv]], 0] == 1,
       Qs[w][[ia, ip]] + Qs[x][[rA, ip]] + If[b === "t", Rs[x][[jv, jp]], 0] == 1,
       Qs[w][[ib, ip]] + Rs[w][[jb, jp]] + Qs[x][[rB, ip]] + If[b === "c", Rs[x][[jv, jp]], 0] == 1
      }],
    {e, edges}]];

psdCons = Join[
   Table[VectorGreaterEqual[{Qs[w], 0}, {"SemidefiniteCone", 5}], {w, nodes}],
   Table[VectorGreaterEqual[{Rs[w], 0}, {"SemidefiniteCone", 4}], {w, nodes}]];

validSigs[T_, s_] := Select[Range[3], T[[s, #]] > -Infinity &];

SolveJoint[strategy_] := Module[{potCons},
   potCons = Join[
     Flatten[Table[
       Module[{w = e[[1]], x = e[[2]], sig, T},
         T = If[edgeLetter[e] === "c", Tc, Tt];
         sig = strategy[{s, e}];
         rVar[e] <= T[[s, sig]] + phiVar[sig - 1, x] - phiVar[s - 1, w]],
       {e, edges}, {s, 1, 3}]],
     Table[
      Module[{w = e[[1]], x = e[[2]]},
        dvar[x] - rVar[e] + psiVar[x] - psiVar[w] <= gammaVar],
      {e, edges}]];
   SemidefiniteOptimization[gammaVar, Join[psdCons, nodeCons, edgeCons, potCons], allVars]];

Improve[strategy_, sol_] := Association[Flatten[Table[
    Module[{w = e[[1]], x = e[[2]], T, valid, vals},
      T = If[edgeLetter[e] === "c", Tc, Tt];
      valid = validSigs[T, s];
      vals = (T[[s, #]] + (phiVar[# - 1, x] /. sol)) & /@ valid;
      {s, e} -> valid[[First@Ordering[-vals, 1]]]],
    {e, edges}, {s, 1, 3}]]];

runFromSeed[strategy0_, label_] := Module[{strat = strategy0, sol, gam, newStrat, history = {}},
   Do[
     sol = Check[SolveJoint[strat], $Failed];
     If[sol === $Failed || Head[sol] =!= List, Return[{label, "FAILED", history}, Module]];
     gam = gammaVar /. sol;
     AppendTo[history, N[gam, 8]];
     newStrat = Improve[strat, sol];
     If[newStrat === strat, Return[{label, N[gam, 10], history}, Module]];
     strat = newStrat,
     {round, 1, 15}];
   {label, N[gam, 10], history}];

(* Seed A: the original "sig=s where valid" seed *)
seedA = Association[Table[
   Module[{T = If[edgeLetter[e] === "c", Tc, Tt], valid},
     valid = validSigs[T, s];
     {s, e} -> If[MemberQ[valid, s], s, First[valid]]],
   {e, edges}, {s, 1, 3}]];

(* Seed B: always pick the FIRST valid sig (a different deterministic rule) *)
seedB = Association[Table[
   Module[{T = If[edgeLetter[e] === "c", Tc, Tt], valid}, valid = validSigs[T, s];
     {s, e} -> First[valid]],
   {e, edges}, {s, 1, 3}]];

(* Seed C: always pick the LAST valid sig *)
seedC = Association[Table[
   Module[{T = If[edgeLetter[e] === "c", Tc, Tt], valid}, valid = validSigs[T, s];
     {s, e} -> Last[valid]],
   {e, edges}, {s, 1, 3}]];

(* Seeds D-H: random valid choices, several different random seeds *)
randomSeed[seedNum_] := (SeedRandom[seedNum];
   Association[Table[
     Module[{T = If[edgeLetter[e] === "c", Tc, Tt], valid}, valid = validSigs[T, s];
       {s, e} -> RandomChoice[valid]],
     {e, edges}, {s, 1, 3}]]);

results = {};
AppendTo[results, runFromSeed[seedA, "A (sig=s)"]];
Print["Seed A done: ", results[[-1, 1]], " -> ", results[[-1, 2]], " history=", results[[-1, 3]]];
AppendTo[results, runFromSeed[seedB, "B (first valid)"]];
Print["Seed B done: ", results[[-1, 1]], " -> ", results[[-1, 2]], " history=", results[[-1, 3]]];
AppendTo[results, runFromSeed[seedC, "C (last valid)"]];
Print["Seed C done: ", results[[-1, 1]], " -> ", results[[-1, 2]], " history=", results[[-1, 3]]];
Do[
  AppendTo[results, runFromSeed[randomSeed[i], "random-" <> ToString[i]]];
  Print["Seed random-", i, " done: -> ", results[[-1, 2]], " history=", results[[-1, 3]]],
  {i, 1, 6}];

Print["=== SUMMARY (target Gamma_3 = 0.125) ==="];
Print[TableForm[{#[[1]], #[[2]]} & /@ results]];
Print["Best Gamma found: ", Min[Select[results[[All, 2]], NumericQ]]];
