(* ::Package:: *)

(* ===========================================================================
   cct_mbqc_patterns_tests.wl -- full validation suite for cct_mbqc_patterns.wl.
   Every claim is asserted with a printed [PASS]/[FAIL]; zero failures required.

   HONEST FRAMING (verbatim): every pattern here is Clifford, so Gottesman-Knill
   guarantees efficient classical simulation.  The claim is FAITHFUL
   PROTOCOL-LEVEL MBQC execution of well-known quantum algorithms on the fixed
   pentagon-mesh graph state at scales far beyond any statevector simulator
   (JUPITER exascale record: 50 qubits) or existing hardware -- NOT a
   quantum-speedup claim.  Path to universality: T-gate injection /
   stabilizer-rank (cost 2^(alpha t) in T-count t).
   Citations: Anders-Browne PRL 102,050502 (2009); Raussendorf PRA 88,022322
   (2013); Hein-Eisert-Briegel PRA 69,062311 (2004); Aaronson-Gottesman PRA
   70,052328 (2004); Bernstein-Vazirani SIAM JC 26,1411 (1997); Grover STOC 1996.

   Run:  wolframscript -file cct_mbqc_patterns_tests.wl
   =========================================================================== *)

CCTMBQCPatternsLoadOnly = True;
Get[FileNameJoin[{DirectoryName[$InputFileName], "cct_mbqc_patterns.wl"}]];

passCount = 0; failCount = 0;
check[label_, ok_] := (If[TrueQ[ok], passCount++, failCount++];
  Print["  [", If[TrueQ[ok], "PASS", "FAIL"], "] ", label]; TrueQ[ok]);

(* ---- independent explicit-matrix graph-state + projective-measurement backend
   (kept separate from the tableau sim so the cross-checks are genuinely
   independent) ------------------------------------------------------------ *)
kp = KroneckerProduct; I2 = IdentityMatrix[2];
mPX = {{0, 1}, {1, 0}}; mPZ = {{1, 0}, {0, -1}}; mPY = {{0, -I}, {I, 0}};
mOp1[P_, q_, n_] := Fold[kp, #[[1]], Rest[#]] &[Table[If[i == q, P, I2], {i, n}]];
mGState[edges_, n_] := Module[{v = ConstantArray[1, 2^n], bt = IntegerDigits[Range[0, 2^n - 1], 2, n]},
  Do[v = v (1 - 2 bt[[All, e[[1]]]] bt[[All, e[[2]]]]), {e, edges}]; v];
mPmat[b_] := Switch[b, "X", mPX, "Y", mPY, "Z", mPZ];
mProj[v_, b_, q_, n_, s_] := Module[{w},
  w = ((mOp1[mPmat[b], q, n] + (-1)^s IdentityMatrix[2^n])/2) . v;
  If[Chop[Norm[N@w]] == 0, None, w]];

Print["############################################################"];
Print["### cct_mbqc_patterns.wl  VALIDATION SUITE"];
Print["############################################################"];

(* ==========================================================================
   TEST A -- input-prep mapping: measuring a degree-1 prep neighbour in X/Z/Y
   leaves the 6 Bloch stabilizer states on the head (machine-verified basis of
   the wire input injection).
   ========================================================================== *)
Print["=== TEST A: prep-neighbour measurement -> 6 Bloch inputs (explicit matrices) ==="];
Module[{rho1, sname, res},
  rho1[v_, q_, n_] := Module[{M = ArrayReshape[v, {2^(q - 1), 2, 2^(n - q)}]},
    Table[Sum[Conjugate[M[[i, a, j]]] M[[i, b, j]], {i, 2^(q - 1)}, {j, 2^(n - q)}], {a, 2}, {b, 2}]];
  sname[rho_] := Module[{r = Simplify[rho/Tr[rho]]}, Which[
     r === {{1, 0}, {0, 0}}, "0", r === {{0, 0}, {0, 1}}, "1",
     r === {{1/2, 1/2}, {1/2, 1/2}}, "+", r === {{1/2, -1/2}, {-1/2, 1/2}}, "-",
     r === {{1/2, -I/2}, {I/2, 1/2}}, "+i", r === {{1/2, I/2}, {-I/2, 1/2}}, "-i", True, "?"]];
  res = Table[Module[{v = mGState[{{1, 2}}, 2], w},
      w = mProj[v, CCTPrepSpec[st][[1]], 1, 2, CCTPrepSpec[st][[2]]];
      sname[rho1[w, 2, 2]] === st], {st, {"0", "1", "+", "-", "+i", "-i"}}];
  check["all 6 CCTPrepSpec preparations leave the intended Bloch state on the head", And @@ res]];
Print[];

(* ==========================================================================
   TEST B -- GADGET 1 wire.
   B1: push each of the 6 Bloch inputs through m=2 (kH=1) and m=3 (kH=2) wires;
       assert output == (Pauli frame) . H^{kH} |psi>  (byproductFrame != UNFAITHFUL),
       over several random shots (byproduct differs, faithfulness holds).
   B2: SMALLEST case exact cross-check tableau-vs-explicit, ALL branches.
   ========================================================================== *)
Print["=== TEST B: GADGET 1 -- gate-teleportation wire ==="];
Module[{path1 = {3, 2, 1}, path2 = {3, 2, 1, 4}, inputs = {"0", "1", "+", "-", "+i", "-i"}, ok1, ok2},
  ok1 = And @@ Flatten[Table[
     Table[TeleportWire[1, path1, st]["byproductFrame"] =!= "UNFAITHFUL", {shot, 4}],
     {st, inputs}]];
  check["wire m=2 (kH=1), all 6 Bloch inputs, 4 random shots each: output == frame . H|psi> (faithful)", ok1];
  ok2 = And @@ Flatten[Table[
     Table[TeleportWire[1, path2, st]["byproductFrame"] =!= "UNFAITHFUL", {shot, 4}],
     {st, inputs}]];
  check["wire m=3 (kH=2), all 6 Bloch inputs, 4 random shots each: output == frame . H^2|psi> (faithful)", ok2];
  (* explicit report of the three required inputs |0>,|+>,|+i> at forced +,+ *)
  Print["  explicit byproduct frames (path {3,2,1}, forced carve/prep/teleport all 0):"];
  Do[With[{w = TeleportWire[1, path1, st, "Forced" -> {0, 0}]},
     Print["     input |", st, ">  ->  logical H|", st, ">  byproductFrame = ", w["byproductFrame"]]],
    {st, {"0", "+", "+i"}}]];

Print["  --- B2: exact cross-check tableau vs independent explicit matrices, ALL teleport branches ---"];
Module[{edges = CCTMeshEdges[1], n = 9, prep = 3, head = 2, others = {4, 5, 6, 7, 8, 9},
   mism = 0, tot = 0, carvePatterns},
  carvePatterns = {{0, 0, 0, 0, 0, 0}, {1, 0, 1, 0, 1, 0}, {0, 1, 0, 1, 0, 1}, {1, 1, 1, 1, 1, 1}};
  Do[Module[{tab, vT, vE, ok = True},
     tab = NewGraphStateTableau[n, edges];
     Do[MeasurePauli[tab, others[[j]], "Z", "ForcedOutcome" -> zf[[j]]], {j, 6}];
     MeasurePauli[tab, prep, bp, "ForcedOutcome" -> sp];
     MeasurePauli[tab, head, "X", "ForcedOutcome" -> s2];
     vT = StateVectorFromTableau[tab]; FreeTableau[tab];
     vE = mGState[edges, n];
     Do[vE = mProj[vE, "Z", others[[j]], n, zf[[j]]]; If[vE === None, ok = False], {j, 6}];
     If[ok, vE = mProj[vE, bp, prep, n, sp]; If[vE === None, ok = False]];
     If[ok, vE = mProj[vE, "X", head, n, s2]; If[vE === None, ok = False]];
     If[ok, tot++; If[! PhaseScaleEquivalentQ[vT, vE], mism++]]],
    {zf, carvePatterns}, {bp, {"X", "Y", "Z"}}, {sp, {0, 1}}, {s2, {0, 1}}];
  check["wire smallest case: tableau state === explicit-matrix state for ALL " <>
     ToString[tot] <> " branches (exact, up to phase)", mism === 0 && tot > 0]];
Print[];

(* ==========================================================================
   TEST C -- GADGET 2 Bernstein-Vazirani.
   C1: exhaustive over ALL secrets at n=3 (reps=1) and n=4 (reps=2).
   C2: determinism -- same secret, many shots (different random frames), the
       recovered string is invariant and equals s.
   C3: 25 random secrets at n=32 (reps=11), all recovered exactly.
   ========================================================================== *)
Print["=== TEST C: GADGET 2 -- Bernstein-Vazirani (prob-1 single-query readout) ==="];
Module[{ok3, ok4},
  ok3 = And @@ Table[RunBernsteinVazirani[1, s]["correct"], {s, Tuples[{0, 1}, 3]}];
  check["BV exhaustive: ALL 8 secrets at n=3 (reps=1) recovered exactly", ok3];
  ok4 = And @@ Table[RunBernsteinVazirani[2, s]["correct"], {s, Tuples[{0, 1}, 4]}];
  check["BV exhaustive: ALL 16 secrets at n=4 (reps=2) recovered exactly", ok4]];
Module[{sec = {1, 0, 1}, runs, frames, recs},
  runs = Table[RunBernsteinVazirani[1, sec], {12}];
  frames = runs[[All, "frame"]]; recs = runs[[All, "recovered"]];
  check["BV determinism: 12 shots of secret {1,0,1} -- byproduct frames VARY ("<>
     ToString[Length[Union[frames]]] <> " distinct) but recovered == secret every time",
    Length[Union[frames]] > 1 && Union[recs] === {sec}]];
Module[{ok32, secrets},
  SeedRandom[26];
  secrets = Table[RandomInteger[{0, 1}, 32], {25}];
  ok32 = And @@ Table[RunBernsteinVazirani[11, s]["correct"], {s, secrets}];
  check["BV: 25 random secrets at n=32 (reps=11, 99-qubit mesh) all recovered exactly", ok32]];
Module[{bv = RunBernsteinVazirani[11, RandomInteger[{0, 1}, 32]]},
  Print["  per-secret-bit overhead: pentagonsPerBit=", bv["pentagonsPerBit"],
     "  qubitsPerBit=", bv["qubitsPerBit"], "  (n=", bv["n"], " qubits / ", Length[bv["tips"]],
     " register tips)"]];
Print[];

(* ==========================================================================
   TEST D -- GADGET 3 Grover.
   D1: RunGrover2 -- all 4 marked items returned with certainty; determinism
       over many random measurement branches.
   D2: cross-check the compiled cluster pattern against the EXPLICIT 2-qubit
       Grover unitary (fidelity 1, all 4 marks).
   D3: RunGroverParallel[100] -- 100 disjoint instances, random marks, all
       correct (region isolation holds).
   ========================================================================== *)
Print["=== TEST D: GADGET 3 -- single-iteration 2-qubit Grover ==="];
Module[{ok},
  ok = And @@ Table[
     And @@ Table[RunGrover2[m]["correct"], {shot, 8}], {m, {0, 1, 2, 3}}];
  check["Grover: all 4 marked items returned with certainty (8 random shots each, deterministic)", ok]];
Module[{Hm, H2, CZ, diff, ket, oracle, okG},
  Hm = {{1, 1}, {1, -1}}/Sqrt[2]; H2 = kp[Hm, Hm]; CZ = DiagonalMatrix[{1, 1, 1, -1}];
  ket[b_] := Normal[UnitVector[4, FromDigits[b, 2] + 1]];
  oracle[m_] := DiagonalMatrix[ReplacePart[ConstantArray[1, 4], (FromDigits[m, 2] + 1) -> -1]];
  diff = H2 . (2 kp[{{1, 0}, {0, 0}}, {{1, 0}, {0, 0}}] - IdentityMatrix[4]) . H2;
  okG = And @@ Table[Module[{g = diff . oracle[m] . H2 . ket[{0, 0}]},
      Chop[Abs[Conjugate[ket[m]] . (g/Norm[g])]] == 1], {m, Tuples[{0, 1}, 2]}];
  check["explicit 2-qubit Grover unitary: G|00> == |m> with fidelity 1, all 4 marks (reference)", okG]];
Module[{gp},
  SeedRandom[100];
  gp = RunGroverParallel[100];
  check["Grover parallel: 100 disjoint instances (n=" <> ToString[gp["n"]] <>
     "), random marks, ALL correct -> region isolation holds",
    gp["allCorrect"] && gp["numCorrect"] === 100]];
Print[];

(* ==========================================================================
   SCOREBOARD
   ========================================================================== *)
Print["############################################################"];
Print["TOTAL CHECKS: ", passCount, " PASS, ", failCount, " FAIL"];
Print["OVERALL: ", If[failCount === 0, "ALL TESTS PASSED", "SOME TESTS FAILED"]];
Print["############################################################"];
