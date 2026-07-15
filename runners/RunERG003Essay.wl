(* Headless runner for open-search-frontier/ERG003_ProofConstruction_Essay.wl.
   Get semantics (not -file) so cell outputs are captured; run with -print all:
       wolframscript -file RunERG003Essay.wl -print all
   The final value printed is ERG003EssayVerification; it must show OK -> True. *)
SetDirectory[DirectoryName[$InputFileName]];
Get["../open-search-frontier/ERG003_ProofConstruction_Essay.wl"]
