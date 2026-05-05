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

| Flag | Since | Effect |
|---|---|---|
| `--project <prj_id>` | 0.4.x | Limit to one project |
| `--project-query <text>` | **0.5.2** | Substring → `prj_xxx` (errors if 0 or 2+ matches). Mutually exclusive with `--project`. |
| `--org <org_id>` | **0.5.1** | Limit to one organization |
| `--org-query <text>` | **0.5.2** | Substring → `org_xxx` |
| `--source-id <src_id>` | **0.5.1** | Limit to one source |
| `--source-query <text>` | **0.5.2** | Substring (name OR path) → `src_xxx` |
| `--holder <agent>` | **0.5.1** | Filter atoms by holder (`agent-claude`, `ckl-auditor`, `user-alice`) |
| `--kind <code\|claim\|proof>` | **0.5.1** | Filter atoms by Curry-Howard kind |
| `--container <blk_xxx>` | **0.5.1** | Filter atoms by their containing block |
| `-t <type>` | 0.4.x | Content type: `code`, `knowledge`, `conversation`, `documentation` |
| `--path-pattern <glob>` | 0.4.x | Limit by file path |
| `--max-per-doc N` | 0.4.x | Cap blocks returned from a single document |
| `--entity <id>` | 0.4.x | Auto-record `Query` nutrient against this entity |
| `--impact` | 0.4.x | Prioritize non-structural relationships only |
| `--at <time>` | 0.4.x | Time-travel (also see Time-travel section) |

The same six scope filters (`--org`, `--project`, `--source-id`, `--holder`, `--kind`, `--container`) are also accepted by `ckl search`, `ckl list`, and `ckl audit` (where applicable) — they form the v0.5.1 unified scoping vocabulary.

### Resolver error semantics (v0.5.2)

The three `--*-query` resolvers require **exactly one** match:

- `0 matches` → error: `no project matches '<text>'`
- `2+ matches` → error listing candidates: `ambiguous: prj_aa7f, prj_bb12 — use --project <id>`

Use the literal-ID flag (`--project <id>` etc.) when you've identified the right candidate, or refine the substring.

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

## When `ckl search` beats `ckl query`

`ckl query` is hybrid (BM25 + semantic) and weights vector similarity strongly. That's optimal for **conceptual / multi-token** queries ("StoragePort", "deadlock retry strategy"), but it can hide the right hit on **short structured-ID queries** where the discriminating signal is in the literal token, not the semantics.

| Query shape | Best tool | Why |
|---|---|---|
| Conceptual / multi-token (≥ 4 tokens) | `ckl query --enriched` | Vector embeddings catch related concepts even with different wording |
| Short structured ID (`B4`, `M1`, `S2`, `v0.5.4`) | `ckl search --format compact` | BM25 weights literal IDs; vector signal is dominated by generic words like "backlog" |
| Block ID directly | `ckl block <blk_id>` or `ckl query --from-block <blk_id>` | Skip search entirely |

**Symptom:** if `ckl query "<short ID>"` returns top-5 hits dominated by generic blocks rather than the atom whose title contains your ID, retry with `ckl search "<short ID>" --format compact`. BM25's exact-token bias usually surfaces the correct match within the top results.

```bash
# Bad fit for query: short IDs swamped by vector noise
ckl query "v0.5.4 backlog B4"  --limit 5  # may miss blk_96dcf4ffcaed_0

# Good fit: BM25-leaning, surfaces literal ID matches
ckl search "v0.5.4 backlog B4" --format compact
```

This is documented as gotcha atom `blk_2307b35fa77f_0` (v0.5.4 backlog B5).

### v0.5.x scoped examples

Resolve project by name + filter to atoms held by a specific agent:
```bash
ckl query "MVCC" \
  --project-query "ckl-engine" \
  --kind claim --holder agent-claude \
  --enriched --pretty
```

Find proof atoms inside a containing block (drill from claim → its supporting evidence):
```bash
ckl query --from-block blk_decision_xxx \
  --kind proof --container blk_decision_xxx \
  --traverse --pretty
```

Cross-source query (substring match on source name/path):
```bash
ckl query "rate limiter" --source-query "core/storage" --enriched --pretty
```
