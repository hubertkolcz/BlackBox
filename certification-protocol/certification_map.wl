(* ::Package:: *)
(* certification_map.wl -- generates certification_map.nb (+ .png), the black-box
   certification map for objective O3, grounded entirely in the project's findings.
   Structure: a 3x3 "staircase" -- ACCESS MODEL (rows) x ADVERSARY STRENGTH (cols) --
   showing where a genuine quantum device is indistinguishable from a classical
   optical emulation, and what access upgrade defeats each adversary. Plus the
   orthogonal second (geometric/DLA) lens, the open cells, and provenance.
   Every cell cites a ledger key / this-session result. Run:
   wolframscript -file certification_map.wl  ->  certification_map.nb / .png *)

(* ---- palette (2026-07-14 visual pass: softer, higher-contrast, rounded cards) ---- *)
distBG   = RGBColor[0.86, 0.93, 0.85]; distFG   = RGBColor[0.14, 0.40, 0.22];
indBG    = RGBColor[0.97, 0.87, 0.85]; indFG    = RGBColor[0.68, 0.22, 0.20];
openBG   = RGBColor[0.92, 0.92, 0.94]; openFG   = RGBColor[0.44, 0.44, 0.52];
hdrBG    = RGBColor[0.16, 0.22, 0.34]; hdrFG    = GrayLevel[1];
ink      = GrayLevel[0.14];

vcell[verd_, key_] := Item[
   Framed[Column[{Style[verd, Bold, 12, If[verd === "INDISTINGUISHABLE", indFG, distFG]],
       Style[key, 8, GrayLevel[0.42]]}, Alignment -> Center, Spacings -> 0.4],
     Background -> If[verd === "INDISTINGUISHABLE", indBG, distBG],
     FrameStyle -> None, RoundingRadius -> 8, FrameMargins -> 10],
   Alignment -> {Center, Center}];

hcell[t_] := Item[Framed[Style[t, Bold, 11, hdrFG], Background -> hdrBG, FrameStyle -> None,
   RoundingRadius -> 6, FrameMargins -> 8], Alignment -> Center];
rcell[t_, s_] := Item[Framed[Column[{Style[t, Bold, 11, hdrFG], Style[s, 8, GrayLevel[0.85]]},
   Spacings -> 0.3], Background -> hdrBG, FrameStyle -> None, RoundingRadius -> 6, FrameMargins -> 8],
   Alignment -> {Left, Center}];

(* ---- the 3x3 staircase ---- *)
mapGrid = Grid[{
   {Item["", Background -> GrayLevel[1]],
    hcell["adversary: NCHV\n(untuned classical)"],
    hcell["adversary: tuned emulator\n(\[Theta]-blind, matches table)"],
    hcell["adversary: tuned emulator\n(\[Theta]-aware, re-tunes)"]},
   {rcell["A1  static table", "per-context click stats"],
    vcell["distinguishable", "BBT-001 \[Bullet] C1-C5"],
    vcell["INDISTINGUISHABLE", "Prop 1 \[Bullet] BBT-002"],
    vcell["INDISTINGUISHABLE", "Prop 1 (A1-A4)"]},
   {rcell["A2  interventional", "inject known SO(3) transforms"],
    vcell["distinguishable", "trivial"],
    vcell["distinguishable", "OQ1-A \[Bullet] rank 0 < 2"],
    vcell["INDISTINGUISHABLE", "OQ1-B \[Bullet] fit < 1e-9"]},
   {rcell["A3  attenuation /\n     event-semantics", "photon-number scaling"],
    vcell["distinguishable", "trivial"],
    vcell["distinguishable", "OQ2 \[Bullet] G8"],
    vcell["distinguishable", "OQ2 / Cor 1 \[Bullet] \[Alpha]=2"]}
   },
  Dividers -> {{False, True, {GrayLevel[0.88]}, False}, {False, True, {GrayLevel[0.88]}, False}},
  Spacings -> {1.35, 1.35}, Frame -> None, ItemSize -> {{11, 13, 13, 13}, Automatic}];

(* ---- the two-lens picture (correlation staircase + orthogonal geometric lens) ---- *)
lensNote = Grid[{
   {Item[Framed[Style["SECOND (geometric) LENS \[LongDash] orthogonal route", Bold, 11, hdrFG],
      Background -> hdrBG, FrameStyle -> None, RoundingRadius -> 6, FrameMargins -> 7], Alignment -> Left]},
   {Item[Framed[TextCell[
      "The staircase above is the CORRELATION lens. Independently, the geometric / "<>
      "dynamical-Lie-algebra lens distinguishes emulators by auditing claimed dynamics: "<>
      "G7 (discrete: leaf-confined DLA < 3 vs the genuine KCBS cascade DLA = 3) and "<>
      "\[LongDash] NEW 2026-07-13 \[LongDash] G7-CV for Gaussian/CV devices (passive u(n), dim n^2, "<>
      "linear-optics-emulable, vs active sp(2n,R), dim n(2n+1); exact-validated: u(2)=4 "<>
      "confined, +two-mode squeezer sp(4,R)=10 active; final_o3_cv_dla.py). Both audits "<>
      "need NO access upgrade but carry a white-box trust assumption. Prop 2 / BBT-003: "<>
      "no table functional can lower-bound the DLA \[LongDash] the two lenses are irreducible. "<>
      "UPGRADE (Prop O3-C, conditional theorem, 2026-07-13): within the intensity-emulator "<>
      "class A_IE the full gate set {C1-C5, G7, G7-CV, G8} is COMPLETE \[LongDash] the map's "<>
      "outer boundary is now class-relative completeness, not necessity alone."],
      Background -> RGBColor[0.975, 0.96, 0.92], FrameStyle -> None, RoundingRadius -> 6, FrameMargins -> 10],
      Alignment -> Left]}
   }, ItemSize -> {{50}, Automatic}];

(* ---- open frontier ---- *)
openGrid = Grid[{
   {Item[Framed[Style["OPEN CELLS \[LongDash] where the map is not yet drawn", Bold, 11, openFG],
      Background -> openBG, FrameStyle -> None, RoundingRadius -> 6, FrameMargins -> 7], Alignment -> Left]},
   {Item[Framed[TextCell[
      "\[Bullet]  ADVERSARY-CLASS MAXIMALITY (H4'): Prop O3-C (2026-07-13) proves the gate "<>
      "set {C1-C5, G7, G7-CV, G8} COMPLETE within the intensity-emulator class A_IE "<>
      "(KBS detector premise + white-box trust); devices OUTSIDE A_IE (photon-number "<>
      "resolution, heralded sources, non-fair-sampling) are the remaining frontier.\n"<>
      "\[Bullet]  CONTINUOUS-VARIABLE column: FILLED 2026-07-13 by G7-CV, the Sp(2n,R) "<>
      "leaf-confinement audit (passive u(n) vs active sp(2n,R); exact-validated); same "<>
      "trust assumption as G7.\n"<>
      "\[Bullet]  SAMPLING-HARDNESS caveat: poly-DLA \[DoubleLongRightArrow] efficient emulation "<>
      "only for algebra-supported observables; it does NOT preclude sampling hardness "<>
      "(Aaronson-Arkhipov). A distinct axis the map does not yet resolve.\n"<>
      "\[Bullet]  cct-optimality sits INSIDE the mesh testbed for the resource axis \[LongDash] "<>
      "it is off this map (a cell-interior detail, not a boundary)."],
      Background -> GrayLevel[0.965], FrameStyle -> None, RoundingRadius -> 6, FrameMargins -> 10],
      Alignment -> Left]}
   }, ItemSize -> {{50}, Automatic}];

legend = Row[{
   Framed["distinguishable", Background -> distBG, FrameStyle -> None, RoundingRadius -> 5, FrameMargins -> 4], "  ",
   Framed["INDISTINGUISHABLE (blind spot)", Background -> indBG, FrameStyle -> None, RoundingRadius -> 5, FrameMargins -> 4], "  ",
   Framed["open", Background -> openBG, FrameStyle -> None, RoundingRadius -> 5, FrameMargins -> 4]}];

(* ---- assemble a poster (for PNG); wrapped in a rounded card ---- *)
posterBody = Column[{
   Style["The Black-Box Certification Map", Bold, 22, ink],
   Style["Objective O3: given only black-box access, when is a genuine quantum device "<>
     "indistinguishable from a classical optical emulation?", Italic, 12, GrayLevel[0.42]],
   Spacer[8], legend, Spacer[6],
   mapGrid,
   Style["Reading: indistinguishability (red) lives at the top-left; each ACCESS upgrade "<>
     "(down the rows) defeats a stronger adversary. Only attenuation / event-semantics "<>
     "defeats the \[Theta]-aware emulator \[LongDash] the correlation lens's staircase.", 10, GrayLevel[0.38]],
   Spacer[10], lensNote, Spacer[8], openGrid
   }, Alignment -> Left, Spacings -> 1.1];
poster = Framed[posterBody, Background -> White, FrameStyle -> GrayLevel[0.85],
   RoundingRadius -> 14, FrameMargins -> 22];

Export["certification_map.png", poster, ImageResolution -> 200];

(* ---- build the notebook ---- *)
sec[t_] := Cell[t, "Section"];
txt[t_] := Cell[t, "Text"];
nb = Notebook[{
   Cell["The Black-Box Certification Map", "Title"],
   Cell["Objective O3 \[LongDash] the indistinguishability boundary, from existing findings", "Subtitle"],
   txt["The central question (O3): given only black-box access, under what conditions is it "<>
     "mathematically impossible to distinguish a genuine quantum device from a classical "<>
     "optical emulation at the input-output level? This notebook assembles the answer, so "<>
     "far, as a map. Every cell is grounded in a project finding (ledger key shown); open "<>
     "cells are marked open."],
   sec["1.  The correlation-lens staircase (access model \[Times] adversary strength)"],
   txt["Rows = how much access the tester has. Columns = how strong the classical emulator is. "<>
     "A cell says whether genuine quantum can be told apart from that emulator under that access."],
   Cell[BoxData[ToBoxes[mapGrid]], "Output"],
   txt["Reading: the blind spot (INDISTINGUISHABLE) is top-left and shrinks as access grows. "<>
     "Static tables cannot separate either tuned emulator (Prop 1). Interventions defeat the "<>
     "\[Theta]-blind emulator (OQ1-A: intervention-orbit rank 0 vs quantum rank 2) but NOT a "<>
     "\[Theta]-aware one that re-tunes (OQ1-B: fit < 1e-9). Only attenuation / event-semantics "<>
     "(OQ2 gate G8; Corollary 1 collapses the emulator to the NCHV bound \[Alpha]=2) defeats the "<>
     "strongest adversary. That staircase IS the operational content of O3 for the correlation lens."],
   sec["2.  The orthogonal second (geometric) lens"],
   Cell[BoxData[ToBoxes[lensNote]], "Output"],
   sec["3.  Open cells \[LongDash] where the map is not yet drawn"],
   Cell[BoxData[ToBoxes[openGrid]], "Output"],
   sec["4.  Per-cell provenance"],
   txt["A1\[Times]NCHV: BBT-001 gates C1-C5 (contextual fraction / GE separate \[Alpha]=2 from \[Theta]=\[Sqrt]5). "<>
     "A1\[Times]tuned: Proposition 1 / BBT-002 (an emulator tuned to the quantum table is table-identical). "<>
     "A2\[Times]\[Theta]-blind: OQ1-A (oq1_interventional_dla.py; orbit rank 0 < 2 at 60/60 points). "<>
     "A2\[Times]\[Theta]-aware: OQ1-B (the \[Theta]-aware ND-polytope fitter reproduces the quantum orbit to < 1e-9). "<>
     "A3\[Times]tuned: OQ2 (oq2_attenuation_gate.py; gate G8 flags the coherent forger 25/25) and Corollary 1. "<>
     "Second lens: G7 DLA audit; Proposition 2 / BBT-003 (no table functional lower-bounds the DLA). "<>
     "See certification-protocol/PROPOSITION-O3.md and the claims ledger."],
   txt["Provenance: generated 2026-07-13 from PROPOSITION-O3.md (Prop 1/2, Cor 1/2, OQ1/OQ2), "<>
     "the claims ledger (BBT-001/002/003, LP-002), and this session's OQ1/OQ2 probe results. "<>
     "Regenerate: wolframscript -file certification_map.wl."]
   },
   WindowSize -> {900, 760}, WindowTitle -> "Black-Box Certification Map"];

res = Quiet@Check[Export["certification_map.nb", nb, "NB"], $Failed];
If[res === $Failed || ! FileExistsQ["certification_map.nb"],
   (* fallback: write the Notebook expression as text (a .nb IS a Notebook[] expression) *)
   With[{os = OpenWrite["certification_map.nb", CharacterEncoding -> "PrintableASCII"]},
     WriteString[os, ToString[nb, InputForm]]; Close[os]];
   Print["NB written via ToString fallback"],
   Print["NB written via Export"]];

Print["FILES: certification_map.nb (", FileByteCount["certification_map.nb"], " B), ",
   "certification_map.png (", FileByteCount["certification_map.png"], " B)"];
