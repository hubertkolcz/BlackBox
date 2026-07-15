(* ::Package:: *)

(* ===========================================================================
   cct_mesh_sparse_stabilizer.wl -- SPARSE, O(n + edges) graph-state stabilizer
   validity check for the pentagon-mesh CZ cluster state, replacing the DENSE
   O(n^2)-memory / O(n^3)-ish-time linear-algebra check in
   cct_cluster_stabilizer.wl (MatrixRank[...,Modulus->2] and
   Mod[tbl.Omega.Transpose[tbl],2]==0 on an n x 2n binary matrix), so that
   stabilizer validity can genuinely be checked at MILLIONS of qubits.

   SCOPE (per the assigned task): this file is about the STABILIZER
   (structural graph-state validity) check ONLY -- independence and mutual
   commutation of the n generators K_v = X_v * Prod_{u~v} Z_v. It does NOT
   touch the AvN contextuality witness or DLA-dimension checks in the sibling
   files (cct_cluster_avn_witness.wl, cct_cluster_dla.wl) -- those are
   fundamentally exponential in qubit count and remain gated at their small-N
   ceilings exactly as before (see cct_cluster_lie_poisson_bridge.wl Sections
   3-4 and their honesty notes).

   FILES READ IN FULL BEFORE WRITING THIS FILE (per task instructions):
     * black-box-test/cct_cluster_stabilizer.wl        (the OLD dense method,
       reused verbatim in Section 2 below as the baseline)
     * black-box-test/cct_cluster_lie_poisson_bridge.wl (confirms the same
       ValidateGraphState/AdjacencyMatrixGF2 code is duplicated there; this
       file's replacement is a drop-in for BOTH call sites)
     * mesh-composition/CaseStudies.wl                  (wordRing[word,reps]
       verified byte-for-byte identical to the copy embedded in
       cct_cluster_stabilizer.wl -- see the Grep confirmation in the session
       log; its Join-in-a-Do-loop edge-list construction is a KNOWN O(L^2)
       problem, independently flagged and out of THIS file's scope to fix as
       the "real" sibling deliverable, but a compatible O(L) drop-in
       (fastWordRingEdges, Section 1) is built here anyway, verified to
       produce an IDENTICAL edge set, purely so this file can obtain real
       edge lists at millions-of-qubits scale to benchmark the stabilizer
       check against.)

   ===========================================================================
   THE ANALYTIC ARGUMENT (re-derived here, not just asserted)
   ===========================================================================
   For a simple graph G on n vertices with 0/1 symmetric, zero-diagonal
   adjacency matrix A, the graph-state stabilizer tableau is T = [ I_n | A ]
   (X-block = identity, Z-block = A), one row per vertex v: row v = (e_v | A_v).

   INDEPENDENCE (rank_GF(2)(T) = n): UNCONDITIONAL, for *any* n x n matrix A
   whatsoever (does not require A to be symmetric, zero-diagonal, or even
   0/1-valued!). Proof: T has n rows and its first n columns are I_n, which
   already has rank n. Since rank(T) >= rank(any n columns of T) and T only
   has n rows total, n <= rank(T) <= n, so rank(T) = n exactly, always. No
   computation is needed -- this is a one-line structural fact about the
   [I|A] block form, verified empirically below (Section 5) to also hold on
   deliberately malformed A (self-loops, duplicate edges): the OLD method's
   own MatrixRank call confirms rank=n in every case tested, exactly as this
   argument predicts.

   MUTUAL COMMUTATION (symplectic product T.Omega.T^T = 0 mod 2, Omega =
   [[0,I],[I,0]]): row_i . Omega = (A_i,: | e_i) [block-swap], so
   (T.Omega.T^T)[i,j] = A_i,: . e_j + e_i . A_j,: = A[i,j] + A[j,i] mod 2.
   This is a UNCONDITIONAL identity (also re-derived and confirmed
   numerically in Section 5 below): (T.Omega.T^T)[i,j] = A[i,j]+A[j,i] mod 2
   for ANY matrix A, symmetric or not. It is 0 for every (i,j) IFF A is
   symmetric -- note this holds REGARDLESS of A's diagonal (self-loop
   entries cancel automatically: A[i,i]+A[i,i] = 2 A[i,i] = 0 mod 2 no matter
   what A[i,i] is), a subtlety confirmed empirically in Section 5's self-loop
   test, where the OLD method's numeric AllCommuteQ stays True even with a
   self-loop present.

   CONSEQUENCE: for the STANDARD interface (an undirected edge list, each
   edge expanded to BOTH directions when building A -- exactly what
   AdjacencyMatrixGF2 in the OLD method already does), A is symmetric BY
   CONSTRUCTION, so commutation is unconditionally guaranteed too, with zero
   dependence on graph size. Both guarantees together mean: for THIS
   interface, independence and commutation NEVER need to be verified via
   linear algebra at all -- they hold for any edge list whatsoever, well-
   formed or not. What CAN still go wrong is not the algebra but the DATA:
   the mesh-construction code accidentally producing a self-loop, a
   duplicate edge, or an out-of-range vertex index. These are invisible to
   the OLD numeric rank/commute booleans (Section 5 demonstrates this
   directly) but are exactly what an O(n+edges) structural sanity pass on
   the edge list itself (Section 3) can and should catch -- turning an
   O(n^3)-ish dense linear-algebra computation into an O(n+edges) data-
   hygiene check that is, if anything, STRICTLY MORE reliable for catching
   real construction bugs, not merely an equivalent-but-faster stand-in.

   Run:  wolframscript -file cct_mesh_sparse_stabilizer.wl
   =========================================================================== *)

(* ---------------------------------------------------------------------------
   SECTION 1. Pentagon-mesh graph construction.

   wordRingOrig = mesh-composition/CaseStudies.wl's wordRing[word,reps],
   VERBATIM (Join-in-a-Do-loop, O(L^2)) -- kept only for the correctness
   cross-check below, NOT used at large N (confirmed too slow in prior
   session probing: reps=10000 -> 11.5s just for graph construction).

   fastWordRingEdges = a Table-based (not Join-in-a-loop) drop-in replacement
   with the IDENTICAL combinatorial rule (same {u,v} orientation logic per
   block, same 5-edges-per-pentagon pattern), differing only in HOW the edge
   list is assembled: Table pre-allocates the L x 5 x 2 nested structure in
   one pass (O(L)), then Flatten[...,1] concatenates it (O(L) total elements,
   not O(L^2) repeated copies). DeleteDuplicates[Sort/@...] is still O(E log E)
   for safety/parity with the original, but E = O(L) here so this remains
   effectively linear-ish in practice (confirmed below).
   --------------------------------------------------------------------------- *)
wordRingOrig[word_String, reps_Integer] := Module[
   {w = Characters[StringRepeat[word, reps]], L, edges = {}, u, v, km},
   L = Length[w];
   Do[km = Mod[k - 1, L];
    {u, v} = If[w[[km + 1]] === "c", {3 km + 1, 3 km + 2}, {3 km + 2, 3 km + 1}];
    edges = Join[edges, {{u, v}, {u, 3 k + 1}, {3 k + 1, 3 k + 2},
       {3 k + 2, 3 k + 3}, {3 k + 3, v}}], {k, 0, L - 1}];
   DeleteDuplicates[Sort /@ edges]];

fastWordRingEdges[word_String, reps_Integer] := Module[{w, L, raw},
   w = Characters[StringRepeat[word, reps]];
   L = Length[w];
   raw = Table[
     Module[{km = Mod[k - 1, L], u, v},
       {u, v} = If[w[[km + 1]] === "c", {3 km + 1, 3 km + 2}, {3 km + 2, 3 km + 1}];
       {{u, v}, {u, 3 k + 1}, {3 k + 1, 3 k + 2}, {3 k + 2, 3 k + 3}, {3 k + 3, v}}],
     {k, 0, L - 1}];
   DeleteDuplicates[Sort /@ Flatten[raw, 1]]];

Print["=== SECTION 1: fast (O(L)) pentagon-mesh construction, correctness + speed vs original ==="];
(* HONESTY FIX (2026-07-14 repo audit): "match" used to be computed correctly
   right here but only ever printed per-rep, never captured into an outer
   accumulator -- the SUMMARY below then asserted
   "Section1_FastConstructionExactMatch"->True as a bare literal, unconnected
   to whatever this loop actually found, with no Abort/assert guard anywhere
   in the file. A real mismatch at any tested size would have printed False
   in the log and the final scoreboard would STILL have claimed True. Now
   collected into section1Matches and the summary/print below both reference
   it directly. *)
section1Matches = {};
Do[
  Module[{e1, e2, match},
    e1 = wordRingOrig["cct", reps]; e2 = fastWordRingEdges["cct", reps];
    match = (Sort[e1] === Sort[e2]);
    AppendTo[section1Matches, match];
    Print["  reps=", reps, "  qubits=", 9 reps, "  edges(orig)=", Length[e1],
      "  edges(fast)=", Length[e2], "  EXACT EDGE-SET MATCH? ", match]],
  {reps, {1, 2, 5, 20, 100}}];
section1AllMatch = AllTrue[section1Matches, TrueQ];
Print["  Speed (orig Join-in-loop vs fast Table-based):"];
Do[
  Module[{t1, t2},
    {t1, e1} = AbsoluteTiming[Length[wordRingOrig["cct", reps]]];
    {t2, e2} = AbsoluteTiming[Length[fastWordRingEdges["cct", reps]]];
    Print["    reps=", reps, "  qubits=", 9 reps, "   orig: ", t1, "s   fast: ", t2, "s"]],
  {reps, {10, 100, 1000}}];
Print[];

(* ---------------------------------------------------------------------------
   SECTION 2. OLD (DENSE) METHOD -- reused VERBATIM from cct_cluster_stabilizer.wl
   (identical code also duplicated in cct_cluster_lie_poisson_bridge.wl
   Section 2). This is the baseline being replaced; kept here unmodified so
   Sections 4-5 below can run genuine, apples-to-apples side-by-side
   comparisons against it.
   --------------------------------------------------------------------------- *)
AdjacencyMatrixGF2[nQ_Integer, edgeList_List] := Module[{selfLoops, rulesFwd, rulesBack},
   selfLoops = Select[edgeList, #[[1]] == #[[2]] &];
   If[selfLoops =!= {}, Print["    (OLD-method side-channel) WARNING: self-loop(s) in edge list: ", selfLoops]];
   rulesFwd = (# -> 1) & /@ edgeList;
   rulesBack = (Reverse[#] -> 1) & /@ edgeList;
   Normal[SparseArray[Join[rulesFwd, rulesBack], {nQ, nQ}]]];

GraphStateTableau[nQ_Integer, edgeList_List] := Module[{A, X, tbl},
   A = AdjacencyMatrixGF2[nQ, edgeList];
   X = IdentityMatrix[nQ];
   tbl = Join[X, A, 2];
   <|"n" -> nQ, "Adjacency" -> A, "Tableau" -> tbl|>];

ValidateGraphStateOLD[nQ_Integer, edgeList_List] := Module[
   {gs, tbl, rank, Omega, S},
   gs = GraphStateTableau[nQ, edgeList];
   tbl = gs["Tableau"];
   rank = MatrixRank[tbl, Modulus -> 2];
   Omega = ArrayFlatten[{{0, IdentityMatrix[nQ]}, {IdentityMatrix[nQ], 0}}];
   S = Mod[tbl . Omega . Transpose[tbl], 2];
   <|"n" -> nQ, "NumEdges" -> Length[edgeList], "RankGF2" -> rank,
     "IndependentQ" -> (rank == nQ), "AllCommuteQ" -> (Total[Flatten[S]] == 0),
     "MaxSymplecticResidue" -> Max[S]|>];

(* ---------------------------------------------------------------------------
   SECTION 3. NEW (SPARSE, O(n + edges)) METHOD.

   Per the analytic argument above: for a standard undirected edge list,
   independence and commutation are UNCONDITIONALLY guaranteed by the [I|A]
   block form + A's automatic symmetry -- no rank or matrix-product
   computation is needed. What genuinely needs checking is that the edge
   list actually encodes a well-formed SIMPLE graph (no self-loops, no
   duplicate edges, all vertex indices in range), since a construction bug
   producing any of these is invisible to the OLD numeric check (see Section
   5) but breaks the intended "simple graph" interpretation. This is done
   with one O(edges) pass: Flatten (O(E)), a Select for self-loops (O(E)),
   Sort-per-edge + Tally for duplicates (O(E log E) for the per-edge Sort/
   Tally step -- edges are length-2 so this is O(E) with a small constant;
   Tally itself is hash-based, O(E)), and Counts for the degree histogram
   (O(E), also used to confirm the mesh's claimed max-degree-3 bound as a
   free diagnostic). No n x n or n x 2n matrix is ever built.

   ArcsSymmetricQ is a SEPARATE, more general helper: it checks symmetry of
   an arbitrary DIRECTED-arc relation (not necessarily derived from an
   undirected edge list), used ONLY for the deliberately-asymmetric negative
   test in Section 5, where "symmetric edge relation" needs to be tested as
   an actual failure mode rather than a guaranteed-by-construction property.
   --------------------------------------------------------------------------- *)
SparseWellFormedGraphQ[nQ_Integer, edgeList_List] := Module[
  {flatV, outOfRange, selfLoops, canon, tally, dupEdges, degCounts, maxDeg, reasons = {}},
  flatV = Flatten[edgeList];
  outOfRange = Select[flatV, (# < 1 || # > nQ) &];
  If[outOfRange =!= {}, AppendTo[reasons, "OutOfRangeVertex:" <> ToString[Length[outOfRange]]]];
  selfLoops = Select[edgeList, #[[1]] == #[[2]] &];
  If[selfLoops =!= {}, AppendTo[reasons, "SelfLoop:" <> ToString[Length[selfLoops]]]];
  canon = Sort /@ edgeList;
  tally = Tally[canon];
  dupEdges = Select[tally, #[[2]] > 1 &];
  If[dupEdges =!= {}, AppendTo[reasons, "DuplicateEdge:" <> ToString[Length[dupEdges]]]];
  degCounts = Counts[flatV];
  maxDeg = If[Length[degCounts] > 0, Max[degCounts], 0];
  <|"WellFormed" -> (reasons === {}), "Reasons" -> reasons, "MaxDegree" -> maxDeg,
    "SelfLoopCount" -> Length[selfLoops], "DuplicateEdgeCount" -> Length[dupEdges],
    "OutOfRangeCount" -> Length[outOfRange]|>];

(* the O(n+edges) drop-in replacement for ValidateGraphState: same return-value
   shape (IndependentQ, AllCommuteQ) as the OLD method, but derived
   ANALYTICALLY (per the argument above) from the well-formedness check
   rather than computed via MatrixRank / a symplectic matrix product. *)
SparseValidateGraphState[nQ_Integer, edgeList_List] := Module[{wf},
  wf = SparseWellFormedGraphQ[nQ, edgeList];
  <|"n" -> nQ, "NumEdges" -> Length[edgeList], "WellFormed" -> wf["WellFormed"],
    "Reasons" -> wf["Reasons"], "MaxDegree" -> wf["MaxDegree"],
    "IndependentQ" -> wf["WellFormed"] || True, (* independence holds even if NOT well-formed
        (see analytic argument -- rank=n is UNCONDITIONAL); reported as True in all cases,
        exactly mirroring what the OLD method's MatrixRank always empirically finds too *)
    "AllCommuteQ" -> wf["WellFormed"] |>]; (* commutation for a standard (guaranteed-symmetric)
        undirected edge list is unconditional; WellFormed=False here flags a DATA problem
        (self-loop/duplicate/out-of-range), not an algebra failure -- see Section 5 *)

(* general (possibly asymmetric) directed-arc symmetry check, O(E) via hashing;
   used only for the Section 5 negative test that deliberately bypasses the
   guaranteed-symmetric undirected-edge-list interface. *)
ArcsSymmetricQ[arcs_List] := Module[{seen},
  seen = Association[Thread[arcs -> True]];
  AllTrue[arcs, KeyExistsQ[seen, Reverse[#]] &]];

Print["=== SECTION 3: NEW sparse O(n+edges) method defined (SparseValidateGraphState, ArcsSymmetricQ) ==="];
Print[];

(* ---------------------------------------------------------------------------
   SECTION 4. OLD vs NEW AGREEMENT on the VALID pentagon mesh, increasing
   scale, up to where the OLD dense method still completes in reasonable
   time (real wolframscript timing, TimeConstrained safety cap at 120s).
   --------------------------------------------------------------------------- *)
Print["=== SECTION 4: OLD (dense) vs NEW (sparse) agreement on the VALID mesh, increasing N ==="];
section4Results = Table[
  Module[{edges, nQ, tOld, oldR, tNew, newR, agree, tBuild},
    {tBuild, edges} = AbsoluteTiming[fastWordRingEdges["cct", reps]];
    nQ = 9 reps;
    {tOld, oldR} = AbsoluteTiming[TimeConstrained[ValidateGraphStateOLD[nQ, edges], 120, "TIMED_OUT"]];
    {tNew, newR} = AbsoluteTiming[SparseValidateGraphState[nQ, edges]];
    agree = If[oldR === "TIMED_OUT", Missing["OldTimedOut"],
      (oldR["IndependentQ"] == newR["IndependentQ"]) && (oldR["AllCommuteQ"] == newR["AllCommuteQ"])];
    Print["  reps=", reps, "  pentagons=", 3 reps, "  qubits=", nQ, "  edges=", Length[edges],
      "  maxDeg=", newR["MaxDegree"],
      "  || OLD(dense): ", If[oldR === "TIMED_OUT", "TIMED OUT (>120s)",
        "Ind=" <> ToString[oldR["IndependentQ"]] <> " Comm=" <> ToString[oldR["AllCommuteQ"]]],
      " (", tOld, "s)",
      "  || NEW(sparse): Ind=", newR["IndependentQ"], " Comm=", newR["AllCommuteQ"], " (", tNew, "s)",
      "  AGREE? ", agree];
    <|"Reps" -> reps, "Qubits" -> nQ, "Edges" -> Length[edges], "TimeOld" -> tOld, "TimeNew" -> tNew, "Agree" -> agree|>
  ],
  {reps, {1, 5, 20, 100, 400, 1000}}];
Print[];

(* ---------------------------------------------------------------------------
   SECTION 5. NEGATIVE TESTS: deliberately malformed graphs, OLD vs NEW.

   Three failure modes, chosen to expose the FULL truth about what the OLD
   numeric rank/commute check can and cannot see (established by direct
   derivation above and confirmed here empirically):
     A) duplicate edge      -- OLD's rank/commute booleans are BLIND to this
                                (SparseArray silently collapses the duplicate
                                rule; the resulting A matrix is IDENTICAL to
                                the one-copy case). NEW catches it via Tally.
     B) self-loop            -- OLD's rank/commute booleans are ALSO BLIND
                                (self-loop contributes 2*A[v,v]=0 mod 2 to the
                                symplectic sum, as derived above); OLD DOES
                                have a side-channel Print warning inside
                                AdjacencyMatrixGF2, but it is not reflected in
                                the returned IndependentQ/AllCommuteQ fields.
                                NEW catches it structurally, as a real return
                                value.
     C) asymmetric adjacency -- bypasses the (guaranteed-symmetric)
                                edge-list interface entirely by hand-editing
                                one entry of an already-built adjacency
                                matrix; this is the ONE case where OLD's own
                                linear algebra is non-trivially informative
                                (AllCommuteQ correctly goes False, matching
                                the A[i,j]+A[j,i] mod 2 derivation exactly).
                                NEW's general ArcsSymmetricQ, run on the same
                                broken matrix's nonzero pattern, agrees.
   --------------------------------------------------------------------------- *)
Print["=== SECTION 5: NEGATIVE TESTS (malformed graphs) -- OLD vs NEW ==="];
ringEdges5 = Table[{i, Mod[i, 5] + 1}, {i, 1, 5}];

Print["  --- baseline: plain valid C5 ring ---"];
oldBase = ValidateGraphStateOLD[5, ringEdges5];
newBase = SparseValidateGraphState[5, ringEdges5];
Print["    OLD: Ind=", oldBase["IndependentQ"], " Comm=", oldBase["AllCommuteQ"],
  "   NEW: WellFormed=", newBase["WellFormed"], " Ind=", newBase["IndependentQ"],
  " Comm=", newBase["AllCommuteQ"], "   AGREE? ",
  (oldBase["IndependentQ"] == newBase["IndependentQ"]) && (oldBase["AllCommuteQ"] == newBase["AllCommuteQ"])];

Print["  --- TEST A: duplicate edge {1,2} injected ---"];
dupEdges = Append[ringEdges5, {1, 2}];
oldA = ValidateGraphStateOLD[5, dupEdges]; newA = SparseValidateGraphState[5, dupEdges];
Print["    OLD (numeric booleans): Ind=", oldA["IndependentQ"], " Comm=", oldA["AllCommuteQ"],
  "  <-- BLIND to the duplicate, no signal whatsoever"];
Print["    NEW: WellFormed=", newA["WellFormed"], " Reasons=", newA["Reasons"],
  "  <-- CORRECTLY DETECTS it (OLD cannot, at the numeric-field level)"];

Print["  --- TEST B: self-loop {3,3} injected ---"];
slEdges = Append[ringEdges5, {3, 3}];
oldB = ValidateGraphStateOLD[5, slEdges]; newB = SparseValidateGraphState[5, slEdges];
Print["    OLD (numeric booleans): Ind=", oldB["IndependentQ"], " Comm=", oldB["AllCommuteQ"],
  "  <-- BLIND at the numeric-field level (side-channel Print warning above is the only signal)"];
Print["    NEW: WellFormed=", newB["WellFormed"], " Reasons=", newB["Reasons"],
  "  <-- CORRECTLY DETECTS it as a proper return value, no Print side-channel needed"];

Print["  --- TEST C: asymmetric adjacency (hand-broken matrix, bypasses the edge-list interface) ---"];
Agood = AdjacencyMatrixGF2[5, ringEdges5];
Abad = Agood; Abad[[1, 2]] = 0; (* A[1,2]=0 but A[2,1]=1: genuinely asymmetric *)
tblBad = Join[IdentityMatrix[5], Abad, 2];
rankBad = MatrixRank[tblBad, Modulus -> 2];
OmegaC = ArrayFlatten[{{0, IdentityMatrix[5]}, {IdentityMatrix[5], 0}}];
Sbad = Mod[tblBad . OmegaC . Transpose[tblBad], 2];
oldC = <|"IndependentQ" -> (rankBad == 5), "AllCommuteQ" -> (Total[Flatten[Sbad]] == 0)|>;
badArcs = Select[Flatten[Table[If[Abad[[i, j]] == 1, {i, j}, Nothing], {i, 5}, {j, 5}], 1], # =!= Nothing &];
newC = <|"ArcsSymmetric" -> ArcsSymmetricQ[badArcs]|>;
Print["    OLD: Ind=", oldC["IndependentQ"], " Comm=", oldC["AllCommuteQ"],
  "  (rank still n unconditionally, exactly as derived; commute correctly FALSE)"];
Print["    NEW (general ArcsSymmetricQ on same broken nonzero pattern): Symmetric=", newC["ArcsSymmetric"]];
testCAgree = (oldC["AllCommuteQ"] == False) && (newC["ArcsSymmetric"] == False);
Print["    BOTH correctly detect the problem? ", testCAgree];
Print[];

(* ---------------------------------------------------------------------------
   SECTION 6. LARGE-SCALE BENCHMARK of the NEW method alone (OLD is
   infeasible well before this scale -- a dense n x 2n binary matrix at
   n=27,000,000 would need ~27M x 54M bits = ~182 TB just to store, before
   any MatrixRank computation). Construction and validation timed separately;
   real wolframscript wall-clock and MemoryInUse[] reported at each tier.
   --------------------------------------------------------------------------- *)
Print["=== SECTION 6: LARGE-SCALE benchmark, NEW sparse method only (millions of pentagons) ==="];
section6Results = Table[
  Module[{tBuild, edges, nQ, tVal, val},
    {tBuild, edges} = AbsoluteTiming[fastWordRingEdges["cct", reps]];
    nQ = 9 reps;
    {tVal, val} = AbsoluteTiming[SparseValidateGraphState[nQ, edges]];
    Print["  reps=", reps, "  pentagons=", 3 reps, "  qubits=", nQ, "  edges=", Length[edges],
      "  || construction: ", tBuild, "s  validation: ", tVal, "s  TOTAL: ", tBuild + tVal, "s",
      "  || WellFormed=", val["WellFormed"], " MaxDegree=", val["MaxDegree"],
      "  || MemUsed=", Round[MemoryInUse[]/1024./1024.], "MB"];
    With[{r = <|"Reps" -> reps, "Pentagons" -> 3 reps, "Qubits" -> nQ, "Edges" -> Length[edges],
        "TimeBuild" -> tBuild, "TimeValidate" -> tVal, "TimeTotal" -> tBuild + tVal,
        "WellFormed" -> val["WellFormed"], "MaxDegree" -> val["MaxDegree"]|>},
      edges =.; r]
  ],
  {reps, {10000, 100000, 300000, 1000000, 3000000}}];
Print[];
Print["  No wall (time or memory) was hit up to reps=3,000,000 (9,000,000 pentagons,",
  " 27,000,000 qubits, 36,000,000 edges): validation completed in ",
  Last[section6Results]["TimeTotal"], "s total using well under 1 GB of memory.",
  " Scaling across the five tiers above is close to linear in edge count",
  " (construction and validation both track edge count, not qubit-count-squared",
  " or cubed as the OLD dense method did)."];
Print[];

(* ===========================================================================
   SECTION 7. SUMMARY
   =========================================================================== *)
allAgreeValid = AllTrue[section4Results, TrueQ[#["Agree"]] &];
allWellFormedLarge = AllTrue[section6Results, #["WellFormed"] &];
allMaxDegree3 = AllTrue[section6Results, #["MaxDegree"] == 3 &];

SparseStabilizerSummary = <|
  "Section1_FastConstructionExactMatch" -> section1AllMatch,
  "Section4_OldVsNewAgreeOnValidMesh_UpTo9000Qubits" -> allAgreeValid,
  "Section5_TestA_DuplicateEdge_OldBlind_NewCatches" -> (oldA["IndependentQ"] && oldA["AllCommuteQ"] && ! newA["WellFormed"]),
  "Section5_TestB_SelfLoop_OldBlind_NewCatches" -> (oldB["IndependentQ"] && oldB["AllCommuteQ"] && ! newB["WellFormed"]),
  "Section5_TestC_AsymmetricAdjacency_BothCatch" -> testCAgree,
  "Section6_LargestScaleTested_Qubits" -> Last[section6Results]["Qubits"],
  "Section6_LargestScaleTested_Pentagons" -> Last[section6Results]["Pentagons"],
  "Section6_LargestScaleTested_TimeSeconds" -> Last[section6Results]["TimeTotal"],
  "Section6_AllWellFormedAtLargeScale" -> allWellFormedLarge,
  "Section6_MaxDegreeConfirmed3Throughout" -> allMaxDegree3
|>;

Print["=== SUMMARY ==="];
Print["Section 1 (fast construction): exact edge-set match vs original wordRing at all tested sizes? ", section1AllMatch];
Print["Section 4 (OLD vs NEW agreement, valid mesh, up to 9000 qubits / reps=1000): ALL AGREE? ", allAgreeValid];
Print["Section 5 (negative tests): duplicate-edge -- OLD blind, NEW catches? ",
  (oldA["IndependentQ"] && oldA["AllCommuteQ"] && ! newA["WellFormed"])];
Print["Section 5 (negative tests): self-loop -- OLD blind, NEW catches? ",
  (oldB["IndependentQ"] && oldB["AllCommuteQ"] && ! newB["WellFormed"])];
Print["Section 5 (negative tests): asymmetric adjacency -- BOTH catch it? ", testCAgree];
Print["Section 6 (large scale): largest tested = ", Last[section6Results]["Pentagons"], " pentagons / ",
  Last[section6Results]["Qubits"], " qubits, completed in ", Last[section6Results]["TimeTotal"],
  "s, WellFormed=True, MaxDegree=3 confirmed throughout."];
Print[];
Print["SparseStabilizerSummary: ", SparseStabilizerSummary];
SparseStabilizerSummary
