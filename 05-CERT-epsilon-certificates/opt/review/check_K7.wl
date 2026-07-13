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
a = LoadCert["EpsilonCertificate_opt_K7.wl"];
b = LoadCert["../../EpsilonCertificate_testK7_output.wl"];
Print["opt_K7(review) vs testK7_output(original generator, this machine):"];
Print["  GammaSame=", a["Gamma"] === b["Gamma"], " (", a["Gamma"], ")"];
Print["  QSame=", a["Q"] === b["Q"], " RSame=", a["R"] === b["R"],
  " PsiSame=", a["Psi"] === b["Psi"], " PhiSame=", a["Phi"] === b["Phi"],
  " StratSame=", a["Strategy"] === b["Strategy"]];
Print["  numeric GammaDiff=", N[a["Gamma"] - b["Gamma"], 10]];
