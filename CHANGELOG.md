# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - 2026-05-05

Documentation hotfix for `ckl-search`. Adds guidance for the retrieval gap on
short structured-ID queries (atom `blk_2307b35fa77f_0`, v0.5.4 backlog B5).

### Added

- **`ckl-search`**
  - New `references/query-flags.md` § "When `ckl search` beats `ckl query`":
    explains why short structured IDs (`B4`, `M1`, `v0.5.4`) get drowned by
    vector similarity in `ckl query` and recommends `ckl search` (BM25-leaning).
  - New gotcha #9 in `SKILL.md` cross-referencing the new section.

### Changed

- `ckl-search` skill `metadata.version`: 0.2.0 → 0.2.1.

## [0.2.0] - 2026-05-04

Sync release. Bumps every skill from `ckl >= 0.4.9` to `ckl >= 0.5.3`, picking
up four upstream ckl minor releases (v0.5.0 Atomic Knowledge, v0.5.1 Scoped
Search II, v0.5.2 Agent-First Discovery, v0.5.3 Direct Blob Access). No
breaking changes to skill structure — same five skills, same composition.

### Added

- **`ckl-knowledge`**
  - JTB+S envelope on `ckl capture`: new `--holder` / `--kind` / `--container`
    flags. Holder cascade (explicit > `$CKL_DEFAULT_HOLDER` > entity-derived
    > `unsigned`).
  - `AtomKind` (Curry-Howard tri-decomposition: `Code` / `Claim` / `Proof`).
  - `ckl distill --block <blk_xxx> [--max-atoms N]` (v0.5.0 placeholder).
    Idempotent via `AtomId::from_content`.
  - **NEW reference:** `references/atom.md` — Atom anatomy, JTB+S, AtomKind,
    AtomId determinism (`free_form` vs `from_content`), holder cascade.
  - Updated `references/cip.md` and `references/distillation-rules.md` with
    the v0.5.0 envelope.

- **`ckl-search`** (largest update)
  - Scoped search section: `--org` / `--project` / `--source-id` / `--holder`
    / `--kind` / `--container` filters across `query` / `search` / `list` /
    `audit`.
  - Cross-entity discovery: `ckl list all` (v0.5.2) with `--query` and
    `--type` CSV (`organizations|orgs`, `projects|prjs`, `sources|srcs`,
    `documents|docs`).
  - Native scope resolvers: `--project-query` / `--org-query` /
    `--source-query` (v0.5.2) — substring → ID with 0/N error semantics.
  - Direct blob access: `ckl blob OID` (default / `--raw` / `--info` /
    `--refs`) + `ckl blob list`.
  - New patterns: scoped query workflow (Org → Project → Block → Atom);
    discovery + scope in one shot; inspecting blob OIDs from logs/audit.
  - **NEW reference:** `references/blob.md` — gix-backed CAS layout, modes,
    daemon-lock caveat (only `--raw` is lock-free).
  - Updated `references/query-flags.md` and `references/navigate.md` with
    all v0.5.1+ filters and resolvers.
  - `ckl list` targets extended: `all`, `organizations`, `atoms`, `entities`.

- **`ckl-evolve`**
  - Severity-graded `weak_decisions` (v0.5.0): High (missing `GROUNDS` or
    `holder=None`), Medium (missing `WARRANT`), Low (missing `REBUTTAL`).
  - `atom_coverage` metric (v0.5.1) with healthy threshold `0.7`.
  - `ckl audit --persist-findings` (v0.5.1) — persists findings as `Claim`
    atoms held by synthetic agent `ckl-auditor` (idempotent).
  - `ckl audit --exclude-low` (v0.5.0), `--include-walton` (v0.5.0
    placeholder), `--project` / `--project-query` for scoped audit.
  - JTB+S enforcement: `holder=None` → severity High; `ckl capture` warns
    to stderr when falling back to `unsigned`.
  - Updated `references/audit.md` and `references/quality-gates.md`.

- **`ckl-system`**
  - `ckl status --pretty` now reports `organizations` count and
    `atoms.{total, by_kind: {code, claim, proof}}` (v0.5.1).
  - Daemon-lock trade-off documented: `ckl list all` and `ckl blob`
    default / `--info` / `--refs` modes briefly hold the SurrealKV lock;
    only `ckl blob OID --raw` is fully lock-free.
  - `~/.ckl/blobs/` (v0.5.3 gix-backed CAS) added to layout reference.
  - `references/migrations.md` — `StoragePort` trait amendment migration
    note (v0.5.0 L1b) for out-of-tree backend implementors.

- **`ckl-edit`**
  - Compatibility bump only. File-ops surface (`edit` / `write` / `apply` /
    `mv` / `mkdir` / `rm` / `session`) is unchanged from v0.4.x.

- **Top-level**
  - README target version raised to `ckl >= 0.5.3` with a per-release
    "What's new" matrix.
  - `template/SKILL.md` sample frontmatter version bumped.

### Changed

- All five SKILL.md frontmatter `compatibility: Requires ckl binary >= 0.5.3`.
- All five SKILL.md `metadata.version: 0.2.0`.
- `ckl-knowledge` `primary-commands` adds `distill`.
- `ckl-search` `primary-commands` adds `blob`.

### Targets

- `ckl` binary >= 0.5.3 on `$PATH`.

### Notes

- No breaking changes to skill structure (5 skills, same composition).
- 60+ ckl subcommands — coverage extended to v0.5.3 surface (Atom / scoped
  search / list all / `--*-query` / blob).
- Apache-2.0 license.

## [0.1.0] - 2026-05-03

Initial release. Five focused Agent Skills for the CKL Rust knowledge engine,
following the [Agent Skills](https://skill.md) open standard with spec-compliant
frontmatter (`name`, `description`, `license`, `compatibility`, `metadata`).

### Added

- **`ckl-system`** — prerequisite skill: install, index a project, configure
  auth, manage the daemon, MCP server, crawl docs, run storage migrations.
  References: `setup.md`, `daemon.md`, `ingest.md`, `migrations.md`.
  Scripts: `reindex.sh`.
- **`ckl-search`** — find code & navigate the knowledge graph (hybrid BM25 +
  semantic + graph search, traversal, project overview, list resources).
  References: `query-flags.md`, `navigate.md`. Scripts: `project-status.sh`.
- **`ckl-edit`** — modify code with provenance (`edit`, `write`, `apply`,
  `mv`, `mkdir`, `rm`, `session`). All edits emit `Edit` nutrients.
  References: `file-ops.md`, `session.md`.
- **`ckl-knowledge`** — capture knowledge via the Capture/Intent Protocol
  (CIP), create typed argument edges (Toulmin: `SUPPORTS`, `GROUNDS`,
  `WARRANT`, `REBUTTAL`, …), compile structured episodes, export/import
  the graph. AGM-grounded belief revision semantics.
  References: `cip.md`, `knowledge-types.md`, `distillation-rules.md`,
  `argument-relations.md`.
- **`ckl-evolve`** — Kronos temporal evolution (`cycle`, `health`, `seed`,
  `history`, `ingest`, `backfill`, `graduate`), audit (`audit`, `reconcile`,
  `clean`).
  References: `kronos.md`, `audit.md`, `quality-gates.md`.
- Repo-level `template/SKILL.md` skeleton for authoring new skills with
  spec-compliant frontmatter.

### Targets

- `ckl` binary >= 0.4.9 on `$PATH`.

### Notes

- 60+ ckl subcommands distributed across five skills with zero overlap.
- Each `SKILL.md` includes a `Composes with` section so multi-skill flows
  are explicit (e.g. `ckl-search` → `ckl-edit` → `ckl-knowledge`).
- Apache-2.0 license.

[0.2.0]: https://github.com/koslab/ckl-skill/releases/tag/v0.2.0
[0.1.0]: https://github.com/koslab/ckl-skill/releases/tag/v0.1.0
