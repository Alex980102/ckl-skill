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
| `weak_decisions` | `decision` atoms missing `GROUNDS`/`SUPPORTS`, or backed but no `WARRANT`/`REBUTTAL`, or `holder=None` (v0.5.0 JTB+S) | Argument is unbacked, thin, or unsigned. See severity table below. |
| `atom_coverage` | v0.5.1: ratio of blocks with `Atom` envelope. Healthy threshold `0.7`. | Re-capture with `--holder`/`--kind`, or `ckl distill --block <blk>`. |

## Flags

| Flag | Effect |
|---|---|
| `--garbage` | Only the garbage section |
| `--duplicates` | Only the duplicates section |
| `--contradictions` | Only the contradictions section |
| `--stale` | Only the stale section |
| `--stale-days N` | Threshold for stale detection (default 30) |
| `--include-linked` | Include pairs already linked by `SEE_ALSO` / `SUPERSEDES` / `CONTRADICTS` (default: skipped) |
| `--project <prj_id>` | Project-scoped audit (v0.5.1+: scopes `atom_coverage` and JTB weak_decisions). Mutually exclusive with `--project-query`. |
| `--project-query <text>` | v0.5.2: resolve project by substring match on name |
| `--persist-findings` | v0.5.1: persist `weak_decisions` as `Claim` atoms held by `ckl-auditor` (idempotent via `AtomId::from_content`). Default OFF — audit stays read-only. |
| `--exclude-low` | v0.5.0: drop severity-Low findings (atoms missing only `REBUTTAL` — "thin argument") |
| `--include-walton` | v0.5.0 placeholder for v0.6.1 Walton fallacy detection. Accepted but no-op + warning. |
| `--pretty` | Human-readable JSON |

## Severity table (v0.5.0)

| Severity | Trigger | Hint |
|---|---|---|
| **High** | No `GROUNDS` AND no `SUPPORTS`, OR `holder=None` | Add evidence edge or set `--holder`. Unsigned atoms fail JTB+S. |
| **Medium** | Has grounds/support but no `WARRANT` | Add the inference rule: `ckl relate <rule> <decision> --kind WARRANT`. |
| **Low** | Has grounds + warrant but no `REBUTTAL` | Document falsification clause, or filter via `--exclude-low`. |

## Output format (v0.5.x extended fields)

```json
{
  "weak_decisions": [
    {
      "block_id": "blk_xxx",
      "atom_id": "at_yyy",
      "severity": "High",
      "issue": "no_holder",
      "holder": null,
      "hint": "set --holder or $CKL_DEFAULT_HOLDER on capture"
    }
  ],
  "atom_coverage": {
    "blocks_total": 320,
    "blocks_with_atoms": 240,
    "coverage_ratio": 0.75,
    "healthy_threshold": 0.7
  }
}
```

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
