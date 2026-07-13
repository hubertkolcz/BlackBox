(* ::Package:: *)

(* ===========================================================================
   cct_mbqc_sim.wl -- sparse, measurement-capable CHP stabilizer simulator
   (Aaronson-Gottesman tableau WITH destabilizers) in pure Wolfram Language,
   for MBQC measurement patterns on the pentagon-mesh graph state.

   HONEST FRAMING: all measurement patterns targeted by this simulator are
   Clifford, so the Gottesman-Knill theorem guarantees efficient classical
   simulation - the claim here is faithful protocol-level MBQC execution of
   well-known quantum algorithms on the pentagon mesh at scales far beyond any
   statevector simulator (JUPITER exascale record: 50 qubits) or any existing
   quantum hardware, NOT a quantum-speedup claim. The documented path to
   universality is T-gate injection / stabilizer-rank methods (cost 2^(alpha t)
   in T-count t).

   REFERENCES:
     * S. Aaronson, D. Gottesman, "Improved simulation of stabilizer
       circuits", PRA 70, 052328 (2004)  (the CHP tableau + destabilizers +
       g-function + rowsum used verbatim here).
     * M. Hein, J. Eisert, H. J. Briegel, "Multiparty entanglement in graph
       states", PRA 69, 062311 (2004)  (graph-state conventions; local
       Pauli-measurement rules the MBQC patterns rely on).

   CONVENTIONS (fixed project-wide, matching mbqc_c5.wl):
     * Graph state |G> = prod_{(i,j) in E} CZ_ij |+>^n.
       Stabilizers K_v = X_v prod_{u~v} Z_u.
     * Qubits are integers 1..n; edge lists are per-pair-sorted {i,j}, i<j
       (exactly the output format of wordRingEdgesFast in
       cct_mesh_sparse_construction.wl).
     * Tableau rows 1..2n:  rows 1..n = DESTABILIZERS (initial d_v = Z_v),
       rows n+1..2n = STABILIZERS (initial s_v = K_v).  This direct
       initialization is a valid CHP pair structure: d_v anticommutes with
       s_v (the X_v in K_v meets Z_v) and commutes with every s_u, u != v;
       destabilizers commute pairwise; all initial signs +1.
     * A row is the HERMITIAN Pauli (-1)^r prod_j W_j with W_j from the bit
       pair (x_j,z_j): (0,0)=I,(1,0)=X,(0,1)=Z,(1,1)=Y (Y == i X Z; the i
       bookkeeping lives exclusively in the g function).  Sign bit r in {0,1};
       stored rows never carry i/-i (enforced by the rowsum parity ASSERT).

   DESIGN: DownValue-store tableau with a LAZY copy-on-write overlay.
   NewGraphStateTableau returns a UNIQUE SYMBOL (Module[{CCTTab},...;CCTTab]);
   all state hangs off that symbol's DownValues.  API functions take the
   symbol by value (tab_Symbol) and mutate via indexed assignment
   tab[key...] = value (pattern substitution inserts the concrete symbol, so
   this writes a literal DownValue of the handle).  Nothing per-row is
   materialized at construction: pattern-fallback definitions give every row,
   sign and incidence list its analytic graph-state default, and the FIRST
   write through the SetRow choke point shadows the fallback with a literal
   (hash-stored) DownValue.  Memory is therefore proportional to the set of
   rows/qubits actually touched ("dirty set"), NOT to n.

   WHY NOT the alternatives:
     * Naive immutable updates (tab = ReplacePart[tab,...] / rebuilding an
       Association per operation) copy O(size) per update - the classic WL
       trap; instantly fatal at n = 10^7.
     * Module-scoped Associations mutated by sym[key]=val ARE fast (special
       evaluator path) but ONLY while the association's refcount is 1: any
       innocent read like xs = tab["xsupp"] creates a second reference and
       the next write silently degrades to a full copy-on-write of the whole
       association.  Nested associations (incidence) make this worse.  The
       DownValue store has no such failure mode.
     * Packed 2n x 2n bit matrices (dense CHP) are O(n^2) memory:
       2.5*10^13 bits at n = 10^7.  Not an option.

   COMPLEXITY (honest):
     * Init: O(|E| log |E|) native SparseArray build + Sort; memory O(n+|E|)
       (adjacency only, ~tens of bytes/qubit + per edge); overlay starts
       EMPTY.  10^7 qubits is well within RAM, consistent with the
       27M-qubit benchmarks of cct_mesh_sparse_stabilizer.wl.
     * Gates: O(#rows incident on the touched qubit(s) x row weight there).
       Fresh mesh (max degree 3): O(1).
     * Measure Z, random case: O((kS+kD)(w_pivot + w_row)) + incidence
       updates, kS/kD = anticommuting stabilizer/destabilizer counts at q.
       Fresh graph state: kS = 1, kD = 0 -> a Z-carve costs O(deg) <= O(3).
     * Measure X on a fresh wire vertex: H conjugation touches deg+2 rows,
       then kS = deg <= 3, kD = 1: O(1) with mesh-bounded constants.
       Y likewise (local-complementation-like fill <= 3 edges at degree <= 3).
     * Deterministic case: O(|T| x row weights) read off the DESTABILIZER
       X-incidence - the destabilizer payoff; NEVER O(n^2), no Gaussian
       elimination anywhere.
     * HONEST worst case: nothing bounds row weights a priori.  Adversarial
       Clifford circuits densify rows to Theta(n), giving Theta(n) per rowsum
       and up to Theta(n^2) per measurement - same asymptotics as dense CHP,
       with sparse overhead.  WHY the target mesh patterns stay sparse: they
       are Hein-rule local operations on a max-degree-3 graph - Z carves
       DELETE vertices (weights shrink), X contracts degree-2 wire segments,
       Y local-complements at degree <= 3 (fill <= 3) - every operation
       touches an O(1)-radius neighborhood; byproduct frames are classical
       bookkeeping.  Row-weight telemetry ("maxWeight") is maintained so any
       unexpected densification is VISIBLE in every run's summary rather
       than assumed away.

   NO floating point anywhere in the simulator core or in any correctness
   comparison (no N[], no Chop, no tolerances).  The only numerics allowed
   are AbsoluteTiming / MemoryInUse in benchmark prints.
   NO cloud calls of any kind; everything is local.

   API SURFACE:
     NewGraphStateTableau[n, edges, "ValidateEdges"->Automatic] -> tab
     ApplyH[tab,q] ApplyS[tab,q] ApplySdg[tab,q] ApplyX[tab,q] ApplyY[tab,q]
     ApplyZ[tab,q] ApplyCZ[tab,a,b] ApplyCNOT[tab,a,b]   (mutate, return tab)
     MeasurePauli[tab, q, "X"|"Y"|"Z", "ForcedOutcome"->0|1|Automatic]
       -> <|"Outcome","Deterministic","Probability","Qubit","Basis"|>
     StateVectorFromTableau[tab, "Normalized"->False|True]  (n <= 10 only)
     PhaseScaleEquivalentQ[u, v]      (exact up-to-phase-and-scale equality)
     TableauRow[tab,i]  TableauStats[tab]  FreeTableau[tab]
     helpers: SymDiff, SetRow, FlipR, RowSumInto, CCTAssert,
              CCTMBQCRunV0Foundations[]   (micro-foundation self-tests)

   LOAD-ONLY USE:   CCTMBQCLoadOnly = True; Get["...cct_mbqc_sim.wl"]
   loads the definitions with no side effects.  Running the file directly
   (wolframscript -file .../cct_mbqc_sim.wl) executes a fast self-check
   (V0 micro-foundations + a small C5 measurement demo).  The FULL
   differential-validation suite lives in cct_mbqc_sim_tests.wl.
   =========================================================================== *)

(* ---------------------------------------------------------------------------
   SECTION L0. Assertion helper and tiny exact-set utilities.
   --------------------------------------------------------------------------- *)
CCTAssert[cond_, tag_String, payload_] :=
  If[!TrueQ[cond],
    Print["*** CCTAssert FAILED: ", tag];
    Print["    payload: ", payload];
    Abort[]];

(* symmetric difference of two sorted duplicate-free integer lists; native
   kernel set functions keep the output sorted and duplicate-free. *)
SymDiff[a_List, b_List] := Complement[Union[a, b], Intersection[a, b]];

(* ---------------------------------------------------------------------------
   SECTION L1. The exact g function (Aaronson-Gottesman PRA 70, 052328,
   Sec. III).  g(x1,z1,x2,z2) is the exponent e in {-1,0,1} such that
       Pauli(x1,z1) . Pauli(x2,z2) = i^e Pauli(x1 XOR x2, z1 XOR z2)
   with Pauli(0,0)=I, (1,0)=X, (0,1)=Z, (1,1)=Y.  Machine-verified against
   all 16 dense 2x2 Pauli products in CCTMBQCRunV0Foundations[].
   --------------------------------------------------------------------------- *)
gPhase[0, 0, _Integer, _Integer] = 0;
gPhase[1, 1, x2_Integer, z2_Integer] := z2 - x2;
gPhase[1, 0, x2_Integer, z2_Integer] := z2 (2 x2 - 1);
gPhase[0, 1, x2_Integer, z2_Integer] := x2 (1 - 2 z2);

(* ---------------------------------------------------------------------------
   SECTION L2. Tableau construction.

   Input hygiene ("ValidateEdges", default Automatic = True iff n <= 10^6):
   the three O(|E|) checks of SparseWellFormedGraphQ from
   cct_mesh_sparse_stabilizer.wl, re-implemented INLINE here (that file is
   read-only and is a self-running script, so it is not Get-able as a
   library): no out-of-range indices, no self-loops, no duplicate (sorted)
   edges.  Abort with a clear message on failure.

   Adjacency: built with a native SparseArray; CRITICAL (empirically
   verified, and re-verified in V0): sa["AdjacencyLists"] returns neighbor
   lists in internal storage order, NOT guaranteed sorted - the explicit
   Sort /@ is MANDATORY, otherwise the "rowZ" analytic defaults violate the
   sorted-support invariant and every Complement/Union downstream silently
   misbehaves.
   --------------------------------------------------------------------------- *)
CCTValidateEdgesInline[n_Integer, edges_List] := Module[
  {flatV, oor, sl, dup},
  CCTAssert[MatchQ[edges, {{_Integer, _Integer} ...}],
    "NewGraphStateTableau: edges must be a list of integer pairs", Short[edges, 3]];
  flatV = Flatten[edges];
  oor = Select[flatV, (# < 1 || # > n) &];
  CCTAssert[oor === {}, "NewGraphStateTableau: out-of-range vertex indices",
    Take[oor, UpTo[10]]];
  sl = Select[edges, #[[1]] == #[[2]] &];
  CCTAssert[sl === {}, "NewGraphStateTableau: self-loop edges", Take[sl, UpTo[10]]];
  dup = Select[Tally[Sort /@ edges], #[[2]] > 1 &];
  CCTAssert[dup === {}, "NewGraphStateTableau: duplicate edges", Take[dup, UpTo[10]]];
  True];

Options[NewGraphStateTableau] = {"ValidateEdges" -> Automatic};

NewGraphStateTableau[n_Integer?Positive, edges_List, OptionsPattern[]] := Module[
  {CCTTab, adj, val = OptionValue["ValidateEdges"], ed, pos, sa},
  If[val === Automatic, val = (n <= 10^6)];
  If[TrueQ[val], CCTValidateEdgesInline[n, edges]];
  adj = If[edges === {},
    ConstantArray[{}, n],
    ed = Developer`ToPackedArray[edges];
    pos = Join[ed, Reverse[ed, 2]];
    sa = SparseArray[pos -> ConstantArray[1, Length[pos]], {n, n}];
    Sort /@ sa["AdjacencyLists"]];                   (* Sort /@ is MANDATORY *)
  (* --- literal (hash-stored) DownValues FIRST --- *)
  CCTTab["n"] = n;
  CCTTab["adj"] = adj;
  CCTTab["dirtyCount"] = 0;
  CCTTab["maxWeight"] = 0;
  (* --- pattern fallbacks: the analytic graph-state defaults.  A literal
     write through SetRow shadows these per-key; Unset would restore them.
     Rows 1..n are destabilizers d_v = Z_v; rows n+1..2n are stabilizers
     K_v = X_v prod_{u~v} Z_u. --- *)
  CCTTab["rowX", i_Integer] := If[i <= CCTTab["n"], {}, {i - CCTTab["n"]}];
  CCTTab["rowZ", i_Integer] := If[i <= CCTTab["n"], {i},
     CCTTab["adj"][[i - CCTTab["n"]]]];
  CCTTab["r", _Integer] := 0;
  CCTTab["xincS", q_Integer] := {CCTTab["n"] + q};      (* only K_q has x_q=1 *)
  CCTTab["xincD", _Integer] := {};                      (* no destab has X    *)
  CCTTab["zincS", q_Integer] := (CCTTab["n"] + #) & /@ CCTTab["adj"][[q]];
  CCTTab["zincD", q_Integer] := {q};                    (* d_q = Z_q          *)
  CCTTab["isDirty", _Integer] := False;
  CCTTab];

(* ---------------------------------------------------------------------------
   SECTION L3. The SetRow choke point + phase-only FlipR + row accessors.

   ALL row mutations (gates, rowsum, measurement row replacement) go through
   SetRow: it diffs old vs new supports and updates the four incidence maps
   (qubit -> sorted list of row ids with an X / Z at that qubit, split by
   stabilizer/destabilizer half).  Because incidence reads ALSO fall back to
   correct analytic defaults, the read-modify-write here transparently
   materializes incidence lists on first touch.  This single choke point
   eliminates the incidence-desync bug class.
   --------------------------------------------------------------------------- *)
SetRow[tab_Symbol, h_Integer, newX_List, newZ_List, newR_Integer] := Module[
  {n = tab["n"], oldX, oldZ, xKey, zKey},
  oldX = tab["rowX", h]; oldZ = tab["rowZ", h];        (* fallback-aware reads *)
  {xKey, zKey} = If[h <= n, {"xincD", "zincD"}, {"xincS", "zincS"}];
  Scan[(tab[xKey, #] = Complement[tab[xKey, #], {h}]) &, Complement[oldX, newX]];
  Scan[(tab[xKey, #] = Union[tab[xKey, #], {h}]) &,      Complement[newX, oldX]];
  Scan[(tab[zKey, #] = Complement[tab[zKey, #], {h}]) &, Complement[oldZ, newZ]];
  Scan[(tab[zKey, #] = Union[tab[zKey, #], {h}]) &,      Complement[newZ, oldZ]];
  tab["rowX", h] = newX; tab["rowZ", h] = newZ; tab["r", h] = newR;
  If[!TrueQ[tab["isDirty", h]],
    tab["isDirty", h] = True;
    tab["dirtyCount"] = tab["dirtyCount"] + 1];
  tab["maxWeight"] = Max[tab["maxWeight"], Length[newX] + Length[newZ]];
  tab];

(* phase-only update (used by ApplyX/Y/Z): no support diffs needed *)
FlipR[tab_Symbol, h_Integer] := (
  tab["r", h] = BitXor[tab["r", h], 1];
  If[!TrueQ[tab["isDirty", h]],
    tab["isDirty", h] = True;
    tab["dirtyCount"] = tab["dirtyCount"] + 1];
  tab);

TableauRow[tab_Symbol, i_Integer] :=
  <|"X" -> tab["rowX", i], "Z" -> tab["rowZ", i], "R" -> tab["r", i]|>;

TableauStats[tab_Symbol] :=
  <|"DirtyRows" -> tab["dirtyCount"], "MaxRowWeight" -> tab["maxWeight"],
    "n" -> tab["n"]|>;

(* each tableau owns exactly one symbol; counters are incremental, so no
   telemetry scan is needed before freeing.  Pattern substitution inserts the
   concrete symbol into ClearAll's held argument - standard idiom. *)
FreeTableau[tab_Symbol] := ClearAll[tab];

(* ---------------------------------------------------------------------------
   SECTION L4. rowsum (Aaronson-Gottesman): row h := row i * row h.
       s := 2 r_h + 2 r_i + Sum_j g(x_ij, z_ij, x_hj, z_hj)   (mod 4)
   with row i's (SOURCE) bits fed FIRST to g.  s is even iff the two rows
   COMMUTE; this simulator's measurement procedure only ever rowsums
   commuting pairs BECAUSE the pivot's destabilizer partner p-n is excluded
   from the rowsum loop before being overwritten (AG's original loop includes
   it and then discards the corrupted row; excluding it is equivalent,
   cheaper, and makes the even-parity ASSERT a genuine invariant check).  If
   the assert fires, the tableau is corrupt: full diagnostics + Abort[].
   The g-sum runs ONLY over Union[supp_X(i), supp_Z(i)] (g vanishes where the
   source row is identity), so cost is O(w_i + w_h) up to membership lookups
   (Association lookups, O(1) amortized).
   --------------------------------------------------------------------------- *)
CCTBitLookup[lst_List] := Association[Thread[lst -> True]];

RowSumInto[tab_Symbol, h_Integer, i_Integer] := Module[
  {xi, zi, xh, zh, rh, ri, js, xiA, ziA, xhA, zhA, s},
  xi = tab["rowX", i]; zi = tab["rowZ", i];
  xh = tab["rowX", h]; zh = tab["rowZ", h];
  rh = tab["r", h]; ri = tab["r", i];
  js = Union[xi, zi];
  xiA = CCTBitLookup[xi]; ziA = CCTBitLookup[zi];
  xhA = CCTBitLookup[xh]; zhA = CCTBitLookup[zh];
  s = Mod[2 rh + 2 ri +
      Total[gPhase[Boole[KeyExistsQ[xiA, #]], Boole[KeyExistsQ[ziA, #]],
          Boole[KeyExistsQ[xhA, #]], Boole[KeyExistsQ[zhA, #]]] & /@ js], 4];
  If[!(s === 0 || s === 2),
    Print["*** RowSumInto PARITY VIOLATION (anticommuting rowsum => corrupt tableau)"];
    Print["    h=", h, " rowX_h=", xh, " rowZ_h=", zh, " r_h=", rh];
    Print["    i=", i, " rowX_i=", xi, " rowZ_i=", zi, " r_i=", ri, " s=", s];
    Abort[]];
  SetRow[tab, h, SymDiff[xh, xi], SymDiff[zh, zi], s/2];
  tab];

(* ---------------------------------------------------------------------------
   SECTION L5. Gate conjugation rules (exact; verified against dense matrix
   conjugation over ALL Pauli combinations in CCTMBQCRunV0Foundations[]).
   Phase updates use PRE-update bits.  Affected-row discovery uses incidence
   SNAPSHOTS taken BEFORE the loop (SetRow mutates the live incidence lists);
   per-row bits at the touched qubit(s) come from those snapshots, never from
   the mutated live lists.  All Apply* mutate tab in place and return tab.
   --------------------------------------------------------------------------- *)

(* H: r ^= x_q z_q  (H Y H = -Y);  swap x_q <-> z_q membership *)
ApplyH[tab_Symbol, q_Integer] := Module[{n = tab["n"], xset, zset, rows, xA, zA},
  CCTAssert[1 <= q <= n, "ApplyH: qubit out of range", {q, n}];
  xset = Union[tab["xincS", q], tab["xincD", q]];
  zset = Union[tab["zincS", q], tab["zincD", q]];
  rows = Union[xset, zset];
  xA = CCTBitLookup[xset]; zA = CCTBitLookup[zset];
  Scan[Function[h, Module[{xq = KeyExistsQ[xA, h], zq = KeyExistsQ[zA, h], rX, rZ, r},
     rX = tab["rowX", h]; rZ = tab["rowZ", h]; r = tab["r", h];
     Which[
       xq && zq, SetRow[tab, h, rX, rZ, BitXor[r, 1]],       (* Y -> -Y *)
       xq,       SetRow[tab, h, Complement[rX, {q}], Union[rZ, {q}], r],
       True,     SetRow[tab, h, Union[rX, {q}], Complement[rZ, {q}], r]]]],
    rows];
  tab];

(* S: rows with x_q=1:  r ^= z_q;  z_q ^= 1  (X->Y, Y->-X, Z->Z) *)
ApplyS[tab_Symbol, q_Integer] := Module[{n = tab["n"], rows, zA},
  CCTAssert[1 <= q <= n, "ApplyS: qubit out of range", {q, n}];
  rows = Union[tab["xincS", q], tab["xincD", q]];
  zA = CCTBitLookup[Union[tab["zincS", q], tab["zincD", q]]];
  Scan[Function[h, Module[{rX, rZ, r, zq},
     rX = tab["rowX", h]; rZ = tab["rowZ", h]; r = tab["r", h];
     zq = KeyExistsQ[zA, h];
     SetRow[tab, h, rX, SymDiff[rZ, {q}], If[zq, BitXor[r, 1], r]]]],
    rows];
  tab];

(* Sdg (INTERNAL helper for the Y basis): rows with x_q=1:
   r ^= (1 - z_q);  z_q ^= 1   (X->-Y, Y->X) *)
ApplySdg[tab_Symbol, q_Integer] := Module[{n = tab["n"], rows, zA},
  CCTAssert[1 <= q <= n, "ApplySdg: qubit out of range", {q, n}];
  rows = Union[tab["xincS", q], tab["xincD", q]];
  zA = CCTBitLookup[Union[tab["zincS", q], tab["zincD", q]]];
  Scan[Function[h, Module[{rX, rZ, r, zq},
     rX = tab["rowX", h]; rZ = tab["rowZ", h]; r = tab["r", h];
     zq = KeyExistsQ[zA, h];
     SetRow[tab, h, rX, SymDiff[rZ, {q}], If[zq, r, BitXor[r, 1]]]]],
    rows];
  tab];

(* Z: flip sign on rows with x_q = 1 (phase-only) *)
ApplyZ[tab_Symbol, q_Integer] := Module[{n = tab["n"], rows},
  CCTAssert[1 <= q <= n, "ApplyZ: qubit out of range", {q, n}];
  rows = Union[tab["xincS", q], tab["xincD", q]];
  Scan[FlipR[tab, #] &, rows];
  tab];

(* X: flip sign on rows with z_q = 1 (phase-only) *)
ApplyX[tab_Symbol, q_Integer] := Module[{n = tab["n"], rows},
  CCTAssert[1 <= q <= n, "ApplyX: qubit out of range", {q, n}];
  rows = Union[tab["zincS", q], tab["zincD", q]];
  Scan[FlipR[tab, #] &, rows];
  tab];

(* Y: flip sign on rows with x_q XOR z_q = 1 (phase-only) *)
ApplyY[tab_Symbol, q_Integer] := Module[{n = tab["n"], rows},
  CCTAssert[1 <= q <= n, "ApplyY: qubit out of range", {q, n}];
  rows = SymDiff[Union[tab["xincS", q], tab["xincD", q]],
                 Union[tab["zincS", q], tab["zincD", q]]];
  Scan[FlipR[tab, #] &, rows];
  tab];

(* CZ: rows with x_a=1 or x_b=1:
   r ^= x_a x_b (z_a XOR z_b);  z_a ^= x_b;  z_b ^= x_a
   (verified identities include CZ(X_a X_b)CZ = +Y_a Y_b, CZ(X_a Y_b)CZ = -Y_a X_b) *)
ApplyCZ[tab_Symbol, a_Integer, b_Integer] := Module[
  {n = tab["n"], xaA, zaA, xbA, zbA, rows},
  CCTAssert[a != b, "ApplyCZ: qubits must differ", {a, b}];
  CCTAssert[1 <= a <= n && 1 <= b <= n, "ApplyCZ: qubit out of range", {a, b, n}];
  xaA = CCTBitLookup[Union[tab["xincS", a], tab["xincD", a]]];
  zaA = CCTBitLookup[Union[tab["zincS", a], tab["zincD", a]]];
  xbA = CCTBitLookup[Union[tab["xincS", b], tab["xincD", b]]];
  zbA = CCTBitLookup[Union[tab["zincS", b], tab["zincD", b]]];
  rows = Union[Keys[xaA], Keys[xbA]];
  Scan[Function[h, Module[{xa = KeyExistsQ[xaA, h], za = KeyExistsQ[zaA, h],
      xb = KeyExistsQ[xbA, h], zb = KeyExistsQ[zbA, h], rX, rZ, r, newZ, newR},
     rX = tab["rowX", h]; rZ = tab["rowZ", h]; r = tab["r", h];
     newR = If[xa && xb && Xor[za, zb], BitXor[r, 1], r];
     newZ = rZ;
     If[xb, newZ = SymDiff[newZ, {a}]];
     If[xa, newZ = SymDiff[newZ, {b}]];
     SetRow[tab, h, rX, newZ, newR]]],
    rows];
  tab];

(* CNOT (control a, target b): rows with x_a=1 or z_b=1:
   r ^= x_a z_b (x_b XOR z_a XOR 1);  x_b ^= x_a;  z_a ^= z_b *)
ApplyCNOT[tab_Symbol, a_Integer, b_Integer] := Module[
  {n = tab["n"], xaA, zaA, xbA, zbA, rows},
  CCTAssert[a != b, "ApplyCNOT: qubits must differ", {a, b}];
  CCTAssert[1 <= a <= n && 1 <= b <= n, "ApplyCNOT: qubit out of range", {a, b, n}];
  xaA = CCTBitLookup[Union[tab["xincS", a], tab["xincD", a]]];
  zaA = CCTBitLookup[Union[tab["zincS", a], tab["zincD", a]]];
  xbA = CCTBitLookup[Union[tab["xincS", b], tab["xincD", b]]];
  zbA = CCTBitLookup[Union[tab["zincS", b], tab["zincD", b]]];
  rows = Union[Keys[xaA], Keys[zbA]];
  Scan[Function[h, Module[{xa = KeyExistsQ[xaA, h], za = KeyExistsQ[zaA, h],
      xb = KeyExistsQ[xbA, h], zb = KeyExistsQ[zbA, h], rX, rZ, r, newX, newZ, newR},
     rX = tab["rowX", h]; rZ = tab["rowZ", h]; r = tab["r", h];
     newR = If[xa && zb && !Xor[xb, za], BitXor[r, 1], r];   (* x_b XOR z_a XOR 1 *)
     newX = If[xa, SymDiff[rX, {b}], rX];
     newZ = If[zb, SymDiff[rZ, {a}], rZ];
     SetRow[tab, h, newX, newZ, newR]]],
    rows];
  tab];

(* ---------------------------------------------------------------------------
   SECTION L6. Measurement.

   MeasureZCore (AG measurement with destabilizers):

   CASE A - RANDOM (some stabilizer row has x_q = 1, found in O(1) via the
   "xincS" incidence): pick pivot p; rowsum p into every OTHER row with
   x_q = 1 - both stabilizer rows and destabilizer rows - EXCLUDING the
   pivot's own destabilizer partner p-n (it is the one anticommuting rowsum
   partner and gets overwritten anyway; excluding it keeps the parity ASSERT
   a genuine invariant).  Then new destabilizer p-n := old pivot row,
   new stabilizer p := (-1)^b Z_q.  Outcome b is RandomInteger[] unless
   forced.  Born probability of either value is exactly 1/2.

   CASE B - DETERMINISTIC (no stabilizer row has X at q): Z_q is (up to
   sign) in the stabilizer group.  The generator subset is read off the
   DESTABILIZER X-incidence: T = xincD[q] (destabilizer ids i whose d_i
   anticommutes with Z_q; by symplectic pairing Z_q = +/- prod_{i in T} s_i).
   Accumulate a LOCAL scratch row via the exact rowsum arithmetic; the
   scratch MUST come out equal to +/- Z_q (defensive assert), and its sign
   is the deterministic outcome.  The tableau is NOT modified.  Cost:
   O(|T| x row weights) - the destabilizer payoff; no Gaussian elimination.

   Basis reduction (single X-incidence suffices for all bases):
     "Z": core directly.
     "X": H, core, H            (H Z H = X; outcome maps identically;
                                 trailing H restores the true post-X state).
     "Y": Sdg, H, core, H, S    (U = H.Sdg has U Y Udg = Z, so outcomes map
                                 with NO bit flip; Udg = S.H applied as
                                 H-then-S restores the exact post-Y state).
   In the ForcedOutcome-conflict path (Probability -> 0) the un-conjugation
   still runs and CASE B never mutates, so the tableau is NET unchanged.
   --------------------------------------------------------------------------- *)
MeasureZCore[tab_Symbol, q_Integer, forced_] := Module[
  {n = tab["n"], stabAnti},
  stabAnti = tab["xincS", q];                          (* snapshot *)
  If[stabAnti =!= {},
   (* ----- CASE A: RANDOM ----- *)
   Module[{p, others, px, pz, pr, b},
    p = First[stabAnti];
    others = Join[DeleteCases[stabAnti, p],
      Complement[tab["xincD", q], {p - n}]];           (* snapshot; exclude partner *)
    px = tab["rowX", p]; pz = tab["rowZ", p]; pr = tab["r", p];  (* snapshot pivot *)
    Scan[RowSumInto[tab, #, p] &, others];             (* clears x_q on each *)
    b = If[forced === Automatic, RandomInteger[], forced];
    SetRow[tab, p - n, px, pz, pr];                    (* new destab = old pivot *)
    SetRow[tab, p, {}, {q}, b];                        (* new stab = (-1)^b Z_q *)
    <|"Outcome" -> b, "Deterministic" -> False, "Probability" -> 1/2|>],
   (* ----- CASE B: DETERMINISTIC ----- *)
   Module[{T = tab["xincD", q], sx = {}, sz = {}, sr = 0, m, prob},
    Scan[Function[i, Module[{rid = n + i, rx, rz, rr, js, rxA, rzA, sxA, szA, s},
       rx = tab["rowX", rid]; rz = tab["rowZ", rid]; rr = tab["r", rid];
       js = Union[rx, rz];
       rxA = CCTBitLookup[rx]; rzA = CCTBitLookup[rz];
       sxA = CCTBitLookup[sx]; szA = CCTBitLookup[sz];
       s = Mod[2 sr + 2 rr +
           Total[gPhase[Boole[KeyExistsQ[rxA, #]], Boole[KeyExistsQ[rzA, #]],
               Boole[KeyExistsQ[sxA, #]], Boole[KeyExistsQ[szA, #]]] & /@ js], 4];
       If[!(s === 0 || s === 2),
         Print["*** MeasureZCore CASE B PARITY VIOLATION: q=", q, " i=", i,
           " scratch=", {sx, sz, sr}, " row=", {rx, rz, rr}, " s=", s];
         Abort[]];
       sr = s/2; sx = SymDiff[sx, rx]; sz = SymDiff[sz, rz]]], T];
    If[!(sx === {} && sz === {q}),
      Print["*** MeasureZCore CASE B: scratch != +/- Z_q => corrupt tableau"];
      Print["    q=", q, " T=", T, " scratchX=", sx, " scratchZ=", sz, " scratchR=", sr];
      Abort[]];
    m = sr;
    prob = If[forced =!= Automatic && forced =!= m, 0, 1];
    <|"Outcome" -> m, "Deterministic" -> True, "Probability" -> prob|>]]];

Options[MeasurePauli] = {"ForcedOutcome" -> Automatic};

MeasurePauli[tab_Symbol, q_Integer, basis_String, OptionsPattern[]] := Module[
  {n = tab["n"], forced = OptionValue["ForcedOutcome"], rec},
  CCTAssert[1 <= q <= n, "MeasurePauli: qubit out of range", {q, n}];
  CCTAssert[MemberQ[{"X", "Y", "Z"}, basis], "MeasurePauli: basis must be X|Y|Z", basis];
  CCTAssert[MemberQ[{0, 1, Automatic}, forced],
    "MeasurePauli: ForcedOutcome must be 0|1|Automatic", forced];
  rec = Switch[basis,
    "Z", MeasureZCore[tab, q, forced],
    "X", (ApplyH[tab, q];
          With[{r = MeasureZCore[tab, q, forced]}, ApplyH[tab, q]; r]),
    "Y", (ApplySdg[tab, q]; ApplyH[tab, q];
          With[{r = MeasureZCore[tab, q, forced]},
            ApplyH[tab, q]; ApplyS[tab, q]; r])];
  Join[rec, <|"Qubit" -> q, "Basis" -> basis|>]];

(* ---------------------------------------------------------------------------
   SECTION L7. Exact statevector extraction (n <= 10 validation aid) and the
   exact up-to-global-phase-and-scale equality predicate.

   Projector method: P = prod_v (I + G_v)/2 is the rank-1 projector |G><G|
   (the 1/2^n is dropped - output is unnormalized by default).  Scan basis
   vectors e_k ascending; a rank-1 projector guarantees some e_k has nonzero
   image, and the ascending scan makes the output deterministic.  Entries are
   exact Gaussian integers {0,+-1,+-i} in each Pauli factor, so the result is
   an exact Gaussian-integer vector.

   PhaseScaleEquivalentQ: Cauchy-Schwarz equality |<u,v>|^2 = |u|^2 |v|^2
   holds iff u,v are proportional; for Gaussian-integer vectors both sides
   are plain non-negative integers, so === is exact (no Simplify, no
   tolerance).
   --------------------------------------------------------------------------- *)
Options[StateVectorFromTableau] = {"Normalized" -> False};

StateVectorFromTableau[tab_Symbol, OptionsPattern[]] := Module[
  {n = tab["n"], dim, sI, sX, sZ, sY, Gmats, zero, found, w},
  If[n > 10,
    Print["*** StateVectorFromTableau: n = ", n, " > 10 - refusing (2^n blowup)."];
    Abort[]];
  dim = 2^n;
  sI = SparseArray[{{1, 0}, {0, 1}}]; sX = SparseArray[{{0, 1}, {1, 0}}];
  sZ = SparseArray[{{1, 0}, {0, -1}}]; sY = SparseArray[{{0, -I}, {I, 0}}];
  Gmats = Table[Module[{Xs = tab["rowX", n + v], Zs = tab["rowZ", n + v],
      r = tab["r", n + v], facs},
     facs = Table[Module[{xb = MemberQ[Xs, j], zb = MemberQ[Zs, j]},
        Which[xb && zb, sY, xb, sX, zb, sZ, True, sI]], {j, n}];
     (-1)^r Fold[KroneckerProduct, First[facs], Rest[facs]]], {v, n}];
  zero = ConstantArray[0, dim];
  found = None;
  Do[
    w = Normal[UnitVector[dim, k]];
    Do[w = Normal[w + Gmats[[v]] . w], {v, n}];
    If[w =!= zero, found = w; Break[]],
    {k, dim}];
  CCTAssert[found =!= None,
    "StateVectorFromTableau: all basis images vanished (projector not rank 1?)", n];
  If[TrueQ[OptionValue["Normalized"]],
    found/Sqrt[Conjugate[found] . found],
    found]];

PhaseScaleEquivalentQ[u_, v_] := Module[{ip = Conjugate[u] . v},
  (Conjugate[u] . u =!= 0) && (Conjugate[v] . v =!= 0) &&
  (ip Conjugate[ip] === (Conjugate[u] . u) (Conjugate[v] . v))];

(* ---------------------------------------------------------------------------
   SECTION L8. V0 micro-foundations: the load-bearing WL behaviors and ALL
   gate/g algebra rules, machine-verified.  Called by the self-check below
   and by cct_mbqc_sim_tests.wl.  Returns an Association of booleans and
   Aborts on any failure.
   --------------------------------------------------------------------------- *)
CCTMBQCRunV0Foundations[] := Module[
  {okIdiom, okAdjSort, pm, gOK, hOK, sOK, sdgOK, xOK, yOK, zOK, czOK, cnOK,
   hsdgOK, okDefaults, Hint, Sm, Sdgm, CZm, CNm, res},
  (* (a) THE load-bearing WL idiom: a literal DownValue shadows a pattern
     fallback; Unset restores the fallback. *)
  okIdiom = Module[{obj, a1, a2, a3},
    obj["val", i_Integer] := {i};
    a1 = (obj["val", 3] === {3});
    obj["val", 7] = {99};
    a2 = (obj["val", 7] === {99} && obj["val", 3] === {3});
    obj["val", 7] =.;
    a3 = (obj["val", 7] === {7});
    a1 && a2 && a3];
  CCTAssert[okIdiom, "V0(a): literal-DownValue-shadows-pattern idiom", okIdiom];
  (* (b) Sort /@ sa["AdjacencyLists"] gives sorted neighbor lists (the raw
     property is only guaranteed to be in internal storage order). *)
  okAdjSort = Module[{edges = {{1, 3}, {2, 3}, {1, 4}, {3, 4}}, pos, sa, adj},
    pos = Join[edges, Reverse[edges, 2]];
    sa = SparseArray[pos -> ConstantArray[1, Length[pos]], {4, 4}];
    adj = Sort /@ sa["AdjacencyLists"];
    adj === {{3, 4}, {3}, {1, 2, 4}, {1, 3}}];
  CCTAssert[okAdjSort, "V0(b): Sort/@ AdjacencyLists", okAdjSort];
  (* (c) exact algebra: g against all 16 dense 2x2 Pauli products; every
     gate rule of Section L5 against dense conjugation, all Pauli inputs. *)
  pm[x_, z_] := Which[
    x == 1 && z == 1, {{0, -I}, {I, 0}},
    x == 1, {{0, 1}, {1, 0}},
    z == 1, {{1, 0}, {0, -1}},
    True, {{1, 0}, {0, 1}}];
  gOK = And @@ Flatten[Table[
     pm[x1, z1] . pm[x2, z2] ===
       I^gPhase[x1, z1, x2, z2] pm[BitXor[x1, x2], BitXor[z1, z2]],
     {x1, 0, 1}, {z1, 0, 1}, {x2, 0, 1}, {z2, 0, 1}]];
  CCTAssert[gOK, "V0(c): g function vs all 16 dense Pauli products", gOK];
  Hint = {{1, 1}, {1, -1}};                     (* integer H: Sqrt[2] H *)
  Sm = {{1, 0}, {0, I}}; Sdgm = {{1, 0}, {0, -I}};
  hOK = And @@ Flatten[Table[
     Hint . pm[x, z] . Hint === 2 (-1)^(x z) pm[z, x], {x, 0, 1}, {z, 0, 1}]];
  sOK = And @@ Flatten[Table[
     Sm . pm[x, z] . Sdgm === (-1)^(x z) pm[x, BitXor[z, x]], {x, 0, 1}, {z, 0, 1}]];
  sdgOK = And @@ Flatten[Table[
     Sdgm . pm[x, z] . Sm === (-1)^(x (1 - z)) pm[x, BitXor[z, x]],
     {x, 0, 1}, {z, 0, 1}]];
  xOK = And @@ Flatten[Table[
     pm[1, 0] . pm[x, z] . pm[1, 0] === (-1)^z pm[x, z], {x, 0, 1}, {z, 0, 1}]];
  zOK = And @@ Flatten[Table[
     pm[0, 1] . pm[x, z] . pm[0, 1] === (-1)^x pm[x, z], {x, 0, 1}, {z, 0, 1}]];
  yOK = And @@ Flatten[Table[
     pm[1, 1] . pm[x, z] . pm[1, 1] === (-1)^BitXor[x, z] pm[x, z],
     {x, 0, 1}, {z, 0, 1}]];
  CZm = DiagonalMatrix[{1, 1, 1, -1}];
  czOK = And @@ Flatten[Table[
     CZm . KroneckerProduct[pm[xa, za], pm[xb, zb]] . CZm ===
       (-1)^(xa xb BitXor[za, zb]) KroneckerProduct[
         pm[xa, BitXor[za, xb]], pm[xb, BitXor[zb, xa]]],
     {xa, 0, 1}, {za, 0, 1}, {xb, 0, 1}, {zb, 0, 1}]];
  CNm = {{1, 0, 0, 0}, {0, 1, 0, 0}, {0, 0, 0, 1}, {0, 0, 1, 0}};
  cnOK = And @@ Flatten[Table[
     CNm . KroneckerProduct[pm[xa, za], pm[xb, zb]] . CNm ===
       (-1)^(xa zb BitXor[xb, BitXor[za, 1]]) KroneckerProduct[
         pm[xa, BitXor[za, zb]], pm[BitXor[xb, xa], zb]],
     {xa, 0, 1}, {za, 0, 1}, {xb, 0, 1}, {zb, 0, 1}]];
  CCTAssert[hOK, "V0(c): H tableau rule vs dense conjugation", hOK];
  CCTAssert[sOK, "V0(c): S tableau rule vs dense conjugation", sOK];
  CCTAssert[sdgOK, "V0(c): Sdg tableau rule vs dense conjugation", sdgOK];
  CCTAssert[xOK && yOK && zOK, "V0(c): X/Y/Z phase rules vs dense conjugation",
    {xOK, yOK, zOK}];
  CCTAssert[czOK, "V0(c): CZ tableau rule vs dense conjugation (16 cases)", czOK];
  CCTAssert[cnOK, "V0(c): CNOT tableau rule vs dense conjugation (16 cases)", cnOK];
  (* (d) (H.Sdg) Y (H.Sdg)^dag == Z  (the Y-basis reduction; factor 2 from
     the integer H = Sqrt[2] H_unitary) *)
  hsdgOK = With[{U = Hint . Sdgm},
    U . pm[1, 1] . ConjugateTranspose[U] === 2 pm[0, 1]];
  CCTAssert[hsdgOK, "V0(d): (H.Sdg) Y (H.Sdg)^dag == Z", hsdgOK];
  (* (e) analytic defaults of a freshly built tableau on the V0(b) graph *)
  okDefaults = Module[{tb = NewGraphStateTableau[4, {{1, 3}, {2, 3}, {1, 4}, {3, 4}}], ok},
    ok = (tb["rowX", 4 + 3] === {3}) && (tb["rowZ", 4 + 3] === {1, 2, 4}) &&
         (tb["rowX", 2] === {}) && (tb["rowZ", 2] === {2}) && (tb["r", 5] === 0) &&
         (tb["xincS", 3] === {7}) && (tb["xincD", 3] === {}) &&
         (tb["zincS", 1] === {7, 8}) && (tb["zincD", 1] === {1}) &&
         (TableauStats[tb]["DirtyRows"] === 0);
    FreeTableau[tb]; ok];
  CCTAssert[okDefaults, "V0(e): fresh-tableau analytic defaults", okDefaults];
  res = <|"IdiomOK" -> okIdiom, "AdjSortOK" -> okAdjSort, "gOK" -> gOK,
    "HOK" -> hOK, "SOK" -> sOK, "SdgOK" -> sdgOK, "XYZOK" -> (xOK && yOK && zOK),
    "CZOK" -> czOK, "CNOTOK" -> cnOK, "HSdgYOK" -> hsdgOK,
    "TableauDefaultsOK" -> okDefaults, "AllOK" -> True|>;
  res];

(* ---------------------------------------------------------------------------
   SECTION L9. Guarded self-check (skipped when CCTMBQCLoadOnly = True).
   Fast: V0 micro-foundations + a tiny C5-ring measurement demo.
   The FULL differential validation suite is cct_mbqc_sim_tests.wl.
   --------------------------------------------------------------------------- *)
If[!TrueQ[CCTMBQCLoadOnly],
  Module[{v0, tab, u, vref, czfull, edges5, rec1, rec2, rec3, eqOK, detOK, conflictOK},
    Print["=== cct_mbqc_sim.wl self-check (library mode: set CCTMBQCLoadOnly=True before Get to skip) ==="];
    Print["--- V0: micro-foundations (WL idioms + exact gate/g algebra) ---"];
    v0 = CCTMBQCRunV0Foundations[];
    Print["    ", v0];
    Print["--- C5 demo: graph-state init === explicit-CZ reference (exact) ---"];
    edges5 = Sort /@ Table[{i, Mod[i, 5] + 1}, {i, 1, 5}];
    tab = NewGraphStateTableau[5, edges5];
    u = StateVectorFromTableau[tab];
    czfull[n_, i_, j_] := DiagonalMatrix[SparseArray[Table[
       If[IntegerDigits[b, 2, n][[i]] == 1 && IntegerDigits[b, 2, n][[j]] == 1, -1, 1],
       {b, 0, 2^n - 1}]]];
    vref = ConstantArray[1, 2^5];
    Do[vref = Normal[czfull[5, e[[1]], e[[2]]] . vref], {e, edges5}];
    eqOK = PhaseScaleEquivalentQ[u, vref];
    Print["    C5 tableau state == prod CZ |+>^5 (up to phase/scale, exact)? ", eqOK];
    CCTAssert[eqOK, "self-check: C5 init", eqOK];
    Print["--- C5 demo: forced Z measurement + determinism repeat + forced conflict ---"];
    rec1 = MeasurePauli[tab, 1, "Z", "ForcedOutcome" -> 0];
    rec2 = MeasurePauli[tab, 1, "Z"];
    rec3 = MeasurePauli[tab, 1, "Z", "ForcedOutcome" -> 1];
    detOK = (rec1["Deterministic"] === False && rec1["Probability"] === 1/2 &&
             rec2["Deterministic"] === True && rec2["Probability"] === 1 &&
             rec2["Outcome"] === 0);
    conflictOK = (rec3["Probability"] === 0 && rec3["Outcome"] === 0);
    Print["    first Z(q=1) forced 0: ", rec1];
    Print["    repeat Z(q=1):         ", rec2];
    Print["    forced-conflict Z(q=1)->1: ", rec3];
    CCTAssert[detOK, "self-check: determinism repeat", {rec1, rec2}];
    CCTAssert[conflictOK, "self-check: forced conflict", rec3];
    FreeTableau[tab];
    Print[];
    Print["CCTMBQCSimSelfCheck: ", <|"V0" -> v0["AllOK"], "C5InitOK" -> eqOK,
      "DeterminismOK" -> detOK, "ForcedConflictOK" -> conflictOK, "AllPass" -> True|>];
  ]
]
