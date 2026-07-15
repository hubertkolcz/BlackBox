(* Native-Wolfram-first probe for ERG-003: before trusting more custom Python (elim2/SAT/NN),
   test what WL's own built-ins can do directly on the SAME problem.
   KEY IDEA (native-first correctness note): omega(G)>=18 clique-in-G is the SAME question as
   an 18-independent-set in Xbar=complement(G). G is DENSE (degree 2616/3644); Xbar is SPARSE
   (degree 1028). Exact clique/independent-set solvers (degeneracy ordering, coloring bounds)
   are typically far more effective on the SPARSE formulation -- test FindIndependentVertexSet
   on Xbar FIRST, FindClique on G second, for a genuine apples-to-apples native comparison.
   Vectorized construction validated: Outer[Plus,verts,connSet,1] + ConstantArray-broadcast Mod
   + dot-product indexing (3.3s for Xbar, degree-1028 confirmed for every vertex). *)
logf = "erg003_wl_native_probe.log";
Clear[lg]; lg[msg_] := Module[{line, strm},
   line = "[" <> DateString["ISODateTime"] <> "] " <> ToString[msg];
   Print[line];
   strm = OpenAppend[logf]; WriteString[strm, line <> "\n"]; Close[strm];];
Quiet[DeleteFile[logf]];

lg["=== building vertex/connection-set structures ==="];
t0 = AbsoluteTime[];
mods = {9, 9, 9, 5};
weights = {405, 45, 5, 1};
verts = Tuples[{Range[0, 8], Range[0, 8], Range[0, 8], Range[0, 4]}];
n = Length[verts]; (* 3645 *)
adjDiffQ[d_] := d =!= {0, 0, 0, 0} && (AnyTrue[Take[d, 3], MemberQ[{1, 8}, #] &] || MemberQ[{1, 4}, d[[4]]]);
Sconn = Select[verts, adjDiffQ]; (* G connection set, degree 2616 *)
SconnBar = Select[verts, # =!= {0, 0, 0, 0} && ! adjDiffQ[#] &]; (* Xbar connection set, degree 1028 *)
lg["|S_G|=" <> ToString[Length[Sconn]] <> "  |S_Xbar|=" <> ToString[Length[SconnBar]] <>
   "  [" <> ToString[AbsoluteTime[] - t0] <> "s]"];

buildGraph[connSet_, label_] := Module[{sums, modsBcast, modded, nbrIdx, edgePairs, g, dt0},
   dt0 = AbsoluteTime[];
   sums = Outer[Plus, verts, connSet, 1];
   modsBcast = ConstantArray[mods, Most[Dimensions[sums]]];
   modded = Mod[sums, modsBcast];
   nbrIdx = 1 + modded.weights;
   lg[label <> ": neighbor table built dims=" <> ToString[Dimensions[nbrIdx]] <>
      "  [" <> ToString[AbsoluteTime[] - dt0] <> "s]"];
   edgePairs = Select[Flatten[Table[Thread[{i, nbrIdx[[i]]}], {i, 1, n}], 1], #[[1]] < #[[2]] &];
   g = Graph[Range[n], UndirectedEdge @@@ edgePairs];
   lg[label <> ": Graph built VertexCount=" <> ToString[VertexCount[g]] <> " EdgeCount=" <>
      ToString[EdgeCount[g]] <> " deg(v1)=" <> ToString[VertexDegree[g, 1]] <>
      "  [total " <> ToString[AbsoluteTime[] - dt0] <> "s]"];
   g];

gXbar = buildGraph[SconnBar, "Xbar"];

lg["=== SPARSE-FIRST TEST: FindIndependentVertexSet[Xbar,{18}], TimeConstraint 900s ==="];
t1 = AbsoluteTime[];
ind18 = TimeConstrained[FindIndependentVertexSet[gXbar, {18}, 1], 900, $TimedOut];
lg["FindIndependentVertexSet[Xbar,{18}] result: " <> ToString[ind18] <> "  [" <>
   ToString[AbsoluteTime[] - t1] <> "s]"];
If[ind18 =!= $TimedOut && Length[ind18] > 0 && Length[ind18[[1]]] == 18,
  lg["*** 18-INDEPENDENT-SET IN Xbar = 18-CLIQUE IN G CANDIDATE -- exporting for independent verification ***"];
  Export["erg003_wl_findindep18_candidate.json", verts[[ind18[[1]]]], "RawJSON"]];

lg["=== SPARSE sanity: FindIndependentVertexSet[Xbar,{17}] (expect success, fast) ==="];
t1b = AbsoluteTime[];
ind17 = TimeConstrained[FindIndependentVertexSet[gXbar, {17}, 1], 120, $TimedOut];
lg["FindIndependentVertexSet[Xbar,{17}]: found=" <>
   ToString[ind17 =!= $TimedOut && Length[ind17] > 0 && Length[ind17[[1]]] == 17] <>
   "  [" <> ToString[AbsoluteTime[] - t1b] <> "s]"];

lg["=== unconstrained max independent set in Xbar, TimeConstraint 300s (what does WL find unprompted?) ==="];
t2 = AbsoluteTime[];
indMax = TimeConstrained[FindIndependentVertexSet[gXbar], 300, $TimedOut];
lg["FindIndependentVertexSet[Xbar] (max) result size: " <>
   ToString[If[indMax === $TimedOut, "$TimedOut", Length[indMax]]] <>
   "  [" <> ToString[AbsoluteTime[] - t2] <> "s]"];

lg["=== building G (dense) for the direct FindClique comparison ==="];
gDense = buildGraph[Sconn, "G"];

lg["=== DENSE comparison: FindClique[G,{18}], TimeConstraint 900s ==="];
t3 = AbsoluteTime[];
c18 = TimeConstrained[FindClique[gDense, {18}, 1], 900, $TimedOut];
lg["FindClique[G,{18}] result: " <> ToString[c18] <> "  [" <> ToString[AbsoluteTime[] - t3] <> "s]"];
If[c18 =!= $TimedOut && Length[c18] > 0 && Length[c18[[1]]] == 18,
  lg["*** 18-CLIQUE IN G CANDIDATE (dense route) -- exporting for independent verification ***"];
  Export["erg003_wl_findclique18_candidate.json", verts[[c18[[1]]]], "RawJSON"]];

lg["=== GraphAutomorphismGroup on Xbar (sparser, likely faster), TimeConstraint 300s (cross-check |Aut|=349920) ==="];
t4 = AbsoluteTime[];
aut = TimeConstrained[GraphAutomorphismGroup[gXbar], 300, $TimedOut];
If[aut =!= $TimedOut,
  lg["GraphAutomorphismGroup[Xbar] order: " <> ToString[GroupOrder[aut]] <> "  (expect 349920)  [" <>
     ToString[AbsoluteTime[] - t4] <> "s]"],
  lg["GraphAutomorphismGroup[Xbar]: $TimedOut  [" <> ToString[AbsoluteTime[] - t4] <> "s]"]];

lg["=== PROBE DONE ==="];
