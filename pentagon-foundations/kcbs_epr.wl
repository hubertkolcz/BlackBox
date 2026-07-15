(* ::Package:: *)

(* ===========================================================================
   kcbs_epr.wl -- reproducing the KCBS value Sqrt5 on an EPR (two-qubit) system,
   with no qutrit.  Standalone: uses only the Wolfram Quantum Framework.

   Q: can we get EXACTLY the KCBS result using EPR qubits instead of a qutrit?

   A: YES for the number. Sqrt5 is fixed by the pentagon (C5) geometry in ANY
   Hilbert space of dimension >= 3, and two qubits give dimension 4. We even
   make the KCBS-optimal state a genuine, maximally entangled Bell state.
   BUT the five KCBS measurements are then JOINT (entangling) operations on the
   pair -- this is single-system contextuality of the 4-level system, NOT Bell
   nonlocality. A true LOCAL Bell test on the same pair is a DIFFERENT inequality
   (CHSH) with a DIFFERENT maximum, Tsirelson's 2 Sqrt2 (Part 2).

   Bottom line: the entanglement here is not the source of the effect -- a global
   unitary can rotate the EPR pair in or out without changing Sqrt5. The
   invariant is the C5 exclusivity geometry, not entanglement.

   Run:  wolframscript -file kcbs_epr.wl
   =========================================================================== *)

PacletInstall["Wolfram/QuantumFramework"];
Needs["Wolfram`QuantumFramework`"];
$ProgressReporting = False;


(* ===========================================================================
   PART 1 -- KCBS pentagon on two qubits; optimal state = EPR pair |Phi+>
   =========================================================================== *)

(* A 3-D subspace of C^4 whose "top" basis vector IS the Bell state. *)
e0 = {0, 1, 0, 0};                 (* |01> *)
e1 = {0, 0, 1, 0};                 (* |10> *)
e2 = {1, 0, 0, 1}/Sqrt[2];         (* |Phi+> = (|00>+|11>)/Sqrt2  -- the EPR pair *)

(* Same pentagram angles as the single-qutrit KCBS. *)
c5 = Cos[Pi/5]; cos2 = c5/(1 + c5); sin2 = 1 - cos2;
phi[i_]  := 4 Pi i/5;
vv[i_]   := Sqrt[sin2] Cos[phi[i]] e0 + Sqrt[sin2] Sin[phi[i]] e1 + Sqrt[cos2] e2;  (* KCBS direction as a 2-qubit vector *)
Proj[i_] := KroneckerProduct[vv[i], Conjugate[vv[i]]];                             (* Pi_i = |v_i><v_i|, 4x4 *)

psi       = e2;                                       (* KCBS-optimal state = the EPR pair *)
expct[i_] := Re[Conjugate[psi] . Proj[i] . psi];      (* <Pi_i> *)
kcbsSum   = Sum[expct[i], {i, 0, 4}];

(* Entanglement facts, via the same library. *)
qpsi        = QuantumState[psi, {2, 2}];
schmidt[i_] := MatrixRank[Chop @ N @ ArrayReshape[vv[i], {2, 2}]];   (* >1 => joint measurement *)

Print["=== Part 1: KCBS on an EPR (two-qubit) pair ==="];
Print["optimal state |Phi+> entangled? .... ", QuantumEntangledQ[qpsi],
      "   (reduced purity ", QuantumPartialTrace[qpsi, {2}]["Purity"], ")"];
Print["neighbours orthogonal .............. ", Chop @ Table[N[vv[i] . vv[Mod[i + 1, 5]]], {i, 0, 4}]];
Print["each <Pi_i> ........................ ", Simplify @ Table[expct[i], {i, 0, 4}]];
Print["KCBS sum ........................... ", Simplify @ kcbsSum, "  = ", N @ kcbsSum];
Print["noncontextual bound ................ ", 2];
Print["measurement Schmidt ranks .......... ", Table[schmidt[i], {i, 0, 4}],
      "  (2 => JOINT / non-local operation)"];
Print[];
Print["==> Same value Sqrt5, carried by a genuine EPR state -- but via JOINT"];
Print["    measurements: contextuality of the 4-level system, not nonlocality."];


(* ===========================================================================
   PART 2 -- genuine EPR nonlocality: LOCAL measurements -> CHSH (different #)
   =========================================================================== *)

Z = {{1, 0}, {0, -1}};  X = {{0, 1}, {1, 0}};
A0 = Z;  A1 = X;  B0 = (Z + X)/Sqrt[2];  B1 = (Z - X)/Sqrt[2];   (* one qubit each: LOCAL *)
phiP = {1, 0, 0, 1}/Sqrt[2];
corr[a_, b_] := Re[Conjugate[phiP] . KroneckerProduct[a, b] . phiP];   (* <A_x (x) B_y> *)
chsh = corr[A0, B0] + corr[A0, B1] + corr[A1, B0] - corr[A1, B1];

Print["\n=== Part 2: same EPR pair, LOCAL measurements -> CHSH ==="];
Print["local (product) measurements A_x (x) B_y, genuinely bipartite / nonlocal"];
Print["CHSH value ......................... ", Simplify @ chsh, "  = ", N @ chsh];
Print["local-realistic bound .............. ", 2];
Print["Tsirelson bound 2 Sqrt2 ............ ", N[2 Sqrt[2]]];
Print[];
Print["==> Genuine EPR nonlocality maxes at 2 Sqrt2 ~ 2.828, NOT Sqrt5 ~ 2.236."];
Print["    The KCBS pentagon is not a bipartite-local scenario: contextuality is"];
Print["    strictly more general than nonlocality."];
