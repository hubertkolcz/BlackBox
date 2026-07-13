(* Headless runner for the computational essay.
   wolframscript -file parses a whole file before evaluating, which creates Global`
   shadows of the paclet symbols (the Global`-shadowing pitfall documented in
   kcbs_circuit.wl). Get[] parses and evaluates expression by expression, so the
   loader cell runs before any paclet symbol is parsed. Run from anywhere:
       wolframscript -file RunEssay.wl -print all
   The value printed is the essay's final verification; it must show OK -> True. *)
SetDirectory[DirectoryName[$InputFileName]];
Get["../01-D2-core-computation/CertifyingQuantumness.wl"]
