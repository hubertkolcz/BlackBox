(* Headless runner for 09-EMU-optical-compiler/IntensityLayer.wl (Layer 2, Builder B).
   Get semantics (see RunBiphotonSimulator.wl): the file is definitions-only, so the
   runner evaluates the delayed IntensityLayerVerification and prints the Column.
   Run:  wolframscript -file RunIntensityLayer.wl -print all
   The printed value must show OK -> True. *)
SetDirectory[DirectoryName[$InputFileName]];
Get["../09-EMU-optical-compiler/IntensityLayer.wl"];
Module[{v = HubertKolcz`OpticalCompiler`IntensityLayerVerification},
  Column[{
    "IntensityLayer (Layer 2) -- A3 + generalized-construction anchors",
    v, "OK" -> v["OK"]}]]
