(* ::Package:: *)

(* :Title: IntensityLayer -- Layer 2 of the EMU optical compiler (Builder B) *)
(* :Context: HubertKolcz`OpticalCompiler` *)
(* :Author: Hubert Kolcz -- July 2026 *)
(* :Summary:
   The INTENSITY layer of optical-synthesis: the constructive form of the
   adversarial construction (iii-d) of certification-protocol/mbqc_blackbox_test.py.
   Given a no-disturbance target table on a cyclic (or covered) contextuality
   scenario, CompileIntensityEmulator synthesizes the per-context intensity
   fractions plus a source/splitter/detector schedule that a divided classical
   beam realizes -- and certifies feasibility over the NO-DISTURBANCE polytope by
   an exact rational/algebraic LinearOptimization (flat variable list,
   Method -> "RevisedSimplex", exact on Q and on Q(Sqrt[5])).

   HONEST SCOPE (survives verbatim in spirit from DESIGN.md): this layer emits
   emulators of BLOCK-LOCAL statistics -- exactly what Prop. 1 / the certification
   map says classical optics CAN do. A Layer-2 blueprint is leaf-confined by its
   own DLA audit (DLADimension < 3, Layer 3's job); it does NOT construct a
   globally entangled cluster state. The table it reproduces can be indistinguishable
   at the table level from a genuine quantum box (this IS construction iii-d); the
   certifying difference is EVENT SEMANTICS, not the table. Cite: Prop. 1 / BBT-002,
   BBT-003, Frustaglia et al., PRL 116, 250404 (2016).

   Native-first: CycleScenario, CycleModel, CycleCoboundary, ContextualFraction,
   NoncontextualFraction are USED from the BlackBox paclet, never re-implemented.
   The intensity-table constructor and the (f00,f01,f10)=(1-2t, t-delta, t+delta)
   convention are ported (with attribution) from mbqc_blackbox_test.py.

   Loadability: definitions only; nothing heavy runs at Get. The A3 anchor + tests
   live in the delayed IntensityLayerVerification association (whose "OK" key
   evaluates True), evaluated by the headless runner runners/RunIntensityLayer.wl.
   The integrator OpticalCompiler.wl / DispatcherEmitter.wl (Builder C) Gets this
   file with no side effects and reuses CompileIntensityEmulator for anchor A3.

   Anchor A3: CompileIntensityEmulator[IntensityTableKCBS[1/Sqrt[5], 0],
   CycleScenario[5]] reproduces construction iii-d's exact KCBS quantum-table
   emulator -- per-context (f00,f01,f10) = (1-2/Sqrt[5], 1/Sqrt[5], 1/Sqrt[5]),
   NodeSum = Sqrt[5], ContextualFraction = 2 Sqrt[5]-4 -- cross-checked against the
   Python original's numbers.
*)

(* Register the BlackBox paclet directory BEFORE BeginPackage so the dependency
   declaration below can load it. Pattern adapted from
   pentagon-foundations/BiphotonSimulator.wl lines 13-14 (per repo convention). *)
PacletDirectoryLoad[FileNameJoin[{Quiet@Check[DirectoryName[$InputFileName], Directory[]], "..", "BlackBox"}]];

(* BlackBox` is a declared dependency: this loads it and keeps its public symbols
   (CycleScenario, CycleModel, CycleCoboundary, ContextualFraction,
   NoncontextualFraction) on $ContextPath for the whole package body, with no
   Global`-context shadowing. *)
BeginPackage["HubertKolcz`OpticalCompiler`", {"HubertKolcz`BlackBox`"}];

CompileIntensityEmulator::usage =
  "CompileIntensityEmulator[table, scenario] compiles the empirical no-disturbance model vector `table` (in `scenario`'s section order) into a classical intensity-redistribution blueprint: per-context intensity fractions and a source/splitter/detector stage schedule that a divided classical beam realizes. Feasibility over the no-disturbance polytope is certified by an exact LinearOptimization (flat variables, Method -> \"RevisedSimplex\"; exact on rationals and on Q(Sqrt[5])). Returns an association with keys \"Feasible\", \"NoDisturbance\", \"IntensitySchedule\", \"Stages\", \"TableReproduced\", \"NodeSum\", \"ContextualFraction\", \"SignalingResidual\", \"SlackL1\", \"RePreparationRequired\", \"ModeCount\", \"n\", \"Scenario\". Option Method (default \"RevisedSimplex\") is passed to LinearOptimization.";

IntensityTableKCBS::usage =
  "IntensityTableKCBS[t, delta] gives the KCBS (5-cycle) divided-beam empirical model vector with per-context fractions (f00,f01,f10) = (1-2 t, t-delta, t+delta) (section order (00,01,10,11), (1,1) structurally absent). IntensityTableKCBS[t, delta, n] gives the n-cycle table. Ported from mbqc_blackbox_test.py `table_intensity` (construction iii). IntensityTableKCBS[1/Sqrt[5], 0] is the A3 quantum-table anchor; IntensityTableKCBS[1/2, 0] is the alpha* = 5/2 Wright ceiling; IntensityTableKCBS[t, 0] a V-visibility / sub-quantum symmetric table.";

IntensityLayerVerification::usage =
  "IntensityLayerVerification is the association of Layer-2 anchor and test results (chiefly A3), whose \"OK\" key evaluates True. Computed on demand; nothing heavy runs at Get.";

Begin["`Private`"];

(* ------------------------------------------------------------------ helpers -- *)

(* exact/numeric twin field on a parameter value (DESIGN 2.3 convention) *)
exnum[x_] := <|"Exact" -> x, "Numeric" -> N[x]|>;
exnumRR[x_] := With[{r = RootReduce[x]}, <|"Exact" -> r, "Numeric" -> N[r]|>];

(* number of measurements/contexts of a cyclic scenario *)
cycleN[scenario_Association] := Lookup[scenario, "n",
   With[{ctx = Lookup[scenario, "Contexts", {}]}, Length[ctx]]];

(* Is this scenario the binary n-cycle with edge contexts {i, i+1 mod n}? *)
cyclicQ[scenario_Association, n_Integer] := TrueQ[
   Lookup[scenario, "Contexts", None] === Table[{i, Mod[i + 1, n]}, {i, 0, n - 1}]];

(* No-disturbance coboundary for the scenario. Cyclic case: reuse the paclet's
   CycleCoboundary[n] verbatim (ker(delta) = no-disturbance models). General cover:
   build the marginal-consistency operator directly from the incidence structure
   (each measurement's marginal must agree across every pair of contexts sharing it). *)
noDisturbanceOperator[scenario_Association, n_Integer] :=
  If[cyclicQ[scenario, n], CycleCoboundary[n], genericCoboundary[scenario]];

genericCoboundary[scenario_Association] := Module[
   {X = scenario["X"], ctx = scenario["Contexts"], secs = scenario["Sections"],
    outs = scenario["Outcomes"], rows, ctxSecIdx, marginalRow},
   (* index of each section (context, tuple) in the flat section list *)
   ctxSecIdx = AssociationThread[secs -> Range[Length[secs]]];
   (* row of the section-length indicator selecting outcome o of measurement x in context c *)
   marginalRow[c_, x_, o_] := Module[{pos = Position[c, x][[1, 1]], vec},
      vec = ConstantArray[0, Length[secs]];
      Do[If[MemberQ[ctx, c] && secs[[k, 1]] === c && secs[[k, 2, pos]] === o,
         vec[[k]] = 1], {k, Length[secs]}];
      vec];
   rows = Reap[
      Do[Module[{ctxsWith = Select[ctx, MemberQ[#, x] &], o = First[outs[x]]},
         If[Length[ctxsWith] >= 2,
            Do[Sow[marginalRow[ctxsWith[[1]], x, o] - marginalRow[ctxsWith[[j]], x, o]],
               {j, 2, Length[ctxsWith]}]]],
         {x, X}]][[2]];
   If[rows === {}, ConstantArray[0, {1, Length[secs]}], First[rows]]];

(* positions of the structurally-absent (1,1) section per context; and the per-context
   section-index blocks. For the binary n-cycle both are the standard 4-blocks. *)
structuralZeroPositions[n_Integer] := Table[4 c + 4, {c, 0, n - 1}];
contextBlocks[n_Integer] := Table[Range[4 c + 1, 4 c + 4], {c, 0, n - 1}];

(* --------------------------------------------------- intensity table constructor -- *)
(* Ported from mbqc_blackbox_test.py: table_from_edge(p00,p01,p10) fills each context
   block with {p00,p01,p10,0}; table_intensity(t,delta) uses (1-2t, t-delta, t+delta). *)
IntensityTableKCBS[t_, delta_] := IntensityTableKCBS[t, delta, 5];
IntensityTableKCBS[t_, delta_, n_Integer /; n >= 3] :=
  Flatten[Table[{1 - 2 t, t - delta, t + delta, 0}, {n}]];

(* --------------------------------------------------------- the feasibility LP -- *)
(* Exact feasibility over the no-disturbance intensity polytope. Variables (flat):
     y  = per-section intensity fractions (length 4n),
     sp, sm = nonneg L1 slacks on reproduction (length 4n each).
   min Total[sp]+Total[sm]  s.t.
     y >= 0,  y[structural (1,1)] == 0,  per-context Total[y-block] == 1,
     delta_ND . y == 0            (no-disturbance: shared-mode marginals agree),
     y - sp + sm == e             (reproduce the target; algebraic e enters ONLY as
                                    the RHS of a 3-variable combination, the shape the
                                    exact algebraic simplex handles on Q(Sqrt[5]) --
                                    the kcbs_ledger.wl RevisedSimplex precedent).
   Minimum == 0  <=>  the target lies in the no-disturbance polytope (honest emulation).
   Minimum  > 0  =  exact L1 distance to that polytope (the signaling deficit).       *)
feasibilityLP[e_List, delND_?MatrixQ, n_Integer, method_] := Module[
   {len = Length[e], y, sp, sm, vars, zpos = structuralZeroPositions[n],
    blocks = contextBlocks[n], cons, slack, pt},
   y = Array[ilY, len]; sp = Array[ilSp, len]; sm = Array[ilSm, len];
   vars = Join[y, sp, sm];
   cons = Join[
      Thread[y >= 0],
      Thread[y[[zpos]] == 0],
      Table[Total[y[[b]]] == 1, {b, blocks}],
      Thread[delND . y == 0],
      Thread[sp >= 0], Thread[sm >= 0],
      Thread[y - sp + sm == e]];
   slack = Quiet@LinearOptimization[Total[sp] + Total[sm], cons, vars,
      "PrimalMinimumValue", Method -> method];
   pt = Quiet@LinearOptimization[Total[sp] + Total[sm], cons, vars, Method -> method];
   <|"Slack" -> slack,
     "Y" -> If[ListQ[pt], y /. pt, $Failed]|>];

(* --------------------------------------------------------- the schedule build -- *)
(* Amplitude beamsplitter angle theta whose intensity reflectivity is the fraction r
   (r = Sin[theta]^2). Kept exact; guarded for r == 0/1. *)
bsAngle[r_] := ArcSin[Sqrt[r]];

(* per-context schedule atom (DESIGN 2.3): Context, Fractions (Exact+Numeric),
   SourceIntensity -> 1. *)
ctxScheduleAtom[ctx_, f00_, f01_, f10_] := <|
   "Context" -> ctx,
   "Fractions" -> <|"f00" -> exnumRR[f00], "f01" -> exnumRR[f01], "f10" -> exnumRR[f10]|>,
   "SourceIntensity" -> 1|>;

(* per-context optical stages (uniform stage schema, DESIGN Section 3): one Source,
   two BS splitters (cascade that divides unit intensity into the 3 detector bins),
   three Detectors. Modes 1-indexed; context c (0-indexed) owns detector modes
   {3c+1, 3c+2, 3c+3}. *)
ctxStages[c_Integer, ctx_, f00_, f01_, f10_] := Module[
   {m0 = 3 c + 1, m1 = 3 c + 2, m2 = 3 c + 3, rem = 1 - f00, r2},
   r2 = If[TrueQ[Simplify[rem == 0]], 0, f01/rem];  (* reflectivity of BS2 on the remainder *)
   {<|"Type" -> "Source", "Modes" -> {m0}, "Parameter" -> exnum[1],
      "Label" -> "Src" <> ToString[ctx]|>,
    <|"Type" -> "BS", "Modes" -> {m0, m1}, "Parameter" -> exnumRR[bsAngle[f00]],
      "Label" -> "Tap00" <> ToString[ctx]|>,
    <|"Type" -> "BS", "Modes" -> {m1, m2}, "Parameter" -> exnumRR[bsAngle[r2]],
      "Label" -> "Split01|10" <> ToString[ctx]|>,
    <|"Type" -> "Detector", "Modes" -> {m0}, "Parameter" -> exnumRR[f00], "Label" -> "D00" <> ToString[ctx]|>,
    <|"Type" -> "Detector", "Modes" -> {m1}, "Parameter" -> exnumRR[f01], "Label" -> "D01" <> ToString[ctx]|>,
    <|"Type" -> "Detector", "Modes" -> {m2}, "Parameter" -> exnumRR[f10], "Label" -> "D10" <> ToString[ctx]|>}];

(* node sum = sum of per-event (per-measurement) probabilities, robust to signaling:
   p_m = 1/2 (marginal of m as 2nd obs of context m-1 + as 1st obs of context m). *)
nodeSumExact[e_List, n_Integer] := RootReduce@Sum[
   (1/2) (e[[4 Mod[m - 1, n] + 2]] + e[[4 m + 3]]), {m, 0, n - 1}];

(* ---------------------------------------------------- CompileIntensityEmulator -- *)
Options[CompileIntensityEmulator] = {Method -> "RevisedSimplex"};

CompileIntensityEmulator[table_List, scenario_Association, opts:OptionsPattern[]] := Module[
   {n = cycleN[scenario], method = OptionValue[Method], delND, sigResidual, sigNorm,
    lp, slack, feasible, noDist, sched, stages, f, cf, ns, e = table},
   delND = noDisturbanceOperator[scenario, n];
   sigResidual = RootReduce[delND . e];                 (* signaling / disturbance vector *)
   sigNorm = RootReduce[Norm[sigResidual]];
   noDist = TrueQ[Simplify[sigNorm == 0]];
   lp = feasibilityLP[e, delND, n, method];
   slack = RootReduce[lp["Slack"]];
   feasible = TrueQ[Simplify[slack == 0]];
   (* the box reports the table entries directly as its per-context fractions *)
   f = Table[{e[[4 c + 1]], e[[4 c + 2]], e[[4 c + 3]]}, {c, 0, n - 1}];
   sched = Table[
      ctxScheduleAtom[If[cyclicQ[scenario, n], {c, Mod[c + 1, n]}, scenario["Contexts"][[c + 1]]],
         f[[c + 1, 1]], f[[c + 1, 2]], f[[c + 1, 3]]], {c, 0, n - 1}];
   stages = Flatten[Table[
      ctxStages[c, If[cyclicQ[scenario, n], {c, Mod[c + 1, n]}, scenario["Contexts"][[c + 1]]],
         f[[c + 1, 1]], f[[c + 1, 2]], f[[c + 1, 3]]], {c, 0, n - 1}], 1];
   cf = If[cyclicQ[scenario, n], RootReduce@ContextualFraction[scenario, e], Missing["NonCyclic"]];
   ns = nodeSumExact[e, n];
   <|
    "Feasible" -> feasible,             (* True <=> honest no-disturbance emulation exists *)
    "NoDisturbance" -> noDist,
    "RePreparationRequired" -> Not[noDist],  (* signaling => per-context beam re-preparation *)
    "SignalingResidual" -> exnumRR[sigNorm],
    "SlackL1" -> exnumRR[slack],        (* exact L1 distance to the no-disturbance polytope *)
    "IntensitySchedule" -> sched,
    "Stages" -> stages,
    "TableReproduced" -> <|"Exact" -> RootReduce[e], "Numeric" -> N[e]|>,
    "NodeSum" -> exnumRR[ns],
    "ContextualFraction" -> If[MissingQ[cf], cf, exnumRR[cf]],
    "ModeCount" -> 3 n,
    "n" -> n,
    "Scenario" -> KeyTake[scenario, {"X", "Contexts", "n"}]
   |>];

(* fold an IntensitySchedule back to a table -- the self-certification primitive that
   Layer-3's VerifyBlueprint (A5) calls on an L2 blueprint. *)
scheduleToTable[sched_List] := Flatten[
   Table[{atom["Fractions", "f00", "Exact"], atom["Fractions", "f01", "Exact"],
          atom["Fractions", "f10", "Exact"], 0}, {atom, sched}]];

(* ============================================================= tests / anchors == *)
(* Packaged in the delayed IntensityLayerVerification so bare Get stays definitions-only. *)

intensityLayerRunChecks[] := Module[
   {scen5 = CycleScenario[5], schQ, schW, schV, schS, checks},

   (* --- A3: KCBS quantum-table emulator, construction iii-d, t=1/Sqrt[5], delta=0 --- *)
   schQ = CompileIntensityEmulator[IntensityTableKCBS[1/Sqrt[5], 0], scen5];

   checks = <|
    (* A3.1 feasible over the no-disturbance polytope, delta=0 => no signaling *)
    "A3_feasible" -> schQ["Feasible"] === True,
    "A3_noDisturbance" -> schQ["NoDisturbance"] === True,
    "A3_signalingResidualZero" -> schQ["SignalingResidual", "Exact"] === 0,
    "A3_slackZero" -> schQ["SlackL1", "Exact"] === 0,
    (* A3.2 per-context fractions = (1-2/Sqrt5, 1/Sqrt5, 1/Sqrt5) exactly *)
    "A3_f00Exact" -> RootReduce[schQ["IntensitySchedule"][[1, "Fractions", "f00", "Exact"]] - (1 - 2/Sqrt[5])] === 0,
    "A3_f01Exact" -> RootReduce[schQ["IntensitySchedule"][[1, "Fractions", "f01", "Exact"]] - 1/Sqrt[5]] === 0,
    "A3_f10Exact" -> RootReduce[schQ["IntensitySchedule"][[1, "Fractions", "f10", "Exact"]] - 1/Sqrt[5]] === 0,
    (* A3.3 NodeSum = Sqrt[5] exactly (matches SQRT5 anchor of the Python original) *)
    "A3_nodeSumSqrt5" -> RootReduce[schQ["NodeSum", "Exact"] - Sqrt[5]] === 0,
    (* A3.4 ContextualFraction = 2 Sqrt[5]-4 exactly (CF_EXACT of mbqc_blackbox_test.py) *)
    "A3_cfExact" -> RootReduce[schQ["ContextualFraction", "Exact"] - (2 Sqrt[5] - 4)] === 0,
    (* A3.5 numeric cross-check against the Python literals *)
    "A3_f01Numeric" -> Abs[schQ["IntensitySchedule"][[1, "Fractions", "f01", "Numeric"]] - 0.4472135954999579] < 10^-12,
    "A3_f00Numeric" -> Abs[schQ["IntensitySchedule"][[1, "Fractions", "f00", "Numeric"]] - 0.10557280900008413] < 10^-12,
    "A3_cfNumeric" -> Abs[schQ["ContextualFraction", "Numeric"] - 0.4721359549995794] < 10^-12,
    (* A3.6 self-certification: fold the schedule back to a table, reproduce exactly *)
    "A3_selfReproduce" -> RootReduce[scheduleToTable[schQ["IntensitySchedule"]] - IntensityTableKCBS[1/Sqrt[5], 0]] === ConstantArray[0, 20]
   |>;

   (* --- alpha* ceiling: Wright box t=1/2, delta=0 => NodeSum = 5/2, feasible, CF=1 --- *)
   schW = CompileIntensityEmulator[IntensityTableKCBS[1/2, 0], scen5];
   checks = Join[checks, <|
    "Wright_feasible" -> schW["Feasible"] === True,
    "Wright_nodeSum52" -> schW["NodeSum", "Exact"] === 5/2,
    "Wright_cf1" -> RootReduce[schW["ContextualFraction", "Exact"] - 1] === 0,
    "Wright_supraQuantum" -> TrueQ[schW["NodeSum", "Exact"] > Sqrt[5]]  (* 5/2 > Sqrt[5]: intensity reaches it, quantum cannot *)
   |>];

   (* --- V-visibility (rational V = 9/10): symmetric sub-alpha* table, feasible --- *)
   With[{V = 9/10}, With[{q = V/Sqrt[5] + (1 - V)/3, p00 = V (1 - 2/Sqrt[5]) + (1 - V)/3},
     schV = CompileIntensityEmulator[Flatten[Table[{p00, q, q, 0}, {5}]], scen5]]];
   checks = Join[checks, <|
    "Vvis_feasible" -> schV["Feasible"] === True,
    "Vvis_noDisturbance" -> schV["NoDisturbance"] === True,
    "Vvis_nodeSumBelowSqrt5" -> TrueQ[schV["NodeSum", "Numeric"] < N[Sqrt[5]]]
   |>];

   (* --- signaling case: t=1/2, delta=1/20 => infeasible over ND polytope, slack>0 --- *)
   schS = CompileIntensityEmulator[IntensityTableKCBS[1/2, 1/20], scen5];
   checks = Join[checks, <|
    "Signaling_notFeasible" -> schS["Feasible"] === False,
    "Signaling_disturbs" -> schS["NoDisturbance"] === False,
    "Signaling_reprep" -> schS["RePreparationRequired"] === True,
    "Signaling_residualPositive" -> TrueQ[schS["SignalingResidual", "Numeric"] > 0],
    "Signaling_slackPositive" -> TrueQ[schS["SlackL1", "Numeric"] > 0]
   |>];

   (* --- C7 generalization: quantum n=7 table is feasible, node sum = theta(C7) --- *)
   With[{t7 = Cos[Pi/7]/(1 + Cos[Pi/7])},
     Module[{sch7 = CompileIntensityEmulator[IntensityTableKCBS[t7, 0, 7], CycleScenario[7]]},
       checks = Join[checks, <|
        "C7_feasible" -> sch7["Feasible"] === True,
        "C7_nodeSumTheta" -> RootReduce[sch7["NodeSum", "Exact"] - 7 Cos[Pi/7]/(1 + Cos[Pi/7])] === 0
       |>]]];

   checks];

(* Delayed (definitions-only): nothing heavy runs at Get; the A3 + generalized-
   construction battery evaluates only when IntensityLayerVerification is asked for
   (by the standalone trigger below, or by the module runner). *)
IntensityLayerVerification := Module[{c = intensityLayerRunChecks[]},
   Append[c, "OK" -> (And @@ Values[c])]];

End[];

EndPackage[];

(* This file is definitions-only (loadability discipline). The A3 + generalized-
   construction battery lives in IntensityLayerVerification (delayed) and is run by
   the headless runner runners/RunIntensityLayer.wl, which prints the verification
   Column ending in "OK" -> True. The integrator OpticalCompiler.wl (Builder C) can
   Get this file with no side effects. *)
