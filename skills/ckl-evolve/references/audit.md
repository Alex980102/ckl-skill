# `ckl audit` — full check reference

Read-only, algorithmic detection. No LLM. Run between captures and before commits to keep the graph clean.

## Table of contents

- [Sections](#sections)
- [Flags](#flags)
- [Output format](#output-format)
- [Reconcile workflow](#reconcile-workflow)
- [Quality gates](#quality-gates)

## Sections

`ckl audit --pretty` returns these sections by default:

| Section | What it detects | Cause / fix |
|---|---|---|
| `garbage` | Low-token test artifacts | Blocks with `< 15 tokens`, names like `Write: test_*`, accidental imports of fixture data. Fix: `ckl clean --garbage --confirm`. |
| `duplicates` | Semantically similar block pairs | Same insight captured twice. Fix: `ckl reconcile --duplicates` (LLM merges) or `ckl deprecate` the loser. |
| `contradictions` | Negation patterns + topic overlap | "X must Y" vs "X must NOT Y". Fix: `ckl reconcile --contradictions` to get LLM resolution + `SUPERSEDES` edge. |
| `stale` | Old blocks without recent access | Default threshold 30 days. Fix: `ckl archive` (reversible) or `--stale-days N` to widen window. |
| `weak_decisions` | `decision` atoms missing `GROUNDS`/`SUPPORTS`, or backed but no `WARRANT`/`REBUTTAL` | Argument is unbacked or thin. Fix: `ckl relate <fact> <decision> --kind GROUNDS --reason "..."`. |

## Flags

| Flag | Effect |
|---|---|
| `--garbage` | Only the garbage section |
| `--duplicates` | Only the duplicates section |
| `--contradictions` | Only the contradictions section |
| `--stale` | Only the stale section |
| `--stale-days N` | Threshold for stale detection (default 30) |
| `--include-linked` | Include pairs already linked by `SEE_ALSO` / `SUPERSEDES` / `CONTRADICTS` (default: skipped) |
| `--project <prj_id>` | Project-scoped audit |
| `--entity <id>` | Entity-scoped audit |
| `--pretty` | Human-readable JSON |

Combine flags to narrow:

```bash
ckl audit --pretty                                  # all sections
ckl audit --duplicates --pretty
ckl audit --garbage --contradictions --pretty
ckl audit --stale --stale-days 60 --pretty
ckl audit --include-linked --pretty
ckl audit --project prj_xxx --entity entity_ckl --pretty
```

## Output format

```json
{
  "garbage": [
    { "block_id": "blk_xxx", "name": "Write: test_foo", "tokens": 8 }
  ],
  "duplicates": [
    {
      "pair": ["blk_a", "blk_b"],
      "similarity": 0.92,
      "linked": false
    }
  ],
  "contradictions": [
    {
      "pair": ["blk_a", "blk_b"],
      "topic_overlap": 0.78,
      "negation_pattern": "MUST vs MUST_NOT"
    }
  ],
  "stale": [
    { "block_id": "blk_xxx", "last_access": "2025-09-01T...", "days_stale": 90 }
  ],
  "weak_decisions": [
    {
      "block_id": "blk_xxx",
      "issue": "no_grounds",
      "hint": "Run: ckl relate <fact> blk_xxx --kind GROUNDS"
    }
  ]
}
```

## Reconcile workflow

For sections with LLM-resolvable issues:

```bash
# 1. Audit
ckl audit --duplicates --pretty

# 2. Reconcile via LLM
ckl reconcile --duplicates --pretty

# 3. Re-audit to confirm
ckl audit --duplicates --pretty
```

`reconcile` reads the pairs flagged by audit, asks the LLM to merge or supersede, applies the result with `RelationshipProvenance::Reconcile`. The `ckl-config` `agents.provider` and `agents.model` settings control which LLM is used.

For pairs you want to handle manually (e.g. ambiguous contradictions), use:

```bash
ckl deprecate --block <loser>                                # mark as deprecated
ckl relate <winner> <loser> --kind SUPERSEDES --reason "..."
```

## Quality gates

Targets for a healthy entity:

| Metric | Computed by | Target |
|---|---|---|
| `unresolved` | `audit` findings / total blocks | ≤ 0.15 |
| `noisy_hubs` | nodes with > N connections | ≤ 5 |
| `non_structural` | semantic edges share | ≥ 0.25 |
| `coherence` | `ckl health` field | ≥ 0.8 |
| `nucleus_ratio` | `ckl health` field | depends on entity age |

Full gate definitions: [quality-gates.md](quality-gates.md).
