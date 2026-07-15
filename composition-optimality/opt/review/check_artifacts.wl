(* review: compare builder's exported certs against ground truths / each other *)
SetDirectory[DirectoryName[$InputFileName]];
certSymbolNames = {"EpsilonCertificate9", "EpsilonCertificate8",
   "EpsilonCertificate7", "EpsilonCertificate"};
LoadCert[file_] := Module[{cert = None},
   If[! FileExistsQ[file], Return[None]];
   Clear /@ certSymbolNames;
   Quiet[Check[Get[file], Return[None]]];
   Do[Module[{v = ToExpression[nm]},
      If[AssociationQ[v] && KeyExistsQ[v, "k"] && KeyExistsQ[v, "Strategy"], cert = v]],
     {nm, certSymbolNames}];
   Clear /@ certSymbolNames;
   cert];
cmp[fa_, fb_] := Module[{a = LoadCert[fa], b = LoadCert[fb]},
   If[a === None || b === None, Print["LOADFAIL ", fa, " | ", fb],
     Print[FileNameTake[fa], " vs ", FileNameTake[fb],
       ": GammaSame=", a["Gamma"] === b["Gamma"],
       " QSame=", a["Q"] === b["Q"], " RSame=", a["R"] === b["R"],
       " PsiSame=", a["Psi"] === b["Psi"], " PhiSame=", a["Phi"] === b["Phi"],
       " StratSame=", a["Strategy"] === b["Strategy"],
       " GammaA=", a["Gamma"]]]];
cmp["../EpsilonCertificate_opt_K3.wl", "../../EpsilonCertificate_testK3_output.wl"];
cmp["../EpsilonCertificate_opt_K4.wl", "../../EpsilonCertificate_testK4_output.wl"];
cmp["../EpsilonCertificate_opt_K5.wl", "../../EpsilonCertificate_testK5_output.wl"];
cmp["../EpsilonCertificate_opt_K6.wl", "../baseline_cert_K6.wl"];
cmp["../baseline_cert_K6.wl", "../profile_cert_K6.wl"];
cmp["../baseline_cert_K4.wl", "../../EpsilonCertificate_testK4_output.wl"];
cmp["../baseline_cert_K5.wl", "../../EpsilonCertificate_testK5_output.wl"];
(* reduced-final K5: exact gates claimed True but NOT byte-identical *)
Module[{r = LoadCert["../EpsilonCertificate_opt_K5_reducedfinal.wl"],
    g = LoadCert["../../EpsilonCertificate_testK5_output.wl"]},
  If[r =!= None && g =!= None,
    Print["reducedfinal K5: GammaSame=", r["Gamma"] === g["Gamma"],
      " diff=", N[r["Gamma"] - g["Gamma"], 10]]]];
