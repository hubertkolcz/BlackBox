# Deliberately-failing stand-in, used ONLY to test the WL-side consecutive-failure
# abort logic (never used in the real submission).
def main(maxsec):
    raise RuntimeError("intentional test failure")
