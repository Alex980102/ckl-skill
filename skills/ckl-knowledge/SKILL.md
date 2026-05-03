---
name: ckl-knowledge
description: Use when the user wants to capture decisions/patterns/gotchas/lessons via the Capture/Intent Protocol (CIP), create typed argument edges (Toulmin model — SUPPORTS, GROUNDS, WARRANT, REBUTTAL), compile a structured episode into atoms, or back up/restore the knowledge graph (export/import). AGM-grounded belief revision semantics map directly to capture/promote/resolve/archive/deprecate intents. Activate on mentions of "capture", "decision", "pattern", "gotcha", "lesson", "rationale", "why we", "argument", "evidence", "Toulmin", "AGM", "supersede", "export knowledge", or any knowledge-graph mutation.
license: Apache-2.0
compatibility: Requires `ckl` binary >= 0.4.9 on $PATH, an entity created via `ckl seed` (see ckl-evolve), and a project indexed (see ckl-system).
metadata:
  version: 0.1.0
  upstream: https://github.com/koslab/ckl
  composes-with: ckl-evolve, ckl-search
  prerequisite: ckl-system, ckl-evolve
  primary-commands: capture, observe, promote, resolve, archive, deprecate, do, knowledge, relate, compile, compile-relations, delete, export, import
---

# CKL Knowledge

Mutate the knowledge graph: capture atoms via CIP, link them with typed argument edges (Toulmin), compile structured episodes, and back up the graph. AGM 1988 belief-revision semantics map one-to-one onto CIP intents (Expansion → `Capture`, Revision → `Promote` + Supersede, Contraction → `Archive`/`Deprecate`).

**Binary:** `ckl` on `$PATH`. **Default capture path:** `ckl capture` (CIP — preferred over low-level `ckl knowledge`).

## Quick Reference

| Command | Purpose |
|---|---|
| `ckl capture --title --content --type --entity --cycle` | CIP: dedup + auto-relate + optional post-cycle (preferred) |
| `ckl observe --query --entity` | Search with `Query` nutrient tracking |
| `ckl promote --block --entity --boost` | Boost an atom's weight (validation) |
| `ckl resolve --block --title --content --supersede` | Close a gap with resolution + supersede edge |
| `ckl archive --block` | Move to Dormant layer (reversible) |
| `ckl deprecate --block` | Freeze weight at 0.0 (irreversible) |
| `ckl do <intent> [args]` | Meta-entrypoint for any CIP intent |
| `ckl knowledge --title --content --type --related` | Low-level add (use only for `--related` / `--no-auto-relate`) |
| `ckl relate <src> <dst> --kind <KIND>` | Typed argument edge (Toulmin or structural) |
| `ckl compile --content --entity` | 5-phase episode pipeline (parse → extract → dedup → contradiction → emit) |
| `ckl compile-relations` | Batch-create edges from JSON |
| `ckl delete block blk_xxx --confirm` | Hard-delete graph node |
| `ckl export --output backup.json` | Dump graph to JSON |
| `ckl import --input backup.json` | Restore from JSON |

Deeper material: [references/cip.md](references/cip.md), [references/knowledge-types.md](references/knowledge-types.md), [references/distillation-rules.md](references/distillation-rules.md), [references/argument-relations.md](references/argument-relations.md).

## Capture (default path: CIP)

```bash
ckl capture \
  --title "SurrealKV MVCC prevents write conflicts in concurrent indexing" \
  --content "Single-line paragraph explaining the fact, stand-alone." \
  --type decision \
  --project prj_xxx --entity entity_ckl \
  --cycle --pretty
```

`ckl capture` runs CIP: auto-dedup + auto-relate + optional `--cycle` post-evolution. Always scope with `--project` and `--entity`, otherwise the atom is orphaned.

## `capture` vs `knowledge` vs `compile`

| Command | When |
|---|---|
| `ckl capture` (CIP, **preferred**) | One atom + auto-dedup + auto-relate + optional `--cycle`. |
| `ckl knowledge` | Low-level. Same effect, no CIP guarantees. Use only for `--related blk_a,blk_b` or `--no-auto-relate`. |
| `ckl compile` | Structured episode (markdown with headings). 5-phase pipeline: parse → extract → dedup → contradiction → emit. |

## Distillation Rules

Distill, don't transcribe. Extract durable insights only.

**WHAT to compile:** decisions with rationale, recurring patterns, gotchas/lessons, architecture facts, rules, processes.
**WHAT NOT to compile:** trivial edits, raw tool-call output, "Done"/"Fixed" confirmations, session debug narrative, diff descriptions, open questions without answers.

- Max 1–3 atoms per episode. Precision > recall. Most responses compile nothing.
- Search first: `ckl search "<title terms>" --format compact`. Skip if it already exists.
- Titles must be searchable with tech / component names:
  - GOOD: "Drizzle ORM requires WAL mode for concurrent reads"
  - BAD: "Database finding"
- Content is plain paragraphs. **Never use `##` sub-headings** — they create child blocks with generic names.
- One atom = one atomic idea. Multiple ideas → multiple atoms.
- Always scope: `--project` + `--entity` on every call.

Full rule set: [references/distillation-rules.md](references/distillation-rules.md).

## Knowledge Types — canonical (22) vs CLI-exposed (12)

CLI emits 12 of the 22 canonical types. Map absent canonical types to the closest exposed type:

| Canonical | Use |
|---|---|
| `tradeoff` | `decision` |
| `antipattern` | `gotcha` |
| `postmortem` | `lesson` |
| `constraint`, `heuristic`, `meta-rule`, `cue` | `rule` |
| `code`, `exemplar` | `pattern` |
| `case` | `fact` |
| `mental-model` | `concept` |

**4-question heuristic:**

- What exists? → `fact` / `entity` / `concept`
- How to do it? → `process` / `operation` / `pattern` / `rule`
- A choice made? → `decision` / `assumption`
- Something learned? → `lesson` / `gotcha`
- Not sure? → `question`

Full taxonomy with examples: [references/knowledge-types.md](references/knowledge-types.md).

## Argument Relations (Toulmin model)

Six edges turn `decision` atoms into traceable claims instead of unbacked text:

| Kind | Use |
|---|---|
| `SUPPORTS` | A `fact` / `pattern` / `rule` provides positive evidence |
| `OPPOSES` | Contrary evidence |
| `ALTERNATIVE_TO` | Option considered but not chosen (target = winning decision) |
| `GROUNDS` | Toulmin: data the claim rests on |
| `WARRANT` | Toulmin: rule connecting grounds → claim |
| `REBUTTAL` | Toulmin: condition that would invalidate the claim |

```bash
ckl relate blk_fact_xxx blk_decision_yyy --kind SUPPORTS \
  --reason "benchmarks show 3× speedup"
ckl relate blk_dec_a   blk_dec_b         --kind ALTERNATIVE_TO \
  --reason "rejected: too slow"
ckl relate blk_rule_x  blk_decision_yyy  --kind WARRANT \
  --reason "principle: prefer composition"
```

`ckl audit --pretty` (in `ckl-evolve`) flags `weak_decisions`: claims without `GROUNDS`/`SUPPORTS`, or backed but missing `WARRANT`/`REBUTTAL`.

Full pattern catalog: [references/argument-relations.md](references/argument-relations.md).

## CIP intents map to AGM 1988

The Capture/Intent Protocol is the operational surface of the AGM belief-revision framework:

| AGM operation | CIP intent | Effect |
|---|---|---|
| Expansion | `Capture` | Add a belief, no consistency check |
| Revision | `Promote` + `Supersedes` edge | Add a belief, retract what conflicts |
| Contraction | `Archive` / `Deprecate` | Retract a belief while preserving lineage |

`ckl resolve --block <gap> --supersede` is the canonical revision shortcut: creates a resolution atom and the `SUPERSEDES` edge in one call.

Full protocol: [references/cip.md](references/cip.md).

## Backup & restore

```bash
ckl export --output backup.json                # full graph dump
ckl import --input backup.json --pretty        # restore from JSON
```

Use before storage migrations or to share a graph across machines.

## Composes with

This skill is one of five `ckl` skills. Use it together with:

- **`ckl-system`** — prerequisite: index the project, configure `entity`/`project` scope
- **`ckl-evolve`** — prerequisite: `ckl seed --entity` creates the entity. Run `ckl cycle` after captures or use `--cycle` flag
- **`ckl-search`** — search before capture to avoid duplicates (`ckl search <terms> --format compact`)
- **`ckl-edit`** — capture the rationale of a change made via `ckl edit/write/apply`

## Gotchas

1. CLI emits only 12 of 22 canonical knowledge types. Use the mapping table above.
2. Content for `capture`/`knowledge` must be plain paragraphs. `##` sub-headings create fragmented child blocks with generic names.
3. `ckl capture --cycle` runs the evolution cycle in the same call — no need for a separate `ckl cycle`.
4. `ckl capture` does NOT accept `--related`. Use `ckl knowledge --related blk_a,blk_b` at creation, or `ckl relate <src> <dst> --kind <KIND>` afterward.
5. Always scope with `--project` and `--entity`. Without them atoms are orphaned and `ckl audit` will flag them.
6. `ckl deprecate` is **irreversible** without manual fix. Use `ckl archive` if you might want it back.
