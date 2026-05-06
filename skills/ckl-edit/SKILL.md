---
name: ckl-edit
description: Use when the user wants to modify code with provenance — edit existing files, write new files, rename, batch-refactor with rollback, or group ops into one auditable session. All edits emit Edit nutrients and auto-relate to the knowledge graph. Activate on mentions of "edit", "refactor", "rename", "create file", "fix", "change", "modify", "apply patch", "batch edit", or any file modification request in indexed projects.
license: Apache-2.0
compatibility: Requires `ckl` binary >= 0.5.6 on $PATH and a project indexed with `ckl index` (see ckl-system skill).
metadata:
  version: 0.2.3
  upstream: https://github.com/koslab/ckl
  composes-with: ckl-search, ckl-knowledge
  prerequisite: ckl-system
  primary-commands: edit, write, apply, mv, mkdir, rm, session
---

# CKL Edit

Agent-first file operations with provenance. Every edit emits an `Edit` nutrient and auto-relates the change to the knowledge graph, so refactors are auditable end-to-end.

**Binary:** `ckl` on `$PATH`. **Conventions:** JSON-by-default, `--pretty` for humans, `--dry-run` to preview without disk/graph writes. Errors return `{error, code, hint}` with semantic exit codes (`1` user, `2` conflict, `3` invalid-state).

## Quick Reference

| Command | Purpose |
|---|---|
| `ckl edit <path> --old "x" --new "y" --reason "..."` | Exact replacement + Edit nutrient + auto-relate |
| `ckl write <path> --reason "..." --entity <id>` | Atomic: file + knowledge + Edit nutrient |
| `ckl apply` (stdin JSON) | Batch edit/write/mv with two-pass + rollback |
| `ckl mv <src> <dst>` | Rename file + update graph blocks referring to it |
| `ckl mkdir <path>` | Create directory (agent-first) |
| `ckl rm <path>` | Tombstone-aware delete |
| `ckl session start \| commit \| abort \| status` | Group N ops into one `process` block |

Full per-flag reference: [references/file-ops.md](references/file-ops.md), [references/session.md](references/session.md).

## Edit existing file

```bash
ckl edit src/main.rs \
  --old "fn legacy(" \
  --new "fn modern(" \
  --reason "rename: legacy → modern after RFC-12"
```

- `--old`/`--new` must be **unique** in the file unless `--replace-all`.
- `--reason` required (unless `--dry-run`).
- `--type decision|fact|process|pattern` (default `decision`).
- `--entity <id>` — emit `Edit` nutrient on every indexed block touched.
- `--session <id>` — attach to active session.

## Write new file

```bash
ckl write src/new_module.rs \
  --content "pub fn hello() {}" \
  --reason "bootstrap module" \
  --entity entity_ckl
```

Or via stdin:
```bash
echo "fn main() {}" | ckl write src/main.rs --reason "init"
```

## Batch operations (atomic)

```bash
cat <<EOF | ckl apply --pretty
{
  "reason": "refactor X across 3 files",
  "entity": "entity_ckl",
  "operations": [
    { "op": "edit",  "path": "a.rs", "old": "foo", "new": "bar" },
    { "op": "write", "path": "b.rs", "content": "..." },
    { "op": "mv",    "src":  "old.rs", "dst": "new.rs" }
  ]
}
EOF
```

Two-pass: validate-all then apply-all. One knowledge block documents the entire batch. Rollback on failure.

**Exit codes:** `0` ok, `1` user-error, `2` conflict-pass1, `3` rollback-ok, `4` rollback-failed (CRITICAL).

## Rename and dir ops

```bash
ckl mv old.rs new.rs                  # rename + update graph blocks
ckl mkdir src/new_dir                  # create directory
ckl rm src/legacy.rs                   # tombstone-aware delete
```

## Sessions — group ops

```bash
ckl session start --pretty             # creates ~/.ckl/sessions/<id>.json
# ... do edits with --session <id> ...
ckl session status --pretty
ckl session commit --pretty            # one process-typed block + PART_OF edges
ckl session abort --pretty             # discard
```

A committed session becomes a single `process` knowledge block linked via `PART_OF` to the underlying ops, so a multi-step refactor reads as one auditable unit.

## When to Use What

| Need | Tool | Why |
|---|---|---|
| Single replacement | `ckl edit` | Edit + nutrient + auto-relate |
| Create new file | `ckl write --reason` | Atomic file + knowledge + nutrient |
| Multi-file batch | `ckl apply` (stdin JSON) | Atomic with rollback |
| Group several ops | `ckl session start/commit` | One `process` block + `PART_OF` edges |
| Rename | `ckl mv` | Updates graph blocks transparently |
| Quick test | add `--dry-run` | Preview without disk/graph writes |

## Composes with

This skill is one of five `ckl` skills. Use it together with:

- **`ckl-system`** — prerequisite: index the project before editing
- **`ckl-search`** — find the code first via `ckl query --enriched`
- **`ckl-knowledge`** — capture the rationale for the change as a separate atom
- **`ckl-evolve`** — run a cycle after meaningful changes; audit weak decisions

## Gotchas

1. `--old` must be unique unless `--replace-all`. Conflict returns exit code `2`.
2. Always pass `--reason` on mutations — without it the change has no audit trail (and `ckl edit` rejects unless `--dry-run`).
3. `ckl apply` exit code `4` (rollback-failed) is CRITICAL — disk/graph may be inconsistent. Inspect immediately.
4. After raw text edits via the native `Edit` tool (no `ckl edit`), re-run `ckl index <path>` so the graph reflects the new state.
5. The `edit` / `write` / `apply` / `mv` / `mkdir` / `rm` / `session` surface is unchanged from v0.4.x — v0.5.0–v0.5.5 added `Atom` / scoped search / `ckl blob` / Lens stack, but file-ops semantics (Edit nutrients, two-pass apply, exit codes) are stable. Pair with `ckl-knowledge` if you want the v0.5.0 JTB+S envelope (`--holder`, `--kind`, `--container`) on the rationale you capture alongside an edit.
6. **Testing/migration helper (v0.5.4):** `ckl manage block create --blob-oid <40-char-hex>` assigns an explicit `blob_oid` so the `blocks_by_blob_oid` reverse index is populated for `ckl blob <oid> --refs` end-to-end tests. **Not** a regular file-op — production captures should go through `ckl write` / `ckl edit` / `ckl capture`. See [`ckl-search/references/blob.md`](../ckl-search/references/blob.md) for the daemon-lock matrix that the reverse index unlocks.
