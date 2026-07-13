(* Headless runner for signaling_taxonomy.wl (Get parses incrementally, avoiding the
   Global`-shadowing pitfall; see RunEssay.wl).
   Run:  wolframscript -file RunSignalingTaxonomy.wl -print all
   The printed value is the final verification; it must show OK -> True.
   The randomized/float-LP layer is executed by signaling_taxonomy.py (exit 0 required). *)
SetDirectory[DirectoryName[$InputFileName]];
Get["../07-SIG-signaling/signaling_taxonomy.wl"]
