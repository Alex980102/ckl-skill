# Quality gates — definitions and targets

Quality gates are advisory thresholds. They don't block operations, but they tell you when an entity needs cleanup before continuing.

## Table of contents

- [Metrics](#metrics)
- [How to read `ckl health`](#how-to-read-ckl-health)
- [Targets and remedies](#targets-and-remedies)

## Metrics

| Metric | Source | Definition |
|---|---|---|
| `unresolved` | `ckl audit` | Sum of all audit findings divided by total blocks in entity |
| `noisy_hubs` | `ckl map` | Count of nodes with edge degree above threshold (over-connected) |
| `non_structural` | `ckl map` | Share of edges that are non-structural (`CALLS`, `DEPENDS_ON`, `SUPPORTS`, `GROUNDS`, …) vs purely structural (`CONTAINS`, `PART_OF`) |
| `coherence` | `ckl health` | Entity coherence score (0..1) — how well atoms agree on subjects |
| `nucleus_ratio` | `ckl health` | Fraction of atoms in the Nucleus layer |
| `tensions` | `ckl health` | Count of unresolved contradictions / weak decisions |

## How to read `ckl health`

```bash
ckl health --entity entity_ckl --pretty
```

Returns:

```json
{
  "entity_id": "entity_ckl",
  "total_blocks": 320,
  "active_blocks": 293,
  "nucleus_count": 35,
  "nucleus_ratio": 0.109,
  "coherence_score": 1.0,
  "active_tensions": 0,
  "total_cycles": 140,
  "total_mass": 145.7
}
```

Interpretation:

- `nucleus_count` / `nucleus_ratio`: how much of the entity is "settled" (high-confidence anchors). Low for young entities, growing over time.
- `coherence_score`: 1.0 means atoms agree; lower means contradictions accumulating.
- `active_tensions`: real-time count of unresolved issues. **0 is the goal.**
- `total_cycles`: how many `ckl cycle` runs have happened. Older entities have more.
- `total_mass`: aggregate weight across all atoms.

## Targets and remedies

| Metric | Target | If above/below | Remedy |
|---|---|---|---|
| `unresolved` | ≤ 0.15 | Too high = noisy graph | `ckl audit --pretty`, then `ckl reconcile` or `ckl clean --garbage --confirm` |
| `noisy_hubs` | ≤ 5 | Too many = single block over-connected | `ckl context <hub_id> --pretty` to inspect; consider splitting the block |
| `non_structural` | ≥ 0.25 | Too low = graph is just file containment | Capture more `decision` / `pattern` / argument edges via `ckl-knowledge` |
| `coherence` | ≥ 0.8 | Too low = contradictions piling up | `ckl audit --contradictions --pretty`, then `ckl reconcile` |
| `nucleus_ratio` | grows over time | Stagnant = atoms not stabilizing | Run `ckl cycle` more often or `ckl promote` validated atoms |
| `tensions` | 0 | Any > 0 = unresolved issue | `ckl audit --pretty` to find them |

These targets are heuristics from production CKL deployments, not hard limits. A research project may tolerate higher `unresolved` while a production codebase wants it lower.

## Workflow: end-of-session quality check

```bash
# 1. Run cycle
ckl cycle --entity entity_ckl --trigger "session_end" --pretty

# 2. Check health
ckl health --entity entity_ckl --pretty

# 3. Audit if anything looks off
ckl audit --pretty

# 4. Address top findings
ckl reconcile --duplicates --pretty       # if dupes
ckl clean --garbage --confirm --pretty    # if garbage
# or manual: ckl relate ... --kind GROUNDS  for weak_decisions
```

## Entity-level vs project-level

`ckl health` is entity-scoped. `ckl audit` and `ckl map` accept both `--entity` and `--project` filters.

| Need | Filter |
|---|---|
| Quality of one knowledge entity | `--entity <id>` |
| Quality of indexed code in a project | `--project <id>` |
| Whole graph | (no filter) |
