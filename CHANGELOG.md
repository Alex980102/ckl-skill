# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.2] - 2026-05-05

Sync release. Bumps every skill from `ckl >= 0.5.3` to `ckl >= 0.5.5`, picking
up two new upstream ckl minor releases (v0.5.4 Blob Reverse Index, v0.5.5
Lens Foundation). All five skills aligned to the same `metadata.version: 0.2.2`
(including `ckl-search` which jumps 0.2.1 → 0.2.2). No breaking changes to
skill structure — same five skills, same composition.

### Added

- **`ckl-knowledge`** (largest update — v0.5.5 Lens stack)
  - **Atom-as-invariant pattern** (atom `blk_481254a21827_0`): atoms are
    canonical; code, ADRs, tests, docs, Markdown are projections compiled
    per audience. Lineage: Knuth Literate Programming → OMG DMN 2014 →
    Lean Mathlib extraction → MDE.
  - **Lens trait overview** (atom `blk_c0574a3ddc2e_0`): `Compiler` /
    `Lens` traits in `ckl-lens`; Foster et al. 2007 well-behaved-lens law
    `put(atom, get(atom)) == identity`; `LensVerifier::verify_round_trip`
    and `verify_round_trip_batch`.
  - **Projected-surface contract** (atom `blk_fdd6c9afb2a6_0`): the law
    applies only to projected fields — non-projected fields (e.g.
    confidence/entrenchment in Markdown frontmatter) are invariant under
    the lens by definition and are not diffed.
  - First concrete impl: **`MarkdownLens`** in `ckl-lens-markdown` (atom
    `blk_642d5ff86b7e_0`).
  - **`AtomDiff` variants section** (`NoOp` / `Name` / `Content` /
    `Multi`) with identity-flatten semantics and `#[non_exhaustive]` note.
  - Foot-gun: `AtomDiff::Multi(vec![])` is vacuously identity (atom
    `blk_6deeebb828e1_0`) — emit explicit `NoOp` instead.
  - `references/atom.md` extended with the AtomDiff section + cross-link
    to the SKILL.md Lens overview.
  - `description` and triggers extended with "Lens", "MarkdownLens",
    "atom-as-invariant", "AtomDiff", "round-trip", "Foster lens".

- **`ckl-search`** (v0.5.4 reverse-index updates)
  - Blob mode table now shows complexity column (`O(log N + k)` for
    default / `--info` / `--refs` post-v0.5.4).
  - New `ckl blob reindex --pretty` example (one-shot back-fill on
    upgrade from v0.5.3).
  - Note that `ckl blob list` is paginated with sorted-hex order and
    each item carries `refs_count`; pack-aware enumeration is a v0.5.4
    follow-up still pending.
  - **Testing/migration helper** section: `ckl manage block create
    --blob-oid <hex>` (B3) — explicit `blob_oid` for end-to-end tests
    of the reverse index. Cross-linked from `ckl-edit`.
  - `references/blob.md` updated: complexity column, daemon-lock
    section rewritten around the reverse-index speedup, new
    `ckl blob reindex` subsection.

- **`ckl-system`**
  - "What's new" matrix extended with `v0.5.4` (Blob Reverse Index)
    and `v0.5.5` (Lens Foundation).
  - Gotcha 7 rewritten: post-v0.5.4 all `ckl blob` modes are
    O(log N + k); only writes (capture/edit/`ckl blob reindex`) still
    need `ckl daemon stop` for heavy jobs.
  - New gotcha 9: one-shot `ckl blob reindex` after upgrade from v0.5.3.
  - `references/migrations.md` — new section "v0.5.4 —
    `blocks_by_blob_oid` reverse index back-fill" + new section "v0.5.5
    — Lens crates (no migration)" stating no on-disk format changes.

- **`ckl-edit`**
  - New gotcha 6: `ckl manage block create --blob-oid` testing/migration
    helper. Cross-link to `ckl-search` `references/blob.md` for the
    daemon-lock matrix.

### Changed

- All five SKILL.md frontmatter `compatibility: Requires ckl binary >= 0.5.5`.
- All five SKILL.md `metadata.version: 0.2.2` (including `ckl-search`,
  which had been 0.2.1 — now aligned).
- `skills/ckl-search/scripts/project-status.sh` requires `ckl >= 0.5.5`
  (was `>= 0.4.9`).
- `skills/ckl-system/scripts/reindex.sh` requires `ckl >= 0.5.5`
  (was `>= 0.4.9`).
- `template/SKILL.md` sample compatibility bumped to `ckl >= 0.5.5`.
- `README.md`: prerequisites bumped to `ckl >= 0.5.5`; "What's new"
  matrix extended with v0.5.4 and v0.5.5 rows.

### Targets

- `ckl` binary >= 0.5.5 on `$PATH`.

### Notes

- No breaking changes to skill structure (5 skills, same composition).
- Lens stack ships as library-only in v0.5.5 (`ckl-lens`,
  `ckl-lens-markdown` crates) — no `ckl lens` CLI subcommand. Future
  minors may add CLI projection / sync commands.
- v0.5.4 reverse-index requires a one-shot `ckl blob reindex --pretty`
  after upgrading from v0.5.3 to populate the index for legacy blocks.
  New writes maintain it inline.

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

[0.2.2]: https://github.com/koslab/ckl-skill/releases/tag/v0.2.2
[0.2.1]: https://github.com/koslab/ckl-skill/releases/tag/v0.2.1
[0.2.0]: https://github.com/koslab/ckl-skill/releases/tag/v0.2.0
[0.1.0]: https://github.com/koslab/ckl-skill/releases/tag/v0.1.0
