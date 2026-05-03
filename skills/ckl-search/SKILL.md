---
name: ckl-search
description: Use when the user wants to find code, navigate the knowledge graph, get a project overview, or explore relationships between blocks. Hybrid search (BM25 + semantic + graph) replaces Grep/Glob in projects indexed with ckl. Activate on mentions of "find", "search", "where is", "what calls", "what references", "show me", "navigate", "trace", "lookup", or specific code/concept names in indexed projects.
license: Apache-2.0
compatibility: Requires `ckl` binary >= 0.4.9 on $PATH and a project indexed with `ckl index` (see ckl-system skill).
metadata:
  version: 0.1.0
  upstream: https://github.com/koslab/ckl
  composes-with: ckl-edit, ckl-knowledge
  prerequisite: ckl-system
  primary-commands: query, search, map, status, block, context, usages, traverse, doc, list
---

# CKL Search

Find code and knowledge across an indexed project via hybrid search (BM25 + semantic + graph). The default replacement for `Grep`/`Glob` in projects indexed with ckl.

**Binary:** `ckl` on `$PATH`. **DB:** `~/.ckl/data/ckl.skv`.

## Quick Reference

| Verb | Command | Purpose |
|---|---|---|
| Search | `ckl query <q> --enriched --pretty` | Hybrid search + relations + source + usages in one call |
| Quick check | `ckl search <q> --format compact` | Fast snippets + scores, no enrichment |
| Overview | `ckl map --pretty` | Entry points, hubs, quality warnings |
| DB stats | `ckl status --pretty` | Per-project counts, vector shard layout |
| One block | `ckl block blk_xxx --pretty` | Single block by ID |
| Relationships | `ckl context blk_xxx --pretty` | Edges in both directions |
| Incoming refs | `ckl usages blk_xxx --pretty` | Who references this block |
| Multi-hop | `ckl traverse blk_xxx --pretty` | BFS from a block |
| Document | `ckl doc doc_xxx --with-blocks --pretty` | Doc + its blocks |
| Resources | `ckl list <what> [filters]` | List blocks, sources, projects, documents |

Full per-flag reference: [references/query-flags.md](references/query-flags.md), [references/navigate.md](references/navigate.md).

## Find — primary entry point

```bash
ckl query "StoragePort" --enriched --limit 5 --pretty
```

`--enriched` is shorthand for `--context --source --usages --traverse` with sane defaults — one call returns the block, its relationships, the source code, and incoming references.

### Entry-point alternatives

| Flag | Use |
|---|---|
| `<QUERY>` | Hybrid text query (default) |
| `--from-block blk_xxx` | Start from a specific block |
| `--from-path "crates/ckl-temporal/**"` | Start from a path glob |
| `--like blk_xxx` | Anchored vector search (semantically similar blocks) |
| `--impact` | Prioritize non-structural relationships (`CALLS`, `DEPENDS_ON`, `IMPLEMENTS`) |
| `--at <iso-date>` | Time-travel query |

### Filters

`--project <prj_id>`, `-t code|knowledge|conversation|documentation`, `--path-pattern <glob>`, `--max-per-doc <N>`, `--entity <id>` (auto-records `Query` nutrient).

### Output control

`--format full|compact|ids-only`, `--max-tokens <N>` (default 4000), `--level metadata|relations|full`, `--keyword-weight 0..1` / `--semantic-weight 0..1`.

## Navigate from a result

After a query returns a block, drill in:

```bash
ckl block blk_xxx --pretty                        # full block
ckl context blk_xxx --pretty                      # relationships, both directions
ckl usages blk_xxx --pretty                       # incoming references (JSON array)
ckl traverse blk_xxx --pretty                     # BFS from a block
ckl doc doc_xxx --with-blocks --pretty            # document + its blocks
ckl doc --location "crates/ckl-core/src/storage.rs"
```

## Project overview

```bash
ckl map --pretty                              # graph overview: entry points, hubs, quality
ckl map --project prj_xxx --quality --pretty  # quality warnings
ckl status --pretty                           # DB statistics
ckl status --project prj_xxx --pretty         # project-scoped
```

## list resources

```bash
ckl list blocks --content-type knowledge --limit 30 --pretty
ckl list blocks --path "crates/ckl-temporal/**" --pretty
ckl list documents --project prj_xxx --pretty
ckl list sources --pretty
```

`<what>` is `blocks`, `sources`, `projects`, `documents` — **plural `documents`, not `docs`**.

## When to Use What

| Need | Tool | Why |
|---|---|---|
| Find code or knowledge | `ckl query --enriched` | Hybrid search + graph in one call |
| Quick existence check | `ckl search --format compact` | Fast, just snippets + scores |
| Read file content | native `Read` tool, or `ckl query --source` | Direct or inlined |
| Multi-hop navigation | `ckl query --from-block --traverse` | BFS from anchor |
| Project overview | `ckl map --pretty` | Entry points, hubs, quality |

**Do NOT use** `Grep`/`Glob` when the project is indexed — `ckl query`/`search` is faster and returns richer context.

## Composes with

This skill is one of five `ckl` skills. Use it together with:

- **`ckl-system`** — prerequisite: install `ckl`, run `ckl index <path>` so search has data
- **`ckl-edit`** — apply changes after finding the code
- **`ckl-knowledge`** — capture insights from what you found
- **`ckl-evolve`** — audit search quality, run cycles after captures

## Utility Scripts

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/project-status.sh [project_id]
```

Falls back to `scripts/project-status.sh` for agents that don't expand `${CLAUDE_SKILL_DIR}`.

## Gotchas

1. `ckl list` accepts plural `documents`, NOT `docs` — `"Unknown list target: docs"`.
2. Empty results often mean the project is not indexed. Run `ckl index <path>` first (see `ckl-system`).
3. `--enriched` is heavier (~4× tokens vs `--format compact`) — start with compact, drill with enriched.
4. Vector index lives in `~/.ckl/data/vectors/<project>.usearch` per project, plus `_orphan.usearch` for blocks without a project.
