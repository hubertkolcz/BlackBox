(* Headless runner for BiphotonSimulator.wl (Get semantics; see RunEssay.wl).
   Run:  wolframscript -file RunBiphotonSimulator.wl -print all
   The printed value must show OK -> True. *)
SetDirectory[DirectoryName[$InputFileName]];
Get["BiphotonSimulator.wl"]
