# PROPOSITION-O3 (completeness): the gate set is complete relative to the intensity-emulator class (2026-07-13)

Companion to `PROPOSITION-O3.md`. That note proved two-lens **necessity** (Prop 2 / BBT-003: no table functional bounds the DLA, so the correlation and geometric lenses are irreducible). This note upgrades the map's outer boundary from *necessity* to a **class-relative completeness** statement: it fixes precisely which adversaries the assembled gate set provably handles, and states — without over-claiming — what "complete" means and where it stops. It introduces no new physics; it makes the adversary class explicit and reads off completeness from results already in the ledger (BBT-001/002, Cor 1/2) plus the single external ceiling (Kovtoniuk–Bohmann–Semenov). Labels: **[established]** = verified in-project or a cited theorem; **[new-claim]** = first stated here, proof given; **[conjecture]** = flagged open.

## The adversary class A_IE (made precise)

**Definition (intensity-emulator class).** A device D is in **A_IE** iff it is built from: **(S) source** — classical light: a Glauber–Sudarshan-classical state (P-function ≥ 0: coherent, thermal, or classical mixtures thereof); **(R) redistribution** — per-context intensity fractions freely assignable within the no-disturbance pentagon polytope, up to the exclusivity-only cap α\* = 5/2 (which strictly contains the quantum point √5 ≈ 2.236 < 5/2) [established: Prop 1 grounding; α\* = 5/2 is the KCBS fractional packing / exclusivity bound]; **(D) detection** — a single **unmodified on–off (click/no-click) detector per outcome**, fair-sampled; **(P) preparation** — fresh per trial (no sequential-within-run memory).

A_IE is exactly the class the whole `mbqc_blackbox_test.py` adversarial construction (iii-d) lives in, and exactly the class characterized by the KBS ceiling below. The four ingredients are the negations, one each, of assumptions A1–A4 of `PROPOSITION-O3.md`.

**The class ceiling [established, external].** Kovtoniuk–Bohmann–Semenov, arXiv:2601.13869 (2026): the click record of a **single unmodified on–off detector** is **coherent-state-forgeable** — for any target click statistics achievable by such a detector on a quantum state, a classical (coherent/intensity) field reproduces them, and conversely the classical forger is *exposed by its attenuation response*: under a calibrated attenuation series {η_j} the click probability of classical light + on–off detection scales in the specific (binomial/linear-in-η) way that a genuine sub-Poissonian single-photon device violates. This theorem is what makes A_IE a *closed, detectable* class: membership in A_IE ⇒ the KBS attenuation signature.

## The assembled gate set

- **C1–C5 [established, BBT-001]** — no-disturbance (C1) + contextual-fraction / Global-Exclusivity certificate: separates the untuned NCHV bound α = 2 from the quantum node-sum √5.
- **G7 [established, Cor 2]** — DLA / so(3) compilation audit: a claimed leaf-confined qutrit compilation (DLA < 3) is flagged vs the genuine KCBS cascade (DLA = 3, the "2→3" anchor). White-box trust assumption.
- **G7-CV [new-claim, this session]** — the continuous-variable analogue of G7, implemented and validated in `final_o3_cv_dla.py`: the Sp(2n,R) leaf-confinement criterion. A claimed Gaussian compilation whose dynamical Lie algebra stays inside u(n) (dim ≤ n², all generators antisymmetric) is **passive-confined** = classically emulable by linear optics; one that closes beyond u(n) toward sp(2n,R) (dim > n², a symmetric/squeezing generator appears) is **active**, not confined. Validated exactly: u(2) = 4 (confined); +two-mode squeezer → sp(4,ℝ) = 10 (active); single-mode squeezer + phase → sp(2,ℝ) = 3 (active). This fills the map's previously-unbuilt CV column (NOTES-hawking §4, §6-item-4).
- **G8 [established as spec, Cor 1 / OQ2]** — attenuation-series gate keyed on the KBS signature: the coherent/intensity forger's clicks scale binomially in η, a single-photon device's do not; the tuned emulator (iii-d) FAILS G8 while quantum boxes pass.

## Proposition O3-C (class-relative completeness) [new-claim]

*Within the intensity-emulator adversary class A_IE, the gate set G = {C1–C5, G7 (+ G7-CV for Gaussian devices), G8} is **complete** in the following exact sense: for every device D ∈ A_IE, running G terminates in one of two verdicts, and never in a false QUANTUM-CERTIFIED — every D is either*

- **(a) DISTINGUISHED** from a genuine quantum KCBS device by at least one gate, *or*
- **(b) certified NCHV-BOUNDED** (node sum α ≤ 2, non-contextual — hence not a claimant to quantum contextuality at all).

*No member of A_IE simultaneously (i) reproduces the genuine quantum contextual signature (α > 2, up to √5) and (ii) passes every gate in G. The table-only blind spot of Prop 1 is therefore the whole of A_IE's evasion power, and G closes it.*

### Proof sketch (the partition argument)

Fix D ∈ A_IE with per-context intensity fractions realizing node sum α_D on the pentagon.

**Case α_D ≤ 2.** Then D's table lies in (or on) the NCHV polytope; C1–C5 return NCHV-bounded — verdict (b). D is not even claiming contextuality; nothing to forge. *(Rigorous: it is the definition of the NCHV cap α = 2, Markiewicz et al., npj QI 5, 5 (2019).)*

**Case α_D > 2.** To exceed the NCHV bound with **fresh-per-trial** preparation and **single-event** semantics is impossible (α = 2 is exactly the deterministic-assignment ceiling). So D can only reach α_D > 2 by exploiting the **intensity-vs-single-click semantics gap** — i.e. reporting normalized intensity fractions (which range up to α\* = 5/2) as if they were single-click probabilities. This is the one and only mechanism by which A_IE reaches the quantum regime (Prop 1). But that mechanism is precisely **source (S) + detection (D)** of A_IE: classical light on a single unmodified on–off detector. By the KBS ceiling, D therefore carries the attenuation signature, and **G8 flags it** — verdict (a). *(This step is rigorous GIVEN the KBS theorem and the detector model; see "what is assumed" below.)*

**The dynamics/compilation flank.** Cases above use the correlation + semantics lenses. Independently, whatever compilation D *claims*, G7 (finite-dim so(3): DLA < 3 ⇒ leaf-confined) or **G7-CV** (Gaussian: DLA ⊆ u(n) ⇒ passive-confined) audits it; a genuinely intensity-redistributing / passive-linear rig is leaf-/passive-confined and flagged — verdict (a) — with **no access upgrade**, at the cost of the white-box trust assumption. This flank is what makes the result robust to an adversary who declines the attenuation test: the compilation audit still separates it.

Since α_D ≤ 2 and α_D > 2 exhaust the cases, every D ∈ A_IE lands in (a) or (b). ∎ (sketch)

### What is rigorous vs what is assumed

- **Rigorous (in-project or elementary):** the exclusivity cap α\* = 5/2 and the NCHV cap α = 2; the case partition; Prop 1's construction that intensity fractions are the *only* A_IE route above α = 2; the Cor 1 collapse to α = 2 under enforced single-event semantics; the G7-CV Sp(2n,ℝ)/u(n) dimension criterion (`final_o3_cv_dla.py`, exact-arithmetic, all anchors pass).
- **Assumed (the single load-bearing physics premise):** the **KBS detector model** — that *every* device in A_IE (classical light + one unmodified on–off detector per outcome, fair-sampled) exhibits the attenuation signature G8 keys on, and that G8's pre-registered thresholds have power to detect it at the tested visibilities. Completeness is **exactly as strong as this premise.** If the adversary is permitted to leave the detector model — photon-number-resolving detectors, heralding/photon-subtraction, engineered non-fair-sampling, or a genuine Fock source it merely *calls* classical — it exits A_IE and Prop O3-C says nothing about it.
- **White-box (G7/G7-CV only):** the compilation audits certify the *claimed* dynamics, not the *actual* dynamics (Cor 2 trust assumption, unchanged; the CV analogue inherits it verbatim — `final_o3_cv_dla.py` docstring, "TRUST ASSUMPTION").

## What this does and does not settle

- **Does [new-claim]:** turns the map's outer boundary from a *two-lens necessity* statement into a *completeness-relative-to-A_IE* statement. Inside A_IE, the assembled gate set is provably exhaustive: the Prop-1 blind spot is the class's *entire* evasion capacity, and G8 (semantics) + G7/G7-CV (dynamics) close it. This is the strongest O3 answer available without new physics.
- **Does not [conjecture — the honest open cell]:** it is **not** an absolute completeness theorem. Whether A_IE is the *maximal* classically-emulable class — i.e. whether some adversary **outside** A_IE (PNR detection, heralded Fock sources, non-fair-sampling) can survive G8 **and** G7/G7-CV while still counting as "classical emulation" in a meaningful sense — is **open** (this is the SQ1 cell of `certification_map.wl`, now sharpened to: *does a super-class of A_IE survive the full gate set?*). Prop O3-C converts that vague "outer boundary" cell into a precise, delegation-ready question.

## Ledger actions

`BBT-002`: cross-reference Prop O3-C as the completeness companion to Prop 1's blind-spot. New candidate `BBT-004` [type NOVEL]: "class-relative completeness of {C1–C5, G7, G7-CV, G8} over the intensity-emulator class A_IE; complete = every device distinguished or NCHV-bounded; load-bearing assumption = KBS single-detector coherent-forgeability + fair-sampling detector model." New candidate `BBT-005` [type NOVEL]: the Sp(2n,ℝ) leaf-confinement criterion and its exact validation (`final_o3_cv_dla.py`), the CV analogue of the G7 so(3) audit — fills the certification map's CV column. Register the sharpened open cell (super-class of A_IE) as the successor to SQ1.
