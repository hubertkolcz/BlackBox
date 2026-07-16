(* ::Package:: *)

(* ===========================================================================
   ddt_mbqc_hawking_review_probe.wl -- ADVERSARIAL REVIEW PROBE (independent).
   Written by the firewalled reviewer; verifies the two hawking deliverables
   with reviewer-owned code paths:
     R1  stabilizer-entropy formula vs reviewer's own dense numeric von
         Neumann entropy (eigenvalues, -sum p log2 p) on 40 fresh random
         Clifford states (incl. mid-circuit measurements), n<=9.
     R2  Lubkin closed form re-derived by Haar Monte Carlo (reviewer's own
         sampler); Clifford-ensemble 2-design purity check; fresh-seed Page
         curves: start 0, end 0, peak position/bound.
     R3  Hayden-Preskill: reviewer's own DENSE 10-qubit statevector sim of the
         whole protocol (Bell prep, U, U*, Bell projections) -> successProb,
         Fe; dense conjugation check that ALL 12 single-qubit Paulis (X,Y,Z on
         4 qubits) map to weight>=3 Paulis; identity control Fe=1/4.
     R4  CF anchors via reviewer's own from-scratch AB LP; explicit-angle CHSH.
     R5  exact Pauli readout DDTPairExp vs reviewer dense expectations, 12
         random cases; carved-pair correlators from dense statevector.
     R6  no-disturbance gate sensitivity: clean control passes, corrupted
         pairs (blatant + subtle) FAIL the pre-registered Hoeffding gate.
   =========================================================================== *)

probeDir = DirectoryName[$InputFileName];
DDTHawkingLoadOnly = True; DDTHawkingCertLoadOnly = True;
Get[FileNameJoin[{probeDir, "ddt_mbqc_hawking_evaporation.wl"}]];
Get[FileNameJoin[{probeDir, "ddt_mbqc_hawking_certification.wl"}]];

rPass = 0; rFail = 0;
rCheck[label_, ok_] := (If[TrueQ[ok], rPass++, rFail++];
  Print["  [", If[TrueQ[ok], "PASS", "FAIL"], "] ", label]; TrueQ[ok]);

(* ---------- reviewer's own dense linear algebra toolkit ------------------- *)
(* tensor convention: qubit 1 = first tensor level (most significant bit),
   matching IntegerDigits[k,2,n]; verified below by self-tests. *)
applyOp[v_List, U_, qs_List, n_Integer] := Module[{T, rest, k = Length[qs], fwd},
  T = ArrayReshape[v, ConstantArray[2, n]];
  rest = Complement[Range[n], qs];
  fwd = Ordering[Join[qs, rest]];
  T = Transpose[T, fwd];
  T = ArrayReshape[T, {2^k, 2^(n - k)}];
  T = U . T;
  T = ArrayReshape[T, ConstantArray[2, n]];
  T = Transpose[T, Join[qs, rest]];
  Flatten[T]];

rrho[v_List, qs_List, n_Integer] := Module[{T, rest, fwd, M},
  T = ArrayReshape[v, ConstantArray[2, n]];
  rest = Complement[Range[n], qs];
  fwd = Ordering[Join[qs, rest]];
  T = Transpose[T, fwd];
  M = ArrayReshape[T, {2^Length[qs], 2^(n - Length[qs])}];
  M . ConjugateTranspose[M]];

mH = {{1, 1}, {1, -1}}/Sqrt[2]; mS = {{1, 0}, {0, I}};
mX = {{0, 1}, {1, 0}}; mY = {{0, -I}, {I, 0}}; mZ = {{1, 0}, {0, -1}};
mI = IdentityMatrix[2];
mCNOT = {{1,0,0,0},{0,1,0,0},{0,0,0,1},{0,0,1,0}};
mCZ = DiagonalMatrix[{1, 1, 1, -1}];
phiP = {1, 0, 0, 1}/Sqrt[2];

(* toolkit self-test *)
Module[{v, ok1, ok2},
  v = ConstantArray[0, 8]; v[[1]] = 1;                       (* |000> *)
  v = applyOp[v, mX, {2}, 3];                                (* -> |010> *)
  ok1 = (Position[v, 1][[1, 1]] === FromDigits[{0, 1, 0}, 2] + 1);
  v = ConstantArray[0, 8]; v[[FromDigits[{0,0,1},2] + 1]] = 1; (* |001> *)
  v = applyOp[v, mCNOT, {3, 1}, 3];                           (* ctrl 3 -> tgt 1 *)
  ok2 = (Position[v, 1][[1, 1]] === FromDigits[{1, 0, 1}, 2] + 1);
  rCheck["R0 dense-toolkit self-test (X placement, nonadjacent CNOT)", ok1 && ok2]];

numVN[rho_] := Module[{ev = Select[Chop[Eigenvalues[N[rho]], 10^-10], # > 0 &]},
  -Total[# Log2[#] & /@ Re[ev]]];

(* ---------- R1: entropy formula vs reviewer dense vN ---------------------- *)
Print["=== R1: DDTStabEntropy vs reviewer dense von Neumann entropy ==="];
Module[{ok, worst = 0.},
  SeedRandom[884422];
  ok = And @@ Table[Module[{n = RandomInteger[{2, 9}], tab, A, sG, v, rho, sN},
    tab = NewGraphStateTableau[n,
      Union[Sort /@ Select[Subsets[Range[n], {2}], RandomReal[] < 0.3 &]]];
    Do[Switch[RandomInteger[{1, 8}],
       1, ApplyH[tab, RandomInteger[{1, n}]],
       2, ApplyS[tab, RandomInteger[{1, n}]],
       3, ApplySdg[tab, RandomInteger[{1, n}]],
       4, ApplyX[tab, RandomInteger[{1, n}]],
       5, ApplyZ[tab, RandomInteger[{1, n}]],
       6, If[n >= 2, With[{p = RandomSample[Range[n], 2]}, ApplyCNOT[tab, p[[1]], p[[2]]]]],
       7, If[n >= 2, With[{p = RandomSample[Range[n], 2]}, ApplyCZ[tab, p[[1]], p[[2]]]]],
       8, MeasurePauli[tab, RandomInteger[{1, n}],
            {"X", "Y", "Z"}[[RandomInteger[{1, 3}]]]]],
      {RandomInteger[{5, 40}]}];
    A = Sort[RandomSample[Range[n], RandomInteger[{0, n}]]];
    sG = DDTStabEntropy[tab, A];
    v = N[StateVectorFromTableau[tab, "Normalized" -> True]];
    sN = If[A === {}, 0., numVN[rrho[v, A, n]]];
    FreeTableau[tab];
    worst = Max[worst, Abs[sN - sG]];
    Abs[sN - sG] < 10^-8], {40}];
  Print["  40 fresh random Clifford states (gates+measurements), worst |dense vN - GF2| = ", worst];
  rCheck["R1 entropy: 40/40 exact match (tol 1e-8)", ok]];

(* ---------- R2: Lubkin closed form + Page turnover ------------------------ *)
Print["=== R2: Lubkin/Page closed form + turnover ==="];
Module[{res, ok},
  SeedRandom[13579];
  res = Table[Module[{dA = dd[[1]], dB = dd[[2]], m = 8000, s = 0., v, M, rho, mc, cf},
    Do[v = RandomVariate[NormalDistribution[], {dA dB, 2}] . {1, I};
       v = v/Norm[v];
       M = ArrayReshape[v, {dA, dB}];
       rho = M . ConjugateTranspose[M];
       s += Re[Tr[rho . rho]], {m}];
    mc = s/m; cf = N[(dA + dB)/(dA dB + 1)];
    Print["  Haar MC purity dA=", dA, " dB=", dB, ": MC=", mc, "  closed=", cf,
      "  |diff|=", Abs[mc - cf]];
    Abs[mc - cf] < 0.012], {dd, {{2, 2}, {2, 4}, {4, 4}, {2, 8}}}];
  rCheck["R2a Haar-MC re-derivation of Lubkin (dA+dB)/(dAdB+1), 4 dims, 8000 samples each", And @@ res];
  rCheck["R2b DDTLubkinPurity/DDTPageRenyi2Closed match reviewer formula",
    DDTLubkinPurity[4, 16] === 20/65 &&
    DDTPageRenyi2Closed[8, 3] === -Log2[(2^3 + 2^5)/(2^8 + 1)]]];

Module[{sum = 0, m = 600, tab, lub, mean, ok},
  SeedRandom[24680];
  Do[tab = NewGraphStateTableau[6, {}];
     DDTScramble[tab, Range[6], 16];
     sum += DDTStabPurity[tab, {1, 2}];
     FreeTableau[tab], {m}];
  mean = N[sum/m]; lub = N[DDTLubkinPurity[4, 16]];
  Print["  Clifford-ensemble mean purity n=6 r=2 (600 shots) = ", mean,
    "  Lubkin = ", lub, "  |diff| = ", Abs[mean - lub]];
  rCheck["R2c Clifford ensemble (2-design) purity matches Lubkin within 0.03", Abs[mean - lub] < 0.03]];

Module[{oks},
  oks = Table[Module[{pc = DDTPageCurveDirect[14, "Seed" -> sd, "Sweeps" -> 6],
      cv, pk, argmax},
    cv = pc["curve"]; pk = Max[cv]; argmax = First[Ordering[cv, -1]] - 1;
    Print["  fresh Page curve n=14 seed=", sd, ": ", cv];
    cv[[1]] === 0 && Last[cv] === 0 && pk <= 7 && pk >= 6 &&
      5 <= argmax <= 9], {sd, {31415, 27182, 16180}}];
  rCheck["R2d 3 fresh-seed Page curves n=14: start 0, end 0, 6<=peak<=n/2=7, turnover at k in [5,9]", And @@ oks]];

(* ---------- R3: Hayden-Preskill by reviewer dense simulation --------------- *)
Print["=== R3: HP protocol re-simulated densely (reviewer code) ==="];
gateMat[g_, conj_] := Switch[g[[1]],
  "H", {mH, {g[[2]]}}, "S", {If[conj, ConjugateTranspose[mS], mS], {g[[2]]}},
  "CNOT", {mCNOT, {g[[2]], g[[3]]}}, "CZ", {mCZ, {g[[2]], g[[3]]}}];

(* U* on the decoder side = entrywise complex conjugate of every gate matrix *)
denseHP2[gates_List] := Module[{n = 10, v, decmap, U, qs, P, pr1, rho, fe},
  v = ConstantArray[0., 2^n]; v[[1]] = 1.;
  Do[v = applyOp[v, mH, {pr[[1]]}, n];
     v = applyOp[v, mCNOT, pr, n], {pr, {{1, 5}, {2, 6}, {3, 7}, {4, 8}, {9, 10}}}];
  Do[{U, qs} = gateMat[g, False]; v = applyOp[v, U, qs, n], {g, gates}];
  decmap = <|1 -> 9, 2 -> 6, 3 -> 7, 4 -> 8|>;
  Do[{U, qs} = gateMat[g, False];
     v = applyOp[v, Conjugate[U], decmap /@ qs, n], {g, gates}];
  P = Outer[Times, phiP, Conjugate[phiP]];
  v = applyOp[v, P, {3, 7}, n];
  v = applyOp[v, P, {4, 8}, n];
  pr1 = Re[Conjugate[v] . v];
  If[pr1 < 10^-12, Return[<|"successProb" -> pr1, "Fe" -> Missing[]|>]];
  v = v/Sqrt[pr1];
  rho = rrho[v, {5, 10}, n];
  fe = Re[Conjugate[phiP] . (rho . phiP)];
  <|"successProb" -> pr1, "Fe" -> fe|>];

sc = DDTFindMaximalScrambler[4, "Seed" -> 123];
Print["  re-found scrambler seed 123: minImageWeight=", sc["minImageWeight"],
  " tries=", sc["tries"], " isMaximal=", sc["isMaximal"]];

Module[{r = denseHP2[sc["gates"]], rid = denseHP2[{}]},
  Print["  DENSE re-sim scrambler: successProb=", r["successProb"], "  Fe=", r["Fe"]];
  Print["  DENSE re-sim identity control: successProb=", rid["successProb"], "  Fe=", rid["Fe"]];
  rCheck["R3a dense re-sim: successProb == 1/4 (tol 1e-9) and Fe == 1 (tol 1e-9)",
    Abs[r["successProb"] - 1/4] < 10^-9 && Abs[r["Fe"] - 1] < 10^-9];
  rCheck["R3b dense identity control: Fe == 1/4 (tol 1e-9)",
    Abs[rid["Fe"] - 1/4] < 10^-9]];

(* all 12 single-qubit Paulis conjugate to weight >= 3 -- dense, reviewer code *)
Module[{m = 4, U, Udag, sq, paulis4, weightOf, ws, minw},
  U = IdentityMatrix[16];
  Do[Module[{gm = gateMat[g, False], full},
     full = Which[
       Length[gm[[2]]] == 1,
         KroneckerProduct @@ ReplacePart[ConstantArray[mI, 4], gm[[2, 1]] -> gm[[1]]],
       True, Module[{n4 = 4, big},
         big = IdentityMatrix[16];
         (* embed 2q gate via applyOp on basis columns *)
         big = Transpose[Table[applyOp[N[IdentityMatrix[16][[k]]], gm[[1]], gm[[2]], n4], {k, 16}]];
         big]];
     U = full . U], {g, sc["gates"]}];
  Udag = ConjugateTranspose[U];
  sq = <|"X" -> mX, "Y" -> mY, "Z" -> mZ, "I" -> mI|>;
  paulis4 = Flatten[Table[{l1, l2, l3, l4}, {l1, {"I","X","Y","Z"}}, {l2, {"I","X","Y","Z"}},
     {l3, {"I","X","Y","Z"}}, {l4, {"I","X","Y","Z"}}], 3];
  weightOf[A_] := Module[{hits},
    hits = Select[paulis4, Abs[Tr[KroneckerProduct @@ (sq /@ #) . A]/16] > 10^-8 &];
    If[Length[hits] =!= 1, -1, Count[hits[[1]], x_ /; x =!= "I"]]];
  ws = Flatten[Table[Module[{P},
     P = KroneckerProduct @@ ReplacePart[ConstantArray[mI, 4], q -> sq[lab]];
     weightOf[U . P . Udag]], {q, 4}, {lab, {"X", "Y", "Z"}}]];
  minw = Min[ws];
  Print["  dense conjugation weights of all 12 single-qubit Paulis: ", ws];
  rCheck["R3c ALL 12 single-qubit Paulis (incl. Y) -> single Pauli of weight >= 3", minw >= 3]];

(* ---------- R4: CF anchors via reviewer's own from-scratch LP -------------- *)
Print["=== R4: CF anchors, reviewer's own AB LP ==="];
Module[{glob, ctxs, rows, myCF, okTs, okLoc, ok225},
  glob = Tuples[{0, 1}, 4];                     (* (a0,a1,b0,b1) *)
  ctxs = Tuples[{0, 1}, 2];                     (* (x,y) *)
  rows = Flatten[Table[Module[{x = xy[[1]], y = xy[[2]]},
      Table[Table[Boole[g[[x + 1]] === a && g[[2 + y + 1]] === b], {g, glob}],
        {a, 0, 1}, {b, 0, 1}]], {xy, ctxs}], 2];
  myCF[s_] := Module[{e, sol},
    e = Flatten[Table[Module[{x = xy[[1]], y = xy[[2]], corr},
        corr = If[x == 1 && y == 1, -s/4, s/4];
        Table[(1 + (-1)^(a + b) corr)/4, {a, 0, 1}, {b, 0, 1}]], {xy, ctxs}]];
    sol = LinearProgramming[-ConstantArray[1., 16], -rows, -N[e],
       ConstantArray[0., 16], Method -> "Simplex"];
    1. - Total[sol]];
  okTs = Abs[myCF[2 Sqrt[2]] - (Sqrt[2] - 1)] < 10^-6;
  okLoc = Abs[myCF[2]] < 10^-7;
  ok225 = Abs[myCF[2.25] - 0.125] < 10^-6;
  Print["  reviewer LP: CF(2sqrt2)=", myCF[2 Sqrt[2]], "  CF(2)=", myCF[2],
    "  CF(2.25)=", myCF[2.25]];
  rCheck["R4a reviewer from-scratch LP reproduces anchors sqrt2-1 / 0 / 0.125", okTs && okLoc && ok225];
  rCheck["R4b builder LP agrees with reviewer LP at 9 grid points",
    And @@ Table[Abs[myCF[s] - DDTCFofSLP[s]] < 10^-6, {s, 2., 4., 0.25}]]];

(* ---------- R5: exact Pauli readout vs dense; carved-pair correlators ------ *)
Print["=== R5: DDTPairExp exact readout vs reviewer dense expectations ==="];
pmat = <|"I" -> mI, "X" -> mX, "Y" -> mY, "Z" -> mZ|>;
Module[{ok},
  SeedRandom[555111];
  ok = And @@ Table[Module[{n = RandomInteger[{3, 8}], tab, ab, v, allok},
    tab = NewGraphStateTableau[n,
      Union[Sort /@ Select[Subsets[Range[n], {2}], RandomReal[] < 0.35 &]]];
    Do[Switch[RandomInteger[{1, 5}],
       1, ApplyH[tab, RandomInteger[{1, n}]],
       2, ApplyS[tab, RandomInteger[{1, n}]],
       3, With[{p = RandomSample[Range[n], 2]}, ApplyCNOT[tab, p[[1]], p[[2]]]],
       4, With[{p = RandomSample[Range[n], 2]}, ApplyCZ[tab, p[[1]], p[[2]]]],
       5, MeasurePauli[tab, RandomInteger[{1, n}], {"X","Y","Z"}[[RandomInteger[{1,3}]]]]],
      {RandomInteger[{4, 25}]}];
    ab = RandomSample[Range[n], 2];
    v = N[StateVectorFromTableau[tab, "Normalized" -> True]];
    allok = And @@ Table[Module[{exG, exD, P},
       exG = DDTPairExp[tab, ab[[1]], ab[[2]], pl[[1]], pl[[2]]];
       P = ConstantArray[mI, n];
       P[[ab[[1]]]] = pmat[pl[[1]]]; P[[ab[[2]]]] = pmat[pl[[2]]];
       exD = Re[Conjugate[v] . applyOp[v, KroneckerProduct @@ P[[ab]], ab, n]];
       Abs[exG - exD] < 10^-9], {pl, DDTHawk15}];
    FreeTableau[tab];
    allok], {12}];
  rCheck["R5a 12 random states x 15 Paulis: exact readout == dense <P> (tol 1e-9)", ok]];

Module[{pairs, bundle, tab, a, b, v, n, exp, T, sv, ok},
  pairs = DDTHawkingSelectPairs[1, 1];
  a = pairs[[1]]["partner"]; b = pairs[[1]]["hawking"];
  bundle = DDTHawkingBuildCarved[1, pairs, "Forced" -> 0]; tab = bundle["tab"];
  n = DDTMeshN[1];
  v = N[StateVectorFromTableau[tab, "Normalized" -> True]];
  exp[pa_, pb_] := Re[Conjugate[v] . applyOp[v,
     KroneckerProduct[pmat[pa], pmat[pb]], {a, b}, n]];
  T = Table[exp[pa, pb], {pa, {"X","Y","Z"}}, {pb, {"X","Y","Z"}}];
  FreeTableau[tab];
  sv = SingularValueList[T];
  Print["  dense carved-pair T = ", Chop[T], "  CHSH_Horodecki = ",
    2 Sqrt[sv[[1]]^2 + sv[[2]]^2]];
  ok = Abs[exp["X","Z"] - 1] < 10^-9 && Abs[exp["Z","X"] - 1] < 10^-9 &&
       Abs[exp["Y","Y"] - 1] < 10^-9 &&
       Abs[2 Sqrt[sv[[1]]^2 + sv[[2]]^2] - 2 Sqrt[2]] < 10^-9;
  rCheck["R5b dense carved pair: <XZ>=<ZX>=<YY>=1, Horodecki CHSH = 2 sqrt2", ok]];

(* ---------- R6: no-disturbance gate catches corrupted pairs --------------- *)
Print["=== R6: no-disturbance Hoeffding gate sensitivity ==="];
ndProbe[reps_, pairs_, builds_, mode_] := Module[
  {hSum = 0, pSum = 0, nShots = builds Length[pairs], bundle, tab, nH, nP, eps},
  Do[bundle = DDTHawkingBuildCarved[reps, pairs, "Forced" -> Automatic];
     tab = bundle["tab"];
     Scan[Function[p,
       Which[mode === "blatant",
           MeasurePauli[tab, p["hawking"], "Z", "ForcedOutcome" -> 0],
         mode === "subtle",
           If[RandomReal[] < 0.2,
             MeasurePauli[tab, p["hawking"], "Z", "ForcedOutcome" -> 0]]];
       hSum += MeasurePauli[tab, p["hawking"], "Z"]["Outcome"];
       pSum += MeasurePauli[tab, p["partner"], "Z"]["Outcome"]], pairs];
     FreeTableau[tab], {builds}];
  nH = N[hSum/nShots]; nP = N[pSum/nShots]; eps = DDTHawkEps[nShots];
  <|"mode" -> mode, "nShots" -> nShots, "nH" -> nH, "nP" -> nP, "eps" -> eps,
    "pass" -> (Abs[nH - 1/2] <= eps && Abs[nP - 1/2] <= eps &&
               Abs[nH - nP] <= 2 eps)|>];
Module[{reps = 30, pairs, clean, blat, subt},
  pairs = DDTHawkingSelectPairs[30, 15];
  SeedRandom[99887766];
  clean = ndProbe[reps, pairs, 140, "clean"];
  blat = ndProbe[reps, pairs, 140, "blatant"];
  subt = ndProbe[reps, pairs, 140, "subtle"];
  Print["  clean:   ", clean];
  Print["  blatant: ", blat];
  Print["  subtle:  ", subt];
  rCheck["R6a clean control PASSES the pre-registered gate", clean["pass"]];
  rCheck["R6b blatant corruption (hawking forced |0>) FAILS the gate", !blat["pass"]];
  rCheck["R6c subtle corruption (20% reset, nH~0.4) FAILS the gate", !subt["pass"]]];

Print[];
Print["REVIEW PROBE TOTAL: ", rPass, " PASS, ", rFail, " FAIL"];
Print["REVIEW PROBE OVERALL: ", If[rFail === 0, "ALL PROBES PASSED", "PROBE FAILURES"]];
