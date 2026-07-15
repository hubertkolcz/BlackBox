(* build deliberately corrupted K=3 certificates for warm-start failure probes *)
SetDirectory[DirectoryName[$InputFileName]];
Get["EpsilonCertificate_opt_K3.wl"];  (* binds EpsilonCertificate9 *)
base = EpsilonCertificate9;

(* corruption A: scramble Strategy -- every decision forced to sig 3
   (valid for some (s,T), invalid for others -> per-decision fallback) *)
cA = base;
cA["Strategy"] = Association[# -> 3 & /@ Keys[base["Strategy"]]];
Export["corrupt_K3_strategy.wl",
  "EpsilonCertificate9 = " <> ToString[cA, InputForm] <> ";\n", "Text"];

(* corruption B: Gamma lied DOWN to 1/100 (impossibly tight) -- the
   monotonicity gate should reject every converged seed and fall back loudly *)
cB = base; cB["Gamma"] = 1/100;
Export["corrupt_K3_gammalow.wl",
  "EpsilonCertificate9 = " <> ToString[cB, InputForm] <> ";\n", "Text"];

(* corruption C: Strategy values nonsense (7 everywhere -> all invalid) AND
   Gamma lied UP to 1/2 (gate becomes vacuous) *)
cC = base; cC["Gamma"] = 1/2;
cC["Strategy"] = Association[# -> 7 & /@ Keys[base["Strategy"]]];
Export["corrupt_K3_both.wl",
  "EpsilonCertificate9 = " <> ToString[cC, InputForm] <> ";\n", "Text"];

Print["corrupt certs written"];
