(* Uncapped, fresh attempt at FindIndependentVertexSet[Xbar,{18}] (no TimeConstraint):
   the 900s TimeConstrained attempt in erg003_wl_native_probe.wl timed out with its search
   state fully discarded (no resume in WL's FindClique/FindIndependentVertexSet), so this is
   a from-scratch attempt with no cap. No intermediate progress telemetry is available from
   WL for this function (unlike the staged SAT run) -- this will be silent until it finishes. *)
logf = "erg003_wl_indep18_uncapped.log";
Clear[lg]; lg[msg_] := Module[{line, strm},
   line = "[" <> DateString["ISODateTime"] <> "] " <> ToString[msg];
   Print[line];
   strm = OpenAppend[logf]; WriteString[strm, line <> "\n"]; Close[strm];];
Quiet[DeleteFile[logf]];

lg["=== rebuilding Xbar (validated construction, ~97s) ==="];
t0 = AbsoluteTime[];
mods = {9, 9, 9, 5}; weights = {405, 45, 5, 1};
verts = Tuples[{Range[0, 8], Range[0, 8], Range[0, 8], Range[0, 4]}];
n = Length[verts];
adjDiffQ[d_] := d =!= {0, 0, 0, 0} && (AnyTrue[Take[d, 3], MemberQ[{1, 8}, #] &] || MemberQ[{1, 4}, d[[4]]]);
SconnBar = Select[verts, # =!= {0, 0, 0, 0} && ! adjDiffQ[#] &];
sums = Outer[Plus, verts, SconnBar, 1];
modsBcast = ConstantArray[mods, Most[Dimensions[sums]]];
nbrIdx = 1 + Mod[sums, modsBcast].weights;
edgePairs = Select[Flatten[Table[Thread[{i, nbrIdx[[i]]}], {i, 1, n}], 1], #[[1]] < #[[2]] &];
gXbar = Graph[Range[n], UndirectedEdge @@@ edgePairs];
lg["Xbar rebuilt: VertexCount=" <> ToString[VertexCount[gXbar]] <> " EdgeCount=" <> ToString[EdgeCount[gXbar]] <>
   "  [" <> ToString[AbsoluteTime[] - t0] <> "s]"];

lg["=== UNCAPPED FindIndependentVertexSet[Xbar,{18}] -- no TimeConstraint, will run until it finishes ==="];
t1 = AbsoluteTime[];
result = FindIndependentVertexSet[gXbar, {18}, 1];
lg["RESULT: " <> ToString[result] <> "  [" <> ToString[AbsoluteTime[] - t1] <> "s = " <>
   ToString[(AbsoluteTime[] - t1)/60.] <> "min]"];
If[Length[result] > 0 && Length[result[[1]]] == 18,
  lg["*** 18-INDEPENDENT-SET FOUND -- exporting for independent verification ***"];
  Export["erg003_wl_indep18_uncapped_candidate.json", verts[[result[[1]]]], "RawJSON"],
  lg["No 18-set found (empty result = exact solver exhausted the search: omega<18 rigorously, "<>
     "IF FindIndependentVertexSet used a complete/exact algorithm here -- verify method before trusting)."]];
lg["=== DONE ==="];
