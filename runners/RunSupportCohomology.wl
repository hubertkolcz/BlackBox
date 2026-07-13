(* Headless runner for SupportCohomology.wl (Get parses incrementally, avoiding the
   Global`-shadowing pitfall; see RunEssay.wl).
   Run:  wolframscript -file RunSupportCohomology.wl -print all
   The printed value is the final verification; it must show OK -> True. *)
SetDirectory[DirectoryName[$InputFileName]];
Get["../06-D3-sheaf-cohomology/SupportCohomology.wl"]
