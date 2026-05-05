---
name: ckl-evolve
description: Use when the user wants to run Kronos temporal evolution (cycles, weight updates, layer transitions Incoming→Low→Medium→High→Nucleus), check entity health (nucleus ratio, coherence, tensions), audit graph quality (duplicates, contradictions, severity-graded weak decisions, atom_coverage, stale blocks), persist audit findings as Claim atoms, reconcile via LLM, seed entities, ingest blocks, or graduate session entities to shared. Activate on mentions of "cycle", "evolve", "health", "coherence", "audit", "quality", "duplicates", "contradictions", "stale", "graduate", "Kronos", "seed entity", "tensions", "weak decisions", "severity", "atom coverage", "JTB+S", or any temporal-evolution / quality request.
license: Apache-2.0
compatibility: Requires `ckl` binary >= 0.5.3 on $PATH.
metadata:
  version: 0.2.0
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
| `ckl audit --persist-findings --pretty` | v0.5.1: persist `weak_decisions` as `Claim` atoms held by `ckl-auditor` (idempotent) |
| `ckl audit --exclude-low --pretty` | v0.5.0: suppress severity-Low weak decisions (atoms missing only `REBUTTAL`) |
| `ckl audit --include-walton --pretty` | v0.5.0 placeholder for v0.6.1 Walton fallacy detection (no-op + warning) |
| `ckl audit --project prj_xxx --pretty` | Scope `atom_coverage` + JTB weak_decisions to one project |
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
| `weak_decisions` | `decision` atoms without `GROUNDS`/`SUPPORTS`, or backed but missing `WARRANT`/`REBUTTAL` (severity-graded — see below) |
| `atom_coverage` | v0.5.1: ratio of blocks with at least one Atom envelope. Healthy threshold: `0.7` |

```bash
ckl audit --pretty                                # all checks
ckl audit --duplicates --pretty
ckl audit --garbage --contradictions --pretty
ckl audit --stale --stale-days 60 --pretty
ckl audit --include-linked --pretty               # show pairs already SEE_ALSO/SUPERSEDES
ckl audit --persist-findings --pretty             # v0.5.1: store findings as Claim atoms
ckl audit --exclude-low --pretty                  # v0.5.0: drop severity=Low (no REBUTTAL only)
ckl audit --project prj_xxx --pretty              # scope atom_coverage + JTB weak_decisions
```

Full check semantics: [references/audit.md](references/audit.md).

## Severity-graded `weak_decisions` (v0.5.0)

`ckl audit` now grades each weak `decision` atom by **severity**, mapping the Toulmin gaps onto a triage scale:

| Severity | Cause | Hint |
|---|---|---|
| **High** | Missing `GROUNDS` and `SUPPORTS`, OR `holder=None` (no JTB+S source) | Claim is unbacked / unsigned. Add `ckl relate <fact> <decision> --kind GROUNDS` or capture with `--holder`. |
| **Medium** | Has grounds/support but no `WARRANT` | Argument lacks the inference rule connecting data → claim. Add `ckl relate <rule> <decision> --kind WARRANT`. |
| **Low** | Has grounds + warrant but no `REBUTTAL` | "Thin argument" — defensible but no falsification clause documented. Add `ckl relate <cond> <decision> --kind REBUTTAL`, or filter with `--exclude-low`. |

Use `--exclude-low` in CI / pre-merge audits where Low-severity findings are advisory and would otherwise dominate the report.

## `atom_coverage` (v0.5.1)

A new audit metric tracks how much of the graph carries the v0.5.0 `Atom` envelope:

```json
"atom_coverage": {
  "blocks_total": 320,
  "blocks_with_atoms": 240,
  "coverage_ratio": 0.75,
  "healthy_threshold": 0.7
}
```

Below `0.7` → most blocks are pre-v0.5.0 / lazy-upgraded but never explicitly enveloped. Remedies:

- Re-capture key decisions with explicit `--holder`/`--kind`/`--container` (see `ckl-knowledge`).
- Run `ckl distill --block <blk>` on long, mixed-content blocks to decompose them into typed atoms.
- Scope per-project with `--project prj_xxx` to find which area of the graph is undersigned.

## `WeakDecision` as a first-class `Atom` (v0.5.1)

`ckl audit --persist-findings` writes each weak decision as a `Claim` atom held by the synthetic agent **`ckl-auditor`**. Determinism is enforced via `AtomId::from_content` (idempotent — re-running with the same finding never creates a duplicate):

```bash
ckl audit --persist-findings --pretty
# Then query the persisted findings:
ckl list atoms --holder ckl-auditor --kind claim --pretty
ckl query "weak decision" --holder ckl-auditor --enriched --pretty
```

**Default is OFF** — audit stays a pure read-only operation unless you opt in. Use this flag in scheduled jobs / dashboards that need to track findings over time without re-running the audit.

## JTB+S enforcement (v0.5.0)

Audit now treats `holder=None` (atom captured without an explicit holder, no `$CKL_DEFAULT_HOLDER`, no entity-derived holder) as a **High-severity** weak decision. Reason: per JTB+S (Justified True Belief + Source), an atom without a holder is unsigned belief — semantically untrustworthy.

`ckl capture` warns to stderr when it falls back to `unsigned`:

```text
warning: capturing without a holder; atom recorded as `unsigned`. Set --holder, $CKL_DEFAULT_HOLDER, or --entity to assign a holder.
```

Cascade resolution order (first match wins):

1. Explicit `--holder <id>`
2. `$CKL_DEFAULT_HOLDER` env var
3. Entity-derived holder (from `entity.principal_holder` if seeded)
4. `unsigned` (triggers severity-High weak_decision on next audit)

## Quality gates

Targets for a healthy entity:

| Metric | Target |
|---|---|
| `unresolved` (audit findings / total) | ≤ 0.15 |
| `noisy_hubs` (over-connected nodes) | ≤ 5 |
| `non_structural` (semantic edges share) | ≥ 0.25 |
| `coherence` (entity coherence score) | ≥ 0.8 |
| `nucleus_ratio` | reported by `ckl health` |
| `atom_coverage` (v0.5.1) | ≥ 0.7 (blocks with at least one `Atom` envelope) |

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
