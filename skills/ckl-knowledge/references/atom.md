# `Atom` — anatomy, JTB+S, AtomKind, AtomId (v0.5.0)

`Atom` is the v0.5.0 envelope for every unit of knowledge in ckl. It wraps the legacy `Block` content with a Justified-True-Belief + Source schema, a Curry-Howard kind, and a deterministic content-addressable ID.

## Table of contents

- [Why an envelope](#why-an-envelope)
- [Atom anatomy](#atom-anatomy)
- [JTB+S — holder, kind, container](#jtbs--holder-kind-container)
- [AtomKind — Curry-Howard tri-decomposition](#atomkind--curry-howard-tri-decomposition)
- [AtomId — `free_form` vs `from_content`](#atomid--free_form-vs-from_content)
- [Holder cascade](#holder-cascade)
- [Querying atoms](#querying-atoms)

## Why an envelope

Pre-v0.5.0 blocks were unsigned propositions: a `decision` block could exist with no record of *who* asserted it, *what kind* of knowledge it represented, or *what containing context* it lived in. This made audit hard and made aggregation across agents/users impossible.

v0.5.0 fixes this by lifting every block into an `Atom` carrying:

- A **holder** (signer / asserter)
- A **kind** (Curry-Howard category: code/claim/proof)
- A **container** (parent block, optional)
- A **deterministic ID** (idempotent re-derivation)

Existing blocks gain a default envelope on first access (lazy upgrade). New captures take the envelope explicitly via `--holder` / `--kind` / `--container` on `ckl capture`.

## Atom anatomy

```text
Atom {
  id:          AtomId,          // free-form OR from_content (see below)
  block_id:    BlockId,         // legacy block this envelopes (1:1 in v0.5.0)
  kind:        AtomKind,        // code | claim | proof
  holder:      Option<HolderId>,// agent/principal id, e.g. "agent-claude"
  container:   Option<BlockId>, // None = top-level atom
  content:     Bytes,           // canonical content (from CAS blob, v0.5.3)
  created_at:  TimestampMicros,
  updated_at:  TimestampMicros,
}
```

- `block_id` is a 1:1 link in v0.5.0. v0.5.x+ may relax to 1:N (one block → many atoms via `ckl distill`).
- `content` lives in the gix-backed CAS blob store (`~/.ckl/blobs/`, v0.5.3). Reach it directly via `ckl blob OID`.

## JTB+S — holder, kind, container

The envelope formalises three independent dimensions of every atom:

| Dimension | Field | Role | Failure mode |
|---|---|---|---|
| Source / signer | `holder` | "Who claims this?" | `holder=None` → severity-High weak_decision (audit). |
| Justification class | `AtomKind` | "What *kind* of knowledge is this?" | Wrong kind → atom won't surface in `--kind <k>` filtered queries. |
| Context | `container` | "Where does it live?" | Missing container = top-level atom (legitimate but uncontextualized). |

The **+ Source** half of JTB+S is the contribution beyond classical Justified True Belief: it forces every belief to be signed. Unsigned beliefs are not first-class — `ckl audit` will flag them.

## AtomKind — Curry-Howard tri-decomposition

```text
enum AtomKind { Code, Claim, Proof }
```

The Curry-Howard isomorphism says programs ≡ proofs. ckl reifies this with three primitive atom kinds:

| Kind | What it is | Typical block types | Example |
|---|---|---|---|
| `Code` | Executable structure — the *program* / type | function, struct, module, fact | a `fn` declaration; `dim = 1024` constant |
| `Claim` | Asserted proposition — the *judgement* | decision, pattern, gotcha, rule, lesson | "MVCC prevents write conflicts in concurrent indexing" |
| `Proof` | Justification of a claim — the *derivation* | benchmark logs, formal arguments, grounded examples | "Benchmarks at `/bench/x.rs` show 3× speedup" linked via `GROUNDS` |

**Default kind from `BlockType::is_structural()`:**

- structural → `Code` (functions, types, modules, files)
- non-structural → `Claim` (decisions, patterns, gotchas, …)

Override with `--kind proof` when capturing an atom whose role is to back another claim. The Toulmin edges (`GROUNDS`, `WARRANT`, `REBUTTAL`) compose with kinds: a typical argument is `Proof --GROUNDS--> Claim` with a `Claim --WARRANT--> Claim` edge from the inference rule.

## AtomId — `free_form` vs `from_content`

`AtomId` has two construction paths:

```rust
AtomId::free_form(s: &str) -> AtomId             // arbitrary string id
AtomId::from_content(kind, holder, content)      // SHA over canonical envelope
```

| Path | When | Determinism |
|---|---|---|
| `free_form` | Programmatic capture where you control the namespace | None — caller responsible for uniqueness |
| `from_content` | All `ckl capture` and `ckl distill` invocations | **Idempotent.** Same `(kind, holder, content)` → same ID, always. |

`from_content` enables idempotent operations:

- **Re-running `ckl distill`** on the same block produces the same atom IDs — no duplicates.
- **Re-running `ckl audit --persist-findings`** on the same finding produces the same `Claim` atom — no duplicates.
- **Replaying a session log** of captures produces the same graph.

⚠ `free_form` IDs are **not** auto-deduped against `from_content` IDs. If you mint atoms programmatically, prefer `from_content` unless you have a reason to namespace them externally.

## Holder cascade

`ckl capture` resolves `holder` in this order (first match wins):

1. **Explicit `--holder <id>`** — always wins. Use for cross-agent captures.
2. **`$CKL_DEFAULT_HOLDER` env var** — session-level safety net. Set once at agent boot.
3. **Entity-derived holder** — if the entity was seeded with `principal_holder`, atoms inherit it.
4. **`unsigned`** — terminal fallback. Captures still succeed but emit a stderr warning, and `ckl audit` flags the resulting atom as severity-High.

Example:

```bash
export CKL_DEFAULT_HOLDER=agent-claude
ckl capture --title "..." --content "..." --type decision --entity entity_ckl
# atom.holder = "agent-claude"

ckl capture --title "..." --content "..." --type fact --entity entity_ckl --holder user-alice
# atom.holder = "user-alice" (explicit wins)
```

## Querying atoms

The list / search / query commands expose Atom-aware filters:

```bash
# List all atoms by kind/holder/container
ckl list atoms --kind claim --pretty
ckl list atoms --holder ckl-auditor --kind claim --pretty
ckl list atoms --container blk_daemon_overview --pretty
ckl list atoms --project prj_xxx --kind proof --pretty

# Filter search results to atoms with a specific envelope
ckl query "MVCC" --kind claim --holder agent-claude --enriched --pretty
ckl search "lock contention" --kind code --container blk_daemon_overview --pretty
```

`ckl status --pretty` reports the global Atom shape:

```json
"atoms": {
  "total": 412,
  "by_kind": { "code": 280, "claim": 120, "proof": 12 }
}
```

A graph dominated by `code` and starved of `proof` is a sign that decisions are being captured (`claim`) without backing (`proof` linked via `GROUNDS`). Use `ckl audit --pretty` to find the specific weak decisions.

## See also

- [cip.md](cip.md) — capture envelope is part of every CIP intent
- [argument-relations.md](argument-relations.md) — Toulmin edges compose with `AtomKind`
- [distillation-rules.md](distillation-rules.md) — `ckl distill` workflow and content rules
- [../../ckl-search/references/blob.md](../../ckl-search/references/blob.md) — `ckl blob OID` reads atom content from the CAS store
