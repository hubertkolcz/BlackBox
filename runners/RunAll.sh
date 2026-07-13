#!/usr/bin/env bash
# One-command verification of the whole repository (POSIX).
#   bash runners/RunAll.sh
# Mirrors RunAll.ps1. Set WOLFRAMSCRIPT to override the binary.
set -u
WS="${WOLFRAMSCRIPT:-wolframscript}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO="$(dirname "$ROOT")"
ALL=0

# Environment capture (auditable verification log)
echo "== RunAll.sh $(date -u +%Y-%m-%dT%H:%M:%SZ) =="
"$WS" -code 'Print["WolframVersion: ", $Version]' 2>/dev/null || { echo "wolframscript not found (set WOLFRAMSCRIPT)"; exit 1; }

# Test battery: plain -file from its own directory (prints its own markers)
out="$(cd "$REPO/BlackBox/Tests" && "$WS" -file BlackBoxTests.wl 2>&1)"
if echo "$out" | grep -q "ALL PASS: True" && echo "$out" | grep -q "DEDUP PASS: True" && echo "$out" | grep -q "UNIFY PASS: True"; then
  printf '%-34s %s\n' "BlackBox/Tests/BlackBoxTests.wl" "OK"
else
  printf '%-34s %s\n' "BlackBox/Tests/BlackBoxTests.wl" "FAILED"; ALL=1
fi

# Note runners: -print all; each must end OK -> True
for f in RunBlackboxProtocol.wl RunEssay.wl RunCaseStudies.wl RunHeptagonCatalysis.wl \
         RunBiphotonSimulator.wl RunWignerFlow.wl RunLedger.wl RunEpilogue.wl \
         RunSupportCohomology.wl RunSignedNegativity.wl RunD1GECopiesSweep.wl \
         RunD1K3Activation.wl RunSignalingTaxonomy.wl; do
  out="$(cd "$ROOT" && "$WS" -file "$f" -print all 2>&1)"
  if [ "$f" = "RunBlackboxProtocol.wl" ]; then
    # Prints a validation report, not OK -> True; surface its Summary line.
    summary="$(echo "$out" | grep -i "Summary" | head -1)"
    printf '%-34s %s\n' "$f" "${summary:-NO SUMMARY LINE (inspect output)}"
    echo "$out" | grep -qi "Summary" || ALL=1
  else
    if echo "$out" | grep -q "OK -> True"; then
      printf '%-34s %s\n' "$f" "OK"
    else
      printf '%-34s %s\n' "$f" "FAILED"; ALL=1
    fi
  fi
done

[ "$ALL" -eq 0 ] && echo "== ALL RUNNERS OK ==" || echo "== FAILURES PRESENT =="
exit $ALL
