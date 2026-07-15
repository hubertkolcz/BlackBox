(* Headless runner for the EMU optical compiler MASTER module
   optical-synthesis/OpticalCompiler.wl (Get semantics; see
   RunBiphotonSimulator.wl).  Run:
     wolframscript -file RunOpticalCompiler.wl -print all
   The printed value must show OK -> True (anchors A1-A5).  The runner also emits the
   four DEMO BLUEPRINTS (blueprints/*.wl data + schematics/*.png) each self-certified
   via VerifyBlueprint, and exports the anchor schematics (PNG + PDF).
   Symbols are referenced fully qualified so wolframscript's whole-file tokenisation
   does not pre-create shadowing Global` symbols. *)
SetDirectory[DirectoryName[$InputFileName]];
Get["../optical-synthesis/OpticalCompiler.wl"];
Get["../optical-synthesis/DemoBlueprints.wl"];

Print["modules: ", HubertKolcz`OpticalCompiler`OpticalCompilerModules];
Print["anchor schematics: ", HubertKolcz`OpticalCompiler`OpticalCompilerExportSchematics[
  FileNameJoin[{Directory[], "..", "optical-synthesis", "schematics"}]]];
Print["demo blueprints: ", HubertKolcz`OpticalCompiler`EmitDemoBlueprints[
  FileNameJoin[{Directory[], "..", "optical-synthesis"}]]];
Print[HubertKolcz`OpticalCompiler`OpticalCompilerVerification]
