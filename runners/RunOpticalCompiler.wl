(* Headless runner for the EMU optical compiler MASTER module
   09-EMU-optical-compiler/OpticalCompiler.wl (Get semantics; see
   RunBiphotonSimulator.wl).  Run:
     wolframscript -file RunOpticalCompiler.wl -print all
   The printed value must show OK -> True (anchors A1-A5).  The runner also emits the
   four DEMO BLUEPRINTS (blueprints/*.wl data + schematics/*.png) each self-certified
   via VerifyBlueprint, and exports the anchor schematics (PNG + PDF).
   Symbols are referenced fully qualified so wolframscript's whole-file tokenisation
   does not pre-create shadowing Global` symbols. *)
SetDirectory[DirectoryName[$InputFileName]];
Get["../09-EMU-optical-compiler/OpticalCompiler.wl"];
Get["../09-EMU-optical-compiler/DemoBlueprints.wl"];

Print["modules: ", HubertKolcz`OpticalCompiler`OpticalCompilerModules];
Print["anchor schematics: ", HubertKolcz`OpticalCompiler`OpticalCompilerExportSchematics[
  FileNameJoin[{Directory[], "..", "09-EMU-optical-compiler", "schematics"}]]];
Print["demo blueprints: ", HubertKolcz`OpticalCompiler`EmitDemoBlueprints[
  FileNameJoin[{Directory[], "..", "09-EMU-optical-compiler"}]]];
Print[HubertKolcz`OpticalCompiler`OpticalCompilerVerification]
