(* ::Package:: *)

(* ===========================================================================
   kcbs.wl  --  the Klyachko-Can-Binicioglu-Shumovsky (KCBS) inequality:
   the simplest proof that a SINGLE QUTRIT is contextual.

   It reuses qutrit.wl unchanged -- states via qutrit[]/qutritKet[], gates and
   measurement via the Wolfram Quantum Framework loaded there.

   Story:  five rank-1 projectors Pi_0..Pi_4 sit on a "pentagram"; neighbours
   (mod 5) are orthogonal, hence jointly measurable / mutually exclusive.
   Any noncontextual value assignment obeys   Sum_i <Pi_i> <= 2.
   Quantum mechanics, on the state |2>=(0,0,1), reaches   Sum_i <Pi_i> = Sqrt5.

   Run:   wolframscript -file kcbs.wl
   =========================================================================== *)


(* ---- locate this file's folder in every run mode ---------------------------
   wolframscript -file / Get  -> $InputFileName
   front-end "Evaluate Notebook" -> NotebookDirectory[]  ($InputFileName is "")
   anything else               -> current Directory[]                          *)
thisDir = Module[{nb},
  Which[
    StringQ[$InputFileName] && $InputFileName =!= "", DirectoryName[$InputFileName],
    TrueQ[$Notebooks] && StringQ[nb = Quiet@NotebookDirectory[EvaluationNotebook[]]], nb,
    True, Directory[]
  ]
];

(* ---- load the qutrit toolkit unmodified (silence its self-test demo) ---- *)
qutritFile = FileNameJoin[{thisDir, "qutrit.wl"}];
If[! FileExistsQ[qutritFile] && FileExistsQ[ExpandFileName["qutrit.wl"]],
  qutritFile = ExpandFileName["qutrit.wl"]];       (* fall back to working dir *)
If[! FileExistsQ[qutritFile],
  Print["ERROR: cannot find qutrit.wl (looked in: ", thisDir, ").\n",
        "Fix: keep qutrit.wl in the same folder as kcbs.wl and save both, then\n",
        "re-run.  Or evaluate first:  SetDirectory[\"<folder holding qutrit.wl>\"]"];
  Abort[]
];
Block[{Print = (Null &)}, Get[qutritFile]];        (* definitions persist; Print localized only during load *)
$ProgressReporting = False;


(* ===========================================================================
   1.  The KCBS pentagram: five directions on a cone
   =========================================================================== *)

c5   = Cos[Pi/5];
cos2 = c5/(1 + c5);                 (* cos^2(theta); makes neighbours orthogonal *)
sin2 = 1 - cos2;
phi[i_]  := 4 Pi i/5;              (* azimuths spaced by 4pi/5 -> pentagram *)
vvec[i_] := {Sqrt[sin2] Cos[phi[i]], Sqrt[sin2] Sin[phi[i]], Sqrt[cos2]};   (* real unit vector *)

ketV[i_] := qutrit @@ vvec[i];                                              (* |v_i> as a qutrit state *)
Proj[i_] := QuantumOperator[KroneckerProduct[vvec[i], Conjugate[vvec[i]]], {1}, 3];  (* Pi_i = |v_i><v_i| *)
pmat[i_] := Normal @ Proj[i]["MatrixRepresentation"];

(* the five compatible measurement contexts (edges of the pentagon C5) *)
contexts = Table[{i, Mod[i + 1, 5]}, {i, 0, 4}];


(* ===========================================================================
   2.  Expectation, KCBS sum, and the noncontextual bound
   =========================================================================== *)

expct[state_, i_] := Re[Conjugate[state["StateVector"]] . pmat[i] . state["StateVector"]];   (* <Pi_i> *)
kcbsSum[state_]   := Sum[expct[state, i], {i, 0, 4}];

psiOpt = qutritKet[2];             (* optimal qutrit state |2> = (0,0,1) *)

(* explicit noncontextual bound = largest independent set of the pentagon:
   in any deterministic 0/1 assignment, orthogonal (adjacent) projectors
   can't both be 1, so at most 2 of the 5 fire. *)
ncBound = Max[Total /@ Select[Tuples[{0, 1}, 5],
    AllTrue[Range[5], Function[i, #[[i]] + #[[Mod[i, 5] + 1]] <= 1]] &]];


(* ===========================================================================
   3.  Shot-based estimate (reuses the Born-rule sampling idea from qutrit.wl)
   =========================================================================== *)

estimate[state_, i_, n_] := N @ Mean @ RandomChoice[{1 - expct[state, i], expct[state, i]} -> {0, 1}, n];
shotKCBS[state_, n_]      := Total @ Table[estimate[state, i, n], {i, 0, 4}];


(* ===========================================================================
   4.  Report
   =========================================================================== *)

Print["=== KCBS contextuality on one qutrit ==="];
Print["neighbours orthogonal (compatible/exclusive):  ",
  Chop @ Table[vvec[i] . vvec[Mod[i + 1, 5]], {i, 0, 4}]];
Print["projectors idempotent (Pi^2 = Pi):             ",
  Table[Max@Abs@Flatten[N[pmat[i].pmat[i] - pmat[i]]] < 10^-10, {i, 0, 4}]];
Print["exclusive on the pentagon (Pi_i.Pi_i+1 = 0):    ",
  Table[Max@Abs@Flatten[N[pmat[i].pmat[Mod[i + 1, 5]]]] < 10^-10, {i, 0, 4}]];
Print["contexts (jointly-measured pairs):             ", contexts];
Print[];
Print["each <Pi_i> on |2> ....... ", Simplify @ Table[expct[psiOpt, i], {i, 0, 4}]];
Print["noncontextual bound ...... ", ncBound];
Print["KCBS sum (exact) ......... ", Simplify @ kcbsSum[psiOpt], "  = ", N @ kcbsSum[psiOpt]];
Print["quantum maximum Sqrt5 .... ", N @ Sqrt[5]];
Print["violation (QM - NCHV) .... ", N[kcbsSum[psiOpt] - ncBound]];
Print["20000-shot estimate ...... ", shotKCBS[psiOpt, 20000]];
Print[];
Print[If[kcbsSum[psiOpt] > ncBound,
  "==> Sum > 2: the qutrit is CONTEXTUAL (no noncontextual model reproduces it).",
  "==> no violation."]];

(* Optional, needs a front end:  the pentagon exclusivity graph
   CycleGraph[5, VertexLabels -> Placed["Name", Center], VertexSize -> 0.2] *)
