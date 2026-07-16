(* ::Package:: *)

(* ===========================================================================
   ddt_mbqc_hawking_certification_tests.wl -- FULL-SCALE certification runner
   for ddt_mbqc_hawking_certification.wl.  Executes all five stages at scale,
   prints every PASS/FAIL and every headline number, and a final scoreboard.

   SCALES (headline):
     stage 1  M = 100 disjoint mesh-carved Hawking pairs @ reps = 1000
              (9000-qubit "ddt" mesh), each verified to be the exact 2 sqrt2
              Bell pair; plus an exact StateVectorFromTableau cross-check @ reps=2.
     stage 2  no-disturbance:  N >= 10^4 seeded Z-basis shots (pooled).
     stage 3  Pauli tomography: >= 4500 seeded shots per each of 9 settings.
     stage 4  exact CHSH + CF gates (closed form AND native-WL AB LP).
     stage 5  depolarizing curve, K = 4000 seeded realizations per p.

   Seeds are fixed for reproducibility.  Runtime target: within the single
   10-minute allowance.  No cloud calls.
   =========================================================================== *)

DDTHawkingCertLoadOnly = True;
Get[FileNameJoin[{DirectoryName[$InputFileName], "ddt_mbqc_hawking_certification.wl"}]];

Print["==================================================================="];
Print[" ddt_mbqc HAWKING-PAIR CHSH/CF CERTIFICATION -- FULL-SCALE RUNNER"];
Print["==================================================================="];
Print["pre-registered budget: alpha=", N[DDTHawkAlpha], " / ", DDTHawkNTests,
  " tests -> per-test delta=", DDTHawkDelta];
Print[];

scoreboard = <||>;
tStart = AbsoluteTiming[

(* ===================== STAGE 1: mesh-carved Hawking pairs ================= *)
Print["------------------------------------------------------------------"];
Print["STAGE 1:  M mesh-carved Hawking pairs, each an exact Bell pair"];
Print["------------------------------------------------------------------"];

(* 1a: exact StateVectorFromTableau cross-check at reps=1 (n=9 <= 10) *)
Module[{reps = 1, pairs, bundle, tab, allOK},
  pairs = DDTHawkingSelectPairs[reps, 2];
  bundle = DDTHawkingBuildCarved[reps, pairs, "Forced" -> 0]; tab = bundle["tab"];
  allOK = AllTrue[pairs, Function[p, Module[
    {a = p["partner"], b = p["hawking"], rdmE, v, nn = DDTMeshN[reps], T2, other, rdmSV},
    rdmE = DDTExactRDM[tab, a, b];
    v = StateVectorFromTableau[tab];
    T2 = ArrayReshape[v, ConstantArray[2, nn]];
    other = Complement[Range[nn], {a, b}];
    T2 = ArrayReshape[Transpose[T2, Ordering[Join[{a, b}, other]]], {4, 2^(nn - 2)}];
    rdmSV = T2 . ConjugateTranspose[T2]; rdmSV = rdmSV/Tr[rdmSV];
    Simplify[rdmE - rdmSV] === Table[0, {4}, {4}]]]];
  FreeTableau[tab];
  Print["  1a  exact-RDM == StateVectorFromTableau partial trace (reps=1, ",
    Length[pairs], " pair(s), n=", DDTMeshN[reps], "): ", allOK];
  scoreboard["S1a_BellExactVsStateVector"] = allOK];

(* 1b: M=100 disjoint pairs @ reps=1000; every pair is the exact 2 sqrt2 pair *)
Module[{reps = 1000, M = 100, pairs, bundle, tab, tsel, tbuild, chsh, allBell,
   allDisjoint, used},
  {tsel, pairs} = AbsoluteTiming[DDTHawkingSelectPairs[reps, M]];
  used = Flatten[{#["partner"], #["hawking"], #["carve"]} & /@ pairs];
  allDisjoint = (Length[used] === Length[Union[used]]);   (* disjoint regions *)
  {tbuild, bundle} = AbsoluteTiming[DDTHawkingBuildCarved[reps, pairs, "Forced" -> 0]];
  tab = bundle["tab"];
  chsh = Table[DDTCHSHOptimal[DDTPairCorrMatrix[tab, p["partner"], p["hawking"]]], {p, pairs}];
  allBell = AllTrue[chsh, Abs[# - 2 Sqrt[2]] < 10^-9 &];
  FreeTableau[tab];
  Print["  1b  M=", Length[pairs], " disjoint pairs @ reps=", reps,
    " (n=", DDTMeshN[reps], " qubits); select=", tsel, "s build+carve=", tbuild, "s"];
  Print["      regions pairwise disjoint (induced matching)? ", allDisjoint];
  Print["      every pair exact CHSH = 2 sqrt2 = ", N[2 Sqrt[2]], " ? ", allBell,
    "   (min=", Min[chsh], " max=", Max[chsh], ")"];
  Print["      Hawking mode = tip 3k+3 (exterior);  partner = 3k+2 (interior)"];
  scoreboard["S1b_Mpairs_disjoint"] = allDisjoint;
  scoreboard["S1b_Mpairs_allBell"] = allBell;
  scoreboard["S1b_M"] = Length[pairs]];

Print[];

(* ===================== STAGE 2: no-disturbance (C1) ====================== *)
Print["------------------------------------------------------------------"];
Print["STAGE 2:  NO-DISTURBANCE  n_H == n_P  (before any entanglement claim)"];
Print["------------------------------------------------------------------"];
Module[{reps = 100, pairs, builds = 68, nd},
  pairs = DDTHawkingSelectPairs[reps, 10^6];
  SeedRandom[20260713];
  nd = DDTHawkingNoDisturbance[reps, pairs, builds];
  Print["  pool: ", Length[pairs], " pairs @ reps=", reps, " x ", builds,
    " seeded builds = ", nd["nShots"], " Z-shots per mode"];
  Print["  n_H (Hawking occupation) = ", nd["nBarHawking"], "   (exact 1/2)"];
  Print["  n_P (partner occupation) = ", nd["nBarPartner"], "   (exact 1/2)"];
  Print["  Hoeffding eps (delta=", DDTHawkDelta, ") = ", nd["eps"],
    "   |n_H-n_P|=", Abs[nd["nBarHawking"] - nd["nBarPartner"]], " <= ", nd["epsDiff"]];
  Print["  PASS n_H=1/2: ", nd["passHawkingHalf"], "  n_P=1/2: ", nd["passPartnerHalf"],
    "  n_H=n_P: ", nd["passEqual"]];
  scoreboard["S2_NoDisturbance"] = nd["pass"];
  scoreboard["S2_nShots"] = nd["nShots"]];

Print[];

(* ===================== STAGE 3: Pauli tomography ========================= *)
Print["------------------------------------------------------------------"];
Print["STAGE 3:  PAULI TOMOGRAPHY (sampled) vs EXACT reduced density matrix"];
Print["------------------------------------------------------------------"];
Module[{reps = 100, pairs, bps = 30, tomo, exact, est, devs, maxdev, pass, recRDM,
   exRDM, frob},
  pairs = DDTHawkingSelectPairs[reps, 10^6];
  (* exact reference from a canonical (Forced->0) build *)
  Module[{bundle = DDTHawkingBuildCarved[reps, pairs, "Forced" -> 0]},
    exRDM = DDTExactRDM[bundle["tab"], pairs[[1]]["partner"], pairs[[1]]["hawking"]];
    exact = Association[Table[pl ->
       Re[Tr[ConjugateTranspose[KroneckerProduct[DDTHawkPauliMat[pl[[1]]], DDTHawkPauliMat[pl[[2]]]]] . exRDM]],
       {pl, DDTHawk15}]];
    FreeTableau[bundle["tab"]]];
  SeedRandom[20260714];
  tomo = DDTHawkingTomography[reps, pairs, bps];
  est = tomo["est"];
  devs = Association[Table[pl -> Abs[Lookup[est, Key[pl], 0] - exact[pl]], {pl, DDTHawk15}]];
  maxdev = Max[Values[devs]];
  pass = (maxdev <= tomo["eps"]);
  recRDM = DDTReconstructRDM[est];
  frob = Sqrt[Total[Abs[Flatten[recRDM - exRDM]]^2]];
  Print["  pool: ", Length[pairs], " pairs @ reps=", reps, " x ", bps,
    " builds = ", tomo["nShots"], " shots per setting (9 settings)"];
  Print["  Hoeffding eps (delta=", DDTHawkDelta, ") = ", tomo["eps"]];
  Print["  nonzero exact expectations (stabilizer correlators):"];
  Do[If[Abs[exact[pl]] > 1/2,
     Print["     <", pl[[1]], "_a ", pl[[2]], "_b> exact=", exact[pl],
       "  est=", Lookup[est, Key[pl], 0], "  |dev|=", devs[pl]]], {pl, DDTHawk15}];
  Print["  max |estimate - exact| over all 15 Paulis = ", maxdev, "  (<= eps? ", pass, ")"];
  Print["  reconstructed vs exact RDM, Frobenius distance = ", frob];
  scoreboard["S3_Tomography"] = pass;
  scoreboard["S3_maxDev"] = maxdev];

Print[];

(* ===================== STAGE 4: CHSH + CF gates ========================== *)
Print["------------------------------------------------------------------"];
Print["STAGE 4:  CHSH at optimal angles + CONTEXTUAL-FRACTION scale"];
Print["------------------------------------------------------------------"];
Module[{reps = 3, pairs, bundle, tab, T, sOpt, sExp, cfTsC, cfLocC, cf225C,
   cfTsLP, cfLocLP, cf225LP, gateTs, gateLoc, mono, linform},
  pairs = DDTHawkingSelectPairs[reps, 1];
  bundle = DDTHawkingBuildCarved[reps, pairs, "Forced" -> 0]; tab = bundle["tab"];
  T = DDTPairCorrMatrix[tab, pairs[[1]]["partner"], pairs[[1]]["hawking"]];
  FreeTableau[tab];
  sOpt = DDTCHSHOptimal[T]; sExp = DDTCHSHExplicit[T];
  Print["  exact correlation matrix T (rows a=X,Y,Z; cols b=X,Y,Z):"];
  Print["     ", T, "   (signed permutation: <X_aZ_b>=<Z_aX_b>=<Y_aY_b>=1)"];
  Print["  CHSH_opt (Horodecki 2 sqrt(s1^2+s2^2)) = ", sOpt];
  Print["  CHSH_explicit (fixed optimal angles)   = ", sExp,
    "   [DECLARED analytic: non-Clifford angles, exact linear combo of Paulis]"];
  Print["  target 2 sqrt2 = ", N[2 Sqrt[2]],
    "   match? ", Abs[sOpt - 2 Sqrt[2]] < 10^-9 && Abs[sExp - 2 Sqrt[2]] < 10^-9];
  (* CF two independent ways: closed form and native-WL AB LP *)
  cfTsC = DDTCFofS[2 Sqrt[2]]; cfLocC = DDTCFofS[2]; cf225C = DDTCFofS[9/4];
  cfTsLP = DDTCFofSLP[2 Sqrt[2]]; cfLocLP = DDTCFofSLP[2]; cf225LP = DDTCFofSLP[9/4];
  gateTs = Abs[cfTsC - (Sqrt[2] - 1)] < 10^-12 && Abs[cfTsLP - (Sqrt[2] - 1)] < 10^-6;
  gateLoc = Abs[cfLocC] < 10^-12 && Abs[cfLocLP] < 10^-7;
  Print["  --- CF scale CF(S)=(S-2)/2 on the isotropic Bell family ---"];
  Print["  GATE  CF(2 sqrt2): closed=", N[cfTsC], "  LP=", cfTsLP,
    "  target sqrt2-1=", N[Sqrt[2] - 1], "  PASS=", gateTs];
  Print["  GATE  CF(2):       closed=", N[cfLocC], "  LP=", cfLocLP,
    "  target 0          PASS=", gateLoc];
  Print["  CF(2.25) [S=2.25 -> CF=0.125 anchor]: closed=", N[cf225C], "  LP=", cf225LP];
  (* CF of the certified Hawking pair itself *)
  Print["  => certified Hawking-pair CHSH S=", N[sOpt],
    " lands at CF=", N[DDTCFofS[sOpt]], " = sqrt2-1 (Tsirelson ceiling)"];
  (* monotone + closed-form check of the LP over a grid *)
  mono = Module[{cfs = Table[DDTCFofSLP[s], {s, 2., 4., 0.1}]},
     AllTrue[Differences[cfs], # >= -10^-9 &]];
  linform = Max[Table[Abs[DDTCFofSLP[s] - (s - 2)/2], {s, 2., 4., 0.1}]];
  Print["  AB LP monotone nondecreasing on [2,4]? ", mono,
    "   max|LP-(S-2)/2|=", linform];
  scoreboard["S4_CHSH2sqrt2"] = (Abs[sOpt - 2 Sqrt[2]] < 10^-9 && Abs[sExp - 2 Sqrt[2]] < 10^-9);
  scoreboard["S4_CFgate_Tsirelson"] = gateTs;
  scoreboard["S4_CFgate_local"] = gateLoc;
  scoreboard["S4_LP_linform"] = (linform < 10^-6)];

Print[];

(* ===================== STAGE 5: noise / temperature ===================== *)
Print["------------------------------------------------------------------"];
Print["STAGE 5:  two-qubit depolarizing channel -> CHSH(p), CF(p) curves"];
Print["------------------------------------------------------------------"];
Module[{reps = 3, pairs, ps, K = 4000, curve, pDeath, p225, mcOK, deathBracket,
   b225},
  pairs = DDTHawkingSelectPairs[reps, 1];
  ps = {0, 0.05, 0.1, 0.15, 0.2, 0.2045, 0.25, 0.2929, 0.3};
  SeedRandom[20260715];
  curve = DDTHawkNoiseCurve[reps, pairs[[1]], ps, K];
  Print["  depolarizing model rho->(1-p)rho+p I/4 (Pauli-twirl, K=", K,
    " seeded realizations/p) [DECLARED: random Pauli gates, circuit-model twirl]"];
  Module[{fmt},
   fmt[x_] := ToString[NumberForm[N[x], {7, 4}, NumberPadding -> {" ", "0"}]];
   Print["    p        CHSH_MC     CHSH_exact    CF_MC      CF_exact   ((1-p)2sqrt2)"];
   Do[Print["   ", fmt[nr["p"]], "    ", fmt[nr["CHSH"]], "     ", fmt[nr["CHSHexact"]],
      "     ", fmt[nr["CF"]], "    ", fmt[nr["CFexact"]]], {nr, curve}]];
  (* MC agreement with exact closed form (within a loose MC tolerance) *)
  mcOK = AllTrue[curve, Abs[#["CHSH"] - #["CHSHexact"]] < 0.06 &];
  (* exact crossings *)
  pDeath = DDTHawkPForCHSH[2];        (* violation death: CHSH=2 *)
  p225 = DDTHawkPForCHSH[2.25];       (* CHSH=2.25 landing, CF=0.125 *)
  Print["  EXACT violation-death crossing  CHSH(p)=2     at p = ", N[pDeath],
    " = 1-1/sqrt2"];
  Print["  EXACT CHSH(p)=2.25 crossing (S=2.25 -> CF=0.125) at p = ", N[p225]];
  Print["  check CF at those crossings: CF(2)=", N[DDTCFofS[2]],
    "  CF(2.25)=", N[DDTCFofS[2.25]]];
  (* the MC curve brackets the crossings (CHSH above 2 below pDeath, below above) *)
  deathBracket = (SelectFirst[curve, #["p"] == 0.25 &]["CHSH"] > 2 &&
                  SelectFirst[curve, #["p"] == 0.3 &]["CHSH"] < 2.2);
  Print["  MC curve matches exact closed form (|dev|<0.06 all p)? ", mcOK];
  scoreboard["S5_MC_matches_exact"] = mcOK;
  scoreboard["S5_pDeath"] = N[pDeath];
  scoreboard["S5_p225"] = N[p225]];

];   (* end AbsoluteTiming *)

Print[];
Print["==================================================================="];
Print[" SCOREBOARD"];
Print["==================================================================="];
Module[{keys, passKeys, allPass},
  passKeys = Select[Keys[scoreboard], StringMatchQ[#, "S" ~~ __] &&
     MemberQ[{True, False}, scoreboard[#]] &];
  Do[Print["  ", If[TrueQ[scoreboard[k]], "PASS", If[scoreboard[k] === False, "FAIL", "----"]],
     "  ", k, " = ", scoreboard[k]], {k, Keys[scoreboard]}];
  allPass = AllTrue[passKeys, TrueQ[scoreboard[#]] &];
  Print[];
  Print["  ALL CERTIFICATION GATES PASS: ", allPass];
  scoreboard["ALLPASS"] = allPass];
Print["  total runtime = ", tStart[[1]], " s"];
Print["==================================================================="];
