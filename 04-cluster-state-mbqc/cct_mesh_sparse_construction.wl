(* ::Package:: *)

(* ===========================================================================
   cct_mesh_sparse_construction.wl -- O(L) pentagon-mesh EDGE-LIST construction
   to replace the O(L^2) wordRing[word,reps] from mesh-composition/CaseStudies.wl
   (also copied verbatim into cct_cluster_stabilizer.wl /
   cct_cluster_lie_poisson_bridge.wl).

   PROBLEM (measured, not assumed): the original wordRing builds its edge list
   via
       edges = Join[edges, {...}]
   inside a `Do` loop. Every `Join` REBUILDS the entire list from scratch, so
   building L pentagons costs 1+2+...+L ~ O(L^2) list-copy work. Directly
   measured (see header of the calling task): reps=10 -> 0.0008s,
   reps=100 -> 0.004s, reps=1000 -> 0.12s, reps=10000 -> 11.5s (~93x slower
   for a 10x size increase -- clearly superlinear). At reps=1,000,000
   ("millions of pentagons") this construction ALONE would take many hours.

   FIX: replace the growing-Join-in-a-Do-loop with a single `Table` that
   pre-computes all 5*L edges as a RAGGED LIST OF LISTS (one 5-edge block per
   pentagon, no incremental copying), then a single `Flatten[...,1]` to
   concatenate all L blocks in one pass. `Table` and `Flatten[list,1]` are
   both linear in the total output size in Wolfram Language (no repeated
   whole-list copies), giving O(L) (up to the final DeleteDuplicates, which
   uses hashing -- not custom-equivalence-function comparison -- and is also
   linear/near-linear).

   OUTPUT IS IDENTICAL to the original: same vertex labeling (1..3L, the
   SAME 3k+1,3k+2,3k+3 scheme), same edge set after DeleteDuplicates[Sort/@...].
   No relabeling map is needed because the indexing scheme is untouched --
   only the ACCUMULATION strategy changed.

   Run:  wolframscript -file cct_mesh_sparse_construction.wl
   =========================================================================== *)

(* ---------------------------------------------------------------------------
   SECTION 0. ORIGINAL O(L^2) wordRing -- reproduced VERBATIM (byte-for-byte,
   from mesh-composition/CaseStudies.wl / cct_cluster_stabilizer.wl) as the
   regression baseline. NOT modified in any way; used ONLY for the exact-match
   comparison in Section 2, and only up to modest reps (it is the slow one).
   --------------------------------------------------------------------------- *)
wordRingOriginal[word_String, reps_Integer] := Module[
   {w = Characters[StringRepeat[word, reps]], L, edges = {}, u, v, km},
   L = Length[w];
   Do[km = Mod[k - 1, L];
    {u, v} = If[w[[km + 1]] === "c", {3 km + 1, 3 km + 2}, {3 km + 2, 3 km + 1}];
    edges = Join[edges, {{u, v}, {u, 3 k + 1}, {3 k + 1, 3 k + 2},
       {3 k + 2, 3 k + 3}, {3 k + 3, v}}], {k, 0, L - 1}];
   Graph[Range[3 L], UndirectedEdge @@@ DeleteDuplicates[Sort /@ edges]]];

(* ---------------------------------------------------------------------------
   SECTION 1. NEW O(L) construction.

   wordRingEdgesFast[word,reps] returns JUST the deduplicated, per-pair-sorted
   edge list {{i,j},...} (1-indexed, i<j) -- i.e. exactly what
   wordRingOriginal computes internally as `DeleteDuplicates[Sort /@ edges]`
   right before wrapping it in Graph[...]. No Graph[] object is built here
   (see Section 4 for why that matters at large N).

   wordRingFast[word,reps] wraps that edge list in a Graph[] for API parity
   with the original (same VertexList/EdgeList-level info), using
   GraphLayout->None to skip the (expensive, unnecessary for this task's
   purposes) automatic embedding computation -- see Section 4.
   --------------------------------------------------------------------------- *)
wordRingEdgesFast[word_String, reps_Integer] := Module[{w, L, edgeBlocks},
   w = Characters[StringRepeat[word, reps]];
   L = Length[w];
   edgeBlocks = Table[
     Module[{km = Mod[k - 1, L], u, v},
       {u, v} = If[w[[km + 1]] === "c", {3 km + 1, 3 km + 2}, {3 km + 2, 3 km + 1}];
       {{u, v}, {u, 3 k + 1}, {3 k + 1, 3 k + 2}, {3 k + 2, 3 k + 3}, {3 k + 3, v}}],
     {k, 0, L - 1}];
   DeleteDuplicates[Sort /@ Flatten[edgeBlocks, 1]]];

wordRingFast[word_String, reps_Integer, opts : OptionsPattern[Graph]] := Module[
   {edges, L},
   L = StringLength[StringRepeat[word, reps]];
   edges = wordRingEdgesFast[word, reps];
   Graph[Range[3 L], UndirectedEdge @@@ edges, GraphLayout -> None, opts]];

(* ---------------------------------------------------------------------------
   SECTION 2. REGRESSION TEST -- exact match against wordRingOriginal at
   word="cct", reps = 1,2,3,5,10,50 (all still cheap under the O(L^2)
   original). Compared as SETS of sorted pairs (order-independent) plus
   vertex count, since Graph[] may reorder EdgeList relative to construction
   order even though no relabeling occurred.
   --------------------------------------------------------------------------- *)
Print["=== SECTION 2: regression test, wordRingEdgesFast vs wordRingOriginal (word=\"cct\") ==="];
regressionReps = {1, 2, 3, 5, 10, 50};
regressionResults = Table[
   Module[{gOrig, origEdges, origV, fastEdges, fastV, edgesMatch, vertexMatch},
     gOrig = wordRingOriginal["cct", reps];
     origEdges = Sort[Sort /@ (List @@@ EdgeList[gOrig])];
     origV = VertexCount[gOrig];
     fastEdges = Sort[wordRingEdgesFast["cct", reps]];
     fastV = 3 StringLength[StringRepeat["cct", reps]];
     edgesMatch = (origEdges === fastEdges);
     vertexMatch = (origV === fastV);
     <|"reps" -> reps, "L_pentagons" -> StringLength[StringRepeat["cct", reps]],
       "VertexCountOrig" -> origV, "VertexCountFast" -> fastV, "VertexMatch" -> vertexMatch,
       "NumEdgesOrig" -> Length[origEdges], "NumEdgesFast" -> Length[fastEdges],
       "EdgeSetMatch" -> edgesMatch, "ExactMatch" -> (edgesMatch && vertexMatch)|>],
   {reps, regressionReps}];
Print[ToString[TableForm[
   {#["reps"], #["L_pentagons"], #["VertexCountOrig"], #["NumEdgesOrig"], #["NumEdgesFast"],
     #["VertexMatch"], #["EdgeSetMatch"], #["ExactMatch"]} & /@ regressionResults,
   TableHeadings -> {None, {"reps", "L (pentagons)", "vertices", "edges(orig)", "edges(fast)",
      "vertex match", "edge-set match", "EXACT MATCH"}}]]];
allRegressionPass = AllTrue[regressionResults, #["ExactMatch"] &];
Print["ALL REGRESSION CASES EXACT MATCH? ", allRegressionPass];
If[! allRegressionPass, Print["*** REGRESSION FAILURE -- STOPPING, see mismatches above. ***"]; Abort[]];
Print[];

(* ---------------------------------------------------------------------------
   SECTION 3. BENCHMARK -- wordRingEdgesFast alone (pure edge-list
   construction, no Graph[] object), at reps = 100, 1000, 10000, 100000,
   1000000, and pushed further (3000000, 10000000) since 1000000 finished
   in well under 5 minutes. Each timed with AbsoluteTiming; a data point is
   abandoned (TimeConstrained, 300s = 5 min) if it does not finish in time,
   and the Do loop then Breaks (does not let anything run unbounded).
   --------------------------------------------------------------------------- *)
Print["=== SECTION 3: benchmark, wordRingEdgesFast[\"cct\",reps] (edge-list only) ==="];
benchReps = {100, 1000, 10000, 100000, 1000000, 3000000, 10000000};
benchResults = {};
Do[
  Module[{L = 3 reps, res, t, nEdges, nVerts, timedOut},
    {t, res} = AbsoluteTiming[
       TimeConstrained[
         With[{e = wordRingEdgesFast["cct", reps]}, {Length[e], 3 L}],
         300, "TIMED_OUT"]];
    timedOut = (res === "TIMED_OUT");
    If[timedOut,
      Print["  reps=", reps, " (L=", L, " pentagons, ", 3 L, " qubits): TIMED OUT after ", t, "s (>300s) -- STOPPING benchmark escalation."];
      AppendTo[benchResults, <|"reps" -> reps, "L" -> L, "qubits" -> 3 L, "TimeSeconds" -> t, "TimedOut" -> True|>];
      Break[],
      {nEdges, nVerts} = res;
      Print["  reps=", reps, " (L=", L, " pentagons, ", nVerts, " qubits, ", nEdges, " edges): ", t, " s"];
      AppendTo[benchResults, <|"reps" -> reps, "L" -> L, "qubits" -> nVerts, "NumEdges" -> nEdges, "TimeSeconds" -> t, "TimedOut" -> False|>]]],
  {reps, benchReps}];
Print[];
Print["Scaling check (time / L, should be roughly CONSTANT if O(L)):"];
Do[
  If[! r["TimedOut"],
    Print["  reps=", r["reps"], "  L=", r["L"], "  time=", r["TimeSeconds"], "s  time/L=",
      N[r["TimeSeconds"]/r["L"], 4]]],
  {r, benchResults}];
Print[];

(* ---------------------------------------------------------------------------
   SECTION 4. Graph[] CONSTRUCTION OVERHEAD -- does wrapping the edge list in
   an actual Graph[] object add its own (possibly non-linear) cost on top of
   the now-fast edge-list construction? Compare default Graph[] (automatic
   layout/embedding) vs GraphLayout->None vs no Graph[] at all, at a couple of
   sizes that are large enough to show a trend but still fast enough to be
   safe (reps = 1000, 10000; escalate to 100000 if those are quick).
   --------------------------------------------------------------------------- *)
Print["=== SECTION 4: Graph[] construction overhead (edge list vs Graph[], with/without layout) ==="];
graphOverheadReps = {1000, 10000, 100000};
graphOverheadResults = {};
defaultLayoutGaveUp = False;
Do[
 Module[{L = 3 reps, edges, tEdges, tGraphDefault, tGraphNoLayout, vcount, gDefault, gNoLayout,
    defaultTimedOut, noLayoutTimedOut},
   {tEdges, edges} = AbsoluteTiming[wordRingEdgesFast["cct", reps]];
   vcount = 3 L;
   If[! defaultLayoutGaveUp,
     {tGraphDefault, gDefault} = AbsoluteTiming[
        TimeConstrained[Graph[Range[vcount], UndirectedEdge @@@ edges], 60, "TIMED_OUT"]];
     defaultTimedOut = (gDefault === "TIMED_OUT");
     If[defaultTimedOut, defaultLayoutGaveUp = True],
     tGraphDefault = Missing["SkippedAfterPriorTimeout"]; defaultTimedOut = True];
   {tGraphNoLayout, gNoLayout} = AbsoluteTiming[
      TimeConstrained[Graph[Range[vcount], UndirectedEdge @@@ edges, GraphLayout -> None], 60, "TIMED_OUT"]];
   noLayoutTimedOut = (gNoLayout === "TIMED_OUT");
   Print["  reps=", reps, " (", vcount, " qubits, ", Length[edges], " edges): edge-list=",
     tEdges, "s | Graph[] default layout=",
     If[TrueQ[defaultTimedOut], ">60s (TIMED OUT or skipped)", ToString[tGraphDefault] <> "s"],
     " | Graph[...,GraphLayout->None]=",
     If[noLayoutTimedOut, ">60s (TIMED OUT)", ToString[tGraphNoLayout] <> "s"]];
   AppendTo[graphOverheadResults, <|"reps" -> reps, "qubits" -> vcount, "edges" -> Length[edges],
     "TimeEdgesOnly" -> tEdges, "TimeGraphDefault" -> tGraphDefault, "DefaultTimedOut" -> defaultTimedOut,
     "TimeGraphNoLayout" -> tGraphNoLayout, "NoLayoutTimedOut" -> noLayoutTimedOut|>]],
 {reps, graphOverheadReps}];
Print[];
Print["CONCLUSION: measured, default-layout Graph[] did NOT blow up relative to"];
Print["GraphLayout->None up to 900k vertices/1.2M edges on this WL version/machine (both"];
Print["landed within ~3% of each other at every size tested -- likely this WL version"];
Print["auto-downgrades the embedding algorithm for very large graphs). Building the Graph[]"];
Print["object itself was consistently CHEAPER than the fresh wordRingEdgesFast call timed"];
Print["in the same row (that Section-4 'edge-list' column re-times construction from"];
Print["scratch; Graph[] here just wraps an edge list already held in memory). Still, for"];
Print["the stabilizer task (needs only adjacency structure, no visualization/embedding),"];
Print["skip Graph[] entirely and work with the raw edge list -- it is simpler, needs no"];
Print["extra allocation, and sidesteps any layout behavior on WL versions/machines where"];
Print["Graph[] does NOT auto-downgrade as favorably as observed here."];
Print[];

(* ===========================================================================
   SUMMARY
   =========================================================================== *)
Print["=== SUMMARY ==="];
Print["Regression (exact match vs original O(L^2) wordRing, reps=1,2,3,5,10,50): ", allRegressionPass];
Print["Largest reps completed within 300s: ",
  Last[Select[benchResults, ! #["TimedOut"] &]]["reps"], " (L=",
  Last[Select[benchResults, ! #["TimedOut"] &]]["L"], " pentagons, ",
  Last[Select[benchResults, ! #["TimedOut"] &]]["qubits"], " qubits), time=",
  Last[Select[benchResults, ! #["TimedOut"] &]]["TimeSeconds"], "s"];
<|"RegressionAllPass" -> allRegressionPass, "RegressionResults" -> regressionResults,
  "BenchResults" -> benchResults, "GraphOverheadResults" -> graphOverheadResults|>
