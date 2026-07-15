(* ::Package:: *)

(* ===========================================================================
   cct_cluster_lie_poisson_bridge.wl

   ONE integrated bridge script combining three independently-built research
   components for the pentagon-mesh MBQC / Lie-Poisson project:

     (1) cct_cluster_stabilizer.wl   -- efficient GF(2) binary stabilizer
         tableau for the cct-glued pentagon-mesh CZ cluster state. POLYNOMIAL
         in n (rank + symplectic-product on an n x 2n binary matrix); verified
         to N=100 pentagons (~300 qubits) in the source file.
     (2) cct_cluster_avn_witness.wl  -- generalized GHZ all-versus-nothing (AvN)
         contextuality witness (Theorem 4's U1 condition, C_F(rho)>0) on the
         actual cluster state. EXPONENTIAL in n (explicit 2^n x 2^n matrices +
         branch enumeration); verified only at N=2,3 pentagons (8, 11 qubits)
         and the literal cct ring wordRing["cct",1] (9 qubits) in the source
         file.
     (3) cct_cluster_dla.wl          -- Dynamical Lie Algebra dimension
         (Proposition 0 of Lie_Poisson_MBQC.wl). EXPONENTIAL and much worse
         than (2) in practice (commutator-closure over 4^n-dimensional flattened
         matrices); the source file established an EXACT feasibility ceiling of
         N=1 pentagon (5 qubits, dim=1023=4^5-1); N=2 pentagons (8 qubits) did
         NOT complete in a 150s probe (only 0.38% of the closure found).

   ==========================================================================
   HONESTY / SCALE-VALIDITY NOTE (read before trusting any result at large N)
   ==========================================================================
   This script exposes ONE top-level parameter, `nPentagonsRequested` (see
   PARAMETERS below), and runs all three checks against the SAME cct-glued
   mesh at that size where feasible. The three checks do NOT share the same
   validity radius in N, and this script does not pretend otherwise:

     * STABILIZER CHECK (Section 2): [UPDATED] mesh construction (Section 1,
       `wordRing`) and the stabilizer validity check (Section 2) were BOTH
       re-architected to be sparse/O(n+edges) -- see cct_mesh_sparse_construction.wl
       and cct_mesh_sparse_stabilizer.wl. Analytically, independence (rank=n)
       and mutual commutation are UNCONDITIONAL consequences of the graph
       state tableau's [I|A] block form + A's guaranteed symmetry for any
       standard undirected edge list (re-derived in Section 2 below); what
       actually needs checking is edge-list well-formedness (no self-loops,
       duplicates, out-of-range vertices), done in O(n+edges) with no dense
       matrix ever built. Benchmarked (real wolframscript runs, see the
       sibling files) to 9,000,000 pentagons / 27,000,000 qubits in ~312s
       total. This bridge script's own local end-to-end test results (small
       AND large N) are reported by whoever last ran it -- see the delivery
       notes accompanying this file for the actual numbers. This is the one
       component of this bridge that is established to scale to MILLIONS of
       pentagons, not just thousands.

     * AvN / CONTEXTUALITY WITNESS CHECK (Section 3): this is gated by
       `avnMaxQubits` (default 11, the largest case explicitly verified in
       cct_cluster_avn_witness.wl). Beyond that qubit count, THIS SCRIPT
       SKIPS THE CHECK ENTIRELY rather than silently extrapolating. The
       underlying ARGUMENT ("every degree-2 vertex carries a local GHZ
       witness, chain or ring, any block position") is stated in the source
       file as plausibly general, but that generality was NOT computationally
       verified beyond N=3 pentagons there, and is not claimed as verified
       for larger N here either. Running this script at large N via
       RemoteBatchSubmit will NOT exercise a working AvN check -- it will
       report "Skipped" and say why, honestly, in the returned association.

     * DLA DIMENSION CHECK (Section 4): gated even more tightly. Only the
       fixed N=1 pentagon (5-qubit) topology is EXACTLY computable (this is
       always attempted, independent of the requested N, as a standing
       ceiling demonstration). For the user's REQUESTED mesh, a full closure
       is attempted ONLY if the qubit count is at or below the ceiling; a
       short SAFETY-BOUNDED probe (TimeConstrained) is attempted up to
       `dlaProbeMaxQubits` (default 14) purely to demonstrate infeasibility
       empirically; beyond that, NO computation is attempted at all (building
       even the generators would be representationally impossible -- see
       Section 4's closing remarks, reproduced from cct_cluster_dla.wl
       Section 8). Running this script at large N via RemoteBatchSubmit will
       NOT produce a DLA dimension for that N -- it will report the N=1
       ceiling and, at most, an admittedly-incomplete probe, or nothing at
       all if N is large.

   In short: SCALE THE STABILIZER CHECK, NOT THE OTHER TWO. If someone submits
   this script at N=100000 pentagons expecting all three checks to mean
   something at that scale, the returned association's "AvN" and "DLA" fields
   will say "Skipped" / "NotAttempted" with reasons -- that is the intended,
   honest behavior, not a bug.

   ==========================================================================
   CLOUD-SUBMISSION READINESS
   ==========================================================================
   Follows the pattern established this session in
   certificates/GenerateEpsilonCertificate9_cloud.wl:
     * no SetDirectory[DirectoryName[$InputFileName]] (this file is meant to
       be submitted as INLINE code via RemoteBatchSubmit, not run from a
       resolvable file path -- $InputFileName is not reliable there);
     * the BlackBox paclet (needed only for the OPTIONAL cross-check of the
       AvN witness against AvNArgument/ContextualFraction) is loaded via a
       list of CANDIDATE directories, all wrapped in Quiet@Check, and the
       script DEGRADES GRACEFULLY (continues with the self-contained ad hoc
       AvN check alone) if none of them resolve -- exactly what will happen
       on a bare remote kernel with no access to this machine's filesystem.
       This is reported honestly in the output ("BlackBoxPacletLoaded").
     * the FINAL expression of this file (no trailing semicolon) is a
       self-contained diagnostic association, so RemoteBatchSubmit's
       EvaluationResult captures everything needed to judge the run without
       depending on Export/file retrieval from the remote machine.

   Run locally:  wolframscript -file cct_cluster_lie_poisson_bridge.wl
   =========================================================================== *)

(* ---------------------------------------------------------------------------
   PARAMETERS -- the only knobs you should need to touch.
   --------------------------------------------------------------------------- *)
nPentagonsRequested = 3000000;      (* <-- CHANGE THIS to scale N. 3 = the literal
                                  "cct-glued" ring wordRing["cct",1] (9 qubits),
                                  already the richest case validated end-to-end
                                  in cct_cluster_avn_witness.wl. *)
avnMaxQubits = 11;             (* AvN check gate: largest qubit count actually
                                  verified in cct_cluster_avn_witness.wl
                                  (N=3 PentagonChain = 11 qubits). *)
dlaProbeMaxQubits = 14;        (* DLA bounded-probe gate: above this, don't even
                                  attempt to build the generators. *)
dlaProbeSeconds = 20;          (* safety time budget for the DLA probe on the
                                  REQUESTED mesh (expected to be INCOMPLETE --
                                  see Section 4). *)
dlaCeilingTimeoutSeconds = 300; (* generous safety budget for the FIXED N=1
                                  pentagon exact-ceiling computation; the
                                  source file measured 77-114s on its dev
                                  machine, so 300s has ample headroom on a
                                  similar or slower machine without letting a
                                  truly stuck run hang forever. *)
denseCrossCheckMaxQubits = 5000; (* Stabilizer check gate (NEW): above this
                                  qubit count, skip the OPTIONAL old-dense-
                                  method cross-check against the new sparse
                                  method's verdict (dense MatrixRank/matrix-
                                  multiply was measured at 57.5s for just
                                  9000 qubits in cct_mesh_sparse_stabilizer.wl,
                                  and becomes literally un-storable in the
                                  millions -- a dense n x 2n tableau at
                                  n=27,000,000 would need ~182 TB). The sparse
                                  method itself (Section 2) has NO such gate
                                  and always runs at the full requested N. *)

reps = Max[1, Round[nPentagonsRequested/3]];  (* wordRing convention: actual
                                  pentagon count is the nearest multiple of 3,
                                  exactly as cct_cluster_stabilizer.wl uses it. *)

Print["=== cct_cluster_lie_poisson_bridge.wl : integrated pentagon-mesh check ==="];
Print["Requested N = ", nPentagonsRequested, " pentagons  ->  reps = ", reps,
  "  ->  actual pentagons = ", 3 reps, ", qubits = ", 9 reps];
If[3 reps != nPentagonsRequested,
  Print["  NOTE: actual pentagon count (", 3 reps,
    ") differs from requested (", nPentagonsRequested,
    ") -- wordRing[\"cct\",reps] only produces multiples of 3, per its own convention."]];
Print[];

(* ---------------------------------------------------------------------------
   SECTION 0. Shared Pauli/Kronecker conventions -- verbatim and IDENTICAL
   across all three source files (mbqc_c5.wl, cct_cluster_stabilizer.wl,
   cct_cluster_avn_witness.wl, cct_cluster_dla.wl), consolidated once here so
   every section below is a byte-for-byte apples-to-apples comparison.
   --------------------------------------------------------------------------- *)
kp = KroneckerProduct; I2 = IdentityMatrix[2];
PX = {{0, 1}, {1, 0}}; PZ = {{1, 0}, {0, -1}}; PY = {{0, -I}, {I, 0}};
Hd = {{1, 1}, {1, -1}}/Sqrt[2]; plusV = {1, 1}/Sqrt[2];
pauliOf["X"] = PX; pauliOf["Y"] = PY; pauliOf["H"] = Hd; pauliOf["I"] = I2;

(* ---------------------------------------------------------------------------
   SECTION 1. Pentagon-mesh graph combinatorics.

   wordRing[word,reps] -- REUSED VERBATIM from mesh-composition/CaseStudies.wl
   (Case D3, "The Optimal Gluing Word") via cct_cluster_stabilizer.wl /
   cct_cluster_avn_witness.wl: a RING of L = Length[word]*reps pentagons glued
   edge-to-edge (cis/trans read off the repeated word), 3L vertices/qubits.
   Self-contained -- no paclet dependency, so this works identically on a bare
   cloud kernel.

   PentagonChainEdges[nblocks] -- REUSED VERBATIM from cct_cluster_avn_witness.wl
   Section 4 (itself matching BlackBox.wl's PentagonChain[nblocks] edge
   pattern): an OPEN chain of nblocks pentagons, 3*nblocks+2 vertices. Used
   ONLY in Section 4 (DLA) below, so the DLA ceiling demonstration needs no
   paclet load either (BlackBox's own PentagonChain is paclet-gated and would
   not be available on a bare cloud kernel).
   --------------------------------------------------------------------------- *)
(* SPARSE REWRITE (this update): the ORIGINAL wordRing built its edge list via
   `edges = Join[edges, {...}]` inside a Do loop -- O(L^2) (every Join recopies
   the whole list from scratch). Measured directly (see
   cct_mesh_sparse_construction.wl): reps=10000 -> 11.5s for construction
   ALONE; at "millions of pentagons" this would take many hours before any
   stabilizer math even runs. REPLACED here with a single Table that
   pre-computes all 5*L edges as a ragged list of per-pentagon blocks (no
   incremental copying) followed by one Flatten[...,1] to concatenate --
   both O(L). Regression-tested to an EXACT MATCH against the original at
   word="cct", reps=1,2,3,5,10,50 in cct_mesh_sparse_construction.wl Section 2
   (identical 3k+1,3k+2,3k+3 vertex-indexing scheme, identical {u,v}
   orientation rule per block, identical final DeleteDuplicates[Sort/@...] --
   ONLY the accumulation strategy changed, so no relabeling map is needed
   anywhere downstream). Benchmarked to reps=3,000,000 (9,000,000 pentagons,
   27,000,000 qubits) in 110.7s with time/L staying flat across 5 orders of
   magnitude (genuinely linear, not merely "not yet quadratic"). Signature
   and return value (a plain edge list, not a Graph[] object) are UNCHANGED,
   so nothing downstream in this script (Sections 2-4) needed to change to
   consume it. *)
wordRing[word_String, reps_Integer] := Module[{w, L, edgeBlocks},
   w = Characters[StringRepeat[word, reps]];
   L = Length[w];
   edgeBlocks = Table[
     Module[{km = Mod[k - 1, L], u, v},
       {u, v} = If[w[[km + 1]] === "c", {3 km + 1, 3 km + 2}, {3 km + 2, 3 km + 1}];
       {{u, v}, {u, 3 k + 1}, {3 k + 1, 3 k + 2}, {3 k + 2, 3 k + 3}, {3 k + 3, v}}],
     {k, 0, L - 1}];
   DeleteDuplicates[Sort /@ Flatten[edgeBlocks, 1]]];

PentagonChainEdges[nblocks_Integer?Positive] := Module[{edges = {}, e0 = {1, 2}, base = 2},
   Do[edges = Join[edges, {{e0[[1]], base + 1}, {base + 1, base + 2},
       {base + 2, base + 3}, {base + 3, e0[[2]]}, {e0[[2]], e0[[1]]}}];
    e0 = {base + 1, base + 2}; base = base + 3, {nblocks}];
   DeleteDuplicates[Sort /@ edges]];

neighborsOf[v_, edgeList_] := Union[Cases[edgeList, {v, u_} :> u], Cases[edgeList, {u_, v} :> u]];
degreeOf[v_, edgeList_] := Length[neighborsOf[v, edgeList]];

meshEdges = wordRing["cct", reps];
nQ = 9 reps;
actualPentagons = 3 reps;
Print["Mesh built: wordRing[\"cct\",", reps, "] -- ", actualPentagons,
  " pentagons, ", nQ, " qubits, ", Length[meshEdges], " CZ edges."];
Print[];

(* ===========================================================================
   SECTION 2. STABILIZER VALIDITY CHECK (POLYNOMIAL, scales to large N).
   REUSED, essentially verbatim, from cct_cluster_stabilizer.wl.
   =========================================================================== *)
Print["--- SECTION 2: stabilizer validity (sparse O(n+edges) structural check) ---"];

(* symmetric 0/1 adjacency matrix from an edge list. KEPT (dense, O(n^2)
   memory) -- used ONLY below for (a) the small, fixed N=1 (5-qubit) baseline
   cross-check against mbqc_c5.wl's explicit matrices (needs an actual dense
   Tableau to build explicit 2^5x2^5 operators) and (b) an OPTIONAL, gated
   old-vs-new agreement cross-check at moderate N. NOT used for the large-N
   verdict itself anymore -- see SparseValidateGraphState below for that. *)
AdjacencyMatrixGF2[nq_Integer, edgeList_List] := Module[{selfLoops, rulesFwd, rulesBack},
   selfLoops = Select[edgeList, #[[1]] == #[[2]] &];
   If[selfLoops =!= {}, Print["WARNING: self-loop(s) in edge list: ", selfLoops]];
   rulesFwd = (# -> 1) & /@ edgeList;
   rulesBack = (Reverse[#] -> 1) & /@ edgeList;
   Normal[SparseArray[Join[rulesFwd, rulesBack], {nq, nq}]]];

(* the n x 2n binary stabilizer tableau [ I | A ] for the graph state. *)
GraphStateTableau[nq_Integer, edgeList_List] := Module[{A, X, tbl},
   A = AdjacencyMatrixGF2[nq, edgeList];
   X = IdentityMatrix[nq];
   tbl = Join[X, A, 2];
   <|"n" -> nq, "Adjacency" -> A, "Tableau" -> tbl|>];

(* independence (rank over GF(2)) + mutual commutation (binary symplectic
   product), pure n x n / n x 2n linear algebra -- NOT a 2^n x 2^n construction,
   but still DENSE (O(n^2) memory, ~O(n^3)-ish time via MatrixRank/matrix
   product) -- infeasible well before millions of qubits (a dense n x 2n
   tableau at n=27,000,000 would need ~182 TB just to store). Measured at
   57.5s for just 9000 qubits in cct_mesh_sparse_stabilizer.wl. KEPT for the
   N=1 baseline and the optional cross-check only -- see SparseValidateGraphState
   below for the method actually used at the requested N. *)
ValidateGraphState[nq_Integer, edgeList_List] := Module[
   {gs, tbl, rank, Omega, S},
   gs = GraphStateTableau[nq, edgeList];
   tbl = gs["Tableau"];
   rank = MatrixRank[tbl, Modulus -> 2];
   Omega = ArrayFlatten[{{0, IdentityMatrix[nq]}, {IdentityMatrix[nq], 0}}];
   S = Mod[tbl . Omega . Transpose[tbl], 2];
   <|"n" -> nq, "NumEdges" -> Length[edgeList], "RankGF2" -> rank,
     "IndependentQ" -> (rank == nq), "AllCommuteQ" -> (Total[Flatten[S]] == 0),
     "MaxSymplecticResidue" -> Max[S], "Tableau" -> tbl, "Adjacency" -> gs["Adjacency"]|>];

(* ---------------------------------------------------------------------------
   NEW: SPARSE, O(n + edges) stabilizer validity check -- replaces the dense
   method above for the REQUESTED mesh, per the re-derived analytic argument
   (see cct_mesh_sparse_stabilizer.wl for the full derivation):
     * INDEPENDENCE (rank_GF(2)(T) = n) is UNCONDITIONAL for T = [I_n | A],
       ANY matrix A whatsoever: the identity block alone (n rows, first n
       columns already rank n) forces rank(T) = n. No computation needed.
     * COMMUTATION: (T.Omega.T^T)[i,j] = A[i,j] + A[j,i] mod 2 -- also an
       unconditional identity -- is 0 everywhere IFF A is symmetric,
       REGARDLESS of A's diagonal (self-loops cancel: 2*A[i,i] mod 2 = 0).
     * For the standard undirected-edge-list interface (A always built
       symmetric by construction, exactly as AdjacencyMatrixGF2 above does),
       BOTH guarantees hold unconditionally, for any N. What can actually go
       wrong is DATA hygiene -- self-loops, duplicate edges, out-of-range
       vertex indices from a construction bug -- invisible to the dense
       method's own rank/commute booleans (SparseArray silently collapses
       duplicates; self-loops cancel mod 2) but exactly what an O(n+edges)
       structural pass over the edge list catches.
   No n x n or n x 2n matrix is ever built. Benchmarked (real wolframscript
   runs) to 27,000,000 qubits / 9,000,000 pentagons / 36,000,000 edges in
   202.8s validation time (311.8s incl. construction), under 1 GB RAM.
   --------------------------------------------------------------------------- *)
SparseWellFormedGraphQ[nq_Integer, edgeList_List] := Module[
  {flatV, outOfRange, selfLoops, canon, tally, dupEdges, degCounts, maxDeg, reasons = {}},
  flatV = Flatten[edgeList];
  outOfRange = Select[flatV, (# < 1 || # > nq) &];
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

SparseValidateGraphState[nq_Integer, edgeList_List] := Module[{wf},
  wf = SparseWellFormedGraphQ[nq, edgeList];
  <|"n" -> nq, "NumEdges" -> Length[edgeList], "WellFormed" -> wf["WellFormed"],
    "Reasons" -> wf["Reasons"], "MaxDegree" -> wf["MaxDegree"],
    "IndependentQ" -> True, (* unconditional for T=[I|A], any A -- see derivation above *)
    "AllCommuteQ" -> wf["WellFormed"]|>]; (* unconditional for symmetric A; WellFormed->False
        here flags a DATA problem (self-loop/duplicate/out-of-range), not an algebra failure *)

(* explicit 2^nq x 2^nq operator from one tableau row -- small-n cross-check only. *)
ExplicitOperatorFromRow[row_List, nq_Integer] := Module[{x, z},
   x = row[[1 ;; nq]]; z = row[[nq + 1 ;; 2 nq]];
   kp @@ Table[
     Which[x[[q]] == 1 && z[[q]] == 0, PX, x[[q]] == 0 && z[[q]] == 1, PZ,
       x[[q]] == 1 && z[[q]] == 1, PY, True, I2],
     {q, 1, nq}]];

(* CRITICAL BASELINE: mbqc_c5.wl's own explicit-matrix construction, reproduced
   VERBATIM inside a Module (not reinvented), always run regardless of the
   requested N -- this is the standing regression check that the efficient
   method is correct before trusting it at any larger, requested N. *)
BuildC5Reference[] := Module[{nq, psi0, bits, cz, edges, psiC5, emb, KstabLocal, stabDev},
   nq = 5;
   psi0 = Flatten[kp @@ ConstantArray[plusV, nq]];
   bits[b_] := IntegerDigits[b, 2, nq];
   cz[i_, j_] := DiagonalMatrix[Table[If[bits[b][[i]] == 1 && bits[b][[j]] == 1, -1, 1], {b, 0, 2^nq - 1}]];
   edges = Table[{i, Mod[i, 5] + 1}, {i, 1, 5}];
   psiC5 = Fold[#2 . #1 &, psi0, cz @@@ edges];
   emb[a_] := kp @@ Table[Lookup[a, k, I2], {k, 1, nq}];
   KstabLocal[i_] := emb[<|i -> PX, Mod[i - 2, 5] + 1 -> PZ, Mod[i, 5] + 1 -> PZ|>];
   stabDev = Table[Max@Abs@Chop[KstabLocal[i] . psiC5 - psiC5], {i, 1, 5}];
   <|"n" -> nq, "Edges" -> edges, "psiC5" -> psiC5,
     "Kstab" -> Table[KstabLocal[i], {i, 1, 5}], "stabDev" -> stabDev|>];

runN1Validation[] := Module[
   {ref, val5, tbl5, myK, opDiff, myStabDev, opMatch, stateMatch},
   ref = BuildC5Reference[];
   val5 = ValidateGraphState[5, ref["Edges"]];
   tbl5 = val5["Tableau"];
   myK = Table[ExplicitOperatorFromRow[tbl5[[v]], 5], {v, 1, 5}];
   opDiff = Table[Max[Abs[Chop[myK[[v]] - ref["Kstab"][[v]]]]], {v, 1, 5}];
   myStabDev = Table[Max[Abs[Chop[myK[[v]] . ref["psiC5"] - ref["psiC5"]]]], {v, 1, 5}];
   opMatch = Max[opDiff] == 0;
   stateMatch = Max[myStabDev] == 0;
   Print["  N=1 baseline (plain C5, 5 qubits) vs mbqc_c5.wl: operator-exact match? ",
     opMatch, "  state-stabilizer deviation 0? ", stateMatch];
   <|"OperatorMatch" -> opMatch, "StateMatch" -> stateMatch|>];

n1StabResult = runN1Validation[];

stabResult = SparseValidateGraphState[nQ, meshEdges];
Print["  Requested mesh (", nQ, " qubits, ", Length[meshEdges], " edges): WellFormed=",
  stabResult["WellFormed"], "  MaxDegree=", stabResult["MaxDegree"],
  If[stabResult["Reasons"] =!= {}, "  Reasons=" <> ToString[stabResult["Reasons"]], ""],
  "  independent? ", stabResult["IndependentQ"], " (unconditional for [I|A] tableau form)",
  "  all commute? ", stabResult["AllCommuteQ"], " (unconditional iff A symmetric, i.e. WellFormed)"];

(* OPTIONAL old(dense)-vs-new(sparse) agreement cross-check, gated by
   denseCrossCheckMaxQubits (set in PARAMETERS above) exactly like
   avnMaxQubits/dlaProbeMaxQubits -- never attempted above the gate so it can
   never become the new bottleneck. *)
denseCrossCheckAttempted = nQ <= denseCrossCheckMaxQubits;
If[denseCrossCheckAttempted,
  Module[{tOld, oldR},
    {tOld, oldR} = AbsoluteTiming[ValidateGraphState[nQ, meshEdges]];
    denseCrossCheckAgree = (oldR["IndependentQ"] == stabResult["IndependentQ"]) &&
       (oldR["AllCommuteQ"] == stabResult["AllCommuteQ"]);
    Print["  dense cross-check (nQ<=", denseCrossCheckMaxQubits, "): OLD rank(GF2)=",
      oldR["RankGF2"], " Ind=", oldR["IndependentQ"], " Comm=", oldR["AllCommuteQ"],
      " (", tOld, "s)  AGREE with sparse verdict? ", denseCrossCheckAgree]],
  (
   denseCrossCheckAgree = Missing["SkippedTooLargeForDenseCheck"];
   Print["  dense cross-check SKIPPED: nQ=", nQ, " exceeds denseCrossCheckMaxQubits=",
     denseCrossCheckMaxQubits, " -- dense MatrixRank/matrix-multiply would be far too",
     " slow/memory-hungry at this scale (this is exactly the bottleneck the sparse",
     " method exists to avoid; see cct_mesh_sparse_stabilizer.wl)."];
  )];

stabPassed = n1StabResult["OperatorMatch"] && n1StabResult["StateMatch"] &&
   stabResult["IndependentQ"] && stabResult["AllCommuteQ"];
Print["  STABILIZER CHECK PASSED? ", stabPassed,
  "  (sparse O(n+edges) structural method; benchmarked to 27,000,000 qubits /",
  " 9,000,000 pentagons in ~312s in cct_mesh_sparse_stabilizer.wl -- genuinely",
  " scales to millions of pentagons, unlike the old dense method)."];
Print[];

(* ===========================================================================
   SECTION 3. AvN / CONTEXTUALITY WITNESS CHECK (EXPONENTIAL, gated).
   REUSED, essentially verbatim, from cct_cluster_avn_witness.wl.
   =========================================================================== *)
Print["--- SECTION 3: AvN contextuality witness (gated at avnMaxQubits=",
  avnMaxQubits, ") ---"];

(* best-effort, cloud-safe BlackBox paclet load: try several candidate
   directories, degrade gracefully (no paclet -> ad hoc check only) if none
   resolve. On a bare RemoteBatchSubmit kernel this is EXPECTED to fail. *)
blackBoxCandidateDirs = {
   FileNameJoin[{Quiet@Check[NotebookDirectory[], Directory[]], "..", "BlackBox"}],
   FileNameJoin[{Directory[], "..", "BlackBox"}],
   FileNameJoin[{Directory[], "BlackBox"}],
   "C:/Users/cp/Desktop/black-box/BlackBox"};
blackBoxLoaded = False;
Do[
  If[! blackBoxLoaded && Quiet[Check[DirectoryQ[d], False]],
    Quiet@Check[
      PacletDirectoryLoad[d];
      Needs["HubertKolcz`BlackBox`"];
      If[NameQ["HubertKolcz`BlackBox`AvNArgument"], blackBoxLoaded = True],
      Null]],
  {d, blackBoxCandidateDirs}];
Print["  BlackBox paclet loaded (optional cross-check available)? ", blackBoxLoaded,
  If[! blackBoxLoaded,
    "  -- proceeding with the SELF-CONTAINED ad hoc AvN check only (operator identity" <>
      " + branch-enumeration value product), which needs no paclet.", ""]];
If[blackBoxLoaded,
  ghzScen = CoverScenario[{"aX", "aY", "bX", "bY", "cX", "cY"},
     {{"aX", "bX", "cX"}, {"aX", "bY", "cY"}, {"aY", "bX", "cY"}, {"aY", "bY", "cX"}}]];

buildClusterState[nq_Integer, edgeList_List] := Module[{psiI, cz},
   psiI = Flatten[kp @@ ConstantArray[plusV, nq]];
   cz[i_, j_] := DiagonalMatrix[Table[
      If[IntegerDigits[b, 2, nq][[i]] == 1 && IntegerDigits[b, 2, nq][[j]] == 1, -1, 1],
      {b, 0, 2^nq - 1}]];
   Fold[#2 . #1 &, psiI, cz @@@ edgeList]];

Kstab[v_, nq_, edgeList_] := Module[{nb = neighborsOf[v, edgeList], a},
   a = <|v -> PX|>; Do[a[u] = PZ, {u, nb}];
   kp @@ Table[Lookup[a, k, I2], {k, 1, nq}]];

buildTripleMat[sortedT_List, assignment_Association] := kp @@ (pauliOf[assignment[#]] & /@ sortedT);

reduceState[psi_, nq_, keepList_List, fixedOutcomes_Association] := Module[{tensor, idxSpec},
   tensor = ArrayReshape[psi, ConstantArray[2, nq]];
   idxSpec = Table[If[MemberQ[keepList, q], All, fixedOutcomes[q] + 1], {q, 1, nq}];
   Flatten[tensor[[Sequence @@ idxSpec]]]];

projVec["X", 0] = {1, 1}/Sqrt[2]; projVec["X", 1] = {1, -1}/Sqrt[2];
projVec["Y", 0] = {1, I}/Sqrt[2]; projVec["Y", 1] = {1, -I}/Sqrt[2];

modelFromStateGeneral[psi3_, sortedT_List, roleOf_Association] := Module[
   {roleCtxLetter = <|"a" -> {"X", "X", "Y", "Y"}, "b" -> {"X", "Y", "X", "Y"}, "c" -> {"X", "Y", "Y", "X"}|>},
   Flatten[Table[
     Abs[Conjugate[Flatten[kp @@ (projVec[roleCtxLetter[roleOf[#]][[ctxIdx]], s[[Position[sortedT, #][[1, 1]]]]] & /@ sortedT)]] . psi3]^2,
     {ctxIdx, 1, 4}, {s, Tuples[{0, 1}, 3]}]]];

(* full witness test on a mesh cluster state: triple {a,center,c} with center's
   FULL neighbor set == {a,c} exactly (degree 2). Ad hoc check ALWAYS runs;
   BlackBox AvNArgument/ContextualFraction cross-check runs ONLY if the paclet
   loaded (see blackBoxLoaded above). *)
testWitness[psi_, nq_, edgeList_, a_, center_, c_, label_] := Module[
  {nb, sortedT, Aop, Bop, Cop, Eop, H3, opProd, otherQ, allOutcomes, results,
   kdev, roleOf, sub, nrm, psiGHZframe, mdl, avn, cf},
  nb = neighborsOf[center, edgeList];
  sortedT = Sort[{a, center, c}];
  kdev = Max[Abs[Chop[Kstab[center, nq, edgeList] . psi - psi]]];
  Aop = buildTripleMat[sortedT, <|a -> "X", center -> "X", c -> "X"|>];
  Bop = buildTripleMat[sortedT, <|a -> "X", center -> "Y", c -> "Y"|>];
  Cop = buildTripleMat[sortedT, <|a -> "Y", center -> "X", c -> "Y"|>];
  Eop = buildTripleMat[sortedT, <|a -> "Y", center -> "Y", c -> "X"|>];
  H3 = buildTripleMat[sortedT, <|a -> "H", center -> "I", c -> "H"|>];
  opProd = Chop[Aop . Bop . Cop . Eop] == -IdentityMatrix[8];
  otherQ = Complement[Range[nq], sortedT];
  allOutcomes = Tuples[{0, 1}, Length[otherQ]];
  results = Table[
    Module[{outAssoc, sub2, nrm2, psiGHZframe2, vals2},
     outAssoc = AssociationThread[otherQ -> outc];
     sub2 = reduceState[psi, nq, sortedT, outAssoc];
     nrm2 = Sqrt[Chop[Conjugate[sub2] . sub2]];
     If[nrm2 < 10^-9, Nothing,
      sub2 = sub2/nrm2;
      psiGHZframe2 = H3 . sub2;
      vals2 = Chop[Re[{psiGHZframe2 . Aop . psiGHZframe2, psiGHZframe2 . Bop . psiGHZframe2,
          psiGHZframe2 . Cop . psiGHZframe2, psiGHZframe2 . Eop . psiGHZframe2}]];
      Times @@ vals2]],
    {outc, allOutcomes}];
  {avn, cf} = If[blackBoxLoaded,
    roleOf = <|a -> "a", center -> "b", c -> "c"|>;
    sub = reduceState[psi, nq, sortedT, AssociationThread[otherQ -> ConstantArray[0, Length[otherQ]]]];
    nrm = Sqrt[Chop[Conjugate[sub] . sub]];
    sub = sub/nrm;
    psiGHZframe = H3 . sub;
    mdl = Chop[modelFromStateGeneral[psiGHZframe, sortedT, roleOf]];
    {AvNArgument[ghzScen, mdl]["AvN"], ContextualFraction[ghzScen, mdl]},
    {Missing["PacletNotLoaded"], Missing["PacletNotLoaded"]}];
  Print["  [", label, "] center=", center, " nb=", nb, " triple=", sortedT,
    "  K_center stabilizer? ", kdev < 10^-9, "  |ABCE=-I|? ", opProd,
    "  branches=", Length[results], " all valProd=-1? ", AllTrue[results, # == -1 &],
    "  || BlackBox: AvN=", avn, " CF=", cf];
  <|"Label" -> label, "Triple" -> sortedT, "KIsStab" -> (kdev < 10^-9), "OpIdentity" -> opProd,
    "AllBranchesMinusOne" -> AllTrue[results, # == -1 &], "BlackBoxAvN" -> avn, "BlackBoxCF" -> cf|>
];

avnAttempted = nQ <= avnMaxQubits;
If[avnAttempted,
  Module[{psiMesh, degree2Vertices, specs, results},
    Print["  nQ=", nQ, " <= avnMaxQubits=", avnMaxQubits, " -- running the full witness test."];
    psiMesh = buildClusterState[nQ, meshEdges];
    degree2Vertices = Select[Range[nQ], degreeOf[#, meshEdges] == 2 &];
    Print["  degree-2 vertices found (each carries its own local GHZ witness): ", degree2Vertices];
    specs = Table[
      Module[{nbrs = neighborsOf[v, meshEdges]},
        {nbrs[[1]], v, nbrs[[2]], "center=" <> ToString[v]}],
      {v, degree2Vertices}];
    avnResults = Table[testWitness[psiMesh, nQ, meshEdges, Sequence @@ spec], {spec, specs}];
    avnAllPass = Length[avnResults] > 0 &&
       AllTrue[avnResults, #["KIsStab"] && #["OpIdentity"] && #["AllBranchesMinusOne"] &];
    avnBlackBoxAllPass = blackBoxLoaded &&
       AllTrue[avnResults, TrueQ[#["BlackBoxAvN"]] && (#["BlackBoxCF"] == 1) &];
    Print["  all ", Length[avnResults], " degree-2-vertex witnesses pass the ad hoc check? ", avnAllPass];
    If[blackBoxLoaded, Print["  all witnesses independently confirmed by BlackBox AvNArgument/ContextualFraction? ", avnBlackBoxAllPass]];
  ],
  (
   avnResults = {};
   avnAllPass = False;
   avnBlackBoxAllPass = False;
   Print["  SKIPPED: nQ=", nQ, " exceeds avnMaxQubits=", avnMaxQubits,
     " (the largest qubit count actually verified in cct_cluster_avn_witness.wl)."];
   Print["  This does NOT mean the witness fails at this N -- it means this script"];
   Print["  refuses to silently extrapolate a check that was only computationally"];
   Print["  verified up to N=3 pentagons / 11 qubits. No 2^n matrices were built."];
  )];
Print["  AvN CHECK ATTEMPTED? ", avnAttempted,
  If[avnAttempted, "   PASSED? " <> ToString[avnAllPass], ""]];
Print[];

(* ===========================================================================
   SECTION 4. DLA DIMENSION CHECK (Proposition 0; feasibility-gated).
   REUSED, essentially verbatim, from cct_cluster_dla.wl.
   =========================================================================== *)
Print["--- SECTION 4: DLA dimension (Proposition 0), feasibility-gated ---"];

sigma1 = {{0, 1}, {1, 0}}; sigma2 = {{0, -I}, {I, 0}}; sigma3 = {{1, 0}, {0, -1}};
LieBracket[A_, B_] := A . B - B . A;

LinearlyIndependentQ[basis_List, newElem_] := Module[{flat},
   flat = Map[Flatten, basis];
   MatrixRank[Append[flat, Flatten[newElem]]] > Length[basis]];

(* the ORIGINAL algorithm, unmodified -- used only for the cheap n=2,3 cross-check. *)
GenerateDLA[gens_List] := Module[{basis, comm, changed},
   basis = Select[gens, Norm[Flatten[N[#]]] > 10^-10 &];
   changed = True;
   While[changed,
     changed = False;
     Do[
       comm = Chop[LieBracket[basis[[i]], basis[[j]]]];
       If[Norm[Flatten[comm]] > 10^-10,
         If[LinearlyIndependentQ[basis, comm], AppendTo[basis, comm]; changed = True]],
       {i, 1, Length[basis]}, {j, i + 1, Length[basis]}]];
   basis];

PauliGens[n_Integer] := Flatten[Table[
   I*KroneckerProduct[IdentityMatrix[2^(v - 1)], {sigma1, sigma2, sigma3}[[k]], IdentityMatrix[2^(n - v)]],
   {k, 1, 3}, {v, 1, n}], 1];

CZGens[n_Integer] := Table[
   I/4*KroneckerProduct[IdentityMatrix[2^(v - 1)], sigma3, sigma3, IdentityMatrix[2^(n - v - 1)]],
   {v, 1, n - 1}];

CZGensGraph[n_Integer, edges_List] := Table[
   With[{lo = Min[e[[1]], e[[2]]], hi = Max[e[[1]], e[[2]]]},
     I/4*KroneckerProduct[IdentityMatrix[2^(lo - 1)], sigma3,
       IdentityMatrix[2^(hi - lo - 1)], sigma3, IdentityMatrix[2^(n - hi)]]],
   {e, edges}];

(* GenerateDLAFast -- verified-equivalent, algorithmically faster closure:
   single monotone double loop + incremental Gram-Schmidt + early exit at the
   su(2^n) dimension cap 4^n-1. REUSED VERBATIM from cct_cluster_dla.wl. *)
GenerateDLAFast[gens_List, capDim_: Infinity, tol_: 10^-9] := Module[
   {basis, Q, i, j, v, coeffs, resid, nrm, comm, nPairs = 0, nNonzero = 0},
   basis = N[Select[gens, Norm[Flatten[N[#]]] > tol &]];
   Q = {};
   Do[
     v = Flatten[basis[[k]]];
     If[Length[Q] > 0, coeffs = Conjugate[Q] . v; resid = v - coeffs . Q, resid = v];
     nrm = Norm[resid];
     If[nrm > tol, AppendTo[Q, resid/nrm]],
     {k, Length[basis]}];
   i = 1;
   While[i <= Length[basis] && Length[basis] < capDim,
     j = i + 1;
     While[j <= Length[basis] && Length[basis] < capDim,
       nPairs++;
       comm = basis[[i]] . basis[[j]] - basis[[j]] . basis[[i]];
       v = Flatten[comm]; nrm = Norm[v];
       If[nrm > tol,
         nNonzero++;
         coeffs = Conjugate[Q] . v; resid = v - coeffs . Q; nrm = Norm[resid];
         If[nrm > tol, AppendTo[Q, resid/nrm]; AppendTo[basis, comm]]];
       j++];
     i++];
   <|"Dim" -> Length[basis], "PairsChecked" -> nPairs, "NonzeroCommutators" -> nNonzero,
     "HitCap" -> (Length[basis] >= capDim)|>];

(* correctness cross-checks, cheap (<5s total): GenerateDLAFast reproduces the
   ORIGINAL exact algorithm at n=2,3, and CZGensGraph reduces exactly to CZGens
   on a plain linear chain. *)
{t2c, d2c} = AbsoluteTiming[Length[GenerateDLA[Join[PauliGens[2], CZGens[2]]]]];
{t3c, d3c} = AbsoluteTiming[Length[GenerateDLA[Join[PauliGens[3], CZGens[3]]]]];
fastCheck = {GenerateDLAFast[Join[PauliGens[2], CZGens[2]]]["Dim"],
   GenerateDLAFast[Join[PauliGens[3], CZGens[3]]]["Dim"]};
fastMatchesOriginal = fastCheck == {d2c, d3c} == {15, 63};
chainEdgesTest[n_] := Table[{i, i + 1}, {i, 1, n - 1}];
czGraphMatchesOriginalChain = And @@ Table[CZGensGraph[n, chainEdgesTest[n]] == CZGens[n], {n, 2, 4}];
Print["  Engine self-check: GenerateDLAFast == GenerateDLA at n=2,3 (expect {15,63})? ",
  fastMatchesOriginal, "   CZGensGraph == CZGens on a chain, n=2..4? ", czGraphMatchesOriginalChain];

(* FIXED CEILING DEMONSTRATION: N=1 pentagon (5 qubits), the largest mesh size
   where the exact DLA closure is known (from cct_cluster_dla.wl) to complete.
   Always attempted, independent of nPentagonsRequested, wrapped in a generous
   TimeConstrained safety budget for portability to slower/cloud machines. *)
dlaCeilingN = 5; dlaCeilingCap = 4^dlaCeilingN - 1;
dlaCeilingEdges = PentagonChainEdges[1];
{dlaCeilingTime, dlaCeilingResult} = AbsoluteTiming[
   TimeConstrained[
     GenerateDLAFast[Join[PauliGens[dlaCeilingN], CZGensGraph[dlaCeilingN, dlaCeilingEdges]], dlaCeilingCap],
     dlaCeilingTimeoutSeconds,
     "TIMED_OUT"]];
dlaCeilingConfirmed = (Head[dlaCeilingResult] === Association) && (dlaCeilingResult["Dim"] == dlaCeilingCap);
Print["  Fixed ceiling: N=1 pentagon (", dlaCeilingN, " qubits): dim = ",
  If[Head[dlaCeilingResult] === Association, dlaCeilingResult["Dim"], dlaCeilingResult],
  " (expect ", dlaCeilingCap, "=4^", dlaCeilingN, "-1), time=", dlaCeilingTime, "s, confirmed? ",
  dlaCeilingConfirmed];
If[! dlaCeilingConfirmed,
  Print["  NOTE: ceiling computation did not complete/confirm within ", dlaCeilingTimeoutSeconds,
    "s on THIS machine -- relying on the previously-established result in cct_cluster_dla.wl",
    " (dim=1023, computed there in 77-114s under two independent vertex labelings)."]];

(* USER-REQUESTED MESH: gated. Full closure only if trivially small; a bounded,
   admittedly-incomplete probe if within dlaProbeMaxQubits; otherwise SKIPPED
   with the analytic (representational-impossibility) argument, no computation
   attempted at all.
   NOTE (adversarial review): under the current reps=Max[1,Round[N/3]] mesh
   convention, the smallest reachable nQ is 9 (N=3, one full ring/chain
   segment), which already exceeds dlaCeilingN=5 -- so the "EXACT" branch
   below is currently dead code, not a bug (it exists defensively in case the
   mesh convention is ever changed to allow smaller nQ; the always-run fixed
   N=1-pentagon ceiling above, at exactly 5 qubits, is what actually exercises
   the EXACT code path today). *)
dlaRequestedStatus = Which[
   nQ <= dlaCeilingN,
     "EXACT",
   nQ <= dlaProbeMaxQubits,
     "BOUNDED_PROBE_INCOMPLETE",
   True,
     "SKIPPED_INFEASIBLE"];

Which[
  dlaRequestedStatus == "EXACT",
    Module[{cap = 4^nQ - 1, res},
      res = GenerateDLAFast[Join[PauliGens[nQ], CZGensGraph[nQ, meshEdges]], cap];
      Print["  Requested mesh (", nQ, " qubits) IS at/below the exact ceiling: dim = ",
        res["Dim"], " (cap ", cap, ")."];
      dlaRequestedDim = res["Dim"]; dlaRequestedCap = cap;],
  dlaRequestedStatus == "BOUNDED_PROBE_INCOMPLETE",
    Module[{cap = 4^nQ - 1, probe, ptime},
      Print["  Requested mesh (", nQ, " qubits) exceeds the exact ceiling (", dlaCeilingN,
        " qubits) but is within the bounded-probe gate (<=", dlaProbeMaxQubits, ")."];
      Print["  Running a ", dlaProbeSeconds,
        "s SAFETY-BOUNDED probe -- NOT expected to complete (cap=", cap, "); this only"];
      Print["  demonstrates infeasibility empirically, per cct_cluster_dla.wl Section 7/8."];
      {ptime, probe} = AbsoluteTiming[
        TimeConstrained[
          GenerateDLAFast[Join[PauliGens[nQ], CZGensGraph[nQ, meshEdges]], cap],
          dlaProbeSeconds, "TIMED_OUT_" <> ToString[dlaProbeSeconds] <> "s"]];
      Print["  Probe result after ", ptime, "s: ",
        If[Head[probe] === Association,
          "dim so far = " <> ToString[probe["Dim"]] <> " / " <> ToString[cap] <>
            " (" <> ToString[N[100. probe["Dim"]/cap, 3]] <> "%)",
          probe]];
      dlaRequestedDim = If[Head[probe] === Association, probe["Dim"], Missing["TimedOut"]];
      dlaRequestedCap = cap;],
  True,
    (* IMPORTANT (caught while testing this update at nQ=9,000,000): the SKIP
       decision/gate itself is UNCHANGED, but the old code computed AND
       Print-ed the exact integer `cap = 4^nQ-1` for the diagnostic message.
       At nQ in the millions that integer has ~nQ*Log10[4] ~ several MILLION
       decimal digits -- materializing/printing it is itself an expensive
       operation whose cost grows with N (measured: ~5.4 MB of Print output
       and non-trivial decimal-conversion time at nQ=9,000,000), which
       violates "don't let a large N value cause this section to attempt
       anything expensive" just as surely as running the closure would. Fixed
       by reporting only the ORDER OF MAGNITUDE (O(1) via Log10), never
       materializing the full bignum; the returned association also no
       longer embeds a multi-million-digit number (relevant for
       RemoteBatchSubmit result retrieval at large N). *)
    Module[{capDigits = Ceiling[N[nQ*Log10[4]]]},
      Print["  Requested mesh (", nQ, " qubits) exceeds dlaProbeMaxQubits=", dlaProbeMaxQubits,
        " -- SKIPPED, no computation attempted."];
      Print["  dim(su(2^", nQ, ")) cap would be 4^", nQ, "-1, i.e. ~10^", capDigits,
        " (~", capDigits, " decimal digits, not materialized) -- constructing even the",
        " Pauli/CZ GENERATORS (2^", nQ, " x 2^", nQ,
        " matrices) is representationally infeasible at this size, let alone the closure."];
      Print["  Per cct_cluster_dla.wl Section 8: this is not a slow computation to speed up;"];
      Print["  it is a representational impossibility once n grows into the hundreds+."];
      dlaRequestedDim = Missing["NotAttempted"];
      dlaRequestedCap = Missing["TooLargeToMaterialize_ApproxDecimalDigits_" <> ToString[capDigits]];]];
Print["  DLA REQUESTED-N STATUS: ", dlaRequestedStatus];
Print[];

(* ===========================================================================
   SECTION 5. FINAL RESULT ASSOCIATION (house style, cf. CaseStudies.wl's
   CaseStudiesVerification) + self-contained cloud diagnostic tail.
   =========================================================================== *)
BridgeVerification = <|
   "Stabilizer_N1BaselineExactMatch" -> (n1StabResult["OperatorMatch"] && n1StabResult["StateMatch"]),
   "Stabilizer_RequestedNIndependentAndCommuting" -> (stabResult["IndependentQ"] && stabResult["AllCommuteQ"]),
   "AvN_Attempted" -> avnAttempted,
   "AvN_AllWitnessesPass" -> (avnAttempted && avnAllPass),
   "AvN_BlackBoxCrossCheckPass" -> (avnAttempted && avnBlackBoxAllPass),
   "DLA_FixedCeilingConfirmed" -> dlaCeilingConfirmed,
   "DLA_RequestedNStatus" -> dlaRequestedStatus
|>;

(* "OK" only ANDs the checks that actually ran and were expected to hold --
   skipped checks are reported separately (see HonestGaps) and are NEITHER
   silently passed NOR counted as failures. *)
attemptedOK = BridgeVerification["Stabilizer_N1BaselineExactMatch"] &&
   BridgeVerification["Stabilizer_RequestedNIndependentAndCommuting"] &&
   (! avnAttempted || avnAllPass) &&
   BridgeVerification["DLA_FixedCeilingConfirmed"];

honestGaps = Join[
   If[! avnAttempted,
     {"AvN witness check SKIPPED at N=" <> ToString[actualPentagons] <>
       " pentagons (" <> ToString[nQ] <> " qubits): exceeds the validated ceiling of " <>
       ToString[avnMaxQubits] <> " qubits established in cct_cluster_avn_witness.wl."},
     {}],
   If[avnAttempted && ! blackBoxLoaded,
     {"AvN BlackBox cross-check NOT performed (paclet not found in this evaluation " <>
       "environment) -- ad hoc operator-identity check still ran and is reported above."},
     {}],
   If[dlaRequestedStatus != "EXACT",
     {"DLA dimension at the REQUESTED N (" <> ToString[nQ] <> " qubits) is " <>
       dlaRequestedStatus <> " -- only the fixed N=1 pentagon (5-qubit) ceiling is " <>
       "exactly established; see cct_cluster_dla.wl for the full feasibility argument."},
     {}]
];

Print["=== SUMMARY ==="];
Print["BridgeVerification: ", BridgeVerification];
Print["All ATTEMPTED checks passed (OK)? ", attemptedOK];
Print["Honest gaps (things NOT established at the requested scale): "];
Do[Print["  - ", g], {g, honestGaps}];
Print[];
Print["Reminder: the STABILIZER check alone is the one component of this bridge"];
Print["genuinely verified to scale to MILLIONS of pentagons (sparse O(n+edges) method,"];
Print["benchmarked to 9,000,000 pentagons / 27,000,000 qubits in ~312s in"];
Print["cct_mesh_sparse_stabilizer.wl / cct_mesh_sparse_construction.wl); the AvN and DLA"];
Print["checks are honestly gated/skipped above the small N where they were actually"];
Print["computationally verified -- see header for the full scale-validity note."];

(* ---------------------------------------------------------------------------
   CLOUD-SUBMISSION TAIL: the FINAL expression (no trailing semicolon) is a
   self-contained diagnostic association, so RemoteBatchSubmit's
   EvaluationResult captures everything needed without depending on file
   retrieval from the remote machine.
   --------------------------------------------------------------------------- *)
<|
  "nPentagonsRequested" -> nPentagonsRequested,
  "actualPentagons" -> actualPentagons,
  "nQubits" -> nQ,
  "OK" -> attemptedOK,
  "BridgeVerification" -> BridgeVerification,
  "HonestGaps" -> honestGaps,
  "Stabilizer" -> <|
     "N1BaselineOperatorMatch" -> n1StabResult["OperatorMatch"],
     "N1BaselineStateMatch" -> n1StabResult["StateMatch"],
     "Method" -> "sparse O(n+edges) structural check (SparseValidateGraphState) -- replaces dense MatrixRank/symplectic-matrix-product for the requested N",
     "RequestedN_WellFormed" -> stabResult["WellFormed"],
     "RequestedN_Reasons" -> stabResult["Reasons"],
     "RequestedN_MaxDegree" -> stabResult["MaxDegree"],
     "RequestedN_IndependentQ" -> stabResult["IndependentQ"],
     "RequestedN_AllCommuteQ" -> stabResult["AllCommuteQ"],
     "DenseCrossCheck_Attempted" -> denseCrossCheckAttempted,
     "DenseCrossCheck_Agree" -> denseCrossCheckAgree,
     "ScalesToLargeN" -> True,
     "ScaleEvidence" -> "benchmarked to 27,000,000 qubits / 9,000,000 pentagons in ~312s in cct_mesh_sparse_stabilizer.wl; construction (Section 1) benchmarked to the same scale in cct_mesh_sparse_construction.wl"
  |>,
  "AvN" -> <|
     "Attempted" -> avnAttempted,
     "MaxQubitsGate" -> avnMaxQubits,
     "AllWitnessesPass" -> If[avnAttempted, avnAllPass, Missing["Skipped"]],
     "BlackBoxPacletLoaded" -> blackBoxLoaded,
     "BlackBoxCrossCheckAllPass" -> If[avnAttempted, avnBlackBoxAllPass, Missing["Skipped"]],
     "NumWitnessesTested" -> Length[avnResults],
     (* FIXED (adversarial review): this field previously implied 8/11-qubit
        cases were within THIS SCRIPT's own reach. They are not -- this
        bridge's own parametrization (reps=Round[N/3]) only ever produces
        qubit counts that are multiples of 9 (9, 18, 27, ...), so 8 and 11
        qubits can never occur here. Those cases were verified ONLY in the
        standalone cct_cluster_avn_witness.wl, on a DIFFERENT topology (open
        PentagonChain, not this script's wordRing["cct",reps] ring). The ONE
        case this bridge itself directly re-exercises and that overlaps with
        the standalone file is the literal ring at nPentagonsRequested=3
        (wordRing["cct",1], 9 qubits) -- everything else is imported evidence
        from a sibling file/topology, not reproduced by a run of this file. *)
     "ValidatedRadius" -> "THIS SCRIPT directly re-verifies only the literal cct ring at N=3 (wordRing[\"cct\",1], 9 qubits). The 8- and 11-qubit cases were verified in the STANDALONE cct_cluster_avn_witness.wl on a DIFFERENT (open PentagonChain) topology, not reachable by this script's own N->reps parametrization -- imported evidence, not reproduced here. NOT established beyond these specific cases on either topology."
  |>,
  "DLA" -> <|
     "FixedCeiling_N" -> dlaCeilingN,
     "FixedCeiling_Qubits" -> dlaCeilingN,
     "FixedCeiling_Dim" -> If[Head[dlaCeilingResult] === Association, dlaCeilingResult["Dim"], dlaCeilingResult],
     "FixedCeiling_ExpectedDim" -> dlaCeilingCap,
     "FixedCeiling_Confirmed" -> dlaCeilingConfirmed,
     "RequestedN_Qubits" -> nQ,
     "RequestedN_Status" -> dlaRequestedStatus,
     "RequestedN_DimFound" -> dlaRequestedDim,
     "RequestedN_Cap" -> dlaRequestedCap,
     "ValidatedRadius" -> "exact ONLY at N=1 pentagon (5 qubits); N=2 pentagons (8 qubits) did not complete in a 150s probe in cct_cluster_dla.wl -- NOT established beyond N=1"
  |>
|>
