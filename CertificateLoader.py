"""
CertificateLoader.py -- a Wolfram-free, exact-rational reader for
EpsilonCertificate.wl (k=7) and EpsilonCertificate8.wl (k=8).

Context / provenance (12 July 2026): these two files are single-line WL
`Export[..., InputForm, "Text"]` dumps of an association with keys "k",
"Gamma", "Nodes", "Q", "R", "Psi", "Phi", "Strategy" (see CaseStudies.wl,
the epsilonCertificateCheck / posSigma / posCycleMean cell around lines
358-451, for the WL-side reader/verifier this mirrors). They hold no floats,
no `Infinity`, no `Rational[...]` wrapper -- only plain integers, `a/b`
fractions, strings and nested `{...}` lists / `<|...|>` associations -- so
they can be parsed into native Python `fractions.Fraction` data with a small,
safe, non-`eval`-of-arbitrary-code transform (WL `{}` = list -> Python `[]`;
WL `<||>` = association -> Python `{}`; `a/b` -> `Fraction(a,b)`).

This exists because, in the session that produced it, the available Wolfram
Language execution channel was a disconnected sandboxed cloud kernel with NO
filesystem access to this repository and a hard ~25s wall-clock ceiling per
call -- so certificate data could not be `Get[]` directly by a live WL
kernel. Re-implementing the reader in pure Python (stdlib only, exact
`Fraction` arithmetic, no solver, no numerical tolerance anywhere) sidesteps
that limitation entirely and gives a portable way to re-verify or interrogate
these certificates without any Wolfram license or network access at all.

Usage:
    from CertificateLoader import load_certificate
    CE8 = load_certificate("EpsilonCertificate8.wl")
    CE8["Gamma"]        # -> Fraction(941357, 12500000)
    CE8["Q"]["cccccccc"]  # -> 5x5 nested list of Fractions
"""
import re
from fractions import Fraction


def load_certificate(path):
    """Parse a WL `<|...|>` association dump (as produced by
    Export[file, ToString[assoc, InputForm], "Text"]) into a Python dict of
    Fraction/int/str/list/dict, preserving EXACT rational values throughout."""
    data = open(path, encoding="utf-8").read()
    start = data.find("<|")
    end = data.rfind("|>") + 2
    if start < 0 or end < 2:
        raise ValueError("no <| ... |> association found in %r" % path)
    body = data[start:end]

    # WL uses {..} for LISTS and <|..|> for ASSOCIATIONS -- both must map to
    # DIFFERENT Python brackets ([..] vs {..}), so protect <|/|> first, turn
    # all remaining {}/{} into Python list brackets, then restore associations.
    body = body.replace("<|", "\x01").replace("|>", "\x02")
    body = body.replace("{", "[").replace("}", "]")
    body = body.replace("\x01", "{").replace("\x02", "}")
    body = body.replace("->", ":")
    # wrap fractions a/b (optionally signed) as Fraction(a,b); plain integers
    # and quoted strings are already valid Python literals unchanged.
    body = re.sub(r"(-?\d+)/(\d+)", r"Fraction(\1,\2)", body)

    ns = {"Fraction": Fraction}
    return eval(body, {"__builtins__": {}}, ns)


if __name__ == "__main__":
    import os
    here = os.path.dirname(os.path.abspath(__file__))
    CE7 = load_certificate(os.path.join(here, "EpsilonCertificate.wl"))
    CE8 = load_certificate(os.path.join(here, "EpsilonCertificate8.wl"))
    print("EpsilonCertificate  (k=7): Gamma =", CE7["Gamma"], "=", float(CE7["Gamma"]),
          " nodes =", len(CE7["Nodes"]))
    print("EpsilonCertificate8 (k=8): Gamma =", CE8["Gamma"], "=", float(CE8["Gamma"]),
          " nodes =", len(CE8["Nodes"]))
