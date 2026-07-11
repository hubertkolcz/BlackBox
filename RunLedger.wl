(* Headless runner for kcbs_ledger.wl (Get parses incrementally, avoiding the
   Global`-shadowing pitfall; see RunEssay.wl).
   Run:  wolframscript -file RunLedger.wl -print all
   The printed value is the final verification; it must show OK -> True. *)
SetDirectory[DirectoryName[$InputFileName]];
Get["kcbs_ledger.wl"]
