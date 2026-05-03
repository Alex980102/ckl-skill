# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.1.0]: https://github.com/koslab/ckl-skill/releases/tag/v0.1.0
