---
name: ckl-evolve
description: Use when the user wants to run Kronos temporal evolution (cycles, weight updates, layer transitions Incoming→Low→Medium→High→Nucleus), check entity health (nucleus ratio, coherence, tensions), audit graph quality (duplicates, contradictions, weak decisions, stale blocks), reconcile via LLM, seed entities, ingest blocks, or graduate session entities to shared. Activate on mentions of "cycle", "evolve", "health", "coherence", "audit", "quality", "duplicates", "contradictions", "stale", "graduate", "Kronos", "seed entity", "tensions", or any temporal-evolution / quality request.
license: Apache-2.0
compatibility: Requires `ckl` binary >= 0.4.9 on $PATH.
metadata:
  version: 0.1.0
  upstream: https://github.com/koslab/ckl
  composes-with: ckl-knowledge
  prerequisite: ckl-system
  primary-commands: cycle, health, seed, history, ingest, backfill, backfill-part-of, graduate, audit, reconcile, reconcile-status, reconcile-cancel, reconcile-history, reconcile-queue, clean
---

# CKL Evolve

Temporal evolution and quality control for the knowledge graph. Atoms move through 5 Kronos layers (Incoming → Low → Medium → High → Nucleus); `ckl audit` detects garbage, duplicates, contradictions, weak decisions; `ckl reconcile` resolves them via LLM.

**Binary:** `ckl` on `$PATH`.

## Quick Reference

| Command | Purpose |
|---|---|
| `ckl seed --entity <id> --name "..."` | Create entity + Slice₀ (do this once before capture/cycle) |
| `ckl ingest --entity <id> --block <blk> --weight <w>` | Add an existing block to entity's temporal state |
| `ckl ingest ... --direct` | Authoritative ingest (starts at Medium layer, skips gradual channel) |
| `ckl cycle --entity <id> --trigger "..."` | 7-phase evolution cycle (weight deltas, tensions, proposals) |
| `ckl health --entity <id> --pretty` | Nucleus ratio, coherence, tensions |
| `ckl history --entity <id> --atom blk_xxx` | Weight history per atom |
| `ckl backfill --entity <id>` | Pull existing knowledge into Kronos |
| `ckl backfill-part-of` | Backfill `PART_OF` edges for composite assets |
| `ckl graduate --from <session_e> --to <shared_e>` | Promote mature atoms session → shared |
| `ckl audit --pretty` | All quality checks (read-only, no LLM) |
| `ckl reconcile --duplicates` | LLM-driven resolution of dupes/contradictions |
| `ckl clean --garbage --confirm` | Remove flagged artifacts |

Deep dives: [references/kronos.md](references/kronos.md), [references/audit.md](references/audit.md), [references/quality-gates.md](references/quality-gates.md).

## Kronos — 5 layers

```
Incoming → Low → Medium → High → Nucleus
```

- **Incoming**: just-captured atoms (gradual channel default).
- **Low / Medium**: weight accumulating from cycles, references, promotion.
- **High / Nucleus**: stable, high-confidence anchors (search prioritizes these).

Atoms reach higher layers via `ckl cycle` (recurring evolution) and `ckl promote` (manual boost). Atoms decay via `ckl archive` (Dormant, reversible) or `ckl deprecate` (frozen at 0, irreversible).

## Lifecycle commands

```bash
# 1. Create the entity (once)
ckl seed --entity entity_ckl --name "CKL Engine" --pretty

# 2. Capture knowledge (see ckl-knowledge skill)
ckl capture --title "..." --content "..." --type decision --entity entity_ckl --cycle

# 3. Manually ingest an existing block
ckl ingest --entity entity_ckl --block blk_xxx --weight 0.5 --pretty

# 4. Run the evolution cycle
ckl cycle --entity entity_ckl --trigger "session_end" --pretty

# 5. Check health
ckl health --entity entity_ckl --pretty

# 6. Inspect a single atom's weight history
ckl history --entity entity_ckl --atom blk_xxx --pretty

# 7. Pull existing knowledge into Kronos
ckl backfill --entity entity_ckl --pretty

# 8. Graduate mature session atoms to a shared entity
ckl graduate --from session_entity --to shared_entity --pretty
```

## Audit & Quality

`ckl audit --pretty` runs read-only, algorithmic checks (no LLM). Run regularly between captures.

| Check | Detects |
|---|---|
| `garbage` | Low-token test artifacts (< 15 tokens, `Write: test_*` names) |
| `duplicates` | Semantically similar block pairs |
| `contradictions` | Negation patterns + topic overlap |
| `stale` | Blocks not accessed in N days (`--stale-days 30` default) |
| `weak_decisions` | `decision` atoms without `GROUNDS`/`SUPPORTS`, or backed but missing `WARRANT`/`REBUTTAL` |

```bash
ckl audit --pretty                                # all checks
ckl audit --duplicates --pretty
ckl audit --garbage --contradictions --pretty
ckl audit --stale --stale-days 60 --pretty
ckl audit --include-linked --pretty               # show pairs already SEE_ALSO/SUPERSEDES
```

Full check semantics: [references/audit.md](references/audit.md).

## Quality gates

Targets for a healthy entity:

| Metric | Target |
|---|---|
| `unresolved` (audit findings / total) | ≤ 0.15 |
| `noisy_hubs` (over-connected nodes) | ≤ 5 |
| `non_structural` (semantic edges share) | ≥ 0.25 |
| `coherence` (entity coherence score) | ≥ 0.8 |
| `nucleus_ratio` | reported by `ckl health` |

Full gate definitions: [references/quality-gates.md](references/quality-gates.md).

## Reconcile (LLM-driven)

```bash
ckl reconcile --duplicates --pretty           # merge dupes flagged by audit
ckl reconcile --contradictions --pretty       # resolve via LLM reasoner
```

`reconcile-status` / `reconcile-cancel` / `reconcile-history` / `reconcile-queue` are deferred to CKL-32.

## Clean

```bash
ckl clean --garbage --confirm --pretty
ckl clean --duplicates --confirm --pretty
```

Always pass `--confirm` for destructive cleans.

## Composes with

This skill is one of five `ckl` skills. Use it together with:

- **`ckl-system`** — prerequisite: ckl installed and project indexed
- **`ckl-knowledge`** — capture creates atoms that this skill evolves; `--cycle` flag on capture invokes this skill's `cycle`
- **`ckl-search`** — `audit` results often refer to blocks you'll want to `ckl block`/`ckl context` (in `ckl-search`)
- **`ckl-edit`** — after major edits, run `ckl cycle` so changes propagate through layers

## Gotchas

1. Run `ckl seed` **once** per entity before any capture/cycle. Capturing without seed orphans atoms.
2. `ckl deprecate` is irreversible. Use `ckl archive` (reversible) unless you are certain.
3. `det_hash` uses SHA-256 via `ckl_index::content_hash`, not Rust's `DefaultHasher`. Custom hashing breaks dedup.
4. `cargo test --workspace --exclude ckl-config` — ckl-config tests are environment-dependent and may fail in CI.
5. After many captures, run `ckl cycle` once at the end — batch evolution is cheaper than per-atom cycles.
6. Quality gates are advisory, not hard limits. Monitor with `ckl health` after each session.
