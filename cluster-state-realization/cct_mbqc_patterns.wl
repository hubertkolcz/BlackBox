(* ::Package:: *)

(* ===========================================================================
   cct_mbqc_patterns.wl -- quantum-algorithm MEASUREMENT PATTERNS on the fixed
   pentagon-mesh graph state, executed through the sparse CHP stabilizer
   simulator cct_mbqc_sim.wl.  Library of pattern functions:

     TeleportWire        (Gadget 1) -- gate-teleportation wire, +:H / -:XH.
     RunBernsteinVazirani(Gadget 2) -- n-bit planted secret, prob-1 readout.
     RunGrover2 / RunGroverParallel (Gadget 3) -- 2-qubit Grover, marked item.

   HONEST FRAMING (verbatim, required):
     Every pattern here is Clifford, so Gottesman-Knill guarantees efficient
     classical simulation.  The claim is FAITHFUL PROTOCOL-LEVEL MBQC execution
     of well-known quantum algorithms on the fixed pentagon-mesh graph state at
     scales far beyond any statevector simulator (JUPITER exascale record: 50
     qubits) or existing quantum hardware -- NOT a quantum-speedup claim.  The
     documented path to universality is T-gate injection / stabilizer-rank
     (cost 2^(alpha t) in T-count t).
   Citations: Anders & Browne PRL 102, 050502 (2009); Raussendorf PRA 88,
     022322 (2013); Hein, Eisert, Briegel PRA 69, 062311 (2004);
     Howard-Wallman-Veitch-Emerson Nature 510, 351 (2014); Aaronson-Gottesman
     PRA 70, 052328 (2004); Bernstein-Vazirani SIAM J.Comput 26,1411 (1997);
     Grover STOC 1996.

   PHYSICS CONVENTIONS (fixed project-wide, matching mbqc_c5.wl and the sim):
     * Graph state |G> = prod_{(i,j) in E} CZ_ij |+>^n ;  K_v = X_v prod_{u~v} Z_u.
     * The quantum resource is the FIXED mesh graph state from
       wordRingEdgesFast["cct",reps]; the edge list is NEVER edited.  Unused
       qubits are removed by ACTUAL Z-measurements inside the simulator; the
       only quantum operations after preparation are single-qubit X/Y/Z Pauli
       measurements plus classical (XOR-linear) feed-forward of a tracked Pauli
       byproduct frame.  (The one exception is the BV phase ORACLE Z^{s_i}, which
       is the queried unitary itself -- see RunBernsteinVazirani; every other
       operation is a measurement.)
     * Hein et al. local Pauli-measurement rules: Z-measurement deletes the
       vertex (Z byproduct on live neighbors for outcome 1); X-measurement
       contracts a wire (teleport step, applies H + outcome-dependent Pauli);
       Y-measurement = local complementation then deletion.

   KNOWN LIMITATIONS (review 2026-07-13, documented as accepted):
     * TeleportWire (Gadget 1 ONLY) POST-SELECTS the input-injection
       measurement: with "Forced"->Automatic the prep-vertex outcome is always
       forced to the CCTPrepSpec canonical value (probability 1/2 per shot on
       real hardware), while carve and teleport outcomes are genuinely random
       with tracked byproducts.  The unimplemented purist alternative would
       leave the prep outcome random and absorb the anti-branch (a Pauli image
       of the intended input) into the tracked frame.  BV, Grover and the NAND
       pipeline force NO outcomes anywhere (verified by instrumentation), so
       the headline results are unaffected.
     * The Grover cluster pattern is calibrated to the k == 0 (mod 3) pentagon
       context of the period-3 "cct" word (see Section P4 note).

   DEPENDS ON:  cct_mbqc_sim.wl  (same directory).  Set CCTMBQCPatternsLoadOnly
   = True before Get to suppress the self-check.

   Run:  wolframscript -file cct_mbqc_patterns.wl   (executes a fast self-check)
   Full validation suite:  cct_mbqc_patterns_tests.wl
   =========================================================================== *)

If[!ValueQ[CCTMBQCPatternsDir],
  CCTMBQCPatternsDir = DirectoryName[$InputFileName]];
Block[{CCTMBQCLoadOnly = True},
  Get[FileNameJoin[{CCTMBQCPatternsDir, "cct_mbqc_sim.wl"}]]];

(* ---------------------------------------------------------------------------
   SECTION P0. Mesh construction (wordRingEdgesFast copied VERBATIM from
   cct_mesh_sparse_construction.wl -- O(L) edge list, verified there to equal
   the original wordRing at reps=1..50 and benchmarked to reps=3e6; NOT edited).
   --------------------------------------------------------------------------- *)
wordRingEdgesFast[word_String, reps_Integer] := Module[{w, L, edgeBlocks},
   w = Characters[StringRepeat[word, reps]]; L = Length[w];
   edgeBlocks = Table[
     Module[{km = Mod[k - 1, L], u, v},
       {u, v} = If[w[[km + 1]] === "c", {3 km + 1, 3 km + 2}, {3 km + 2, 3 km + 1}];
       {{u, v}, {u, 3 k + 1}, {3 k + 1, 3 k + 2}, {3 k + 2, 3 k + 3}, {3 k + 3, v}}],
     {k, 0, L - 1}];
   DeleteDuplicates[Sort /@ Flatten[edgeBlocks, 1]]];

CCTMeshEdges[reps_Integer] := wordRingEdgesFast["cct", reps];
CCTMeshN[reps_Integer] := 9 reps;

(* adjacency in the ORIGINAL (uncarved) mesh, from the edge list *)
CCTNbrs[edges_List, v_Integer] :=
  Union[Cases[edges, {v, u_} :> u], Cases[edges, {u_, v} :> u]];
CCTAdjacency[edges_List, n_Integer] := Module[{a = ConstantArray[{}, n]},
  Do[a[[e[[1]]]] = Append[a[[e[[1]]]], e[[2]]];
     a[[e[[2]]]] = Append[a[[e[[2]]]], e[[1]]], {e, edges}];
  Sort /@ a];
CCTTips[edges_List, n_Integer] := Module[{a = CCTAdjacency[edges, n]},
  Select[Range[n], Length[a[[#]]] == 2 &]];

(* ---------------------------------------------------------------------------
   SECTION P1. Single-qubit stabilizer-state helpers (explicit-matrix aids for
   the n<=9 cross-checks; the tableau sim is the ground-truth executor).
   --------------------------------------------------------------------------- *)
CCTketPsi["0"] = {1, 0};            CCTketPsi["1"] = {0, 1};
CCTketPsi["+"] = {1, 1}/Sqrt[2];    CCTketPsi["-"] = {1, -1}/Sqrt[2];
CCTketPsi["+i"] = {1, I}/Sqrt[2];   CCTketPsi["-i"] = {1, -I}/Sqrt[2];
CCTHmat = {{1, 1}, {1, -1}}/Sqrt[2];
CCTPmat["I"] = IdentityMatrix[2]; CCTPmat["X"] = {{0, 1}, {1, 0}};
CCTPmat["Z"] = {{1, 0}, {0, -1}}; CCTPmat["Y"] = {{0, -I}, {I, 0}};

(* prep-neighbour measurement basis / outcome that leaves |psi> on the head:
     X-meas -> {|0>(s0),|1>(s1)} ; Z-meas -> {|+>(s0),|->(s1)} ;
     Y-meas -> {|-i>(s0),|+i>(s1)}   (machine-verified in the tests). *)
CCTPrepSpec["0"] = {"X", 0};  CCTPrepSpec["1"] = {"X", 1};
CCTPrepSpec["+"] = {"Z", 0};  CCTPrepSpec["-"] = {"Z", 1};
CCTPrepSpec["-i"] = {"Y", 0}; CCTPrepSpec["+i"] = {"Y", 1};

(* reduced 1-qubit density of qubit q from a full statevector v (n qubits) *)
CCTReducedRho1[v_List, q_Integer, n_Integer] := Module[
  {M = ArrayReshape[v, {2^(q - 1), 2, 2^(n - q)}]},
  Table[Sum[Conjugate[M[[i, a, j]]] M[[i, b, j]], {i, 2^(q - 1)}, {j, 2^(n - q)}],
    {a, 2}, {b, 2}]];

(* identify the SIGNED single-qubit Pauli byproduct P (in {I,X,Y,Z} x {+,-})
   with  P.psiExpected  proportional to the actual output pure state (given as
   its density rhoOut).  Returns {name,sign} or "UNFAITHFUL" if no Pauli works
   (i.e. teleportation did not land on a Pauli image of psiExpected). *)
CCTIdentifyByproduct[rhoOut_, psiExpected_List] := Module[{cands, rho, rn, tr},
  rho[psi_] := Module[{d = Outer[Times, psi, Conjugate[psi]]}, d/Tr[d]];
  tr = Tr[rhoOut];
  rn = If[Simplify[tr] === 0, rhoOut, rhoOut/tr];    (* normalize (sim state is unnormalized) *)
  cands = Reap[Do[
      With[{p = CCTPmat[nm], sgn = sg},
        If[Simplify[rho[sgn p . psiExpected] - rn] === {{0, 0}, {0, 0}}, Sow[{nm, sgn}]]],
      {nm, {"I", "X", "Y", "Z"}}, {sg, {1, -1}}]][[2]];
  If[cands === {}, "UNFAITHFUL",
    (If[cands[[1, 1, 2]] == 1, "+", "-"]) <> cands[[1, 1, 1]]]];

(* ---------------------------------------------------------------------------
   SECTION P2. GADGET 1 -- gate-teleportation WIRE.

   A wire is a PATH of mesh vertices  {prep, head, interior..., output}.  It is
   carved out of the fixed mesh by Z-measuring EVERY non-path qubit (real
   measurements; the edge list is not touched).  The logical input |psi> is
   injected by measuring the degree-1 prep vertex in the basis of CCTPrepSpec
   (a genuine single-qubit measurement -- see mapping above).  CAVEAT: the
   prep-vertex OUTCOME is post-selected to the CCTPrepSpec canonical value
   even with "Forced"->Automatic (see KNOWN LIMITATIONS in the file header);
   all other outcomes are random with tracked byproducts.  The interior
   vertices head..output-1 are then X-measured; each X-measurement is one
   teleport step applying H plus an outcome-dependent Pauli byproduct
   (mbqc_c5 rule  +:H|psi>, -:XH|psi>).  Output = (Pauli frame) . H^{k} |psi>,
   k = number of interior X-measurements.

   TeleportWire[reps, path, inState, opts] executes on the tableau sim.
     path       : list of mesh vertices forming a path (path[[1]] = prep vertex,
                  path[[-1]] = output vertex); must be an induced path once the
                  rest of the mesh is Z-carved.
     inState    : one of "0","1","+","-","+i","-i".
     "Forced"   : Automatic (random outcomes) or a list giving the forced
                  outcome for prep + each interior X-measurement, in order.
   Returns an association with the output statevector (tableau), the number k of
   H's applied, and the identified byproduct frame.
   --------------------------------------------------------------------------- *)
Options[TeleportWire] = {"Forced" -> Automatic, "ReturnState" -> True};

TeleportWire[reps_Integer, path_List, inState_String, OptionsPattern[]] := Module[
  {edges = CCTMeshEdges[reps], n = CCTMeshN[reps], prep, out, interior, others,
   forced = OptionValue["Forced"], tab, prepBasis, prepForced, xForced, k,
   recPrep, recX, outcomes = {}, vT, rho, frame, kH, fi = 1},
  prep = First[path]; out = Last[path];
  (* X-measured logical carriers = head..output-1 = every vertex strictly
     between the prep vertex and the output vertex *)
  interior = path[[2 ;; -2]];
  kH = Length[interior];                             (* one H per interior X-measurement *)
  others = Complement[Range[n], path];
  {prepBasis, prepForced} = CCTPrepSpec[inState];
  (* forced-outcome bookkeeping *)
  If[forced === Automatic,
    xForced = ConstantArray[Automatic, kH],
    CCTAssert[Length[forced] === kH + 1,
      "TeleportWire: Forced list must have length (#interior + 1)", {forced, kH}];
    prepForced = forced[[1]]; xForced = forced[[2 ;;]]];
  tab = NewGraphStateTableau[n, edges];
  (* carve: Z-measure all non-path qubits *)
  Do[MeasurePauli[tab, q, "Z"], {q, others}];
  (* inject |psi> on the head by measuring the prep vertex *)
  recPrep = MeasurePauli[tab, prep, prepBasis, "ForcedOutcome" -> prepForced];
  AppendTo[outcomes, recPrep["Outcome"]];
  (* teleport: X-measure each interior carrier in order *)
  Do[recX = MeasurePauli[tab, interior[[i]], "X", "ForcedOutcome" -> xForced[[i]]];
     AppendTo[outcomes, recX["Outcome"]], {i, kH}];
  vT = If[TrueQ[OptionValue["ReturnState"]] && n <= 10,
         StateVectorFromTableau[tab], Missing["StateSkipped"]];
  FreeTableau[tab];
  frame = If[Head[vT] === List,
    rho = CCTReducedRho1[vT, out, n];
    CCTIdentifyByproduct[rho, MatrixPower[CCTHmat, kH] . CCTketPsi[inState]],
    Missing["StateSkipped"]];
  <|"reps" -> reps, "path" -> path, "inState" -> inState, "kH" -> kH,
    "prepBasis" -> prepBasis, "outcomes" -> outcomes, "outputVertex" -> out,
    "outputState" -> vT, "byproductFrame" -> frame,
    "expectedLogical" -> MatrixPower[CCTHmat, kH] . CCTketPsi[inState]|>];

(* ---------------------------------------------------------------------------
   SECTION P3. GADGET 2 -- BERNSTEIN-VAZIRANI (n-bit planted secret s).

   Mapping: one pentagon per secret bit; register qubit = that pentagon's TIP
   (the unique degree-2 vertex, verified).  Per-bit mesh overhead = 1 pentagon
   = 3 qubits (rails/glues are shared backbone; only the tip is private).

   PROTOCOL (single measurement round, feed-forward is XOR-linear):
     1. Z-measure every NON-tip qubit (the rails/glues), recording outcomes.
        This isolates each tip to |+> up to a Z byproduct; by the Hein Z-rule
        the byproduct exponent on tip t is  frame_t = XOR of the outcomes of
        t's ORIGINAL mesh neighbours (all of which are measured).  [The
        measured-measured global sign is irrelevant to single-qubit readout.]
     2. ORACLE query U_s = prod_i Z_{tip_i}^{s_i}  (the phase oracle f(x)=s.x;
        this is the queried unitary, applied once).
     3. X-measure every tip, recording the raw outcome raw_i.
     4. Corrected readout  s_i = raw_i XOR frame_i   (deterministic: the tip
        physically holds Z^{frame_i} Z^{s_i} |+>, so raw_i = frame_i XOR s_i).
   The frame varies shot-to-shot with the random carve outcomes, but the
   corrected readout is INVARIANT and equals s exactly -- BV in one query.

   RunBernsteinVazirani[reps, secret] executes the whole pattern on the tableau
   sim of wordRingEdgesFast["cct",reps].  Length[secret] <= #tips = 3*reps.
   --------------------------------------------------------------------------- *)
RunBernsteinVazirani[reps_Integer, secret_List] := Module[
  {edges = CCTMeshEdges[reps], n = CCTMeshN[reps], tips, allTips, others, tab,
   zout, frame, raw, corrected, nbrsMeasured},
  allTips = CCTTips[edges, n];
  CCTAssert[Length[secret] <= Length[allTips],
    "RunBernsteinVazirani: secret longer than #tips (=3 reps)", {Length[secret], Length[allTips]}];
  CCTAssert[SubsetQ[{0, 1}, Union[secret]] || Union[secret] === {} ||
            Union[secret] === {0} || Union[secret] === {1} || Union[secret] === {0,1},
    "RunBernsteinVazirani: secret must be a 0/1 list", secret];
  tips = Take[allTips, Length[secret]];
  others = Complement[Range[n], tips];               (* every non-register qubit is carved *)
  tab = NewGraphStateTableau[n, edges];
  zout = Association[Table[q -> MeasurePauli[tab, q, "Z"]["Outcome"], {q, others}]];
  frame = Table[
    nbrsMeasured = Select[CCTNbrs[edges, tips[[i]]], KeyExistsQ[zout, #] &];
    Mod[Total[Lookup[zout, nbrsMeasured]], 2], {i, Length[tips]}];
  Do[If[secret[[i]] == 1, ApplyZ[tab, tips[[i]]]], {i, Length[tips]}];  (* oracle *)
  raw = Table[MeasurePauli[tab, tips[[i]], "X"]["Outcome"], {i, Length[tips]}];
  corrected = Table[Mod[raw[[i]] + frame[[i]], 2], {i, Length[tips]}];
  FreeTableau[tab];
  <|"reps" -> reps, "n" -> n, "tips" -> tips, "secret" -> secret,
    "frame" -> frame, "raw" -> raw, "recovered" -> corrected,
    "correct" -> (corrected === secret),
    "pentagonsPerBit" -> 1, "qubitsPerBit" -> 3|>];

(* ---------------------------------------------------------------------------
   SECTION P4. GADGET 3 -- 2-qubit GROVER (single iteration, exact).

   Cluster: two ADJACENT pentagons k, k+1 (they share pentagon k's rail pair,
   which is pentagon k+1's glue pair).  Their induced subgraph is two 5-cycles
   sharing one edge -- an 8-vertex cluster present at EVERY interior location of
   the mesh (so it tiles for RunGroverParallel), unlike the induced hexagon that
   exists only at reps=1.  CANONICAL 8-vertex labelling (edges verified against
   the actual mesh):
     1 = 3(k-1)+1   2 = 3(k-1)+2      (pentagon k's glue pair = pent k-1 rails)
     3 = 3k+1       4 = 3k+2          (shared rail pair)     5 = 3k+3 (tip k)
     6 = 3(k+1)+1   7 = 3(k+1)+2      (pent k+1 rails)       8 = 3(k+1)+3 (tip k+1)
   canonical edges {1,2},{1,5},{2,3},{3,4},{3,6},{4,5},{4,8},{6,7},{7,8}.
   OUTPUT (logical) qubits = canonical {1,3}; the other six are MEASURED in the
   basis pattern below (measurement order canonical {2,4,5,6,7,8}).

   The single-iteration 2-qubit Grover circuit  |00>-H2-O_m-D-measure  (all
   Clifford; verified |m> with fidelity 1) is COMPILED onto this cluster: the
   marked item m selects the Pauli-measurement bases (the compiled oracle -- the
   same way inputs enter the Anders-Browne gadget as X/Y basis choices), and the
   fixed XOR-linear byproduct frame on the six recorded outcomes plus the Z
   read-out of the two output qubits returns m DETERMINISTICALLY (probability 1)
   for every measurement branch.  The four per-mark patterns were found by exact
   search over the cluster and re-verified branch-by-branch against the tableau
   sim AND the explicit Grover unitary (see cct_mbqc_patterns_tests.wl).

   Frame semantics: for mark m the recorded pattern outcomes o (length 6) give
   raw Z read-outs r=(r1,r2); corrected bit b_i = r_i XOR (linFrame_i . o).  The
   chosen pattern has corrected == m for all branches.  Region isolation
   (Z-carving the rest of the mesh) adds Hein Z-byproducts on the cluster's
   boundary vertices; a boundary vertex measured in X or Y has its outcome
   flipped by the parity of its carved neighbours' outcomes (Z-basis pattern
   measurements and the Z read-out are unaffected).  This is folded in before
   the linear frame -- keeping the corrected read-out deterministic.
   --------------------------------------------------------------------------- *)
CCTGroverMeasCanon = {2, 4, 5, 6, 7, 8};
CCTGroverOutCanon = {1, 3};
CCTGroverPattern = <|
  0 -> {{"X", "X", "X", "X", "Z", "X"}, {{1, 0, 0, 1, 1, 0}, {0, 0, 0, 1, 1, 0}}},
  1 -> {{"Y", "Z", "X", "Y", "X", "Y"}, {{0, 1, 1, 0, 0, 0}, {0, 1, 0, 1, 1, 1}}},
  2 -> {{"Y", "X", "Y", "X", "Z", "Y"}, {{0, 1, 1, 1, 0, 1}, {0, 0, 0, 1, 1, 0}}},
  3 -> {{"X", "X", "Y", "X", "X", "Y"}, {{0, 1, 1, 1, 0, 1}, {1, 1, 1, 1, 0, 1}}}|>;

(* canonical -> mesh vertex map for the pentagon pair (k, k+1) *)
CCTGroverCanonMap[k_Integer] := <|
  1 -> 3 (k - 1) + 1, 2 -> 3 (k - 1) + 2, 3 -> 3 k + 1, 4 -> 3 k + 2,
  5 -> 3 k + 3, 6 -> 3 (k + 1) + 1, 7 -> 3 (k + 1) + 2, 8 -> 3 (k + 1) + 3|>;

(* markedItem accepted as integer 0..3 or 2-bit {m1,m2} (m1 = high bit). *)
CCTGroverMarkInt[m_Integer] := m;
CCTGroverMarkInt[m_List] := FromDigits[m, 2];

(* run ONE Grover instance whose cluster is at pentagon pair (k,k+1) on an
   already-built tableau `tab` whose non-cluster qubits have ALREADY been
   Z-measured (outcomes in the association `zout`, keyed by qubit).  Returns the
   frame-corrected 2-bit output {b1,b2}. *)
CCTGroverRunInstance[tab_Symbol, edges_List, k_Integer, mark_Integer, zout_] := Module[
  {cm = CCTGroverCanonMap[k], bases, lin, meas, outs, pflip, clean, zread, frame},
  {bases, lin} = CCTGroverPattern[mark];
  meas = cm /@ CCTGroverMeasCanon; outs = cm /@ CCTGroverOutCanon;
  pflip[v_] := Mod[Total[Lookup[zout, Select[CCTNbrs[edges, v], KeyExistsQ[zout, #] &], 0]], 2];
  clean = Table[Module[{v = meas[[j]], b = bases[[j]], rw},
     rw = MeasurePauli[tab, v, b]["Outcome"];
     Mod[rw + If[b === "Z", 0, pflip[v]], 2]], {j, 6}];
  zread = Table[MeasurePauli[tab, outs[[j]], "Z"]["Outcome"], {j, 2}];
  frame = {Mod[lin[[1]] . clean, 2], Mod[lin[[2]] . clean, 2]};
  {Mod[zread[[1]] + frame[[1]], 2], Mod[zread[[2]] + frame[[2]], 2]}];

(* RunGrover2[markedItem] -- single 2-qubit Grover instance on one carved
   pentagon-pair of a small mesh; returns {found, expected, correct, ...}. *)
Options[RunGrover2] = {"reps" -> 3, "k" -> 3};
RunGrover2[markedItem_, OptionsPattern[]] := Module[
  {mark = CCTGroverMarkInt[markedItem], reps = OptionValue["reps"], k = OptionValue["k"],
   edges, n, cm, cluster, others, tab, zout, corr},
  CCTAssert[Mod[k, 3] == 0,
    "RunGrover2: k must be == 0 (mod 3) to match the calibrated pentagon context", k];
  CCTAssert[2 <= k <= 3 reps - 2,
    "RunGrover2: need an interior pentagon pair (2 <= k <= 3 reps - 2)", {k, reps}];
  edges = CCTMeshEdges[reps]; n = CCTMeshN[reps];
  cm = CCTGroverCanonMap[k]; cluster = Values[cm];
  others = Complement[Range[n], cluster];
  tab = NewGraphStateTableau[n, edges];
  zout = Association[Table[q -> MeasurePauli[tab, q, "Z"]["Outcome"], {q, others}]];
  corr = CCTGroverRunInstance[tab, edges, k, mark, zout];
  FreeTableau[tab];
  <|"markedItem" -> IntegerDigits[mark, 2, 2], "found" -> corr,
    "correct" -> (corr === IntegerDigits[mark, 2, 2]),
    "reps" -> reps, "k" -> k|>];

(* RunGroverParallel[M] -- M independent Grover instances in DISJOINT pentagon-
   pair regions of ONE mesh, each with its own (random unless given) marked item,
   all measured in a single round; verifies region isolation.  Instances are
   spaced by `spacing` pentagons (>=4 keeps clusters + their Z-buffer sources
   disjoint on the ring). *)
(* NB: the "cct" word makes the pentagon-pair context period-3 in k; the fixed
   canonical pattern is calibrated to the k == 0 (mod 3) context (verified at
   k=3).  Parallel instances therefore use k == 0 (mod 3): startK=3 and a spacing
   that is a multiple of 3 (default 6) keeps every instance in the same context
   AND keeps clusters + their Z-buffer sources disjoint on the ring. *)
Options[RunGroverParallel] = {"spacing" -> 6, "marks" -> Automatic, "startK" -> 3};
RunGroverParallel[M_Integer, OptionsPattern[]] := Module[
  {spacing = OptionValue["spacing"], startK = OptionValue["startK"], marks,
   ks, reps, edges, n, clusters, allCluster, others, tab, zout, results},
  ks = Table[startK + spacing (j - 1), {j, M}];
  (* +spacing pentagons of slack so the RING seam between the last instance and
     the wrap-around to the first stays wider than one buffer pentagon *)
  reps = Ceiling[(Last[ks] + 3 + spacing)/3];
  edges = CCTMeshEdges[reps]; n = CCTMeshN[reps];
  marks = OptionValue["marks"];
  If[marks === Automatic, marks = RandomInteger[{0, 3}, M]];
  clusters = Values[CCTGroverCanonMap[#]] & /@ ks;
  allCluster = Union @@ clusters;
  others = Complement[Range[n], allCluster];
  tab = NewGraphStateTableau[n, edges];
  zout = Association[Table[q -> MeasurePauli[tab, q, "Z"]["Outcome"], {q, others}]];
  results = Table[Module[{corr = CCTGroverRunInstance[tab, edges, ks[[j]], marks[[j]], zout]},
     <|"k" -> ks[[j]], "mark" -> IntegerDigits[marks[[j]], 2, 2], "found" -> corr,
       "correct" -> (corr === IntegerDigits[marks[[j]], 2, 2])|>], {j, M}];
  FreeTableau[tab];
  <|"M" -> M, "reps" -> reps, "n" -> n, "spacing" -> spacing,
    "allCorrect" -> AllTrue[results, #["correct"] &],
    "numCorrect" -> Count[results, _?(#["correct"] &)], "results" -> results|>];

(* ---------------------------------------------------------------------------
   SECTION P9. Guarded self-check.
   --------------------------------------------------------------------------- *)
If[!TrueQ[CCTMBQCPatternsLoadOnly],
  Module[{w, bv},
    Print["=== cct_mbqc_patterns.wl self-check ==="];
    Print["--- wire: push |+> through reps=1 path {3,2,1}, forced +,+ ---"];
    w = TeleportWire[1, {3, 2, 1}, "+", "Forced" -> {0, 0}];
    Print["    kH=", w["kH"], "  byproductFrame=", w["byproductFrame"],
      "  (expected logical H^1|+> = |0>)"];
    Print["--- BV: reps=1, secret {1,0,1} ---"];
    bv = RunBernsteinVazirani[1, {1, 0, 1}];
    Print["    recovered=", bv["recovered"], "  correct=", bv["correct"],
      "  frame=", bv["frame"], "  raw=", bv["raw"]];
    Print["--- Grover: 2-qubit, all 4 marked items ---"];
    Do[With[{g = RunGrover2[m]},
       Print["    mark ", IntegerDigits[m, 2, 2], " -> found ", g["found"],
         "  correct=", g["correct"]]], {m, {0, 1, 2, 3}}];
    Print["--- Grover parallel: 3 disjoint instances ---"];
    With[{gp = RunGroverParallel[3, "marks" -> {1, 2, 3}]},
      Print["    all correct=", gp["allCorrect"], "  (", gp["numCorrect"], "/3), reps=", gp["reps"]]];
    Print["CCTMBQCPatternsSelfCheck done."];
  ]
]
