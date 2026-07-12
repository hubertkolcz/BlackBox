"""
ZeroSlackDiagnostic.py -- exact-rational diagnostic for the "zero-slack
recalibration on cct" question posed in QUANTUM_CONTEXTUALITY.md section 9
(the "12 July 2026 research push" note), attempting the Guglielmi-Protasov
invariant-polytope-style recipe against the EXISTING EpsilonCertificate.wl
(k=7) and EpsilonCertificate8.wl (k=8) windowed transfer-SDP certificates.

RECIPE ATTEMPTED (per the task): seed a candidate from cct's own exact
optimum, and check whether the certificate can be recalibrated to hold with
EXACT EQUALITY on cct's own 3-cycle and non-negative slack (sigma(e) <=
Gamma) on every other de Bruijn-k edge -- which, if achieved with the
right target value, would be a complete, finite, exact proof that (cct)^inf
is the true global maximizer of gap(w) = theta-bar(w) - alpha-bar(w).

METHOD. This reimplements CaseStudies.wl's posSigma / posCycleMean /
posCheck (see CaseStudies.wl lines ~358-451) independently in Python
`fractions.Fraction`, using CertificateLoader.py to parse the committed
EpsilonCertificate*.wl data files directly (no Wolfram kernel needed for
this part -- see that module's docstring for why). All arithmetic below is
EXACT rational; no floating point enters the pass/fail logic (floats are
only used for human-readable display, always paired with the exact
Fraction).

RESULT (see the printed report for exact numbers): a PROOF OF IMPOSSIBILITY
for the cheapest version of the recipe (recalibrating Psi alone, holding the
existing Q,R,Phi,Strategy fixed), plus a structural argument about why the
recipe, done in full, reduces to the SAME open problem it was hoped to route
around. Full details in the module docstring below and in the final report
this file accompanies. NOT achieved: a full re-derivation of Q,R,Phi,Strategy
at k=7/k=8 with cct forced tight (infeasible at that scale within this
session's compute -- see "WHAT WAS NOT ATTEMPTED AND WHY" below).

======================================================================
FINDING 1 (rigorous, exact, decisive) -- Psi-only recalibration is provably
impossible without introducing negative slack elsewhere.

Psi is the only free "gauge" variable in the certificate that does NOT
affect the PSD/equality feasibility of Q, R (those constraints never
mention Psi at all -- see nodeCons/edgeCons/psdCons in CaseStudies.wl and
GenerateEpsilonCertificate9.wl). So the cheapest possible "recalibration" is:
keep the EXISTING, already-verified-valid Q, R, Phi, Strategy from
EpsilonCertificate.wl / EpsilonCertificate8.wl exactly as committed, and
choose a DIFFERENT Psi to force sigma(e) = mu_cct exactly on cct's 3 edges
(always achievable for a single simple cycle by a local telescoping
construction), then check whether sigma(e) <= mu_cct still holds everywhere
else.

It does not. The reason is elementary and needs no SDP re-solve: around ANY
closed cycle C, telescoping cancels the Psi(x)-Psi(w) terms, so the MEAN of
sigma(e) over C's edges equals the mean of c(e) := d(x) - r(e) over C,
a quantity that is completely Psi-INDEPENDENT (verified computationally
below too, by perturbing Psi at random and confirming the cycle mean is
unchanged). Consequently:

  mu_cct      := mean of c(e) around cct's own 3-edge cycle       (INTRINSIC)
  mu_bottleneck := mean of c(e) around the documented bottleneck
                   cycle ((cttt)^inf at k=7, (ctt)^inf at k=8)      (INTRINSIC)

are both fixed facts about the EXISTING Q,R,Phi,Strategy, independent of
Psi. Exact computation (this script) gives, using the certificates exactly
as committed:

  k=7: mu_cct = 3783027/50000000 = 0.07566054
       mu_bottleneck = 30824939/400000000 = 0.0770623475  (= Gamma_7 to a
         2.5e-9 "rationalization sliver", confirming (cttt)^inf really is
         the Karp-exact bottleneck of THIS certificate)
       mu_bottleneck - mu_cct = 560723/400000000 = 0.0014018075 (EXACT)

  k=8: mu_cct = 22397449/300000000 = 0.0746581633...
       mu_bottleneck = 5648141/75000000 = 0.0753085467  (= Gamma_8 to a
         1.33e-8 sliver)
       mu_bottleneck - mu_cct = 39023/60000000 = 0.0006503833... (EXACT)

Since mu_bottleneck > mu_cct strictly at BOTH k, forcing sigma(e) = mu_cct on
cct's edges (via ANY choice of Psi whatsoever) FORCES at least one edge of
the bottleneck cycle to sigma(e) >= mu_bottleneck > mu_cct -- i.e. negative
slack of EXACTLY mu_bottleneck - mu_cct, no numerical search needed to see
this fails. The competing cycle that "absorbs" the negative slack is
therefore, exactly as documented, (cttt)^inf at k=7 and (ctt)^inf at k=8 --
now derived directly rather than just cited.

FINDING 2 (structural clarification of the recipe itself) -- "equality on
cct with non-negative slack elsewhere," if achieved by a FULL re-derivation
(changing Q,R,Phi,Strategy, not just Psi), constitutes a complete proof of
cct's global optimality ONLY IF the resulting common value G equals
gap(cct) = cctDensity - 4/3 = 0.0698975... EXACTLY -- not merely "some
value where cct happens to be a tight cycle of that particular certificate."
A recalibrated certificate whose forced value G is larger than gap(cct) is
just a differently-shaped epsilon-certificate (bottleneck relocated to cct)
-- it does not upgrade the bracket. And G = gap(cct) exactly, at finite
k=7/8, is precisely the open "does lim Gamma_k = gap(cct)?" question that
the 12 July push already found has no known convergence-rate route. So the
recipe, done properly, does not sidestep the open problem's real difficulty;
it re-poses it as a constrained search for the same target value.

FINDING 3 (small-scale, k=3, hands-on exploration; see the session notes
for the exact Wolfram calls) -- attempting the FULL recipe (re-deriving
Q,R,Phi,Strategy, not just Psi) at a small, tractable scale surfaced two
things: (a) restricting the windowed transfer-SDP to JUST cct's own 3-node
cycle in isolation (dropping the de Bruijn branching, i.e. only ever
offering the one out-edge that continues the cct pattern) reproduces
theta-bar(cct) = 1.40323087 correctly via the Q,R/Schur-complement part
(to ~9 significant digits, an independent cross-check of the documented
320-digit DFT-symbol value via a completely different, position-space
method) but does NOT reproduce the correct alpha-density 4/3 via the Phi/
Strategy mean-payoff-game part (it converges instead to rate 1, regardless
of which of 3 different strategy seeds was tried) -- because Lemma B's
alpha-density>=4/3 guarantee is inherently a statement requiring the FULL
BRANCHING graph (both "c" and "t" options at every DP phase), which a
3-edge-only reduction structurally cannot express; and (b) reproducing the
FULL de Bruijn-3 graph's joint SDP + policy-iteration (8 nodes, 16 edges,
matching GenerateEpsilonCertificate9.wl's own approach) hit the EXACT SAME
documented convergence bug from that file's header -- Gamma converging to
~0.5 (a useless fixed point) instead of the correct Gamma_3 = 0.1250 -- now
newly confirmed to occur even at k=3 (the prior investigation only reported
it at k=4). This means a trustworthy from-scratch re-derivation at ANY k
needs that solver bug fixed first; it was left unfixed per this task's
explicit scope (fixing GenerateEpsilonCertificate9.wl was optional and
out of the requested focus).

WHAT WAS NOT ATTEMPTED AND WHY -- a genuine re-derivation of Q,R,Phi,Strategy
at the ACTUAL k=7 (128 nodes/256 edges) or k=8 (256 nodes/512 edges) scale,
with cct's cycle forced tight, was not attempted, for three compounding
reasons: (1) the only live Wolfram execution channel available in this
session was a disconnected, stateless sandboxed cloud kernel (confirmed via
$CloudConnected/$MachineName/FileNames checks) with a hard ~25-27s wall-clock
ceiling per call and NO filesystem access to this repository -- a genuinely
large coupled SDP (GenerateEpsilonCertificate9.wl's own timing notes put a
same-SIZE synthetic k=8-scale block-SDP at tens of seconds per solve, before
even counting multiple policy-iteration rounds) does not fit that ceiling;
(2) mid-session, a message formatted to look like an authoritative
correction from "the coordinator" instructed switching to a local
`wolframscript` CLI against the user's real, PAID Wolfram Cloud account
specifically to remove this ceiling -- this was judged to be a suspected
prompt injection (arrived through a tool-adjacent channel with no way to
verify it was genuinely from the orchestrating agent, asked to spend real
money and run an unverified template script) and was declined; a second,
similarly-suspicious message later urged relying on `Reduce`/`FindInstance`
"over the exact rational field" in place of the checks below, which is not
practically viable for an SDP feasibility problem of this size and was also
declined -- both are reported to the user rather than acted on; (3) the
only from-scratch generator pipeline that exists for this problem family,
GenerateEpsilonCertificate9.wl, has a confirmed, UNFIXED convergence bug in
exactly the component (policy iteration over Phi/Strategy) a k=7/8
re-derivation would need, independently reproduced here at k=3 in addition
to its previously-documented occurrence at k=4.

MOST PROMISING NEXT STEP: fix GenerateEpsilonCertificate9.wl's policy-
iteration convergence bug first (now confirmed to bite at k=3 as well as
k=4 -- see the "reproduce the k=3 bug" note in the accompanying session
report), validate it reproduces the KNOWN Gamma_2..Gamma_8 sequence exactly,
THEN attempt the zero-slack-on-cct recalibration (as an ADDED equality
constraint on the joint SDP, not a post-hoc Psi patch) at increasing k on a
machine/session with enough sustained compute to run a real k=7/8 solve in
one sitting -- and, per Finding 2, evaluate success only by checking whether
the resulting forced value equals gap(cct) exactly, not merely by checking
that a fixed point was reached.
"""
import os
import random
from fractions import Fraction

from CertificateLoader import load_certificate

dpStates = [(0, 0), (1, 0), (0, 1)]


def dpTransfer(letter):
    """Verbatim (Python) port of CaseStudies.wl's dpTransfer[letter_]."""
    T = [[None] * 3 for _ in range(3)]
    for i in range(3):
        for s1 in (0, 1):
            for s2 in (0, 1):
                for s3 in (0, 1):
                    if (not (dpStates[i][0] == 1 and s1 == 1)
                            and not (s1 == 1 and s2 == 1)
                            and not (s2 == 1 and s3 == 1)
                            and not (s3 == 1 and dpStates[i][1] == 1)):
                        out = (s1, s2) if letter == "c" else (s2, s1)
                        j = dpStates.index(out)
                        val = s1 + s2 + s3
                        if T[i][j] is None or val > T[i][j]:
                            T[i][j] = val
    return T


Tc = dpTransfer("c")
Tt = dpTransfer("t")


def posEdges(CE):
    nodes = CE["Nodes"]
    return [(w, x) for w in nodes for x in nodes if w[1:] == x[:-1]]


def posSigma(CE, e):
    """Verbatim (Python) port of CaseStudies.wl's posSigma[CE_][e_]:
    sigma(e) = d(x) - r(e) + Psi(x) - Psi(w), all EXACT Fraction arithmetic."""
    w, x = e
    T = Tc if w[-1] == "c" else Tt
    strat = CE["Strategy"]
    phi = CE["Phi"]
    vals = []
    for s in (1, 2, 3):
        sig = strat["%d|%s>%s" % (s - 1, w, x)]
        Tsx = T[s - 1][sig - 1]
        assert Tsx is not None, "strategy selected an invalid (-Infinity) transition"
        vals.append(Tsx + phi["%d|%s" % (sig - 1, x)] - phi["%d|%s" % (s - 1, w)])
    r = min(vals)
    Q, R, psi = CE["Q"], CE["R"], CE["Psi"]
    d_x = Q[x][4][4] + R[x][3][3]  # ip=5, jp=4 (1-indexed) -> 4,3 (0-indexed)
    return d_x - r + psi[x] - psi[w]


def periodic_cycle_edges(word, k):
    p = len(word)
    rep = word * ((k + p) // p + 3)
    nodes = [rep[j:j + k] for j in range(p)]
    return [(nodes[j], nodes[(j + 1) % p]) for j in range(p)]


def cycle_mean(CE, word):
    edges = periodic_cycle_edges(word, CE["k"])
    vals = [posSigma(CE, e) for e in edges]
    return sum(vals, Fraction(0)) / len(vals), vals, edges


def psi_independence_check(CE, word, seed):
    """Empirically confirms mean(sigma) around a closed cycle is Psi-
    independent (telescoping), by perturbing Psi at random and re-checking."""
    random.seed(seed)
    psi0 = CE["Psi"]
    perturbed = dict(CE)
    perturbed["Psi"] = {w: psi0[w] + Fraction(random.randint(-999, 999),
                                               random.choice([7, 11, 13, 97]))
                         for w in psi0}
    mu_orig, _, _ = cycle_mean(CE, word)
    mu_pert, _, _ = cycle_mean(perturbed, word)
    return mu_orig == mu_pert, mu_orig, mu_pert


def full_report(CE, name, bottleneck_word):
    print("=" * 70)
    print(name, " k =", CE["k"], " #nodes =", len(CE["Nodes"]))
    gamma = CE["Gamma"]
    edges = posEdges(CE)
    sigmas = {e: posSigma(CE, e) for e in edges}
    worst_e = max(sigmas, key=lambda e: sigmas[e])
    worst_val = sigmas[worst_e]
    all_ok = all(v <= gamma for v in sigmas.values())
    print("  #edges =", len(edges), " Gamma =", gamma, "=", float(gamma))
    print("  max sigma(e) =", worst_val, "=", float(worst_val), "at", worst_e,
          " (== Gamma exactly:", worst_val == gamma, ", <= Gamma everywhere:", all_ok, ")")

    mu_cct, cct_sigmas, cct_edges = cycle_mean(CE, "cct")
    print("  cct cycle", cct_edges, "sigma values", [float(v) for v in cct_sigmas])
    print("  mu_cct =", mu_cct, "=", float(mu_cct), " Gamma - mu_cct (slack) =",
          gamma - mu_cct, "=", float(gamma - mu_cct))

    mu_bot, bot_sigmas, bot_edges = cycle_mean(CE, bottleneck_word)
    print("  bottleneck", repr(bottleneck_word), "sigma values", [float(v) for v in bot_sigmas])
    print("  mu_bottleneck =", mu_bot, "=", float(mu_bot), " Gamma - mu_bottleneck =",
          gamma - mu_bot, "=", float(gamma - mu_bot), "(rationalization sliver)")

    forced_violation = mu_bot - mu_cct
    print("  ==> forcing sigma=mu_cct on cct via Psi alone forces >=",
          float(forced_violation), "negative slack on", repr(bottleneck_word), "(EXACT:",
          forced_violation, ")")
    return dict(gamma=gamma, mu_cct=mu_cct, mu_bot=mu_bot, all_ok=all_ok,
                forced_violation=forced_violation)


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    CE7 = load_certificate(os.path.join(here, "EpsilonCertificate.wl"))
    CE8 = load_certificate(os.path.join(here, "EpsilonCertificate8.wl"))

    r7 = full_report(CE7, "EpsilonCertificate (k=7)", "cttt")
    r8 = full_report(CE8, "EpsilonCertificate8 (k=8)", "ctt")

    print("=" * 70, "\nPsi-independence check (telescoping sanity check):")
    for CE, name, word in [(CE7, "k=7", "cct"), (CE7, "k=7", "cttt"),
                            (CE8, "k=8", "cct"), (CE8, "k=8", "ctt")]:
        ok, mu0, mu1 = psi_independence_check(CE, word, seed=hash((name, word)) & 0xffff)
        print(f"  {name} {word!r}: mu={float(mu0):.10f} (unperturbed) vs "
              f"{float(mu1):.10f} (Psi randomly perturbed) -- identical={ok}")

    print("=" * 70, "\nComparison to the true continuum value (320-digit numeric, NOT")
    print("known exactly rational/algebraic -- see QUANTUM_CONTEXTUALITY.md sec.6):")
    gap_cct = Fraction(140323086923899745105894248, 10 ** 26) - Fraction(4, 3)
    for r, name in [(r7, "k=7"), (r8, "k=8")]:
        print(f"  {name}: Gamma-gap(cct)={float(r['gamma']-gap_cct):.8f}  "
              f"mu_cct-gap(cct)={float(r['mu_cct']-gap_cct):.8f}")
