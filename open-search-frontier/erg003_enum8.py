"""Enumerate ALL 8-cliques of H = C9^v3 that contain vertex 0.

= all 7-cliques of the induced subgraph on N(0) (386 vertices), via the
selftest-validated coloring-bounded enumerator of erg003_pentagram_search.

By translation transitivity every 8-clique of H is a translate of one through
vertex 0, so this list (count0 of them) generates the full 8-clique inventory:
total = count0 * 729 / 8 (each 8-clique counted once per vertex).

Writes erg003_cliques8_v0.json: {count, masks(hex), nodes, wall, classes}
where classes counts edge-products vs staircase-prisms vs other.
"""
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import erg003_pentagram_search as ps
from erg003_rigidpair import products

DEADLINE = float(sys.argv[1]) if len(sys.argv) > 1 else 480.0


def main():
    N, coords, adj, FULL = ps.build_H(9, 3)
    stats = [0, time.time() + DEADLINE]
    t0 = time.time()
    masks = []
    status = "COMPLETE"
    try:
        for m in ps.enum_size_cliques(adj[0], 7, adj, stats):
            masks.append(m | 1)          # add vertex 0
            if len(masks) % 20000 == 0:
                print(f"  ... {len(masks)} found, nodes={stats[0]}, "
                      f"{time.time()-t0:.0f}s", flush=True)
    except ps.Deadline:
        status = "PARTIAL"
    wall = time.time() - t0
    print(f"[enum8] status={status} count0={len(masks)} nodes={stats[0]} "
          f"wall={wall:.1f}s", flush=True)

    # classify (only if complete and small)
    cls = {}
    if status == "COMPLETE" and len(masks) <= 2_000_000:
        prodmasks = {m for (_, m) in products(9, 3) if m & 1}
        nprod = sum(1 for m in masks if m in prodmasks)
        cls = {"products_through_0": nprod, "non_product": len(masks) - nprod}
        print(f"[enum8] products through 0: {nprod}, non-product: "
              f"{len(masks) - nprod}", flush=True)
    out = {"status": status, "count0": len(masks), "nodes": stats[0],
           "wall_seconds": round(wall, 1), "classes": cls,
           "total_8cliques_if_complete": len(masks) * 729 // 8
           if status == "COMPLETE" else None}
    with open(os.path.join(HERE, "erg003_cliques8_v0.json"), "w") as f:
        json.dump(out, f, indent=1)
    if status == "COMPLETE" and len(masks) <= 2_000_000:
        with open(os.path.join(HERE, "erg003_cliques8_v0_masks.txt"), "w") as f:
            for m in masks:
                f.write(format(m, "x") + "\n")
        print("[enum8] masks written", flush=True)


if __name__ == "__main__":
    main()
