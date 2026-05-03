# Argument relations — Toulmin model + structural edges

Six argument-edge kinds turn `decision` atoms into traceable claims. `ckl audit` flags `decision` atoms that lack backing or warrant.

## Table of contents

- [Toulmin edges](#toulmin-edges)
- [Structural edges](#structural-edges)
- [How to apply](#how-to-apply)
- [Auditability](#auditability)
- [Examples](#examples)

## Toulmin edges

Stephen Toulmin's argument model decomposes a claim into:

```
Claim ← Grounds (data) ← Warrant (rule) ← Backing
            ↑
        Rebuttal (when does it fail?)
```

CIP exposes 6 argument edges that correspond:

| Kind | Meaning | Toulmin role |
|---|---|---|
| `SUPPORTS` | Fact / pattern / rule provides positive evidence | Backing |
| `OPPOSES` | Contrary evidence | counter-Backing |
| `ALTERNATIVE_TO` | Option considered but not chosen (target = winning decision) | Alternative claim |
| `GROUNDS` | Data the claim rests on | Grounds |
| `WARRANT` | Rule connecting grounds → claim | Warrant |
| `REBUTTAL` | Condition that would invalidate the claim | Rebuttal |

A well-argued `decision` has:
- ≥ 1 `GROUNDS` edge (what's it based on?)
- ≥ 1 `WARRANT` or `SUPPORTS` edge (why does that ground apply?)
- ≥ 1 `REBUTTAL` (when would this fail?) — defensive

## Structural edges

These are non-Toulmin but used heavily by parsers and CIP:

| Kind | Meaning |
|---|---|
| `SEE_ALSO` | Loosely related |
| `SUPERSEDES` | Replaces / makes obsolete (used by `Promote` + Revision) |
| `CONTRADICTS` | Logically incompatible |
| `IMPLEMENTS` | Block A implements abstraction B |
| `EXTENDS` | A extends B |
| `DEPENDS_ON` | A depends on B |
| `CALLS` | A calls B (parser-emitted) |
| `REFERENCES` | A references B (parser-emitted) |
| `DOCUMENTS` | A is documentation for B |
| `CONTAINS` / `PART_OF` | Containment hierarchy |

## How to apply

```bash
ckl relate <SOURCE> <TARGET> --kind <KIND> [--reason "..."] --pretty
```

`--kind` accepts both `SCREAMING_SNAKE` and `PascalCase`. Backed by `Intent::CreateRelationship` — endpoints validated, provenance attributed (`RelationshipProvenance::Manual`).

Add `--reason` to record why the edge exists; otherwise the edge has no rationale on inspection.

## Auditability

`ckl audit --pretty` (in `ckl-evolve`) emits a `weak_decisions` section flagging:

- **Unbacked claims:** `decision` without any `GROUNDS` / `SUPPORTS` edge.
- **Thin arguments:** `decision` with backing but no `WARRANT` and no `REBUTTAL`.

Targets:
- Every `decision` should have ≥ 1 `GROUNDS` or `SUPPORTS`.
- Critical decisions should have a `WARRANT` (the principle) and a `REBUTTAL` (the trigger that would change the call).

## Examples

### Decision with full Toulmin trail

```bash
# Capture the decision
DEC=$(ckl capture --title "Use SurrealKV over RocksDB for ckl storage" \
  --content "..." --type decision --entity entity_ckl --pretty | jq -r .block_id)

# Capture the grounds (data)
GR=$(ckl capture --title "RocksDB requires C++ toolchain on every platform" \
  --content "..." --type fact --entity entity_ckl --pretty | jq -r .block_id)

# Capture the warrant (rule)
WR=$(ckl capture --title "Prefer pure-Rust dependencies for cross-platform builds" \
  --content "..." --type rule --entity entity_ckl --pretty | jq -r .block_id)

# Capture the rebuttal (failure mode)
RB=$(ckl capture --title "RocksDB benchmarks ahead by 5x on >10M keys" \
  --content "..." --type fact --entity entity_ckl --pretty | jq -r .block_id)

# Wire them up
ckl relate "$GR" "$DEC" --kind GROUNDS --reason "build-friction is the constraint"
ckl relate "$WR" "$DEC" --kind WARRANT --reason "principle: minimize toolchain"
ckl relate "$RB" "$DEC" --kind REBUTTAL --reason "would flip if we hit 10M+ blocks"
```

### Considered alternative

```bash
ALT=$(ckl capture --title "Use sled as embedded KV (rejected)" \
  --content "..." --type decision --entity entity_ckl --pretty | jq -r .block_id)

ckl relate "$ALT" "$DEC" --kind ALTERNATIVE_TO --reason "rejected: ABI not stable"
```

### Supporting evidence

```bash
ckl relate <fact_block> <decision_block> --kind SUPPORTS \
  --reason "benchmark shows 3x speedup"
```

## Quick verification

```bash
ckl context <decision_block> --pretty       # see all edges in/out
ckl audit --pretty | jq '.weak_decisions'   # is this decision flagged?
```

If `audit` flags the decision after wiring, the audit thresholds may have changed — review `ckl-evolve/references/quality-gates.md`.
