(* method_probe.wl -- measurement-only probe: builds the K=5 joint SDP for
   seed A (round-1 strategy) exactly as GenerateEpsilonCertificate9.wl does,
   then times SemidefiniteOptimization under different Method settings and
   reports gamma each time. Does NOT touch any original file. *)

K = 5;
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
      {Qs[w][[ia, ia]] + Qs[x][[rA, rA]] + If[b === "t", Rs[x][[jv, jv]], 0] == 1,
       Qs[w][[ib, ib]] + Rs[w][[jb, jb]] + Qs[x][[rB, rB]] + If[b === "d", Rs[x][[jv, jv]], 0] == 1,
       Qs[w][[ia, ip]] + Qs[x][[rA, ip]] + If[b === "t", Rs[x][[jv, jp]], 0] == 1,
       Qs[w][[ib, ip]] + Rs[w][[jb, jp]] + Qs[x][[rB, ip]] + If[b === "d", Rs[x][[jv, jp]], 0] == 1}],
    {e, edges}]];
PSDMARGIN = 10^-6;
psdCons = Join[
   Table[VectorGreaterEqual[{Qs[w] - PSDMARGIN*IdentityMatrix[5], 0}, {"SemidefiniteCone", 5}], {w, nodes}],
   Table[VectorGreaterEqual[{Rs[w] - PSDMARGIN*IdentityMatrix[4], 0}, {"SemidefiniteCone", 4}], {w, nodes}]];
validSigs[T_, s_] := Select[Range[3], T[[s, #]] > -Infinity &];
seedA = Association[Table[
   Module[{T = If[edgeLetter[e] === "d", Td, Tt], valid},
     valid = validSigs[T, s];
     {s, e} -> If[MemberQ[valid, s], s, First[valid]]],
   {e, edges}, {s, 1, 3}]];
potCons = Join[
   Flatten[Table[
     Module[{w = e[[1]], x = e[[2]], sig, T},
       T = If[edgeLetter[e] === "d", Td, Tt];
       sig = seedA[{s, e}];
       rVar[e] <= T[[s, sig]] + phiVar[sig - 1, x] - phiVar[s - 1, w]],
     {e, edges}, {s, 1, 3}]],
   Table[Module[{w = e[[1]], x = e[[2]]},
      dvar[x] - rVar[e] + psiVar[x] - psiVar[w] <= gammaVar], {e, edges}]];
consAll = Join[psdCons, nodeCons, edgeCons, potCons];

Do[Module[{res},
   res = Quiet[Check[AbsoluteTiming[
       SemidefiniteOptimization[gammaVar, consAll, allVars, Method -> m]], $Failed]];
   If[res === $Failed || Head[res[[2]]] =!= List,
     Print["[PROBE] Method ", m, " : FAILED/unavailable"],
     Print["[PROBE] Method ", m, " : ", res[[1]], " s, gamma = ",
       N[gammaVar /. res[[2]], 12]]]],
  {m, {Automatic, "CSDP", "DSDP", "SCS", "MOSEK"}}];

(* how much of a solve is symbolic->conic parse? proxy: repeat the SAME call
   (any caching would show), then time a warm second Automatic call *)
Module[{t1, t2},
  t1 = First@AbsoluteTiming[SemidefiniteOptimization[gammaVar, consAll, allVars]];
  t2 = First@AbsoluteTiming[SemidefiniteOptimization[gammaVar, consAll, allVars]];
  Print["[PROBE] Automatic repeat timings (warm): ", t1, " s then ", t2, " s"]];
Print["[PROBE] done, MaxMemoryUsed = ", N[MaxMemoryUsed[]/2^20, 5], " MB"];
