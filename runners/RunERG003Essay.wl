(* Headless runner for 02-D1-theory-frontier/ERG003_ProofConstruction_Essay.wl.
   Get semantics (not -file) so cell outputs are captured; run with -print all:
       wolframscript -file RunERG003Essay.wl -print all
   The final value printed is ERG003EssayVerification; it must show OK -> True. *)
SetDirectory[DirectoryName[$InputFileName]];
Get["../02-D1-theory-frontier/ERG003_ProofConstruction_Essay.wl"]
