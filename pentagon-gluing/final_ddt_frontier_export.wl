(* final_ddt_frontier_export.wl -- export exact d(x), r(e), de Bruijn-k structure
   from the window-k epsilon certificate for the Legendre frontier sweep (LANE 1).
   Reads a materialized certificate (EpsilonCertificate9.wl by default), computes
     dHead(x) = Q[x][5,5] + R[x][4,4]              (theta head payoff, exact rational)
     rInner(e)= min_s (T[s,sigma]+Phi[sigma|x]-Phi[s|w]) (alpha inner value, exact)
   and writes node/edge tables (exact numerator/denominator) to a text file. *)
$HistoryLength = 0;
certDir = "C:/Users/cp/Desktop/black-box/composition-optimality";
outDir  = "C:/Users/cp/Desktop/black-box/pentagon-gluing";
certFile = If[Length[$ScriptCommandLine] >= 2, $ScriptCommandLine[[2]], "EpsilonCertificate9.wl"];
symName  = If[Length[$ScriptCommandLine] >= 3, $ScriptCommandLine[[3]], "EpsilonCertificate9"];
outFile  = If[Length[$ScriptCommandLine] >= 4, $ScriptCommandLine[[4]], "final_ddt_frontier_k9.txt"];

dpStates = {{0, 0}, {1, 0}, {0, 1}};
dpTransfer[letter_] := Module[{T = ConstantArray[-Infinity, {3, 3}], out, j},
   Do[If[! (dpStates[[i, 1]] == 1 && s1 == 1) && ! (s1 == 1 && s2 == 1) &&
        ! (s2 == 1 && s3 == 1) && ! (s3 == 1 && dpStates[[i, 2]] == 1),
      out = If[letter === "d", {s1, s2}, {s2, s1}];
      j = Position[dpStates, out][[1, 1]];
      T[[i, j]] = Max[T[[i, j]], s1 + s2 + s3]],
     {i, 3}, {s1, 0, 1}, {s2, 0, 1}, {s3, 0, 1}];
   T];

Get[FileNameJoin[{certDir, certFile}]];
CE = Symbol[symName];
k = CE["k"]; nodes = CE["Nodes"]; gam = CE["Gamma"];
Print["loaded k=", k, " |V|=", Length[nodes], " Gamma=", N[gam, 12]];
idx = AssociationThread[nodes -> Range[Length[nodes]]];
ip = 5; jp = 4;
dHead[x_] := CE["Q"][x][[ip, ip]] + CE["R"][x][[jp, jp]];
rInner[w_, x_] := Module[{T = dpTransfer[StringTake[w, {-1}]]},
   Min[Table[Module[{sig = CE["Strategy"][ToString[s - 1] <> "|" <> w <> ">" <> x]},
       T[[s, sig]] + CE["Phi"][ToString[sig - 1] <> "|" <> x]
        - CE["Phi"][ToString[s - 1] <> "|" <> w]], {s, 3}]]];

edges = Select[Tuples[nodes, 2], StringDrop[#[[1]], 1] === StringDrop[#[[2]], -1] &];
Print["|E|=", Length[edges]];

(* node table: index  isC(last letter)  dnum  dden *)
nodeLines = Table[Module[{x = nodes[[i]], d = dHead[nodes[[i]]]},
    StringRiffle[{ToString[i - 1],
       If[StringTake[x, {-1}] === "d", "1", "0"],
       ToString[Numerator[d]], ToString[Denominator[d]]}, " "]], {i, Length[nodes]}];

(* edge table: ui  vi  isCadded(last letter of x)  rnum  rden *)
edgeLines = Table[Module[{w = e[[1]], x = e[[2]], r = rInner[e[[1]], e[[2]]]},
    StringRiffle[{ToString[idx[w] - 1], ToString[idx[x] - 1],
       If[StringTake[x, {-1}] === "d", "1", "0"],
       ToString[Numerator[r]], ToString[Denominator[r]]}, " "]], {e, edges}];

out = OpenWrite[FileNameJoin[{outDir, outFile}]];
WriteString[out, "# k=" <> ToString[k] <> " gammaNum=" <> ToString[Numerator[gam]] <>
   " gammaDen=" <> ToString[Denominator[gam]] <> "\n"];
WriteString[out, "# NODES " <> ToString[Length[nodes]] <> "\n"];
Do[WriteString[out, l <> "\n"], {l, nodeLines}];
WriteString[out, "# EDGES " <> ToString[Length[edges]] <> "\n"];
Do[WriteString[out, l <> "\n"], {l, edgeLines}];
Close[out];
Print["wrote ", FileNameJoin[{outDir, outFile}]];
