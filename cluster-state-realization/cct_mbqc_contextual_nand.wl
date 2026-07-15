(* ::Package:: *)

(* ===========================================================================
   cct_mbqc_contextual_nand.wl
   Pentagon-mesh-carved GHZ triples power universal classical computation
   via contextuality (Anders & Browne, PRL 102, 050502 (2009)).

   Self-contained explicit small-matrix demonstration (mbqc_c5.wl style,
   independent of the sparse tableau simulator):

     STEP 1  CARVE. On the ACTUAL pentagon-mesh graph state
             |G> = prod_{(i,j) in wordRingEdgesFast["cct",reps]} CZ_ij |+>^n
             (reps=1: n=9 qubits; reps=2: n=18 qubits), Z-measure every
             vertex except the path-adjacent survivors S={1,2,3}. ALL
             Z-outcome branches are enumerated EXHAUSTIVELY (64 at reps=1,
             32768 at reps=2) and each branch is shown EXACTLY equal to
               (global sign) x (prod_s Z_s^{c_s}) |P3>,
             where the byproduct exponent c_s = parity of the outcomes of
             survivor s's measured neighbors (Hein et al., PRA 69, 062311
             (2004): Z-measurement deletes the vertex, Z byproducts on
             neighbors for outcome 1), and the residual global sign is
             (-1)^{sum of z_u z_v over measured-measured edges}. Then the
             exact local Clifford correction  (H (x) I (x) H)|P3> = |GHZ3>
             is derived and verified as matrices (global phase exactly +1).

     STEP 2  ANDERS-BROWNE OR GATE on the carved state. Inputs (a,b) ->
             GHZ-frame measurement bases (a?Y:X, b?Y:X, (a xor b)?Y:X).
             The LC correction conjugates the measurement operators on
             qubits 1 and 3:  H X H = Z,  H Y H = -Y  (signs verified as
             matrices), and the carve byproducts Z^{c_s} flip the outcome
             of any measurement that anticommutes with Z (classical
             feed-forward frame: f = a*c1 xor c2 xor (a xor b)*c3).
             ALL measurement branches of all 4 input pairs on ALL 64 carve
             branches are enumerated in EXACT arithmetic: every branch with
             nonzero probability (exactly 4 per case, probability exactly
             1/4 each) has XOR-of-outcomes (frame-corrected) == OR(a,b).
             That proves determinism -- no sampling involved.

     STEP 3  THE CLASSICAL XOR SIDE-PROCESSOR ALONE IS PROVABLY TOO WEAK.
             All 64 noncontextual +-1 assignments to {X_1,X_2,X_3,Y_1,Y_2,
             Y_3} violate at least one of the four GHZ stabilizer
             constraints (Mermin all-versus-nothing) -- enumerated, 0 of 64
             survive -- and none of the 8 affine-over-GF(2) functions
             equals OR (enumerated, 0 of 8). The nonlinear OR is bought by
             contextuality, not by the linear side-processing.

     STEP 4  NAND AND AN 8-BIT RIPPLE-CARRY ADDER. NAND(x,y) =
             OR(not x, not y) -- negations are linear, free for the XOR
             side-processor. Per full-adder bit: sum = a xor b xor cin is
             free; carry = NAND( NAND(a,b), NAND(a xor b, cin) ) costs 3
             NANDs. So one 8-bit addition consumes exactly 24 fresh carved
             GHZ triples. EVERY NAND evaluation carves a FRESH mesh at run
             time (sequential Z measurements with sampled random outcomes,
             tracked Z-byproduct frame) and then samples the three-qubit
             measurement branches; the OR value is read off the
             (deterministic, Step-2-proven) frame-corrected parity.
             50 random 8-bit pairs, sum checked against a+b every time.

   HONEST FRAMING (required): all patterns here are Clifford, so
   Gottesman-Knill guarantees efficient classical simulation -- the claim
   is faithful protocol-level MBQC execution of well-known computations on
   the pentagon mesh at scales far beyond any statevector simulator
   (JUPITER exascale record: 50 qubits) or any existing quantum hardware,
   NOT a quantum-speedup claim. The documented path to universality is
   T-gate injection / stabilizer-rank (cost 2^(alpha t) in T-count t).
   What THIS file adds is the Anders-Browne point: the mesh's contextuality
   is a computational RESOURCE -- a parity-limited (XOR-only) classical
   control computer plus carved GHZ triples computes OR/NAND and hence any
   Boolean function, which the XOR computer provably cannot do alone
   (Step 3).

   Project physics conventions (fixed):
     graph state |G> = prod_{(i,j) in E} CZ_ij |+>^n ;
     stabilizers K_v = X_v prod_{u~v} Z_u ;
     Z-measurement deletes the vertex, Z byproducts on the neighbors for
     outcome 1 (Hein et al., PRA 69, 062311 (2004)).
   The quantum resource is the FIXED mesh graph state from
   wordRingEdgesFast["cct",reps]; the edge list is NEVER edited -- unused
   qubits are removed by actual Z measurements inside the simulator, and
   the only quantum operations after state preparation are single-qubit
   Pauli measurements plus classical feed-forward (Pauli frame).

   KNOWN LIMITATION (review 2026-07-13, documented as accepted): STEP 4's
   runtime branch SAMPLING uses machine floats (N[...] state, RandomReal[]
   thresholding, float renormalization), a deviation from the project's
   exact-arithmetic discipline.  It cannot affect correctness here: Step 2
   proves in EXACT arithmetic that every branch probability is exactly 0 or
   1/4, so the float comparison cannot misclassify a branch at these
   magnitudes, and the final adder outputs are checked with exact integer ===.
   Steps 1-3 (all correctness proofs) are exact throughout.

   Run:  wolframscript -file cct_mbqc_contextual_nand.wl
   =========================================================================== *)

(* ---------------------------------------------------------------------------
   wordRingEdgesFast: copied VERBATIM from
   cluster-state-realization/cct_mesh_sparse_construction.wl (O(L) replacement for the
   original wordRing in pentagon-gluing/CaseStudies.wl; verified there to
   give the EXACT same edge set at reps=1..50 and benchmarked to reps=3e6).
   NOT modified here in any way.
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

(* ---------------------------------------------------------------------------
   SECTION 0. Primitives + PASS/FAIL harness.
   --------------------------------------------------------------------------- *)
kp = KroneckerProduct; I2 = IdentityMatrix[2]; I8 = IdentityMatrix[8];
PX = {{0, 1}, {1, 0}}; PZ = {{1, 0}, {0, -1}}; PY = {{0, -I}, {I, 0}};
Hd = {{1, 1}, {1, -1}}/Sqrt[2];

passCount = 0; failCount = 0;
check[label_, ok_] := (If[TrueQ[ok], passCount++, failCount++];
   Print["  [", If[TrueQ[ok], "PASS", "FAIL"], "] ", label]; TrueQ[ok]);

nbrsOf[edges_, v_] :=
  Union[Join[Cases[edges, {v, u_} :> u], Cases[edges, {u_, v} :> u]]];

(* scaled graph state 2^{n/2}|G>: every amplitude is exactly +1 or -1 *)
meshStateScaled[edges_, n_] := Module[{bt, v},
   bt = IntegerDigits[Range[0, 2^n - 1], 2, n];
   v = ConstantArray[1, 2^n];
   Do[v = v*(1 - 2 bt[[All, e[[1]]]]*bt[[All, e[[2]]]]), {e, edges}];
   v];

psiP3scaled = meshStateScaled[{{1, 2}, {2, 3}}, 3];   (* 2^{3/2}|P3>, entries +-1 *)
psiP3 = psiP3scaled/2^(3/2);
ghz3 = {1, 0, 0, 0, 0, 0, 0, 1}/Sqrt[2];

(* ---------------------------------------------------------------------------
   SECTION 1. Carve P3 out of the ACTUAL mesh by Z measurements
   (exhaustive over all Z-outcome branches), then P3 -> GHZ3 local Clifford.
   --------------------------------------------------------------------------- *)
Print["=== STEP 1: carve GHZ triple out of the pentagon mesh (Z measurements, byproducts tracked) ==="];

verifyCarve[reps_] := Module[
   {n = 9 reps, nM, edges, sEdges, mmEdges, state, brM, ztab, measNbrLoc,
    cvecs, sgM, prodM, colT, predS, okPath, okConst, okSign},
   edges = wordRingEdgesFast["cct", reps];
   nM = n - 3;
   sEdges = Select[edges, Max[#] <= 3 &];
   mmEdges = Select[edges, Min[#] >= 4 &];
   okPath = (sEdges === {{1, 2}, {2, 3}});
   measNbrLoc = Table[Select[nbrsOf[edges, s], # > 3 &], {s, 1, 3}];
   Print["  reps=", reps, ": n=", n, " qubits, ", Length[edges],
     " edges from wordRingEdgesFast[\"cct\",", reps, "] (edge list NOT edited)"];
   Print["    survivors S={1,2,3}; measured M={4..", n, "}; measured-neighbor sets of S (byproduct sources): ", measNbrLoc];
   check["reps=" <> ToString[reps] <> ": induced subgraph on survivors is exactly the path 1-2-3", okPath];
   state = meshStateScaled[edges, n];               (* 2^{n/2}|G>, entries +-1 *)
   brM = Partition[state, 2^nM];                    (* 8 x 2^nM ; column z = unnormalized carve branch (+-1 entries) *)
   ztab = IntegerDigits[Range[0, 2^nM - 1], 2, nM]; (* row z+1 = Z outcomes on qubits 4..n *)
   cvecs = Table[Mod[Total[Table[ztab[[All, q - 3]], {q, measNbrLoc[[s]]}]], 2], {s, 1, 3}];
   sgM = Table[Module[{x = IntegerDigits[s, 2, 3]},
       ((1 - 2 cvecs[[1]])^x[[1]])*((1 - 2 cvecs[[2]])^x[[2]])*((1 - 2 cvecs[[3]])^x[[3]])],
     {s, 0, 7}];
   prodM = psiP3scaled*(brM*sgM);
   colT = Total[prodM];                             (* column z: +-8 iff branch == (sign) Z^c |P3> exactly *)
   okConst = (Union[Abs[colT]] === {8});
   predS = ConstantArray[1, 2^nM];
   Do[predS = predS*(1 - 2 ztab[[All, e[[1]] - 3]]*ztab[[All, e[[2]] - 3]]), {e, mmEdges}];
   okSign = TrueQ[colT == 8 predS];
   check["reps=" <> ToString[reps] <> ": ALL " <> ToString[2^nM] <>
     " Z-outcome branches == (sign) x Z^c |P3> EXACTLY (byproduct c = parity of measured-neighbor outcomes)", okConst];
   check["reps=" <> ToString[reps] <> ": residual global sign == (-1)^{sum z_u z_v over measured-measured edges} for ALL branches", okSign];
   {brM, ztab, measNbrLoc, colT}];

{brM1, ztab1, measNbr, colT1} = verifyCarve[1];
Print["    sample carve branches at reps=1 (z on qubits 4..9 | byproduct c on survivors | residual sign):"];
Do[Module[{cz, sg},
    cz = Table[Mod[Total[ztab1[[z + 1, # - 3]] & /@ measNbr[[s]]], 2], {s, 1, 3}];
    sg = colT1[[z + 1]]/8;
    Print["      z=", ztab1[[z + 1]], "  ->  c=", cz, "   sign=", sg]],
  {z, {0, 1, 5, 21, 63}}];
verifyCarve[2];   (* 18-qubit mesh, all 32768 branches, exhaustive *)

Print["  local Clifford correction P3 -> GHZ3:"];
check["H.X.H == Z  (matrices)", Simplify[Hd . PX . Hd] === PZ];
check["H.Y.H == -Y (matrices)", Simplify[Hd . PY . Hd] === -PY];
check["H.Z.H == X  (matrices)", Simplify[Hd . PZ . Hd] === PX];
Ulc = kp[Hd, kp[I2, Hd]];
check["(H (x) I (x) H) |P3> == |GHZ3> EXACTLY (global phase +1)",
  Union[FullSimplify[Ulc . psiP3 - ghz3]] === {0}];
Print[];

(* ---------------------------------------------------------------------------
   SECTION 2. Anders-Browne OR gate on the carved state -- ALL branches.
   GHZ-frame settings: (a?Y:X, b?Y:X, (a xor b)?Y:X).
   Carved (P3) frame:  qubits 1,3 conjugated by H:  X -> Z,  Y -> -Y ;
                       qubit 2 unchanged.
   Byproduct frame:    Z^{c_s} flips outcomes of anticommuting measurements:
                       f = a*c1 xor c2 xor (a xor b)*c3   (Z commutes -> no flip).
   --------------------------------------------------------------------------- *)
Print["=== STEP 2: Anders-Browne OR(a,b) via XOR of outcomes -- exhaustive branch enumeration ==="];

ghzSetting[t_] := If[t == 1, PY, PX];      (* GHZ-frame operator *)
omg[t_] := If[t == 1, -PY, PZ];            (* H-conjugated operator on qubits 1,3 *)
settingNames[a_, b_] := Module[{c = Mod[a + b, 2]},
   {StringJoin["GHZ frame {", If[a == 1, "Y", "X"], ",", If[b == 1, "Y", "X"], ",", If[c == 1, "Y", "X"], "}"],
    StringJoin["carved frame {", If[a == 1, "-Y", "Z"], ",", If[b == 1, "Y", "X"], ",", If[c == 1, "-Y", "Z"], "}"]}];

gadgetOps[{a_, b_}] := Module[{c = Mod[a + b, 2]},
   {kp[omg[a], kp[I2, I2]], kp[I2, kp[ghzSetting[b], I2]], kp[I2, kp[I2, omg[c]]]}];
jointProjs[{a_, b_}] := Module[{ops = gadgetOps[{a, b}]},
   Table[{m, Dot @@ Table[(I8 + (1 - 2 m[[i]]) ops[[i]])/2, {i, 1, 3}]}, {m, Tuples[{0, 1}, 3]}]];

inputPairs = {{0, 0}, {0, 1}, {1, 0}, {1, 1}};
jp = Association[Table[ab -> jointProjs[ab], {ab, inputPairs}]];

(* illustrative table on the c=(0,0,0) carve branch (z=0) *)
Print["  illustrative branch table (carve branch z=0, byproduct c={0,0,0}), exact probabilities:"];
Module[{v = brM1[[All, 1]]},
  Do[Module[{a = ab[[1]], b = ab[[2]], names = settingNames @@ ab, rows},
     rows = Select[Table[{br[[1]], Simplify[(Conjugate[v] . (br[[2]] . v))/8]}, {br, jp[ab]}],
        #[[2]] =!= 0 &];
     Print["    (a,b)=", ab, "  ", names[[1]], " -> ", names[[2]], "   OR=", Max[ab]];
     Do[Print["        outcomes m=", r[[1]], "  prob=", r[[2]], "  xor(m)=", Mod[Total[r[[1]]], 2]], {r, rows}]],
    {ab, inputPairs}]];

(* exhaustive: 64 carve branches x 4 inputs x 8 measurement branches, EXACT *)
step2Bad = 0; step2Cases = 0;
Do[Module[{v = brM1[[All, z + 1]], cvec},
   cvec = Table[Mod[Total[ztab1[[z + 1, # - 3]] & /@ measNbr[[s]]], 2], {s, 1, 3}];
   Do[Module[{a = ab[[1]], b = ab[[2]], f, orTruth, nnz = 0, ptot = 0},
      f = Mod[a cvec[[1]] + cvec[[2]] + Mod[a + b, 2] cvec[[3]], 2];
      orTruth = Max[ab];
      Do[Module[{m = br[[1]], q},
         q = Simplify[(Conjugate[v] . (br[[2]] . v))/8];
         ptot += q;
         If[q =!= 0,
           nnz++;
           If[q =!= 1/4, step2Bad++];
           If[Mod[Total[m] + f, 2] =!= orTruth, step2Bad++]]],
        {br, jp[ab]}];
      If[nnz =!= 4 || ptot =!= 1, step2Bad++];
      step2Cases++],
     {ab, inputPairs}]],
  {z, 0, 63}];
Print["  checked ", step2Cases, " (carve branch, input) cases x 8 measurement branches each, exact arithmetic"];
check["every nonzero-probability branch has exact probability 1/4 (4 branches per case, total 1)", step2Bad === 0];
check["frame-corrected XOR of outcomes == OR(a,b) on EVERY branch of EVERY carve, all 4 inputs -> DETERMINISTIC", step2Bad === 0];
Print[];

(* ---------------------------------------------------------------------------
   SECTION 3. All-versus-nothing: the classical XOR side-processor alone
   cannot produce OR.
   --------------------------------------------------------------------------- *)
Print["=== STEP 3: contextuality is the resource -- classical side-processor provably too weak ==="];
stabOps = {kp[PX, kp[PX, PX]], kp[PX, kp[PY, PY]], kp[PY, kp[PX, PY]], kp[PY, kp[PY, PX]]};
stabSigns = {1, -1, -1, -1};
check["GHZ3 stabilizer signs (XXX:+1),(XYY:-1),(YXY:-1),(YYX:-1) verified as matrices on |GHZ3>",
  And @@ Table[Union[Simplify[stabOps[[i]] . ghz3 - stabSigns[[i]] ghz3]] === {0}, {i, 1, 4}]];
nSat = Count[Tuples[{1, -1}, 6],
   v_ /; v[[1]] v[[2]] v[[3]] == 1 && v[[1]] v[[5]] v[[6]] == -1 &&
     v[[4]] v[[2]] v[[6]] == -1 && v[[4]] v[[5]] v[[3]] == -1];
Print["  assignments {v(X1),v(X2),v(X3),v(Y1),v(Y2),v(Y3)} in {+1,-1}^6 satisfying all 4 constraints: ",
  nSat, " of 64"];
check["NO fixed +-1 assignment reproduces the 4 GHZ constraints (Mermin AvN) -- 0 of 64", nSat === 0];
Print["  parity argument: multiply the 4 constraints -- every v appears twice, LHS = +1, but RHS = (+1)(-1)(-1)(-1) = -1."];
nAffine = Count[Tuples[{0, 1}, 3],
   {al_, be_, ga_} /; Flatten[Table[Mod[al a + be b + ga, 2], {a, 0, 1}, {b, 0, 1}]] === {0, 1, 1, 1}];
check["NO affine-over-GF(2) function al*a xor be*b xor ga equals OR -- 0 of 8 (XOR processing alone cannot do OR)",
  nAffine === 0];
Print["  => the OR gate of Step 2 is bought by the contextual GHZ correlations, not by linear postprocessing."];
Print[];

(* ---------------------------------------------------------------------------
   SECTION 4. NAND from OR + linear negations; 8-bit ripple-carry adder in
   which EVERY nonlinear gate consumes one fresh carved GHZ triple.
   Runtime protocol per NAND: build fresh 9-qubit mesh state -> sequential Z
   measurements on qubits 4..9 with sampled outcomes (byproduct frame c) ->
   sequential measurement of the three conjugated operators with sampled
   outcomes -> output = frame-corrected XOR (deterministic by Step 2).
   --------------------------------------------------------------------------- *)
Print["=== STEP 4: NAND gates + 8-bit ripple-carry adder, one fresh GHZ triple per nonlinear gate ==="];

nQ = 9; edges1 = wordRingEdgesFast["cct", 1];
meshN = N[meshStateScaled[edges1, nQ]];
bt9 = IntegerDigits[Range[0, 2^nQ - 1], 2, nQ];
bitcols = Table[N[bt9[[All, q]]], {q, 1, nQ}];

nTriples = 0; nandMismatch = 0;

carveTriple[] := Module[{v = meshN, zs = <||>, p1, z, zint, sub, cvec},
   Do[
     p1 = Total[(v*bitcols[[q]])^2]/Total[v^2];
     z = If[RandomReal[] < p1, 1, 0];
     zs[q] = z;
     v = v*If[z == 1, bitcols[[q]], 1 - bitcols[[q]]],
     {q, 4, nQ}];
   zint = FromDigits[Table[zs[q], {q, 4, nQ}], 2];
   sub = Table[v[[64 s + zint + 1]], {s, 0, 7}];
   sub = sub/Norm[sub];
   cvec = Table[Mod[Total[zs /@ measNbr[[s]]], 2], {s, 1, 3}];
   nTriples++;
   {sub, cvec}];

gadgetData = Association[Table[
    ab -> Table[{N[(I8 + op)/2], N[(I8 - op)/2]}, {op, gadgetOps[ab]}], {ab, inputPairs}]];

orGadget[a_, b_, st_, cvec_] := Module[{v = st, ms = {}, pd = gadgetData[{a, b}], pPlus, m, f},
   Do[
     pPlus = Min[Max[Re[Conjugate[v] . (pd[[i, 1]] . v)], 0.], 1.];
     m = If[RandomReal[] < pPlus, 0, 1];
     v = If[m == 0, pd[[i, 1]] . v, pd[[i, 2]] . v];
     v = v/Norm[v];
     AppendTo[ms, m],
     {i, 1, 3}];
   f = Mod[a cvec[[1]] + cvec[[2]] + Mod[a + b, 2] cvec[[3]], 2];
   Mod[Total[ms] + f, 2]];

nandGate[x_, y_] := Module[{st, cvec, out},
   {st, cvec} = carveTriple[];
   out = orGadget[1 - x, 1 - y, st, cvec];   (* OR(not x, not y) = NAND(x,y); negations linear/free *)
   If[out =!= 1 - x*y, nandMismatch++];
   out];

fullAdder[x_, y_, cin_] := Module[{p = BitXor[x, y], sm, t1, t2, cout},
   sm = BitXor[p, cin];                      (* linear, free for the XOR side-processor *)
   t1 = nandGate[x, y];
   t2 = nandGate[p, cin];
   cout = nandGate[t1, t2];                  (* NAND(t1,t2) = (x AND y) OR (p AND cin) = carry *)
   {sm, cout}];

add8[a_, b_] := Module[{abts = Reverse[IntegerDigits[a, 2, 8]],
    bbts = Reverse[IntegerDigits[b, 2, 8]], cin = 0, sbits = ConstantArray[0, 8], sm},
   Do[{sm, cin} = fullAdder[abts[[i]], bbts[[i]], cin]; sbits[[i]] = sm, {i, 1, 8}];
   Total[sbits*2^Range[0, 7]] + cin*2^8];

SeedRandom[20260713];
nTrials = 50; nCorrect = 0; failList = {};
Do[Module[{a = RandomInteger[{0, 255}], b = RandomInteger[{0, 255}], got, ok},
    got = add8[a, b];
    ok = (got === a + b);
    If[ok, nCorrect++, AppendTo[failList, {a, b, got}]];
    If[t <= 3 || ! ok,
      Print["    trial ", t, ": ", a, " + ", b, " = ", got, " (expected ", a + b, ")  ",
        If[ok, "ok", "WRONG"]]]],
  {t, 1, nTrials}];
Print["    ... (", nTrials, " trials total, ", Length[failList], " failures)"];
Print[];

(* ---------------------------------------------------------------------------
   FINAL SCOREBOARD
   --------------------------------------------------------------------------- *)
Print["=== FINAL SCOREBOARD ==="];
Print["  8-bit additions run ................ ", nTrials];
Print["  correct sums (== a+b exactly) ...... ", nCorrect, " / ", nTrials];
Print["  fresh carved GHZ triples consumed .. ", nTriples,
  "  (expected ", 24 nTrials, " = 3 NANDs/bit x 8 bits x ", nTrials, " additions)"];
Print["  NAND outputs matching truth table .. ", nTriples - nandMismatch, " / ", nTriples];
check["all " <> ToString[nTrials] <> " random 8-bit additions correct", nCorrect === nTrials];
check["exactly 24 fresh GHZ triples per addition (every nonlinear gate = one triple)", nTriples === 24 nTrials];
check["zero NAND truth-table mismatches across all " <> ToString[nTriples] <> " gate evaluations", nandMismatch === 0];
Print[];
Print["TOTAL CHECKS: ", passCount, " PASS, ", failCount, " FAIL"];
Print["OVERALL: ", If[failCount === 0, "ALL TESTS PASSED",
   "SOME TESTS FAILED -- see FAIL lines above"]];
