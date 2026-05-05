# Navigation commands — full reference

After `ckl query` returns blocks, drill in with these read-only navigators.

## Table of contents

- [`block`](#block) — single block by ID
- [`context`](#context) — relationships in both directions
- [`usages`](#usages) — incoming references
- [`traverse`](#traverse) — BFS from a starting block
- [`doc`](#doc) — document by ID, path, or name
- [`list`](#list) — enumerate resources

## `block`

```bash
ckl block <blk_id> --pretty
```

Returns the full block: name, type, source_file, line range, content_hash, layer (Kronos), tokens, metadata.

## `context`

```bash
ckl context <blk_id> --pretty
```

Returns categorized relationships in both directions:

- `contains` / `depended_on_by` / `depends_on` / `part_of`
- `reasoning` (Toulmin: `GROUNDS`, `WARRANT`, `REBUTTAL`)
- `related` (`SEE_ALSO`, `SUPERSEDES`, `CONTRADICTS`, …)

Use this when `ckl query --enriched` is too noisy and you only need edges.

## `usages`

```bash
ckl usages <blk_id> --pretty
```

Just incoming references (JSON array, agent-first). Useful for impact analysis: "what calls this?", "what depends on this?".

Filter at the query level: `ckl query --from-block <id> --usages --usages-rel-type CALLS`.

## `traverse`

```bash
ckl traverse <blk_id> --pretty
ckl traverse <blk_id> --depth 3 --direction outgoing --pretty
```

BFS from a starting block.

| Flag | Default | Effect |
|---|---|---|
| `--depth N` | 2 | Hops |
| `--nodes N` | 20 | Max nodes returned |
| `--direction <dir>` | both | `outgoing`, `incoming`, `both` |

For complex traversals prefer `ckl query --from-block --traverse` — the same engine but with filtering and projection knobs.

## `doc`

```bash
ckl doc <doc_id> --with-blocks --pretty                # by ID
ckl doc --location "crates/ckl-core/src/storage.rs"    # by path
ckl doc --name "storage.rs" --with-blocks              # by file name
```

`--with-blocks` includes the block list. Use to see the structure of a file as the indexer parsed it.

## `list`

```bash
ckl list <what> [filters]
```

`<what>` is one of: `all` (v0.5.2), `blocks`, `sources`, `projects`, `documents`, `organizations` (v0.5.1), `atoms` (v0.5.1), `entities`. **Plural `documents`, NOT `docs`** (returns `"Unknown list target: docs"`).

### Common filters

| Flag | Effect |
|---|---|
| `--source <src_id>` / `--source-query <text>` (v0.5.2) | Limit to one source (literal ID or substring resolver) |
| `-t <type>` | Content type: `code`, `knowledge`, `conversation` |
| `--query <text>` | Text filter over name / location / path |
| `--type <csv>` | (`list all` only) CSV subset: `organizations\|orgs`, `projects\|prjs`, `sources\|srcs`, `documents\|docs` |
| `--project <prj_id>` / `--project-query <text>` (v0.5.2) | Project scope |
| `--kind <code\|claim\|proof>` (v0.5.1) | (`atoms` only) Filter by AtomKind |
| `--holder <agent>` (v0.5.1) | (`atoms` only) Filter by holder |
| `--container <blk_xxx>` (v0.5.1) | (`atoms` only) Filter by container block |
| `--path <glob>` | Path-glob filter |
| `--limit N` | Default 50 |
| `--offset N` | Pagination |
| `--pretty` | Human-readable JSON |

### Examples

```bash
ckl list blocks --content-type knowledge --limit 30 --pretty
ckl list blocks --path "crates/ckl-temporal/**" --pretty
ckl list documents --project prj_xxx --pretty
ckl list sources --pretty
ckl list projects --pretty

# v0.5.1+ targets
ckl list organizations --pretty
ckl list atoms --kind claim --holder agent-claude --pretty
ckl list atoms --container blk_xxx --pretty
ckl list entities --pretty
```

### `ckl list all` (v0.5.2)

Aggregates Organizations + Projects + Sources + Documents into one grouped JSON response. Combine with `--query` (text filter) and `--type` (CSV subset):

```bash
ckl list all --pretty                                       # everything
ckl list all --query "ckl" --pretty                         # name/path substring
ckl list all --type orgs,projects --pretty                  # subset
ckl list all --type documents --query "storage.rs" --pretty
```

## `blob` (v0.5.3)

```bash
ckl blob <OID>                              # JSON envelope (default)
ckl blob <OID> --raw                         # raw bytes (lock-free)
ckl blob <OID> --info --pretty               # metadata only
ckl blob <OID> --refs --pretty               # reverse-lookup blocks
ckl blob list --pretty                       # enumerate loose objects
```

OID is the full 40-char SHA-1. Reads from gix-backed CAS at `~/.ckl/blobs/`. **Only `--raw` is fully lock-free.**

Full reference: [blob.md](blob.md).

## When to use which

| Goal | Command |
|---|---|
| One block by ID | `ckl block` |
| Edges of one block | `ckl context` |
| Who references this | `ckl usages` |
| Multi-hop walk | `ckl traverse` |
| Full document | `ckl doc --with-blocks` |
| Enumerate by filter | `ckl list <what>` |
| Discovery (orgs+projects+sources+docs) | `ckl list all --query <text>` (v0.5.2) |
| List atoms by envelope | `ckl list atoms --kind --holder --container` (v0.5.1) |
| Read blob content by OID | `ckl blob <OID> [--raw]` (v0.5.3) |
| Combine all | `ckl query --enriched` (one call) |
