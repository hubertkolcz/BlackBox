(* Headless runner for kcbs_wigner_flow.wl (Get parses incrementally, avoiding the
   Global`-shadowing pitfall; see RunEssay.wl).
   Run:  wolframscript -file RunWignerFlow.wl -print all
   The printed value is the final verification; it must show OK -> True. *)
SetDirectory[DirectoryName[$InputFileName]];
Get["../01-D2-core-computation/kcbs_wigner_flow.wl"]
