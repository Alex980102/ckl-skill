---
name: ckl-system
description: Use when the user wants to set up ckl, index a project for the first time, manage the daemon, configure auth/embeddings, watch for code or session changes, crawl documentation from URLs, or run storage migrations. This is the prerequisite skill for all other ckl skills — without `ckl index`, search/edit/knowledge/evolve do not work. Activate on mentions of "install ckl", "setup", "configure", "index project", "daemon", "MCP server", "crawl docs", "watch", "migrate", "reembed", "warm shards", "auth", or any ckl infrastructure / admin operation.
license: Apache-2.0
compatibility: Requires `ckl` binary >= 0.5.3 on $PATH. Some commands need write access to `~/.ckl/data/` and may require stopping the daemon first.
metadata:
  version: 0.2.0
  upstream: https://github.com/koslab/ckl
  composes-with: ckl-search, ckl-edit, ckl-knowledge, ckl-evolve
  prerequisite-for: all other ckl skills
  primary-commands: setup, index, config, auth, daemon, mcp, crawl, watch, watch-session, manage, warm, migrate, migrate-vectors, migrate-finalize, reembed
---

# CKL System

Setup and administration for `ckl`. This is the **prerequisite skill** — without `ckl index`, none of the other ckl skills (search/edit/knowledge/evolve) have any data to operate on.

**Binary:** `ckl` on `$PATH`. **DB:** `~/.ckl/data/ckl.skv` (SurrealKV). **Config:** `~/.ckl/settings.json`. **Vector index:** `~/.ckl/data/vectors/<project>.usearch` per project + `_orphan.usearch`. **CAS blob store (v0.5.3):** `~/.ckl/blobs/` (gix-backed).

## What's new in ckl 0.5.x

This skill targets **ckl 0.5.3** — covers four minor releases since v0.4.9:

| Release | Surface |
|---|---|
| `v0.5.0` Atomic Knowledge | `Atom` + JTB+S envelope (`--holder` / `--kind` / `--container`), `StoragePort` trait amendment, `ckl distill` (placeholder) |
| `v0.5.1` Scoped Search II | scoped filters on `query` / `search` / `list` / `audit`, `ckl audit --persist-findings`, `--exclude-low` |
| `v0.5.2` Agent-First Discovery | `ckl list all`, `--project-query` / `--org-query` / `--source-query` resolvers (substring → ID with 0/N error handling) |
| `v0.5.3` Direct Blob Access | `ckl blob OID` (default / `--raw` / `--info` / `--refs`), `ckl blob list` |

Per-skill detail: `ckl-search` covers scoping + blobs; `ckl-knowledge` covers JTB+S + AtomKind + distill; `ckl-evolve` covers severity-graded weak decisions + `atom_coverage`.

## Quick Reference

| Command | Purpose |
|---|---|
| `ckl setup` | First-time onboarding wizard |
| `ckl index <path> --pretty` | Index a project directory (idempotent) |
| `ckl config get` / `set <key> <value>` / `path` | View / modify configuration |
| `ckl auth claude` / `ckl auth api-key <key>` | Authenticate (OAuth or API key) |
| `ckl daemon status` / `start` / `stop` | Manage background daemon |
| `ckl mcp` | Start MCP server on stdio (Claude Desktop / Code) |
| `ckl watch <path>` | Live re-index on file changes |
| `ckl watch-session --transcript <path>` | Index Claude Code session transcript |
| `ckl crawl discover <url>` / `crawl index <url>` | Fetch documentation from URLs |
| `ckl manage <resource> <action>` | CRUD orgs / projects / sources / blocks / relationships |
| `ckl warm --project <id>` | Force-load vector shards into RAM |
| `ckl migrate-vectors --confirm` | Migrate to per-project vector shard layout |
| `ckl reembed --project <id>` | Re-compute embeddings (stop daemon first on large jobs) |

Deeper material: [references/setup.md](references/setup.md), [references/daemon.md](references/daemon.md), [references/ingest.md](references/ingest.md), [references/migrations.md](references/migrations.md).

## First-time setup

```bash
# 1. Install (ckl >= 0.5.3 required for this skill suite)
cargo install --git https://github.com/koslab/ckl ckl-cli

# 2. Onboarding wizard
ckl setup

# 3. Authenticate (one of)
ckl auth claude              # OAuth
ckl auth api-key <key>       # Anthropic API key

# 4. Index your project
ckl index /path/to/project --pretty
```

After this, all other ckl skills work against the indexed project.

## Configuration

```bash
ckl config get                       # show full config
ckl config get embeddings.provider   # one key
ckl config set <key> <value>         # mutate
ckl config path                      # print settings.json path
```

Common keys: `database.path`, `embeddings.provider` (`voyage` / `openai`), `embeddings.model`, `embeddings.dimensions`, `agents.provider`, `agents.model`, `parsers` (list).

## Daemon management

```bash
ckl daemon status
ckl daemon start
ckl daemon stop                      # required before reembed / migrate-vectors
```

The daemon owns the DB lock. Heavy ops (reembed, migrate) need exclusive access — stop the daemon first.

## MCP server (stdio)

```bash
ckl mcp                              # used by Claude Desktop / Code
```

Configure your client to launch `ckl mcp` as a stdio MCP server.

## Continuous ingest

```bash
ckl watch /path/to/project --debounce 500 --pretty           # live re-index on file changes
ckl watch-session --transcript /path/to/session.jsonl --follow --pretty   # index Claude Code transcript
```

`watch-session` is useful for indexing the running agent's own transcripts as they happen.

## Crawl documentation

```bash
ckl crawl discover https://example.com/docs --pretty         # preview crawlable pages
ckl crawl index https://example.com/docs --project prj_xxx --pretty
```

`ckl crawl` often passes Cloudflare challenges where headless browsers fail — try it before reaching for puppeteer/chromium.

## CRUD admin

```bash
ckl manage project list --pretty
ckl manage project create --name "..." --pretty
ckl manage source list --pretty
ckl manage block ...                 # rare — prefer capture/edit/delete
```

## Storage migrations

Vector index v0.3.0+ uses per-project shards in `~/.ckl/data/vectors/`. Auto-migration triggers below 500k vectors; above requires confirmation.

```bash
ckl migrate-vectors --confirm                 # migrate to per-project shards
ckl migrate-vectors --force-rebuild           # rebuild index from scratch
ckl reembed --project prj_xxx --pretty        # re-compute embeddings (stop daemon first)
ckl migrate                                    # Wave-6 CAS blob store migration
ckl migrate-finalize                          # purge vlog + GC blob store
```

**Thresholds:** ≥ 5k vectors requires `--confirm`; ≥ 500k requires `CKL_MIGRATE_CONFIRM=1` env var.

## Warm shards

```bash
ckl warm --project prj_xxx --pretty           # force-load vector shards (pg_prewarm analogue)
```

Useful before a heavy search session to avoid first-query cold-start.

## Composes with

This skill is the prerequisite for the other four `ckl` skills. After running `ckl index <path>` you can use:

- **`ckl-search`** — find code and knowledge
- **`ckl-edit`** — modify code with provenance
- **`ckl-knowledge`** — capture decisions / patterns / gotchas via CIP
- **`ckl-evolve`** — Kronos cycles + audit + quality gates

## Utility Scripts

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/reindex.sh [path]    # re-index after external file changes
```

Falls back to `scripts/reindex.sh` for agents that don't expand `${CLAUDE_SKILL_DIR}`.

## `ckl status` — what it reports

```bash
ckl status --pretty
ckl status --project prj_xxx --pretty   # per-project filter
```

Fields (v0.5.3):

- `blocks: { total, by_type }` — knowledge graph blocks
- `documents`, `sources`, `projects` — counts
- **`organizations`** (v0.5.1) — count
- **`atoms: { total, by_kind: { code, claim, proof } }`** (v0.5.1) — Atom envelope counts
- `vectors: { total, on_disk, by_project }` — vector shard layout
- `daemon: { running, pid }` — daemon state

Use `atoms.by_kind.claim` to gauge how much of the graph is JTB+S-enveloped knowledge vs structural code (`code`).

## Gotchas

1. **Stop the daemon** before `reembed` or `migrate-vectors` on large thresholds: `ckl daemon stop`.
2. Vector index path: `~/.ckl/data/vectors/<project>.usearch` per project + `_orphan.usearch` for blocks without a project.
3. `ckl crawl` often beats headless browsers on Cloudflare-protected docs — try it first.
4. `ckl-config` tests are environment-dependent: `cargo test --workspace --exclude ckl-config` for clean CI.
5. `ckl index` is idempotent — re-running on the same path updates only changed files.
6. After raw text edits outside `ckl edit/write/apply`, run `ckl index <path>` so the graph reflects the new state.
7. **Daemon-lock trade-off (v0.5.2 / v0.5.3).** Most read commands are lock-free, but a few need exclusive DB access while the daemon is down: `ckl list all` (v0.5.2 enriched join), `ckl blob` default / `--info` / `--refs` modes (v0.5.3 — they touch SurrealKV for refs lookup). **Only `ckl blob OID --raw` is fully lock-free** (reads `~/.ckl/blobs/` directly via gix). If you script blob reads in a long-running pipeline, pass `--raw` to avoid contending with the daemon.
8. **CAS store path (v0.5.3):** `~/.ckl/blobs/` is gix-backed. Don't manipulate it manually — use `ckl blob list` to enumerate and `ckl migrate-finalize` to GC.
