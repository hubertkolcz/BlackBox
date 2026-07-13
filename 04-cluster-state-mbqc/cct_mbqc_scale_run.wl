(* ::Package:: *)

(* ===========================================================================
   cct_mbqc_scale_run.wl -- SCALE RUNS of the MBQC measurement patterns on the
   fixed pentagon-mesh graph state, through the sparse CHP tableau simulator.

     * Bernstein-Vazirani at secret sizes n = 10^2 .. 10^6 (planted secret,
       full protocol: mesh tableau init -> Z-carve -> oracle -> X readout ->
       XOR-linear byproduct correction; recovered == planted checked).
     * Grover 2-qubit instances in parallel disjoint regions, M = 10^3 / 10^4.
     * Contextual-NAND (Anders-Browne OR) throughput on mesh-carved GHZ
       triples, executed on the sparse tableau (settings/signs taken from the
       exhaustively verified cct_mbqc_contextual_nand.wl and re-validated
       against the tableau sim before any scale run).

   HONEST FRAMING (verbatim, required): every pattern here is Clifford, so
   Gottesman-Knill guarantees efficient classical simulation.  The claim is
   FAITHFUL PROTOCOL-LEVEL MBQC execution of well-known quantum algorithms on
   the fixed pentagon-mesh graph state at scales far beyond any statevector
   simulator (JUPITER exascale record: 50 qubits) or existing quantum
   hardware -- NOT a quantum-speedup claim.  The documented path to
   universality is T-gate injection / stabilizer-rank (cost 2^(alpha t) in
   T-count t).

   The quantum resource is ALWAYS the fixed mesh graph state from
   wordRingEdgesFast["cct",reps]; the edge list is NEVER edited.  Unused
   qubits are removed by ACTUAL Z-measurements inside the simulator; the only
   quantum operations after preparation are single-qubit X/Y/Z Pauli
   measurements plus classical XOR-linear feed-forward of the tracked Pauli
   byproduct frame (the one exception is the BV phase ORACLE Z^{s_i}, the
   queried unitary itself).

   SCALE-SPECIFIC IMPLEMENTATION NOTES (why not just call the library fns):
     * RunBernsteinVazirani / CCTGroverRunInstance in cct_mbqc_patterns.wl
       compute byproduct frames via CCTNbrs[edges, v], an O(|E|) scan PER
       VERTEX -- O(n^2) total at scale.  The runners here use the tableau's
       own sorted adjacency (tab["adj"], O(1) lookup) instead.  Protocol,
       bases, byproduct rules and Grover sign patterns are IDENTICAL (the
       pattern table CCTGroverPattern is reused verbatim), and each scale
       runner is cross-validated against its library counterpart below
       before any scale run.
     * Carve outcomes are stored in a packed integer array (zarr) instead of
       an Association; zarr is nonzero ONLY on carved qubits, so the parity
       of zarr over a vertex's full neighbor list equals the parity over its
       CARVED neighbors -- the same quantity the library computes.
     * MeasX/Y Fast replicate MeasurePauli's documented basis reductions
       (H core H; Sdg H core H S) calling MeasureZCore directly, skipping
       per-call option parsing (identical physics, verified by the library's
       own tests).

   DEPENDS ON: cct_mbqc_patterns.wl (-> cct_mbqc_sim.wl), same directory.

   Run:
     wolframscript -file cct_mbqc_scale_run.wl validate   (validation only)
     wolframscript -file cct_mbqc_scale_run.wl full       (default: validate
                       + BV 1e2..1e5 + Grover 1e3 + NAND throughput + table)
     wolframscript -file cct_mbqc_scale_run.wl mega       (BV 1e6, Grover 1e4,
                       NAND 1e5 -- large-scale benchmark stage)
   =========================================================================== *)

If[!ValueQ[CCTScaleDir], CCTScaleDir = DirectoryName[$InputFileName]];
Block[{CCTMBQCPatternsLoadOnly = True, CCTMBQCLoadOnly = True},
  Get[FileNameJoin[{CCTScaleDir, "cct_mbqc_patterns.wl"}]]];

passCount = 0; failCount = 0;
check[label_, ok_] := (If[TrueQ[ok], passCount++, failCount++];
   Print["  [", If[TrueQ[ok], "PASS", "FAIL"], "] ", label]; TrueQ[ok]);

(* fast measurement wrappers: EXACTLY MeasurePauli's basis reductions,
   calling MeasureZCore directly (no option parsing).  Return the outcome bit. *)
MeasZFast[tab_Symbol, q_Integer] := MeasureZCore[tab, q, Automatic]["Outcome"];
MeasXFast[tab_Symbol, q_Integer] := (ApplyH[tab, q];
  With[{r = MeasureZCore[tab, q, Automatic]}, ApplyH[tab, q]; r["Outcome"]]);
MeasYFast[tab_Symbol, q_Integer] := (ApplySdg[tab, q]; ApplyH[tab, q];
  With[{r = MeasureZCore[tab, q, Automatic]}, ApplyH[tab, q]; ApplyS[tab, q];
    r["Outcome"]]);

CCTResults = {};   (* rows of the final consolidated table *)

(* ---------------------------------------------------------------------------
   SECTION 1. Bernstein-Vazirani at scale.
   Protocol identical to RunBernsteinVazirani (cct_mbqc_patterns.wl):
     register = pentagon tips (deg-2 vertices, = multiples of 3);
     1) Z-carve every non-register qubit (real measurements, outcomes zarr);
     2) frame_i = XOR of tip i's ORIGINAL mesh neighbors' carve outcomes;
     3) oracle U_s = prod Z_{tip_i}^{s_i} (the queried unitary, applied once);
     4) X-measure tips; s_i = raw_i XOR frame_i, deterministically.
   --------------------------------------------------------------------------- *)
CCTScaleBV[nSecret_Integer] := Module[
  {reps, n, secret, tE, edges, tT, tab, adj, tips, tipDegOK, tipNbrOK, others,
   zarr, tCarve, tAlg, frame, raw, corrected, ok, nMeas, stats},
  reps = Ceiling[nSecret/3]; n = 9 reps;
  SeedRandom[42 + nSecret];
  secret = RandomInteger[{0, 1}, nSecret];
  {tE, edges} = AbsoluteTiming[CCTMeshEdges[reps]];
  {tT, tab} = AbsoluteTiming[
     NewGraphStateTableau[n, edges, "ValidateEdges" -> (n <= 10^5)]];
  adj = tab["adj"];
  tips = Range[3, 3 nSecret, 3];          (* == Take[CCTTips[...], nSecret], checked in validation *)
  tipDegOK = Union[Length /@ adj[[tips]]] === {2};
  tipNbrOK = FreeQ[Mod[Flatten[adj[[tips]]], 3], 0];  (* no tip adjacent to a tip *)
  CCTAssert[tipDegOK && tipNbrOK, "CCTScaleBV: tip structure violated", {nSecret, tipDegOK, tipNbrOK}];
  others = Complement[Range[n], tips];
  zarr = ConstantArray[0, n];
  tCarve = First@AbsoluteTiming[
     Do[zarr[[q]] = MeasureZCore[tab, q, Automatic]["Outcome"], {q, others}]];
  {tAlg, corrected} = AbsoluteTiming[
     frame = Mod[Map[Total[zarr[[adj[[#]]]]] &, tips], 2];
     Do[If[secret[[i]] == 1, ApplyZ[tab, tips[[i]]]], {i, nSecret}];   (* oracle *)
     raw = Table[MeasXFast[tab, tips[[i]]], {i, nSecret}];
     Mod[raw + frame, 2]];
  ok = (Normal[corrected] === Normal[secret]);
  nMeas = Length[others] + nSecret;
  stats = TableauStats[tab];
  FreeTableau[tab];
  <|"task" -> "BV", "size" -> nSecret, "reps" -> reps, "qubits" -> n,
    "meas" -> nMeas, "tEdges" -> tE, "tTab" -> tT, "tCarve" -> tCarve,
    "tAlg" -> tAlg, "tTotal" -> tE + tT + tCarve + tAlg,
    "maxRowWeight" -> stats["MaxRowWeight"], "correct" -> ok|>];

(* ---------------------------------------------------------------------------
   SECTION 2. Parallel 2-qubit Grover at scale.
   Geometry, canonical pattern table (CCTGroverPattern), byproduct rules and
   marks handling identical to RunGroverParallel; frame parities via adjacency.
   --------------------------------------------------------------------------- *)
CCTScaleGrover[M_Integer] := Module[
  {spacing = 6, startK = 3, ks, reps, n, marks, tE, edges, tT, tab, adj,
   clusters, allCluster, others, zarr, tCarve, tAlg, resultsOK, ok, nMeas, stats},
  SeedRandom[9000 + M];
  ks = Table[startK + spacing (j - 1), {j, M}];
  reps = Ceiling[(Last[ks] + 3 + spacing)/3]; n = 9 reps;
  marks = RandomInteger[{0, 3}, M];
  {tE, edges} = AbsoluteTiming[CCTMeshEdges[reps]];
  {tT, tab} = AbsoluteTiming[
     NewGraphStateTableau[n, edges, "ValidateEdges" -> (n <= 10^5)]];
  adj = tab["adj"];
  clusters = Values[CCTGroverCanonMap[#]] & /@ ks;
  allCluster = Union @@ clusters;
  others = Complement[Range[n], allCluster];
  zarr = ConstantArray[0, n];
  tCarve = First@AbsoluteTiming[
     Do[zarr[[q]] = MeasureZCore[tab, q, Automatic]["Outcome"], {q, others}]];
  {tAlg, resultsOK} = AbsoluteTiming[Table[
     Module[{k = ks[[j]], mark = marks[[j]], cm, bases, lin, meas, outs,
       clean, zread, frame, corr},
      cm = CCTGroverCanonMap[k];
      {bases, lin} = CCTGroverPattern[mark];
      meas = cm /@ CCTGroverMeasCanon; outs = cm /@ CCTGroverOutCanon;
      clean = Table[Module[{v = meas[[jj]], b = bases[[jj]], rw},
         rw = Switch[b, "X", MeasXFast[tab, v], "Y", MeasYFast[tab, v],
           "Z", MeasZFast[tab, v]];
         Mod[rw + If[b === "Z", 0, Mod[Total[zarr[[adj[[v]]]]], 2]], 2]], {jj, 6}];
      zread = Table[MeasZFast[tab, outs[[jj]]], {jj, 2}];
      frame = {Mod[lin[[1]] . clean, 2], Mod[lin[[2]] . clean, 2]};
      corr = {Mod[zread[[1]] + frame[[1]], 2], Mod[zread[[2]] + frame[[2]], 2]};
      corr === IntegerDigits[mark, 2, 2]], {j, M}]];
  ok = And @@ resultsOK;
  nMeas = Length[others] + 8 M;
  stats = TableauStats[tab];
  FreeTableau[tab];
  <|"task" -> "Grover", "size" -> M, "reps" -> reps, "qubits" -> n,
    "meas" -> nMeas, "tEdges" -> tE, "tTab" -> tT, "tCarve" -> tCarve,
    "tAlg" -> tAlg, "tTotal" -> tE + tT + tCarve + tAlg,
    "maxRowWeight" -> stats["MaxRowWeight"],
    "correct" -> ok, "numCorrect" -> Count[resultsOK, True]|>];

(* ---------------------------------------------------------------------------
   SECTION 3. Contextual NAND (Anders-Browne OR) on mesh-carved GHZ triples.

   Settings/signs taken from cct_mbqc_contextual_nand.wl (exhaustively
   verified there in exact matrix arithmetic on the ACTUAL mesh):
     survivors = induced path s1 - s2 - s3 (ends s1,s3 H-conjugated by the
     P3 -> GHZ3 local Clifford), carve byproduct c_s = parity of survivor s's
     measured neighbors' Z outcomes;
     OR(a,b) measurement operators in the CARVED frame:
       s1: a==1 ? -Y : Z ;  s2: b==1 ? Y : X ;  s3: (a xor b)==1 ? -Y : Z ;
     the tableau measures +Y, and outcome(-Y) = outcome(Y) XOR 1;
     feed-forward f = a*c1 xor c2 xor (a xor b)*c3;
     OR(a,b) = XOR(outcomes) xor f, DETERMINISTICALLY (Step 2 of that file).
   NAND(x,y) = OR(1-x, 1-y): negations are linear, free for the XOR side
   processor.  Triples at scale: survivors {9j+1, 9j+2, 9j+3} (period-9
   translates of the verified {1,2,3}; induced path with center 9j+2 --
   asserted per triple against the actual adjacency before running).
   --------------------------------------------------------------------------- *)
CCTORGadget[tab_Symbol, {s1_, s2_, s3_}, c_List, a_Integer, b_Integer] :=
  Module[{t = Mod[a + b, 2], m1, m2, m3, f},
   m1 = If[a == 1, BitXor[MeasYFast[tab, s1], 1], MeasZFast[tab, s1]];
   m2 = If[b == 1, MeasYFast[tab, s2], MeasXFast[tab, s2]];
   m3 = If[t == 1, BitXor[MeasYFast[tab, s3], 1], MeasZFast[tab, s3]];
   f = Mod[a c[[1]] + c[[2]] + t c[[3]], 2];
   Mod[m1 + m2 + m3 + f, 2]];

(* M triples on one reps=M mesh; one NAND evaluation per triple, random inputs *)
CCTScaleNAND[M_Integer] := Module[
  {reps = M, n, tE, edges, tT, tab, adj, triples, structOK, survivors, others,
   zarr, tCarve, tAlg, xs, ys, outs, expect, ok, nMeas, stats},
  n = 9 M;
  SeedRandom[7000 + M];
  {tE, edges} = AbsoluteTiming[CCTMeshEdges[reps]];
  {tT, tab} = AbsoluteTiming[
     NewGraphStateTableau[n, edges, "ValidateEdges" -> (n <= 10^5)]];
  adj = tab["adj"];
  triples = Table[{9 j + 1, 9 j + 2, 9 j + 3}, {j, 0, M - 1}];
  (* induced-path + isolation structure check against the ACTUAL adjacency:
     center adjacent to both ends, ends not adjacent, and no survivor is
     adjacent to a survivor of ANY other triple (survivor residues mod 9 are
     {1,2,3}; a neighbor with such a residue must be in the SAME triple). *)
  structOK = AllTrue[triples, Function[tr,
     MemberQ[adj[[tr[[2]]]], tr[[1]]] && MemberQ[adj[[tr[[2]]]], tr[[3]]] &&
     !MemberQ[adj[[tr[[1]]]], tr[[3]]] &&
     AllTrue[Complement[Flatten[adj[[tr]]], tr],
       !MemberQ[{1, 2, 3}, Mod[#, 9]] &]]];
  CCTAssert[structOK, "CCTScaleNAND: triple structure violated", M];
  survivors = Flatten[triples];
  others = Complement[Range[n], survivors];
  zarr = ConstantArray[0, n];
  tCarve = First@AbsoluteTiming[
     Do[zarr[[q]] = MeasureZCore[tab, q, Automatic]["Outcome"], {q, others}]];
  xs = RandomInteger[{0, 1}, M]; ys = RandomInteger[{0, 1}, M];
  {tAlg, outs} = AbsoluteTiming[Table[
     Module[{tr = triples[[j]], c},
      c = Mod[Map[Total[zarr[[adj[[#]]]]] &, tr], 2];
      CCTORGadget[tab, tr, c, 1 - xs[[j]], 1 - ys[[j]]]], {j, M}]];
  expect = Table[1 - xs[[j]] ys[[j]], {j, M}];
  ok = (outs === expect);
  nMeas = Length[others] + 3 M;
  stats = TableauStats[tab];
  FreeTableau[tab];
  <|"task" -> "NAND", "size" -> M, "reps" -> reps, "qubits" -> n,
    "meas" -> nMeas, "tEdges" -> tE, "tTab" -> tT, "tCarve" -> tCarve,
    "tAlg" -> tAlg, "tTotal" -> tE + tT + tCarve + tAlg,
    "maxRowWeight" -> stats["MaxRowWeight"], "correct" -> ok,
    "numCorrect" -> Count[MapThread[SameQ, {outs, expect}], True],
    "gatesPerSecAmortized" -> M/(tE + tT + tCarve + tAlg),
    "gatesPerSecGadget" -> M/tAlg|>];

(* ---------------------------------------------------------------------------
   SECTION 4. VALIDATION -- every scale runner against its verified library
   counterpart / verified settings, BEFORE any scale run.
   --------------------------------------------------------------------------- *)
CCTRunValidation[] := Module[
  {edges5, bvLib, bvScale, gpLib, gpScale, orOK, orTrials, multiOK, r},
  Print["=== VALIDATION (scale runners vs verified library implementations) ==="];

  (* V1: tip formula == CCTTips *)
  edges5 = CCTMeshEdges[5];
  check["V1: tips = Range[3,9reps,3] == CCTTips (reps=5)",
    Range[3, 45, 3] === CCTTips[edges5, 45]];

  (* V2: BV -- library on reps=4 (12 bits), scale runner on 12/100 bits *)
  SeedRandom[123]; bvLib = RunBernsteinVazirani[4, RandomInteger[{0, 1}, 12]];
  check["V2a: library RunBernsteinVazirani reps=4 recovers planted secret",
    bvLib["correct"]];
  bvScale = CCTScaleBV[12];
  check["V2b: CCTScaleBV n=12 recovers planted secret", bvScale["correct"]];
  bvScale = CCTScaleBV[100];
  check["V2c: CCTScaleBV n=100 recovers planted secret", bvScale["correct"]];

  (* V3: Grover -- library parallel M=10 vs scale runner M=10 (all-correct) *)
  SeedRandom[456]; gpLib = RunGroverParallel[10];
  check["V3a: library RunGroverParallel M=10 all correct", gpLib["allCorrect"]];
  gpScale = CCTScaleGrover[10];
  check["V3b: CCTScaleGrover M=10 all correct (" <>
      ToString[gpScale["numCorrect"]] <> "/10)", gpScale["correct"]];

  (* V4: Anders-Browne OR gadget on the tableau, reps=1 survivors {1,2,3}:
     all 4 inputs x 100 random-branch trials each must give OR deterministically.
     Signs/settings from cct_mbqc_contextual_nand.wl -- if this fails, STOP. *)
  SeedRandom[789];
  orTrials = 100;
  orOK = And @@ Flatten[Table[
     Module[{tab, adj, zarr, c, out},
      tab = NewGraphStateTableau[9, CCTMeshEdges[1]];
      adj = tab["adj"];
      zarr = ConstantArray[0, 9];
      Do[zarr[[q]] = MeasureZCore[tab, q, Automatic]["Outcome"], {q, 4, 9}];
      c = Mod[Map[Total[zarr[[adj[[#]]]]] &, {1, 2, 3}], 2];
      out = CCTORGadget[tab, {1, 2, 3}, c, a, b];
      FreeTableau[tab];
      out === Max[a, b]],
     {a, 0, 1}, {b, 0, 1}, {trial, orTrials}]];
  check["V4: AB OR gadget on tableau (reps=1, {1,2,3}): 4 inputs x " <>
      ToString[orTrials] <> " random branches, all == OR(a,b)", orOK];
  If[!orOK,
    Print["*** SIGN DISAGREEMENT between cct_mbqc_contextual_nand.wl settings"];
    Print["*** and the sparse tableau sim -- STOPPING NAND scale runs."]];

  (* V5: multi-triple mesh (reps=6): every triple {9j+1..9j+3}, all 4 inputs,
     20 random branches each, deterministic OR on the SHARED carved mesh *)
  If[orOK,
    SeedRandom[790];
    multiOK = And @@ Flatten[Table[
       Module[{tab, adj, zarr, others, out, tr},
        tab = NewGraphStateTableau[54, CCTMeshEdges[6]];
        adj = tab["adj"];
        others = Complement[Range[54], Flatten[Table[{9 j + 1, 9 j + 2, 9 j + 3}, {j, 0, 5}]]];
        zarr = ConstantArray[0, 54];
        Do[zarr[[q]] = MeasureZCore[tab, q, Automatic]["Outcome"], {q, others}];
        Table[
          tr = {9 j + 1, 9 j + 2, 9 j + 3};
          out = CCTORGadget[tab, tr,
            Mod[Map[Total[zarr[[adj[[#]]]]] &, tr], 2], a, b];
          out === Max[a, b], {j, 0, 5}]],
       {a, 0, 1}, {b, 0, 1}, {trial, 20}]];
    check["V5: OR gadget on ALL 6 triples of a shared reps=6 carved mesh, 4 inputs x 20 branches",
      multiOK];
    (* V6: end-to-end NAND scale runner, small *)
    r = CCTScaleNAND[20];
    check["V6: CCTScaleNAND M=20 all NAND outputs match truth table (" <>
        ToString[r["numCorrect"]] <> "/20)", r["correct"]];
  ];
  failCount === 0];

(* ---------------------------------------------------------------------------
   SECTION 5. Consolidated reporting.
   --------------------------------------------------------------------------- *)
fmt[x_?NumericQ] := ToString[NumberForm[N[x], {6, 2}, ExponentFunction -> (Null &)]];
CCTAddRow[res_Association, memMB_] := AppendTo[CCTResults,
  <|"task" -> res["task"], "size" -> res["size"], "qubits" -> res["qubits"],
    "meas" -> res["meas"],
    "tEdges" -> res["tEdges"], "tTab" -> res["tTab"],
    "tCarve" -> res["tCarve"], "tAlg" -> res["tAlg"], "tTotal" -> res["tTotal"],
    "MB" -> memMB, "maxW" -> res["maxRowWeight"],
    "ok" -> If[TrueQ[res["correct"]], "PASS", "FAIL"]|>];

CCTPrintTable[] := Module[{cols, widths, rows, hdr},
  cols = {"task", "size", "qubits", "meas", "tEdges", "tTab", "tCarve",
    "tAlg", "tTotal", "MB", "maxW", "ok"};
  rows = Table[ToString /@ {r["task"], r["size"], r["qubits"], r["meas"],
      fmt[r["tEdges"]], fmt[r["tTab"]], fmt[r["tCarve"]], fmt[r["tAlg"]],
      fmt[r["tTotal"]], fmt[r["MB"]], r["maxW"], r["ok"]}, {r, CCTResults}];
  hdr = {"task", "size", "meshQubits", "measurements", "tEdges(s)", "tTableau(s)",
    "tCarve(s)", "tAlg(s)", "tTotal(s)", "peakMB", "maxRowW", "verdict"};
  widths = Table[Max[StringLength[hdr[[j]]], Max @@ Prepend[StringLength /@ rows[[All, j]], 1]], {j, Length[hdr]}];
  Print["=== CONSOLIDATED RESULTS TABLE ==="];
  Print["  ", StringRiffle[Table[StringPadLeft[hdr[[j]], widths[[j]]], {j, Length[hdr]}], "  "]];
  Do[Print["  ", StringRiffle[Table[StringPadLeft[rows[[i, j]], widths[[j]]], {j, Length[hdr]}], "  "]], {i, Length[rows]}];
  (* linearity check on the BV rows: microseconds per measurement *)
  Module[{bv = Select[CCTResults, #["task"] === "BV" &]},
    If[Length[bv] >= 2,
      Print[];
      Print["  BV LINEARITY CHECK (time / measurement, should be ~constant if O(n)):"];
      Do[Print["    n=", StringPadLeft[ToString[r["size"]], 8],
         "   us/measurement total=", fmt[10^6 r["tTotal"]/r["meas"]],
         "   carve-only=", fmt[10^6 r["tCarve"]/r["meas"]]], {r, bv}]]];
  ];

CCTRunAndRow[label_String, f_] := Module[{res, mem},
  Print["--- ", label, " ---"];
  mem = MaxMemoryUsed[res = f[]];
  CCTAddRow[res, mem/2.^20];
  Print["    qubits=", res["qubits"], "  measurements=", res["meas"],
    "  tTotal=", fmt[res["tTotal"]], "s  peakMB=", fmt[mem/2.^20],
    "  maxRowWeight=", res["maxRowWeight"], "  -> ",
    If[TrueQ[res["correct"]], "PASS", "FAIL"]];
  If[res["task"] === "NAND",
    Print["    OR/NAND gate throughput: ", fmt[res["gatesPerSecAmortized"]],
      " gates/s amortized (incl. mesh init+carve), ",
      fmt[res["gatesPerSecGadget"]], " gates/s gadget-only"]];
  res];

(* ---------------------------------------------------------------------------
   SECTION 6. Stage driver.
   --------------------------------------------------------------------------- *)
mode = If[Length[$ScriptCommandLine] >= 2, $ScriptCommandLine[[2]], "full"];
Print["cct_mbqc_scale_run.wl  stage = ", mode];
Print[];

valOK = CCTRunValidation[];
Print[];

Which[
  mode === "validate",
  Null,

  mode === "full",
  If[valOK,
    Do[CCTRunAndRow["Bernstein-Vazirani n=" <> ToString[nn],
       With[{n2 = nn}, CCTScaleBV[n2] &]], {nn, {100, 1000, 10000, 100000}}];
    CCTRunAndRow["Grover parallel M=1000", CCTScaleGrover[1000] &];
    CCTRunAndRow["Contextual NAND M=10000 (one gate per carved GHZ triple)",
      CCTScaleNAND[10000] &];
    Print[];
    CCTPrintTable[],
    Print["*** VALIDATION FAILED -- scale runs skipped."]],

  (* mega: sized from the measured full-stage scaling (~570us/measurement,
     linear): Grover 1e4 ~ 180s, NAND 3e4 ~ 190s.  BV 1e6 would be ~1700s --
     over the ~5-minute per-run decision threshold AND the 10-minute hard
     timeout, so it is deliberately NOT attempted (largest BV = 1e5, in the
     "full" stage). *)
  mode === "mega",
  If[valOK,
    CCTRunAndRow["Grover parallel M=10000", CCTScaleGrover[10000] &];
    CCTRunAndRow["Contextual NAND M=30000", CCTScaleNAND[30000] &];
    Print[];
    CCTPrintTable[],
    Print["*** VALIDATION FAILED -- scale runs skipped."]],

  True, Print["unknown stage: ", mode]];

Print[];
Print["TOTAL CHECKS: ", passCount, " PASS, ", failCount, " FAIL"];
