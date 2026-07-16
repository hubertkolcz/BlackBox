(* Hypothesis: Phi returned by the JOINT (Q,R,Phi,Psi,Gamma) solve is NOT the
   canonical mean-payoff-game bias function for the fixed strategy -- it is
   merely SOME jointly-optimal allocation entangled with the Q/R choice, which
   misleads Improve[]'s greedy one-step lookahead (confirmed empirically: 9
   different seeds converge to at least 3 DISTINCT fixed points -- 0.5, 0.377,
   0.293 -- which cannot happen under correct policy iteration for a
   mean-payoff game, where every improving sequence must reach the SAME global
   optimum). FIX: decouple -- compute the CANONICAL Phi for the current fixed
   strategy via its own small LP (maximize the worst-case r(e) using ONLY the
   game constraints, with NO Q/R/Psi involved at all), and use THAT Phi to
   drive Improve[]. Still use the full joint SDP to report the actual Gamma
   (since Q,R,Psi legitimately need to jointly optimize against whatever r(e)
   profile the strategy achieves). *)

SetDirectory[DirectoryName[$InputFileName]];
K = 3;

nodes = StringJoin /@ Tuples[{"d", "t"}, K];
edges = Select[Tuples[nodes, 2], StringDrop[#[[1]], 1] === StringDrop[#[[2]], -1] &];

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

Qs = Association[Table[w -> Table[Subscript[q, w, Min[i, j], Max[i, j]], {i, 5}, {j, 5}], {w, nodes}]];
Rs = Association[Table[w -> Table[Subscript[rblk, w, Min[i, j], Max[i, j]], {i, 4}, {j, 4}], {w, nodes}]];
dvar[w_] := Qs[w][[ip, ip]] + Rs[w][[jp, jp]];
phiVar[ph_, w_] := Subscript[phi, ph, w];
psiVar[w_] := Subscript[psiv, w];
rVar[e_] := Subscript[rvar, e];

qrVars = Join[
   Flatten[Table[Subscript[q, w, i, j], {w, nodes}, {i, 5}, {j, i, 5}]],
   Flatten[Table[Subscript[rblk, w, i, j], {w, nodes}, {i, 4}, {j, i, 4}]]];
phiVars = Flatten[Table[phiVar[ph, w], {ph, 0, 2}, {w, nodes}]];
potVars = Join[phiVars, Table[psiVar[w], {w, nodes}], Table[rVar[e], {e, edges}], {gammaVar}];
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

validSigs[T_, s_] := Select[Range[3], T[[s, #]] > -Infinity &];

(* DECOUPLED canonical game solve: maximize the worst (minimum) r(e) achievable
   by ANY choice of Phi, for the FIXED strategy -- pure LP, no Q/R/Psi at all.
   This is the textbook "solve for state values under a fixed policy" step of
   policy iteration, done as its own well-posed problem instead of leaking into
   the joint SDP. Anchor phi[0,refNode]=0 to remove the (harmless, since this
   solve doesn't touch Q/R) 1-dim additive gauge freedom, purely for numerical
   sanity -- does not change which strategy looks best. *)
refNode = First[nodes];
CanonicalPhi[strategy_] := Module[{potCons, sol, tVar},
   potCons = Flatten[Table[
      Module[{w = e[[1]], x = e[[2]], sig, T},
        T = If[edgeLetter[e] === "d", Td, Tt];
        sig = strategy[{s, e}];
        tVar <= T[[s, sig]] + phiVar[sig - 1, x] - phiVar[s - 1, w]],
      {e, edges}, {s, 1, 3}]];
   sol = Quiet[Check[
      LinearOptimization[-tVar, Join[potCons, {phiVar[0, refNode] == 0}],
        Append[phiVars, tVar]], $Failed]];
   sol];

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
   SemidefiniteOptimization[gammaVar, Join[psdCons, nodeCons, edgeCons, potCons], allVars]];

(* Improve[] now uses the CANONICAL (decoupled) phi solution, not the joint
   solve's entangled one. *)
ImproveCanonical[strategy_, canonSol_] := Association[Flatten[Table[
    Module[{w = e[[1]], x = e[[2]], T, valid, vals},
      T = If[edgeLetter[e] === "d", Td, Tt];
      valid = validSigs[T, s];
      vals = (T[[s, #]] + (phiVar[# - 1, x] /. canonSol)) & /@ valid;
      {s, e} -> valid[[First@Ordering[-vals, 1]]]],
    {e, edges}, {s, 1, 3}]]];

runFromSeed[strategy0_, label_] := Module[
  {strat = strategy0, canonSol, jointSol, gam, newStrat, history = {}},
  Do[
    canonSol = CanonicalPhi[strat];
    If[canonSol === $Failed, Return[{label, "CANON_FAILED", history}, Module]];
    jointSol = Check[SolveJoint[strat], $Failed];
    gam = If[jointSol === $Failed || Head[jointSol] =!= List, "JOINT_FAILED",
       N[gammaVar /. jointSol, 8]];
    AppendTo[history, gam];
    newStrat = ImproveCanonical[strat, canonSol];
    If[newStrat === strat, Return[{label, gam, history}, Module]];
    strat = newStrat,
    {round, 1, 20}];
  {label, gam, history}];

seedA = Association[Table[
   Module[{T = If[edgeLetter[e] === "d", Td, Tt], valid}, valid = validSigs[T, s];
     {s, e} -> If[MemberQ[valid, s], s, First[valid]]],
   {e, edges}, {s, 1, 3}]];
seedB = Association[Table[
   Module[{T = If[edgeLetter[e] === "d", Td, Tt], valid}, valid = validSigs[T, s];
     {s, e} -> First[valid]],
   {e, edges}, {s, 1, 3}]];
randomSeed[seedNum_] := (SeedRandom[seedNum];
   Association[Table[
     Module[{T = If[edgeLetter[e] === "d", Td, Tt], valid}, valid = validSigs[T, s];
       {s, e} -> RandomChoice[valid]],
     {e, edges}, {s, 1, 3}]]);

results = {};
AppendTo[results, runFromSeed[seedA, "A (sig=s)"]];
Print["Seed A: -> ", results[[-1, 2]], "  history=", results[[-1, 3]]];
AppendTo[results, runFromSeed[seedB, "B (first valid)"]];
Print["Seed B: -> ", results[[-1, 2]], "  history=", results[[-1, 3]]];
Do[
  AppendTo[results, runFromSeed[randomSeed[i], "random-" <> ToString[i]]];
  Print["Seed random-", i, ": -> ", results[[-1, 2]], "  history=", results[[-1, 3]]],
  {i, 1, 4}];

Print["=== SUMMARY (target Gamma_3 = 0.125) ==="];
Print[{#[[1]], #[[2]]} & /@ results];
