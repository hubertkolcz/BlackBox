(* ::Package:: *)

(* :Title: DispatcherEmitter (optical-synthesis, Builder C) *)
(* :Context: HubertKolcz`OpticalCompiler` *)
(* :Author: Hubert Kolcz *)
(* :Date: 2026-07-13 *)

(* :Summary:
   Layer 3 (dispatcher), the blueprint emitter, the schematic renderer, and the
   self-certification loop of the optical compiler -- the CONSTRUCTIVE mirror of
   certification-protocol certification.  Given a target (a scenario name, a claimed generator
   set, a no-disturbance table, or a pentagon-mesh word), DispatchLayers decides
   per component whether an intensity redistribution (Layer 2, leaf-confined,
   emulable) suffices or a genuine interferometer (Layer 1, so(3) DLA >= 3) is
   required; EmitBlueprint assembles the blueprint Association (Section 3 of
   DESIGN.md); the schematic renderer draws the beamsplitter mesh; VerifyBlueprint
   re-simulates the blueprint from its own data and checks it reproduces the
   target statistics EXACTLY and that the recorded DLA verdict matches the layer
   used (gate A5).

   HONEST SCOPE (verbatim in spirit, per DESIGN.md / README.md): the compiler
   emits emulators of BLOCK-LOCAL statistics (per-block tables, block-local AvN
   witnesses) -- exactly what Prop. 1 / the certification map says classical
   optics CAN do.  It does NOT construct globally-entangled cluster states:
   single-photon linear optics cannot, absent exponential mode count or KLM
   nonlinearity.  A Layer-2 blueprint is the constructive form of the adversarial
   case (iii-d) of mbqc_blackbox_test.py -- a divided classical beam reproducing a
   quantum table exactly -- and is flagged leaf-confined (DLADimension < 3) by its
   own DLA audit.  The emulated/genuine boundary carried in every blueprint is the
   framework's two-lens theorem applied constructively.
   Cite: Prop. 1 / BBT-002, BBT-003, MESH-004, MESH-008; Frustaglia et al.,
   PRL 116, 250404 (2016); Lapkiewicz et al., Nature 474, 490 (2011).

   Native-first / exact-first (WL mandates): the so(3) audit reuses the BlackBox
   paclet verbatim (CascadeGenerators, So3Axis, DLADimension, CycleScenario,
   CycleCoboundary, ContextualFraction, KCBSDirections); nothing the paclet
   exposes is re-implemented.  The KCBS Givens angle is kept as
   ArcCos[1/GoldenRatio] and matrix entries stay algebraic on the exact path;
   N[...] fills only the "Numeric" twin and the Graphics.  The CV column ports
   certification-protocol/final_o3_cv_dla.py (Sp(2n,R) leaf-confinement) with attribution.  Mesh
   routing copies wordRingEdgesFast from cluster-state-realization verbatim (single
   Table + one Flatten; no Join-in-loop).

   Loadability: definitions only; nothing heavy runs on bare Get.  The A1-A5
   battery lives in OpticalCompilerVerification (a delayed value) and is triggered
   by runners/RunOpticalCompiler.wl. *)

PacletDirectoryLoad[
  FileNameJoin[{Quiet@Check[NotebookDirectory[], DirectoryName[$InputFileName]],
    "..", "BlackBox"}]];

BeginPackage["HubertKolcz`OpticalCompiler`", {"HubertKolcz`BlackBox`"}];

(* ---- Layer 1 : interferometer synthesis ------------------------------------ *)
CompileInterferometer::usage = "CompileInterferometer[spec_Association] gives a StageMesh association for a scenario target (spec = <|\"Scenario\"->\"KCBS\"|> or <|\"Scenario\"->\"Cn\",\"n\"->n|>), reproducing the Lapkiewicz cascade [P,T1..T(n-1)]. CompileInterferometer[u_?MatrixQ] Givens-decomposes a unitary.";
GivensDecompose::usage = "GivensDecompose[u_?MatrixQ] gives the list of two-level (Givens) stage atoms of the special-orthogonal matrix u by Reck elimination.";
StagesToUnitary::usage = "StagesToUnitary[stages_List, n_Integer] re-multiplies a stage list back into <|\"Exact\"->matrix, \"Numeric\"->matrix|>.";
CompileMeshRouting::usage = "CompileMeshRouting[word_String, reps_Integer] gives the pentagon-mesh routing association (verbatim wordRingEdgesFast topology): ModeCount, EdgeList, Blocks, Routing.";

(* ---- Layer 2 : intensity emulator synthesis -------------------------------- *)
CompileIntensityEmulator::usage = "CompileIntensityEmulator[table_List, scenario_Association] gives the intensity-redistribution Schedule association for a no-disturbance table over a cycle scenario (exact rational feasibility LP over the no-disturbance polytope, RevisedSimplex).";
IntensityTableKCBS::usage = "IntensityTableKCBS[t_, delta_] gives the KCBS/cycle no-disturbance model vector with per-context fractions (f00,f01,f10)=(1-2t, t-delta, t+delta). IntensityTableKCBS[1/Sqrt[5],0] is the A3 anchor.";

(* ---- Layer 3 : dispatcher --------------------------------------------------- *)
DispatchLayers::usage = "DispatchLayers[targetSpec_Association] gives the per-component dispatch association: for each component a Span, DLADimension, LeafConfined flag, Verdict (emulable|genuine) and Layer (L1|L2|Mesh). Genuine (DLA>=3)=>L1; leaf-confined (DLA<3) or table-only=>L2.";
CVLeafConfinedQ::usage = "CVLeafConfinedQ[gens_List, n_Integer] gives the Sp(2n,R) leaf-confinement audit of a claimed Gaussian generator set (ported from certification-protocol/final_o3_cv_dla.py): <|\"Dim\",\"Compact\",\"Confined\"|>. Confined <=> closure subset u(n) (all antisymmetric, dim<=n^2).";

(* ---- emission + self-certification ----------------------------------------- *)
EmitBlueprint::usage = "EmitBlueprint[targetSpec_Association] gives the blueprint Association (Section 3 of DESIGN.md): TargetSpec, ModeCount, Layer, Stages, Routing, IntensitySchedule, Unitary, CertificationVerdict, Schematic, Provenance, SelfCertification. Option Method->Automatic|\"L1\"|\"L2\"|\"Mesh\" forces a layer.";
VerifyBlueprint::usage = "VerifyBlueprint[bp_Association] re-simulates a blueprint from its own data and gives <|\"StatisticsMatch\",\"MaxDeviation\",\"TargetReproduced\",\"DLAVerdictConsistent\",\"OK\"|> (gate A5).";
OpticalCompilerSchematic::usage = "OpticalCompilerSchematic[bp_Association] gives the Graphics schematic of a blueprint (mode lines, beamsplitter crossings labelled with the exact angle, phase boxes, sources left, detectors right, mesh routing for word targets).";
OpticalCompilerExportSchematics::usage = "OpticalCompilerExportSchematics[dir_String] emits the anchor blueprints and exports each Schematic to dir as PNG + PDF; gives the list of written files.";
OpticalCompilerVerification::usage = "OpticalCompilerVerification is the module verdict association: it runs anchors A1-A5 and ANDs their pass flags into \"OK\" (must be True). Delayed value; nothing heavy runs on bare Get.";

Begin["`Private`"];

(* ============================================================================
   0.  SHARED CONSTANTS AND HELPERS
   ============================================================================ *)

(* The KCBS cascade Givens angle: cos theta = 1/GoldenRatio = (Sqrt[5]-1)/2 EXACTLY
   (RootReduce-verified this pass), sin theta = Sqrt[1/GoldenRatio].  Kept symbolic. *)
$KCBSAngle = ArcCos[1/GoldenRatio];

$citations = {"BBT-002", "BBT-003", "MESH-004", "MESH-008",
  "Frustaglia PRL116 250404", "Lapkiewicz Nature474 490"};
$anchors = {"A1", "A2", "A3", "A4", "A5"};
$emitDate = "2026-07-13";

twin[expr_] := <|"Exact" -> expr, "Numeric" -> N[expr]|>;

(* an n-mode two-level (Givens) rotation on the ordered pair {i,j}, angle t:
   [i,i]=[j,j]=Cos t, [i,j]=+Sin t, [j,i]=-Sin t.  Native Dot elsewhere. *)
givens[n_Integer, {i_Integer, j_Integer}, t_] := Module[{m = IdentityMatrix[n]},
  m[[i, i]] = Cos[t]; m[[j, j]] = Cos[t];
  m[[i, j]] = Sin[t]; m[[j, i]] = -Sin[t]; m];

(* build the matrix an individual stage atom represents.  A stage that carries an
   explicit exact "Matrix" twin (Builder A's InterferometerLayer format, the
   authoritative pipeline) IS its own action -- use it verbatim; otherwise
   reconstruct natively from the annotation (this module's own stage format). *)
stageMatrix[stage_Association, n_Integer] := With[{mx = Lookup[stage, "Matrix", None]},
  Which[
   AssociationQ[mx] && MatrixQ[mx["Exact"]], mx["Exact"],
   True,
   Switch[stage["Type"],
    "BS", givens[n, stage["Modes"], stage["Parameter"]["Exact"]],
    "Phase", Module[{m = IdentityMatrix[n]},
      m[[stage["Modes"][[1]], stage["Modes"][[1]]]] = Exp[I stage["Parameter"]["Exact"]]; m],
    "Prep", stage["Matrix"]["Exact"],
    _, IdentityMatrix[n]]]];

(* ============================================================================
   1.  LAYER 1 -- INTERFEROMETER SYNTHESIS
   ---------------------------------------------------------------------------- *)

(* KCBS / n-cycle cascade geometry.  Extracted verbatim (frames, transitions,
   prep completion) from pentagon-foundations/kcbs_circuit.wl Sections 2-4 and
   kcbs_circuit_ncycle.wl buildNCycleCircuit, per repo convention.  For n=5 the
   directions come from the BlackBox paclet's KCBSDirections[] (exact, Q(Sqrt5));
   for general odd n the azimuth step is (n-1)Pi/n (kcbs_circuit_ncycle.wl). *)
cascadeGeometry[n_Integer] := cascadeGeometry[n] = Module[
   {exactQ = (n === 5), c2, vecs, psi, frame, sf, Ts, prepCol, prep, Pmat},
   frame[a_, b_] := {a, b, Cross[a, b]};
   If[exactQ,
     vecs = KCBSDirections[],                       (* exact pentagram, paclet *)
     c2 = Cos[Pi/n]/(1 + Cos[Pi/n]);
     (* kept EXACT (no N-collapse): "Exact" blueprint fields must stay algebraic
        end-to-end; N[] fills only the "Numeric" twin (repo convention). *)
     vecs = Table[{Sqrt[1 - c2] Cos[(n - 1) Pi i/n],
        Sqrt[1 - c2] Sin[(n - 1) Pi i/n], Sqrt[c2]}, {i, 0, n - 1}]];
   psi = {0, 0, 1};
   (* context k frame: shared vertex alternates slot (detector alternation) *)
   sf = Table[If[OddQ[k], frame[vecs[[k]], vecs[[Mod[k, n] + 1]]],
       frame[vecs[[Mod[k, n] + 1]], vecs[[k]]]], {k, n}];
   Ts = Table[sf[[k + 1]] . Transpose[sf[[k]]], {k, n - 1}];
   prepCol = sf[[1]] . psi;
   (* Gram-Schmidt completion of P; only its first column (= prepCol) drives the
      |0>-input statistics (kcbs_circuit.wl line 101-102). *)
   Pmat = Transpose@Select[Orthogonalize[Join[{prepCol}, IdentityMatrix[3]]],
      N[Norm[#]] > 1/2 &];   (* numeric test only; the kept rows stay exact *)
   <|"n" -> n, "Exact" -> exactQ, "Frames" -> sf, "Ts" -> Ts,
     "PrepCol" -> prepCol, "Prep" -> Pmat|>];

(* canonicalise a transition rotation T (fixing one mode) to {orderedModes, angle}
   with a POSITIVE angle, so the KCBS blueprint carries Exact->ArcCos[1/GoldenRatio]
   literally.  Native: test both mode orders against the target matrix. *)
givensCanonical[T_, n_Integer, exactQ_ : False] := Module[
   {fixed, acting, i, j, c, ang, cand},
   fixed = First@Select[Range[n],
      Chop[N[Norm[T[[#]] - UnitVector[n, #]]]] < 10^-8 &&
      Chop[N[Norm[T[[All, #]] - UnitVector[n, #]]]] < 10^-8 &];
   acting = Sort@DeleteCases[Range[n], fixed];
   {i, j} = acting;
   c = If[exactQ, RootReduce[T[[i, i]]], T[[i, i]]];
   (* canonicalise the KCBS diagonal to the literal 1/GoldenRatio so the blueprint
      carries Exact->ArcCos[1/GoldenRatio] (schema), verified by RootReduce *)
   If[exactQ && TrueQ[RootReduce[c - 1/GoldenRatio] === 0], c = 1/GoldenRatio];
   ang = ArcCos[c];
   (* pick the mode order reproducing T with the positive angle *)
   cand = {i, j};
   If[Chop[Max@Abs[N[givens[n, {i, j}, ang] - T]]] > 10^-8, cand = {j, i}];
   {cand, ang}];

(* the scenario cascade as a stage list *)
cascadeStages[n_Integer] := Module[{geo = cascadeGeometry[n], Pmat, stages, gc},
  Pmat = geo["Prep"];
  stages = {<|"Type" -> "Prep", "Modes" -> {1, 2, 3}, "Parameter" -> None,
     "Label" -> "P", "Matrix" -> twin[Pmat]|>};
  Join[stages, Table[
     gc = givensCanonical[geo["Ts"][[k]], 3, geo["Exact"]];
     <|"Type" -> "BS", "Modes" -> gc[[1]], "Parameter" -> twin[gc[[2]]],
       "Label" -> "T" <> ToString[k]|>, {k, n - 1}]]];

CompileInterferometer[spec_Association] := Module[{n, stages, U},
  Which[
    spec["Scenario"] === "KCBS", n = 5,
    spec["Scenario"] === "Cn", n = spec["n"],
    True, Return[$Failed]];
  stages = cascadeStages[n];
  U = StagesToUnitary[stages, 3];
  <|"ModeCount" -> 3, "Stages" -> stages, "Unitary" -> U,
    "Method" -> "LapkiewiczCascade", "Scenario" -> spec["Scenario"], "n" -> n|>];

CompileInterferometer[u_?MatrixQ] :=
  With[{stages = GivensDecompose[u]},
   <|"ModeCount" -> Length[u], "Stages" -> stages,
     "Unitary" -> StagesToUnitary[stages, Length[u]], "Method" -> "Reck"|>];

(* Reck Givens elimination of a special-orthogonal u into two-level rotations.
   Native Table/Reap (no Join-in-loop).  Real-orthogonal path (sufficient for the
   so(3) cascades this module emits); returns the stage list zeroing sub-diagonal
   entries column by column. *)
GivensDecompose[u_?MatrixQ] := Module[{n = Length[u], m = u, stages, a, b, ang, g},
  stages = Reap[
    Do[Do[
       a = m[[i, c]]; b = m[[j, c]];
       If[Chop[N@b] =!= 0,
        ang = ArcTan[a, b];
        g = givens[n, {i, j}, -ang];
        m = g . m;
        Sow[<|"Type" -> "BS", "Modes" -> {i, j}, "Parameter" -> twin[ang],
          "Label" -> "G" <> ToString[i] <> ToString[j]|>]],
      {j, i + 1, n}], {i, 1, n}, {c, i, i}];
    ][[2]];
  If[stages === {}, {}, First[stages]]];

StagesToUnitary[stages_List, n_Integer] := Module[{mats, Uex},
  mats = stageMatrix[#, n] & /@ stages;
  Uex = If[mats === {}, IdentityMatrix[n], Dot @@ Reverse[mats]];
  <|"Exact" -> Uex, "Numeric" -> N[Uex]|>];

(* ---------------------------------------------------------------------------
   MESH ROUTING.  wordRingEdgesFast is copied VERBATIM from
   cluster-state-realization/cct_mesh_sparse_construction.wl (Section 1), per repo
   convention: all 5L edges via one Table of ragged blocks + a single Flatten,
   NO Join-in-loop.
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

CompileMeshRouting[word_String, reps_Integer] := Module[
   {w, L, edges, blocks, routing},
   w = Characters[StringRepeat[word, reps]];
   L = Length[w];
   edges = wordRingEdgesFast[word, reps];
   (* one 3-mode Lapkiewicz block-stage per pentagon (Table, no loop growth) *)
   blocks = Table[<|"Block" -> k, "Modes" -> {3 k + 1, 3 k + 2, 3 k + 3},
      "Letter" -> w[[k + 1]]|>, {k, 0, L - 1}];
   (* routing: block k glues to block k-1's shared pair.  The glue orientation
      INTO block k is set by the FROM-block letter w[[k]] (block k-1's letter):
      wordRingEdgesFast picks {u,v} = If[w[[km+1]]==="c", {3km+1,3km+2},
      {3km+2,3km+1}] with km = k-1, i.e. cis iff w[[k]] === "c". *)
   routing = Table[<|"From" -> k - 1, "To" -> k,
      "SharedModes" -> {3 (k - 1) + 1, 3 (k - 1) + 2},
      "Orientation" -> If[w[[k]] === "c", "cis", "trans"]|>, {k, 1, L - 1}];
   <|"Word" -> word, "Reps" -> reps, "L" -> L, "ModeCount" -> 3 L,
     "Blocks" -> blocks, "Routing" -> routing, "EdgeList" -> edges|>];

(* ============================================================================
   2.  LAYER 2 -- INTENSITY EMULATOR SYNTHESIS
   ---------------------------------------------------------------------------- *)

(* per-context fractions (f00,f01,f10)=(1-2t, t-delta, t+delta); 11 structurally
   absent.  Section order (00,01,10,11) matches CycleScenario / mbqc_blackbox_test.py. *)
IntensityTableKCBS[t_, delta_] := Flatten[Table[{1 - 2 t, t - delta, t + delta, 0}, {5}]];

(* exact rational feasibility LP over the no-disturbance polytope.  Given the
   empirical model e (the target table), confirm a nonnegative per-context
   intensity assignment reproduces it under no-disturbance (CycleCoboundary.e==0)
   with per-context source split <= 1.  LinearOptimization, FLAT variable list,
   Method->RevisedSimplex, exact arithmetic (the NoncontextualFraction precedent). *)
CompileIntensityEmulator[table_List, scenario_Association] := Module[
   {n, ctx, delta, residual, noSig, nonneg, sums, ratQ, vars, rhs, lpCons, lpOK,
    feasible, schedule, nodeSum, ctxSchedule, contexts},
   n = scenario["n"];
   ctx = Partition[table, 4];                       (* per-context {f00,f01,f10,f11} *)
   contexts = scenario["Contexts"];
   delta = CycleCoboundary[n];
   (* --- exact no-disturbance-polytope membership (the honest Q(Sqrt5) certificate) ---
      The intensity emulator (construction iii-d) reproduces the table per-context
      EXACTLY, so feasibility is exactly polytope membership: no-signalling,
      nonnegativity and per-context normalisation, each certified by RootReduce on
      the exact (algebraic) table -- LinearOptimization's rational simplex cannot
      process Q(Sqrt5) equalities, so the exact linear (in)equalities ARE the
      certificate over the extension field. *)
   residual = RootReduce[delta . table];
   noSig = (residual === ConstantArray[0, Length[residual]]) ||
      Chop[N@Norm[delta . table]] == 0;
   nonneg = AllTrue[table, (Simplify[# >= 0] === True) &];
   sums = AllTrue[Range[n], (Simplify[Total[ctx[[#]]] <= 1] === True) &];
   (* --- exact rational feasibility LP (flat var list, RevisedSimplex) ---
      Runs natively when the table is rational (e.g. IntensityTableKCBS[t,delta]
      with rational t); the Q(Sqrt5) quantum table is certified by the exact checks
      above.  Flat single-index variable list (the documented pitfall avoided). *)
   ratQ = AllTrue[table, (IntegerQ[#] || Head[#] === Rational) &];
   lpOK = If[ratQ,
     vars = Array[g, 3 n];
     rhs = Flatten[ctx[[All, {1, 2, 3}]]];
     lpCons = Join[Thread[vars <= rhs], Thread[vars >= rhs], Thread[vars >= 0],
        Table[Sum[vars[[3 (c - 1) + i]], {i, 3}] <= 1, {c, n}]];
     ListQ@Quiet@LinearOptimization[Total[vars], lpCons, vars,
        Method -> "RevisedSimplex"],
     True];
   feasible = noSig && nonneg && sums && lpOK;
   (* per-context schedule *)
   ctxSchedule = Table[<|
      "Context" -> contexts[[c]],
      "Fractions" -> <|"f00" -> twin[ctx[[c, 1]]], "f01" -> twin[ctx[[c, 2]]],
         "f10" -> twin[ctx[[c, 3]]]|>,
      "SourceIntensity" -> 1|>, {c, n}];
   (* NodeSum = the cycle event sum = sum of the n distinct per-node click
      probabilities.  In CycleScenario the contexts are {i,i+1}, so node i is the
      FIRST measurement of exactly one context; its click marginal is that
      context's f10.  Hence the distinct-node sum is Total[f10] (each node once),
      = Sqrt[5] for the KCBS quantum table (no double counting). *)
   nodeSum = Simplify[Total[ctx[[All, 3]]]];
   schedule = <|
      "Feasible" -> feasible, "Scenario" -> scenario,
      "IntensitySchedule" -> ctxSchedule,
      "TableReproduced" -> twin[table],
      "NodeSum" -> twin[nodeSum],
      "ContextualFraction" -> twin[ContextualFraction[scenario, table]],
      "SignalingResidual" -> If[noSig, 0, twin[Norm[residual]]]|>;
   schedule];

(* ============================================================================
   3.  LAYER 3 -- DISPATCHER (so(3) via paclet; CV via Sp(2n,R) port)
   ---------------------------------------------------------------------------- *)

$dlaCache = <||>;   (* memoise DLA verdicts keyed by the exact generator set *)

componentAudit[comp_Association] := Module[{gens, span, dla, leaf, verdict, layer},
  Which[
   KeyExistsQ[comp, "Generators"] && comp["Generators"] =!= {},
     gens = comp["Generators"];
     {span, dla} = Lookup[$dlaCache, Key[gens], Module[{sp, dl},
        sp = MatrixRank[So3Axis /@ gens, Tolerance -> 10^-8];
        dl = DLADimension[gens];
        $dlaCache[gens] = {sp, dl}; {sp, dl}]];
     leaf = dla < 3;
     verdict = If[leaf, "emulable", "genuine"];
     layer = If[leaf, "L2", "L1"],
   True,                                            (* table-only component *)
     span = 0; dla = 0; leaf = True; verdict = "emulable"; layer = "L2"];
  <|"Name" -> Lookup[comp, "Name", "component"], "Span" -> span,
    "DLADimension" -> dla, "LeafConfined" -> leaf, "Verdict" -> verdict,
    "Layer" -> layer|>];

DispatchLayers[targetSpec_Association] := Module[{comps, audits, layers, overall},
  comps = Lookup[targetSpec, "Components", {targetSpec}];
  audits = componentAudit /@ comps;
  layers = Union[#["Layer"] & /@ audits];
  overall = Which[layers === {"L1"}, "L1", layers === {"L2"}, "L2",
     True, "Mixed"];
  <|"Components" -> audits, "OverallLayer" -> overall|>];

(* ---------------------------------------------------------------------------
   MESH per-block genuine-vs-emulable audit (closes the honest
   Missing["NotComputed"] stub left by EmitBlueprint's Mesh branch and
   BlackBoxCertifier.wl's blueprintDLA -- see KNOWN_ISSUES.md and
   figure-gallery/so3_leaf_confinement_sphere.wl's header for why the
   naive shortcut ("reuse CascadeGenerators[] for an arbitrary word, assuming
   UNROTATED standard axes") was previously investigated and rejected: it
   asserted a raw NUMERICAL identity of physical axes across cis/trans
   routing that was never checked against this mesh's real construction.

   WHAT THIS DOES INSTEAD (a narrower, VERIFIED claim, not that rejected one):
   CascadeGenerators[] is built purely from the ABSTRACT KCBS-pentagon
   combinatorial pattern (KCBSDirections[] never references physical mode
   numbers or routing at all), and this very module already relies on that
   same abstractness to reuse CascadeGenerators[] verbatim for arbitrary Cn
   scenarios (scenarioComponents's Cn branch: "so(3) audit is n-independent:
   genuine"). Separately, the DLA-dimension rank computation is invariant
   under any fixed change of basis: conjugating so(3) generators by a
   rotation only rotates their axis vectors (So3Axis), so MatrixRank of the
   axis set is unchanged regardless of WHICH physical rotation a cis/trans
   routing choice corresponds to. So the only thing that actually needs
   checking -- and the only thing the previous attempt skipped -- is whether
   a given mesh block's own local exclusivity structure really IS a genuine,
   non-degenerate 5-cycle (a bona fide independent KCBS-pentagon unit, not a
   collapsed/merged structure at small L). meshDLAAudit verifies exactly that,
   block by block, directly from the blueprint's OWN stored edge list (never
   assumed), and only THEN applies the existing so(3) audit.

   SCOPE, STATED HONESTLY: this certifies per-block LOCAL genuineness only --
   consistent with the compiler's documented block-local honest scope. It
   makes NO claim whatsoever about JOINT/global entanglement across the whole
   mesh's su(2^n) qubits; that route is separately tracked, currently
   computationally infeasible past ~14 qubits (cluster-state-realization/
   cct_cluster_dla.wl, SKIPPED_INFEASIBLE), and remains its own open item --
   not something this closes. *)
meshBlockEdges[w_List, L_Integer, k_Integer] := Module[{km, u, v},
  km = Mod[k - 1, L];
  {u, v} = If[w[[km + 1]] === "c", {3 km + 1, 3 km + 2}, {3 km + 2, 3 km + 1}];
  Sort /@ {{u, v}, {u, 3 k + 1}, {3 k + 1, 3 k + 2}, {3 k + 2, 3 k + 3}, {3 k + 3, v}}];

(* A block's own 5 edges form a genuine KCBS-pentagon unit iff they are a
   simple 5-cycle: exactly 5 distinct vertices, each of degree 2, connected.
   At small L (block routes to itself / a near neighbour) this can degenerate
   -- correctly flagged False rather than assumed True. *)
meshBlockCycleQ[blockEdges_List] := Module[{verts, g},
  verts = Union[Flatten[blockEdges]];
  If[Length[DeleteDuplicates[blockEdges]] =!= 5 || Length[verts] =!= 5, False,
    g = Graph[verts, UndirectedEdge @@@ blockEdges];
    ConnectedGraphQ[g] && AllTrue[VertexDegree[g], # == 2 &]]];

(* JOINT (global) entanglement of the mesh's corresponding graph-state topology
   (2026-07-14 addition, closing the "JointEntanglementAudited"->False gap left
   above -- see cluster-state-realization/cct_cluster_dla.wl's Section 10 for the
   full derivation, citations, and validation this reuses).

   SCOPE, STATED PRECISELY: this is NOT the su(2^n) dynamical-Lie-algebra /
   universal-controllability question (that remains its own separate, genuinely
   open, infeasible-past-~14-qubits problem -- cct_cluster_dla.wl Sections 6-9).
   It is the strictly easier, well-posed question of whether the ABSTRACT graph
   state this mesh word/reps topology encodes (were it realized as a genuine
   multi-qubit CZ cluster state, exactly as cluster-state-realization's own
   NewGraphStateTableau/cct_cluster_dla.wl construction does) is genuinely
   multipartite entangled (GME) -- i.e. whether it factorizes as a product
   state across ANY bipartition. By Hein-Eisert-Briegel (PRA 69, 062311, 2004):
   a graph state is GME iff its graph is connected -- an O(V+E) check, exact at
   any mesh size, never sharing the DLA route's exponential blow-up.

   IMPORTANT: this certifies a fact about the TOPOLOGY / the corresponding
   qubit-based cluster-state construction, NOT a claim that optical-synthesis's own
   OPTICAL Mesh blueprint physically realizes that entanglement -- per this
   file's own "HONEST SCOPE" header, single-photon linear optics cannot
   construct global entanglement without exponential mode count or KLM
   nonlinearity, and the Mesh layer as built here (Stages = combinatorial
   routing only, no per-block Unitary/IntensitySchedule yet specified) makes
   no such physical claim either. *)
meshGraphStateGMEQ[n_Integer, edges_List] := ConnectedGraphQ[Graph[Range[n], UndirectedEdge @@@ edges]];

meshDLAAudit[word_String, reps_Integer, storedEdges_List] := Module[
   {w, L, blockData, allVerified, allGenuine, gens, span, dla, nModes, jointGME},
   w = Characters[StringRepeat[word, reps]];
   L = Length[w];
   nModes = 3 L;
   gens = CascadeGenerators[];
   {span, dla} = Lookup[$dlaCache, Key[gens], Module[{sp, dl},
      sp = MatrixRank[So3Axis /@ gens, Tolerance -> 10^-8];
      dl = DLADimension[gens];
      $dlaCache[gens] = {sp, dl}; {sp, dl}]];
   blockData = Table[Module[{be = meshBlockEdges[w, L, k], cycleOK, inBP},
      cycleOK = meshBlockCycleQ[be];
      inBP = SubsetQ[storedEdges, DeleteDuplicates[be]];
      <|"Block" -> k, "Modes" -> {3 k + 1, 3 k + 2, 3 k + 3}, "Letter" -> w[[k + 1]],
        "CycleVerified" -> cycleOK, "InBlueprintEdgeList" -> inBP,
        "Span" -> If[cycleOK && inBP, span, Missing["BlockNotVerified"]],
        "DLADimension" -> If[cycleOK && inBP, dla, Missing["BlockNotVerified"]],
        "LeafConfined" -> If[cycleOK && inBP, dla < 3, Missing["BlockNotVerified"]],
        "Verdict" -> If[cycleOK && inBP, If[dla < 3, "emulable", "genuine"],
           Missing["BlockNotVerified"]]|>],
     {k, 0, L - 1}];
   allVerified = AllTrue[blockData, TrueQ[#["CycleVerified"]] && TrueQ[#["InBlueprintEdgeList"]] &];
   allGenuine = allVerified && AllTrue[blockData, #["Verdict"] === "genuine" &];
   jointGME = meshGraphStateGMEQ[nModes, storedEdges];
   <|"Name" -> "pentagon-mesh",
     "Span" -> If[allVerified, span, Missing["BlockNotVerified"]],
     "DLADimension" -> If[allVerified, dla, Missing["BlockNotVerified"]],
     "LeafConfined" -> If[allVerified, !allGenuine, Missing["BlockNotVerified"]],
     "Verdict" -> If[allVerified, If[allGenuine, "genuine", "mixed"], Missing["BlockNotVerified"]],
     "Layer" -> "Mesh",
     "Blocks" -> blockData,
     "AllBlocksVerified" -> allVerified,
     "Method" -> "Per-block structural C5-isomorphism check against the blueprint's own stored edge list, then the existing so(3) CascadeGenerators/DLADimension audit reused per verified block (same n-independent-cascade precedent already used for Cn scenarios).",
     "JointEntanglementAudited" -> True,
     "JointlyEntangledTopology" -> jointGME,
     "JointEntanglementMethod" -> "Graph-connectivity GME certificate (Hein-Eisert-Briegel PRA 69, 062311 (2004); O(V+E), exact at any mesh size) applied to the mesh's own stored edge list -- see cct_cluster_dla.wl Section 10. Certifies the ABSTRACT graph-state topology only, NOT that this optical Mesh blueprint physically realizes it (still block-local per this module's honest scope; no per-block Unitary/IntensitySchedule is specified at the Mesh layer today).",
     "ScopeNote" -> "Per-block LOCAL genuineness certified above (so(3) DLA, per block). JointlyEntangledTopology certifies GME of the corresponding graph-state topology (poly-time, any size) -- a DIFFERENT and easier question than su(2^n) universal controllability, which remains its own separate, open, infeasible-past-~14-qubits problem (cct_cluster_dla.wl Sections 6-9) and is NOT resolved here."|>];

(* ---------------------------------------------------------------------------
   CV column: Sp(2n,R) leaf-confinement.  Ported from
   certification-protocol/final_o3_cv_dla.py (exact matrix Lie closure;
   confined <=> closure subset u(n), all antisymmetric, dim <= n^2), with
   attribution.  Quadrature order (x1,p1,...,xn,pn).
   --------------------------------------------------------------------------- *)
cvOmega[n_] := Module[{o = ConstantArray[0, {2 n, 2 n}]},
   Do[o[[2 j - 1, 2 j]] = 1; o[[2 j, 2 j - 1]] = -1, {j, n}]; o];
cvSymG[n_, terms_] := Module[{g = ConstantArray[0, {2 n, 2 n}]},
   Do[With[{a = tt[[1]], b = tt[[2]], cc = tt[[3]]},
      If[a == b, g[[a, a]] += cc, (g[[a, b]] += cc/2; g[[b, a]] += cc/2)]], {tt, terms}]; g];
cvGen[n_, g_] := cvOmega[n] . g;
cvX[j_] := 2 j - 1; cvP[j_] := 2 j;
cvPhase[n_, j_] := cvGen[n, cvSymG[n, {{cvX[j], cvX[j], 1}, {cvP[j], cvP[j], 1}}]];
cvBSre[n_, j_, k_] := cvGen[n, cvSymG[n, {{cvX[j], cvX[k], 1}, {cvP[j], cvP[k], 1}}]];
cvBSim[n_, j_, k_] := cvGen[n, cvSymG[n, {{cvX[j], cvP[k], 1}, {cvP[j], cvX[k], -1}}]];
cvSq1[n_, j_] := cvGen[n, cvSymG[n, {{cvX[j], cvX[j], 1}, {cvP[j], cvP[j], -1}}]];
cvSq2re[n_, j_, k_] := cvGen[n, cvSymG[n, {{cvX[j], cvX[k], 1}, {cvP[j], cvP[k], -1}}]];
cvSq2im[n_, j_, k_] := cvGen[n, cvSymG[n, {{cvX[j], cvP[k], 1}, {cvP[j], cvX[k], 1}}]];

cvFlat[m_] := Flatten[m];
cvRank[mats_] := If[mats === {}, 0, MatrixRank[cvFlat /@ mats]];
cvComm[a_, b_] := a . b - b . a;
cvLieClosure[gens_List, maxit_ : 64] := Module[{basis = {}, new, added, c},
  Do[If[cvRank[Append[basis, gg]] > cvRank[basis], AppendTo[basis, gg]], {gg, gens}];
  Do[new = basis; added = False;
    Do[Do[c = cvComm[basis[[i]], basis[[j]]];
       If[! (c === 0 c) && cvRank[Append[new, c]] > Length[new],
        AppendTo[new, c]; added = True], {j, i + 1, Length[basis]}], {i, Length[basis]}];
    basis = new; If[! added, Break[]], {maxit}];
  basis];
cvCompactQ[basis_] := AllTrue[basis, (# + Transpose[#]) === 0 # &];

CVLeafConfinedQ[gens_List, n_Integer] := Module[{basis, d, compact},
  basis = cvLieClosure[gens]; d = cvRank[basis]; compact = cvCompactQ[basis];
  <|"Dim" -> d, "UN" -> n^2, "Sp" -> n (2 n + 1), "Compact" -> compact,
    "Confined" -> (compact && d <= n^2)|>];

(* the three pre-registered CV validation generator sets (final_o3_cv_dla.py) *)
cvValidationSets[] := {
  {"(i) beamsplitter + phases, 2 modes", 2,
    {cvPhase[2, 1], cvPhase[2, 2], cvBSre[2, 1, 2], cvBSim[2, 1, 2]}},
  {"(ii) (i) + two-mode squeezer, 2 modes", 2,
    {cvPhase[2, 1], cvPhase[2, 2], cvBSre[2, 1, 2], cvBSim[2, 1, 2],
     cvSq2re[2, 1, 2], cvSq2im[2, 1, 2]}},
  {"(iii) single-mode squeezer + phase, 1 mode", 1,
    {cvPhase[1, 1], cvSq1[1, 1]}}};

(* ============================================================================
   4.  BLUEPRINT EMISSION
   ---------------------------------------------------------------------------- *)

Options[EmitBlueprint] = {Method -> Automatic};

(* build the per-component targetSpec DispatchLayers consumes, from a scenario spec *)
scenarioComponents[spec_Association, forcedLayer_] := Which[
  forcedLayer === "L2" || KeyExistsQ[spec, "Table"],
    {<|"Name" -> Lookup[spec, "Scenario", "table"], "Table" -> True|>},
  spec["Scenario"] === "KCBS",
    {<|"Name" -> "KCBS-cascade", "Generators" -> CascadeGenerators[]|>},
  spec["Scenario"] === "Cn",
    {<|"Name" -> "C" <> ToString[spec["n"]] <> "-cascade",
       "Generators" -> CascadeGenerators[]|>},   (* so(3) audit is n-independent: genuine *)
  KeyExistsQ[spec, "Components"], spec["Components"],
  True, {spec}];

EmitBlueprint[targetSpec_Association, opts : OptionsPattern[]] := Module[
   {method, dispatch, layer, comps, bp, mesh, sched, ci, n, verdict, sch, prov},
   method = OptionValue[Method];
   (* MESH target *)
   If[KeyExistsQ[targetSpec, "Word"],
    mesh = CompileMeshRouting[targetSpec["Word"], targetSpec["Reps"]];
    (* MESH DLA AUDIT CLOSED (2026-07-14): this used to hardcode
       "LeafConfined"->True, "Verdict"->"emulable" regardless of word/reps
       (a fabricated conclusion), then honestly downgraded to Missing[] once
       that was caught, because no content-aware, tractable DLA test for a
       Mesh blueprint existed anywhere in this repo: the so(3)
       CascadeGenerators[] cascade is KCBS-specific (reusing it for an
       arbitrary word by ASSUMING unrotated standard axes was investigated
       and could not be substantiated -- see figure-gallery/
       so3_leaf_confinement_sphere.wl's header), and the su(2^n)
       cluster-state DLA route (cluster-state-realization/cct_cluster_dla.wl)
       hits SKIPPED_INFEASIBLE past ~14 qubits -- this blueprint's own
       reps=2 case is 18 qubits. meshDLAAudit (defined above, Section 3)
       closes this properly: instead of assuming axes are unrotated, it
       VERIFIES per block, from this blueprint's own edge list, that the
       block really is an isomorphic KCBS-pentagon (5-cycle) unit, and only
       then applies the existing so(3) audit -- a verified precondition
       replacing an unverified assumption. It still makes NO joint/global
       entanglement claim (see "JointEntanglementAudited" in its output);
       that su(2^n) route remains its own separate open item. See
       BlackBoxCertifier.wl's blueprintDLA (generic over this shape, no
       change needed) and KNOWN_ISSUES.md for the historical record. *)
    verdict = <|"Mesh" -> meshDLAAudit[targetSpec["Word"], targetSpec["Reps"], mesh["EdgeList"]]|>;
    bp = <|
      "TargetSpec" -> targetSpec, "ModeCount" -> mesh["ModeCount"], "Layer" -> "Mesh",
      "Stages" -> mesh["Blocks"], "Routing" -> mesh["Routing"],
      "IntensitySchedule" -> Missing[], "Unitary" -> Missing[],
      "MeshEdgeList" -> mesh["EdgeList"],
      "CertificationVerdict" -> verdict,
      "Schematic" -> Null, "Provenance" -> provenance[targetSpec],
      "SelfCertification" -> Missing[]|>;
    bp["Schematic"] = OpticalCompilerSchematic[bp];
    Return[bp]];
   (* scenario / component targets: dispatch *)
   comps = scenarioComponents[targetSpec, method];
   dispatch = DispatchLayers[<|"Components" -> comps|>];
   layer = Switch[method, "L1", "L1", "L2", "L2", "Mesh", "Mesh",
      _, dispatch["OverallLayer"]];
   verdict = Association@MapThread[#2["Name"] -> Append[#2, "Layer" -> layer] &,
      {comps, dispatch["Components"]}];
   Which[
    layer === "L1",
      ci = CompileInterferometer[targetSpec]; n = ci["ModeCount"];
      bp = <|"TargetSpec" -> targetSpec, "ModeCount" -> n, "Layer" -> "L1",
         "Stages" -> ci["Stages"], "Routing" -> Missing[],
         "IntensitySchedule" -> Missing[], "Unitary" -> ci["Unitary"],
         "CertificationVerdict" -> verdict, "Schematic" -> Null,
         "Provenance" -> provenance[targetSpec], "SelfCertification" -> Missing[]|>,
    layer === "L2",
      sched = CompileIntensityEmulator[
         Lookup[targetSpec, "Table", IntensityTableKCBS[1/Sqrt[5], 0]],
         Lookup[targetSpec, "Scenario2", CycleScenario[5]]];
      bp = <|"TargetSpec" -> targetSpec, "ModeCount" -> 1, "Layer" -> "L2",
         "Stages" -> intensityStages[sched], "Routing" -> Missing[],
         "IntensitySchedule" -> sched["IntensitySchedule"], "Unitary" -> Missing[],
         "CertificationVerdict" -> verdict, "Schedule" -> sched,
         "Schematic" -> Null, "Provenance" -> provenance[targetSpec],
         "SelfCertification" -> Missing[]|>,
    True, Return[$Failed]];
   bp["Schematic"] = OpticalCompilerSchematic[bp];
   bp];

provenance[targetSpec_] := <|"Targets" -> targetSpec, "Anchors" -> $anchors,
   "Date" -> $emitDate, "Citations" -> $citations|>;

(* an L2 schedule rendered as source/splitter/detector stage atoms *)
intensityStages[sched_Association] := Module[{cs = sched["IntensitySchedule"]},
  Flatten@Table[{
     <|"Type" -> "Source", "Modes" -> {1}, "Parameter" -> None, "Label" -> "src"|>,
     <|"Type" -> "Detector", "Modes" -> c["Context"],
       "Parameter" -> c["Fractions"]["f10"], "Label" -> "det"|>}, {c, cs}]];

(* ============================================================================
   5.  SCHEMATIC RENDERER
   ---------------------------------------------------------------------------- *)

OpticalCompilerSchematic[bp_Association] := Which[
  bp["Layer"] === "L1", schematicL1[bp],
  bp["Layer"] === "L2", schematicL2[bp],
  bp["Layer"] === "Mesh", schematicMesh[bp],
  True, Graphics[{Text["(empty blueprint)", {0, 0}]}]];

(* ---- shared visual style (2026-07-14 pass): soft-glow nodes, smooth round-capped
   wires, a compact numeric angle label with the exact closed form on Tooltip (fixes
   long algebraic labels overlapping at high stage counts, e.g. the C7 heptagon),
   rounded block glyphs. Presentation-only: no Stages/Routing/IntensitySchedule
   numeric content is touched by any of this. ---- *)
$schemInk = GrayLevel[0.12]; $schemSub = GrayLevel[0.40]; $schemGrid = GrayLevel[0.80];
$schemSrc = RGBColor[0.14, 0.40, 0.70]; $schemDet = RGBColor[0.80, 0.34, 0.16];
$schemMuted = RGBColor[0.55, 0.57, 0.63];
schemWire[{x1_, y1_}, {x2_, y2_}] := {$schemGrid, CapForm["Round"], JoinForm["Round"],
   Thickness[0.0026], Line[{{x1, y1}, {x2, y2}}]};
schemNode[{x_, y_}, col_] := {EdgeForm[None], {Opacity[0.16], col, Disk[{x, y}, 0.273]},
   {Opacity[0.30], col, Disk[{x, y}, 0.195]}, col, Disk[{x, y}, 0.13], White, Opacity[0.9], Disk[{x, y}, 0.0416]};
schemDetector[{x_, y_}, a_, col_] := {EdgeForm[None],
   {Opacity[0.16], col, Disk[{x, y}, 0.323, {a - 0.62, a + 0.62}]}, col, Disk[{x, y}, 0.17, {a - 0.44, a + 0.44}]};
schemBS[{x_, y1_}, {x_, y2_}, wsz_, col_] := {CapForm["Round"], JoinForm["Round"],
   {Opacity[0.22], col, Thickness[0.011], Line[{{x - wsz, y1}, {x + wsz, y2}}], Line[{{x - wsz, y2}, {x + wsz, y1}}]},
   {col, Thickness[0.0032], Line[{{x - wsz, y1}, {x + wsz, y2}}], Line[{{x - wsz, y2}, {x + wsz, y1}}]},
   {White, EdgeForm[Directive[col, Thickness[0.0022]]], Disk[{x, (y1 + y2)/2}, 0.045]}};
schemAngleLabel[Automatic, numeric_] := Tooltip[Style[NumberForm[N[numeric], {5, 4}], $schemSub, 9],
   NumberForm[numeric, {16, 15}]];
schemAngleLabel[exact_, numeric_] := Tooltip[Style[NumberForm[N[numeric], {5, 4}], $schemSub, 9],
   TraditionalForm[exact]];

schematicL1[bp_Association] := Module[{n = 3, stages, xs, prims},
  stages = bp["Stages"];
  xs = Range[Length[stages]];
  prims = Join[
    (* mode lines, glowing sources, detector wedges *)
    Table[schemWire[{0, m}, {Length[stages] + 1, m}], {m, n}],
    Table[schemNode[{0, m}, $schemSrc], {m, n}],
    Table[schemDetector[{Length[stages] + 1, m}, 0, $schemDet], {m, n}],
    (* stage glyphs *)
    Flatten@Table[
      With[{st = stages[[k]], x = xs[[k]]},
       Switch[st["Type"],
        "Prep", {EdgeForm[None], {Opacity[0.88], $schemInk,
           Rectangle[{x - 0.22, 0.6}, {x + 0.22, n + 0.4}, RoundingRadius -> 0.06]},
          White, Text[Style[st["Label"], Bold, 12], {x, (n + 1)/2}]},
        "BS", With[{i = st["Modes"][[1]], j = st["Modes"][[2]]},
          {schemBS[{x, i}, {x, j}, 0.20, $schemInk],
           Text[schemAngleLabel[st["Parameter"]["Exact"], st["Parameter"]["Numeric"]], {x, n + 0.38}],
           Text[Style[st["Label"], 9, $schemSub], {x, Min[i, j] - 0.3}]}],
        _, {}]], {k, Length[stages]}]];
  Graphics[prims, PlotRange -> {{-0.5, Length[stages] + 1.6}, {0.15, n + 0.75}},
    ImageSize -> 560, AspectRatio -> 0.48, Background -> White,
    PlotLabel -> Style["Layer 1 interferometer  (" <> ToString[bp["Layer"]] <> ")", 13, $schemInk]]];

schematicL2[bp_Association] := Module[{cs = bp["IntensitySchedule"], nrows, prims},
  nrows = Length[cs];
  prims = Flatten@Table[
    With[{y = nrows - c + 1, ctx = cs[[c]]},
     {schemWire[{0, y}, {4, y}], schemNode[{0, y}, $schemSrc],
      Text[Style["ctx " <> ToString[ctx["Context"]], 9, $schemInk], {0.62, y + 0.30}],
      (* three splitter fractions: compact numeric, exact form on Tooltip *)
      Text[Style["f00=", 8, $schemDet], {1.85, y + 0.28}],
      Text[schemAngleLabel[ctx["Fractions"]["f00"]["Exact"], ctx["Fractions"]["f00"]["Numeric"]], {2.35, y + 0.28}],
      Text[Style["f01=", 8, $schemDet], {1.85, y}],
      Text[schemAngleLabel[ctx["Fractions"]["f01"]["Exact"], ctx["Fractions"]["f01"]["Numeric"]], {2.35, y}],
      Text[Style["f10=", 8, $schemDet], {1.85, y - 0.28}],
      Text[schemAngleLabel[ctx["Fractions"]["f10"]["Exact"], ctx["Fractions"]["f10"]["Numeric"]], {2.35, y - 0.28}],
      schemDetector[{4, y}, 0, $schemDet]}],
    {c, nrows}];
  Graphics[prims, PlotRange -> {{-0.5, 5}, {0, nrows + 1}}, ImageSize -> 560, Background -> White,
    PlotLabel -> Style["Layer 2 intensity emulator (per-context splitter schedule)", 13, $schemInk]]];

schematicMesh[bp_Association] := Module[{routing = bp["Routing"], blocks = bp["Stages"], prims, blockX},
  blockX[idx_] := 1.35 idx;
  prims = Join[
    (* block index key: "Index" (Builder A, authoritative) or "Block" (this module);
       rounded, glow-tinted blocks colored by letter (c=structural, t=trans-highlight) *)
    Table[With[{x = blockX[Lookup[b, "Index", Lookup[b, "Block", 0]]], letter = b["Letter"]},
      Module[{col = If[letter == "t", $schemDet, $schemSrc]},
       {EdgeForm[None], {Opacity[0.14], col, Rectangle[{x - 0.46, -0.46}, {x + 0.46, 0.46}, RoundingRadius -> 0.12]},
        {col, Rectangle[{x - 0.4, -0.4}, {x + 0.4, 0.4}, RoundingRadius -> 0.10]},
        White, Text[Style[b["Letter"], Bold, 13], {x, 0}],
        $schemSub, Text[Style["blk " <> ToString[Lookup[b, "Index", Lookup[b, "Block", 0]]], 8], {x, -0.68}]}]],
      {b, blocks}],
    (* smooth Bezier routing arcs, arched above the blocks; trans-orientation highlighted *)
    Table[With[{x1 = blockX[r["From"]], x2 = blockX[r["To"]], transQ = (r["Orientation"] === "trans")},
      Module[{col = If[transQ, $schemDet, $schemMuted], yArc = 0.62},
       {col, CapForm["Round"], Thickness[If[transQ, 0.008, 0.005]], Arrowheads[0.05],
        Arrow[BezierCurve[{{x1 + 0.42, 0.05}, {(x1 + x2)/2, yArc}, {x2 - 0.42, 0.05}}]],
        Text[Style[r["Orientation"], 8, If[transQ, $schemDet, $schemSub]], {(x1 + x2)/2, yArc + 0.16}]}]],
      {r, routing}]];
  Graphics[prims, PlotRange -> All, ImageSize -> 620, AspectRatio -> 0.36, Background -> White,
    PlotLabel -> Style["Pentagon-mesh routing  word=" <> bp["TargetSpec"]["Word"] <>
       "  reps=" <> ToString[bp["TargetSpec"]["Reps"]], 13, $schemInk]]];

OpticalCompilerExportSchematics[dir_String] := Module[{bps, files},
  If[! DirectoryQ[dir], CreateDirectory[dir, CreateIntermediateDirectories -> True]];
  bps = {{"kcbs_L1", EmitBlueprint[<|"Scenario" -> "KCBS"|>]},
         {"kcbs_L2", EmitBlueprint[<|"Scenario" -> "KCBS"|>, Method -> "L2"]},
         {"mesh_cct2", EmitBlueprint[<|"Word" -> "cct", "Reps" -> 2|>]}};
  files = Flatten@Table[
     With[{name = b[[1]], g = b[[2]]["Schematic"]},
      {Export[FileNameJoin[{dir, name <> ".png"}], g, ImageResolution -> 200],
       Export[FileNameJoin[{dir, name <> ".pdf"}], g]}], {b, bps}];
  files];

(* ============================================================================
   6.  SELF-CERTIFICATION LOOP (gate A5)
   ---------------------------------------------------------------------------- *)

(* recompute the KCBS/Cn context statistics from a blueprint's own stage list *)
l1ContextProbs[bp_Association] := Module[
   {stages, prep, bsStages, prepCol, n, prefixState, probs},
   stages = bp["Stages"];
   prep = SelectFirst[stages, #["Type"] === "Prep" &];
   bsStages = Select[stages, #["Type"] === "BS" &];
   prepCol = prep["Matrix"]["Exact"][[All, 1]];
   n = Length[bsStages] + 1;                         (* number of contexts *)
   prefixState[k_] := If[k == 1, prepCol,
      (Dot @@ Reverse[stageMatrix[#, 3] & /@ Take[bsStages, k - 1]]) . prepCol];
   probs = Table[prefixState[k]^2, {k, n}];
   probs];

VerifyBlueprint[bp_Association] := Module[
   {layer, statMatch, maxDev, targetOK, dlaOK, verdict, ok},
   layer = bp["Layer"];
   Which[
    layer === "L1",
      Module[{probs, S, expProbs, expS, comp, exactQ},
       exactQ = MatchQ[bp["TargetSpec"]["Scenario"], "KCBS"];
       probs = l1ContextProbs[bp];
       S = Total[(#[[3]] - #[[1]] - #[[2]]) & /@ probs];
       If[exactQ,
         expProbs = ConstantArray[{1/Sqrt[5], 1/Sqrt[5], 1 - 2/Sqrt[5]}, 5];
         expS = 5 - 4 Sqrt[5];
         statMatch = (RootReduce[S - expS] === 0) &&
            (RootReduce[Flatten[probs - expProbs]] === ConstantArray[0, 15]);
         maxDev = Max[Abs[N[Flatten[probs - expProbs]]]],
         (* Cn numeric: compare to Lovasz-family identity n-4 theta(Cn) *)
         Module[{nn = bp["TargetSpec"]["n"], th},
          th = nn Cos[Pi/nn]/(1 + Cos[Pi/nn]);
          statMatch = Abs[N[S - (nn - 4 th)]] < 10^-8;
          maxDev = Abs[N[S - (nn - 4 th)]]]];
       targetOK = statMatch;
       (* DLA audit: the cascade is genuine (dla 3) => Layer L1 *)
       comp = First@Values[bp["CertificationVerdict"]];
       dlaOK = (comp["Verdict"] === "genuine") && (comp["Layer"] === "L1") &&
          (DLADimension[CascadeGenerators[]] >= 3)],
    layer === "L2",
      Module[{sched, folded, target, cf},
       sched = bp["Schedule"];
       (* fold the intensity schedule back to a table and compare exactly *)
       folded = Flatten[{#["Fractions"]["f00"]["Exact"], #["Fractions"]["f01"]["Exact"],
            #["Fractions"]["f10"]["Exact"], 0} & /@ bp["IntensitySchedule"]];
       target = sched["TableReproduced"]["Exact"];
       statMatch = (RootReduce[folded - target] === ConstantArray[0, Length[target]]);
       maxDev = Max[Abs[N[folded - target]]];
       targetOK = statMatch && sched["Feasible"];
       (* DLA audit: a table-only / leaf-confined rig => Layer L2 *)
       Module[{comp = First@Values[bp["CertificationVerdict"]]},
        dlaOK = (comp["Verdict"] === "emulable") && (comp["Layer"] === "L2") &&
           TrueQ[comp["LeafConfined"]]]],
    layer === "Mesh",
      Module[{rebuilt, stored, freshAudit, storedAudit},
       rebuilt = wordRingEdgesFast[bp["TargetSpec"]["Word"], bp["TargetSpec"]["Reps"]];
       stored = bp["MeshEdgeList"];
       statMatch = (Sort[rebuilt] === Sort[stored]);
       maxDev = 0;
       targetOK = statMatch;
       (* MESH DLA AUDIT CLOSED (2026-07-14): this used to just check that
          the "Layer" tag reads "Mesh" -- a tag EmitBlueprint sets on itself
          moments earlier, so the comparison was tautological and could
          never catch a fabricated verdict (this is exactly how the
          LeafConfined->True hardcode upstream went undetected by gate A5).
          Now it genuinely RE-DERIVES the per-block audit from the
          blueprint's own TargetSpec + MeshEdgeList (self-certification
          discipline, matching L1/L2's own re-simulate-from-stored-data
          convention) and requires the fresh recomputation to agree with
          the stored verdict -- a real, non-tautological, independent check.
          See meshDLAAudit's header (Section 3) for the scope/reasoning;
          still makes no joint/global entanglement claim. *)
       storedAudit = bp["CertificationVerdict"]["Mesh"];
       freshAudit = meshDLAAudit[bp["TargetSpec"]["Word"], bp["TargetSpec"]["Reps"], stored];
       dlaOK = statMatch && (storedAudit["Layer"] === "Mesh") &&
          TrueQ[storedAudit["AllBlocksVerified"]] && TrueQ[freshAudit["AllBlocksVerified"]] &&
          (freshAudit["Verdict"] === storedAudit["Verdict"]) &&
          (freshAudit["DLADimension"] === storedAudit["DLADimension"])],
    True, statMatch = False; maxDev = Infinity; targetOK = False; dlaOK = False];
   ok = TrueQ[statMatch] && TrueQ[targetOK] && TrueQ[dlaOK];
   <|"StatisticsMatch" -> TrueQ[statMatch], "MaxDeviation" -> maxDev,
     "TargetReproduced" -> TrueQ[targetOK], "DLAVerdictConsistent" -> TrueQ[dlaOK],
     "OK" -> ok|>];

(* ============================================================================
   7.  MODULE VERDICT -- anchors A1-A5 (delayed; nothing runs on bare Get)
   ---------------------------------------------------------------------------- *)

OpticalCompilerVerification := Module[
   {bpKCBS, vKCBS, a1, bp7, v7ok, a2, schKCBS, a3, a4reps, a4, bpL2, vL2,
    bpMesh, vMesh, a5, cvSets, cvA, allOK},

   (* ---- A1: KCBS pentagon reproduces the Lapkiewicz cascade EXACTLY ---- *)
   bpKCBS = EmitBlueprint[<|"Scenario" -> "KCBS"|>];
   vKCBS = VerifyBlueprint[bpKCBS];
   a1 = <|
     "BSAnglesExact" -> AllTrue[Select[bpKCBS["Stages"], #["Type"] === "BS" &],
        RootReduce[Cos[#["Parameter"]["Exact"]] - 1/GoldenRatio] === 0 &],
     "Period2" -> With[{bs = Select[bpKCBS["Stages"], #["Type"] === "BS" &]},
        (bs[[1]]["Modes"] === bs[[3]]["Modes"]) &&
        (bs[[2]]["Modes"] === bs[[4]]["Modes"]) &&
        (RootReduce[bs[[1]]["Parameter"]["Exact"] - bs[[3]]["Parameter"]["Exact"]] === 0)],
     "T1Modes" -> (Sort@Select[bpKCBS["Stages"], #["Label"] === "T1" &][[1]]["Modes"] === {1, 3}),
     "T2Modes" -> (Sort@Select[bpKCBS["Stages"], #["Label"] === "T2" &][[1]]["Modes"] === {2, 3}),
     "StatMatch" -> vKCBS["StatisticsMatch"], "MaxDev" -> vKCBS["MaxDeviation"],
     "SelfCertOK" -> vKCBS["OK"]|>;
   a1["OK"] = a1["BSAnglesExact"] && a1["Period2"] && a1["T1Modes"] && a1["T2Modes"] &&
      a1["StatMatch"] && (a1["MaxDev"] < 10^-12) && a1["SelfCertOK"];

   (* ---- A2: C7 target -> n=7 cascade (numeric identity S = n - 4 theta) ---- *)
   bp7 = EmitBlueprint[<|"Scenario" -> "Cn", "n" -> 7|>];
   v7ok = VerifyBlueprint[bp7];
   a2 = <|"n7Match" -> v7ok["StatisticsMatch"], "MaxDev" -> v7ok["MaxDeviation"],
     "SelfCertOK" -> v7ok["OK"]|>;
   a2["OK"] = a2["n7Match"] && (a2["MaxDev"] < 10^-8) && a2["SelfCertOK"];

   (* ---- A3: intensity layer reproduces construction iii-d for KCBS ---- *)
   schKCBS = CompileIntensityEmulator[IntensityTableKCBS[1/Sqrt[5], 0], CycleScenario[5]];
   a3 = <|"Feasible" -> schKCBS["Feasible"],
     (* shape-agnostic: Builder B (authoritative) reports the residual as an
        Exact/Numeric twin; this module's own copy reports a bare 0 *)
     "SignalingZero" -> With[{sr = schKCBS["SignalingResidual"]},
        sr === 0 || (AssociationQ[sr] && sr["Exact"] === 0)],
     "NodeSumSqrt5" -> (RootReduce[schKCBS["NodeSum"]["Exact"] - Sqrt[5]] === 0),
     "CFExact" -> (RootReduce[schKCBS["ContextualFraction"]["Exact"] - (2 Sqrt[5] - 4)] === 0),
     "f00" -> RootReduce[schKCBS["IntensitySchedule"][[1]]["Fractions"]["f00"]["Exact"] - (1 - 2/Sqrt[5])] === 0|>;
   a3["OK"] = a3["Feasible"] && a3["SignalingZero"] && a3["NodeSumSqrt5"] &&
      a3["CFExact"] && a3["f00"];

   (* ---- A4: mesh routing matches wordRingEdgesFast exactly (reps 1,2,3) ---- *)
   a4reps = Table[Module[{bp = EmitBlueprint[<|"Word" -> "cct", "Reps" -> r|>], v},
       v = VerifyBlueprint[bp];
       (Sort[bp["MeshEdgeList"]] === Sort[wordRingEdgesFast["cct", r]]) &&
        (bp["ModeCount"] === 3 StringLength[StringRepeat["cct", r]]) && v["OK"]], {r, 1, 3}];
   a4 = <|"AllRepsMatch" -> AllTrue[a4reps, TrueQ], "reps" -> a4reps|>;
   a4["OK"] = a4["AllRepsMatch"];

   (* ---- A5: self-certification of L1 / L2 / Mesh blueprints ---- *)
   bpL2 = EmitBlueprint[<|"Scenario" -> "KCBS"|>, Method -> "L2"];
   vL2 = VerifyBlueprint[bpL2];
   bpMesh = EmitBlueprint[<|"Word" -> "cct", "Reps" -> 2|>];
   vMesh = VerifyBlueprint[bpMesh];
   (* CV column port sanity (final_o3_cv_dla.py anchors) *)
   cvSets = cvValidationSets[];
   cvA = CVLeafConfinedQ[#[[3]], #[[2]]] & /@ cvSets;
   a5 = <|
     "L1SelfCert" -> vKCBS["OK"], "L1Genuine" -> (vKCBS["DLAVerdictConsistent"]),
     "L2SelfCert" -> vL2["OK"], "L2LeafConfined" -> vL2["DLAVerdictConsistent"],
     "MeshSelfCert" -> vMesh["OK"],
     "CV_i_confined" -> (cvA[[1]]["Dim"] == 4 && cvA[[1]]["Confined"]),
     "CV_ii_active" -> (cvA[[2]]["Dim"] == 10 && ! cvA[[2]]["Confined"]),
     "CV_iii_active" -> (cvA[[3]]["Dim"] == 3 && ! cvA[[3]]["Confined"])|>;
   a5["OK"] = a5["L1SelfCert"] && a5["L1Genuine"] && a5["L2SelfCert"] &&
      a5["L2LeafConfined"] && a5["MeshSelfCert"] &&
      a5["CV_i_confined"] && a5["CV_ii_active"] && a5["CV_iii_active"];

   allOK = a1["OK"] && a2["OK"] && a3["OK"] && a4["OK"] && a5["OK"];
   <|"A1" -> a1, "A2" -> a2, "A3" -> a3, "A4" -> a4, "A5" -> a5,
     "Date" -> $emitDate, "OK" -> allOK|>];

End[];
EndPackage[];
