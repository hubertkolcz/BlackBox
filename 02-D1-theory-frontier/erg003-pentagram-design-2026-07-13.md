# ERG-003 pentagram-layer search: design for the 18-clique decision in C9 v C9 v C9 v C5

**Cell.** G = C9 v C9 v C9 v C5 = H v C5, H = C9 v C9 v C9 (729 vertices), 3645
vertices total. `v` is the OR / conormal product (distinct tuples adjacent iff
adjacent in the base graph in at least one coordinate). Activation (CE
violation) holds iff omega(G) >= 18, load = omega/(8 sqrt5), 18/(8 sqrt5) =
9 sqrt5 / 20 ~ 1.006. Established bounds 16 <= omega <= 19; goal is to decide
whether an 18-clique exists (and, en route, pin the exact value).

> ## CRITICAL CORRECTION (2026-07-13, from `erg003_structure_check.py`)
>
> **The load-bearing "established fact" that the maximum 8-cliques of H are
> EXACTLY the 729 products-of-one-edge-per-factor is FALSE.** An exact
> max-clique solver (`bin/mcq.exe`, MCQ branch-and-bound) found a genuine
> 8-clique of H that is NOT a product of edges (vertices
> {(0,0,0),(6,8,4),(8,6,5),(5,8,4),(8,5,5),(8,7,6),(7,8,5),(7,7,8)};
> re-verified all 28 pairs adjacent). Its symmetry orbit (Z9^3 x S3) alone
> yields **>=4374 distinct non-product maximum 8-cliques**, and
> `HeptagonCatalysis.wl` itself (line ~224) reports the size-8 clique
> population of H at **>10^8 (plausibly 10^10-10^12)**. omega(H)=8 still holds
> (theta ceiling 8.795 + product construction), but the *characterization* of
> its maximum cliques does not.
>
> **Consequence for this design.** The method council's route-(iii) rigidity
> argument -- "25 of 26 S=17 families force a pentagram-pair union to be a
> MAXIMUM 8-clique of H, *hence a product-of-edges clique* (729 candidates,
> rigid)" -- is INVALID: the "hence product-of-edges" step is false. A pentagram
> pin to "a maximum 8-clique" ranges over >10^8 cliques (>10^8 / |Aut(H)|,
> |Aut(H)| = |D9 wr S3| = 18^3*6 = 34,992, so still MANY THOUSANDS of orbit
> representatives), NOT one canonical product. The council's feasibility
> estimate (core-hours-to-core-days) rested on this rigidity and must be
> revised upward. Sections 1 and 3 below are rewritten accordingly; the
> pentagram DECOMPOSITION, the family census, and the neighborhood-propagation
> measurements all remain valid -- only the "cheap 729-candidate pin"
> disappears. **Do not implement the 729-pin search; see sec 1'.**

This generalizes `HeptagonCatalysis.wl :: nineCliqueViaLayersQ` / the Python
`beyond7_theorem_sweep.py :: decide`, which decide the 2-box analogue
(9-clique in Cn v Cn v C5, omega(H2)=4) instantly. The generalization from 2
boxes to 3 boxes changes omega(H) from 4 to 8, so the dense compat-matrix
approach of the 2-box tool is replaced by max-clique enumeration + pentagram
constraint propagation (the 2-box tool materializes all size-<=3 cliques of a
49/81-vertex H and a full compat matrix; here H has 729 vertices and its
size->=4 clique domains explode -- see "Clique domains" below).

All numbers below are MEASURED (`erg003_structure_check.py`,
`erg003_pin_measure.py`), not assumed.

---

## 0. Verified structural facts this design rests on

From `erg003_structure_check.py` (3/4 PASS; claim 2 FAILS):

- **omega(H) = 8.** [PASS -- theta ceiling theta(comp C9)^3 = 8.795 gives
  omega <= 8; explicit product-of-edges 8-clique gives omega >= 8.]
- ~~The maximum 8-cliques of H are EXACTLY the 729 products-of-one-edge-per-
  factor~~ **[FALSE -- see CRITICAL CORRECTION above].** The 729 products ARE
  8-cliques, but they are NOT all of them: non-product maximum 8-cliques exist
  in the >10^8 range. Any design step that assumed a "maximum 8-clique of H"
  is one of 729 rigid products is unsound.
- **Pentagram layer principle** (H v C5): a clique of G meets each C5 layer
  c in {0..4} in an H-clique Q_c; C5-adjacent layers are jointly exclusive for
  free; each pentagram pair (c, c+2 mod 5) needs Q_c, Q_{c+2} disjoint with
  Q_c u Q_{c+2} an H-clique, hence s_c + s_{c+2} <= omega(H) = 8. Summing the
  pentagram 5-cycle 0-2-4-1-3-0 gives omega(G) <= floor(5*8/2) = 20.
- **The known 16-clique** (edge of C9 x [edge of C5 x 4-clique of C9vC9])
  decomposes into layer size vector (8,8,0,0,0) on two C5-adjacent positions;
  both nonempty layers are product-of-edges maximum 8-cliques of H.

## Size-vector families (S = 17), MEASURED

`erg003_structure_check.py` enumerates size vectors (s_0..s_4), s_i >= 0,
sum = S, with the pentagram necessary condition s_i + s_{i+2} <= 8, deduped
under the pentagon dihedral group D5 (order 10; rotations i->i+k, reflections
i->-i+k, which preserve both pentagon- and pentagram-adjacency):

| S  | families up to D5 | with a size-8 pentagram pin | without |
|----|-------------------|-----------------------------|---------|
| 16 | 57                | 52                          | 5       |
| 17 | **26**            | **25**                      | **1**   |
| 18 | 10                | 10                          | 0       |

Confirms the method council: **26 families for S=17, 25 of which force some
s_i + s_{i+2} = 8**. The lone no-pin S=17 family is **(3,3,3,4,4)** (pentagram
pair sums [6,7,7,7,7], all <= 7, so no layer pair fills a maximum 8-clique --
its layers are size-<=7 cliques of H, a much larger and unstructured domain).

**Key consequence for the activation decision:** at **S=18 all 10 families are
size-8-pinned (0 no-pin families)** -- so the actual 18-clique decision always
has a pentagram pair whose union is a maximum 8-clique of H. This is still
useful (it constrains the pinned pair to the max-clique variety), but -- given
the CRITICAL CORRECTION -- that variety is NOT 729 rigid products; it is the
full set of >10^8 maximum 8-cliques (thousands of Aut(H)-orbits). The pin
narrows the pair but does not make it cheap.

Note on target S: the search is parameterized by S. To DECIDE activation the
implementer runs S = 18 (existence of an 18-clique). S = 17 is the council's
worked family census and a natural warm-up / regression target; the family
generator takes S as an argument so all of S in {16,17,18,19} run through the
identical machinery. The design below is written for a general S.

---

## 1'. Per-family search: the pin is a maximum 8-clique (NOT 729 products)

**Pin (corrected).** For each family whose canonical size vector has a
pentagram pair (i, i+2) with s_i + s_{i+2} = 8, that pair's union Q_i u Q_{i+2}
is a MAXIMUM 8-clique of H. **This is where the naive plan breaks:** there are
>10^8 maximum 8-cliques (thousands of Aut(H)-orbits, |Aut(H)|=34,992), not 729,
so the pin is NOT a cheap 729-way branch. The pinned pair must be enumerated by
an actual MAXIMUM-CLIQUE ENUMERATOR over H (the `bin/mcq.exe` MCQ solver
generalized to emit all maximum cliques, or an equivalent bitset
Bron-Kerbosch-with-coloring), deduped under Aut(H). Splitting a fixed max clique
K into (Q_i, Q_{i+2}) of sizes (s_i, s_{i+2}) is still cheap -- any subset of an
8-clique is an H-clique, so all C(8, s_i) splits are legal -- but the number of
K's is the cost driver and it is large. **This is the finding that most changes
the feasibility picture and must be resolved before committing compute:** an
implementer should FIRST measure how many maximum-8-clique Aut(H)-orbits exist
(run `mcq.exe`-style enumeration with orbit dedup, time-boxed) to size the pin
branch honestly, rather than assuming 729.

Two mitigations that may restore tractability (both need measurement, neither
assumed):
- **Translate-pin one vertex.** H is vertex-transitive, so WLOG one vertex of
  the pinned max clique K is (0,0,0) (the 2-box tool uses exactly this Z_n^2
  pin). This divides the pin cost by ~729 and restricts K to max cliques through
  a fixed vertex = max cliques of the 386-vertex N_H(0) subgraph -- a much
  smaller enumeration. Measure |max cliques through (0,0,0)| first.
- **Only pins that extend.** Most maximum cliques K will not extend to the
  target S; forward-checking (does N_H(Q_i) ∩ N_H(Q_{i+2}) admit the other three
  layers at all?) prunes the pin stream early. Whether this prunes >10^8 down
  to something tractable is an EMPIRICAL question the implementer must settle on
  a sample before scaling.

**Propagation (MEASURED, `erg003_pin_measure.py`).** Once the pinned pair is
placed, the remaining three layers are forced into common H-neighborhoods. The
propagation principle is independent of the pin's structure. (The table below
was measured on a product-of-edges K; exact N_H sizes for non-product pins may
differ slightly but the sharp collapse with |S| is generic since H is
386-regular.) For a sub-clique S of a pinned 8-clique K, the common
H-neighborhood N_H(S) = {v : v adjacent to all of S} has these sizes, and the
largest clique there is exactly 8 - |S|:

| |S| | \|N_H(S)\| | omega(N_H(S)) |
|-----|-----------|----------------|
| 1   | 386       | 7              |
| 2   | 288       | 6              |
| 3   | 190       | 5              |
| 4   | 162       | 4              |
| 5   | 64        | 3              |
| 6   | 36        | 2              |
| 7   | 8         | 1              |
| 8   | 0         | -              |

(H is 386-regular.) Reading the propagation: a layer Q_j that is a pentagram
partner of a pinned layer Q_c of size s_c must live inside N_H(Q_c), whose
vertex count drops sharply with s_c (162 already at s_c=4, 8 at s_c=7). Each
new placement intersects its domain with N_H of all already-placed pentagram
partners, so candidate sets collapse fast -- e.g. two pentagram partners of
sizes 4 and 3 restrict a layer to a clique inside N_H(Q_a) ∩ N_H(Q_b), a set
far smaller than 162. **This is why neighborhood-restricted max-clique
enumeration replaces a global clique domain**: the domains are always
neighborhoods of already-placed layers (<= 386 vertices, usually << 100), never
the full 729-vertex H.

**Enumeration order (per family).** Order the 5 layers along the pentagram
cycle so that the pinned pair is placed first, then extend to pentagram-
adjacent layers in a fixed BFS from the pin:
1. Place pinned pair (Q_i, Q_{i+2}) := split of a maximum 8-clique K (enumerated
   by the max-clique enumerator, translate-pinned to contain (0,0,0), Aut(H)-
   deduped -- NOT a 729-product branch; see sec 1').
2. For the next layer j on the pentagram cycle, domain = max-cliques of size
   s_j inside the intersection of N_H(Q_c) over already-placed pentagram
   partners c of j. Enumerate via a Bron-Kerbosch / bitset pivot restricted to
   that neighborhood (target size s_j exactly).
3. Recurse; prune the moment any domain is empty. The last layer closes the
   pentagram 5-cycle (two pentagram constraints simultaneously) -- test both.
A hit = a full assignment; report the 18 (or S) tuples and STOP that family
(existence decision) or continue (if counting).

## 2. The one no-size-8-pin family (dedicated treatment)

The single S=17 no-pin family is **(3,3,3,4,4)**, pentagram pair sums
[6,7,7,7,7] (sum-of-pairs = 2S = 34 <= max 35, so four 7's and one 6).
No layer pair fills a maximum 8-clique, so there is no max-clique pin to anchor
on; every layer domain is a size-3 or size-4 clique of H. (This family is NOT
hit by the S=18 activation decision -- see the family table -- so it is only a
regression/census concern, not a blocker for the main result. NOTE: with claim
2 false, even the pinned families no longer enjoy a cheap anchor, so this "no-
pin" family is less special than the council framing suggested -- ALL families
now require max-clique enumeration for their anchor layer.)

**Clique domains of H (MEASURED, why global enumeration is off the table):**

| size k | # k-cliques of H |
|--------|------------------|
| 1      | 729              |
| 2      | 140,697          |
| 3      | 9,103,752        |
| 4      | 219,167,289 (essay) |
| 5,6,7  | explode further (not materialized) |

So no family can start from a global size->=4 domain (219M+). Dedicated plan
(applies to (3,3,3,4,4) and, post-correction, is the template for ALL families):
place the family's SMALLEST layers first -- **size-<=3 layers have cheap,
fully-materializable domains** (size-3 = 9.1M streamable, size-1/2 tiny),
translate-pinned to contain (0,0,0) by vertex-transitivity. Each placement
immediately restricts pentagram-adjacent neighbors to N_H(.) (<=190 vertices for
a size-3 layer), then fill the larger (size-4..7) layers by max-clique
enumeration INSIDE those small neighborhoods (never globally). Since sum-of-pairs
is tight (34 of max 35), constraints are nearly saturated and propagation should
be aggressive -- MEASURE actual per-neighborhood domain sizes on the first real
run before committing compute. Fallback: run a single family as a flat exact
max-clique / SAT decision on the 3645-vertex G with the layer-size profile as a
cardinality/structural constraint (far cheaper than the monolith, since the
layer sizes are pinned). Given claim 2, this SAT fallback may in fact be the
more honest primary tool for ALL families -- see sec 6.

## 3. Symmetry dedup

The task brief cites **Aut(G) order 140**; this looks too small and should be
recomputed (`igraph`/`nauty` on the 3645-vertex G) before any multiplicity
arithmetic is trusted -- **|Aut(H)| alone is |D9 wr S3| = 18^3 * 6 = 34,992**,
and Aut(G) for the conormal product H v C5 is at least |Aut(H)|*|Aut(C5)| =
34,992 * 10. (Where "140" comes from is unclear; do not rely on it.) Decompose
the usable reductions:
- **D5 on the 5 C5 layers** (order 10): already applied at the family level
  (26 families instead of the raw vector count). Within a family it also
  relates the choice of WHICH pentagram pair is pinned when several pairs are
  size-8 -- pick the D5-canonical pinned pair only.
- **Box symmetry** on H = C9 v C9 v C9 = D9 wr S3 (order 34,992): translation
  Z9^3 (729) x factor-permutation S3 (6) x per-factor reflection. Use the
  vertex-transitive Z9^3 to translate-pin one vertex of the anchor layer to
  (0,0,0) (as the 2-box tool pins its singleton to {(0,0)}), and S3 + reflections
  to canonicalize the rest. **CORRECTION to the naive plan:** the anchor
  (pinned) max clique does NOT collapse to O(1) representatives -- there are
  >10^8 maximum 8-cliques, so even modulo Aut(H)=34,992 there remain on the
  order of 10^3-10^4+ orbit representatives (MEASURE the exact orbit count with
  the max-clique enumerator + canonical-form dedup before scaling). This is the
  single biggest cost the corrected design must budget for.

Recompute Aut(G) (do NOT assume 140) and its subgroup action with
`igraph`/`nauty` on the 3645-vertex G at gate time before trusting any
multiplicity arithmetic.

## 4. Data structures & resumability

- **Bitsets over 729 vertices** (12 x uint64 words per H-vertex row) for
  adjacency and neighborhood intersection; N_H(S) = AND of rows of S. Layer
  cliques are 729-bit masks. This mirrors `d1_k3_maxclique.c`'s packed uint64
  bitset rows (`pack_and_write`) -- reuse that packing for G's H-block.
- **Per-family result files**: `erg003_family_<canon>.json` with fields
  {family, S, pinned_pair, status in {NO, YES}, witness (18 tuples) or null,
  wall_seconds, blocks_scanned}. A family is skippable if its result file
  exists and status != PARTIAL. Write a PARTIAL checkpoint (last block index
  scanned) every few seconds so a killed family resumes mid-scan.
- **Embarrassingly parallel** across the 26 (or 10, for S=18) families and,
  within a family, across the anchor-clique orbit representatives (thousands,
  NOT O(1) -- see sec 3) -- honor the repo compute throttle (<=3 processes while
  Paley-13 runs, else <=10).

## 5. Validation gates for the implementer

**GATE-1 (recover the 2-box known results).** The generalized tool, run with
omega(H2)=4 and S=9 on the 2-box cells, MUST reproduce
`nineCliqueViaLayersQ` / `beyond7_theorem_sweep.py`:
- omega(C7 v C7 v C5) = 9, with the known 9-clique FOUND (True);
- omega(C9 v C9 v C5) = 8 (nonagon (2,1) cell), no 9-clique (False);
- the wraparound path P7 v P7 v C5: no 9-clique (False).
Cross-check the witness against `verify_witness` in `beyond7_theorem_sweep.py`.

**GATE-2 (find the known 16-clique of the (3,1) cell).** Run the tool on
G = C9^v3 v C5 with target S = 16; it MUST find a 16-clique, and the witness
MUST decompose to a valid layer size vector with each nonempty layer an H-clique
and each pentagram-pair union an H-clique (the known construction gives
(8,8,0,0,0) with product-of-edges layers -- verified in
`erg003_structure_check.py` claim 4 -- but the tool must NOT hard-code product
structure, since non-product max cliques exist). Only after GATE-1 and GATE-2
pass should S=17 (census regression) and then S=18 (the activation decision)
run.

**GATE-3 (upper-bound sanity).** With S=19 the tool must terminate consistently
with the theta ceiling theta(comp C9)^3 * sqrt5 ~ 19.67; S=20/21 must return NO
(pentagram cap floor(5*8/2)=20, and 20 requires the doubled-catalyst C5vC5
pentad which this single-C5 cell lacks).

## 6. Revised feasibility (post claim-2 correction) -- READ BEFORE SCALING

The method council rated route (iii) "core-hours-to-core-days, embarrassingly
parallel" ON THE ASSUMPTION that each pinned pentagram pair is one of 729 rigid
product cliques. **That assumption is false** (claim 2), so that time estimate
is not supported. The corrected picture:
- the pentagram decomposition, family census, and neighborhood propagation all
  still hold -- the reduction is real and still far better than the monolith;
- BUT the per-family anchor is a max-8-clique enumeration over an object with
  >10^8 maximum cliques (thousands+ of Aut(H)-orbits), so the constant in front
  is much larger than "729".
The implementer's FIRST task is therefore an EMPIRICAL sizing pass, not a build:
1. enumerate maximum 8-cliques of H through the fixed vertex (0,0,0) (= max
   cliques of the 386-vertex N_H(0)); count them and their Aut_stab(0)-orbits;
2. for a sample of anchor cliques, forward-check how many survive to admit the
   other layers of an S=18 family (the real pruning power);
3. from (1)x(2) estimate the true search size and re-derive a credit/core-hour
   figure BEFORE committing -- and compare against just running the whole S=18
   decision as one symmetry-broken exact max-clique / cube-and-conquer SAT job
   on the 3645-vertex G, which -- now that the "cheap rigid pin" is gone -- may
   be competitive with or simpler than the per-family pipeline. Do NOT spend the
   ~3,480-credit "one hard family" budget the council quoted until (1)-(3)
   confirm the scale.

---

## Files
- `erg003_structure_check.py` -- claims (1)-(4) verifier (PASS/FAIL; claim 2
  FAILS -- exhibits the non-product max-clique counterexample).
- `erg003_pin_measure.py` -- pin-propagation & clique-domain measurements.
- `erg003_claim2.py` -- fast max-clique-through-v0 enumerator (coloring-bounded
  bitset BK); support tool for the claim-2 investigation.
- `bin/Hc9x3.bin`, `bin/mcq.exe` -- packed H adjacency + compiled MCQ solver
  (the tool that found the non-product 8-clique; `mcq.exe bin/Hc9x3.bin
  --reduce` returns omega=8 in ~1s).
- Reference (2-box, being generalized): `beyond7_theorem_sweep.py`,
  `HeptagonCatalysis.wl` ("Beyond n=7" section, `nineCliqueViaLayersQ`).
