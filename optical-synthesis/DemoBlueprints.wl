(* ::Package:: *)

(* ===========================================================================
   DemoBlueprints.wl  --  the four committed DEMO BLUEPRINTS of the EMU optical
   compiler (Integrator).  Definitions only; the emission runs behind
   EmitDemoBlueprints[], triggered by runners/RunOpticalCompiler.wl.

   The four demos (DESIGN.md Section 3 blueprint schema), each SELF-CERTIFIED via
   VerifyBlueprint (gate A5) before it is written:

     (i)   demo1_kcbs_pentagon_L1   -- the Lapkiewicz pentagon reconstruction:
           Layer-1 Givens cascade [P,T1,T2,T1,T2], exact cos theta = 1/GoldenRatio,
           genuine (so(3) DLA = 3).
     (ii)  demo2_c7_heptagon_L1     -- the C7 heptagon cascade: Layer-1, six Givens
           stages, numeric identity S = 7 - 4 theta(C7).
     (iii) demo3_cct_mesh_reps2     -- the cct pentagon-mesh chain, reps = 2:
           block-local, shared-mode routing shown, per-block verdicts (emulable).
     (iv)  demo4_table_V0977_L2     -- a pure no-disturbance table at visibility
           V = 977/1000: Layer-2 ONLY (leaf-confined), the divided-beam intensity
           schedule that reproduces it exactly.

   Each blueprint is committed as a .wl DATA file (blueprints/<name>.wl, the
   blueprint Association with the heavy Schematic Graphics stripped, PLUS its
   SelfCertification = VerifyBlueprint result) and a .png/.pdf schematic
   (schematics/<name>.png).  Honest scope: demos (i)-(iii) whose components carry a
   genuine so(3) block are Layer-1 interferometers; demo (iv) and the mesh blocks are
   BLOCK-LOCAL emulators (Prop. 1 / construction iii-d) -- the compiler never claims
   a globally entangled cluster state (KLM caveat).  Requires OpticalCompiler.wl
   loaded (the master; DispatcherEmitter authoritative for EmitBlueprint /
   VerifyBlueprint / OpticalCompilerSchematic).
   =========================================================================== *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "OpticalCompiler.wl"}]];

(* BlackBox` is a declared dependency so CycleScenario resolves to the paclet symbol
   (not a fresh Private` placeholder) when this file is read. *)
BeginPackage["HubertKolcz`OpticalCompiler`", {"HubertKolcz`BlackBox`"}];

EmitDemoBlueprints::usage =
  "EmitDemoBlueprints[] emits the four demo blueprints, self-certifies each via VerifyBlueprint, writes each as a .wl data file under blueprints/ and a .png+.pdf schematic under schematics/, and returns the summary association <|demo -> <|Layer, VerifyOK, Files|>, ..., \"AllOK\" -> True|>. EmitDemoBlueprints[baseDir] targets baseDir instead of the module directory.";
DemoBlueprintSpecs::usage =
  "DemoBlueprintSpecs[] gives the ordered list {name, targetSpec, emitOptions} of the four demo blueprint targets.";
VvisibilityTable::usage =
  "VvisibilityTable[V] gives the symmetric KCBS no-disturbance table at visibility V: per-context (f00,f01,f10) = (V(1-2/Sqrt[5])+(1-V)/3, V/Sqrt[5]+(1-V)/3, V/Sqrt[5]+(1-V)/3). V=1 is the quantum table (construction iii-d); V=0 the maximally-mixed centre. Kept exact.";

Begin["`Private`"];

(* symmetric V-visibility table (exact); V=1 -> the KCBS quantum table *)
VvisibilityTable[V_] := With[
   {q = V/Sqrt[5] + (1 - V)/3, p00 = V (1 - 2/Sqrt[5]) + (1 - V)/3},
   Flatten[Table[{p00, q, q, 0}, {5}]]];

DemoBlueprintSpecs[] := {
  {"demo1_kcbs_pentagon_L1", <|"Scenario" -> "KCBS"|>, {}},
  {"demo2_c7_heptagon_L1", <|"Scenario" -> "Cn", "n" -> 7|>, {}},
  {"demo3_cct_mesh_reps2", <|"Word" -> "cct", "Reps" -> 2|>, {}},
  {"demo4_table_V0977_L2",
     <|"Scenario" -> "KCBS-V0977", "Table" -> VvisibilityTable[977/1000],
       "Scenario2" -> CycleScenario[5]|>, {Method -> "L2"}}};

(* strip the heavy Schematic Graphics so the .wl data file stays a clean data dump *)
stripSchematic[bp_Association] := Append[bp, "Schematic" -> "(exported separately)"];

EmitDemoBlueprints[] := EmitDemoBlueprints[DirectoryName[$InputFileName]];

EmitDemoBlueprints[baseDir_String] := Module[
   {bpDir, schemDir, specs, results},
   bpDir = FileNameJoin[{baseDir, "blueprints"}];
   schemDir = FileNameJoin[{baseDir, "schematics"}];
   Quiet@If[! DirectoryQ[bpDir], CreateDirectory[bpDir, CreateIntermediateDirectories -> True]];
   Quiet@If[! DirectoryQ[schemDir], CreateDirectory[schemDir, CreateIntermediateDirectories -> True]];
   specs = DemoBlueprintSpecs[];
   results = Association@Table[
      Module[{name = s[[1]], spec = s[[2]], opts = s[[3]], bp, v, dataFile, png, pdf},
        bp = EmitBlueprint[spec, Sequence @@ opts];
        v = VerifyBlueprint[bp];
        bp = Append[bp, "SelfCertification" -> v];
        (* .wl data (Schematic stripped) *)
        dataFile = FileNameJoin[{bpDir, name <> ".wl"}];
        Put[stripSchematic[bp], dataFile];
        (* .png + .pdf schematic *)
        png = FileNameJoin[{schemDir, name <> ".png"}];
        pdf = FileNameJoin[{schemDir, name <> ".pdf"}];
        Export[png, bp["Schematic"], ImageResolution -> 200];
        Export[pdf, bp["Schematic"]];
        name -> <|"Layer" -> bp["Layer"], "ModeCount" -> bp["ModeCount"],
           "VerifyOK" -> v["OK"], "MaxDeviation" -> v["MaxDeviation"],
           "Files" -> {dataFile, png, pdf}|>],
      {s, specs}];
   Append[results, "AllOK" -> AllTrue[Values[results], TrueQ[#["VerifyOK"]] &]]];

End[];
EndPackage[];
