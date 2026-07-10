(* ::Package:: *)

(* ===========================================================================
   qutrit.wl  --  a small qutrit (3-level quantum system) toolkit.

   Part 1 uses Wolfram's own Quantum Framework paclet (states, gates,
   measurement, entanglement) -- the recommended path.
   Part 2 is a self-contained pure-linear-algebra version with no paclet.

   Run it all:      wolframscript -file qutrit.wl
   Or evaluate section by section in a notebook.
   =========================================================================== *)


(* ===========================================================================
   PART 1 -- built on the Wolfram Quantum Framework
   =========================================================================== *)

PacletInstall["Wolfram/QuantumFramework"];   (* one-time download; no-op afterwards *)
Needs["Wolfram`QuantumFramework`"];

(* ---- states (qudit dimension d = 3) ---- *)
qutritKet[i_Integer] := QuantumState[UnitVector[3, i + 1], 3];   (* |0>, |1>, |2> *)
qutrit[a_, b_, c_]    := QuantumState[{a, b, c}, 3];             (* a|0>+b|1>+c|2> (normalized on query) *)

(* ---- single-qutrit gates: the qutrit Weyl-Heisenberg / Fourier set ---- *)
q3w = Exp[2 Pi I/3];                                                        (* primitive cube root of unity *)
qX = QuantumOperator[{{0, 0, 1}, {1, 0, 0}, {0, 1, 0}}, {1}, 3];           (* shift X: |i> -> |i+1 mod 3> *)
qZ = QuantumOperator[DiagonalMatrix[{1, q3w, q3w^2}], {1}, 3];             (* clock Z: |i> -> w^i |i> *)
qH = QuantumOperator[(1/Sqrt[3]) {{1, 1,      1     },
                                  {1, q3w,    q3w^2 },
                                  {1, q3w^2,  q3w^4 }}, {1}, 3];           (* Fourier = generalized Hadamard *)
qPhase[t_] := QuantumOperator[DiagonalMatrix[{1, 1, Exp[I t]}], {1}, 3];   (* tunable phase on |2> *)

(* ---- measurement in the computational basis ---- *)
qMeasure[st_] := QuantumMeasurementOperator[{1}, 3][st];        (* -> QuantumMeasurement *)
qSample[st_, n_Integer] :=                                      (* n Born-rule shots -> Counts of 0/1/2 *)
  KeySort @ Counts @ RandomChoice[qMeasure[st]["ProbabilitiesList"] -> {0, 1, 2}, n];

(* ---- demo ---- *)
Print["=== Part 1: Wolfram Quantum Framework ==="];
Print["qX|0>  == |1> ? ......... ", qX[qutritKet[0]]["StateVector"] == qutritKet[1]["StateVector"]];
Print["qX^3   == I    ? ......... ", (qX @ qX @ qX)["MatrixRepresentation"] == IdentityMatrix[3] // Simplify];
Print["qH unitary     ? ......... ", qH["UnitaryQ"]];
plus = qH[qutritKet[0]];                                        (* uniform superposition (|0>+|1>+|2>)/Sqrt3 *)
Print["qH|0> probs .............. ", Chop @ N @ qMeasure[plus]["ProbabilitiesList"]];
Print["6000 shots of qH|0> ...... ", qSample[plus, 6000]];

(* ---- two qutrits: a maximally entangled (qutrit "Bell") state ---- *)
qutritBell = QuantumState[{1, 0, 0, 0, 1, 0, 0, 0, 1}/Sqrt[3], {3, 3}];    (* (|00>+|11>+|22>)/Sqrt3 *)
Print["Bell entangled ? ......... ", QuantumEntangledQ[qutritBell]];
Print["reduced qutrit A = I/3 ... ",
  Normal @ Simplify @ QuantumPartialTrace[qutritBell, {2}]["DensityMatrix"]];


(* ===========================================================================
   PART 2 -- dependency-free (plain matrices, no paclet)
   A qutrit state is a length-3 complex vector; gates are 3x3 unitaries.
   =========================================================================== *)

w  = Exp[2 Pi I/3];
k[i_] := UnitVector[3, i + 1];                         (* |0>, |1>, |2> *)
xX = {{0, 0, 1}, {1, 0, 0}, {0, 1, 0}};               (* shift *)
zZ = DiagonalMatrix[{1, w, w^2}];                     (* clock *)
hH = (1/Sqrt[3]) {{1, 1, 1}, {1, w, w^2}, {1, w^2, w^4}};
prob[psi_] := Abs[psi]^2 / Total[Abs[psi]^2];         (* Born rule *)
shots[psi_, n_] := KeySort @ Counts @ RandomChoice[prob[psi] -> {0, 1, 2}, n];

Print["\n=== Part 2: pure linear algebra ==="];
Print["xX.|0> ................... ", xX . k[0]];                                   (* -> |1> *)
Print["hH unitary ? ............. ", Simplify[ConjugateTranspose[hH] . hH] == IdentityMatrix[3]];
Print["Weyl relation zZ.xX = w xX.zZ ? ", Simplify[zZ . xX - w xX . zZ] == 0 xX]; (* defining qutrit algebra *)
Print["hH.|0> probs ............. ", Chop @ N @ prob[hH . k[0]]];
Print["6000 shots of hH.|0> ..... ", shots[hH . k[0], 6000]];
