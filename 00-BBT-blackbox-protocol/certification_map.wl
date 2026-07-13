(* ::Package:: *)
(* certification_map.wl -- generates certification_map.nb (+ .png), the black-box
   certification map for objective O3, grounded entirely in the project's findings.
   Structure: a 3x3 "staircase" -- ACCESS MODEL (rows) x ADVERSARY STRENGTH (cols) --
   showing where a genuine quantum device is indistinguishable from a classical
   optical emulation, and what access upgrade defeats each adversary. Plus the
   orthogonal second (geometric/DLA) lens, the open cells, and provenance.
   Every cell cites a ledger key / this-session result. Run:
   wolframscript -file certification_map.wl  ->  certification_map.nb / .png *)

(* ---- palette ---- *)
distBG   = RGBColor[0.82, 0.90, 0.80]; distFG   = RGBColor[0.13, 0.42, 0.20];
indBG    = RGBColor[0.96, 0.82, 0.80]; indFG    = RGBColor[0.62, 0.16, 0.16];
openBG   = RGBColor[0.90, 0.90, 0.92]; openFG   = RGBColor[0.42, 0.42, 0.50];
hdrBG    = RGBColor[0.20, 0.26, 0.38]; hdrFG    = GrayLevel[1];
ink      = GrayLevel[0.15];

vcell[verd_, key_] := Item[
   Framed[Column[{Style[verd, Bold, 12, If[verd === "INDISTINGUISHABLE", indFG, distFG]],
       Style[key, 8, GrayLevel[0.4]]}, Alignment -> Center, Spacings -> 0.4],
     FrameStyle -> None, ImageMargins -> 6],
   Background -> If[verd === "INDISTINGUISHABLE", indBG, distBG],
   Alignment -> {Center, Center}];

hcell[t_] := Item[Style[t, Bold, 11, hdrFG], Background -> hdrBG, Alignment -> Center,
   ImageMargins -> 5];
rcell[t_, s_] := Item[Column[{Style[t, Bold, 11, hdrFG], Style[s, 8, GrayLevel[0.85]]},
   Spacings -> 0.3], Background -> hdrBG, Alignment -> {Left, Center}, ImageMargins -> 5];

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
  Dividers -> {{False, True, {GrayLevel[0.85]}, False}, {False, True, {GrayLevel[0.85]}, False}},
  Spacings -> {1.2, 1.2}, Frame -> GrayLevel[0.7], ItemSize -> {{11, 13, 13, 13}, Automatic}];

(* ---- the two-lens picture (correlation staircase + orthogonal geometric lens) ---- *)
lensNote = Grid[{
   {Item[Style["SECOND (geometric) LENS \[LongDash] orthogonal route", Bold, 11, hdrFG],
      Background -> hdrBG, Alignment -> Left, ImageMargins -> 5]},
   {Item[TextCell[
      "The staircase above is the CORRELATION lens. Independently, the geometric / "<>
      "dynamical-Lie-algebra lens (gate G7) distinguishes a leaf-confined emulator "<>
      "(DLA < 3) from the genuine KCBS cascade (DLA = 3) by auditing the claimed mode "<>
      "compilation \[LongDash] a route that needs NO access upgrade but carries a "<>
      "white-box trust assumption (the compilation is auditable). Prop 2 / BBT-003: no "<>
      "table functional can lower-bound the DLA, so this lens is NOT derivable from the "<>
      "correlation lens. That irreducibility \[LongDash] two lenses, neither reducible to "<>
      "the other \[LongDash] is the shape of the answer to O3."],
      Background -> RGBColor[0.97, 0.95, 0.90], Alignment -> Left, ImageMargins -> 8]}
   }, ItemSize -> {{50}, Automatic}, Frame -> GrayLevel[0.75]];

(* ---- open frontier ---- *)
openGrid = Grid[{
   {Item[Style["OPEN CELLS \[LongDash] where the map is not yet drawn", Bold, 11, openFG],
      Background -> openBG, Alignment -> Left, ImageMargins -> 5]},
   {Item[TextCell[
      "\[Bullet]  COMPLETENESS (SQ1): is there an adversary that survives attenuation + "<>
      "event-semantics AND the DLA audit? Not ruled out \[LongDash] the map's outer boundary "<>
      "is a two-lens NECESSITY result, not yet a completeness theorem.\n"<>
      "\[Bullet]  CONTINUOUS-VARIABLE column: the DLA audit does not transplant to Gaussian / "<>
      "CV devices (needs an Sp(2n,R) re-derivation, not done \[LongDash] NOTES-hawking). That "<>
      "device class is unbuilt.\n"<>
      "\[Bullet]  SAMPLING-HARDNESS caveat: poly-DLA \[DoubleLongRightArrow] efficient emulation "<>
      "only for algebra-supported observables; it does NOT preclude sampling hardness "<>
      "(Aaronson-Arkhipov). A distinct axis the map does not yet resolve.\n"<>
      "\[Bullet]  cct-optimality sits INSIDE the mesh testbed for the resource axis \[LongDash] "<>
      "it is off this map (a cell-interior detail, not a boundary)."],
      Background -> GrayLevel[0.96], Alignment -> Left, ImageMargins -> 8]}
   }, ItemSize -> {{50}, Automatic}, Frame -> GrayLevel[0.8]];

legend = Row[{
   Framed["distinguishable", Background -> distBG, FrameStyle -> None, ImageMargins -> 3], "  ",
   Framed["INDISTINGUISHABLE (blind spot)", Background -> indBG, FrameStyle -> None, ImageMargins -> 3], "  ",
   Framed["open", Background -> openBG, FrameStyle -> None, ImageMargins -> 3]}];

(* ---- assemble a poster (for PNG) ---- *)
poster = Column[{
   Style["The Black-Box Certification Map", Bold, 22, ink],
   Style["Objective O3: given only black-box access, when is a genuine quantum device "<>
     "indistinguishable from a classical optical emulation?", Italic, 12, GrayLevel[0.4]],
   Spacer[8], legend, Spacer[6],
   mapGrid,
   Style["Reading: indistinguishability (red) lives at the top-left; each ACCESS upgrade "<>
     "(down the rows) defeats a stronger adversary. Only attenuation / event-semantics "<>
     "defeats the \[Theta]-aware emulator \[LongDash] the correlation lens's staircase.", 10, GrayLevel[0.35]],
   Spacer[10], lensNote, Spacer[8], openGrid
   }, Alignment -> Left, Spacings -> 1.1];

Export["certification_map.png", poster, ImageResolution -> 150];

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
     "See 00-BBT-blackbox-protocol/PROPOSITION-O3.md and the claims ledger."],
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
