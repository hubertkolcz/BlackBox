(* Genuine Wolfram CLOUD run of ZeroSlackDiagnostic.wl's core check, submitted
   via CloudEvaluate (spends real Wolfram Compute Services credits, per the
   user's explicit chat confirmation). Certificate data is loaded LOCALLY
   first (Get[] needs local file access) and the extracted, already-parsed
   association is passed INTO the CloudEvaluate block, so the actual
   sigma/cycle-mean arithmetic genuinely executes on the cloud kernel. *)

SetDirectory[DirectoryName[$InputFileName]];
Get["EpsilonCertificate.wl"];
Get["EpsilonCertificate8.wl"];

t0 = AbsoluteTime[];
result = CloudEvaluate[Module[
   {CE7 = #1, CE8 = #2, dpStates, dpTransfer, posEdges, posSigma,
    periodicCycleEdges, cycleMean, fullReport, r7, r8},

   dpStates = {{0, 0}, {1, 0}, {0, 1}};
   dpTransfer[letter_] := Module[{T = ConstantArray[-Infinity, {3, 3}], out, j},
      Do[If[!(dpStates[[i, 1]] == 1 && s1 == 1) && !(s1 == 1 && s2 == 1) &&
          !(s2 == 1 && s3 == 1) && !(s3 == 1 && dpStates[[i, 2]] == 1),
         out = If[letter === "c", {s1, s2}, {s2, s1}];
         j = Position[dpStates, out][[1, 1]];
         T[[i, j]] = Max[T[[i, j]], s1 + s2 + s3]],
        {i, 3}, {s1, 0, 1}, {s2, 0, 1}, {s3, 0, 1}];
      T];

   posEdges[CE_] := Select[Tuples[CE["Nodes"], 2],
      StringDrop[#[[1]], 1] === StringDrop[#[[2]], -1] &];

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
      Mean[posSigma[CE] /@ edges]];

   fullReport[CE_, bottleneckWord_String] := Module[{muCct, muBot},
      muCct = cycleMean[CE, "cct"];
      muBot = cycleMean[CE, bottleneckWord];
      <|"gamma" -> CE["Gamma"], "muCct" -> muCct, "muBot" -> muBot,
        "forcedViolation" -> muBot - muCct|>];

   r7 = fullReport[CE7, "cttt"];
   r8 = fullReport[CE8, "ctt"];
   <|"k7" -> r7, "k8" -> r8,
     "matchesKnown" -> (r7["forcedViolation"] == 560723/400000000 &&
                         r8["forcedViolation"] == 39023/60000000)|>
   ] &[EpsilonCertificate, EpsilonCertificate8]];
elapsed = AbsoluteTime[] - t0;

Print["=== GENUINE WOLFRAM CLOUD run (CloudEvaluate, real credits spent) ==="];
Print["elapsed wall time: ", elapsed, " s"];
Print["result: ", result];
If[AssociationQ[result],
  Print["k=7 forced violation = ", result["k7"]["forcedViolation"], " = ",
    N[result["k7"]["forcedViolation"], 10]];
  Print["k=8 forced violation = ", result["k8"]["forcedViolation"], " = ",
    N[result["k8"]["forcedViolation"], 10]];
  Print["Matches previously-known result (560723/400000000, 39023/60000000): ",
    result["matchesKnown"]],
  Print["Cloud computation did not return the expected association -- raw result above."]];
