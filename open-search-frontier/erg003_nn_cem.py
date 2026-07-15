# ERG-003: graph-specific neural policy for clique construction, trained via the
# Cross-Entropy Method (self-play: sample rollouts, imitate the elite fraction, repeat).
# Not a pretrained/generic GNN (which would likely be symmetry-blind, same failure mode
# that killed plain CDCL SAT on this graph) -- a policy trained ONLY on this one fixed,
# exactly-known graph, so there is no generalization gap, only the usual sample-efficiency
# question. Reuses the verified adjacency/bitset machinery from erg003_helper.py.
import sys, time, json
sys.path.insert(0, '.')
import numpy as np
import torch
import torch.nn as nn
import erg003_helper as H

torch.manual_seed(0)
np.random.seed(0)

N = H.N
LAYER = np.array([v[3] for v in H.verts])  # C5-layer of each vertex, 0..4


def bitlist_np(mask):
    return np.array(H.bitlist(mask), dtype=np.int64)


def features(cand_idx, clique, common_before_mask):
    """Vectorized features for each candidate v in cand_idx, given the current clique.
    12-dim: [layer onehot(5), |C|/18, |common(C+v)|/N, shrink-ratio,
             distinct-Z9-residues-per-coord(3)/9, distinct-layers/5]"""
    k = len(cand_idx)
    if k == 0:
        return np.zeros((0, 12), dtype=np.float32)
    layer_oh = np.zeros((k, 5), dtype=np.float32)
    layer_oh[np.arange(k), LAYER[cand_idx]] = 1.0
    sizeC = len(clique) / 18.0
    common_before = bin(common_before_mask).count("1")
    common_after = np.empty(k, dtype=np.float64)
    for i, v in enumerate(cand_idx):
        common_after[i] = bin(common_before_mask & H.adj[v]).count("1")
    common_after_n = (common_after / N).astype(np.float32)
    shrink = (common_after / max(common_before, 1)).astype(np.float32)
    coord_div = np.zeros((k, 3), dtype=np.float32)
    layer_div = np.zeros((k, 1), dtype=np.float32)
    if clique:
        cverts = np.array([H.verts[u] for u in clique])
        for t in range(3):
            base_set = set(cverts[:, t].tolist())
            for i, v in enumerate(cand_idx):
                s = base_set | {H.verts[v][t]}
                coord_div[i, t] = len(s) / 9.0
        base_layers = set(cverts[:, 3].tolist())
        for i, v in enumerate(cand_idx):
            layer_div[i, 0] = len(base_layers | {H.verts[v][3]}) / 5.0
    else:
        coord_div[:, :] = 1.0 / 9.0
        layer_div[:, 0] = 1.0 / 5.0
    out = np.concatenate([
        layer_oh,
        np.full((k, 1), sizeC, dtype=np.float32),
        common_after_n.reshape(-1, 1),
        shrink.reshape(-1, 1),
        coord_div,
        layer_div], axis=1)
    return out


class Scorer(nn.Module):
    def __init__(self, d=12, h=64):
        super().__init__()
        self.net = nn.Sequential(nn.Linear(d, h), nn.ReLU(), nn.Linear(h, h), nn.ReLU(), nn.Linear(h, 1))

    def forward(self, x):
        return self.net(x).squeeze(-1)


def rollout(model, start, temperature=1.0, greedy=False):
    clique = [start]
    common_mask = H.adj[start]
    trace = []  # (features, chosen_local_idx) for elite reuse
    while common_mask:
        cand = bitlist_np(common_mask)
        feat = features(cand, clique, common_mask)
        with torch.no_grad():
            scores = model(torch.from_numpy(feat)).numpy()
        if greedy:
            j = int(np.argmax(scores))
        else:
            logits = scores / max(temperature, 1e-6)
            logits -= logits.max()
            p = np.exp(logits); p /= p.sum()
            j = int(np.random.choice(len(cand), p=p))
        trace.append((feat, j))
        v = int(cand[j])
        clique.append(v)
        common_mask &= H.adj[v]
    return clique, trace


def train(generations=40, batch=160, elite_frac=0.15, temperature=1.2, lr=1e-3, log_path="erg003_nn_cem.log"):
    model = Scorer()
    opt = torch.optim.Adam(model.parameters(), lr=lr)
    best_ever = 0
    best_clique = None
    history = []

    def log(msg):
        line = f"[{time.strftime('%H:%M:%S')}] {msg}"
        print(line, flush=True)
        with open(log_path, "a") as f:
            f.write(line + "\n")

    open(log_path, "w").close()
    log(f"start: generations={generations} batch={batch} elite_frac={elite_frac} temp={temperature}")

    for gen in range(generations):
        t0 = time.time()
        starts = np.random.randint(0, N, size=batch)
        rollouts = []
        for s in starts:
            cl, tr = rollout(model, int(s), temperature=temperature)
            rollouts.append((cl, tr))
        sizes = np.array([len(cl) for cl, _ in rollouts])
        order = np.argsort(-sizes)
        n_elite = max(1, int(batch * elite_frac))
        elite_idx = order[:n_elite]

        gen_best = int(sizes.max())
        gen_best_clique = rollouts[int(order[0])][0]
        if gen_best > best_ever:
            best_ever = gen_best
            best_clique = gen_best_clique
            ok, bad = H.verify(best_clique)
            log(f"*** NEW BEST {best_ever} at gen {gen} -- independently_verified={ok} bad={bad[:2]} ***")
            if best_ever >= 18 and ok:
                json.dump({"witness": H.astuples(best_clique), "size": best_ever, "generation": gen,
                           "verified": ok}, open("erg003_nn_cem_18_witness.json", "w"), indent=1)
                log("!!!!! 18-CLIQUE CANDIDATE SAVED TO erg003_nn_cem_18_witness.json !!!!!")

        # behavior-clone on elite trajectories: cross-entropy over the candidate set at each step
        opt.zero_grad()
        total_loss = torch.tensor(0.0)
        n_terms = 0
        for i in elite_idx:
            _, tr = rollouts[i]
            for feat, chosen in tr:
                if feat.shape[0] <= 1:
                    continue
                x = torch.from_numpy(feat)
                logits = model(x)
                loss = nn.functional.cross_entropy(logits.unsqueeze(0), torch.tensor([chosen]))
                total_loss = total_loss + loss
                n_terms += 1
        if n_terms > 0:
            (total_loss / n_terms).backward()
            opt.step()

        dt = time.time() - t0
        rec = {"gen": gen, "mean_size": float(sizes.mean()), "max_size": int(sizes.max()),
               "min_size": int(sizes.min()), "n_terms": n_terms, "seconds": round(dt, 1),
               "best_ever": best_ever}
        history.append(rec)
        log(f"gen={gen:3d} mean={sizes.mean():.2f} max={sizes.max()} min={sizes.min()} "
            f"loss_terms={n_terms} best_ever={best_ever} [{dt:.1f}s]")
        json.dump({"history": history, "best_ever": best_ever,
                   "best_clique": H.astuples(best_clique) if best_clique else None},
                  open("erg003_nn_cem_progress.json", "w"), indent=1)

    log("DONE")
    return model, history, best_ever, best_clique


if __name__ == "__main__":
    train()
