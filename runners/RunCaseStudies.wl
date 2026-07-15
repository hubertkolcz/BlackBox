(* Headless runner for CaseStudies.wl (Get parses incrementally, avoiding the
   Global`-shadowing pitfall of whole-file parsing; see RunEssay.wl).
   Run:  wolframscript -file RunCaseStudies.wl -print all
   The printed value is the final verification; it must show OK -> True. *)
SetDirectory[DirectoryName[$InputFileName]];
Get["../pentagon-gluing/CaseStudies.wl"]
