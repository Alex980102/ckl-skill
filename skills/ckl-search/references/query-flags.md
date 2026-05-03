# `ckl query` — full flag reference

## Table of contents

- [Entry points](#entry-points) — required, one of
- [Enrichment](#enrichment) — what to include in the response
- [Filters](#filters) — narrow the candidate set
- [Output control](#output-control) — format and token budget
- [Time-travel](#time-travel)
- [Examples](#examples)

## Entry points

Exactly one is required.

| Flag | Use |
|---|---|
| `<QUERY>` (positional) | Hybrid text query (BM25 + semantic + graph) |
| `--from-block <blk_id>` | Anchor at a specific block, then enrich |
| `--from-path <glob>` | Anchor at all blocks under a path glob |
| `--like <blk_id>` | Anchored vector search — semantically similar blocks |

## Enrichment

| Flag | Default | Effect |
|---|---|---|
| `--enriched` | off | Shortcut: enables `--context --source --usages --traverse` with sane defaults |
| `--context` | off | Categorized relationships (contains, depends_on, uses, …) |
| `--depth N` | 1 | Context expansion depth (1..3) |
| `--source` | off | Inline source code at original line range |
| `--source-expand N` | 5 | Extra lines around each block |
| `--usages` | off | Incoming references |
| `--usages-limit N` | 5 | Cap on incoming refs returned |
| `--usages-rel-type <T>` | any | Filter incoming refs by type (`IMPORTS`, `CALLS`, `DEPENDS_ON`, `EXTENDS`, …) |
| `--traverse` | off | Multi-hop BFS |
| `--traverse-depth N` | 2 | BFS depth |
| `--traverse-nodes N` | 20 | Cap on nodes returned |
| `--traverse-direction <dir>` | both | `outgoing`, `incoming`, or `both` |

## Filters

| Flag | Effect |
|---|---|
| `--project <prj_id>` | Limit to one project |
| `-t <type>` | Filter by content type: `code`, `knowledge`, `conversation`, `documentation` |
| `--path-pattern <glob>` | Limit by file path |
| `--max-per-doc N` | Cap blocks returned from a single document |
| `--entity <id>` | Auto-record `Query` nutrient against this entity |
| `--impact` | Prioritize non-structural relationships only |

## Output control

| Flag | Default | Effect |
|---|---|---|
| `--format <fmt>` | `full` | One of `full`, `compact`, `ids-only` |
| `--max-tokens N` | 4000 | Token budget for the response |
| `--level <l>` | `full` | Projection: `metadata`, `relations`, `full` |
| `--keyword-weight <w>` | balanced | 0.0..1.0 BM25 weight |
| `--semantic-weight <w>` | balanced | 0.0..1.0 vector weight |
| `--limit N` | 10 | Max results |
| `--pretty` | off | Human-readable JSON |

## Time-travel

| Flag | Format | Effect |
|---|---|---|
| `--at <time>` | ISO date or unix-micros | Query the graph as it was at that time |

## Examples

Find a struct and inline its source:
```bash
ckl query "StoragePort" --enriched --source --pretty
```

Find what depends on a block:
```bash
ckl query --from-block blk_xxx --usages --usages-rel-type DEPENDS_ON --pretty
```

Vector-similar blocks (semantic):
```bash
ckl query --like blk_xxx --limit 5 --pretty
```

Compact orientation, drill later:
```bash
ckl search "error handling" --format compact --pretty
ckl query --from-block blk_xxx --enriched --pretty
```

Time-travel:
```bash
ckl query "deprecated_api" --at "2025-12-01T00:00:00Z" --pretty
```

Impact-focused (only `CALLS` / `DEPENDS_ON` / `IMPLEMENTS`):
```bash
ckl query "ConfigLoader" --impact --depth 2 --pretty
```
