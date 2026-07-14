(* Headless runner for the master essay fragment docs/essay-src/essay_sections_7_10.wl
   (Sections 7-10; Section Builder C).  Get semantics (not -file) so the loader cell's
   Global`-deshadow runs before any paclet symbol is tokenised in a later cell -- the
   pitfall documented in RunEssay.wl / CertifyingQuantumness.wl.  Run from anywhere:
       wolframscript -file RunEssaySectionsC.wl -print all
   The final value printed is the fragment's verification; it must show OK -> True. *)
SetDirectory[DirectoryName[$InputFileName]];
Get["../docs/essay-src/essay_sections_7_10.wl"]
