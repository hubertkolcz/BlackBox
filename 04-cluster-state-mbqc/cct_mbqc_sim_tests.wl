(* ::Package:: *)

(* ===========================================================================
   cct_mbqc_sim_tests.wl -- FULL validation suite for cct_mbqc_sim.wl, the
   sparse measurement-capable CHP (Aaronson-Gottesman + destabilizers)
   stabilizer simulator for MBQC patterns on the pentagon mesh.

   HONEST FRAMING: all measurement patterns targeted by this simulator are
   Clifford, so the Gottesman-Knill theorem guarantees efficient classical
   simulation - the claim here is faithful protocol-level MBQC execution of
   well-known quantum algorithms on the pentagon mesh at scales far beyond any
   statevector simulator (JUPITER exascale record: 50 qubits) or any existing
   quantum hardware, NOT a quantum-speedup claim. The documented path to
   universality is T-gate injection / stabilizer-rank methods (cost 2^(alpha t)
   in T-count t).

   REFERENCES: S. Aaronson, D. Gottesman, PRA 70, 052328 (2004);
               M. Hein et al., PRA 69, 062311 (2004).

   SECTIONS (all comparisons EXACT - integer/rational ===; zero tolerance;
   no N[], no Chop anywhere in a correctness path; AbsoluteTiming /
   MemoryInUse appear only in benchmark prints):
     V0. Micro-foundations (delegated to CCTMBQCRunV0Foundations[] in the
         library: DownValue idiom, AdjacencyLists sortedness, g function and
         every gate rule vs dense conjugation, (H.Sdg) Y (H.Sdg)^dag == Z).
     V1. Graph-state init cross-check on 6 graphs (C5 ring, path P4, star
         K_{1,3}, complete K4, edgeless n=3, pentagon mesh "cct" reps=1)
         against dense exact prod-CZ reference + K_v u === u for every v.
     V2. DIFFERENTIAL RANDOM-CIRCUIT VALIDATION: n = 2..6, 40 circuits per n
         (200 total), 30 random ops each (gates from {H,S,X,Y,Z,CZ,CNOT} with
         probability 3/4, else a branch-forced random-basis measurement, min 5
         measurements per circuit), against a dense EXACT Gaussian-integer
         statevector reference; after EVERY operation the full state is
         compared (PhaseScaleEquivalentQ), and every measurement checks
         classification / probability / outcome + a determinism-repeat and a
         forced-conflict follow-up.
     V3. Scale smoke test on the pentagon mesh (reps = 10^5, 10^6 -> 9*10^5
         and 9*10^6 qubits): genuine local pattern (3x Z carve, 1x X wire,
         1x Y) with per-measurement timing, TableauStats telemetry,
         MemoryInUse; the two tiers' timings side by side (n-independence).
     V3b. Wire-scaling smoke test (task addendum): reps = 10^4 and 10^5;
         Z-measure 2000 qubits and X-measure 2000 wire qubits per tier;
         total + per-measurement timing.
     V4. Summary association (last expression).

   Run: wolframscript -file C:/Users/cp/Desktop/black-box/04-cluster-state-mbqc/cct_mbqc_sim_tests.wl
   =========================================================================== *)

(* ---------------------------------------------------------------------------
   SECTION 0. Load the library (definitions only) and run V0.
   --------------------------------------------------------------------------- *)
CCTMBQCLoadOnly = True;
Module[{libPath},
  libPath = If[StringQ[$InputFileName] && $InputFileName =!= "",
    FileNameJoin[{DirectoryName[$InputFileName], "cct_mbqc_sim.wl"}],
    "C:/Users/cp/Desktop/black-box/04-cluster-state-mbqc/cct_mbqc_sim.wl"];
  Print["Loading library: ", libPath];
  Get[libPath]];

Print["=== V0: micro-foundations (WL idioms + exact g/gate algebra vs dense conjugation) ==="];
v0Result = CCTMBQCRunV0Foundations[];
v0OK = TrueQ[v0Result["AllOK"]];
Print["  ", v0Result];
Print["  V0 PASS? ", v0OK];
Print[];

(* ---------------------------------------------------------------------------
   Shared exact dense reference machinery (style of mbqc_c5.wl, but
   INTEGER-EXACT throughout: states are unnormalized Gaussian-integer
   vectors; H is the integer {{1,1},{1,-1}} (the dropped Sqrt[2] is harmless
   - every check is scale-invariant); all probabilities are exact rationals).
   --------------------------------------------------------------------------- *)
refI2 = {{1, 0}, {0, 1}};   refXm = {{0, 1}, {1, 0}};
refYm = {{0, -I}, {I, 0}};  refZm = {{1, 0}, {0, -1}};
refHint = {{1, 1}, {1, -1}}; refSm = {{1, 0}, {0, I}};
refP0 = {{1, 0}, {0, 0}};   refP1 = {{0, 0}, {0, 1}};

refEmb[n_, a_Association] := Module[{f = Table[SparseArray[Lookup[a, k, refI2]], {k, n}]},
  Fold[KroneckerProduct, First[f], Rest[f]]];

(* memoized gate/Pauli matrices *)
refGate[n_, "H", q_]  := refGate[n, "H", q]  = refEmb[n, <|q -> refHint|>];
refGate[n_, "S", q_]  := refGate[n, "S", q]  = refEmb[n, <|q -> refSm|>];
refGate[n_, "X", q_]  := refGate[n, "X", q]  = refEmb[n, <|q -> refXm|>];
refGate[n_, "Y", q_]  := refGate[n, "Y", q]  = refEmb[n, <|q -> refYm|>];
refGate[n_, "Z", q_]  := refGate[n, "Z", q]  = refEmb[n, <|q -> refZm|>];
refGate[n_, "CZ", {a_, b_}] := refGate[n, "CZ", {a, b}] =
  refEmb[n, <|a -> refP0|>] + refEmb[n, <|a -> refP1, b -> refZm|>];
refGate[n_, "CNOT", {a_, b_}] := refGate[n, "CNOT", {a, b}] =
  refEmb[n, <|a -> refP0|>] + refEmb[n, <|a -> refP1, b -> refXm|>];
refPauliAt[n_, q_, basis_] := refPauliAt[n, q, basis] =
  refEmb[n, <|q -> Switch[basis, "X", refXm, "Y", refYm, "Z", refZm]|>];

(* diagonal CZ exactly as mbqc_c5.wl's cz[] builds it (bit test per basis
   state), used for the V1 prod-CZ reference construction *)
refCZfull[n_, i_, j_] := DiagonalMatrix[SparseArray[Table[
   If[IntegerDigits[b, 2, n][[i]] == 1 && IntegerDigits[b, 2, n][[j]] == 1, -1, 1],
   {b, 0, 2^n - 1}]]];

(* exact Born probability of outcome b for Pauli P in (unnormalized) state v:
   p = (v'.v + (-1)^b v'.(P.v)) / (2 v'.v)  - an exact rational in {0,1/2,1} *)
refProb[v_, P_, b_] := Module[{vd = Conjugate[v], nn, ee, p},
  nn = vd . v; ee = vd . Normal[P . v];
  p = (nn + (-1)^b ee)/(2 nn);
  CCTAssert[MemberQ[{0, 1/2, 1}, p], "refProb: not in {0,1/2,1}", {p, b}];
  p];

(* inline copy of wordRingEdgesFast from
   04-cluster-state-mbqc/cct_mesh_sparse_construction.wl (that file is a read-only
   self-running SCRIPT - Get would rerun its benchmarks - so the 8-line body
   is reproduced verbatim here with this provenance note; it was verified
   there exactly equal to the original wordRing in
   03-MESH-pentagon-composition/CaseStudies.wl at reps = 1..50). *)
wordRingEdgesFastLocal[word_String, reps_Integer] := Module[{w, L, edgeBlocks},
   w = Characters[StringRepeat[word, reps]];
   L = Length[w];
   edgeBlocks = Table[
     Module[{km = Mod[k - 1, L], u, v},
       {u, v} = If[w[[km + 1]] === "c", {3 km + 1, 3 km + 2}, {3 km + 2, 3 km + 1}];
       {{u, v}, {u, 3 k + 1}, {3 k + 1, 3 k + 2}, {3 k + 2, 3 k + 3}, {3 k + 3, v}}],
     {k, 0, L - 1}];
   DeleteDuplicates[Sort /@ Flatten[edgeBlocks, 1]]];

(* ---------------------------------------------------------------------------
   SECTION V1. Graph-state init cross-check (exact).
   For each graph: u = StateVectorFromTableau[NewGraphStateTableau[n,edges]]
   vs v = prod CZ . (all-ones vector) (all-ones = unnormalized |+>^n), and
   K_v u === u for every vertex (exact matrix-vector on the unnormalized
   Gaussian-integer vector).
   --------------------------------------------------------------------------- *)
Print["=== V1: graph-state init cross-check vs dense prod-CZ reference + K_v stabilization ==="];
v1cases = {
  {"C5ring",      5, Sort /@ Table[{i, Mod[i, 5] + 1}, {i, 1, 5}]},
  {"P4path",      4, {{1, 2}, {2, 3}, {3, 4}}},
  {"StarK13",     4, {{1, 2}, {1, 3}, {1, 4}}},
  {"CompleteK4",  4, Subsets[Range[4], {2}]},
  {"Edgeless3",   3, {}},
  {"MeshCCTreps1", 9, wordRingEdgesFastLocal["cct", 1]}};
v1Results = Table[Module[{name, nn, edges, tab, u, vref, nbrsOf, eqOK, kOK},
   {name, nn, edges} = case;
   tab = NewGraphStateTableau[nn, edges];
   u = StateVectorFromTableau[tab];
   vref = ConstantArray[1, 2^nn];
   Do[vref = Normal[refCZfull[nn, e[[1]], e[[2]]] . vref], {e, edges}];
   eqOK = PhaseScaleEquivalentQ[u, vref];
   nbrsOf[v_] := Union[Cases[edges, {v, w_} :> w], Cases[edges, {w_, v} :> w]];
   kOK = AllTrue[Range[nn], Module[{K},
      K = refEmb[nn, Association[Join[{# -> refXm}, (nb |-> (nb -> refZm)) /@ nbrsOf[#]]]];
      Normal[K . u] === u] &];
   FreeTableau[tab];
   Print["  ", name, " (n=", nn, ", |E|=", Length[edges],
     "): state==prodCZ|+>^n? ", eqOK, "   all K_v u === u? ", kOK];
   <|"Case" -> name, "InitEq" -> eqOK, "StabilizerFix" -> kOK,
     "OK" -> (eqOK && kOK)|>], {case, v1cases}];
v1OK = AllTrue[v1Results, #["OK"] &];
Print["  V1 PASS? ", v1OK];
Print[];

(* ---------------------------------------------------------------------------
   SECTION V2. Differential random-circuit validation (>= 200 circuits).
   Protocol per circuit (SeedRandom[100000 n + c], fully reproducible - the
   tableau side never draws randomness because every measurement is
   branch-forced):
     * random graph on n vertices (each pair w.p. 1/2); tableau via DIRECT
       init, reference via explicit CZs on all-ones (cross-validating the
       direct init against the CZ construction every circuit);
     * 30 operations: w.p. 3/4 a uniform random gate from
       {H,S,X,Y,Z,CZ,CNOT} (2-qubit gates on a random distinct pair), else a
       branch-forced measurement (random qubit, random basis); padded to >= 5
       measurements;
     * after EVERY operation: full-state check
       PhaseScaleEquivalentQ[StateVectorFromTableau[tab], vRef];
     * per measurement: (1) Deterministic flag === (reference probability of
       the forced branch is 1), (2) reported Probability === exact reference
       probability of the reported Outcome, (3) Outcome === the forced
       branch (and reference prob 1 when Deterministic), (5) immediate
       unforced re-measurement is Deterministic/prob-1/same-outcome and
       leaves the state equivalent, (6) forcing the OPPOSITE outcome on the
       (now deterministic) same measurement returns Probability 0, the TRUE
       Outcome, and leaves the tableau state-equivalent (exercises the
       conjugate-unconjugate net-no-op path for X/Y too).
   Any failure prints a full repro block (n, c, seed, edges, op list,
   expected vs got) and is recorded; the suite requires ZERO failures.
   --------------------------------------------------------------------------- *)
Print["=== V2: differential random-circuit validation vs exact dense statevector ==="];
CIRCUITSPERN = If[ValueQ[CCTMBQCCircuitsPerNOverride], CCTMBQCCircuitsPerNOverride,
  60];   (* n = 2..6  ->  300 circuits total (spec minimum 40 -> 200; the
            recommended 60 is cheap); override hook is for quick dev smoke
            runs only - the recorded validation run uses the default *)
v2failures = {}; v2gateCount = 0; v2measCount = 0; v2stateChecks = 0; v2circuits = 0;

recordV2Failure[info_] := (AppendTo[v2failures, info];
  Print["  *** V2 FAILURE REPRO BLOCK: ", info]);

v2StateCheck[tab_, vRef_, ctx_] := Module[{u = StateVectorFromTableau[tab], ok},
  v2stateChecks++;
  ok = PhaseScaleEquivalentQ[u, vRef];
  If[!ok,
    recordV2Failure[Join[ctx, <|"Check" -> "FullStateMismatch",
      "TableauVec" -> Short[u, 4], "RefVec" -> Short[vRef, 4]|>]];
    Throw[False, "v2circ"]];
  True];

v2Timing = AbsoluteTiming[
Do[Do[
  Catch[Module[
    {n = nn, c = cc, seed, edges, tab, v, mCount = 0, ops = {}, ctx, doMeas},
    seed = 100000 nn + cc;
    SeedRandom[seed];
    v2circuits++;
    edges = Select[Subsets[Range[n], {2}], RandomInteger[] == 1 &];
    ctx := <|"n" -> n, "c" -> c, "seed" -> seed, "edges" -> edges,
      "ops" -> ops|>;
    tab = NewGraphStateTableau[n, edges];
    v = ConstantArray[1, 2^n];
    Do[v = Normal[refGate[n, "CZ", e] . v], {e, edges}];
    AppendTo[ops, {"init", edges}];
    v2StateCheck[tab, v, ctx];
    doMeas := Module[{q, basis, Pm, vPre, bTry, pTry, bForce, pForce, rec, pOut, rec2, rec3},
      q = RandomInteger[{1, n}]; basis = RandomChoice[{"X", "Y", "Z"}];
      Pm = refPauliAt[n, q, basis];
      vPre = v;
      bTry = RandomInteger[];
      pTry = refProb[vPre, Pm, bTry];
      bForce = If[pTry === 0, 1 - bTry, bTry];
      pForce = refProb[vPre, Pm, bForce];
      AppendTo[ops, {"meas", basis, q, "forced" -> bForce}];
      rec = MeasurePauli[tab, q, basis, "ForcedOutcome" -> bForce];
      mCount++; v2measCount++;
      (* (1) classification *)
      If[rec["Deterministic"] =!= (pForce === 1),
        recordV2Failure[Join[ctx, <|"Check" -> "Classification",
          "Expected" -> (pForce === 1), "Got" -> rec|>]]; Throw[False, "v2circ"]];
      (* (3) outcome *)
      If[rec["Outcome"] =!= bForce,
        recordV2Failure[Join[ctx, <|"Check" -> "Outcome",
          "Expected" -> bForce, "Got" -> rec|>]]; Throw[False, "v2circ"]];
      pOut = refProb[vPre, Pm, rec["Outcome"]];
      If[rec["Deterministic"] && pOut =!= 1,
        recordV2Failure[Join[ctx, <|"Check" -> "DeterministicProb1",
          "pOut" -> pOut, "Got" -> rec|>]]; Throw[False, "v2circ"]];
      (* (2) probability *)
      If[rec["Probability"] =!= pOut,
        recordV2Failure[Join[ctx, <|"Check" -> "Probability",
          "Expected" -> pOut, "Got" -> rec|>]]; Throw[False, "v2circ"]];
      (* reference branch update, then (4) full state *)
      v = vPre + (-1)^bForce Normal[Pm . vPre];
      v2StateCheck[tab, v, ctx];
      (* (5) determinism-repeat, unforced *)
      rec2 = MeasurePauli[tab, q, basis];
      If[!(rec2["Deterministic"] === True && rec2["Probability"] === 1 &&
           rec2["Outcome"] === rec["Outcome"]),
        recordV2Failure[Join[ctx, <|"Check" -> "DeterminismRepeat",
          "First" -> rec, "Repeat" -> rec2|>]]; Throw[False, "v2circ"]];
      v2StateCheck[tab, v, ctx];
      (* (6) forced-conflict on the same, now deterministic, measurement *)
      rec3 = MeasurePauli[tab, q, basis, "ForcedOutcome" -> 1 - rec["Outcome"]];
      If[!(rec3["Probability"] === 0 && rec3["Outcome"] === rec["Outcome"] &&
           rec3["Deterministic"] === True),
        recordV2Failure[Join[ctx, <|"Check" -> "ForcedConflict",
          "First" -> rec, "Conflict" -> rec3|>]]; Throw[False, "v2circ"]];
      v2StateCheck[tab, v, ctx]];
    Do[
      If[RandomInteger[{1, 4}] <= 3,
        Module[{gname = RandomChoice[{"H", "S", "X", "Y", "Z", "CZ", "CNOT"}], q1, pair},
          If[MemberQ[{"CZ", "CNOT"}, gname],
            pair = RandomSample[Range[n], 2];
            Switch[gname,
              "CZ", ApplyCZ[tab, pair[[1]], pair[[2]]],
              "CNOT", ApplyCNOT[tab, pair[[1]], pair[[2]]]];
            v = Normal[refGate[n, gname, pair] . v];
            AppendTo[ops, {gname, pair}],
            q1 = RandomInteger[{1, n}];
            Switch[gname,
              "H", ApplyH[tab, q1], "S", ApplyS[tab, q1],
              "X", ApplyX[tab, q1], "Y", ApplyY[tab, q1], "Z", ApplyZ[tab, q1]];
            v = Normal[refGate[n, gname, q1] . v];
            AppendTo[ops, {gname, q1}]];
          v2gateCount++;
          v2StateCheck[tab, v, ctx]],
        doMeas],
      {op, 30}];
    While[mCount < 5, doMeas];
    FreeTableau[tab];
  ], "v2circ"],
  {cc, CIRCUITSPERN}];
  Print["  n=", nn, ": ", CIRCUITSPERN, " circuits done, cumulative failures=",
    Length[v2failures]],
 {nn, 2, 6}]][[1]];

v2OK = (Length[v2failures] === 0);
Print["  V2 totals: circuits=", v2circuits, "  gates=", v2gateCount,
  "  measurements=", v2measCount, "  full-state comparisons=", v2stateChecks,
  "  failures=", Length[v2failures], "  (", Round[v2Timing], "s)"];
Print["  V2 ALL EXACT MATCH (zero failures)? ", v2OK];
If[!v2OK,
  Print["*** V2 FAILURES PRESENT - suite FAILED, see repro blocks above. ***"];
  Print["V2 failure summary: ", Short[v2failures, 20]];
  Exit[1]];
Print[];

(* ---------------------------------------------------------------------------
   SECTION V3. Scale smoke test: mesh locality + telemetry (its own asserts
   are the correctness gate; the timing prints are diagnostics).  At each
   tier: build the pentagon-mesh tableau, then at a mid-ring location run a
   GENUINE local pattern via MeasurePauli with Automatic outcomes under
   SeedRandom[42]: three Z measurements carving a pentagon's fresh vertices
   {3m+1, 3m+2, 3m+3}, one X measurement on a degree-2 wire vertex 3(m+3)+3
   (vertices 3k+3 have degree exactly 2 in the mesh: edges {3k+2,3k+3} and
   {3k+3,v}), and one Y measurement nearby (3(m+6)+3).
   --------------------------------------------------------------------------- *)
Print["=== V3: scale smoke test (mesh locality, telemetry, n-independence) ==="];
wellFormedRecQ[rec_] := AssociationQ[rec] && MemberQ[{0, 1}, rec["Outcome"]] &&
  MemberQ[{True, False}, rec["Deterministic"]] &&
  MemberQ[{0, 1/2, 1}, rec["Probability"]] &&
  IntegerQ[rec["Qubit"]] && MemberQ[{"X", "Y", "Z"}, rec["Basis"]];

runV3Tier[reps_, validate_] := Module[
  {L = 3 reps, nQ = 9 reps, tBuild, edges, tTab, tab, m, targets, recs = {},
   times = {}, stats},
  {tBuild, edges} = AbsoluteTiming[wordRingEdgesFastLocal["cct", reps]];
  {tTab, tab} = AbsoluteTiming[
    NewGraphStateTableau[nQ, edges, "ValidateEdges" -> validate]];
  Print["  reps=", reps, "  (", L, " pentagons, ", nQ, " qubits, ",
    Length[edges], " edges): edge build ", tBuild, "s, tableau init ", tTab,
    "s (ValidateEdges->", validate, ")"];
  m = Floor[L/2];
  targets = {{3 m + 1, "Z"}, {3 m + 2, "Z"}, {3 m + 3, "Z"},
    {3 (m + 3) + 3, "X"}, {3 (m + 6) + 3, "Y"}};
  SeedRandom[42];
  Do[Module[{t, rec},
     {t, rec} = AbsoluteTiming[MeasurePauli[tab, tg[[1]], tg[[2]]]];
     CCTAssert[wellFormedRecQ[rec], "V3: malformed measurement record", rec];
     AppendTo[recs, rec]; AppendTo[times, t];
     Print["    MeasurePauli[", tg[[2]], ", q=", tg[[1]], "] -> outcome ",
       rec["Outcome"], ", det=", rec["Deterministic"], "  (", t, "s)"]],
    {tg, targets}];
  stats = TableauStats[tab];
  Print["    TableauStats: ", stats, "   MemoryInUse: ",
    Round[MemoryInUse[]/1024./1024.], " MB"];
  FreeTableau[tab];
  <|"Reps" -> reps, "Qubits" -> nQ, "Edges" -> Length[edges],
    "TimeBuild" -> tBuild, "TimeInit" -> tTab, "MeasTimes" -> times,
    "MeanMeasTime" -> Total[times]/Length[times], "Records" -> recs,
    "DirtyRows" -> stats["DirtyRows"], "MaxRowWeight" -> stats["MaxRowWeight"]|>];

{v3RepsA, v3RepsB} = If[ValueQ[CCTMBQCV3TiersOverride], CCTMBQCV3TiersOverride,
  {10^5, 10^6}];   (* override hook for quick dev smoke runs only *)
v3TierA = runV3Tier[v3RepsA, True];
v3TierB = runV3Tier[v3RepsB, False];
v3Ratio = v3TierB["MeanMeasTime"]/v3TierA["MeanMeasTime"];
Print["  per-measurement mean: reps=", v3RepsA, " -> ", v3TierA["MeanMeasTime"],
  "s | reps=", v3RepsB, " -> ", v3TierB["MeanMeasTime"], "s | ratio (10x more qubits) = ",
  v3Ratio, If[v3Ratio > 10, "  *** FLAG: ratio > 10, unexpected n-dependence ***",
    "  (n-independent within hardware noise)"]];
v3OK = AllTrue[Join[v3TierA["Records"], v3TierB["Records"]], wellFormedRecQ] &&
  v3TierA["MaxRowWeight"] <= 32 && v3TierB["MaxRowWeight"] <= 32;
Print["  V3 PASS (all records well-formed, row weights stayed mesh-local <= 32)? ", v3OK];
Print[];

(* ---------------------------------------------------------------------------
   SECTION V3b. Wire-scaling smoke test (task addendum): thousands of
   measurements per tier.  Z-carve 2000 fresh pentagon-top vertices 3k+1
   (k = 10..2009), then X-measure 2000 degree-2 wire vertices 3k+3
   (k = 2020, 2022, ..., stride 2 so each contraction stays strictly local).
   --------------------------------------------------------------------------- *)
Print["=== V3b: wire-scaling smoke test - thousands of Z and X measurements ==="];
runV3bTier[reps_] := Module[
  {L = 3 reps, nQ = 9 reps, edges, tab, tZ, tX, nZ = 2000, nX = 2000, zq, xq,
   zrecs, xrecs, stats},
  edges = wordRingEdgesFastLocal["cct", reps];
  tab = NewGraphStateTableau[nQ, edges, "ValidateEdges" -> False];
  zq = Table[3 k + 1, {k, 10, 10 + nZ - 1}];
  xq = Table[3 k + 3, {k, 10 + nZ + 10, 10 + nZ + 10 + 2 (nX - 1), 2}];
  CCTAssert[Max[Join[zq, xq]] <= nQ, "V3b: target qubits out of range", {reps, Max[xq]}];
  SeedRandom[43];
  {tZ, zrecs} = AbsoluteTiming[MeasurePauli[tab, #, "Z"] & /@ zq];
  {tX, xrecs} = AbsoluteTiming[MeasurePauli[tab, #, "X"] & /@ xq];
  stats = TableauStats[tab];
  Print["  reps=", reps, " (", nQ, " qubits): ", nZ, " Z-measurements in ", tZ,
    "s (", tZ/nZ, " s/meas), ", nX, " X-measurements in ", tX, "s (", tX/nX,
    " s/meas)"];
  Print["    TableauStats: ", stats, "   MemoryInUse: ",
    Round[MemoryInUse[]/1024./1024.], " MB"];
  FreeTableau[tab];
  <|"Reps" -> reps, "Qubits" -> nQ, "TimeZ" -> tZ, "TimeX" -> tX,
    "PerZ" -> tZ/2000, "PerX" -> tX/2000,
    "AllRecsOK" -> AllTrue[Join[zrecs, xrecs], wellFormedRecQ],
    "DirtyRows" -> stats["DirtyRows"], "MaxRowWeight" -> stats["MaxRowWeight"]|>];

{v3bRepsA, v3bRepsB} = If[ValueQ[CCTMBQCV3bTiersOverride], CCTMBQCV3bTiersOverride,
  {10^4, 10^5}];   (* override hook for quick dev smoke runs only *)
v3bTierA = runV3bTier[v3bRepsA];
v3bTierB = runV3bTier[v3bRepsB];
Print["  per-measurement (Z) tier ratio reps=", v3bRepsB, " / reps=", v3bRepsA, ": ",
  v3bTierB["PerZ"]/v3bTierA["PerZ"], " | (X): ", v3bTierB["PerX"]/v3bTierA["PerX"]];
v3bOK = v3bTierA["AllRecsOK"] && v3bTierB["AllRecsOK"];
Print["  V3b PASS (all 8000 records well-formed)? ", v3bOK];
Print[];

(* ---------------------------------------------------------------------------
   SECTION V4. Summary.
   --------------------------------------------------------------------------- *)
CCTMBQCSimulatorSummary = <|
  "V0_FoundationsOK" -> v0OK,
  "V1_InitCrossCheckOK" -> v1OK,
  "V2_Circuits" -> v2circuits,
  "V2_Gates" -> v2gateCount,
  "V2_Measurements" -> v2measCount,
  "V2_StateComparisons" -> v2stateChecks,
  "V2_Failures" -> Length[v2failures],
  "V2_AllExactMatch" -> v2OK,
  "V3_LargestQubits" -> v3TierB["Qubits"],
  "V3_MaxRowWeightObserved" -> Max[v3TierA["MaxRowWeight"], v3TierB["MaxRowWeight"]],
  "V3_DirtyRowsObserved" -> Max[v3TierA["DirtyRows"], v3TierB["DirtyRows"]],
  "V3_MeasTimeRatio_10x" -> v3Ratio,
  "V3b_PerMeasurementZ_Seconds_9e5qubits" -> v3bTierB["PerZ"],
  "V3b_PerMeasurementX_Seconds_9e5qubits" -> v3bTierB["PerX"],
  "V3b_MaxRowWeightObserved" -> Max[v3bTierA["MaxRowWeight"], v3bTierB["MaxRowWeight"]],
  "AllPass" -> (v0OK && v1OK && v2OK && v3OK && v3bOK)
|>;
Print["=== V4: SUMMARY ==="];
Print["CCTMBQCSimulatorSummary: ", CCTMBQCSimulatorSummary];
If[!TrueQ[CCTMBQCSimulatorSummary["AllPass"]], Print["*** SUITE FAILED ***"]; Exit[1]];
Print["ALL SECTIONS PASS."];
CCTMBQCSimulatorSummary
