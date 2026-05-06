# Lens stack — `Compiler`, `Lens`, `LensVerifier` (v0.5.5 / v0.5.6)

The Lens stack is the **library-level** foundation for bidirectional Atom ↔ projection round-trips. The atom is canonical; everything visible to a user (Markdown, Rust source, JSON, dashboards) is a *projection* compiled per audience and per target language. Lenses make those projections **editable** without losing the atom-as-source-of-truth invariant.

No CLI surface yet — this is consumed by Rust callers (in-app editors, sync agents, downstream tooling).

## Table of contents

- [Trait surface](#trait-surface)
- [Foster well-behaved-lens law](#foster-well-behaved-lens-law)
- [`LensVerifier` — round-trip + projection-invariance](#lensverifier--round-trip--projection-invariance)
- [`AtomDiff` variants](#atomdiff-variants)
- [Projected-surface contract](#projected-surface-contract)
- [In-tree crates](#in-tree-crates)
- [Writing a custom lens](#writing-a-custom-lens)
- [Property-test pattern](#property-test-pattern)
- [Anti-patterns](#anti-patterns)
- [TODO / future work](#todo--future-work)

## Trait surface

Two traits, an associated type, three crates. The split mirrors the read/write asymmetry: not every projection needs to be editable.

```rust
// ckl-lens/src/lens.rs

pub trait Compiler {
    /// The representation produced by `compile`.
    /// Examples: `String` (Markdown), `syn::File` (Rust), `serde_json::Value` (JSON).
    type Target;

    /// Project an atom into the target representation.
    fn compile(&self, atom: &Atom) -> Result<Self::Target, LensError>;
}

pub trait Lens: Compiler {
    /// Lift an edited projection back into an atom-shaped diff.
    /// When `edited` is byte-identical to `compile(atom)?`, the diff
    /// MUST be identity (`AtomDiff::is_identity()` returns `true`).
    fn put(&self, atom: &Atom, edited: &Self::Target) -> Result<AtomDiff, LensError>;
}
```

**Why associated `type Target`, not `dyn`?** The associated type makes `Compiler` / `Lens` **not** object-safe — `dyn Lens` does not compile. This is deliberate: every call site is statically dispatched (one `MarkdownLens`, one `RustLens`, …) and each lens picks the most natural representation without `Box<dyn Any>` ceremony. A future `dyn ErasedLens` façade with `Target = String` can be added on top without breaking the foundation.

`Compiler` alone is valid for **read-only views** (HTML preview, dashboard widget, audit report) where the user is never expected to edit the projection.

## Foster well-behaved-lens law

Foster et al. *Combinators for Bidirectional Tree Transformations* (2007) require:

```text
put(atom, get(atom)) == identity AtomDiff
```

Re-projecting an atom and pushing the **unmodified** projection back through `put` must produce no change. Two failure modes are caught by this law:

1. **Information leak** — `compile` drops a field that `put` cannot reconstruct from the projection (the original value is gone, so `put` either invents a wrong one or marks it as changed).
2. **Over-eager `put`** — manufacturing diffs from idempotent input (e.g. reformatting a float on round-trip and emitting a `Content` diff for the cosmetic change).

Both violate the law. Tracked as atom `blk_c0574a3ddc2e_0`.

## `LensVerifier` — round-trip + projection-invariance

```rust
// ckl-lens/src/lens.rs
#[derive(Debug, Default, Clone, Copy)]
pub struct LensVerifier;

impl LensVerifier {
    // v0.5.5 L1 — single-atom round-trip law.
    pub fn verify_round_trip<L: Lens>(lens: &L, atom: &Atom) -> Result<(), LensError>
    where L::Target: core::fmt::Debug;

    // v0.5.5 L2 — batch variant; collects all violations with their indices.
    pub fn verify_round_trip_batch<L: Lens>(
        lens: &L, atoms: &[Atom],
    ) -> Result<(), Vec<(usize, LensError)>>
    where L::Target: core::fmt::Debug;

    // v0.5.6 V — generic projection-invariance check with polymorphic mutator.
    pub fn verify_projection_invariance<L, F>(
        lens: &L, atom: &Atom, mutator: F,
    ) -> Result<(), LensError>
    where
        L: Lens,
        F: FnOnce(&mut L::Target),
        L::Target: Clone + core::fmt::Debug;
}
```

| Helper | What it asserts | When |
|---|---|---|
| `verify_round_trip` | Foster law for one atom: `put(atom, get(atom)).is_identity()`. | Single-atom unit test. |
| `verify_round_trip_batch` | Foster law across `&[Atom]`; failures do **not** short-circuit so one assertion reports the full set. | Property tests over many atoms, CI snapshot runs. |
| `verify_projection_invariance` | Edits the **mutator** makes to non-projected fields of `Target` round-trip to identity; edits to projected fields surface as `RoundTripViolation`. | Property tests confirming a lens's projected surface is exactly what the doc claims. |

On violation, all three helpers return `LensError::RoundTripViolation { diff, atom_id, target_debug }` carrying the offending diff, the originating atom id, and a `Debug` rendering of the target — populated for property-test failure messages.

## `AtomDiff` variants

```rust
// ckl-lens/src/diff.rs
#[non_exhaustive]
pub enum AtomDiff {
    NoOp,                                   // identity — round-trip success.
    Name { old: String, new: String },      // Atom::name changed.
    Content { old: String, new: String },   // projected body changed.
    Multi(Vec<AtomDiff>),                   // multiple field-level diffs at once.
}
```

| Variant | Semantics |
|---|---|
| `NoOp` | Identity. The value `put(atom, get(atom))` must produce when the lens is well-behaved. |
| `Name { old, new }` | The atom's display name changed (M1 / M2 lenses emit this on title rename). |
| `Content { old, new }` | The projected content body changed. "Content" is lens-specific — for M1 Markdown it's the body slice; for M2 Rust it's the rendered `///` doc body. |
| `Multi(Vec<AtomDiff>)` | Multiple field-level diffs combined. Required when one edit touches both name and content. |

`AtomDiff::is_identity()` recursively flattens `Multi`: a `Multi` whose inner diffs are all `NoOp` is treated as identity. `#[non_exhaustive]` lets v0.5.x+ add variants (`Holder`, structured `Frontmatter`, edge-set patches) without an API break — downstream matches must include a `_ => …` arm.

**Foot-gun (atom `blk_6deeebb828e1_0`):** `AtomDiff::Multi(vec![])` is **vacuously identity** — `parts.iter().all(...)` over an empty `Vec` is `true`. A lens that returns `Multi(vec![])` to mean "no structural changes" silently passes the round-trip law verifier even when its iteration found nothing to inspect. The fix is **explicit `NoOp` slots**: M1 `MarkdownLens` and M2 `RustLens` both return `Multi(vec![name_diff, content_diff])` where each component is either `NoOp` or its specific variant. Reviewers can then read all four cases ("name unchanged / changed" × "body unchanged / changed") at a glance, and "I considered the change and found nothing" is distinguishable from "I forgot to compute the diff".

## Projected-surface contract

Tracked as atom `blk_fdd6c9afb2a6_0`. The Foster law applies to the **projected surface**, not the full atom payload.

A `Lens<Target = T>` projects a strict subset of an `Atom` into `T`. Fields **not** present in `T`'s editable region are invariant under that lens by definition: user edits to non-projected metadata (e.g. `confidence: 0.8` → `0.95` in Markdown frontmatter) MUST yield identity diff, **not** fabricated diffs. This avoids the over-eager-`put` failure mode for fields that are emitted only for human reading context but cannot round-trip cleanly (floats reformatted by serialization, timestamps re-encoded, etc.).

In practice each lens documents its projected surface as a table (atom field → projection slot → round-trip behaviour) and uses **slice-extract** rather than parse-then-compare for non-projected fields. `verify_projection_invariance` materialises the contract: pass a mutator that touches non-projected fields and assert `Ok(())`; pass one that touches projected fields and assert `Err(RoundTripViolation)`.

Cross-link: see [atom.md § `AtomDiff`](atom.md#atomdiff--coarse-change-description-v055) for the diff variants and identity-flatten semantics.

## In-tree crates

Three foundation crates plus one test-only crate live in the ckl workspace as of v0.5.6:

| Crate | Target | Module / Type | Status |
|---|---|---|---|
| `ckl-lens` | foundation | trait + struct defs (`Compiler`, `Lens`, `AtomDiff`, `LensVerifier`, `LensError`) | v0.5.5 (L1) |
| `ckl-lens-markdown` | `String` | `MarkdownLens` | v0.5.5 (M1) |
| `ckl-lens-rust` | `syn::File` | `RustLens` | v0.5.6 (M2) |
| `ckl-lens-tests` | (test crate) | cross-lens projection-invariance properties (`tests/projection_invariance.rs`) | v0.5.6 (V) |

`ckl-lens-tests` is `publish = false`, `[lib] doctest = false` — it exists only to host integration tests that exercise the verifier API against multiple concrete lenses without inverting the layering (the foundation crate must not depend on its adopters, even as dev-dependencies, to keep the dependency graph acyclic and downstream-friendly).

## Writing a custom lens

Minimal worked example — a lens projecting an atom into a one-line `id|name` string:

```rust
use ckl_lens::{AtomDiff, Compiler, Lens, LensError};
use ckl_types::Atom;

pub struct OneLineLens;

impl Compiler for OneLineLens {
    type Target = String;
    fn compile(&self, atom: &Atom) -> Result<String, LensError> {
        if atom.name.contains('|') || atom.name.contains('\n') {
            return Err(LensError::Compile(
                "name contains delimiter or newline".into(),
            ));
        }
        Ok(format!("{}|{}", atom.id.as_str(), atom.name))
    }
}

impl Lens for OneLineLens {
    fn put(&self, atom: &Atom, edited: &String) -> Result<AtomDiff, LensError> {
        let (_id, new_name) = edited
            .split_once('|')
            .ok_or_else(|| LensError::Put("missing `|` separator".into()))?;
        // Slice-extract: only `name` is in the projected surface.
        // The id slot is read-only; we don't diff it.
        if new_name == atom.name {
            Ok(AtomDiff::Multi(vec![AtomDiff::NoOp]))
        } else {
            Ok(AtomDiff::Multi(vec![AtomDiff::Name {
                old: atom.name.clone(),
                new: new_name.to_string(),
            }]))
        }
    }
}
```

Key choices that match the M1 / M2 reference impls:

- `Multi([slot])` with explicit `NoOp` rather than empty `Multi(vec![])` (avoids the vacuous-identity foot-gun).
- Slice-extract on the projected surface only (`name`); the id is emitted for context but **not** parsed back.
- `compile` rejects atoms whose `name` would break round-trip (delimiter / newline). Reject early in `compile`, never silently re-encode.

## Property-test pattern

`verify_projection_invariance` materialises the projected-surface contract. Use a non-projected mutator and assert `Ok(())`; use a projected mutator and assert `Err(RoundTripViolation)`:

```rust
use ckl_lens::{LensError, LensVerifier};
use ckl_lens_markdown::MarkdownLens;

#[test]
fn frontmatter_confidence_edit_is_invariant() {
    let atom = full_atom();
    LensVerifier::verify_projection_invariance(&MarkdownLens, &atom, |md| {
        // Non-projected: confidence lives in frontmatter, not in the surface.
        *md = md.replace("confidence: 0.8", "confidence: 0.95");
    })
    .expect("frontmatter edit must round-trip to identity");
}

#[test]
fn body_edit_violates_invariance() {
    let atom = full_atom();
    let result = LensVerifier::verify_projection_invariance(&MarkdownLens, &atom, |md| {
        // Projected: body IS in the surface — must surface a violation.
        *md = md.replace("First paragraph", "MUTATED");
    });
    assert!(matches!(result, Err(LensError::RoundTripViolation { .. })));
}
```

The negative test is critical — it confirms the helper is not vacuously accepting everything. Pair every positive `verify_projection_invariance` with at least one negative case that touches the projected surface. See `crates/ckl-lens-tests/tests/projection_invariance.rs` for the full M1 + M2 cross-lens suite (positive frontmatter / file-header tests, negative body / mod-doc tests, and a 50-case proptest over `arb_atom()`).

## Anti-patterns

- **`Multi(vec![])` as no-op signal.** Vacuously identity (atom `blk_6deeebb828e1_0`) — passes the law verifier even when iteration found nothing. Use explicit `NoOp` slots so the diff shape documents which fields were inspected.
- **Parsing non-projected fields back in `put`.** A field emitted by `compile` for human reading (confidence, timestamps, ids) but parsed back by `put` will fabricate diffs whenever serialization is non-canonical. Slice-extract the projected surface; ignore the rest.
- **Non-`#[non_exhaustive]` matches on `AtomDiff`.** `AtomDiff` is `#[non_exhaustive]`. A future variant (e.g. `Holder`, `Frontmatter`) would silently break exhaustive matches. Always include `_ => …`.
- **`dyn Lens` collections.** Not object-safe by design (associated `Target`). Reach for an `enum LensKind { Markdown(MarkdownLens), Rust(RustLens), … }` or a thin erased façade with `Target = String`.
- **Skipping the negative `verify_projection_invariance` test.** A mutator that never touches the projected surface always passes; without a paired negative case you're proving "this code compiles", not "this lens has the surface I think it does".

## TODO / future work

- **`ckl ask --aspect projection --as <target>` CLI aspect — shipped in v0.5.7 (W2 δ)** for `markdown` (M1) and `rust` (M2). Lives in the `ckl-ask-projection` crate; respects the projected-surface contract verbatim. See [ask.md § Projection](ask.md#projection--projection---as-markdownrust).
- **M3 TypeScript lens** — `Target = swc_ecma_ast::Module` or similar. Candidate for v0.5.8. The trait surface and verifier helpers cover this with no foundation changes; landing it adds one new variant to `ProjectionTargetArg` + one match arm in `ProjectionAspect`.
- **Heterogeneous lens collections** — a `dyn ErasedLens` façade fixing `Target = String` would let registries iterate over an arbitrary set of lenses for round-trip CI sweeps. Not yet justified by demand.

## See also

- [SKILL.md § Lens trait overview](../SKILL.md#lens-trait-overview-v055) — the entry-point summary in `ckl-knowledge`.
- [ask.md § Projection](ask.md#projection--projection---as-markdownrust) — the v0.5.7 CLI aspect that wraps the Lens stack via FIPA-ACL REQUEST.
- [atom.md § `AtomDiff`](atom.md#atomdiff--coarse-change-description-v055) — diff anatomy and identity-flatten semantics.
- [atom.md § Atom anatomy](atom.md#atom-anatomy) — the canonical envelope a lens projects.
- Atom IDs cross-referenced above: `blk_481254a21827_0` (atom-as-invariant pattern), `blk_c0574a3ddc2e_0` (Lens trait law), `blk_338f812e632c_0` (v0.5.5 L1 decision), `blk_642d5ff86b7e_0` (v0.5.5 M1 MarkdownLens), `blk_56b45ba60f45_0` (v0.5.6 M2 RustLens), `blk_6deeebb828e1_0` (Multi(vec![]) foot-gun), `blk_fdd6c9afb2a6_0` (projected-surface contract).
