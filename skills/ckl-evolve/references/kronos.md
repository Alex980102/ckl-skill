# Kronos — Temporal Knowledge Evolution

Kronos is CKL's epistemological layer. It tracks how confident the engine is in any captured atom and lets knowledge mature (or decay) over time.

## The five layers

Atoms flow through five confidence layers. Each layer has a confidence range and gating criteria.

| Layer | Confidence | Meaning | Typical source |
|---|---|---|---|
| **Incoming** | new | Fresh capture, unverified | A `ckl capture` you just ran |
| **Low** | 0.0 – 0.4 | Tentative, single observation | Hypotheses, drafts |
| **Medium** | 0.4 – 0.7 | Reasonably trusted, used a few times | Working knowledge |
| **High** | 0.7 – 0.9 | Battle-tested, widely referenced | Established patterns/decisions |
| **Nucleus** | 0.9 – 1.0 | Core invariant, near-axiomatic | Architectural pillars |

Promotion is **driven by signals**, not calendar time:

- **Reuse** — how often the atom is referenced or queried
- **Corroboration** — how many independent atoms support it
- **Stability** — how rarely it is contradicted or revised
- **Explicit confirmation** — an agent or human ran `ckl observe` / `ckl resolve`

Demotion happens when contradictions accumulate or the atom goes unused for a long stretch.

## Running an evolution cycle

```bash
ckl capture --cycle
```

Run this **after** a batch of captures (typically end of session). It:

1. Recomputes confidence scores using current signals.
2. Promotes/demotes atoms across layers.
3. Surfaces candidates for resolution (duplicates, contradictions).
4. Emits a summary you can read.

Pair with `--cycle-dry-run` to preview without committing changes.

## Inspecting the layer of an atom

```bash
ckl block <id> --pretty
# or
ckl query --from-block <id> --level full --pretty
```

Output includes `kronos_layer` and `confidence` fields.

## Manual signals

You can hint Kronos directly:

```bash
ckl observe <id>            # mark as referenced/used (boosts confidence)
ckl promote <id> --to high  # explicit promotion
ckl resolve <id> --as duplicate-of <other-id>  # collapses two atoms
ckl deprecate <id>          # marks superseded
ckl archive <id>            # removes from active recall, keeps history
```

## Why layers matter for retrieval

`ckl query` ranks by:

1. Hybrid relevance (BM25 + semantic)
2. Graph centrality
3. **Kronos confidence**

A Nucleus pattern always outranks a Low-layer note for the same query, even if textual match is weaker. Use `--layer-min` to filter:

```bash
ckl query "auth flow" --layer-min medium --limit 10
```

## Keeping Kronos healthy

- **Capture regularly** — sparse capture starves the signal model.
- **Run `--cycle` at session end** — otherwise confidence drifts stale.
- **Audit periodically** — `ckl audit duplicates`, `ckl audit contradictions` (see references/commands.md).
- **Resolve don't delete** — `ckl resolve` and `ckl deprecate` preserve history; raw `rm` loses provenance.

## Reading the cycle summary

After `ckl capture --cycle` you typically see:

```
Kronos cycle complete:
  promoted:    7  (2 → Nucleus, 3 → High, 2 → Medium)
  demoted:     1
  resolved:    3  (2 duplicates, 1 contradiction)
  candidates:  4  (review with `ckl audit duplicates`)
```

Always glance at the candidates list — that is where humans add the most value.
