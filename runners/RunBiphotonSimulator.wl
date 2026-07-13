(* Headless runner for BiphotonSimulator.wl (Get semantics; see RunEssay.wl).
   Run:  wolframscript -file RunBiphotonSimulator.wl -print all
   The printed value must show OK -> True. *)
SetDirectory[DirectoryName[$InputFileName]];
Get["../01-D2-core-computation/BiphotonSimulator.wl"]
