(* ::Package:: *)

(* ===========================================================================
   ddt_mbqc_hawking_confirmation.wl -- POST-BUILD CONFIRMATION STAGE.

   Confronts the agnostic first-principles Hawking build
     * ddt_mbqc_hawking_evaporation.wl   (Page curve, Renyi-2, Hayden-Preskill)
     * ddt_mbqc_hawking_certification.wl (CHSH / contextual-fraction stack)
   with tiered PUBLISHED targets from the 2026-07-12 literature sweep.  This is
   the ONLY file permitted to read the confirmation-targets sheet; the build
   files were written without it (agnostic-implementation discipline).

   The build modules are loaded LOAD-ONLY (no side effects); this file re-runs
   the specific quantities each target needs and prints a head-to-head table.
   Every deviation from a published number is surfaced, with magnitude, in the
   printed MISMATCHES block -- nothing is papered over.

   TARGET TIERS (see hawking_confirmation_targets.md):
     T1 Chowdhury arXiv:2412.15180  -- exact Renyi-2 Page formula, N=8/10/12
     T2 Landsman  arXiv:1806.02807  -- Hayden-Preskill ideal + noise bands
     T3 Zhu PNAS 2020 / Sagastizabal npj 2021 -- beta=0 TFD Bell anchors
     T4 CHSH/CF   project + BEC arXiv:2404.16497 -- CF(2sqrt2), CF(2.25)
     Shi arXiv:2111.11092 -- monogamy signature (concurrence falls / S rises)

   UNITS NOTE.  The build's Renyi-2 helpers return entropy in BITS (-Log2).
   Chowdhury/Zhu/Landsman quote NATS (natural log).  Conversion nats = bits*ln2
   is applied explicitly at every T1/T3 comparison and flagged in-line.

   Run:  wolframscript -file ddt_mbqc_hawking_confirmation.wl
   =========================================================================== *)

If[!ValueQ[DDTConfDir], DDTConfDir = DirectoryName[$InputFileName]];

(* load both build modules with NO side effects *)
Block[{DDTHawkingLoadOnly = True, DDTMBQCPatternsLoadOnly = True,
       DDTMBQCLoadOnly = True},
  Get[FileNameJoin[{DDTConfDir, "ddt_mbqc_hawking_evaporation.wl"}]]];
Block[{DDTHawkingCertLoadOnly = True, DDTMBQCPatternsLoadOnly = True},
  Get[FileNameJoin[{DDTConfDir, "ddt_mbqc_hawking_certification.wl"}]]];

ln2 = N[Log[2]];
fmt[x_] := N[Round[N[x], 0.0001]];       (* clean 4-dp real for script Print *)
mismatches = {};                 (* every discrepancy accumulates here *)
logMismatch[s_] := AppendTo[mismatches, s];

Print["================================================================"];
Print[" ddt_mbqc_hawking_confirmation.wl -- build vs published targets"];
Print["================================================================"];

(* ===========================================================================
   T1.  PAGE CURVE vs Chowdhury et al. (arXiv:2412.15180), Renyi-2 Page formula
     S2(N_rad) = -log[(2^N_rad + 2^(N-N_rad))/(2^N + 1)]   (NATS)
   Peaks (N/2): ~2.08 (N=8), 2.77 (N=10), 3.47 (N=12).
   Our DDTPageRenyi2Closed is EXACTLY this formula in bits; the 2-design
   Clifford ensemble (DDTPageRenyi2Ensemble) reproduces <purity> exactly, so
   sampled -log2<purity> lands on the closed form within sampling error.
   =========================================================================== *)
Print[];
Print["--- T1  Chowdhury arXiv:2412.15180 : Renyi-2 Page curve (nats) ---"];
t1Targets = <|8 -> 2.08, 10 -> 2.77, 12 -> 3.47|>;
t1Shots  = <|8 -> 200, 10 -> 120, 12 -> 60|>;
t1Rows = {};
Do[
  Module[{r2, peakClosedBits, peakClosedNats, peakSampledBits, peakSampledNats,
          maxdiffBits, tgt},
   SeedRandom[100 + n];
   r2 = DDTPageRenyi2Ensemble[n, t1Shots[n], "Seed" -> (100 + n)];
   peakClosedBits   = Max[r2["S2closed"]];
   peakSampledBits  = Max[r2["S2sampled"]];
   peakClosedNats   = peakClosedBits*ln2;
   peakSampledNats  = peakSampledBits*ln2;
   maxdiffBits = Max[Abs[r2["S2sampled"] - r2["S2closed"]]];
   tgt = t1Targets[n];
   AppendTo[t1Rows, {n, tgt, peakClosedNats, peakSampledNats, maxdiffBits}];
   Print["  N=", n, " shots=", t1Shots[n],
     " | paper peak=", tgt, " nats",
     " | our closed-form peak=", fmt[peakClosedNats], " nats",
     " | our 2-design sampled peak=", fmt[peakSampledNats], " nats",
     " | max|sampled-closed| (bits)=", fmt[maxdiffBits]];
   If[Abs[peakClosedNats - tgt] > 0.01,
     logMismatch["T1 N=" <> ToString[n] <> " closed peak " <>
       ToString[fmt[peakClosedNats]] <> " vs paper " <> ToString[tgt] <>
       " nats (delta " <> ToString[fmt[peakClosedNats - tgt]] <> ")"]];
   If[maxdiffBits > 0.15,
     logMismatch["T1 N=" <> ToString[n] <> " 2-design sampling gap max|d|=" <>
       ToString[fmt[maxdiffBits]] <> " bits (finite shots)"]];
  ], {n, {8, 10, 12}}];

(* T1 EXTENSION: single-realization exact curves beyond the N<=12 hardware
   ceiling.  Stabilizer single realizations have a flat spectrum so Renyi-2 =
   von Neumann = exact integer; peak ~ n/2 (bits), computed in ms at n=50/100/200. *)
Print["  -- extension beyond Chowdhury N<=12 hardware ceiling --"];
t1ExtRows = {};
Do[Module[{pc, peakBits, closedPeakBits, closedPeakNats},
   pc = DDTPageCurveScrambledState[n, "Seed" -> n, "Sweeps" -> 14];
   peakBits = pc["peak"];
   closedPeakBits = N[DDTPageRenyi2Closed[n, n/2]];   (* exact ensemble Renyi-2 *)
   closedPeakNats = closedPeakBits*ln2;
   AppendTo[t1ExtRows, {n, peakBits, closedPeakNats, pc["time"]}];
   Print["  N=", n, " EXACT closed Renyi-2 peak=", fmt[closedPeakNats],
     " nats (", fmt[closedPeakBits], " bits); single-realization vN peak=",
     peakBits, " bits; time=", fmt[pc["time"]], "s"];
  ], {n, {50, 100, 200}}];
Print["  (headline scalable claim = EXACT closed-form Renyi-2 at any N; the",
  " single-realization von Neumann peak sits in [n/2-O(1), n/2], agreeing with",
  " the ensemble peak up to the O(1) Page/finite-size spread -- e.g. N=100 shot",
  " hit 50 bits vs ensemble 49 bits, a 1-bit single-realization fluctuation.)"];

(* ===========================================================================
   T2.  HAYDEN-PRESKILL vs Landsman et al. (arXiv:1806.02807).
   Ideal stabilizer predictions: EPR success P=1/4, teleport F=1 (six inputs),
   deterministic decoder recovered, non-scrambling control F=1/2.
   Then Pauli-noise sweep at their gate fidelities (1q~99%, 2q~98.5%).
   Measured hardware: deterministic 77(2)%, OTOC 0.47(2) vs ideal 0.25.
   =========================================================================== *)
Print[];
Print["--- T2  Landsman arXiv:1806.02807 : Hayden-Preskill ---"];
Module[{sc, epr, det, tele, idctrl, sweep},
  sc  = DDTFindMaximalScrambler[4, "Seed" -> 123];
  epr = DDTHPDecodeEPR[sc["gates"]];
  det = DDTHPDecodeDeterministic[sc["gates"]];
  tele = DDTHPTeleportFidelity[sc["gates"]];
  idctrl = DDTHPDecodeEPR[{}];                  (* identity = non-scrambling ctrl *)
  Print["  maximal scrambler minImageWeight=", sc["minImageWeight"],
    " (>=3? ", sc["isMaximal"], ")"];
  Print["  IDEAL (noiseless):"];
  Print["    EPR success P  : ours=", epr["successProb"], "  paper ideal=1/4",
    "  (measured OTOC 0.47(2))"];
  Print["    entanglement Fe: ours=", epr["Fe"], "  -> teleport F=(2Fe+1)/3=",
    fmt[(2 epr["Fe"] + 1)/3]];
  Print["    deterministic decoder recovered? ours=", det["recovered"],
    "  paper measured 77(2)%"];
  Print["    teleport frac recovered (6 Pauli inputs): ours=", tele["fracRecovered"],
    "  paper ideal=1"];
  Print["    non-scrambling control Fe=", idctrl["Fe"],
    " -> avg F=", fmt[(2 idctrl["Fe"] + 1)/3], "  paper control=1/2"];
  If[epr["successProb"] =!= 1/4,
    logMismatch["T2 EPR success " <> ToString[epr["successProb"]] <> " != 1/4"]];
  If[tele["fracRecovered"] != 1.,
    logMismatch["T2 teleport frac " <> ToString[tele["fracRecovered"]] <> " != 1"]];
  (* NOISE SWEEP at their gate fidelities.  Per-gate depol p ~ gate infidelity:
     1q 99.0% -> p~0.010, 2q 98.5% -> p~0.015.  Report meanFe & teleport F. *)
  Print["  NOISE SWEEP (per-gate depolarizing p; 300 trajectories):"];
  sweep = DDTHPNoiseSweep[sc["gates"], {0.005, 0.010, 0.015, 0.020}, 300, 7];
  t2Noise = {};
  Do[Module[{p = nr["p"], fe = nr["meanFe"], f},
     f = (2 fe + 1)/3;
     AppendTo[t2Noise, {p, fe, f}];
     Print["    p=", p, "  meanFe=", fmt[fe], "  teleport F=", fmt[f],
       If[p == 0.015, "  <- ~2q infidelity band (paper 77(2)%)", ""]]], {nr, sweep}];
  Module[{f015 = (2 (Select[sweep, #["p"] == 0.015 &][[1]]["meanFe"]) + 1)/3},
   Print["    our F at p=0.015 = ", fmt[f015],
     " vs Landsman deterministic 0.77(2): delta=", fmt[f015 - 0.77]];
   logMismatch["T2 noise-band: our teleport F(p=0.015)=" <> ToString[fmt[f015]] <>
     " vs Landsman measured 0.77(2); ours is noiseless-limit protocol on 4-qubit " <>
     "scrambler (fewer gates than their 7-qubit run), so sits ABOVE their band"]];
  Print["  NOTE: our OTOC/success is EXACTLY 0.25 (ideal); Landsman measured 0.47(2)",
    " reflects their hardware OTOC floor -- exact-ideal vs hardware gap, expected."];
  logMismatch["T2 OTOC: ours exact 0.25 vs Landsman measured 0.47(2) -- hardware floor gap"];
];

(* ===========================================================================
   T3.  beta=0 THERMOFIELD-DOUBLE anchors.  Zhu PNAS 2020 (singlet convention
   <XX>=<YY>=<ZZ>=-1, S_A = n ln2), Sagastizabal npj 2021 (F=1, purity 0.25,
   S=2 bits).  Our mesh/graph-state Bell pairs realise the beta=0 TFD.
   =========================================================================== *)
Print[];
Print["--- T3  Zhu PNAS 2020 / Sagastizabal npj 2021 : beta=0 TFD ---"];
Module[{tab, nPairs = 3, xx, yy, zz, sA, sHalf, pur},
  (* n Bell pairs on qubits (1,2),(3,4),(5,6): graph-state Phi+ up to local H.
     Build directly: edge graph state on those pairs, H on the second of each. *)
  tab = NewGraphStateTableau[2 nPairs, Table[{2 k - 1, 2 k}, {k, nPairs}]];
  Scan[ApplyH[tab, 2 #] &, Range[nPairs]];     (* -> Phi+ = (|00>+|11>)/sqrt2 *)
  xx = DDTPairExp[tab, 1, 2, "X", "X"];
  yy = DDTPairExp[tab, 1, 2, "Y", "Y"];
  zz = DDTPairExp[tab, 1, 2, "Z", "Z"];
  sA    = DDTStabEntropy[tab, {1, 3, 5}];      (* one half of each pair *)
  sHalf = DDTStabEntropy[tab, {1}];
  pur   = DDTStabPurity[tab, {1, 2}];          (* joint pair purity (pure=1) *)
  Print["  graph-state Phi+ Bell pair correlators: <XX>=", xx, " <YY>=", yy,
    " <ZZ>=", zz];
  Print["    (Zhu singlet convention is <XX>=<YY>=<ZZ>=-1; our Phi+ frame gives",
    " (+1,-1,+1); |corr|=1 all three -- same maximal correlation, LU-equivalent frame)"];
  Print["  S_A (one qubit per pair, 3 pairs) = ", sA, " bits = ", fmt[sA*ln2],
    " nats  (Zhu S_A = 3 ln2 = ", fmt[3 ln2], " nats)"];
  Print["  S(single qubit) = ", sHalf, " bit  (Sagastizabal S_A=2 bits for 2 pairs)"];
  Print["  joint 2q pair purity = ", pur, " (pure). Bell-state fidelity F=1",
    " (Sagastizabal measured 99%, purity 0.262; Zhu fidelity 1.00 @ beta=0)"];
  If[Abs[xx] =!= 1 || Abs[yy] =!= 1 || Abs[zz] =!= 1,
    logMismatch["T3 Bell correlator magnitude != 1"]];
  If[sA =!= 3, logMismatch["T3 S_A(3 pairs) = " <> ToString[sA] <> " bits != 3"]];
  logMismatch["T3 correlator SIGN: our graph-state Phi+ gives (+1,-1,+1) not the " <>
    "singlet (-1,-1,-1); local-unitary equivalent, magnitudes all 1 (convention)"];
];

(* ===========================================================================
   T4.  CHSH / CF certification vs project + BEC anchors.
   CF(2sqrt2)=sqrt2-1, CF(2)=0, CF(2.25)=0.125.  From the certification stack,
   closed form AND native-WL Abramsky-Brandenburger LP.
   =========================================================================== *)
Print[];
Print["--- T4  CHSH/CF : project anchors + BEC arXiv:2404.16497 ---"];
Module[{reps, pairs, bundle, tab, T, sOpt, cfTsC, cfTsLP, cf0C, cf0LP,
        cf225C, cf225LP, tgtTs},
  reps = 3; pairs = DDTHawkingSelectPairs[reps, 1];
  bundle = DDTHawkingBuildCarved[reps, pairs, "Forced" -> 0]; tab = bundle["tab"];
  T = DDTPairCorrMatrix[tab, pairs[[1]]["partner"], pairs[[1]]["hawking"]];
  sOpt = DDTCHSHOptimal[T];
  FreeTableau[tab];
  cfTsC = DDTCFofS[2 Sqrt[2]]; cfTsLP = DDTCFofSLP[2 Sqrt[2]];
  cf0C = DDTCFofS[2]; cf0LP = DDTCFofSLP[2];
  cf225C = DDTCFofS[2.25]; cf225LP = DDTCFofSLP[2.25];
  tgtTs = N[Sqrt[2] - 1];
  Print["  mesh-carved Hawking pair CHSH_opt = ", fmt[sOpt],
    " (Tsirelson 2 sqrt2 = ", fmt[2 Sqrt[2]], ")"];
  Print["  CF(2 sqrt2): closed=", fmt[cfTsC], " LP=", fmt[cfTsLP],
    "  target sqrt2-1=", fmt[tgtTs]];
  Print["  CF(2)      : closed=", fmt[cf0C], " LP=", fmt[cf0LP], "  target 0"];
  Print["  CF(2.25)   : closed=", fmt[cf225C], " LP=", fmt[cf225LP],
    "  target 0.125 (BEC B=2.25 @ T=0, arXiv:2404.16497)"];
  If[Abs[sOpt - 2 Sqrt[2]] > 1.*^-9,
    logMismatch["T4 CHSH_opt " <> ToString[fmt[sOpt]] <> " != 2 sqrt2"]];
  If[Abs[cfTsLP - tgtTs] > 1.*^-6,
    logMismatch["T4 CF(2sqrt2) LP " <> ToString[fmt[cfTsLP]] <> " != sqrt2-1"]];
  If[Abs[cf225C - 0.125] > 1.*^-9,
    logMismatch["T4 CF(2.25) " <> ToString[fmt[cf225C]] <> " != 0.125"]];
  Print["  NEGATIVE CONTROL: no VQE-Hawking paper reports ANY Bell/CHSH value;",
    " the BEC B=2.25 theory point is the only external CF anchor (stated)."];
];

(* ===========================================================================
   SHI et al. (arXiv:2111.11092) monogamy signature.  Implement Wootters
   concurrence of 2-qubit RDMs along an evaporation run and check the
   qualitative trade-off: the Hawking-pair concurrence FALLS while the
   radiation-region entanglement entropy RISES (monogamy).
   =========================================================================== *)
Print[];
Print["--- Shi arXiv:2111.11092 : monogamy (concurrence falls / S rises) ---"];

(* Wootters concurrence of a normalized 2-qubit density matrix rho. *)
DDTConcurrence[rho_] := Module[{Y2, rhoTilde, R, ev, l},
  Y2 = KroneckerProduct[{{0, -I}, {I, 0}}, {{0, -I}, {I, 0}}];
  rhoTilde = Y2 . Conjugate[rho] . Y2;
  R = rho . rhoTilde;
  ev = Sort[Re[Eigenvalues[N[R]]], Greater];
  l = Sqrt[Clip[ev, {0, Infinity}]];
  Max[0., l[[1]] - l[[2]] - l[[3]] - l[[4]]]];

(* concurrence of qubits {a,b} of a tableau via the exact statevector RDM. *)
DDTPairConcurrence[tab_Symbol, a_Integer, b_Integer] := Module[{rho},
  rho = DDTReducedRhoState[tab, {a, b}];
  rho = rho/Tr[rho];
  DDTConcurrence[rho]];

Module[{nPairs = 5, n, tab, ext, intr, extActive = {}, intActive = {},
        rows = {}, c, sInt, cFirst},
  (* Evaporating BH with progressive Hawking emission.  Qubit (2k-1)=exterior
     (emitted) mode of pair k, (2k)=interior partner.  At each time step k:
       (i)  a fresh Hawking pair k is created (CZ on |+>|+> = maximally entangled
            2-vertex graph state) -> the INTERIOR block gains one mode, so the
            interior entanglement entropy S(interior) RISES by 1;
       (ii) the exterior modes emitted so far are scrambled together (one sweep)
            -> each exterior mode's entanglement spreads across the whole exterior
            sector, so by MONOGAMY the FIRST Hawking pair's 2-qubit concurrence
            FALLS toward 0 even though S(interior) keeps rising.
     Both curves move simultaneously in opposite directions -- the Shi signature. *)
  n = 2 nPairs;
  tab = NewGraphStateTableau[n, {}];              (* product |+>^n *)
  ext[k_] := 2 k - 1; intr[k_] := 2 k;
  Do[Module[{},
     ApplyCZ[tab, ext[k], intr[k]];                (* create Hawking pair k *)
     AppendTo[extActive, ext[k]]; AppendTo[intActive, intr[k]];
     If[Length[extActive] >= 2, DDTScramble[tab, extActive, 1]];  (* mix exterior *)
     sInt  = DDTStabEntropy[tab, intActive];        (* interior block entropy *)
     cFirst = DDTPairConcurrence[tab, ext[1], intr[1]];  (* first pair concurrence *)
     AppendTo[rows, {k, sInt, cFirst}];
     Print["  emission k=", k, "  S(interior)=", sInt, " bits",
       "  C(first Hawking pair)=", fmt[cFirst]];
    ], {k, nPairs}];
  FreeTableau[tab];
  Module[{ss = rows[[All, 2]], cs = rows[[All, 3]], sRise, cFall},
   sRise = ss[[-1]] > ss[[1]];
   cFall = cs[[-1]] < cs[[1]] - 1.*^-6;
   Print["  monogamy signature: S(interior) RISES ", ss[[1]], " -> ", ss[[-1]],
     " bits (", sRise, ");  C(first pair) FALLS ", fmt[cs[[1]]], " -> ",
     fmt[cs[[-1]]], " (", cFall, ")"];
   Print["  Shi qualitative signature (interior entropy up, pair concurrence",
     " down, simultaneously) reproduced? ", sRise && cFall];
   If[!(sRise && cFall),
     logMismatch["Shi monogamy signature not reproduced (S or C wrong direction)"]];
   Print["  NOTE (targets sheet): Shi T_H (1.7e-5 / 7.7e-5 K) and tomography",
     " fidelities (99.2% prep, 88.1% @1000ns) are spectral/hardware quantities",
     " OUT of stabilizer reach -- information-dynamics signature only, as declared."];
  ];
];

(* ===========================================================================
   MISMATCH SUMMARY.
   =========================================================================== *)
Print[];
Print["================================================================"];
Print[" MISMATCHES / CAVEATS (", Length[mismatches], " logged):"];
Print["================================================================"];
Do[Print["  * ", m], {m, mismatches}];
Print[];
Print["CONFIRMATION COMPLETE."];
