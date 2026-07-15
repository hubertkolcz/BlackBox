(* Headless runner for the PRIMARY module: certification-protocol/mbqc_c5.wl
   (Get parses incrementally, avoiding the Global`-shadowing pitfall; see
   RunEssay.wl). This is the module that directly answers the project's own
   central research question (see certification-protocol/README.md) -- the
   MBQC-flow half of the black-box certification protocol.
   Run:  wolframscript -file RunBlackboxProtocol.wl -print all
   Unlike the other runners, mbqc_c5.wl does not end in an OK->True
   association; it prints a validation report (stabilizer deviation, gate
   teleportation check, GHZ all-versus-nothing contradiction) -- read the
   printed Summary for the pass/fail signal.

   The other half of this module, mbqc_blackbox_test.py (the full statistical
   certification protocol against classical/classical-optics impostors), is
   Python, run directly:  python3 ../certification-protocol/mbqc_blackbox_test.py *)
SetDirectory[DirectoryName[$InputFileName]];
Get["../certification-protocol/mbqc_c5.wl"]
