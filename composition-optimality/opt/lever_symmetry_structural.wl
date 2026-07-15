(* LEVER 4 structural test: does the windowed transfer-SDP constraint system
   admit an EXACT automorphism implementing word-reversal, c<->t swap, or
   reversal+swap -- allowing NODE-DEPENDENT signed-permutation gauges on the
   Q (5x5) / R (4x4) blocks and node-dependent phase permutations on Phi?
   Pure symbolic set-equality of constraints; no SDP solves. *)

SetDirectory[DirectoryName[$InputFileName]];

(* ---------- constraint templates (verbatim structure from
   GenerateEpsilonCertificate9.wl; q[u,i,j] i<=j upper entries of Q[u],
   rb[u,i,j] of R[u]) ---------- *)
nodeConsE[u_] := {rb[u,3,3] - 1, rb[u,3,4] - 1, q[u,2,3], q[u,1,4],
   q[u,2,4] + rb[u,1,2]};
edgeConsE[w_, x_, b_] := If[b === "c",
   {q[w,3,3] + q[x,1,1] - 1,
    q[w,4,4] + rb[w,2,2] + q[x,2,2] + rb[x,1,1] - 1,
    q[w,3,5] + q[x,1,5] - 1,
    q[w,4,5] + rb[w,2,4] + q[x,2,5] + rb[x,1,4] - 1},
   {q[w,3,3] + q[x,2,2] + rb[x,1,1] - 1,
    q[w,4,4] + rb[w,2,2] + q[x,1,1] - 1,
    q[w,3,5] + q[x,2,5] + rb[x,1,4] - 1,
    q[w,4,5] + rb[w,2,4] + q[x,1,5] - 1}];

canon[ex_] := Module[{x = Expand[ex], vl},
   vl = Variables[x];
   If[vl === {}, x, If[Coefficient[x, First[Sort[vl]]] < 0, -x, x]]];
canonSet[l_List] := Sort[canon /@ l];

(* transport of node u's block vars to node mu under
   g = {piQ(5-list, fixes 5), sQ(5-list, sQ5=1), piR(4-list, fixes 4), sR} *)
tRules[u_, mu_, g_] := Join[
   Flatten@Table[q[u,i,j] ->
      g[[2,i]] g[[2,j]] q[mu, Min[g[[1,i]], g[[1,j]]], Max[g[[1,i]], g[[1,j]]]],
     {i, 5}, {j, i, 5}],
   Flatten@Table[rb[u,i,j] ->
      g[[4,i]] g[[4,j]] rb[mu, Min[g[[3,i]], g[[3,j]]], Max[g[[3,i]], g[[3,j]]]],
     {i, 4}, {j, i, 4}]];

(* ---------- Part A1: admissible per-node gauges (must map nodeCons to
   nodeCons and preserve dvar = Q[5,5]+R[4,4], i.e. piQ(5)=5, piR(4)=4) ---- *)
nodeTemplate = canonSet[nodeConsE[V]];
cands = Reap[
    Do[Module[{g = {Join[pQ, {5}], Join[sQ, {1}], Join[pR, {4}], Join[sR, {1}]}},
       If[canonSet[nodeConsE[U] /. tRules[U, V, g]] === nodeTemplate, Sow[g]]],
      {pQ, Permutations[Range[4]]}, {sQ, Tuples[{1, -1}, 4]},
      {pR, Permutations[Range[3]]}, {sR, Tuples[{1, -1}, 3]}]][[2]];
cands = If[cands === {}, {}, cands[[1]]];
nc = Length[cands];
Print["Part A1: admissible per-node signed-permutation gauges (nodeCons- and ",
  "dvar-preserving): ", nc];
Print["  distinct piQ: ", Union[cands[[All,1]]], "  distinct piR: ",
  Union[cands[[All,3]]]];

(* ---------- Part A2: edge-compatibility tables. For a candidate symmetry,
   edge e=(w,x) with source-letter b maps to image edge with source-letter bp:
   - direction-REVERSING (reversal, rev+swap): e' = (m x, m w):
       transported cons(e) must equal edgeConsE[MX, MW, bp]
   - direction-PRESERVING (swap): e' = (m w, m x):
       transported cons(e) must equal edgeConsE[MW, MX, bp]           ---- *)
edgeOK[gW_, gX_, b_, bp_, dirRev_] := Module[{lhs, rhs},
   lhs = canonSet[edgeConsE[W, X, b] /. tRules[W, MW, gW] /. tRules[X, MX, gX]];
   rhs = If[dirRev, canonSet[edgeConsE[MX, MW, bp]],
     canonSet[edgeConsE[MW, MX, bp]]];
   lhs === rhs];

letters = {"c", "t"};
Print["Part A2: building 2x2x2 edge-compatibility tables over ", nc, "^2 gauge ",
  "pairs (this is the expensive symbolic step)..."];
tstart = AbsoluteTime[];
pairTable = Association[];
Do[pairTable[{b, bp, dirRev}] =
    SparseArray[
      Table[Boole[edgeOK[cands[[i]], cands[[j]], b, bp, dirRev]],
        {i, nc}, {j, nc}]],
   {b, letters}, {bp, letters}, {dirRev, {True, False}}];
Print["  tables built in ", Round[AbsoluteTime[] - tstart, 0.1], " s"];
Do[Print["  allowed (gW,gX) pairs for (b=", b, " -> b'=", bp, ", dirRev=",
    dirRev, "): ", Total[pairTable[{b, bp, dirRev}], 2], " / ", nc^2],
  {b, letters}, {bp, letters}, {dirRev, {True, False}}];

(* ---------- Part A3: CSP over the de Bruijn graph for each node map ------ *)
flip[c_] := If[c === "c", "t", "c"];
runCSP[K_, mapName_, dirRev_, bpFun_] := Module[
   {nodes, edges, cand, changed, empty = False, w, x, b, bp, tbl, ok},
   nodes = StringJoin /@ Tuples[{"c", "t"}, K];
   edges = Select[Tuples[nodes, 2],
     StringDrop[#[[1]], 1] === StringDrop[#[[2]], -1] &];
   cand = Association[Table[u -> Range[nc], {u, nodes}]];
   changed = True;
   While[changed && ! empty, changed = False;
    Do[w = e[[1]]; x = e[[2]];
      b = StringTake[w, -1]; bp = bpFun[w, x];
      tbl = pairTable[{b, bp, dirRev}];
      ok = Select[cand[w],
        Function[i, AnyTrue[cand[x], tbl[[i, #]] == 1 &]]];
      If[Length[ok] < Length[cand[w]], cand[w] = ok; changed = True];
      ok = Select[cand[x],
        Function[j, AnyTrue[cand[w], tbl[[#, j]] == 1 &]]];
      If[Length[ok] < Length[cand[x]], cand[x] = ok; changed = True];
      If[cand[w] === {} || cand[x] === {}, empty = True; Break[]],
     {e, edges}]];
   If[empty || AnyTrue[nodes, cand[#] === {} &],
    Module[{bad = Select[nodes, cand[#] === {} &]},
     Print["  K=", K, " ", mapName,
       ": NO automorphism -- arc consistency emptied candidate set",
       If[bad =!= {}, " at node(s) " <> ToString[Take[bad, UpTo[4]]], ""]];
     False],
    Print["  K=", K, " ", mapName, ": arc-consistent candidate sets survive, ",
      "sizes min/max = ", Min[Length /@ Values[cand]], "/",
      Max[Length /@ Values[cand]],
      "  (NOT yet a proof of existence -- needs DFS witness)"];
    True]];

Print["Part A3: CSP for each candidate node map, Q/R constraint side:"];
Do[
  Print[" map = reversal (w->rev w, e->(rev x, rev w)), K=", K];
  runCSP[K, "reversal", True, Function[{w, x}, StringTake[w, {2}]]];
  Print[" map = swap (w->sw w, e->(sw w, sw x)), K=", K];
  runCSP[K, "swap", False, Function[{w, x}, flip[StringTake[w, -1]]]];
  Print[" map = rev+swap, K=", K];
  runCSP[K, "rev+swap", True, Function[{w, x}, flip[StringTake[w, {2}]]]],
  {K, {4, 5}}];

(* ---------- Part B: game/Phi side -- node-dependent phase permutations.
   Transfer matrices: *)
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
TM["c"] = Tc; TM["t"] = Tt;
taus = Permutations[Range[3]];

(* finiteness-pattern compatibility:
   dirRev: need pattern T_bp[s,sig] finite <=> T_b[tauW[sig], tauX[s]] finite
   dirPres: need T_bp[s,sig] finite <=> T_b[tauW[s], tauX[sig]] finite *)
gameOK[tW_, tX_, b_, bp_, dirRev_] := Module[{ok = True},
   Do[Module[{lhsFin, rhsFin},
      lhsFin = TM[bp][[s, sig]] > -Infinity;
      rhsFin = If[dirRev, TM[b][[tW[[sig]], tX[[s]]]] > -Infinity,
        TM[b][[tW[[s]], tX[[sig]]]] > -Infinity];
      If[lhsFin =!= rhsFin, ok = False]],
     {s, 3}, {sig, 3}]; ok];

gamePairTable = Association[];
Do[gamePairTable[{b, bp, dirRev}] =
    Table[Boole[gameOK[taus[[i]], taus[[j]], b, bp, dirRev]], {i, 6}, {j, 6}],
   {b, letters}, {bp, letters}, {dirRev, {True, False}}];
Do[Print["  game-side allowed (tauW,tauX) for (b=", b, "->b'=", bp, ", dirRev=",
    dirRev, "): ", Total[gamePairTable[{b, bp, dirRev}], 2], " / 36"],
  {b, letters}, {bp, letters}, {dirRev, {True, False}}];

runGameCSP[K_, mapName_, dirRev_, bpFun_] := Module[
   {nodes, edges, cand, changed, empty = False, w, x, b, bp, tbl, ok},
   nodes = StringJoin /@ Tuples[{"c", "t"}, K];
   edges = Select[Tuples[nodes, 2],
     StringDrop[#[[1]], 1] === StringDrop[#[[2]], -1] &];
   cand = Association[Table[u -> Range[6], {u, nodes}]];
   changed = True;
   While[changed && ! empty, changed = False;
    Do[w = e[[1]]; x = e[[2]];
      b = StringTake[w, -1]; bp = bpFun[w, x];
      tbl = gamePairTable[{b, bp, dirRev}];
      ok = Select[cand[w], Function[i, AnyTrue[cand[x], tbl[[i, #]] == 1 &]]];
      If[Length[ok] < Length[cand[w]], cand[w] = ok; changed = True];
      ok = Select[cand[x], Function[j, AnyTrue[cand[w], tbl[[#, j]] == 1 &]]];
      If[Length[ok] < Length[cand[x]], cand[x] = ok; changed = True];
      If[cand[w] === {} || cand[x] === {}, empty = True; Break[]],
     {e, edges}]];
   If[empty || AnyTrue[nodes, cand[#] === {} &],
    Module[{bad = Select[nodes, cand[#] === {} &]},
     Print["  K=", K, " ", mapName, " (game side): NO phase transport -- ",
       "candidate set emptied",
       If[bad =!= {}, " at node(s) " <> ToString[Take[bad, UpTo[4]]], ""]];
     False],
    Print["  K=", K, " ", mapName, " (game side): survives arc consistency, ",
      "candidate sizes min/max = ", Min[Length /@ Values[cand]], "/",
      Max[Length /@ Values[cand]]];
    True]];

Print["Part B: CSP for the Phi/dpTransfer game side (finiteness patterns):"];
Do[
  runGameCSP[K, "reversal", True, Function[{w, x}, StringTake[w, {2}]]];
  runGameCSP[K, "swap", False, Function[{w, x}, flip[StringTake[w, -1]]]];
  runGameCSP[K, "rev+swap", True, Function[{w, x}, flip[StringTake[w, {2}]]]],
  {K, {4, 5}}];

Print["DONE"];
