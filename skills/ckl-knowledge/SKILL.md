---
name: ckl-knowledge
description: Use when the user wants to capture decisions/patterns/gotchas/lessons via the Capture/Intent Protocol (CIP) with the v0.5.0 JTB+S envelope (holder/kind/container), distill a block into pure-knowledge atoms (Curry-Howard tri-decomposition Code/Claim/Proof), create typed argument edges (Toulmin model — SUPPORTS, GROUNDS, WARRANT, REBUTTAL), compile a structured episode into atoms, or back up/restore the knowledge graph (export/import). AGM-grounded belief revision semantics map directly to capture/promote/resolve/archive/deprecate intents. Activate on mentions of "capture", "decision", "pattern", "gotcha", "lesson", "rationale", "why we", "argument", "evidence", "Toulmin", "AGM", "supersede", "JTB+S", "Atom", "AtomKind", "Curry-Howard", "distill", "holder", "container", "export knowledge", or any knowledge-graph mutation.
license: Apache-2.0
compatibility: Requires `ckl` binary >= 0.5.3 on $PATH, an entity created via `ckl seed` (see ckl-evolve), and a project indexed (see ckl-system).
metadata:
  version: 0.2.0
  upstream: https://github.com/koslab/ckl
  composes-with: ckl-evolve, ckl-search
  prerequisite: ckl-system, ckl-evolve
  primary-commands: capture, distill, observe, promote, resolve, archive, deprecate, do, knowledge, relate, compile, compile-relations, delete, export, import
---

# CKL Knowledge

Mutate the knowledge graph: capture atoms via CIP, link them with typed argument edges (Toulmin), compile structured episodes, and back up the graph. AGM 1988 belief-revision semantics map one-to-one onto CIP intents (Expansion → `Capture`, Revision → `Promote` + Supersede, Contraction → `Archive`/`Deprecate`).

**Binary:** `ckl` on `$PATH`. **Default capture path:** `ckl capture` (CIP — preferred over low-level `ckl knowledge`).

## Quick Reference

| Command | Purpose |
|---|---|
| `ckl capture --title --content --type --entity --cycle` | CIP: dedup + auto-relate + optional post-cycle (preferred) |
| `ckl capture ... --holder --kind --container` | v0.5.0: attach JTB+S envelope (signer + AtomKind + container block) |
| `ckl distill --block blk_xxx [--max-atoms N]` | v0.5.0: decompose a block into pure-knowledge atoms (idempotent via `AtomId::from_content`). Currently a placeholder mirror; v0.5.x+ plugs in LLM decomposition. |
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

Deeper material: [references/atom.md](references/atom.md) (v0.5.0 Atom + JTB+S anatomy), [references/cip.md](references/cip.md), [references/knowledge-types.md](references/knowledge-types.md), [references/distillation-rules.md](references/distillation-rules.md), [references/argument-relations.md](references/argument-relations.md).

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

## JTB+S envelope (v0.5.0)

ckl 0.5.0 wraps every captured atom in an envelope inspired by the **Justified True Belief + Source** epistemic schema. Three new flags on `ckl capture` (and any CIP intent) attach the envelope:

| Flag | Field | Meaning |
|---|---|---|
| `--holder <id>` | `holder` | The agent/principal asserting the atom (`agent-claude`, `user-alice`, `ckl-auditor`). Without it, atoms are recorded `unsigned` and audited as severity-High weak decisions. |
| `--kind <code\|claim\|proof>` | `AtomKind` | Curry-Howard category — see below. Defaults from `BlockType::is_structural()` (structural → `code`, knowledge → `claim`). |
| `--container <blk_xxx>` | `container` | The containing block. `None` = top-level atom. Use to nest atoms inside a function/section/document. |

```bash
ckl capture \
  --title "Daemon holds DB lock during MCP proxy — stop before reembed" \
  --content "..." \
  --type gotcha \
  --kind claim --holder agent-claude \
  --container blk_daemon_overview \
  --project prj_xxx --entity entity_ckl --pretty
```

**Holder cascade** (first match wins):

1. Explicit `--holder <id>`
2. `$CKL_DEFAULT_HOLDER` env var
3. Entity-derived holder (from `entity.principal_holder`)
4. `unsigned` (and stderr warning)

Set `CKL_DEFAULT_HOLDER` once per session to avoid passing `--holder` on every call:

```bash
export CKL_DEFAULT_HOLDER=agent-claude
ckl capture --title "..." --content "..." --type decision  # holder=agent-claude
```

## AtomKind — Curry-Howard tri-decomposition (v0.5.0)

The Curry-Howard correspondence (programs ≡ proofs) splits knowledge into three primitive kinds:

| `AtomKind` | What it is | Typical block types | Example |
|---|---|---|---|
| `code` | Executable structure (the *program*) | function, struct, module, fact | a `fn` declaration; `vector_dim = 1024` |
| `claim` | Asserted knowledge (the *proposition*) | decision, pattern, gotcha, rule, lesson | "MVCC prevents write conflicts"; "always pass --reason" |
| `proof` | Justification of a claim (the *derivation*) | grounded reasoning, benchmarks, formal arguments | "benchmarks at /bench/x.rs show 3× speedup" linked via `GROUNDS` |

Defaults: structural blocks (functions, types, files) → `code`; knowledge blocks (decisions, gotchas) → `claim`. Override with `--kind proof` when you capture an atom whose role is to back another claim.

`ckl status --pretty` reports `atoms.by_kind: { code, claim, proof }` so you can see the shape of your graph at a glance.

## `ckl distill` (v0.5.0 — placeholder)

```bash
ckl distill --block blk_xxx --pretty
ckl distill --block blk_xxx --max-atoms 5 --pretty
```

`ckl distill` decomposes a single block into 1..N pure-knowledge atoms. **Idempotent** — `AtomId` is computed via `AtomId::from_content` (deterministic SHA over `kind|holder|content`), so re-running on the same block produces identical IDs and never duplicates.

| Flag | Effect |
|---|---|
| `--block <blk_xxx>` | Source block (required) |
| `--max-atoms N` | Hint for the LLM decomposer (default 3) |
| `--pretty` | Human-readable JSON |

**v0.5.0 status:** placeholder. Returns a single mirror atom (the input block, copied as a `claim`) plus a warning. v0.5.x+ plugs in real LLM-driven 1:N decomposition. Use it now to pre-allocate the workflow — when the real decomposer ships your scripts will benefit automatically.

When to distill:

- A long block mixes a decision with multiple supporting facts → split into one `claim` + several `proof` atoms.
- Migrated pre-v0.5.0 blocks need explicit `Atom` envelopes to lift `atom_coverage`.
- Audit reports a block with high token count and severity-Medium weak decision (no WARRANT) — distillation often surfaces the missing rule.

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
7. **`--holder` on every capture (v0.5.0).** Without it the atom is recorded `unsigned` and audited as a severity-High weak decision. Set `$CKL_DEFAULT_HOLDER=agent-<name>` once per session as a safety net.
8. **`AtomId::from_content` is deterministic.** `ckl distill` re-runs on the same block produce identical IDs — never duplicates. Free-form `AtomId` (when you mint one programmatically) is **not** automatically deduped against `from_content` IDs; prefer `from_content` unless you have a reason.
9. `ckl distill` in v0.5.0 is a **placeholder** — it returns a single mirror atom + warning. Real LLM decomposition lands in a future minor. Scripts can adopt the flag now safely.
