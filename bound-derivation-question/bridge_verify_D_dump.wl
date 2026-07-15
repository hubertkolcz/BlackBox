(* bridge_verify_D_dump.wl -- INDEPENDENT extraction for Bridge D.
   Loads each materialized certificate, recomputes sigma(e) via the certificate's
   own posSigma definition, and DUMPS {nodes, edges(index pairs), sigma, cWeight}
   to JSON per window. The max-cycle-mean is then computed INDEPENDENTLY in Python
   (bridge_verify_D.py), not by the builder's Wolfram Karp routine. *)
$HistoryLength = 0;
certDir = "C:/Users/cp/Desktop/black-box/05-CERT-epsilon-certificates";
outDir  = "C:/Users/cp/Desktop/black-box/06-D3-sheaf-cohomology";

dpStates = {{0,0},{1,0},{0,1}};
dpTransfer[letter_] := Module[{T = ConstantArray[-Infinity,{3,3}], out, j},
  Do[If[!(dpStates[[i,1]]==1 && s1==1) && !(s1==1 && s2==1) &&
        !(s2==1 && s3==1) && !(s3==1 && dpStates[[i,2]]==1),
      out = If[letter==="c", {s1,s2}, {s2,s1}];
      j = Position[dpStates, out][[1,1]];
      T[[i,j]] = Max[T[[i,j]], s1+s2+s3]], {i,3},{s1,0,1},{s2,0,1},{s3,0,1}]; T];

posEdges[CE_] := Select[Tuples[CE["Nodes"],2], StringDrop[#[[1]],1]===StringDrop[#[[2]],-1] &];
cW[CE_][e_] := Module[{w=e[[1]], x=e[[2]], T, r, ip=5, jp=4},
  T = dpTransfer[StringTake[w,{-1}]];
  r = Min[Table[Module[{sig=CE["Strategy"][ToString[s-1]<>"|"<>w<>">"<>x]},
       T[[s,sig]] + CE["Phi"][ToString[sig-1]<>"|"<>x] - CE["Phi"][ToString[s-1]<>"|"<>w]], {s,3}]];
  (CE["Q"][x][[ip,ip]] + CE["R"][x][[jp,jp]]) - r];
sig[CE_][e_] := cW[CE][e] + CE["Psi"][e[[2]]] - CE["Psi"][e[[1]]];

files = {{"EpsilonCertificate_testK3_output.wl","EpsilonCertificate9"},
         {"EpsilonCertificate_testK4_output.wl","EpsilonCertificate9"},
         {"EpsilonCertificate_testK5_output.wl","EpsilonCertificate9"}};
If[FileExistsQ[certDir<>"/EpsilonCertificate_testK6_output.wl"],
   AppendTo[files, {"EpsilonCertificate_testK6_output.wl","EpsilonCertificate9"}]];

Do[Module[{path=certDir<>"/"<>f[[1]], CE, nodes, idx, edges, sg, cw, gam, kk},
   ClearAll[EpsilonCertificate9];
   Get[path];
   CE = EpsilonCertificate9;
   nodes = CE["Nodes"]; kk = CE["k"]; gam = CE["Gamma"];
   idx = Association[Table[nodes[[i]]->i, {i,Length[nodes]}]];
   edges = posEdges[CE];
   sg = Table[N[sig[CE][e], 25], {e, edges}];
   cw = Table[N[cW[CE][e], 25], {e, edges}];
   Export[outDir<>"/bridge_verify_D_k"<>ToString[kk]<>".json",
     <|"k"->kk, "Gamma"->N[gam,25], "GammaExact"->ToString[gam,InputForm],
       "nodes"->nodes,
       "edges"->Table[{idx[e[[1]]], idx[e[[2]]]}, {e,edges}],
       "sigma"->sg, "cWeight"->cw,
       "maxSigma"->N[Max[Table[sig[CE][e],{e,edges}]],25]|>, "JSON"];
   Print["dumped k=", kk, " nodes=", Length[nodes], " edges=", Length[edges],
     " Gamma=", N[gam,12], " maxSigma=", N[Max[sg],12]];
  ], {f, files}];
Print["done"];
