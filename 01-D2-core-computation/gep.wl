(* ::Package:: *)

(* ===========================================================================
   gep.wl -- Global Exclusivity for KCBS:  the  C5  vs  C5 x C5  story.

   Completes the trilogy:
     kcbs.wl      single qutrit  (dim 3)         -- KCBS sum = sqrt5
     kcbs_epr.wl  two qubits, joint (dim 4)      -- KCBS sum = sqrt5
     gep.wl       THIS FILE: the two-COPY scenario that makes the
                  global-exclusivity score S reach the quantum value sqrt5.

   Point:  the exclusivity principle applied to ONE copy of C5 only bounds the
   sum by 5/2 (too loose). Applied to TWO copies (C5 x C5) it tightens to
   exactly sqrt5 = the Lovasz number = the quantum contextual maximum.

   Self-contained: plain graph theory + linear algebra, no paclet.
   Run:  wolframscript -file gep.wl
   =========================================================================== *)

adj5[a_, b_] := MemberQ[{1, 4}, Mod[a - b, 5]];    (* C5 adjacency = exclusivity of neighbours *)

(* ---- single copy C5 = KCBS pentagon: the three characteristic numbers ---- *)
alphaNC = 2;                                         (* independence number  -> NCHV bound  *)
theta   = FullSimplify[5 Cos[Pi/5]/(1 + Cos[Pi/5])]; (* Lovasz number        -> QM maximum = sqrt5 *)
omega1  = Length @ First @ FindClique[CycleGraph[5]];(* clique number of C5  = 2 *)
S1      = 5/omega1;                                  (* GE, 1 copy: |G|/omega = 5/2 *)

(* ---- two copies: exclusivity graph = OR (co-normal) product  C5 (+) C5 ---- *)
verts = Tuples[Range[0, 4], 2];                      (* 25 global events (i,j) *)
orAdj[{i_, j_}, {ip_, jp_}] := adj5[i, ip] || adj5[j, jp];   (* adjacent if exclusive in EITHER copy *)
g2     = Graph[verts, UndirectedEdge @@@ Select[Subsets[verts, {2}], orAdj @@ # &]];
omega2 = Length @ First @ FindClique[g2];            (* clique number = 5  ( > omega(C5)^2 = 4 ) *)
S2     = 5 * omega2^(-1/2);                          (* GE, 2 copies, per copy = 5/sqrt5 = sqrt5 *)

(* ---- quantum realization of the two copies: two qutrits (dim 3 x 3 = 9) ---- *)
c = Cos[Pi/5]; cos2 = c/(1 + c); sin2 = 1 - cos2; phi[i_] := 4 Pi i/5;
v[i_]    := N[{Sqrt[sin2] Cos[phi[i]], Sqrt[sin2] Sin[phi[i]], Sqrt[cos2]}];  (* KCBS pentagram vectors *)
psi      = {0, 0, 1};                                (* optimal qutrit state |2> *)
prob[i_] := (psi . v[i])^2;                          (* <Pi_i> = |<psi|v_i>|^2  = 1/sqrt5 *)
singleSum = Total @ Table[prob[i], {i, 0, 4}];                              (* -> sqrt5 *)
globalSum = Total @ Flatten @ Table[prob[i] prob[j], {i, 0, 4}, {j, 0, 4}]; (* -> 5, tensor state psi(x)psi *)

Print["=== KCBS global exclusivity:   C5   vs   C5 x C5 ==="];
Print[];
Print["single copy C5 -- three bounds on the sum S:"];
Print["  NCHV (independence number) alpha .... ", alphaNC];
Print["  QM   (Lovasz number)       theta .... ", theta, " = ", N@theta];
Print["  GE, 1 copy (frac packing)  S1 ....... ", S1, " = ", N[S1], "   <-- LOOSE (above QM)"];
Print[];
Print["two copies C5 x C5 (OR product, 25 global events):"];
Print["  clique number  omega(C5) ............ ", omega1];
Print["  clique number  omega(C5 (+) C5) ..... ", omega2, "   (note: 5 > omega(C5)^2 = 4)"];
Print["  GE, 2 copies   S2 (per copy) ........ ", Simplify@S2, " = ", N[S2], "   <-- REACHES QM"];
Print[];
Print["quantum two-qutrit realization (dim 9), state |2> x |2>:"];
Print["  single-copy sum   Sum_i <Pi_i> ...... ", Chop@singleSum, "   (= sqrt5)"];
Print["  25 global-event sum  Sum <Pi_i x Pi_j> ", Chop@globalSum, "   (= 5, saturates omega = 5)"];
Print[];
Print["==> Global exclusivity singles out the quantum value only on TWO copies:"];
Print["      1 copy  ->  5/2   = 2.5       (does NOT reach QM)"];
Print["      2 copies->  sqrt5 = ", N@Sqrt[5], "   (= QM = Lovasz theta(C5))"];
Print[];
Print["Physical carriers of the two copies: two qutrits (2 x kcbs.wl, dim 9),"];
Print["or two 2-qubit registers (2 x kcbs_epr.wl, 4 qubits, dim 16). Graph result is carrier-free."];
