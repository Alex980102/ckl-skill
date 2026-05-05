---
name: ckl-search
description: Use when the user wants to find code, navigate the knowledge graph, get a project overview, scope searches by org/project/source/holder/kind/container, do cross-entity discovery (orgs+projects+sources+documents in one shot), resolve names to IDs by substring (--project-query / --org-query / --source-query), read content-addressed blobs by OID, or explore relationships between blocks. Hybrid search (BM25 + semantic + graph) replaces Grep/Glob in projects indexed with ckl. Activate on mentions of "find", "search", "where is", "what calls", "what references", "show me", "navigate", "trace", "lookup", "list all", "by holder", "by kind", "blob", "OID", "scoped search", or specific code/concept names in indexed projects.
license: Apache-2.0
compatibility: Requires `ckl` binary >= 0.5.3 on $PATH and a project indexed with `ckl index` (see ckl-system skill).
metadata:
  version: 0.2.0
  upstream: https://github.com/koslab/ckl
  composes-with: ckl-edit, ckl-knowledge
  prerequisite: ckl-system
  primary-commands: query, search, map, status, block, context, usages, traverse, doc, list, blob
---

# CKL Search

Find code and knowledge across an indexed project via hybrid search (BM25 + semantic + graph). The default replacement for `Grep`/`Glob` in projects indexed with ckl.

**Binary:** `ckl` on `$PATH`. **DB:** `~/.ckl/data/ckl.skv`.

## Quick Reference

| Verb | Command | Purpose |
|---|---|---|
| Search | `ckl query <q> --enriched --pretty` | Hybrid search + relations + source + usages in one call |
| Quick check | `ckl search <q> --format compact` | Fast snippets + scores, no enrichment |
| Discovery | `ckl list all --query <text> --pretty` | v0.5.2: Orgs+Projects+Sources+Documents grouped in one call (`--type` to subset) |
| Overview | `ckl map --pretty` | Entry points, hubs, quality warnings |
| DB stats | `ckl status --pretty` | Per-project counts, vector shard layout, atoms.by_kind |
| One block | `ckl block blk_xxx --pretty` | Single block by ID |
| Relationships | `ckl context blk_xxx --pretty` | Edges in both directions |
| Incoming refs | `ckl usages blk_xxx --pretty` | Who references this block |
| Multi-hop | `ckl traverse blk_xxx --pretty` | BFS from a block |
| Document | `ckl doc doc_xxx --with-blocks --pretty` | Doc + its blocks |
| Blob (CAS) | `ckl blob <oid> [--raw\|--info\|--refs]` | v0.5.3: Direct read from `~/.ckl/blobs/` (gix-backed). `ckl blob list` enumerates loose objects. |
| Resources | `ckl list <what> [filters]` | List blocks, sources, projects, documents, organizations, atoms, entities |

**Scoped search flags** (v0.5.1 — work on `query`, `search`, `list`, `audit`):

`--org <id>` / `--org-query <text>` (v0.5.2) | `--project <id>` / `--project-query <text>` (v0.5.2) | `--source-id <id>` / `--source-query <text>` (v0.5.2) | `--holder <agent>` | `--kind <code\|claim\|proof>` | `--container <blk_xxx>`

Full per-flag reference: [references/query-flags.md](references/query-flags.md), [references/navigate.md](references/navigate.md), [references/blob.md](references/blob.md).

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

| Flag | Effect |
|---|---|
| `--project <prj_id>` / `--project-query <text>` | Project scope (v0.5.2 substring resolver: 0/N matches errors out — disambiguate with `--project <id>`). |
| `--org <org_id>` / `--org-query <text>` | Organization scope (v0.5.1 / v0.5.2). |
| `--source-id <src_id>` / `--source-query <text>` | Source scope (v0.5.1 / v0.5.2). |
| `--holder <agent>` | v0.5.1: filter atoms by holder (e.g. `agent-claude`, `ckl-auditor`, `user-alice`). |
| `--kind <code\|claim\|proof>` | v0.5.1: filter atoms by Curry-Howard kind. |
| `--container <blk_xxx>` | v0.5.1: filter atoms by their containing block. |
| `-t <type>` | Content type: `code`, `knowledge`, `conversation`, `documentation`. |
| `--path-pattern <glob>` | Limit by file path. |
| `--max-per-doc <N>` | Cap blocks returned from a single document. |
| `--entity <id>` | Auto-record `Query` nutrient against this entity. |

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

# v0.5.1+ targets:
ckl list organizations --pretty                                    # v0.5.1
ckl list atoms --kind claim --holder agent-claude --pretty         # v0.5.1
ckl list atoms --container blk_daemon_overview --pretty            # v0.5.1
ckl list entities --pretty
```

`<what>` is `all`, `blocks`, `sources`, `projects`, `documents`, `organizations`, `atoms`, `entities` — **plural `documents`, not `docs`**.

## Scoped search (v0.5.1)

Every search/list/audit accepts the same six scoping filters: `--org`, `--project`, `--source-id`, `--holder`, `--kind`, `--container`. Combine them freely — they AND together.

```bash
# All decision atoms held by agent-claude in one project
ckl query "MVCC" \
  --project prj_xxx \
  --kind claim --holder agent-claude \
  --enriched --pretty

# All atoms inside a specific container block
ckl query "deadlock" --container blk_daemon_overview --pretty

# Audit a single project's atom_coverage and JTB findings
ckl audit --project prj_xxx --pretty
```

Scope resolution order (Org → Project → Source → Holder/Kind/Container) lets you start broad and narrow without re-typing the query.

## Cross-entity discovery — `ckl list all` (v0.5.2)

`ckl list all` aggregates **Organizations + Projects + Sources + Documents** into one grouped JSON response. Combine with `--query` for fuzzy match across names/paths and `--type` (CSV) to subset.

```bash
ckl list all --pretty                                       # everything
ckl list all --query "ckl" --pretty                         # name/path substring filter
ckl list all --type orgs,projects --pretty                  # subset
ckl list all --type documents --query "storage.rs" --pretty # find a doc across all sources
```

Aliases accepted by `--type`: `organizations|orgs`, `projects|prjs`, `sources|srcs`, `documents|docs`.

Use this as the **single discovery entry point** when you don't yet know which org/project/source the user is asking about.

## Native scope resolution — `--*-query` resolvers (v0.5.2)

`query`, `search`, `list`, and `audit` accept three substring-to-ID resolvers:

| Flag | Resolves |
|---|---|
| `--project-query <text>` | substring → `prj_xxx` |
| `--org-query <text>` | substring → `org_xxx` |
| `--source-query <text>` | substring (name OR path) → `src_xxx` |

```bash
ckl query "lock" --project-query "ckl-engine" --enriched --pretty
ckl audit --project-query "ckl-engine" --pretty
ckl list documents --source-query "core/storage" --pretty
```

**Error semantics:** the resolver requires **exactly one** match.

- `0 matches` → exits with error: "no project matches 'ckl-engine'".
- `2+ matches` → exits with error listing candidates: "ambiguous: prj_aa7f, prj_bb12 — use --project <id>".

This mirrors how a human disambiguates: "did you mean prj_aa7f or prj_bb12?" — let the CLI tell you and pass `--project <id>` to nail it down.

## Direct blob access — `ckl blob` (v0.5.3)

ckl 0.5.3 stores block content in a gix-backed CAS at `~/.ckl/blobs/`. Each block has a `blob_oid` (40-char SHA-1) you can read directly:

| Mode | Output | Daemon-lock |
|---|---|---|
| Default (no flag) | JSON envelope: `{oid, size_bytes, content, encoding, refs_count, exists}`; `encoding` is `utf8` or `base64`. | Locks DB briefly for refs lookup |
| `--raw` | Pipes raw bytes to stdout (binary-safe). Skips refs lookup. | **Lock-free** — reads gix store directly |
| `--info` | Metadata only (no content). | Locks DB briefly |
| `--refs` | Reverse lookup: blocks whose `blob_oid == OID`. | Locks DB |

```bash
# JSON envelope
ckl blob 4f3a8b... --pretty

# Stream raw content (binary-safe, lock-free)
ckl blob 4f3a8b... --raw > /tmp/recovered.txt
ckl blob 4f3a8b... --raw | sha1sum                # verify OID

# What references this blob?
ckl blob 4f3a8b... --refs --pretty

# Just metadata
ckl blob 4f3a8b... --info --pretty

# Enumerate all loose objects
ckl blob list --pretty
```

When to use `ckl blob` over `ckl block`:

- You have an OID from a log line / audit report and want the content fast.
- You want lock-free reads in long-running pipelines: always pass `--raw`.
- You're verifying CAS integrity (compare returned content's SHA against the OID).

Full reference: [references/blob.md](references/blob.md).

## Patterns

### Pattern: Scoped query workflow (Org → Project → Block → Atom)

Drill from broad to narrow without leaving the search surface:

```bash
# 1. Find the project (substring resolver)
ckl list all --type projects --query "ckl" --pretty

# 2. Search inside it
ckl query "StoragePort" --project prj_aa7f --enriched --pretty

# 3. Filter to atoms held by a specific agent
ckl query "StoragePort" --project prj_aa7f --kind claim --holder agent-claude --pretty

# 4. Inspect the resulting block + its container atoms
ckl block blk_xxx --pretty
ckl list atoms --container blk_xxx --pretty
```

### Pattern: Discovery + scope in one shot

When the user asks something like "what decisions has agent-claude made in the ckl project this week?":

```bash
# Resolve project by name in one step (errors if ambiguous)
ckl query "decision" \
  --project-query "ckl" \
  --kind claim --holder agent-claude \
  --enriched --pretty
```

No separate "list projects then re-run with `--project <id>`" round-trip.

### Pattern: Inspecting blob OIDs from logs / audit

Audit / migration logs sometimes surface raw OIDs. Resolve them fast:

```bash
# What is this OID?
ckl blob 4f3a8b... --info --pretty

# Who references it?
ckl blob 4f3a8b... --refs --pretty

# Stream the content (lock-free)
ckl blob 4f3a8b... --raw | less
```

If `--info` returns `exists: false`, the loose object was packed or GC'd — re-run `ckl status` and check `wave6_migrated`.

## When to Use What

| Need | Tool | Why |
|---|---|---|
| Find code or knowledge | `ckl query --enriched` | Hybrid search + graph in one call |
| Quick existence check | `ckl search --format compact` | Fast, just snippets + scores |
| Read file content | native `Read` tool, or `ckl query --source` | Direct or inlined |
| Multi-hop navigation | `ckl query --from-block --traverse` | BFS from anchor |
| Project overview | `ckl map --pretty` | Entry points, hubs, quality |
| Cross-entity discovery (orgs/projects/sources/docs) | `ckl list all --query <text>` | v0.5.2 grouped one-shot — no per-target round-trips |
| "Find me the X project by name" | `--project-query <text>` (or `--org-query` / `--source-query`) | v0.5.2 substring → ID resolver |
| Filter to my agent's atoms | `--holder <agent>` + `--kind claim` | v0.5.1 atom envelope filter |
| Read a blob by OID | `ckl blob <oid> --raw` | v0.5.3 lock-free CAS read |
| Inspect what references an OID | `ckl blob <oid> --refs` | v0.5.3 reverse lookup |

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

1. `ckl list` accepts plural `documents`, NOT `docs` — `"Unknown list target: docs"`. v0.5.2 added `all`, `organizations`, `atoms`, `entities`.
2. Empty results often mean the project is not indexed. Run `ckl index <path>` first (see `ckl-system`).
3. `--enriched` is heavier (~4× tokens vs `--format compact`) — start with compact, drill with enriched.
4. Vector index lives in `~/.ckl/data/vectors/<project>.usearch` per project, plus `_orphan.usearch` for blocks without a project.
5. **`--*-query` resolvers (v0.5.2) require exactly one match.** 0 matches → error; 2+ → error with candidate list. Use `--project <id>` (literal) when ambiguous. The flags are mutually exclusive with their `--project` / `--org` / `--source-id` counterparts.
6. **Daemon-lock trade-off (v0.5.2 / v0.5.3).** `ckl list all` and `ckl blob` *default / --info / --refs* modes briefly hold the SurrealKV lock. Only `ckl blob OID --raw` is fully lock-free. In long-running pipelines reading many blobs, prefer `--raw`.
7. **`ckl blob OID` requires the full 40-char SHA-1.** Short prefixes are not currently expanded.
8. `--kind` accepts only `code`, `claim`, `proof` (v0.5.0 AtomKind). Other strings error out.
