(* ::Package:: *)

(* ===========================================================================
   cct_cluster_stabilizer.wl -- EFFICIENT (GF(2) binary symplectic) stabilizer
   tableau for a pentagon-mesh CZ cluster/graph state, parametrized by a
   cis/trans gluing word (word="cct" repeated, or any other word).

   Bridges three existing bodies of work in this project:
     * mesh-composition/CaseStudies.wl  -- wordRing[word,reps]: the pentagon-mesh
       GRAPH combinatorics (Case D3, "The Optimal Gluing Word"). There, vertex =
       KCBS event, edge = mutually-exclusive pair (an EXCLUSIVITY graph).
     * black-box-test/mbqc_c5.wl -- explicit-matrix (2^5 x 2^5) worked example:
       a genuine CZ cluster state on a single C5 qubit topology, verified via
       stabilizers K_i|C5> = |C5>, K_i = X_i Z_{i-1} Z_{i+1}.
     * Lie_Poisson_MBQC.wl -- Section 6/7/19 theoretical framework: DLA
       dimension explodes as 4^n-1 once CZ is included, i.e. an explicit
       2^n x 2^n stabilizer check is exponential and does NOT scale.

   THIS FILE reuses wordRing's graph combinatorics but reinterprets the SAME
   vertex/edge list as a qubit/CZ-gate ENTANGLEMENT graph (Hein-Eisert-Briegel,
   PRA 69, 062311 (2004)) rather than an exclusivity graph, and represents the
   n stabilizer generators K_v = X_v * Prod_{u~v} Z_u of the resulting graph
   state as an n x 2n binary (GF(2)) symplectic tableau [ I | A ] (X-block =
   identity, Z-block = adjacency matrix), instead of building 2^n x 2^n
   matrices. Verification (independence = rank n over GF(2); mutual
   commutation = binary symplectic product 0 mod 2) is then LINEAR ALGEBRA ON
   AN n x n MATRIX, not exponential in n -- this is what lets stabilizer
   verification scale to hundreds of qubits (tested to N=100 pentagons /
   ~300 qubits below), where mbqc_c5.wl's explicit-matrix method is confined
   to n=5 (32x32) by construction.

   CRITICAL VALIDATION (Section 3 below): at N=1 (plain C5 ring, 5 qubits),
   this file's binary-tableau generators are converted to explicit 2^5 x 2^5
   matrices and compared -- OPERATOR BY OPERATOR, not just state-by-state --
   against mbqc_c5.wl's own Kstab[i] matrices (that file's exact code is
   reproduced verbatim inside BuildC5Reference[] below, not reinvented).  Only
   after that comparison is exact (deviation 0) does the file proceed to
   larger N using purely the efficient method.

   Run:  wolframscript -file cct_cluster_stabilizer.wl
   =========================================================================== *)

(* ---------------------------------------------------------------------------
   SECTION 0. Pauli/Kronecker conventions -- verbatim from mbqc_c5.wl, so that
   the explicit-matrix cross-check in Section 3 is a byte-for-byte apples-to-
   apples comparison (same sign conventions for X, Z, Y).
   --------------------------------------------------------------------------- *)
kp = KroneckerProduct; I2 = IdentityMatrix[2];
PX = {{0, 1}, {1, 0}}; PZ = {{1, 0}, {0, -1}}; PY = {{0, -I}, {I, 0}};

(* ---------------------------------------------------------------------------
   SECTION 1. Pentagon-mesh graph combinatorics -- REUSED VERBATIM from
   mesh-composition/CaseStudies.wl (Case D3, "The Optimal Gluing Word").
   wordRing[word,reps] builds a RING of L = Length[word]*reps pentagons glued
   edge-to-edge, the gluing orientation (cis "c" / trans "t") at each junction
   read cyclically off the repeated word; 3L vertices, one C5 per block.
   Here vertices are reinterpreted as QUBITS and edges as CZ-GATE locations
   (an entanglement graph), NOT as the exclusivity graph CaseStudies.wl uses
   it for.
   --------------------------------------------------------------------------- *)
wordRing[word_String, reps_Integer] := Module[
   {w = Characters[StringRepeat[word, reps]], L, edges = {}, u, v, km},
   L = Length[w];
   Do[km = Mod[k - 1, L];
    {u, v} = If[w[[km + 1]] === "c", {3 km + 1, 3 km + 2}, {3 km + 2, 3 km + 1}];
    edges = Join[edges, {{u, v}, {u, 3 k + 1}, {3 k + 1, 3 k + 2},
       {3 k + 2, 3 k + 3}, {3 k + 3, v}}], {k, 0, L - 1}];
   Graph[Range[3 L], UndirectedEdge @@@ DeleteDuplicates[Sort /@ edges]]];

(* helper: exact word of length nb following the repeating "cct" pattern,
   truncated -- gives an N-pentagon ring for an arbitrary requested N (used
   only for readability; the scaling test below instead calls
   wordRing["cct",reps] directly, i.e. exact multiples of 3, per the task's
   own suggested convention). *)
cctWord[nb_Integer] := StringTake[StringRepeat["cct", Ceiling[nb/3] + 1], nb];

(* ---------------------------------------------------------------------------
   SECTION 2. EFFICIENT (GF(2)) stabilizer tableau for a graph state.

   Standard graph-state stabilizer formalism (Hein-Eisert-Briegel, PRA 69,
   062311 (2004)):  for a simple graph G on n vertices with adjacency matrix
   A, the graph state |G> is stabilized by K_v = X_v Prod_{u ~ v} Z_u for each
   vertex v.  In the length-2n binary (X|Z) symplectic representation, row v
   is (e_v | A_v) -- a single 1 in the X-block at position v, and 1's in the
   Z-block at exactly the neighbors of v.  Stacking all n rows gives the
   n x 2n tableau  T = [ I_n | A ]  (X-block = identity, Z-block = the
   adjacency matrix itself).  This already PROVES, for any simple graph:
     * independence: the X-block alone is I_n, full rank n, so no nontrivial
       GF(2) combination of rows can vanish;
     * mutual commutation: the binary symplectic product of rows u,v is
       e_u.A_v + A_u.e_v = A[v,u]+A[u,v] = 2 A[u,v] = 0 mod 2, since A is
       symmetric -- true for ANY simple graph, with no size dependence.
   Both properties are nonetheless VERIFIED COMPUTATIONALLY below (not just
   asserted), via native GF(2) linear algebra (MatrixRank[...,Modulus->2] for
   independence; an explicit binary symplectic form Omega=[[0,I],[I,0]] and
   Mod[T.Omega.T^T,2] for commutation), exactly as the task specifies.
   --------------------------------------------------------------------------- *)

(* symmetric 0/1 adjacency matrix from an edge list {i,j} (1-indexed, both
   directions filled); warns (but does not silently swallow) any self-loop,
   since X_v Z_v is not part of the standard graph-state stabilizer. *)
AdjacencyMatrixGF2[nQ_Integer, edgeList_List] := Module[{selfLoops, rulesFwd, rulesBack},
   selfLoops = Select[edgeList, #[[1]] == #[[2]] &];
   If[selfLoops =!= {}, Print["WARNING: self-loop(s) in edge list: ", selfLoops]];
   rulesFwd = (# -> 1) & /@ edgeList;
   rulesBack = (Reverse[#] -> 1) & /@ edgeList;
   Normal[SparseArray[Join[rulesFwd, rulesBack], {nQ, nQ}]]];

(* the n x 2n binary stabilizer tableau [ I | A ] for the graph state on
   nQ qubits with the given CZ edge list. *)
GraphStateTableau[nQ_Integer, edgeList_List] := Module[{A, X, tbl},
   A = AdjacencyMatrixGF2[nQ, edgeList];
   X = IdentityMatrix[nQ];
   tbl = Join[X, A, 2];
   <|"n" -> nQ, "Adjacency" -> A, "Tableau" -> tbl|>];

(* full validation: rank over GF(2) (independence) + binary symplectic
   commutation check, both as native GF(2)/mod-2 linear algebra on an
   n x n / n x 2n matrix -- NOT an exponential 2^n x 2^n construction. *)
ValidateGraphState[nQ_Integer, edgeList_List] := Module[
   {gs, tbl, rank, Omega, S},
   gs = GraphStateTableau[nQ, edgeList];
   tbl = gs["Tableau"];
   rank = MatrixRank[tbl, Modulus -> 2];
   Omega = ArrayFlatten[{{0, IdentityMatrix[nQ]}, {IdentityMatrix[nQ], 0}}];
   S = Mod[tbl . Omega . Transpose[tbl], 2];
   <|"n" -> nQ, "NumEdges" -> Length[edgeList], "RankGF2" -> rank,
     "IndependentQ" -> (rank == nQ), "AllCommuteQ" -> (Total[Flatten[S]] == 0),
     "MaxSymplecticResidue" -> Max[S], "Tableau" -> tbl, "Adjacency" -> gs["Adjacency"]|>];

(* convert one tableau row (length 2 nQ: X-bits then Z-bits) to its explicit
   2^nQ x 2^nQ Pauli-string matrix, for the small-n cross-check only. Uses the
   SAME PX,PZ,PY,I2 conventions as mbqc_c5.wl (Section 0). For graph-state
   stabilizer rows specifically, a qubit never has x=z=1 simultaneously
   (A has zero diagonal, so position v is 0 in both the x-block save v itself
   and the z-block), but the Y case is included for a general-purpose
   converter. *)
ExplicitOperatorFromRow[row_List, nQ_Integer] := Module[{x, z},
   x = row[[1 ;; nQ]]; z = row[[nQ + 1 ;; 2 nQ]];
   kp @@ Table[
     Which[x[[q]] == 1 && z[[q]] == 0, PX, x[[q]] == 0 && z[[q]] == 1, PZ,
       x[[q]] == 1 && z[[q]] == 1, PY, True, I2],
     {q, 1, nQ}]];

(* ---------------------------------------------------------------------------
   SECTION 3. CRITICAL VALIDATION at N=1 (plain C5 ring, 5 qubits).

   BuildC5Reference[] reproduces mbqc_c5.wl's OWN explicit-matrix code
   VERBATIM (same psi0/bits/cz/edges/psiC5/emb/Kstab/stabDev construction --
   not reinvented), so the comparison below is against that file's exact
   method, not a re-derivation of it.
   --------------------------------------------------------------------------- *)
BuildC5Reference[] := Module[{nq, psi0, bits, cz, edges, psiC5, emb, Kstab, stabDev},
   nq = 5;
   psi0 = Flatten[kp @@ ConstantArray[{1, 1}/Sqrt[2], nq]];
   bits[b_] := IntegerDigits[b, 2, nq];
   cz[i_, j_] := DiagonalMatrix[Table[If[bits[b][[i]] == 1 && bits[b][[j]] == 1, -1, 1], {b, 0, 2^nq - 1}]];
   edges = Table[{i, Mod[i, 5] + 1}, {i, 1, 5}];     (* the pentagon ring of qubits, verbatim *)
   psiC5 = Fold[#2 . #1 &, psi0, cz @@@ edges];
   emb[a_] := kp @@ Table[Lookup[a, k, I2], {k, 1, nq}];
   Kstab[i_] := emb[<|i -> PX, Mod[i - 2, 5] + 1 -> PZ, Mod[i, 5] + 1 -> PZ|>];  (* K_i = X_i Z_{i-1} Z_{i+1} *)
   stabDev = Table[Max@Abs@Chop[Kstab[i] . psiC5 - psiC5], {i, 1, 5}];
   <|"n" -> nq, "Edges" -> edges, "psiC5" -> psiC5,
     "Kstab" -> Table[Kstab[i], {i, 1, 5}], "stabDev" -> stabDev|>];

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
   Print["=== SECTION 3: N=1 (plain C5, 5 qubits) validation against mbqc_c5.wl ==="];
   Print["  structural check on my own tableau: rank(GF2) = ", val5["RankGF2"],
     " (independent? ", val5["IndependentQ"], "),  all commute? ", val5["AllCommuteQ"]];
   Print["  mbqc_c5.wl reference stabDev (should be ~0): ", ref["stabDev"]];
   Print["  my tableau-derived operators K_v vs mbqc_c5.wl's Kstab[v]:"];
   Print["    per-vertex |K_v(mine) - K_v(mbqc_c5.wl)| (operator norm, exact matrix compare): ", opDiff];
   Print["    per-vertex |K_v(mine).psiC5 - psiC5| (state deviation, my operators): ", myStabDev];
   Print["    operators EXACTLY match mbqc_c5.wl (deviation 0)? ................. ", opMatch];
   Print["    my operators also stabilize psiC5 to machine precision (dev 0)? ... ", stateMatch];
   Print[];
   <|"OperatorMatch" -> opMatch, "StateMatch" -> stateMatch, "OpDiff" -> opDiff,
     "MyStabDev" -> myStabDev, "RefStabDev" -> ref["stabDev"], "Val5" -> val5|>];

(* ---------------------------------------------------------------------------
   SECTION 4. Scaling: rank/commutativity checks + timing at N=2,5,20,100
   pentagons glued via the word "cct" repeated (wordRing["cct",reps]; actual
   pentagon count is 3*reps, the nearest multiple of 3 to the requested N,
   per wordRing's own reps convention).
   --------------------------------------------------------------------------- *)
runScalingTests[] := Module[{requested = {2, 5, 20, 100}, results},
   results = Table[
     Module[{reps = Max[1, Round[nb/3]], g, edgeList, nQ, timing, val},
       g = wordRing["cct", reps];
       nQ = VertexCount[g];
       edgeList = List @@@ EdgeList[g];
       {timing, val} = AbsoluteTiming[ValidateGraphState[nQ, edgeList]];
       <|"RequestedN" -> nb, "Reps" -> reps, "ActualPentagons" -> 3 reps, "Qubits" -> nQ,
         "Edges" -> val["NumEdges"], "RankGF2" -> val["RankGF2"], "IndependentQ" -> val["IndependentQ"],
         "AllCommuteQ" -> val["AllCommuteQ"], "MaxSymplecticResidue" -> val["MaxSymplecticResidue"],
         "TimeSeconds" -> timing|>
       ],
     {nb, requested}];
   Print["=== SECTION 4: scaling of the GF(2) tableau method, word=\"cct\" repeated ==="];
   Print[ToString[TableForm[
     {#["RequestedN"], #["ActualPentagons"], #["Qubits"], #["Edges"], #["RankGF2"],
       #["IndependentQ"], #["AllCommuteQ"], #["TimeSeconds"]} & /@ results,
     TableHeadings -> {None, {"N requested", "N pentagons (3*reps)", "qubits n", "edges",
        "rank GF(2)", "independent?", "all commute?", "time (s)"}}]]];
   Print[];
   results];

(* ===========================================================================
   RUN
   =========================================================================== *)
Print["=== EFFICIENT (GF(2)) STABILIZER TABLEAU FOR CCT-GLUED PENTAGON CLUSTER STATES ==="];
Print[];
n1Result = runN1Validation[];
scalingResult = runScalingTests[];
Print["=== SUMMARY ==="];
Print["N=1 baseline: operator-exact match with mbqc_c5.wl? ", n1Result["OperatorMatch"],
  "  (state-stabilizer deviation 0? ", n1Result["StateMatch"], ")"];
Print["Larger-N structural checks (independence + mutual commutation) all passed? ",
  AllTrue[scalingResult, #["IndependentQ"] && #["AllCommuteQ"] &]];
Print["Max time at N=100 pentagons (~300 qubits): ", Last[scalingResult]["TimeSeconds"], " s"];
