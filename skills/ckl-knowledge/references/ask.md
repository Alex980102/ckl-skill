# `ckl ask` — conversational layer (v0.5.7)

`ckl ask <blk>` is ckl's third working mode: a read-only, structured introspection surface over a known block. It complements **search** (find) and **capture** (mutate) and is the first FIPA-ACL Layer 4 verb in CKL — every aspect maps to a typed speech act and the substrate replies with a structured *inform*.

This document is the canonical per-aspect reference. The high-level introduction lives in [SKILL.md § Conversational layer](../SKILL.md#conversational-layer--ckl-ask).

## Table of contents

- [FIPA-ACL Layer 4 framing](#fipa-acl-layer-4-framing)
- [Crate decomposition](#crate-decomposition)
- [`AspectKindArg` — variant ordering](#aspectkindarg--variant-ordering)
- [`AskContext` — params surface](#askcontext--params-surface)
- [Identity envelope (`default`)](#identity-envelope-default)
- [Toulmin trio — `grounds` / `warrants` / `rebuttals` / `alternatives` / `conflicts`](#toulmin-trio--grounds--warrants--rebuttals--alternatives--conflicts)
- [Lineage — `evolved` / `peers` / `used-by` / `depends-on`](#lineage--evolved--peers--used-by--depends-on)
- [Projection — `projection --as <markdown\|rust>`](#projection--projection---as-markdownrust)
- [`argumentation_debt` pedagogical loop](#argumentation_debt-pedagogical-loop)
- [Empty-bucket contract](#empty-bucket-contract)
- [`ckl ask` vs `ckl block` / `ckl context` / `ckl usages`](#ckl-ask-vs-ckl-block--ckl-context--ckl-usages)
- [Future — `ckl tell` (CONFIRM / DISCONFIRM)](#future--ckl-tell-confirm--disconfirm)

## FIPA-ACL Layer 4 framing

Tracked as atom `blk_8edc98757909_0`. CKL distinguishes four conceptual layers in the agent ↔ knowledge interaction stack:

1. **Storage** — atoms, blocks, edges (SurrealKV + gix CAS).
2. **Retrieval** — hybrid BM25 + semantic + graph (`ckl query` / `ckl search`).
3. **Mutation** — Capture/Intent Protocol (`ckl capture` / `ckl edit` / `ckl relate`).
4. **Conversation** — typed speech acts (`ckl ask`, future `ckl tell`).

Layer 4 borrows from FIPA-ACL: every utterance carries an explicit *performative* (QUERY-REF, QUERY-IF, REQUEST, INFORM, CONFIRM, DISCONFIRM …). The agent sends a typed query against a known block id; the substrate returns a structured envelope. Tracked as the third CKL working mode atom `blk_11d2d0442289_0`.

The mode contrast:

| Mode | Verb | Speech act | Direction | Best for |
|---|---|---|---|---|
| Search | `ckl search` | INFORM-REF | substrate → agent | "find me a block matching X" |
| Capture | `ckl capture` | INFORM | agent → substrate | "I assert that …" |
| **Ask** | `ckl ask <blk>` | **QUERY-REF / QUERY-IF / REQUEST** | round-trip on a known id | "what *is* this block? what backs it?" |

Use search to *locate*, ask to *understand*, capture to *commit*.

## Crate decomposition

The 11 aspects are split across four crates so each batch of work in v0.5.7 stays one-pull-request-shaped. The CLI binary depends on all four.

| Crate | Wave | Aspects | Role |
|---|---|---|---|
| `ckl-ask` | W1 (α / L3) | `default` (`IdentityAspect`) | Foundation: `AskContext`, `Signature`, `EdgeBucket`, `AspectAnswer`, `AspectHandler`, `AspectRegistry`. The other crates extend the registry — never the trait. |
| `ckl-ask-toulmin` | W2 β | `grounds`, `warrants`, `rebuttals`, `alternatives`, `conflicts` | Toulmin-model in/out edges; `register_toulmin(&mut registry)` adds all five at once. |
| `ckl-ask-lineage` | W2 γ | `evolved`, `peers`, `used-by`, `depends-on` | Block history + `Replaces` / `Supersedes` proxy + `SeeAlso` top-5 + structural usage edges. |
| `ckl-ask-projection` | W2 δ | `projection` | Wraps the v0.5.5 / v0.5.6 Lens stack. Reads `--as <target>` from `AskContext::param("target")` and routes to `MarkdownLens` (M1) or `RustLens` (M2). |

`AspectRegistry::with_builtins()` calls each crate's `register_*` exactly once. Adding a new aspect is one new crate (or one new file) + one line in `with_builtins`.

## `AspectKindArg` — variant ordering

The clap value-enum in `ckl-cli/src/main.rs` declares the variants in a deliberate order: foundation first, projection second (because it's the only aspect with a co-flag), then β grouped, then γ grouped. **Don't reorder** — clap's `--help` output mirrors the declaration order, and the canonical reading order communicates how the surface grew.

```rust
pub(crate) enum AspectKindArg {
    Default,        // α (W1) — identity envelope
    Projection,     // δ (W2) — Lens render via --as
    Grounds,        // β (W2) — Toulmin
    Warrants,
    Rebuttals,
    Alternatives,
    Conflicts,
    Evolved,        // γ (W2) — lineage
    Peers,
    UsedBy,
    DependsOn,
}
```

clap converts each PascalCase variant to kebab-case for the CLI: `Default → default`, `UsedBy → used-by`, `DependsOn → depends-on`. The internal aspect ids (in `AspectKindArg::id()`) use snake_case because that's what `AspectHandler::aspect_id()` returns: `used_by`, `depends_on`. Same surface, two delimiters; the CLI handles the translation.

## `AskContext` — params surface

```rust
pub struct AskContext<'a> {
    runtime: &'a CklRuntime,
    params: HashMap<String, String>,
}

impl<'a> AskContext<'a> {
    pub fn new(runtime: &'a CklRuntime) -> Self;
    pub fn with_param(self, key: impl Into<String>, value: impl Into<String>) -> Self;
    pub fn runtime(&self) -> &CklRuntime;
    pub fn param(&self, key: &str) -> Option<&str>;
}
```

`AskContext` is the only handle an aspect handler receives. It is **read-only** by construction: handlers reach the runtime via `ctx.runtime()` and call its read-only API surface (`get_block`, `get_context`, `find_usages`, `storage().list_atoms_by_container`, `storage().get_blocks_batch`, `storage().get_block_history`, `storage().get_relationships`). Mutations are forbidden.

Aspect-specific inputs travel through `params` as opaque `String → String` pairs. The foundation reads none of them. Today only `projection` consumes a key — `target` (matched by the public constant `ckl_ask_projection::PARAM_TARGET`). Future aspects with co-flags follow the same pattern: define a public constant for the key, document it in the handler's module doc, surface bad/missing values as `AskError::Runtime("…")`.

## Identity envelope (`default`)

The default `--aspect default` (also the implicit value when `--aspect` is omitted) returns a ~30-line JSON envelope describing the block.

**Output shape (claim-shaped block, atom persisted, missing GROUNDS):**

```json
{
  "id": "blk_xxx",
  "name": "title only — first line of block.name",
  "type": "Decision",
  "role": "leaf",
  "atom": {
    "id": "atm_aaaa",
    "kind": "claim",
    "holder": "agent-claude",
    "container": "blk_xxx",
    "layer": "medium"
  },
  "kronos": { "layer": "medium", "last_cycle": "2026-05-04T12:00:00Z" },
  "edges": {
    "structural":    { "out": { "DEPENDS_ON": 2 }, "in":  {} },
    "argumentation": { "out": {}, "in":  { "SUPPORTS": 1 } },
    "semantic":      { "out": { "SEE_ALSO": 3 },  "in":  {} },
    "temporal":      { "out": {}, "in":  { "PART_OF": 1 } }
  },
  "argumentation_summary": null,
  "neighbors_top_3": [
    { "id": "blk_yyy", "name": "…", "via": "SEE_ALSO", "direction": "out" }
  ],
  "size_hint": { "tokens": 480, "lines": 22 },
  "elapsed_ms": 4,
  "argumentation_debt": "no GROUNDS edges — consider `ckl relate <fact-id> blk_xxx --kind GROUNDS`"
}
```

**Roles** are computed from `(in_degree, out_degree, has_parent)` with a fixed priority `Root → Orphan → Hub → Chain → Leaf`. `Root` wins on `has_parent == false` regardless of degrees because it speaks to the `CONTAINS` hierarchy, not to edge counts. `Hub` triggers at `in_degree > 5`.

**Edge bucketing** (`EdgeKind` in `ckl-ask`) is load-bearing for the foundation envelope and intentionally diverges from `RelationshipCategory` — Inference and `SEE_ALSO` get their own buckets so β / γ can consume the bucketed `Signature` without re-walking edges. Unmapped relationship types fall into `Structural` so totals stay stable.

`argumentation_summary` is `null` until W3 ε populates it; it is **always present** in the envelope per the empty-bucket contract.

## Toulmin trio — `grounds` / `warrants` / `rebuttals` / `alternatives` / `conflicts`

Five aspects expose Toulmin-model edges. Each one performs at most two storage round-trips: one `get_block` + `get_context`, plus one `get_blocks_batch` to resolve neighbour names.

**Output shapes:**

```json
// --aspect grounds
{ "kind": "grounds", "id": "blk_xxx",
  "supports": [ { "id": "blk_yyy", "name": "…", "type": "Pattern", "via": "SUPPORTS",  "weight": 0.8  } ],
  "grounds":  [ { "id": "blk_zzz", "name": "…", "type": "Fact",    "via": "GROUNDS",   "weight": null } ] }

// --aspect warrants
{ "kind": "warrants", "id": "blk_xxx",
  "inbound":  [ { "via": "WARRANT", ... } ],
  "outbound": [ { "via": "WARRANT", ... } ] }

// --aspect rebuttals
{ "kind": "rebuttals", "id": "blk_xxx",
  "direct":         [ { "via": "REBUTTAL",    ... } ],
  "contradictions": [ { "via": "CONTRADICTS", ... } ] }

// --aspect alternatives  (rejected = inbound, winners = outbound)
{ "kind": "alternatives", "id": "blk_xxx",
  "rejected": [ { "via": "ALTERNATIVE_TO", ... } ],
  "winners":  [ { "via": "ALTERNATIVE_TO", ... } ] }

// --aspect conflicts
{ "kind": "conflicts", "id": "blk_xxx",
  "opposed_by":     [ { "via": "OPPOSES",     ... } ],
  "contradictions": [ { "via": "CONTRADICTS", ... } ] }
```

**Direction semantics:**

- `--aspect grounds` reads only **incoming** evidence (`SUPPORTS` / `GROUNDS`). The block under inspection is the *claim*; what backs it points *into* it.
- `--aspect warrants` exposes both directions — a warrant atom may *land on* a claim, or a claim may itself act as warrant for another claim further on.
- `--aspect rebuttals` reads incoming `REBUTTAL` and incoming `CONTRADICTS` (already typed in the graph). **Semantic** contradiction detection (negation patterns, word overlap) deliberately stays in `ckl audit --pretty` — see [argument-relations.md](argument-relations.md) and the audit reference in `ckl-evolve`.
- `--aspect alternatives` follows the canonical `ckl relate <rejected> <winning> --kind ALTERNATIVE_TO` convention — `rejected` is the inbound bucket, `winners` is the outbound bucket. Both are surfaced so the aspect is symmetric whichever side the agent stands on.
- `--aspect conflicts` overlaps with `rebuttals` by design — the same `CONTRADICTS` edge surfaces in both, framed differently. `opposed_by` is the general "contrary evidence on record"; `contradictions` is the Kronos-flavoured directional contradiction.

The five aspects close the v0.5.7 argumentation gap (motivation atom `blk_f6a8aaba62e3_0`): pre-W2, only ~0.3 % of edges in the live graph were argumentation edges. Surfacing the scaffolding makes Toulmin edges cheap to *consult*, which makes them cheap to *create*.

## Lineage — `evolved` / `peers` / `used-by` / `depends-on`

Four aspects answer the four lineage questions.

```json
// --aspect evolved (history capped at 10, newest first)
{ "kind": "evolved",
  "history": [ { "timestamp": "...", "layer": "medium", "last_cycle": "..." } ],
  "history_total": 23,
  "derived_from": [ { "id": "blk_aaa", "name": "…", "via": "Replaces",   "direction": "out" },
                    { "id": "blk_bbb", "name": "…", "via": "Supersedes", "direction": "in"  } ] }

// --aspect peers (top-5 SeeAlso by edge weight, default 0.5 if missing)
{ "kind": "peers",
  "id": "blk_xxx",
  "items": [ { "id": "blk_yyy", "name": "…", "via": "SEE_ALSO", "weight": 0.92 } ] }

// --aspect used-by (incoming structural)
{ "kind": "used_by",
  "id": "blk_xxx",
  "items": [ { "id": "blk_yyy", "via": "DEPENDS_ON" } ] }

// --aspect depends-on (outgoing structural — same edge set)
{ "kind": "depends_on",
  "id": "blk_xxx",
  "items": [ { "id": "blk_zzz", "via": "IMPORTS" } ] }
```

Notes:

- `evolved.derived_from` exposes `Replaces` / `Supersedes` edges as a proxy for Kronos `CausalEdgeType::DerivedFrom`. The temporal causal graph is entity-scoped and lives outside the regular `RelationshipType` table; future temporal-edge work will widen this surface.
- `evolved.history_total` carries the un-capped count so callers can detect a truncated view.
- `peers` and the structural pair share the same edge set: `DependsOn`, `Imports`, `Calls`, `Extends`, `Implements`. `used-by` is the in-direction; `depends-on` is the out-direction.
- **`peers` weight default is 0.5** (matches the `IdentityAspect` `neighbors_top_3` convention). `NaN` is coerced to `Equal` in the sort comparator so dirty fixtures never panic.

## Projection — `projection --as <markdown|rust>`

The projection aspect is the bridge from the conversational layer to the v0.5.5 / v0.5.6 Lens stack. It maps the FIPA-ACL **REQUEST** speech act ("renderéate como X") onto a `Compiler::compile(&atom)` call.

```json
{ "kind": "projection",
  "target": "markdown",
  "atom_id": "atm_xxx",
  "body": "---\nid: atm_xxx\n...\n---\n# Title\n\n…body…",
  "warnings": [] }
```

**`--as` targets:**

| Target | Lens | Crate | Output |
|---|---|---|---|
| `markdown` | `MarkdownLens` (M1) | `ckl-lens-markdown` | YAML frontmatter + `# title` + verbatim body |
| `rust` | `RustLens` (M2) | `ckl-lens-rust` | File-level `//!` header + `pub mod atom_<id> {}` carrying name + metadata as `///` doc lines, unparsed via `prettyplease` |

**Atom resolution.** The aspect picks the first persisted atom whose `container == blk`, ordered by `sequence` (mirrors the G3 v0.5.6 visibility rule used by the identity envelope). When no atom has been captured yet, the aspect raises an `AskError::Runtime` pointing the user to `ckl capture --container <blk>`.

**Projected-surface contract.** The aspect returns the lens's projection verbatim. It does **not** emit any field outside the lens's projected surface — anything the lens treats as read-only header (Markdown frontmatter, Rust `//!` lines) stays read-only here too. A user-visible `confidence: 0.8 → 0.95` edit in the projection round-trips as identity per the `Foster::put(atom, get(atom)) == identity` law. See [lens.md](lens.md) for the full contract.

The `warnings` array is **always present** (never omitted). Today it is always empty; reserved for future projected-surface advisories like "lens dropped non-projected field X".

**Future targets.** M3 TypeScript (`TypeScriptLens` → `Target = ts_morph::SourceFile` or similar) is on the v0.5.8 roadmap. Adding it is one new crate + one new variant in `ProjectionTargetArg` + one match arm in `ProjectionAspect::run`.

## `argumentation_debt` pedagogical loop

The default identity envelope inspects claim-shaped blocks (`block_type.is_structural() == false` — Decision, Lesson, Heuristic, Hypothesis-y types) and emits a top-level `argumentation_debt` note when the block has zero `GROUNDS` edges in either direction:

```text
"argumentation_debt": "no GROUNDS edges — consider `ckl relate <fact-id> blk_xxx --kind GROUNDS`"
```

Pedagogical workflow atom `blk_8c68386ad6f9_0`:

1. `ckl audit --pretty` reports `weak_decisions` project-wide.
2. `ckl ask <blk>` surfaces the same gap **per-block, on demand**, the moment an agent inspects the block.
3. The agent fills the gap with `ckl relate <fact-id> <blk> --kind GROUNDS` (Toulmin edge — see [argument-relations.md](argument-relations.md)).
4. Re-running `ckl ask <blk>` no longer emits `argumentation_debt`; the audit report shrinks at the next cycle.

The note exists only when applicable. Code blocks (`is_structural() == true`), claim blocks that already have GROUNDS, and structural references never see it. The exact wording will be tightened by W3 ε; the hook itself stays stable.

## Empty-bucket contract

Every aspect emits its `kind` discriminator and every documented slot — empty or not. **Empty must be visible**, never silently omitted.

- `edges.structural.in` with no edges → `{}`, not missing.
- `grounds.supports` with no edges → `[]`, not missing, not `null`.
- `argumentation_summary` pre-ε → `null`, key still present.
- `warnings` on `projection` → `[]`, key always present.

This carries the v0.5.5 M1 `Multi(vec![])` lesson (atom `blk_6deeebb828e1_0`): `Multi(vec![])` is *vacuously* identity in the Lens stack because `parts.iter().all(...)` over an empty Vec is `true`. The same logic applies upstream — downstream consumers can `is_empty()` defensively only when the slot is guaranteed present. Foundation tests (`empty_edge_bucket_serializes_as_explicit_empty_objects`) lock this in.

## `ckl ask` vs `ckl block` / `ckl context` / `ckl usages`

| Need | Use | Why |
|---|---|---|
| "What is this block? Should I dig in?" | `ckl ask <blk>` | One round-trip, structured envelope, role + edge histograms + neighbour preview + size hint |
| "Read the body of this block" | `ckl block <blk> --pretty` | Direct content read, no envelope overhead |
| "Show me every edge of this block, with full content" | `ckl context <blk> --pretty` | Symmetric edge dump (markdown or JSON) — heavier than ask |
| "Who points at this block?" | `ckl usages <blk>` or `ckl ask <blk> --aspect used-by` | `usages` returns the JSON array; `ask --aspect used-by` adds neighbour names + bucketed totals |
| "Pipe content to a tool" | `ckl block <blk>` or `ckl blob <oid> --raw` | `ckl ask` returns an envelope, not raw content — pipelines that need text use the block / blob path |
| "Find a block matching a query" | `ckl query` / `ckl search` | `ckl ask` requires a known id; the search layer handles fuzzy lookup |
| "Render the atom as Markdown / Rust" | `ckl ask <blk> --aspect projection --as markdown\|rust` | Projects through the v0.5.5 / v0.5.6 Lens stack; respects projected-surface contract |

Cross-link: the `ckl-search` skill calls out the same boundary — search to *find*, ask to *understand* (see `ckl-search/SKILL.md` "When to Use What").

## Future — `ckl tell` (CONFIRM / DISCONFIRM)

`ckl ask` covers the **query** half of the FIPA-ACL Layer 4 surface. The complementary **assertion** half — CONFIRM / DISCONFIRM speech acts an agent uses to register agreement or disagreement with a claim — is deferred to v0.5.8 as `ckl tell`. Once it ships, the speech-act table grows:

| Verb | Speech act | Direction | Effect |
|---|---|---|---|
| `ckl ask <blk> [--aspect …]` | QUERY-REF / QUERY-IF / REQUEST | round-trip | Read-only introspection (this doc) |
| `ckl tell <blk> --confirm` | CONFIRM | agent → substrate | Increment a per-holder confidence signal on the atom |
| `ckl tell <blk> --disconfirm` | DISCONFIRM | agent → substrate | Decrement confidence; surfaces in `ckl audit --pretty` |

`ckl tell` is **not** a synonym for `ckl capture` — capture *adds* an atom; tell *votes* on an existing one. The exact mechanics (whether a `CONFIRM` lifts entrenchment, whether `DISCONFIRM` triggers a cycle) will land with the v0.5.8 design; this section will be updated then.

## See also

- [SKILL.md § Conversational layer — `ckl ask`](../SKILL.md#conversational-layer--ckl-ask) — high-level orientation.
- [atom.md](atom.md) — Atom envelope (the unit `ckl ask` reports on).
- [lens.md](lens.md) — Lens stack invoked by `--aspect projection`.
- [argument-relations.md](argument-relations.md) — Toulmin edges that `--aspect grounds` / `warrants` / `rebuttals` surface.
- `ckl-evolve/SKILL.md` § Audit — project-wide `weak_decisions` view that `argumentation_debt` complements per-block.
- `ckl-search/SKILL.md` "When to Use What" — search-then-ask boundary.
