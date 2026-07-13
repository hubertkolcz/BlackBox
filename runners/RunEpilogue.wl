(* Headless runner for kcbs_epilogue.wl (Get parses incrementally, avoiding the
   Global`-shadowing pitfall; see RunEssay.wl).
   Run:  wolframscript -file RunEpilogue.wl -print all
   The printed value is the final verification; it must show OK -> True. *)
SetDirectory[DirectoryName[$InputFileName]];
Get["../01-D2-core-computation/kcbs_epilogue.wl"]
