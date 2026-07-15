(* ::Package:: *)

(* ===========================================================================
   OpticalCompiler.wl  --  MASTER module of optical-synthesis (Integrator).

   The single Get-loadable entry point of the EMU optical compiler: the
   CONSTRUCTIVE mirror of certification-protocol certification.  It Get-loads the three layer
   files and exposes ONE unified public API in context HubertKolcz`OpticalCompiler`,
   ending in the OpticalCompilerVerification association whose "OK" key gates on
   ALL five validation anchors A1-A5 (must evaluate True).

     Layer 1  INTERFEROMETER  InterferometerLayer.wl  (Builder A) -- the Givens /
              beamsplitter cascade of an indivisible qutrit (Lapkiewicz) and the
              pentagon-mesh routing; exact Reck/Clements, KCBSCascadeStages,
              biphoton (spin-1) encoding.
     Layer 2  INTENSITY       IntensityLayer.wl       (Builder B) -- the divided
              classical beam that reproduces any no-disturbance table (construction
              iii-d), certified over the no-disturbance polytope by an exact
              RevisedSimplex LP; the extended 27-check battery IntensityLayerVerification.
     Layer 3  DISPATCHER      DispatcherEmitter.wl    (Builder C) -- the two-lens
              dispatcher (so(3) DLA via the paclet; CV Sp(2n,R) port), the blueprint
              emitter, the schematic renderer and the A5 self-certification loop,
              WITH self-contained L1/L2/mesh compilers it orchestrates.

   AUTHORITY / RECONCILIATION.  DispatcherEmitter.wl is self-contained: it carries
   its own SIMPLIFIED copies of the shared pipeline symbols (CompileInterferometer,
   GivensDecompose, StagesToUnitary, CompileMeshRouting, CompileIntensityEmulator,
   IntensityTableKCBS).  The standalone Layer-1/Layer-2 files carry the RICHER,
   independently verified implementations of the same symbols (exact Reck/Clements
   with round-trip < 10^-12, biphoton, n-cycle table, LP-with-slack).  To make the
   integrated pipeline DETERMINISTIC -- and CORRECT: the dispatcher's simplified
   GivensDecompose does NOT round-trip (its stage product deviates O(1) from the
   input), while Builder A's is exact -- this master hands sole authority for the
   six shared symbols to the LAYER BUILDERS: it Get-loads DispatcherEmitter FIRST
   (contributing dispatch, emission, schematics and the A1-A5 gate), clears the six
   shared symbols, then Get-loads Layers 1 and 2 LAST as the single authorities.
   DispatcherEmitter's orchestration (DispatchLayers, EmitBlueprint, VerifyBlueprint,
   OpticalCompilerVerification) resolves the shared symbols at call time, so Builder
   A/B implementations drive the pipeline end-to-end.  The per-layer EXTENDED
   batteries (Builder A's tests_interferometer_layer.wl, Builder B's
   IntensityLayerVerification) additionally run STANDALONE via their own runners
   (tests_interferometer_layer.wl, runners/RunIntensityLayer.wl); the integrated gate
   here is OpticalCompilerVerification (A1-A5).

   HONEST SCOPE (verbatim in spirit, per DESIGN.md / every layer header): the
   compiler emits emulators of BLOCK-LOCAL statistics (per-block tables, block-local
   AvN witnesses) -- exactly what Prop. 1 / the certification map says classical
   optics CAN do.  It does NOT construct globally-entangled cluster states:
   single-photon linear optics cannot, absent exponential mode count or KLM
   nonlinearity.  The emulated/genuine boundary carried in every blueprint is the
   framework's two-lens theorem applied constructively.  Cite: Prop. 1 / BBT-002,
   BBT-003, MESH-004, MESH-008; Frustaglia et al., PRL 116, 250404 (2016);
   Lapkiewicz et al., Nature 474, 490 (2011); Reck et al., PRL 73, 58 (1994);
   Clements et al., Optica 3, 1460 (2016).

   Loadability discipline: definitions only; nothing heavy runs on bare Get.  The
   A1-A5 battery lives in OpticalCompilerVerification (delayed) and is triggered by
   runners/RunOpticalCompiler.wl (which also emits the four demo blueprints).

   Unified public API (all in HubertKolcz`OpticalCompiler`):
     CompileInterferometer, GivensDecompose, StagesToUnitary, CompileMeshRouting,
     CompileIntensityEmulator, IntensityTableKCBS, DispatchLayers, CVLeafConfinedQ,
     EmitBlueprint, VerifyBlueprint, OpticalCompilerSchematic,
     OpticalCompilerExportSchematics, OpticalCompilerVerification, KCBSCascadeStages.

   Run the gate:  wolframscript -file runners/RunOpticalCompiler.wl -print all
   =========================================================================== *)

$OpticalCompilerDir = DirectoryName[$InputFileName];

(* -- Layer 3 FIRST (dispatcher + emitter + verification + simplified copies) -- *)
Get[FileNameJoin[{$OpticalCompilerDir, "DispatcherEmitter.wl"}]];

(* -- hand sole pipeline authority to the layer builders (see AUTHORITY note):
      clear the dispatcher's simplified copies of the six shared symbols -- *)
With[{shared = {
    HubertKolcz`OpticalCompiler`CompileInterferometer,
    HubertKolcz`OpticalCompiler`GivensDecompose,
    HubertKolcz`OpticalCompiler`StagesToUnitary,
    HubertKolcz`OpticalCompiler`CompileMeshRouting,
    HubertKolcz`OpticalCompiler`CompileIntensityEmulator,
    HubertKolcz`OpticalCompiler`IntensityTableKCBS}},
  Quiet[Unprotect @@ shared; ClearAll @@ shared]];

(* -- Layers 1 and 2 LAST: their verified implementations are authoritative -- *)
Get[FileNameJoin[{$OpticalCompilerDir, "InterferometerLayer.wl"}]];
Get[FileNameJoin[{$OpticalCompilerDir, "IntensityLayer.wl"}]];

(* Make the unified public API visible without a context-path surprise. *)
Needs["HubertKolcz`OpticalCompiler`"];

(* -- master metadata (definitions-only; no heavy evaluation) -- *)
HubertKolcz`OpticalCompiler`OpticalCompilerModules =
  <|"Layer1" -> "InterferometerLayer.wl", "Layer2" -> "IntensityLayer.wl",
    "Layer3" -> "DispatcherEmitter.wl",
    "PipelineAuthority" ->
      "InterferometerLayer.wl + IntensityLayer.wl (shared pipeline symbols); DispatcherEmitter.wl (dispatch/emit/verify)",
    "Gate" -> "OpticalCompilerVerification (anchors A1-A5)",
    "StandaloneLayerGates" ->
      {"tests_interferometer_layer.wl", "runners/RunIntensityLayer.wl"}|>;

HubertKolcz`OpticalCompiler`OpticalCompilerAPI = {
  "CompileInterferometer", "GivensDecompose", "StagesToUnitary",
  "CompileMeshRouting", "CompileIntensityEmulator", "IntensityTableKCBS",
  "DispatchLayers", "CVLeafConfinedQ", "EmitBlueprint", "VerifyBlueprint",
  "OpticalCompilerSchematic", "OpticalCompilerExportSchematics",
  "OpticalCompilerVerification", "KCBSCascadeStages"};

HubertKolcz`OpticalCompiler`OpticalCompilerModules::usage =
  "OpticalCompilerModules is the master manifest: the three layer files, the pipeline authority, the integrated gate, and the standalone per-layer gates.";
HubertKolcz`OpticalCompiler`OpticalCompilerAPI::usage =
  "OpticalCompilerAPI is the list of unified public symbol names exposed by the master module OpticalCompiler.wl.";
