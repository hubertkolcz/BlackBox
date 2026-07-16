(* ZeroSlackDiagnostic.wl -- native Wolfram Language cross-check of
   ZeroSlackDiagnostic.py's result, run via a LOCAL wolframscript kernel
   (NOT CloudEvaluate; no Wolfram Cloud compute credits consumed -- see the
   session notes this accompanies for why that distinction matters here).

   Loads EpsilonCertificate.wl (k=7) and EpsilonCertificate8.wl (k=8)
   directly via Get[] (genuine exact-rational SDP data, already committed
   in this repo), and re-derives -- in native Wolfram exact rational
   arithmetic, independently of the Python implementation in
   CertificateLoader.py / ZeroSlackDiagnostic.py -- whether a Psi-only
   recalibration can force zero-slack on the ddt cycle. Mirrors
   CaseStudies.wl's own posSigma/posCycleMean cell (lines ~358-451)
   verbatim in construction. *)

SetDirectory[DirectoryName[$InputFileName]];
Get["../EpsilonCertificate.wl"];
Get["../EpsilonCertificate8.wl"];

dpStates = {{0, 0}, {1, 0}, {0, 1}};
dpTransfer[letter_] := Module[{T = ConstantArray[-Infinity, {3, 3}], out, j},
   Do[If[!(dpStates[[i, 1]] == 1 && s1 == 1) && !(s1 == 1 && s2 == 1) &&
       !(s2 == 1 && s3 == 1) && !(s3 == 1 && dpStates[[i, 2]] == 1),
      out = If[letter === "d", {s1, s2}, {s2, s1}];
      j = Position[dpStates, out][[1, 1]];
      T[[i, j]] = Max[T[[i, j]], s1 + s2 + s3]],
     {i, 3}, {s1, 0, 1}, {s2, 0, 1}, {s3, 0, 1}];
   T];
Td = dpTransfer["d"]; Tt = dpTransfer["t"];
Print["Td = ", Td]; Print["Tt = ", Tt];
Print["-Infinity entries confirmed: Td[[2,2]]=", Td[[2, 2]], "  Tt[[2,3]]=", Tt[[2, 3]]];

posEdges[CE_] := Select[Tuples[CE["Nodes"], 2], StringDrop[#[[1]], 1] === StringDrop[#[[2]], -1] &];

posSigma[CE_][e_] := Module[{w = e[[1]], x = e[[2]], T, r, ip = 5, jp = 4},
   T = dpTransfer[StringTake[w, {-1}]];
   r = Min[Table[Module[{sig = CE["Strategy"][ToString[s - 1] <> "|" <> w <> ">" <> x]},
       T[[s, sig]] + CE["Phi"][ToString[sig - 1] <> "|" <> x] -
        CE["Phi"][ToString[s - 1] <> "|" <> w]], {s, 3}]];
   (CE["Q"][x][[ip, ip]] + CE["R"][x][[jp, jp]]) - r + CE["Psi"][x] - CE["Psi"][w]];

periodicCycleEdges[word_String, k_Integer] := Module[{p = StringLength[word], wl, nodes},
   wl = Characters[StringRepeat[word, Ceiling[(k + p)/p] + 3]];
   nodes = Table[StringJoin[wl[[j ;; j + k - 1]]], {j, 1, p}];
   Table[{nodes[[i]], nodes[[Mod[i, p] + 1]]}, {i, p}]];

cycleMean[CE_, word_String] := Module[{k = CE["k"], edges},
   edges = periodicCycleEdges[word, k];
   {Mean[posSigma[CE] /@ edges], posSigma[CE] /@ edges, edges}];

fullReport[CE_, name_, bottleneckWord_String] := Module[
   {gamma = CE["Gamma"], edges, sigmas, worst, allOK, muCct, ddtSig, ddtE,
    muBot, botSig, botE, forcedViolation},
   Print["======================================================================"];
   Print[name, "  k=", CE["k"], "  nodes=", Length[CE["Nodes"]]];
   edges = posEdges[CE];
   sigmas = Association[Table[e -> posSigma[CE][e], {e, edges}]];
   worst = MaximalBy[Normal[sigmas], Last][[1]];
   allOK = AllTrue[Values[sigmas], # <= gamma &];
   Print["  #edges=", Length[edges], "  Gamma=", gamma, "=", N[gamma, 10]];
   Print["  max sigma(e)=", worst[[2]], "=", N[worst[[2]], 10], " at ", worst[[1]],
     "  (==Gamma exactly: ", worst[[2]] == gamma, ", <=Gamma everywhere: ", allOK, ")"];

   {muCct, ddtSig, ddtE} = cycleMean[CE, "ddt"];
   Print["  ddt cycle: ", ddtE];
   Print["  sigma values on ddt: ", N[ddtSig, 8]];
   Print["  mu_ddt = ", muCct, " = ", N[muCct, 12]];
   Print["  Gamma - mu_ddt (slack at ddt) = ", gamma - muCct, " = ", N[gamma - muCct, 10]];

   {muBot, botSig, botE} = cycleMean[CE, bottleneckWord];
   Print["  bottleneck word ", bottleneckWord, ": sigma values ", N[botSig, 8]];
   Print["  mu_bottleneck = ", muBot, " = ", N[muBot, 12]];
   Print["  Gamma - mu_bottleneck = ", gamma - muBot, " = ", N[gamma - muBot, 10],
     "  (rationalization sliver)"];

   forcedViolation = muBot - muCct;
   Print["  ==> forcing sigma=mu_ddt on ddt via Psi alone forces >= ", forcedViolation,
     " = ", N[forcedViolation, 10], " NEGATIVE SLACK on ", bottleneckWord];
   <|"gamma" -> gamma, "muCct" -> muCct, "muBot" -> muBot, "allOK" -> allOK,
     "forcedViolation" -> forcedViolation|>];

r7 = fullReport[EpsilonCertificate, "EpsilonCertificate (k=7)", "dttt"];
r8 = fullReport[EpsilonCertificate8, "EpsilonCertificate8 (k=8)", "dtt"];

(* Psi-independence sanity check: perturb Psi at random exact rationals and
   confirm the cycle mean is unchanged (telescoping argument, verified). *)
Print["======================================================================"];
Print["Psi-independence check:"];
SeedRandom[42];
Do[
  Module[{CE = item[[1]], word = item[[2]], label = item[[3]], psiPerturbed, CE2, mu0, mu1},
    psiPerturbed = Association[Table[
       node -> CE["Psi"][node] + RandomInteger[{-999, 999}]/RandomChoice[{7, 11, 13, 97}],
       {node, CE["Nodes"]}]];
    CE2 = CE;
    CE2["Psi"] = psiPerturbed;
    mu0 = cycleMean[CE, word][[1]];
    mu1 = cycleMean[CE2, word][[1]];
    Print["  ", label, " ", word, ": mu=", N[mu0, 10], " vs perturbed-Psi mu=", N[mu1, 10],
      "  identical=", mu0 == mu1]],
  {item, {{EpsilonCertificate, "ddt", "k=7"}, {EpsilonCertificate, "dttt", "k=7"},
    {EpsilonCertificate8, "ddt", "k=8"}, {EpsilonCertificate8, "dtt", "k=8"}}}];

Print["======================================================================"];
Print["FINAL EXACT RESULT (native Wolfram, independent of the Python implementation):"];
Print["  k=7 forced violation = ", r7["forcedViolation"], " = ", N[r7["forcedViolation"], 10]];
Print["  k=8 forced violation = ", r8["forcedViolation"], " = ", N[r8["forcedViolation"], 10]];
Print["  Matches Python result (560723/400000000, 39023/60000000): ",
  r7["forcedViolation"] == 560723/400000000 && r8["forcedViolation"] == 39023/60000000];
