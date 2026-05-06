---
name: ckl-knowledge
description: Use when the user wants to capture decisions/patterns/gotchas/lessons via the Capture/Intent Protocol (CIP) with the v0.5.0 JTB+S envelope (holder/kind/container), distill a block into pure-knowledge atoms (Curry-Howard tri-decomposition Code/Claim/Proof), create typed argument edges (Toulmin model — SUPPORTS, GROUNDS, WARRANT, REBUTTAL), compile a structured episode into atoms, or back up/restore the knowledge graph (export/import). Also covers the v0.5.5 atom-as-invariant pattern and the Lens / MarkdownLens bidirectional projection stack (Foster et al. 2007 well-behaved-lens law, AtomDiff, LensVerifier). AGM-grounded belief revision semantics map directly to capture/promote/resolve/archive/deprecate intents. Activate on mentions of "capture", "decision", "pattern", "gotcha", "lesson", "rationale", "why we", "argument", "evidence", "Toulmin", "AGM", "supersede", "JTB+S", "Atom", "AtomKind", "Curry-Howard", "distill", "holder", "container", "export knowledge", "Lens", "MarkdownLens", "atom-as-invariant", "AtomDiff", "round-trip", "Foster lens", or any knowledge-graph mutation.
license: Apache-2.0
compatibility: Requires `ckl` binary >= 0.5.6 on $PATH, an entity created via `ckl seed` (see ckl-evolve), and a project indexed (see ckl-system).
metadata:
  version: 0.2.3
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

Deeper material: [references/atom.md](references/atom.md) (v0.5.0 Atom + JTB+S anatomy + v0.5.5 AtomDiff), [references/cip.md](references/cip.md), [references/knowledge-types.md](references/knowledge-types.md), [references/distillation-rules.md](references/distillation-rules.md), [references/argument-relations.md](references/argument-relations.md).

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

## Atom-as-invariant pattern (v0.5.5)

Tracked as atom `blk_481254a21827_0`. Knowledge atoms are **invariant**; code, ADRs, tests, docs, and Markdown are **projections** compiled per audience.

```text
                         atom (canonical, signed, JTB+S-enveloped)
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
     Code lens            Markdown lens          Test lens
   (M2 — Rust src)       (M1 — README/ADR)      (proof harness)
```

The atom is the **source of truth**. A projection is a *view*: when a user edits the view, a `Lens::put` lifts the edit back into the atom (or rejects it as out-of-scope). This pattern is the operational core of v0.5.5 and unifies several historically separate workflows under one invariant.

**Lineage** (the pattern is not new — v0.5.5 is its first first-class CKL implementation):

- **Knuth, *Literate Programming* (1984)** — one TeX source compiles to documentation *and* compilable code (`weave` / `tangle`).
- **OMG DMN 1.1 (2014)** — decision tables are the invariant; code, docs, and audit reports are generated views.
- **Lean Mathlib `extraction` (current)** — proofs are the invariant; OCaml/Haskell code is extracted.
- **Model-Driven Engineering (MDE)** — the model is the invariant; multiple platforms are projected.

CKL's contribution is to anchor the invariant in JTB+S-signed atoms and to enforce the law via `LensVerifier::verify_round_trip`.

## Lens trait overview (v0.5.5 / v0.5.6)

Tracked as atom `blk_c0574a3ddc2e_0`. Foundation lives in the `ckl-lens` crate. **No CLI surface yet** — v0.5.5 (L1 + M1 MarkdownLens) and v0.5.6 (M2 RustLens + cross-lens projection-invariance properties) are library-level additions. Custom downstream tooling (in-app editors, sync agents) implements these traits.

Full surface — Compiler/Lens trait surface, projected-surface contract, in-tree crates table (`ckl-lens` / `ckl-lens-markdown` / `ckl-lens-rust` / `ckl-lens-tests`), worked custom-lens example, property-test patterns, and anti-patterns: **[references/lens.md](references/lens.md)**.

```rust
// ckl-lens/src/lens.rs
pub trait Compiler {
    type Target;
    fn compile(&self, atom: &Atom) -> Result<Self::Target, LensError>;
}

pub trait Lens: Compiler {
    fn put(&self, atom: &Atom, edited: &Self::Target) -> Result<AtomDiff, LensError>;
}
```

- `Compiler` is the **one-way** half (read-only views: HTML preview, dashboard rendering).
- `Lens` extends `Compiler` with `put` so edits **lift back** to an `AtomDiff`. This is the core bidirectional contract.

### Foster et al. 2007 well-behaved-lens law

Every `Lens` implementation must satisfy:

```text
put(atom, get(atom)) == identity AtomDiff
```

In words: re-projecting an atom and pushing the *unmodified* projection back through `put` must produce no change. Information leaks (`compile` drops a field that `put` cannot reconstruct) and over-eager `put` implementations (manufacturing diffs from idempotent input) both violate this law.

```rust
LensVerifier::verify_round_trip<L: Lens>(lens: &L, atom: &Atom) -> Result<(), LensError>
LensVerifier::verify_round_trip_batch<L: Lens>(lens: &L, atoms: &[Atom]) -> Result<(), LensError>
```

Use these in tests and CI to catch round-trip violations early.

### Projected-surface contract

Tracked as atom `blk_fdd6c9afb2a6_0`. The well-behaved-lens law applies **only to fields the lens projects** — non-projected fields are invariant under the lens by definition.

Concrete example: the `MarkdownLens` projects `name` and `body` to Markdown frontmatter + body. It does **not** project `confidence` or `entrenchment` — those live in the atom envelope but are not surfaced in the Markdown view. Therefore:

- ✅ Editing the projected body and pushing back produces a `Content` diff (in scope).
- ✅ Editing the title produces a `Name` diff (in scope).
- ❌ Editing confidence/entrenchment in the frontmatter is **not** diffed — it's outside the projected surface.

A lens implementation that surfaces non-projected fields and tries to `put` them back violates the contract. Document the projected surface in the lens's doc comment.

### First concrete impl: `MarkdownLens`

Tracked as atom `blk_642d5ff86b7e_0`. Lives in the `ckl-lens-markdown` crate. Projects an atom into a Markdown document (frontmatter + body) and lifts edits back.

```rust
// Conceptual usage
use ckl_lens_markdown::MarkdownLens;
use ckl_lens::{Lens, LensVerifier};

let lens = MarkdownLens::default();
let md: String = lens.compile(&atom)?;
// ... user edits md ...
let diff: AtomDiff = lens.put(&atom, &edited_md)?;

// Verify the law on a fresh round-trip
LensVerifier::verify_round_trip(&lens, &atom)?;  // Ok(()) if well-behaved
```

### `AtomDiff` variants

```rust
#[non_exhaustive]
pub enum AtomDiff {
    NoOp,                                        // identity — round-trip success
    Name { old: String, new: String },           // display-name change
    Content { old: String, new: String },        // body/projected content change
    Multi(Vec<AtomDiff>),                        // multiple field-level diffs at once
}
```

`AtomDiff::is_identity()` recursively flattens `Multi`: a `Multi` whose inner diffs are all `NoOp` is treated as identity. Use `AtomDiff::identity()` (alias for `NoOp`) when you want to be explicit.

**Foot-gun (atom `blk_6deeebb828e1_0`):** `AtomDiff::Multi(vec![])` is **vacuously identity** — `is_identity()` returns `true` because `parts.iter().all(...)` over an empty Vec is `true`. Don't rely on an empty `Multi` to mean "structural noop"; emit `AtomDiff::NoOp` (or an explicit no-op slot) when you mean "no change". Reviewers can't distinguish "I considered the change and found nothing" from "I forgot to compute the diff" if you ship `Multi(vec![])`.

`#[non_exhaustive]` means downstream code must handle the `_ => …` arm — future variants (e.g. `Holder` change, structured `Frontmatter` patch) can be added without breaking the API.

## `ckl distill` (v0.5.0 — placeholder, v0.5.6 budget-aware)

```bash
ckl distill --block blk_xxx --pretty
ckl distill --block blk_xxx --max-atoms 5 --pretty
ckl distill --block blk_xxx --budget-tokens 4000 --pretty   # v0.5.6 (D1)
```

`ckl distill` decomposes a single block into 1..N pure-knowledge atoms. **Idempotent** — `AtomId` is computed via `AtomId::from_content` (deterministic SHA over `kind|holder|content`), so re-running on the same block produces identical IDs and never duplicates.

| Flag | Effect |
|---|---|
| `--block <blk_xxx>` | Source block (required) |
| `--max-atoms N` | Hint for the LLM decomposer (default 3) |
| `--budget-tokens N` | **v0.5.6 (D1):** cap LLM token spend at `N` (>= 100). Default unlimited. On budget reached → returns the partial result + warning, never a hard error. |
| `--pretty` | Human-readable JSON |

### `--budget-tokens` (v0.5.6, D1)

Optional cap on the per-call LLM token spend driven by an `LlmTokenBudget` runtime type (separate from `ckl_search`'s `TokenBudget` — different surface, different consumer). Behaviour:

- **Default:** unlimited (no flag).
- **`>= 100`:** budget is enforced. When reached the call returns whatever atoms it has produced so far plus a warning string in the JSON envelope. Never a hard error — partial output is the success path.
- **`0..99`:** **rejected** at validation (exit code 1, `{error, code, hint}`). The lower bound exists because anything tighter is below the floor any real distillation prompt + reply needs.

Use this in batch / CI distillation jobs where a runaway prompt could otherwise drain a key. Pair with `--max-atoms` to bound both the *count* and the *cost* of a single call.

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
10. **Lens stack is library-only in v0.5.5.** No `ckl lens` CLI subcommand yet — `ckl-lens` and `ckl-lens-markdown` ship trait + first impl for downstream Rust consumers. CLI-level projection / sync commands land in a later minor. The well-behaved-lens law (`put(atom, get(atom)) == identity`) is enforced in tests via `LensVerifier::verify_round_trip`.
11. **`AtomDiff::Multi(vec![])` is vacuously identity** (atom `blk_6deeebb828e1_0`). `is_identity()` returns `true` because `all` over an empty Vec is `true`. Don't ship empty `Multi` to mean "structural noop" — emit `AtomDiff::NoOp` (or `AtomDiff::identity()`) explicitly so reviewers can tell "I considered the change" from "I forgot to compute the diff".
12. **Projected-surface contract** (atom `blk_fdd6c9afb2a6_0`): the well-behaved-lens law applies *only* to fields the lens projects. Non-projected fields (e.g. `confidence`/`entrenchment` for `MarkdownLens`) are invariant under that lens by definition — they don't appear in `AtomDiff` even if the user "edits" them in the projected frontmatter.
