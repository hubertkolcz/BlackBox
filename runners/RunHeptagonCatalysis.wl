(* Headless runner for HeptagonCatalysis.wl (Get parses incrementally, avoiding the
   Global`-shadowing pitfall; see RunEssay.wl).
   Run:  wolframscript -file RunHeptagonCatalysis.wl -print all
   The printed value is the final verification; it must show OK -> True. *)
SetDirectory[DirectoryName[$InputFileName]];
Get["../02-D1-theory-frontier/HeptagonCatalysis.wl"]
