(* ::Package:: *)

(* ===========================================================================
   cct_mbqc_hawking_evaporation_tests.wl -- FULL validation suite / test runner
   for cct_mbqc_hawking_evaporation.wl.  Every test prints [PASS]/[FAIL] and a
   consolidated scoreboard is printed at the end.

   Structure:
     T1  STABILIZER ENTROPY -- 120 random stabilizer states x random subsets,
         GF(2) formula === exact von Neumann from the statevector, zero
         tolerance; independent graph-state cut-rank cross-check; Bell/GHZ
         anchors.
     T2  PAGE CURVE -- direct sequential model (rise/turnover/return); mesh-
         cluster model; mesh-carved Bell pairs (S=1); ensemble-averaged
         Renyi-2 at n=8,10,12 (>=100 shots) vs the Lubkin/Page closed form;
         single-realization SCALE demo at n=50,100,200 (timings reported).
     T3  HAYDEN-PRESKILL -- maximal Clifford scrambler (all single-qubit Paulis
         -> weight >= 3); EPR-projection success probability == 1/d_A^2; decode
         fidelity == 1 (maximal) both EPR and deterministic; identity control
         -> basis-averaged teleport fidelity 1/2; Pauli-basis teleportation of
         all 6 eigenstates recovered; depolarizing noise sweep (>=500 shots).

   Uses ONLY the exact-arithmetic APIs (integers / rationals) for PASS/FAIL;
   floats appear only in timings and the sampled-vs-closed-form Renyi-2
   comparison (compared within an explicit sampling tolerance).

   Run:  wolframscript -file cct_mbqc_hawking_evaporation_tests.wl
   (Includes the n=200 scale point -- expect ~8-9 minutes.)
   =========================================================================== *)

If[!ValueQ[CCTTestDir], CCTTestDir = DirectoryName[$InputFileName]];
Block[{CCTHawkingLoadOnly = True},
  Get[FileNameJoin[{CCTTestDir, "cct_mbqc_hawking_evaporation.wl"}]]];

passCount = 0; failCount = 0; scoreRows = {};
check[label_, ok_] := (If[TrueQ[ok], passCount++, failCount++];
   Print["  [", If[TrueQ[ok], "PASS", "FAIL"], "] ", label]; TrueQ[ok]);
fmt[x_] := ToString[NumberForm[N[x], {7, 3}, ExponentFunction -> (Null &)]];
addRow[t_, d_, tm_, ok_] := AppendTo[scoreRows,
   {t, d, ToString[NumberForm[N[tm], {7, 2}, ExponentFunction -> (Null &)]],
    If[TrueQ[ok], "PASS", "FAIL"]}];

Print["############################################################"];
Print["cct_mbqc_hawking_evaporation_tests.wl -- full validation"];
Print["############################################################"];

(* ---------------------------------------------------------------------------
   T1.  STABILIZER SUBSYSTEM ENTROPY.
   --------------------------------------------------------------------------- *)
Print["\n=== T1: exact stabilizer subsystem entropy ==="];

Module[{t, ok},
  SeedRandom[2026];
  {t, ok} = AbsoluteTiming[And @@ Table[
     Module[{n = RandomInteger[{2, 8}], tab, A, sG, rep},
       tab = NewGraphStateTableau[n, {}];
       CCTScramble[tab, Range[n], 5];
       A = Sort[RandomSample[Range[n], RandomInteger[{0, n}]]];
       sG = CCTStabEntropy[tab, A];
       rep = CCTStateEntropyReport[tab, A];
       FreeTableau[tab];
       (sG === rep["S"]) && TrueQ[rep["Flat"]]], {120}]];
  check["120 random stabilizer states x random subsets: GF(2) S(A) === von Neumann, flat spectrum, zero tolerance", ok];
  addRow["T1 entropy-vs-statevec", "120 cases, n<=8", t, ok]];

Module[{t, ok},
  (* independent formula: for a GRAPH state, S(A) = GF(2) cut-rank of the
     A x B biadjacency submatrix (Hein et al.).  Cross-check vs CCTStabEntropy
     on random graph states. *)
  SeedRandom[55];
  {t, ok} = AbsoluteTiming[And @@ Table[
     Module[{n = RandomInteger[{4, 9}], edges, adj, tab, A, B, sG, sCut},
       edges = Union[Sort /@ Select[Subsets[Range[n], {2}],
          RandomReal[] < 0.4 &]];
       adj = SparseArray[Join[edges, Reverse[edges, 2]] ->
          ConstantArray[1, 2 Length[edges]], {n, n}];
       tab = NewGraphStateTableau[n, edges];
       A = Sort[RandomSample[Range[n], RandomInteger[{1, n - 1}]]];
       B = Complement[Range[n], A];
       sG = CCTStabEntropy[tab, A];
       sCut = MatrixRank[adj[[A, B]], Modulus -> 2];
       FreeTableau[tab];
       sG === sCut], {80}]];
  check["80 random GRAPH states: CCTStabEntropy === GF(2) biadjacency cut-rank (independent formula)", ok];
  addRow["T1 graph cut-rank", "80 cases", t, ok]];

Module[{bell, ghz, tab},
  bell = CCTMeshBellPair[1, {2, 3}]["entropy"];
  (* GHZ_3 = path graph state 1-2-3 with H on the two tips (local-Clifford
     equivalent to GHZ); its subsystem entropies are the GHZ values. *)
  tab = NewGraphStateTableau[3, {{1, 2}, {2, 3}}];
  ApplyH[tab, 1]; ApplyH[tab, 3];
  ghz = {CCTStabEntropy[tab, {2}], CCTStabEntropy[tab, {1, 3}], CCTStabEntropy[tab, {1, 2, 3}]};
  FreeTableau[tab];
  check["anchors: Bell S(1qubit)=1; GHZ3 S({center})=1, S({tips})=1, S(all)=0",
    bell === 1 && ghz === {1, 1, 0}];
  addRow["T1 anchors", "Bell,GHZ3", 0, bell === 1 && ghz === {1, 1, 0}]];

(* ---------------------------------------------------------------------------
   T2.  PAGE CURVE.
   --------------------------------------------------------------------------- *)
Print["\n=== T2: Page curve (unitary evaporation) ==="];

(* T2a: direct sequential model -- rise, turnover at Page time, return to 0 *)
Module[{pc, mono, ok},
  pc = CCTPageCurveDirect[16, "Seed" -> 4242];
  Print["  direct n=16 curve = ", pc["curve"], "  (peak ", pc["peak"], " of n/2=", 8, ")"];
  ok = pc["curve"][[1]] === 0 && pc["final"] === 0 && pc["peak"] >= 5 &&
       pc["peak"] === Max[pc["curve"][[7 ;; 11]]];       (* peak near Page time *)
  check["direct evaporation n=16: S(rad) starts 0, peaks near Page time k~n/2, returns to 0", ok];
  addRow["T2 direct Page", "n=16", pc["time"], ok]];

(* T2b: mesh-cluster-state model -- initial black hole = pentagon-mesh state *)
Module[{pc, ok},
  pc = CCTPageCurveMesh[2, "Seed" -> 7, "Sweeps" -> 4];   (* n=18 mesh qubits *)
  Print["  mesh reps=2 (n=18) curve = ", pc["curve"], "  peak ", pc["peak"]];
  ok = pc["curve"][[1]] === 0 && pc["final"] === 0 && pc["peak"] >= 6;
  check["mesh-cluster evaporation reps=2 (n=18): valid Page curve from the pentagon-mesh initial state", ok];
  addRow["T2 mesh Page", "reps=2,n=18", pc["time"], ok]];

(* T2c: mesh-carved Bell pairs on several mesh edges -> S=1 each *)
Module[{t, edges, res, ok},
  {t, res} = AbsoluteTiming[Module[{e = CCTMeshEdges[1]},
     CCTMeshBellPair[1, #]["isBellPair"] & /@ e]];
  ok = And @@ res;
  check["mesh-carved Bell pairs on ALL " <> ToString[Length[res]] <> " reps=1 edges: every carve gives S=1 (maximal entanglement)", ok];
  addRow["T2 mesh Bell pairs", ToString[Length[res]] <> " edges", t, ok]];

(* T2d: ensemble-averaged Renyi-2 vs Lubkin/Page closed form, n=8,10,12 *)
Module[{tol = 0.15, allok = True},
  Do[Module[{r2, d},
     r2 = CCTPageRenyi2Ensemble[nn, 100, "Seed" -> 1000 + nn];
     d = Max[Abs[r2["S2sampled"] - r2["S2closed"]]];
     Print["  n=", nn, " (100 shots): peak S2 sampled=", fmt[Max[r2["S2sampled"]]],
       " closed=", fmt[Max[r2["S2closed"]]], "  max|diff|=", fmt[d], "  t=", fmt[r2["time"]], "s"];
     allok = allok && (d < tol);
     addRow["T2 Renyi2 ensemble", "n=" <> ToString[nn] <> ",100sh", r2["time"], d < tol]],
    {nn, {8, 10, 12}}];
  check["ensemble Renyi-2 (100 random-Clifford realizations) matches Lubkin/Page closed form within " <> ToString[tol] <> " (Clifford 2-design)", allok]];

(* T2e: SCALE demonstration, single-realization Page curve n=50,100,200 *)
Module[{allok = True},
  Do[Module[{nn = c[[1]], sw = c[[2]], pc, ok},
     pc = CCTPageCurveScrambledState[nn, "Seed" -> 3, "Sweeps" -> sw];
     ok = pc["final"] === 0 && pc["peak"] >= Floor[0.9 nn/2];
     Print["  n=", nn, " sweeps=", sw, ": peak=", pc["peak"], " (n/2=", nn/2,
       ") final=", pc["final"], " maxRowWeight=", pc["maxWeight"], "  time=", fmt[pc["time"]], "s"];
     allok = allok && ok;
     addRow["T2 SCALE Page", "n=" <> ToString[nn], pc["time"], ok]],
    {c, {{50, 12}, {100, 14}, {200, 16}}}];
  check["SCALE: single-realization exact Page curve at n=50,100,200 -- peak ~ n/2, returns to 0", allok]];

(* ---------------------------------------------------------------------------
   T3.  HAYDEN-PRESKILL.
   --------------------------------------------------------------------------- *)
Print["\n=== T3: Hayden-Preskill decoding ==="];

sc = CCTFindMaximalScrambler[4, "Seed" -> 123];
Module[{ok},
  ok = sc["isMaximal"];
  Print["  maximal scrambler m=4: minImageWeight=", sc["minImageWeight"], " tries=", sc["tries"]];
  check["constructed maximal Clifford scrambler: every 1-qubit Pauli conjugates to a >= 3-qubit Pauli (verified on tableau)", ok];
  addRow["T3 maximal scrambler", "m=4", 0, ok]];

Module[{epr, ok},
  epr = CCTHPDecodeEPR[sc["gates"]];
  Print["  EPR-projection: successProb=", epr["successProb"], "  Fe=", epr["Fe"]];
  ok = epr["successProb"] === 1/4 && epr["Fe"] === 1;
  check["EPR-projection decoder: success prob == 1/d_A^2 == 1/4 (derived) and decode fidelity Fe == 1", ok];
  addRow["T3 EPR decoder", "d_A=2", 0, ok]];

Module[{det, ok},
  det = CCTHPDecodeDeterministic[sc["gates"]];
  Print["  deterministic decoder: S_pair=", det["S_pair"], " S_half=", det["S_half"]];
  ok = det["recovered"];
  check["deterministic decoder: reference pair (A',R) left a pure Bell state (S_pair=0, S_half=1) -> fidelity 1, prob 1", ok];
  addRow["T3 deterministic", "-", 0, ok]];

Module[{tele, ok},
  tele = CCTHPTeleportFidelity[sc["gates"]];
  Print["  Pauli-basis teleport recovered: ", tele["perInput"]];
  ok = tele["allRecovered"];
  check["teleportation of all 6 Pauli-basis diary states through scrambler+decoder recovered (fidelity 1)", ok];
  addRow["T3 Pauli teleport", "6 states", 0, ok]];

Module[{idepr, favg, ok},
  idepr = CCTHPDecodeEPR[{}];
  favg = (2 idepr["Fe"] + 1)/3;
  Print["  identity (non-scrambling) control: Fe=", idepr["Fe"], " -> basis-averaged teleport fidelity=", favg];
  ok = idepr["Fe"] === 1/4 && favg === 1/2;
  check["non-scrambling control: Fe=1/4 -> basis-averaged teleportation fidelity == 1/2 (no recovery)", ok];
  addRow["T3 identity control", "-", 0, ok]];

Module[{t, sweep, fes, mono, ok},
  {t, sweep} = AbsoluteTiming[CCTHPNoiseSweep[sc["gates"], {0.005, 0.01, 0.015, 0.02}, 500, 11]];
  fes = #["meanFe"] & /@ sweep;
  Print["  Pauli-depolarizing noise sweep (500 shots/point):"];
  Do[Print["    p=", s["p"], "  <Fe>=", fmt[s["meanFe"]], "  (", s["valid"], " valid, ", s["projFail"], " proj-fail)"], {s, sweep}];
  mono = And @@ (Negative /@ Differences[fes]);           (* strictly degrading *)
  ok = (First[fes] < 1) && (Last[fes] < First[fes]) && mono;
  check["depolarizing noise sweep (0.5%-2%/gate, 500 shots): decode fidelity degrades monotonically from 1", ok];
  addRow["T3 noise sweep", "0.5-2%,500sh", t, ok]];

(* ---------------------------------------------------------------------------
   SCOREBOARD.
   --------------------------------------------------------------------------- *)
Print["\n############################################################"];
Print["=== CONSOLIDATED SCOREBOARD ==="];
Module[{hdr = {"test", "detail", "time(s)", "verdict"}, w},
  w = Table[Max[StringLength[hdr[[j]]], Max @@ Prepend[StringLength /@ scoreRows[[All, j]], 1]], {j, 4}];
  Print["  ", StringRiffle[Table[StringPadRight[hdr[[j]], w[[j]]], {j, 4}], "  "]];
  Do[Print["  ", StringRiffle[Table[StringPadRight[r[[j]], w[[j]]], {j, 4}], "  "]], {r, scoreRows}]];
Print["\nTOTAL: ", passCount, " PASS, ", failCount, " FAIL"];
Print["OVERALL: ", If[failCount === 0, "ALL TESTS PASSED", "SOME TESTS FAILED"]];
Print["############################################################"];
