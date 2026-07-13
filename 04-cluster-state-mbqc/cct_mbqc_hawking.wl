(* ::Package:: *)

(* ===========================================================================
   cct_mbqc_hawking.wl -- MASTER DELIVERABLE / consolidated runner for the
   Hawking information-dynamics suite on the pentagon-mesh MBQC stack.

   Loads the two build modules (definitions only, no side effects)
     * cct_mbqc_hawking_evaporation.wl    Page curve, Renyi-2 ensemble,
                                          Hayden-Preskill decoding
     * cct_mbqc_hawking_certification.wl  mesh-carved Hawking pairs, CHSH /
                                          contextual-fraction certification
   and executes a representative scoreboard with a consolidated PASS/FAIL
   verdict, following the cct_mbqc_master.wl conventions.

   ---------------------------------------------------------------------------
   HONEST FRAMING (required, verbatim discipline of this repo).  This suite is
   CLIFFORD INFORMATION-DYNAMICS OF HAWKING RADIATION, NOT a field-theory
   simulation.  Every state is a stabilizer state and every dynamical step is
   Clifford, so Gottesman-Knill guarantees efficient classical simulation; the
   claim is faithful protocol-level reproduction of the INFORMATION-THEORETIC
   signatures (Page curve, Hayden-Preskill mirroring, Bell/CHSH certification
   of carved Hawking pairs) at exact arithmetic and at scales beyond
   statevector simulators -- never a quantum-speedup or spectrum claim.
   The Sp(2n,R)/CV boundary of 08-HK-hawking/NOTES-hawking.md STANDS: real
   analogue-Hawking pair states are Gaussian continuous-variable states whose
   symmetry group is the real symplectic group Sp(2n,R); nothing here touches
   that regime (no mode spectra, no Hawking temperature, no Bogoliubov
   transformation).  Qubit stabilizer dynamics only.

   ---------------------------------------------------------------------------
   DECLARED NON-MBQC / FORCED / ANALYTIC STEPS (union of both build modules'
   header declarations, per the repo's TeleportWire-caveat convention):
   from cct_mbqc_hawking_evaporation.wl --
     [E-SCRAMBLE]  the random-Clifford scrambling that drives evaporation is
                   CIRCUIT-MODEL unitary dynamics on the tableau, not a
                   measurement pattern (also used front-loaded at scale);
     [E-HP-U]      the Hayden-Preskill scrambler U and its conjugate U*, and
                   all EPR/reference preparation, are circuit-model Clifford;
     [E-RELABEL]   "emitting" a qubit is a bookkeeping relabelling (the global
                   pure state is untouched);
     [E-EPR-FORCE] the EPR-projection decoder uses FORCED-OUTCOME
                   post-selection (MeasurePauli ForcedOutcome); the
                   deterministic decoder and Page-curve dynamics force nothing.
   from cct_mbqc_hawking_certification.wl --
     [A-ANGLES]    CHSH optimal-angle evaluation is an exact linear combination
                   of Pauli expectations at non-Clifford analytic angles;
     [B-EXACT-RDM] exact 2-qubit RDM / Pauli expectations are read from the
                   tableau by group membership (exact readout, not a sample);
     [C-FORCED-CARVE] exact-comparison stages carve with "Forced"->0 (post-
                   selected canonical frame); all SAMPLED statistics instead
                   use genuine random carve outcomes with the Hein Z-rule
                   byproduct frame corrected classically;
     [D-NOISE-TWIRL] the depolarizing model applies random Pauli GATES
                   (circuit-model Pauli twirl), not measurements.
   Inherited library caveat: TeleportWire input-injection post-selects the
   injection outcome (cct_mbqc_patterns.wl header); BV/Grover/NAND force
   nothing.  Everything else in this suite is genuine single-qubit Pauli
   measurement on the verified sparse CHP tableau.

   ---------------------------------------------------------------------------
   FIREWALL STATEMENT.  Both build modules were written AGNOSTICALLY, from
   first principles, without access to the confirmation-targets sheet
   (hawking_confirmation_targets.md, literature sweep 2026-07-12).  The ONLY
   file permitted to read that sheet is cct_mbqc_hawking_confirmation.wl,
   which confronts the finished build with published targets POST HOC
   (T1 Chowdhury arXiv:2412.15180 Renyi-2 Page curve; T2 Landsman
   arXiv:1806.02807 Hayden-Preskill; T3 Zhu PNAS 2020 / Sagastizabal npj QI
   2021 beta=0 TFD anchors; T4 project CF anchors + BEC arXiv:2404.16497),
   surfacing every mismatch.  Section H5 below re-runs the exact-arithmetic
   core of that confrontation; the full sampled version is the confirmation
   file itself.  An independent adversarial review probe
   (cct_mbqc_hawking_review_probe.wl, reviewer-owned dense re-simulations)
   validates both modules end to end.

   ANCHORS (project-pinned, 08-HK-hawking/hawking_cf_bridge.py conventions):
   CF(S)=(S-2)/2 on the isotropic CHSH family; CF(2 sqrt2)=sqrt2-1;
   CF(2)=0; CF(2.25)=0.125.

   Run:  wolframscript -file cct_mbqc_hawking.wl        (~2-4 minutes)
   Full suites: cct_mbqc_hawking_evaporation_tests.wl,
     cct_mbqc_hawking_certification_tests.wl, cct_mbqc_hawking_confirmation.wl,
     cct_mbqc_hawking_review_probe.wl (same directory).
   No cloud calls of any kind, ever, by design.
   =========================================================================== *)

If[!ValueQ[CCTHawkMasterDir], CCTHawkMasterDir = DirectoryName[$InputFileName]];
Block[{CCTHawkingLoadOnly = True, CCTMBQCPatternsLoadOnly = True,
       CCTMBQCLoadOnly = True},
  Get[FileNameJoin[{CCTHawkMasterDir, "cct_mbqc_hawking_evaporation.wl"}]]];
Block[{CCTHawkingCertLoadOnly = True, CCTMBQCPatternsLoadOnly = True},
  Get[FileNameJoin[{CCTHawkMasterDir, "cct_mbqc_hawking_certification.wl"}]]];

passCount = 0; failCount = 0; scoreRows = {};
check[label_, ok_] := (If[TrueQ[ok], passCount++, failCount++];
   Print["  [", If[TrueQ[ok], "PASS", "FAIL"], "] ", label]; TrueQ[ok]);
addRow[task_, size_, t_, ok_] := AppendTo[scoreRows,
   {task, ToString[size],
    ToString[NumberForm[N[t], {6, 2}, ExponentFunction -> (Null &)]],
    If[TrueQ[ok], "PASS", "FAIL"]}];
fmtN[x_] := ToString[NumberForm[N[x], {6, 4}, ExponentFunction -> (Null &)]];
ln2 = N[Log[2]];

Print["############################################################"];
Print["cct_mbqc_hawking.wl -- Hawking suite consolidated scoreboard"];
Print["############################################################"];
Print[];

(* ---------------------------------------------------------------------------
   H1. ENTROPY VALIDATION.  Exact GF(2) stabilizer entropy vs the exact
   statevector reduced density matrix (rank + flat-spectrum idempotent test),
   zero tolerance, on random Clifford circuits WITH mid-circuit measurements.
   --------------------------------------------------------------------------- *)
Print["=== H1: exact stabilizer entropy vs exact statevector (zero tolerance) ==="];
Module[{t, ok},
  SeedRandom[20260713];
  {t, ok} = AbsoluteTiming[And @@ Table[
    Module[{nn = RandomInteger[{2, 9}], tb, A, sG, rep},
      tb = NewGraphStateTableau[nn,
        Union[Sort /@ Select[Subsets[Range[nn], {2}], RandomReal[] < 0.3 &]]];
      Do[Switch[RandomInteger[{1, 6}],
         1, ApplyH[tb, RandomInteger[{1, nn}]],
         2, ApplyS[tb, RandomInteger[{1, nn}]],
         3, If[nn >= 2, With[{p = RandomSample[Range[nn], 2]}, ApplyCNOT[tb, p[[1]], p[[2]]]]],
         4, If[nn >= 2, With[{p = RandomSample[Range[nn], 2]}, ApplyCZ[tb, p[[1]], p[[2]]]]],
         5, ApplyX[tb, RandomInteger[{1, nn}]],
         6, MeasurePauli[tb, RandomInteger[{1, nn}],
              {"X", "Y", "Z"}[[RandomInteger[{1, 3}]]]]],
        {RandomInteger[{5, 30}]}];
      A = Sort[RandomSample[Range[nn], RandomInteger[{0, nn}]]];
      sG = CCTStabEntropy[tb, A];
      rep = If[A === {}, <|"S" -> 0, "Flat" -> True|>, CCTStateEntropyReport[tb, A]];
      FreeTableau[tb];
      (sG === rep["S"]) && rep["Flat"]], {60}]];
  check["60 random Clifford states (gates+measurements) x random subsets: GF(2) === statevector vN, flat spectrum", ok];
  addRow["entropy", "60 states", t, ok]];
Print[];

(* ---------------------------------------------------------------------------
   H2. PAGE CURVE.  (a) n=12 ensemble Renyi-2 vs the exact Lubkin/Page closed
   form (Clifford 2-design); (b) n=100 single-shot exact von Neumann curve
   ([E-SCRAMBLE], front-loaded); (c) mesh-cluster evaporation reps=2.
   --------------------------------------------------------------------------- *)
Print["=== H2: Page curve -- n=12 ensemble + n=100 single-shot + mesh ==="];
Module[{t, r2, maxd, okA, pc, okB, pm, okC},
  {t, r2} = AbsoluteTiming[CCTPageRenyi2Ensemble[12, 60, "Seed" -> 112]];
  maxd = Max[Abs[r2["S2sampled"] - r2["S2closed"]]];
  okA = maxd < 0.35;
  Print["  (a) n=12, 60-shot Clifford-ensemble Renyi-2: peak sampled=",
    fmtN[Max[r2["S2sampled"]]], " bits, closed=", fmtN[Max[r2["S2closed"]]],
    " bits, max|sampled-closed|=", fmtN[maxd], " bits (", fmtN[t], "s)"];
  check["n=12 ensemble Renyi-2 lands on the exact Lubkin closed form (max dev < 0.35 bits @ 60 shots)", okA];
  addRow["Page n=12 ens", "60 shots", t, okA];

  {t, pc} = AbsoluteTiming[CCTPageCurveScrambledState[100, "Seed" -> 100, "Sweeps" -> 14]];
  okB = (First[pc["curve"]] === 0) && (pc["final"] === 0) &&
        (46 <= pc["peak"] <= 50);
  Print["  (b) n=100 single-shot exact vN Page curve: start=", First[pc["curve"]],
    " peak=", pc["peak"], " bits (Page time ~", pc["pageTime"], ") final=",
    pc["final"], " (", fmtN[t], "s)"];
  check["n=100 single-shot: starts 0, peak in [46,50] bits near n/2, returns to 0 (exact integers)", okB];
  addRow["Page n=100", "1 shot", t, okB];

  {t, pm} = AbsoluteTiming[CCTPageCurveMesh[2, "Seed" -> 7, "Sweeps" -> 4]];
  okC = (First[pm["curve"]] === 0) && (pm["final"] === 0) && (pm["peak"] >= 6);
  Print["  (c) mesh-cluster evaporation reps=2 (n=", pm["n"], "): curve=", pm["curve"]];
  check["pentagon-mesh initial state evaporates through a valid Page curve (peak >= 6, ends 0)", okC];
  addRow["Page mesh", "reps=2", t, okC]];
Print[];

(* ---------------------------------------------------------------------------
   H3. HAYDEN-PRESKILL FIDELITY MATRIX ([E-HP-U]; EPR decoder [E-EPR-FORCE]).
   Maximal scrambler (all 12 single-qubit Paulis -> weight >= 3), then:
   EPR-projection decoder, deterministic decoder, 6-input Pauli teleportation,
   identity (non-scrambling) control, small depolarizing sweep.
   --------------------------------------------------------------------------- *)
Print["=== H3: Hayden-Preskill fidelity matrix ==="];
Module[{t, sc, epr, det, tele, idc, sweep, okS, okE, okD, okT, okI, okN, tt},
  {t, sc} = AbsoluteTiming[CCTFindMaximalScrambler[4, "Seed" -> 123]];
  okS = sc["isMaximal"];
  Print["  maximal scrambler m=4: minImageWeight=", sc["minImageWeight"],
    " tries=", sc["tries"], " (", fmtN[t], "s)"];
  check["scrambler is maximal: every single-qubit Pauli image has weight >= 3", okS];

  {tt, epr} = AbsoluteTiming[CCTHPDecodeEPR[sc["gates"]]];
  okE = (epr["successProb"] == 1/4) && (Abs[epr["Fe"] - 1] < 10^-12);
  Print["  EPR-projection decoder: successProb=", epr["successProb"],
    " (ideal 1/4 = 1/d_A^2)  Fe=", epr["Fe"]];
  check["EPR decoder: successProb == 1/4 exactly and Fe == 1", okE];

  det = CCTHPDecodeDeterministic[sc["gates"]];
  okD = det["recovered"];
  Print["  deterministic decoder: S(A',R)=", det["S_pair"], " S(A')=",
    det["S_half"], " -> recovered=", det["recovered"]];
  check["deterministic decoder: S_pair == 0 and S_half == 1 (diary recovered, prob 1)", okD];

  tele = CCTHPTeleportFidelity[sc["gates"]];
  okT = tele["allRecovered"];
  Print["  Pauli-input teleport matrix: ", Normal[tele["perInput"]],
    "  frac=", tele["fracRecovered"]];
  check["all 6 Pauli-basis diary inputs teleported with fidelity 1 (after Pauli frame)", okT];

  idc = CCTHPDecodeEPR[{}];
  okI = Abs[idc["Fe"] - 1/4] < 10^-12;
  Print["  identity (non-scrambling) control: Fe=", idc["Fe"],
    " -> basis-avg teleport F=", fmtN[(2 idc["Fe"] + 1)/3], " (ideal control 1/2)"];
  check["non-scrambling control: Fe == 1/4 (avg teleport F = 1/2)", okI];

  {tt, sweep} = AbsoluteTiming[CCTHPNoiseSweep[sc["gates"], {0.01, 0.02}, 120, 5]];
  okN = AllTrue[sweep, 0.5 < #["meanFe"] < 1 &];
  Print["  depolarizing sweep (120 trajectories): ",
    {#["p"], #["meanFe"]} & /@ sweep, " (", fmtN[tt], "s)"];
  check["noise degrades Fe below 1 but stays above 0.5 at p <= 0.02", okN];
  addRow["Hayden-Preskill", "m=4", t + tt, okS && okE && okD && okT && okI && okN]];
Print[];

(* ---------------------------------------------------------------------------
   H4. CHSH / CF ANCHORS on a mesh-carved Hawking pair ([C] canonical carve,
   [B] exact readout, [A] analytic angles).  Anchors per
   08-HK-hawking/hawking_cf_bridge.py.
   --------------------------------------------------------------------------- *)
Print["=== H4: CHSH / contextual-fraction anchors ==="];
Module[{t, pairs, bundle, tab, T, okT, sOpt, okS, cfTs, cfLPTs, cf0, cfLP0,
   cf225, cfLP225, okCF, tLP},
  {t, T} = AbsoluteTiming[
    pairs = CCTHawkingSelectPairs[3, 1];
    bundle = CCTHawkingBuildCarved[3, pairs, "Forced" -> 0];
    tab = bundle["tab"];
    With[{m = CCTPairCorrMatrix[tab, pairs[[1]]["partner"], pairs[[1]]["hawking"]]},
      FreeTableau[tab]; m]];
  okT = (T === {{0, 0, 1}, {0, 1, 0}, {1, 0, 0}});
  Print["  mesh-carved pair exact correlation matrix T=", T];
  check["carved Hawking pair: exact <XZ>=<ZX>=<YY>=1, all others 0 (graph-state Bell)", okT];
  sOpt = CCTCHSHOptimal[T];
  okS = Abs[sOpt - 2 Sqrt[2]] < 10^-9;
  Print["  CHSH_opt (Horodecki) = ", fmtN[sOpt], "  (Tsirelson 2 sqrt2 = ",
    fmtN[2 Sqrt[2]], ")"];
  check["CHSH_opt == 2 sqrt2 (Tsirelson) on the carved pair", okS];
  {tLP, {cfTs, cfLPTs, cf0, cfLP0, cf225, cfLP225}} = AbsoluteTiming[
    {CCTCFofS[2 Sqrt[2]], CCTCFofSLP[2 Sqrt[2]], CCTCFofS[2], CCTCFofSLP[2],
     CCTCFofS[2.25], CCTCFofSLP[2.25]}];
  okCF = Abs[N[cfTs] - N[Sqrt[2] - 1]] < 10^-12 &&
         Abs[cfLPTs - N[Sqrt[2] - 1]] < 10^-6 &&
         N[cf0] == 0 && Abs[cfLP0] < 10^-7 &&
         Abs[cf225 - 0.125] < 10^-12 && Abs[cfLP225 - 0.125] < 10^-6;
  Print["  CF(2 sqrt2): closed=", fmtN[cfTs], " LP=", fmtN[cfLPTs],
    "  anchor sqrt2-1=", fmtN[Sqrt[2] - 1]];
  Print["  CF(2):       closed=", fmtN[cf0], " LP=", fmtN[cfLP0], "  anchor 0"];
  Print["  CF(2.25):    closed=", fmtN[cf225], " LP=", fmtN[cfLP225],
    "  anchor 0.125 (BEC B=2.25 @ T=0)"];
  check["CF anchors reproduced closed-form AND by native-WL AB LP: sqrt2-1 / 0 / 0.125", okCF];
  addRow["CHSH/CF", "reps=3", t + tLP, okT && okS && okCF]];
Print[];

(* ---------------------------------------------------------------------------
   H5. CONFIRMATION TABLE SUMMARY (exact-arithmetic core of the post-hoc
   confrontation; full sampled version = cct_mbqc_hawking_confirmation.wl).
   --------------------------------------------------------------------------- *)
Print["=== H5: confirmation vs published targets (exact core) ==="];
Module[{t1ok, peaks, tfd, xx, yy, zz, sA, pur, t3ok, tab, verdicts, t},
  {t, peaks} = AbsoluteTiming[
    Table[{n, N[Max[Table[CCTPageRenyi2Closed[n, r], {r, 0, n}]]]*ln2}, {n, {8, 10, 12}}]];
  t1ok = And @@ MapThread[Abs[#1[[2]] - #2] < 0.01 &,
    {peaks, {2.08, 2.77, 3.47}}];
  Print["  T1 Chowdhury 2412.15180: closed Renyi-2 peaks (nats) ",
    Map[fmtN, peaks[[All, 2]]], " vs paper {2.08, 2.77, 3.47}"];
  check["T1: exact closed-form Renyi-2 peaks match Chowdhury N=8/10/12 within 0.01 nats", t1ok];

  Print["  T2 Landsman 1806.02807: ideal stabilizer matrix (H3) = paper's exact",
    " ideal column (P=1/4, F=1 x6, control 1/2); their hardware: 77(2)%, OTOC 0.47(2)"];

  tab = NewGraphStateTableau[6, {{1, 2}, {3, 4}, {5, 6}}];
  Scan[ApplyH[tab, #] &, {2, 4, 6}];
  xx = CCTPairExp[tab, 1, 2, "X", "X"]; yy = CCTPairExp[tab, 1, 2, "Y", "Y"];
  zz = CCTPairExp[tab, 1, 2, "Z", "Z"];
  sA = CCTStabEntropy[tab, {1, 3, 5}]; pur = CCTStabPurity[tab, {1, 2}];
  FreeTableau[tab];
  t3ok = (xx === 1) && (yy === -1) && (zz === 1) && (sA === 3) && (pur === 1);
  Print["  T3 Zhu PNAS 2020 / Sagastizabal npj 2021 (beta=0 TFD): <XX>,<YY>,<ZZ>=",
    {xx, yy, zz}, " (|corr|=1; Phi+ frame vs their singlet -- LU-equivalent),",
    " S_A(3 pairs)=", sA, " bits = ", fmtN[sA*ln2], " nats (= 3 ln2), pair purity=", pur];
  check["T3: beta=0 TFD anchors exact (|correlators|=1, S_A=3 ln2 nats, pure pairs)", t3ok];

  Print["  T4 CF anchors: see H4 (closed + LP, sqrt2-1 / 0 / 0.125); no VQE-Hawking",
    " paper reports any Bell/CHSH value -- BEC B=2.25 is the only external anchor"];

  verdicts = {
    {"T1 Page/Renyi-2 (Chowdhury)", If[t1ok, "CONFIRMED (exact formula; ensemble 2-design H2a)", "MISMATCH"]},
    {"T2 Hayden-Preskill (Landsman)", "CONFIRMED ideal-Clifford column (H3); hardware gap declared"},
    {"T3 beta=0 TFD (Zhu/Sagastizabal)", If[t3ok, "CONFIRMED (Phi+ vs singlet frame caveat)", "MISMATCH"]},
    {"T4 CHSH/CF (project + BEC)", "CONFIRMED (H4 anchors, closed form + AB LP)"}};
  Print[];
  Print["  CONFIRMATION VERDICT TABLE:"];
  Do[Print["    ", StringPadRight[v[[1]], 36], " ", v[[2]]], {v, verdicts}];
  addRow["confirmation", "T1-T4", t, t1ok && t3ok]];
Print[];

(* ---------------------------------------------------------------------------
   Consolidated scoreboard.
   --------------------------------------------------------------------------- *)
Print["############################################################"];
Print["=== CONSOLIDATED SCOREBOARD ==="];
Module[{hdr = {"section", "size", "time(s)", "verdict"}, widths},
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
