(* ::Package:: *)

(* ===========================================================================
   cct_mbqc_master.wl -- MASTER RUNNER for the pentagon-mesh MBQC suite.

   Single wolframscript-runnable entry point that loads the simulator +
   pattern libraries and executes a representative MEDIUM-SIZE validation of
   every deliverable, printing a consolidated scoreboard:

     M0  simulator micro-foundations (exact gate/measurement algebra checks);
     M1  gate-teleportation wire (Gadget 1), all 6 Bloch inputs, random shots;
     M2  Bernstein-Vazirani with a planted 1000-bit secret (Gadget 2);
     M3  100 parallel disjoint 2-qubit Grover instances on one mesh (Gadget 3);
     M4  contextual (Anders-Browne) OR/NAND gadget truth table + an 8-bit
         ripple-carry adder in which EVERY nonlinear gate consumes one fresh
         mesh-carved GHZ triple, all on the sparse tableau.

   HONEST FRAMING (verbatim, required): every pattern here is Clifford, so
   Gottesman-Knill guarantees efficient classical simulation.  The claim is
   FAITHFUL PROTOCOL-LEVEL MBQC execution of well-known quantum algorithms on
   the fixed pentagon-mesh graph state at scales far beyond any statevector
   simulator (JUPITER exascale record: 50 qubits) or existing quantum
   hardware -- NOT a quantum-speedup claim.  The documented path to
   universality is T-gate injection / stabilizer-rank (cost 2^(alpha t) in
   T-count t).

   The quantum resource is ALWAYS the fixed mesh graph state built from
   wordRingEdgesFast["cct",reps]; the edge list is NEVER edited.  Unused
   qubits are removed by ACTUAL Z-measurements inside the simulator; the only
   quantum operations after preparation are single-qubit X/Y/Z Pauli
   measurements plus classical XOR-linear feed-forward of the tracked Pauli
   byproduct frame (the one exception is the BV phase ORACLE Z^{s_i}, the
   queried unitary itself).

   KNOWN LIMITATIONS carried over from the libraries (documented there):
     * TeleportWire post-selects the input-injection outcome (Gadget 1 only;
       see cct_mbqc_patterns.wl header) -- BV/Grover/NAND force no outcomes.
     * The Grover cluster pattern is calibrated to the k == 0 (mod 3)
       pentagon context of the period-3 "cct" word.

   CLOUD-DELEGABLE STRUCTURE (no cloud calls HERE, ever, by design): the Get
   chain is fully relative -- this file loads cct_mbqc_patterns.wl (which
   loads cct_mbqc_sim.wl) from ITS OWN directory via $InputFileName, with no
   absolute paths anywhere.  To delegate later, ship the three files together
   (or inline the two libraries above the marker below) and run the single
   file; nothing else is required.  This script performs NO CloudEvaluate /
   CloudDeploy / RemoteBatchSubmit and never will.

   Run:  wolframscript -file cct_mbqc_master.wl        (~1-2 minutes)
   Full suites: cct_mbqc_sim_tests.wl, cct_mbqc_patterns_tests.wl,
     cct_mbqc_contextual_nand.wl, cct_mbqc_scale_run.wl (same directory).
   =========================================================================== *)

(* --- load chain (relative; inline libraries below this marker for cloud) --- *)
If[!ValueQ[CCTMasterDir], CCTMasterDir = DirectoryName[$InputFileName]];
Block[{CCTMBQCPatternsLoadOnly = True, CCTMBQCLoadOnly = True},
  Get[FileNameJoin[{CCTMasterDir, "cct_mbqc_patterns.wl"}]]];

passCount = 0; failCount = 0; scoreRows = {};
check[label_, ok_] := (If[TrueQ[ok], passCount++, failCount++];
   Print["  [", If[TrueQ[ok], "PASS", "FAIL"], "] ", label]; TrueQ[ok]);
addRow[task_, size_, qubits_, meas_, t_, ok_] := AppendTo[scoreRows,
   {task, ToString[size], ToString[qubits], ToString[meas],
    ToString[NumberForm[N[t], {6, 2}, ExponentFunction -> (Null &)]],
    If[TrueQ[ok], "PASS", "FAIL"]}];
fmtN[x_] := ToString[NumberForm[N[x], {6, 2}, ExponentFunction -> (Null &)]];

Print["############################################################"];
Print["cct_mbqc_master.wl -- consolidated medium-size validation"];
Print["############################################################"];
Print[];

(* ---------------------------------------------------------------------------
   M0. Simulator micro-foundations (exact algebra vs dense conjugation).
   --------------------------------------------------------------------------- *)
Print["=== M0: simulator micro-foundations ==="];
Module[{t, v0},
  {t, v0} = AbsoluteTiming[CCTMBQCRunV0Foundations[]];
  check["V0 foundations (gate/measurement algebra, 16+16 dense cross-checks)",
    TrueQ[v0["AllOK"]]];
  addRow["foundations", "-", "-", "-", t, TrueQ[v0["AllOK"]]]];
Print[];

(* ---------------------------------------------------------------------------
   M1. Gate-teleportation wire: all 6 Bloch inputs, 4 random shots each on
   the reps=1 mesh (9 qubits), path {3,2,1} (prep=3, one teleport step, out=1).
   Faithful iff the output is a signed Pauli image of H|psi> (frame tracked).
   --------------------------------------------------------------------------- *)
Print["=== M1: gate-teleportation wire (Gadget 1) ==="];
Module[{t, ok},
  SeedRandom[20260713];
  {t, ok} = AbsoluteTiming[And @@ Flatten[Table[
     Module[{w = TeleportWire[1, {3, 2, 1}, st]},
       StringQ[w["byproductFrame"]] && w["byproductFrame"] =!= "UNFAITHFUL"],
     {st, {"0", "1", "+", "-", "+i", "-i"}}, {shot, 4}]]];
  check["wire: 6 Bloch inputs x 4 random shots, output == frame . H|psi> every branch", ok];
  addRow["wire", "6x4", 9, 24*8, t, ok]];
Print[];

(* ---------------------------------------------------------------------------
   M2. Bernstein-Vazirani, planted 1000-bit secret (reps=334, 3006 qubits;
   every mesh qubit measured; recovered === planted checked exactly).
   --------------------------------------------------------------------------- *)
Print["=== M2: Bernstein-Vazirani n=1000 (Gadget 2) ==="];
Module[{nBits = 1000, reps, secret, t, r, mem},
  reps = Ceiling[nBits/3];
  SeedRandom[42 + nBits];
  secret = RandomInteger[{0, 1}, nBits];
  mem = MaxMemoryUsed[{t, r} = AbsoluteTiming[RunBernsteinVazirani[reps, secret]]];
  Print["  reps=", reps, "  meshQubits=", r["n"], "  secretBits=", nBits,
    "  time=", fmtN[t], "s  peakMB=", fmtN[mem/2.^20]];
  check["BV n=1000: recovered === planted secret (single oracle query, prob-1 readout)",
    r["correct"]];
  addRow["BV", nBits, r["n"], r["n"], t, r["correct"]]];
Print[];

(* ---------------------------------------------------------------------------
   M3. 100 parallel disjoint 2-qubit Grover instances on ONE mesh, random
   marked items, single measurement round; region isolation verified by
   every instance returning its own mark deterministically.
   --------------------------------------------------------------------------- *)
Print["=== M3: Grover parallel M=100 (Gadget 3) ==="];
Module[{t, g, mem},
  SeedRandom[456];
  mem = MaxMemoryUsed[{t, g} = AbsoluteTiming[RunGroverParallel[100]]];
  Print["  M=100  reps=", g["reps"], "  meshQubits=", g["n"], "  time=",
    fmtN[t], "s  peakMB=", fmtN[mem/2.^20], "  correct=", g["numCorrect"], "/100"];
  check["Grover: 100 disjoint instances, ALL marks recovered (region isolation)",
    g["allCorrect"]];
  addRow["Grover", 100, g["n"], g["n"], t, g["allCorrect"]]];
Print[];

(* ---------------------------------------------------------------------------
   M4. Contextual (Anders-Browne) OR/NAND + 8-bit ripple-carry adder on the
   sparse tableau.  Settings/signs from cct_mbqc_contextual_nand.wl (proved
   there exhaustively in exact arithmetic on the actual mesh) and re-validated
   against the tableau in cct_mbqc_scale_run.wl V4-V6:
     survivors {9j+1, 9j+2, 9j+3} carve to a GHZ triple (P3 up to local H's);
     carve byproduct c_s = parity of survivor s's measured neighbors;
     OR(a,b) carved-frame settings  s1: a?-Y:Z, s2: b?Y:X, s3: (a xor b)?-Y:Z
     (outcome(-Y) = outcome(Y) XOR 1); feed-forward
     f = a*c1 xor c2 xor (a xor b)*c3;  OR(a,b) = XOR(outcomes) xor f.
   NAND(x,y) = OR(1-x,1-y) -- negations are linear (free for the XOR-only
   side-processor).  Per full-adder bit: sum is linear; carry costs 3 NANDs,
   so one 8-bit addition consumes exactly 24 fresh carved GHZ triples.
   --------------------------------------------------------------------------- *)
Print["=== M4: contextual NAND -> 8-bit ripple-carry adder on the tableau ==="];

CCTMasterORGadget[tab_Symbol, {s1_, s2_, s3_}, c_List, a_Integer, b_Integer] :=
  Module[{t = Mod[a + b, 2], m1, m2, m3, f},
   m1 = If[a == 1, BitXor[MeasurePauli[tab, s1, "Y"]["Outcome"], 1],
     MeasurePauli[tab, s1, "Z"]["Outcome"]];
   m2 = If[b == 1, MeasurePauli[tab, s2, "Y"]["Outcome"],
     MeasurePauli[tab, s2, "X"]["Outcome"]];
   m3 = If[t == 1, BitXor[MeasurePauli[tab, s3, "Y"]["Outcome"], 1],
     MeasurePauli[tab, s3, "Z"]["Outcome"]];
   f = Mod[a c[[1]] + c[[2]] + t c[[3]], 2];
   Mod[m1 + m2 + m3 + f, 2]];

(* M4a: OR truth table on fresh reps=1 carves, 4 inputs x 25 random branches *)
Module[{t, ok},
  SeedRandom[789];
  {t, ok} = AbsoluteTiming[And @@ Flatten[Table[
     Module[{tab, adj, zarr, c, out},
       tab = NewGraphStateTableau[9, CCTMeshEdges[1]];
       adj = tab["adj"];
       zarr = ConstantArray[0, 9];
       Do[zarr[[q]] = MeasurePauli[tab, q, "Z"]["Outcome"], {q, 4, 9}];
       c = Mod[Map[Total[zarr[[adj[[#]]]]] &, {1, 2, 3}], 2];
       out = CCTMasterORGadget[tab, {1, 2, 3}, c, a, b];
       FreeTableau[tab];
       out === Max[a, b]],
     {a, 0, 1}, {b, 0, 1}, {trial, 25}]]];
  check["OR gadget truth table: 4 inputs x 25 random carve/measurement branches, all == OR(a,b)", ok];
  addRow["OR-gadget", "4x25", 9, 100*9, t, ok]];

(* M4b: 8-bit adder -- 5 random additions, 24 fresh triples each, on ONE
   reps=120 mesh (1080 qubits, 120 triples), structure-checked per triple. *)
Module[{nAdd = 5, reps, n, edges, tab, adj, triples, structOK, survivors,
   others, zarr, cAll, nextTriple = 0, nTriples = 0, nandMismatch = 0,
   nandGate, fullAdder, add8, t, sumsOK, mem, tCarve},
  reps = 24 nAdd; n = 9 reps;
  SeedRandom[20260713];
  edges = CCTMeshEdges[reps];
  tab = NewGraphStateTableau[n, edges];
  adj = tab["adj"];
  triples = Table[{9 j + 1, 9 j + 2, 9 j + 3}, {j, 0, reps - 1}];
  (* induced-path + cross-triple isolation check against the ACTUAL adjacency *)
  structOK = AllTrue[triples, Function[tr,
     MemberQ[adj[[tr[[2]]]], tr[[1]]] && MemberQ[adj[[tr[[2]]]], tr[[3]]] &&
     !MemberQ[adj[[tr[[1]]]], tr[[3]]] &&
     AllTrue[Complement[Flatten[adj[[tr]]], tr],
       !MemberQ[{1, 2, 3}, Mod[#, 9]] &]]];
  check["adder mesh reps=" <> ToString[reps] <>
    ": all " <> ToString[reps] <> " GHZ triples are induced paths, cross-isolated", structOK];
  survivors = Flatten[triples];
  others = Complement[Range[n], survivors];
  zarr = ConstantArray[0, n];
  tCarve = First@AbsoluteTiming[
     Do[zarr[[q]] = MeasurePauli[tab, q, "Z"]["Outcome"], {q, others}]];
  cAll = Table[Mod[Map[Total[zarr[[adj[[#]]]]] &, tr], 2], {tr, triples}];
  nandGate[x_, y_] := Module[{tr, out},
    nextTriple++; nTriples++;
    tr = triples[[nextTriple]];
    out = CCTMasterORGadget[tab, tr, cAll[[nextTriple]], 1 - x, 1 - y];
    If[out =!= 1 - x*y, nandMismatch++];
    out];
  fullAdder[x_, y_, cin_] := Module[{p = BitXor[x, y], sm, t1, t2},
    sm = BitXor[p, cin];                       (* linear, free *)
    t1 = nandGate[x, y]; t2 = nandGate[p, cin];
    {sm, nandGate[t1, t2]}];
  add8[a_, b_] := Module[{ab = Reverse[IntegerDigits[a, 2, 8]],
     bb = Reverse[IntegerDigits[b, 2, 8]], cin = 0, sb = ConstantArray[0, 8], sm},
    Do[{sm, cin} = fullAdder[ab[[i]], bb[[i]], cin]; sb[[i]] = sm, {i, 8}];
    Total[sb*2^Range[0, 7]] + cin*2^8];
  mem = MaxMemoryUsed[{t, sumsOK} = AbsoluteTiming[Table[
     Module[{a = RandomInteger[{0, 255}], b = RandomInteger[{0, 255}], got},
       got = add8[a, b];
       Print["    ", a, " + ", b, " = ", got, "  (expected ", a + b, ")  ",
         If[got === a + b, "ok", "WRONG"]];
       got === a + b], {nAdd}]]];
  FreeTableau[tab];
  Print["  meshQubits=", n, "  carve=", Length[others], " Z-measurements (",
    fmtN[tCarve], "s)  triples consumed=", nTriples,
    "  NAND truth-table matches=", nTriples - nandMismatch, "/", nTriples];
  check["all " <> ToString[nAdd] <> " random 8-bit sums exact (== a+b)", And @@ sumsOK];
  check["exactly 24 fresh mesh-carved GHZ triples per addition", nTriples === 24 nAdd];
  check["zero NAND truth-table mismatches", nandMismatch === 0];
  addRow["adder8", nAdd, n, Length[others] + 3 nTriples, t + tCarve,
    (And @@ sumsOK) && nTriples === 24 nAdd && nandMismatch === 0]];
Print[];

(* ---------------------------------------------------------------------------
   Consolidated scoreboard.
   --------------------------------------------------------------------------- *)
Print["############################################################"];
Print["=== CONSOLIDATED SCOREBOARD ==="];
Module[{hdr = {"task", "size", "meshQubits", "measurements", "time(s)", "verdict"}, widths},
  widths = Table[Max[StringLength[hdr[[j]]],
     Max @@ Prepend[StringLength /@ scoreRows[[All, j]], 1]], {j, Length[hdr]}];
  Print["  ", StringRiffle[Table[StringPadLeft[hdr[[j]], widths[[j]]], {j, Length[hdr]}], "  "]];
  Do[Print["  ", StringRiffle[Table[StringPadLeft[r[[j]], widths[[j]]], {j, Length[hdr]}], "  "]],
    {r, scoreRows}]];
Print[];
Print["TOTAL CHECKS: ", passCount, " PASS, ", failCount, " FAIL"];
Print["OVERALL: ", If[failCount === 0, "ALL TESTS PASSED",
   "SOME TESTS FAILED -- see FAIL lines above"]];
Print["############################################################"];
