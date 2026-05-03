# Setup and configuration — full reference

## Table of contents

- [Install](#install)
- [`ckl setup`](#ckl-setup)
- [`ckl auth`](#ckl-auth)
- [`ckl config`](#ckl-config)
- [`ckl index`](#ckl-index)
- [`ckl manage`](#ckl-manage)

## Install

```bash
cargo install --git https://github.com/koslab/ckl ckl-cli
```

Requires Rust toolchain. Built binary lands in `~/.cargo/bin/ckl` (or `~/.local/bin/ckl`).

Verify:
```bash
which ckl
ckl --version          # should print 0.4.9 or higher
```

## `ckl setup`

First-time onboarding wizard. Guides through:

1. Selecting the database path (default `~/.ckl/data/ckl.skv`).
2. Choosing the embeddings provider (`voyage`, `openai`, …) and model.
3. Choosing the agent provider for `reconcile` (Claude / OpenAI).
4. Authentication.
5. Optionally indexing a starter project.

```bash
ckl setup                  # interactive
ckl setup --pretty
```

Settings are persisted to `~/.ckl/settings.json`.

## `ckl auth`

```bash
ckl auth claude                    # Claude OAuth flow
ckl auth api-key <key>             # Anthropic API key
ckl auth status                    # show what's authenticated
ckl auth import                    # import from another machine
ckl auth keychain-disable          # opt out of keychain mirror
ckl auth delete                    # remove credentials
```

By default keychain mirroring is **off** (v0.4.9 phase ζ change). Enable explicitly:
```bash
ckl config set credentials.keychain_mirror true
```

## `ckl config`

```bash
ckl config get                       # show full settings.json
ckl config get embeddings.provider   # one key
ckl config set <key> <value>         # mutate
ckl config path                      # print settings.json path
ckl config get-all                   # full schema for agent introspection
```

### Common keys

| Key | Default | Notes |
|---|---|---|
| `database.path` | `~/.ckl/data/ckl.skv` | SurrealKV file |
| `database.versioning_retention_hours` | 24 | History retention |
| `embeddings.provider` | `voyage` | `voyage` or `openai` |
| `embeddings.model` | `voyage-4-large` | provider-specific |
| `embeddings.dimensions` | 1024 | Must match model |
| `agents.provider` | `anthropic` | LLM for `reconcile` |
| `agents.model` | `claude-haiku-4-5-20251001` | provider-specific |
| `agents.reconcile_budget_tokens` | 20000 | Per-job budget |
| `agents.reconcile_max_pairs` | 10 | Per-job max |
| `parsers` | `["rust","typescript","markdown","python","go"]` | Languages tree-sitter parses |
| `credentials.keychain_mirror` | `false` | OS keychain sync |

## `ckl index`

Index a project directory.

```bash
ckl index /path/to/project --pretty
ckl index /path/to/project --project prj_xxx --pretty   # explicit project
```

Idempotent. Re-running on the same path:
1. Walks the file tree (respects `.gitignore`).
2. Parses files via tree-sitter (Rust, TS, Python, Go, Markdown).
3. Computes content hash (SHA-256 via `ckl_index::content_hash`).
4. Skips unchanged files.
5. Re-parses and re-embeds changed files.
6. Updates blocks, documents, and relationships.

After indexing, `ckl-search`, `ckl-edit`, `ckl-knowledge`, `ckl-evolve` all work against this project.

## `ckl manage`

CRUD for orgs, projects, sources, blocks, relationships. Rare — prefer `capture`/`edit`/`delete` for normal flow.

```bash
ckl manage org list --pretty
ckl manage org create --name "..." --pretty
ckl manage project list --pretty
ckl manage project create --name "..." --org <org_id> --pretty
ckl manage project update <prj_id> --name "..." --pretty
ckl manage project delete <prj_id> --confirm --pretty
ckl manage source list --pretty
ckl manage source create --name "..." --project <prj_id> --pretty
ckl manage block list --project <prj_id> --pretty
ckl manage relationship create --source <src> --target <tgt> --type <kind> --pretty
```

Use `ckl manage` for:
- Creating organizations to scope multiple projects.
- Renaming a project.
- Hard-resetting a stuck source.
- Inspecting raw block listings (rarer than `ckl list blocks`).

For most knowledge graph mutations, prefer the higher-level `ckl-knowledge` skill (`capture`/`relate`/`compile`).
